-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- BASE DE DATOS: Oracle 21c
-- SCRIPT: 26A_negocio_avisos.sql
-- DESCRIPCION: Punto unico por el que los procesos de negocio de la
--              Fase 4 (cierre diario, reporte semanal de inventario y
--              premiacion de clientes) mandan sus avisos por correo.
--              Paquete PKG_CP_AVISO: deja cada aviso en la cola del
--              modulo de notificaciones (PKG_CP_NOTIFICACIONES.encolar),
--              sin COMMIT, dirigido al correo del parametro
--              CORREO_ALERTAS_BD (el mismo que usa ese modulo). El envio
--              real lo hace despues el job JOB_CP_PROCESAR_NOTIFICACIONES.
--
--              Regla principal: un aviso que no se puede encolar NO
--              detiene al proceso que avisa. El error queda en
--              CP_BITACORA_ERROR (modulo AVISO) y el cierre, el reporte
--              o la premiacion se guardan igual.
--
--              Se numera 26A para no renumerar los scripts 27 al 31: va
--              antes que ellos porque sus paquetes llaman a este.
--
-- EJECUTAR COMO: CP_POS en XEPDB1 (despues del script 26). No depende
--                de que el modulo de notificaciones ya este instalado
--                (ver la seccion 2). Se puede volver a ejecutar
--                completo las veces que haga falta.
--
-- ERRORES PROPIOS (tramo -20340 a -20349):
--   -20340 el parametro del correo de avisos esta vacio
--   -20341 no existe el tipo de contacto CORREO
--   -20342 queue_notice_to recibio un correo vacio
--
-- queue_notice_to y already_queued los usan tambien PKG_CP_ALERTA y
-- PKG_CP_MONITOREO (Notificaciones/CP_notificaciones_paquetes.sql).
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED

-- ============================================================
-- 1. PAQUETE PKG_CP_AVISO (ESPECIFICACION)
-- ============================================================

CREATE OR REPLACE PACKAGE PKG_CP_AVISO AUTHID DEFINER AS

    -- Resultado del ultimo aviso de la sesion (ver last_status)
    c_status_queued   CONSTANT VARCHAR2(12) := 'ENCOLADO';
    c_status_failed   CONSTANT VARCHAR2(12) := 'FALLIDO';
    c_status_disabled CONSTANT VARCHAR2(12) := 'DESACTIVADO';

    -- Parametro con el correo que recibe los avisos de negocio
    c_default_mail_parameter CONSTANT VARCHAR2(60) := 'CORREO_ALERTAS_BD';

    -- Deja un aviso en la cola de notificaciones sin confirmar: queda
    -- dentro de la transaccion de quien llama, asi que si ese proceso
    -- hace ROLLBACK el aviso desaparece con el. Nunca lanza error: si
    -- falla, deshace solo lo suyo, lo registra en la bitacora y deja
    -- last_status = FALLIDO.
    PROCEDURE queue_notice(
        p_type           IN VARCHAR2,
        p_subject        IN VARCHAR2,
        p_message        IN CLOB,
        p_mail_parameter IN VARCHAR2 DEFAULT c_default_mail_parameter
    );

    -- Igual que queue_notice, pero dirigido a un correo concreto (por
    -- ejemplo el de un cliente) en lugar del correo de un parametro.
    PROCEDURE queue_notice_to(
        p_type    IN VARCHAR2,
        p_subject IN VARCHAR2,
        p_message IN CLOB,
        p_mail    IN VARCHAR2
    );

    -- Indica si ya hay en la cola un aviso de ese tipo (y de ese asunto,
    -- si se indica) creado desde p_since. Sirve para no repetir un aviso
    -- cuando el proceso se ejecuta varias veces en el mismo periodo.
    FUNCTION already_queued(
        p_type    IN VARCHAR2,
        p_subject IN VARCHAR2 DEFAULT NULL,
        p_since   IN DATE     DEFAULT TRUNC(SYSDATE)
    ) RETURN BOOLEAN;

    -- Enciende o apaga los avisos en esta sesion (por defecto
    -- encendidos). Las pruebas los apagan para no dejar correos reales
    -- en cola. Tambien limpia last_status.
    PROCEDURE set_enabled(
        p_enabled IN BOOLEAN
    );

    FUNCTION is_enabled RETURN BOOLEAN;

    -- ENCOLADO, FALLIDO o DESACTIVADO segun el ultimo queue_notice de
    -- la sesion; NULL si todavia no hubo ninguno.
    FUNCTION last_status RETURN VARCHAR2;

    -- Ajusta un CLOB al limite de VARCHAR2 que acepta encolar. Si no
    -- cabe, corta en el ultimo salto de linea completo y agrega una nota.
    FUNCTION fit_text(
        p_text IN CLOB
    ) RETURN VARCHAR2;

END PKG_CP_AVISO;
/

-- ============================================================
-- 2. PAQUETE PKG_CP_AVISO (CUERPO)
-- ============================================================
-- La llamada al modulo de correo va por SQL dinamico (EXECUTE
-- IMMEDIATE) y no escrita directamente. Con una llamada directa este
-- paquete dependeria de PKG_CP_NOTIFICACIONES al compilar: si ese
-- modulo no esta instalado o su cuerpo queda invalido, el error
-- saldria en el cierre o en la premiacion y los detendria. Con SQL
-- dinamico el error ocurre dentro de queue_notice, que lo atrapa y lo
-- registra. El precio es que el compilador ya no revisa esa llamada;
-- por eso las pruebas de la seccion 3 la ejecutan de verdad cuando el
-- modulo esta listo. Los valores viajan como variables de enlace
-- (:1 a :4), nunca pegados al texto, asi que no hay inyeccion de SQL.

CREATE OR REPLACE PACKAGE BODY PKG_CP_AVISO AS

    c_modulo CONSTANT VARCHAR2(20) := 'AVISO';

    c_err_sin_correo CONSTANT PLS_INTEGER := -20340;
    c_err_sin_tipo   CONSTANT PLS_INTEGER := -20341;
    c_err_vacio      CONSTANT PLS_INTEGER := -20342;

    -- encolar recibe el mensaje como VARCHAR2 (maximo 32 767 bytes en
    -- PL/SQL); se deja margen. Los trozos de 8000 caracteres ocupan como
    -- maximo 32 000 bytes aunque cada caracter use 4 bytes en UTF-8.
    c_max_bytes   CONSTANT PLS_INTEGER := 32000;
    c_chunk_chars CONSTANT PLS_INTEGER := 8000;
    c_max_subject CONSTANT PLS_INTEGER := 200;
    c_cut_note    CONSTANT VARCHAR2(120) :=
        CHR(10) || '... (mensaje recortado por tamano; el detalle completo esta en la base de datos)';

    c_enqueue_call CONSTANT VARCHAR2(200) :=
        'BEGIN PKG_CP_NOTIFICACIONES.encolar('
        || 'p_tipo => :1, p_asunto => :2, p_mensaje => :3, p_correo => :4); END;';

    -- Estado de la sesion (cada sesion tiene su propia copia)
    g_enabled     BOOLEAN := TRUE;
    g_last_status VARCHAR2(12);


    FUNCTION fit_text(
        p_text IN CLOB
    ) RETURN VARCHAR2
    IS
        v_room   PLS_INTEGER := c_max_bytes - LENGTHB(c_cut_note);
        v_total  NUMBER;
        v_offset NUMBER := 1;
        v_piece  VARCHAR2(32767);
        v_text   VARCHAR2(32767);
        v_cut    PLS_INTEGER;
    BEGIN

        IF p_text IS NULL THEN
            RETURN NULL;
        END IF;

        v_total := DBMS_LOB.GETLENGTH(p_text);

        WHILE v_offset <= v_total LOOP
            v_piece := DBMS_LOB.SUBSTR(p_text, c_chunk_chars, v_offset);

            IF NVL(LENGTHB(v_text), 0) + LENGTHB(v_piece) > v_room THEN
                -- Entra solo una parte del trozo: se corta por bytes y
                -- se retrocede al ultimo salto de linea para no dejar
                -- una fila del reporte a la mitad.
                v_piece := SUBSTRB(v_piece, 1, v_room - NVL(LENGTHB(v_text), 0));
                v_cut := INSTR(v_piece, CHR(10), -1);
                IF v_cut > 0 THEN
                    v_piece := SUBSTR(v_piece, 1, v_cut - 1);
                END IF;
                RETURN v_text || v_piece || c_cut_note;
            END IF;

            v_text := v_text || v_piece;
            v_offset := v_offset + c_chunk_chars;
        END LOOP;

        RETURN v_text;

    END fit_text;


    FUNCTION mail_contact_type RETURN NUMBER
    IS
        v_id CP_TIPO_DE_CONTACTO.id_tipo_contacto%TYPE;
    BEGIN
        SELECT id_tipo_contacto
        INTO v_id
        FROM CP_TIPO_DE_CONTACTO
        WHERE UPPER(TRIM(nombre_tipo_contacto)) = 'CORREO';

        RETURN v_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_sin_tipo,
                'No existe el tipo de contacto CORREO en CP_TIPO_DE_CONTACTO.'
            );
    END mail_contact_type;


    -- encolar solo acepta correos que ya esten registrados como contacto
    -- y como destinatario activo. Igual que los procedimientos de alertas
    -- del modulo de notificaciones, aqui se registran si faltan. Si el
    -- destinatario existe pero esta inactivo se respeta (alguien lo
    -- apago a proposito) y encolar rechazara el aviso.
    PROCEDURE ensure_recipient(
        p_mail IN VARCHAR2
    )
    IS
        v_type    NUMBER := mail_contact_type;
        v_contact CP_CONTACTO.id_contacto%TYPE;
        v_count   NUMBER;
    BEGIN

        SELECT MIN(id_contacto)
        INTO v_contact
        FROM CP_CONTACTO
        WHERE id_tipo_contacto = v_type
          AND LOWER(TRIM(valor_contacto)) = LOWER(p_mail);

        IF v_contact IS NULL THEN
            INSERT INTO CP_CONTACTO (id_tipo_contacto, valor_contacto)
            VALUES (v_type, p_mail)
            RETURNING id_contacto INTO v_contact;
        END IF;

        -- id_contacto es UNIQUE en los destinatarios: a lo sumo una fila
        SELECT COUNT(*)
        INTO v_count
        FROM CP_DESTINATARIO_NOTIFICACION
        WHERE id_contacto = v_contact;

        IF v_count = 0 THEN
            INSERT INTO CP_DESTINATARIO_NOTIFICACION (id_contacto, activo)
            VALUES (v_contact, 'S');
        END IF;

    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            -- Otra sesion registro el mismo destinatario al mismo tiempo:
            -- ya existe, que es justo lo que se buscaba.
            NULL;
    END ensure_recipient;


    -- Recorta el asunto y el mensaje, registra el destinatario si falta
    -- y deja el aviso en la cola. Lanza error si algo falla: quien llama
    -- decide que hacer con el (los dos procedimientos publicos lo atrapan).
    PROCEDURE enqueue(
        p_type    IN VARCHAR2,
        p_subject IN VARCHAR2,
        p_message IN CLOB,
        p_mail    IN VARCHAR2
    )
    IS
        v_subject VARCHAR2(200);
        v_text    VARCHAR2(32767);
    BEGIN

        -- La columna asunto mide 200 bytes (no caracteres): se corta por bytes
        v_subject := SUBSTRB(p_subject, 1, c_max_subject);
        v_text    := fit_text(p_message);

        ensure_recipient(p_mail);

        EXECUTE IMMEDIATE c_enqueue_call
            USING p_type, v_subject, v_text, p_mail;

    END enqueue;


    PROCEDURE queue_notice(
        p_type           IN VARCHAR2,
        p_subject        IN VARCHAR2,
        p_message        IN CLOB,
        p_mail_parameter IN VARCHAR2 DEFAULT c_default_mail_parameter
    )
    IS
        v_mail VARCHAR2(500);
    BEGIN

        IF NOT g_enabled THEN
            g_last_status := c_status_disabled;
            RETURN;
        END IF;

        -- Si algo falla se deshace solo lo del aviso (contacto,
        -- destinatario y notificacion); lo del proceso que avisa queda.
        SAVEPOINT sp_queue_notice;

        v_mail := TRIM(PKG_CP_PARAMETRO.obtener_texto(p_mail_parameter));

        IF v_mail IS NULL THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_sin_correo,
                'El parametro ' || p_mail_parameter || ' no tiene un correo.',
                'tipo=' || p_type
            );
        END IF;

        enqueue(p_type, p_subject, p_message, v_mail);

        g_last_status := c_status_queued;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK TO SAVEPOINT sp_queue_notice;
            g_last_status := c_status_failed;
            -- Los errores propios (-20200 a -20399) ya quedaron en la
            -- bitacora al lanzarse; aqui solo se registra lo inesperado
            -- (modulo de correo sin instalar, sin configuracion activa...).
            PKG_CP_ERROR.registrar_inesperado(
                c_modulo,
                'tipo=' || p_type || ' parametro=' || p_mail_parameter
            );
            -- No se relanza a proposito: el aviso no debe detener el proceso.
    END queue_notice;


    PROCEDURE queue_notice_to(
        p_type    IN VARCHAR2,
        p_subject IN VARCHAR2,
        p_message IN CLOB,
        p_mail    IN VARCHAR2
    )
    IS
        v_mail VARCHAR2(500);
    BEGIN

        IF NOT g_enabled THEN
            g_last_status := c_status_disabled;
            RETURN;
        END IF;

        SAVEPOINT sp_queue_notice_to;

        -- Se asigna aqui y no al declarar: asi un correo demasiado largo
        -- cae en el manejador de abajo y tampoco detiene al que avisa
        v_mail := TRIM(SUBSTR(p_mail, 1, 500));

        IF v_mail IS NULL THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_vacio,
                'El aviso no tiene un correo de destino.',
                'tipo=' || p_type
            );
        END IF;

        enqueue(p_type, p_subject, p_message, v_mail);

        g_last_status := c_status_queued;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK TO SAVEPOINT sp_queue_notice_to;
            g_last_status := c_status_failed;
            PKG_CP_ERROR.registrar_inesperado(
                c_modulo,
                'tipo=' || p_type || ' correo=' || SUBSTR(v_mail, 1, 100)
            );
    END queue_notice_to;


    FUNCTION already_queued(
        p_type    IN VARCHAR2,
        p_subject IN VARCHAR2 DEFAULT NULL,
        p_since   IN DATE     DEFAULT TRUNC(SYSDATE)
    ) RETURN BOOLEAN
    IS
        v_count NUMBER;
    BEGIN

        SELECT COUNT(*)
        INTO v_count
        FROM CP_NOTIFICACION
        WHERE tipo_notificacion = p_type
          AND (p_subject IS NULL OR asunto = SUBSTRB(p_subject, 1, c_max_subject))
          AND fecha_creacion >= CAST(p_since AS TIMESTAMP);

        RETURN v_count > 0;

    END already_queued;


    PROCEDURE set_enabled(
        p_enabled IN BOOLEAN
    )
    IS
    BEGIN
        g_enabled := NVL(p_enabled, TRUE);
        g_last_status := NULL;
    END set_enabled;


    FUNCTION is_enabled RETURN BOOLEAN
    IS
    BEGIN
        RETURN g_enabled;
    END is_enabled;


    FUNCTION last_status RETURN VARCHAR2
    IS
    BEGIN
        RETURN g_last_status;
    END last_status;

END PKG_CP_AVISO;
/

SHOW ERRORS PACKAGE BODY PKG_CP_AVISO

-- ============================================================
-- 3. PRUEBAS DE LOS AVISOS
-- ============================================================
-- Se ejecutan como CP_POS y todo se deshace con ROLLBACK. Se usa un
-- parametro propio de prueba (CORREO_PRUEBA_AVISO) para no tocar
-- CORREO_ALERTAS_BD. Las pruebas 9 y 10 necesitan el modulo de
-- notificaciones de Cipriano instalado y VALID y una configuracion de
-- correo activa; si falta algo se omiten y la prueba 8 comprueba que
-- el fallo no interrumpe ni deja datos. Solo se borran de la bitacora
-- los errores provocados a proposito.

DECLARE
    c_param CONSTANT VARCHAR2(60) := 'CORREO_PRUEBA_AVISO';
    c_type  CONSTANT VARCHAR2(50) := 'PRUEBA_AVISO';

    v_antes       NUMBER;
    v_notif_antes NUMBER;
    v_ok          NUMBER := 0;
    v_falla       NUMBER := 0;
    v_omitida     NUMBER := 0;

    v_stamp       VARCHAR2(20) := TO_CHAR(SYSDATE, 'MMDDHH24MISS');
    v_mail        VARCHAR2(100);
    v_status      VARCHAR2(12);
    v_count       NUMBER;
    v_valid       NUMBER;
    v_config      NUMBER;
    v_ready       BOOLEAN;
    v_called      BOOLEAN;
    v_long        CLOB;
    v_fit         VARCHAR2(32767);

    PROCEDURE reportar(
        p_prueba IN VARCHAR2,
        p_ok     IN BOOLEAN
    )
    IS
    BEGIN
        IF p_ok THEN
            v_ok := v_ok + 1;
        ELSE
            v_falla := v_falla + 1;
        END IF;
        DBMS_OUTPUT.PUT_LINE(
            RPAD(p_prueba, 72, '.') || CASE WHEN p_ok THEN ' OK' ELSE ' FALLA' END
        );
    END reportar;

    PROCEDURE omitir(
        p_prueba IN VARCHAR2,
        p_motivo IN VARCHAR2
    )
    IS
    BEGIN
        v_omitida := v_omitida + 1;
        DBMS_OUTPUT.PUT_LINE(RPAD(p_prueba, 72, '.') || ' omitida (' || p_motivo || ')');
    END omitir;

    -- Llama al aviso y devuelve FALSE si se le escapo un error
    FUNCTION call_notice(
        p_message IN CLOB,
        p_param   IN VARCHAR2
    ) RETURN BOOLEAN
    IS
    BEGIN
        PKG_CP_AVISO.queue_notice(c_type, 'Prueba del script 26A', p_message, p_param);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END call_notice;

    FUNCTION notices_of_test RETURN NUMBER
    IS
        v_total NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_total
        FROM CP_NOTIFICACION
        WHERE id_notificacion > v_notif_antes
          AND tipo_notificacion = c_type;
        RETURN v_total;
    END notices_of_test;

    FUNCTION contacts_of_test RETURN NUMBER
    IS
        v_total NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_total
        FROM CP_CONTACTO
        WHERE LOWER(valor_contacto) = v_mail;
        RETURN v_total;
    END contacts_of_test;

BEGIN

    v_mail := 'aviso.prueba.' || v_stamp || '@ejemplo.com';

    SELECT NVL(MAX(id_bitacora_error), 0) INTO v_antes FROM CP_BITACORA_ERROR;
    SELECT NVL(MAX(id_notificacion), 0) INTO v_notif_antes FROM CP_NOTIFICACION;

    PKG_CP_AVISO.set_enabled(TRUE);

    SELECT COUNT(*) INTO v_count
    FROM user_objects
    WHERE object_name = 'PKG_CP_AVISO' AND status = 'VALID';

    reportar('1. PKG_CP_AVISO compila (especificacion y cuerpo VALID)',
             v_count = 2);

    -- ------------------------------------------------------------
    -- A. Ajuste del texto al limite de encolar
    -- ------------------------------------------------------------
    reportar('2. Un texto corto pasa igual',
             PKG_CP_AVISO.fit_text(TO_CLOB('Cierre del dia')) = 'Cierre del dia');

    DBMS_LOB.CREATETEMPORARY(v_long, TRUE);
    FOR i IN 1 .. 1000 LOOP
        DBMS_LOB.APPEND(v_long, TO_CLOB(RPAD('Linea ' || i || ' del aviso largo ', 40, '.') || CHR(10)));
    END LOOP;

    v_fit := PKG_CP_AVISO.fit_text(v_long);

    reportar('3. Un texto de 41 000 caracteres se recorta bajo el limite y lo avisa',
             LENGTHB(v_fit) <= 32000
             AND INSTR(v_fit, 'mensaje recortado') > 0
             AND INSTR(v_fit, 'Linea 1 del aviso largo') = 1);

    -- ------------------------------------------------------------
    -- B. Avisos apagados
    -- ------------------------------------------------------------
    PKG_CP_AVISO.set_enabled(FALSE);
    v_called := call_notice(TO_CLOB('No debe encolarse'), c_param);
    v_status := PKG_CP_AVISO.last_status;
    PKG_CP_AVISO.set_enabled(TRUE);

    reportar('4. Con los avisos apagados no se encola nada',
             v_called AND v_status = 'DESACTIVADO' AND notices_of_test = 0);

    -- ------------------------------------------------------------
    -- C. Un aviso que falla no interrumpe a quien avisa
    -- ------------------------------------------------------------
    v_called := call_notice(TO_CLOB('Sin parametro'), 'CORREO_PRUEBA_INEXISTENTE');

    SELECT COUNT(*) INTO v_count
    FROM CP_BITACORA_ERROR
    WHERE id_bitacora_error > v_antes
      AND modulo = 'PARAMETRO'
      AND codigo_error = -20210;

    reportar('5. Sin el parametro el aviso falla sin lanzar error y queda en la bitacora',
             v_called AND PKG_CP_AVISO.last_status = 'FALLIDO' AND v_count = 1);

    -- Parametro de prueba con un valor en blanco (la tabla no acepta NULL)
    INSERT INTO CP_PARAMETRO
        (codigo_parametro, modulo, tipo_dato, es_cifrado, valor, descripcion)
    VALUES
        (c_param, 'NOTIFICACION', 'TEXTO', 'N', '   ', 'Correo de prueba del script 26A');

    v_called := call_notice(TO_CLOB('Correo en blanco'), c_param);

    SELECT COUNT(*) INTO v_count
    FROM CP_BITACORA_ERROR
    WHERE id_bitacora_error > v_antes
      AND modulo = 'AVISO'
      AND codigo_error = -20340;

    reportar('6. Con el correo en blanco da -20340 una sola vez en la bitacora',
             v_called AND PKG_CP_AVISO.last_status = 'FALLIDO' AND v_count = 1);

    SELECT COUNT(*) INTO v_count
    FROM CP_PARAMETRO WHERE codigo_parametro = c_param;

    reportar('7. El fallo deshace solo lo del aviso: lo previo de la transaccion sigue',
             v_count = 1);

    -- ------------------------------------------------------------
    -- D. Encolar de verdad (depende del modulo de Cipriano)
    -- ------------------------------------------------------------
    UPDATE CP_PARAMETRO SET valor = v_mail WHERE codigo_parametro = c_param;

    SELECT COUNT(*) INTO v_valid
    FROM user_objects
    WHERE object_name = 'PKG_CP_NOTIFICACIONES'
      AND object_type IN ('PACKAGE', 'PACKAGE BODY')
      AND status = 'VALID';

    SELECT COUNT(*) INTO v_config
    FROM CP_CONFIGURACION_CORREO WHERE activo = 'S';

    v_ready := v_valid = 2 AND v_config > 0;

    DBMS_OUTPUT.PUT_LINE('   modulo de correo: ' || v_valid || ' de 2 objetos VALID, '
                         || v_config || ' configuracion(es) activa(s)');

    v_called := call_notice(v_long, c_param);
    v_status := PKG_CP_AVISO.last_status;

    IF v_ready THEN
        reportar('8. Con el modulo de correo listo el aviso queda ENCOLADO',
                 v_called AND v_status = 'ENCOLADO');

        SELECT COUNT(*) INTO v_count
        FROM CP_CONTACTO c
        JOIN CP_DESTINATARIO_NOTIFICACION d
          ON d.id_contacto = c.id_contacto
        WHERE LOWER(c.valor_contacto) = v_mail
          AND d.activo = 'S';

        reportar('9. Registra el contacto y el destinatario del correo nuevo',
                 v_count = 1);

        SELECT COUNT(*) INTO v_count
        FROM CP_NOTIFICACION n
        JOIN CP_NOTIFICACION_DESTINATARIO nd
          ON nd.id_notificacion = n.id_notificacion
        JOIN CP_DESTINATARIO_NOTIFICACION d
          ON d.id_destinatario = nd.id_destinatario
        JOIN CP_CONTACTO c
          ON c.id_contacto = d.id_contacto
        WHERE n.id_notificacion > v_notif_antes
          AND n.tipo_notificacion = c_type
          AND nd.estado_envio = 'PENDIENTE'
          AND LOWER(c.valor_contacto) = v_mail
          AND DBMS_LOB.INSTR(n.mensaje, 'mensaje recortado') > 0;

        reportar('10. Queda PENDIENTE para ese correo y con el mensaje recortado',
                 v_count = 1);
    ELSE
        reportar('8. Sin el modulo de correo listo falla sin interrumpir ni dejar datos',
                 v_called AND v_status = 'FALLIDO'
                 AND contacts_of_test = 0 AND notices_of_test = 0);
        omitir('9. Registra el contacto y el destinatario del correo nuevo',
               'modulo de correo sin instalar o sin configuracion activa');
        omitir('10. Queda PENDIENTE para ese correo y con el mensaje recortado',
               'modulo de correo sin instalar o sin configuracion activa');
    END IF;

    -- ------------------------------------------------------------
    -- E. Limpieza
    -- ------------------------------------------------------------
    ROLLBACK;

    SELECT COUNT(*) INTO v_count
    FROM CP_PARAMETRO WHERE codigo_parametro = c_param;

    reportar('11. El ROLLBACK deja la base sin el parametro, el contacto ni el aviso',
             v_count = 0 AND contacts_of_test = 0 AND notices_of_test = 0);

    DELETE FROM CP_BITACORA_ERROR
    WHERE id_bitacora_error > v_antes
      AND modulo IN ('AVISO', 'PARAMETRO');
    COMMIT;

    DBMS_LOB.FREETEMPORARY(v_long);

    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'Resultado: ' || v_ok || ' OK, '
                         || v_falla || ' FALLA, ' || v_omitida || ' omitida(s)'
                         || CASE WHEN v_omitida > 0
                                 THEN ' (no son fallas: falta el modulo de correo o su configuracion)'
                            END);

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        PKG_CP_AVISO.set_enabled(TRUE);
        DBMS_OUTPUT.PUT_LINE('ERROR en las pruebas: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        RAISE;
END;
/

-- ============================================================
-- 4. CONSULTAS PARA LA DEFENSA
-- ============================================================
-- Correo que reciben los avisos (lo carga el modulo de notificaciones):
--   SELECT codigo_parametro, valor FROM CP_PARAMETRO
--   WHERE codigo_parametro = 'CORREO_ALERTAS_BD';
-- Avisos de negocio en cola o enviados:
--   SELECT n.id_notificacion, n.tipo_notificacion, n.asunto,
--          nd.estado_envio, nd.fecha_envio, nd.detalle_error
--   FROM CP_NOTIFICACION n
--   JOIN CP_NOTIFICACION_DESTINATARIO nd
--     ON nd.id_notificacion = n.id_notificacion
--   WHERE n.tipo_notificacion IN ('CIERRE_DIARIO', 'REPORTE_INVENTARIO',
--                                 'PREMIACION_CLIENTES')
--   ORDER BY n.id_notificacion DESC;
-- Avisos que no se pudieron encolar:
--   SELECT fecha_hora, codigo_error, mensaje_error
--   FROM CP_BITACORA_ERROR WHERE modulo = 'AVISO'
--   ORDER BY id_bitacora_error DESC;
