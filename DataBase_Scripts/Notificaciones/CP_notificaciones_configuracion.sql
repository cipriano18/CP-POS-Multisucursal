-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- BASE DE DATOS: Oracle 21c
-- SCRIPT: CP_notificaciones_configuracion.sql
-- DESCRIPCION: Deja lista la configuracion que necesita el modulo
--              de notificaciones para mandar correos:
--                1. Parametro CORREO_ALERTAS_BD: correo externo que
--                   recibe todos los avisos (definido antes de la
--                   defensa, segun el enunciado).
--                2. Configuracion SMTP activa en CP_CONFIGURACION_CORREO
--                   con la clave cifrada por PKG_CP_CRIPTO (AES-256).
--                3. Contacto y destinatario activo para ese correo.
--              Los tres valores se piden al ejecutar (variables de
--              sustitucion), asi ningun correo ni clave queda escrito
--              en el repositorio.
--
-- EJECUTAR COMO: CP_POS en XEPDB1, con F5 (como script) en SQL
--                Developer. Despues del script 15
--                (PKG_CP_CRIPTO y PKG_CP_PARAMETRO) y antes de
--                instalar PKG_CP_NOTIFICACIONES. Se puede volver a
--                ejecutar: actualiza en vez de duplicar (sirve para
--                cambiar el correo o la clave).
--
-- PREREQUISITO FUERA DE ESTE SCRIPT: el Oracle Wallet con los
-- certificados de Gmail en /opt/oracle/wallets/smtp dentro del
-- contenedor (ver Notificaciones/README.md, seccion 5), y las
-- secciones 15 y 16 de CP_usuario_esquema.sql ejecutadas como SYS.
--
-- ERRORES PROPIOS (tramo -20350 a -20359):
--   -20350 un correo no tiene un formato valido
--   -20351 la clave esta vacia
--   -20352 no existe el tipo de contacto CORREO
--   -20353 la clave guardada no se pudo descifrar igual
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
-- Evita que SQL Developer imprima las lineas con los valores ya
-- sustituidos (la clave apareceria en la salida).
SET VERIFY OFF

PROMPT Correo que recibe los avisos (CORREO_ALERTAS_BD):
DEFINE correo_alertas = '&correo_alertas'
PROMPT Correo de Gmail que envia (remitente y usuario SMTP):
DEFINE correo_remitente = '&correo_remitente'
PROMPT Contrasena de aplicacion de Gmail (16 caracteres, sin espacios):
DEFINE clave_aplicacion = '&clave_aplicacion'

-- ============================================================
-- 1. PARAMETRO, CONFIGURACION SMTP Y DESTINATARIO
-- ============================================================
-- Todo en un solo bloque y una sola transaccion: si algo falla no
-- queda una configuracion a medias.

DECLARE
    -- Servidor de Gmail: debe coincidir con la ACL de la seccion 16
    -- de CP_usuario_esquema.sql.
    c_smtp_host CONSTANT VARCHAR2(100) := 'smtp.gmail.com';
    c_smtp_port CONSTANT NUMBER        := 587;

    c_mail_pattern CONSTANT VARCHAR2(60) := '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$';

    v_alerts   VARCHAR2(100) := LOWER(TRIM('&&correo_alertas'));
    v_sender   VARCHAR2(100) := LOWER(TRIM('&&correo_remitente'));
    -- Gmail muestra la contrasena de aplicacion en grupos de 4 con
    -- espacios; se quitan para que no fallen al copiarla.
    v_secret   VARCHAR2(100) := REPLACE('&&clave_aplicacion', ' ', '');

    v_type     NUMBER;
    v_config   NUMBER;
    v_count    NUMBER;

    -- Devuelve el contacto de tipo CORREO con ese valor; si no existe lo crea.
    FUNCTION mail_contact(
        p_mail IN VARCHAR2
    ) RETURN NUMBER
    IS
        v_id NUMBER;
    BEGIN
        SELECT MIN(id_contacto)
        INTO v_id
        FROM CP_CONTACTO
        WHERE id_tipo_contacto = v_type
          AND LOWER(TRIM(valor_contacto)) = p_mail;

        IF v_id IS NULL THEN
            INSERT INTO CP_CONTACTO (id_tipo_contacto, valor_contacto)
            VALUES (v_type, p_mail)
            RETURNING id_contacto INTO v_id;
        END IF;

        RETURN v_id;
    END mail_contact;

    PROCEDURE check_mail(
        p_mail  IN VARCHAR2,
        p_label IN VARCHAR2
    )
    IS
    BEGIN
        IF p_mail IS NULL OR NOT REGEXP_LIKE(p_mail, c_mail_pattern) THEN
            RAISE_APPLICATION_ERROR(
                -20350,
                'El ' || p_label || ' no tiene un formato de correo valido: '
                || NVL(p_mail, '<vacio>')
            );
        END IF;
    END check_mail;

BEGIN

    check_mail(v_alerts, 'correo de avisos');
    check_mail(v_sender, 'correo remitente');

    IF v_secret IS NULL THEN
        RAISE_APPLICATION_ERROR(-20351, 'La contrasena de aplicacion esta vacia.');
    END IF;

    BEGIN
        SELECT id_tipo_contacto
        INTO v_type
        FROM CP_TIPO_DE_CONTACTO
        WHERE UPPER(TRIM(nombre_tipo_contacto)) = 'CORREO';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20352, 'No existe el tipo de contacto CORREO.');
    END;

    -- 1.1 Parametro con el correo de avisos (lo leen las alertas de
    --     Cipriano y PKG_CP_AVISO de la Fase 4)
    MERGE INTO CP_PARAMETRO p
    USING (SELECT 'CORREO_ALERTAS_BD' AS codigo FROM dual) s
       ON (p.codigo_parametro = s.codigo)
    WHEN MATCHED THEN
        UPDATE SET p.valor = v_alerts,
                   p.fecha_modificacion = SYSTIMESTAMP
    WHEN NOT MATCHED THEN
        INSERT (codigo_parametro, modulo, tipo_dato, es_cifrado, valor, descripcion)
        VALUES (s.codigo, 'NOTIFICACION', 'TEXTO', 'N', v_alerts,
                'Correo externo que recibe todos los avisos del sistema');

    -- 1.2 Configuracion SMTP. El codigo de envio toma la primera fila
    --     activa, por eso debe haber UNA sola: se apagan las demas y se
    --     actualiza (o crea) la del remitente indicado. Las viejas no se
    --     borran porque las notificaciones ya enviadas las referencian.
    UPDATE CP_CONFIGURACION_CORREO
    SET activo = 'N'
    WHERE activo = 'S'
      AND LOWER(usuario_smtp) <> v_sender;

    SELECT MIN(id_configuracion_correo)
    INTO v_config
    FROM CP_CONFIGURACION_CORREO
    WHERE LOWER(usuario_smtp) = v_sender;

    IF v_config IS NULL THEN
        INSERT INTO CP_CONFIGURACION_CORREO
            (id_contacto_remitente, servidor_smtp, puerto_smtp, usuario_smtp,
             clave_cifrada, requiere_tls, activo)
        VALUES
            (mail_contact(v_sender), c_smtp_host, c_smtp_port, v_sender,
             PKG_CP_CRIPTO.cifrar(v_secret), 'S', 'S')
        RETURNING id_configuracion_correo INTO v_config;
    ELSE
        UPDATE CP_CONFIGURACION_CORREO
        SET servidor_smtp = c_smtp_host,
            puerto_smtp   = c_smtp_port,
            clave_cifrada = PKG_CP_CRIPTO.cifrar(v_secret),
            requiere_tls  = 'S',
            activo        = 'S'
        WHERE id_configuracion_correo = v_config;

        -- Si hubiera mas de una fila con el mismo usuario, solo una queda activa
        UPDATE CP_CONFIGURACION_CORREO
        SET activo = 'N'
        WHERE LOWER(usuario_smtp) = v_sender
          AND id_configuracion_correo <> v_config;
    END IF;

    -- 1.3 Destinatario activo para el correo de avisos (encolar solo
    --     acepta destinatarios registrados y activos)
    MERGE INTO CP_DESTINATARIO_NOTIFICACION d
    USING (SELECT mail_contact(v_alerts) AS id_contacto FROM dual) s
       ON (d.id_contacto = s.id_contacto)
    WHEN MATCHED THEN
        UPDATE SET d.activo = 'S'
    WHEN NOT MATCHED THEN
        INSERT (id_contacto, activo) VALUES (s.id_contacto, 'S');

    -- 1.4 Comprobacion antes de confirmar: la clave guardada se descifra
    --     igual a la escrita (sin imprimirla)
    SELECT COUNT(*)
    INTO v_count
    FROM CP_CONFIGURACION_CORREO
    WHERE id_configuracion_correo = v_config
      AND PKG_CP_CRIPTO.descifrar(clave_cifrada) = v_secret;

    IF v_count <> 1 THEN
        RAISE_APPLICATION_ERROR(-20353, 'La clave guardada no se pudo descifrar igual a la escrita.');
    END IF;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Configuracion de correo lista:');
    DBMS_OUTPUT.PUT_LINE('  avisos a ...... ' || v_alerts);
    DBMS_OUTPUT.PUT_LINE('  remitente ..... ' || v_sender || ' (' || c_smtp_host || ':' || c_smtp_port || ', TLS)');
    DBMS_OUTPUT.PUT_LINE('  configuracion . ' || v_config || ' (clave cifrada y verificada)');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        -- PKG_CP_ERROR guarda el error; la clave nunca va en el detalle
        PKG_CP_ERROR.registrar_inesperado('NOTIFICACION', 'configuracion de correo');
        DBMS_OUTPUT.PUT_LINE('No se guardo nada: ' || SQLERRM);
        RAISE;
END;
/

UNDEFINE correo_alertas
UNDEFINE correo_remitente
UNDEFINE clave_aplicacion
SET VERIFY ON

-- ============================================================
-- 2. VERIFICACION (sin mostrar la clave)
-- ============================================================

SELECT codigo_parametro, valor
FROM   CP_PARAMETRO
WHERE  codigo_parametro = 'CORREO_ALERTAS_BD';

SELECT id_configuracion_correo, servidor_smtp, puerto_smtp, usuario_smtp,
       requiere_tls, activo, DBMS_LOB.GETLENGTH(TO_BLOB(clave_cifrada)) AS bytes_clave_cifrada
FROM   CP_CONFIGURACION_CORREO
ORDER  BY id_configuracion_correo;

SELECT d.id_destinatario, c.valor_contacto, d.activo
FROM   CP_DESTINATARIO_NOTIFICACION d
JOIN   CP_CONTACTO c
  ON   c.id_contacto = d.id_contacto
ORDER  BY d.id_destinatario;
