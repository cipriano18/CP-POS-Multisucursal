-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- BASE DE DATOS: Oracle 21c
-- SCRIPT: 15_seguridad_paquetes.sql
-- DESCRIPCION: Paquetes PKG_CP_ERROR (registro de errores),
--              PKG_CP_CRIPTO (cifrado AES-256), PKG_CP_PARAMETRO
--              (parametros), PKG_CP_SEGURIDAD (claves de roles),
--              PKG_CP_CLAVE_ROL y PKG_CP_SESION (activacion de
--              roles) con llaves iniciales y pruebas.
--
-- EJECUTAR COMO: CP_POS en XEPDB1 (despues de los scripts 12 y 14)
-- ============================================================

-- ============================================================
-- 1. PAQUETE PKG_CP_ERROR (ESPECIFICACION)
-- ============================================================
-- Registra errores en CP_BITACORA_ERROR sin que un ROLLBACK los borre
-- y permite registrar y lanzar un error propio en un solo paso.
-- Los errores propios (-20200 a -20299) no se vuelven a registrar.

CREATE OR REPLACE PACKAGE PKG_CP_ERROR AUTHID DEFINER AS

    PROCEDURE registrar(
        p_modulo  IN VARCHAR2,
        p_codigo  IN NUMBER,
        p_mensaje IN VARCHAR2,
        p_detalle IN CLOB DEFAULT NULL
    );

    PROCEDURE registrar_excepcion(
        p_modulo   IN VARCHAR2,
        p_contexto IN VARCHAR2 DEFAULT NULL
    );

    PROCEDURE lanzar(
        p_modulo  IN VARCHAR2,
        p_codigo  IN NUMBER,
        p_mensaje IN VARCHAR2,
        p_detalle IN VARCHAR2 DEFAULT NULL
    );

    PROCEDURE registrar_inesperado(
        p_modulo   IN VARCHAR2,
        p_contexto IN VARCHAR2 DEFAULT NULL
    );

END PKG_CP_ERROR;
/

-- ============================================================
-- 2. PAQUETE PKG_CP_ERROR (CUERPO)
-- ============================================================
-- Usa una transaccion autonoma y nunca lanza excepcion al registrar.

CREATE OR REPLACE PACKAGE BODY PKG_CP_ERROR AS

    c_largo_modulo  CONSTANT PLS_INTEGER := 100;
    c_largo_mensaje CONSTANT PLS_INTEGER := 1000;

    PROCEDURE registrar(
        p_modulo  IN VARCHAR2,
        p_codigo  IN NUMBER,
        p_mensaje IN VARCHAR2,
        p_detalle IN CLOB DEFAULT NULL
    )
    IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN

        INSERT INTO CP_BITACORA_ERROR (
            modulo,
            codigo_error,
            mensaje_error,
            detalle_error
        )
        VALUES (
            SUBSTR(p_modulo, 1, c_largo_modulo),
            p_codigo,
            SUBSTR(NVL(p_mensaje, '(sin mensaje)'), 1, c_largo_mensaje),
            p_detalle
        );

        COMMIT;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
    END registrar;


    PROCEDURE registrar_excepcion(
        p_modulo   IN VARCHAR2,
        p_contexto IN VARCHAR2 DEFAULT NULL
    )
    IS
    BEGIN

        registrar(
            p_modulo,
            SQLCODE,
            SQLERRM,
            NVL(p_contexto, '-')
                || CHR(10)
                || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
        );

    END registrar_excepcion;


    PROCEDURE lanzar(
        p_modulo  IN VARCHAR2,
        p_codigo  IN NUMBER,
        p_mensaje IN VARCHAR2,
        p_detalle IN VARCHAR2 DEFAULT NULL
    )
    IS
    BEGIN

        registrar(p_modulo, p_codigo, p_mensaje, p_detalle);
        RAISE_APPLICATION_ERROR(p_codigo, p_mensaje);

    END lanzar;


    PROCEDURE registrar_inesperado(
        p_modulo   IN VARCHAR2,
        p_contexto IN VARCHAR2 DEFAULT NULL
    )
    IS
    BEGIN

        IF SQLCODE NOT BETWEEN -20299 AND -20200 THEN
            registrar_excepcion(p_modulo, p_contexto);
        END IF;

    END registrar_inesperado;

END PKG_CP_ERROR;
/

-- ============================================================
-- 3. PAQUETE PKG_CP_CRIPTO (ESPECIFICACION)
-- ============================================================
-- Cifra y descifra textos con la llave activa de CP_LLAVE_CIFRADO.

CREATE OR REPLACE PACKAGE PKG_CP_CRIPTO AUTHID DEFINER AS

    PROCEDURE generar_llave;

    FUNCTION cifrar(
        p_texto IN VARCHAR2
    ) RETURN RAW;

    FUNCTION descifrar(
        p_bloque IN RAW
    ) RETURN VARCHAR2;

END PKG_CP_CRIPTO;
/

-- ============================================================
-- 4. PAQUETE PKG_CP_CRIPTO (CUERPO)
-- ============================================================
-- AES-256, modo CBC, relleno PKCS5. La lectura de la llave es privada.

CREATE OR REPLACE PACKAGE BODY PKG_CP_CRIPTO AS

    c_modulo CONSTANT VARCHAR2(20) := 'CRIPTO';

    c_modo CONSTANT PLS_INTEGER :=
        DBMS_CRYPTO.ENCRYPT_AES256
        + DBMS_CRYPTO.CHAIN_CBC
        + DBMS_CRYPTO.PAD_PKCS5;

    c_largo_llave     CONSTANT PLS_INTEGER := 32;
    c_largo_id        CONSTANT PLS_INTEGER := 4;
    c_largo_iv        CONSTANT PLS_INTEGER := 16;
    c_largo_minimo    CONSTANT PLS_INTEGER := 36;
    c_max_bytes_texto CONSTANT PLS_INTEGER := 1900;

    c_err_sin_llave_activa  CONSTANT PLS_INTEGER := -20200;
    c_err_texto_invalido    CONSTANT PLS_INTEGER := -20201;
    c_err_no_descifra       CONSTANT PLS_INTEGER := -20202;
    c_err_llave_inexistente CONSTANT PLS_INTEGER := -20203;


    FUNCTION id_llave_activa
    RETURN PLS_INTEGER
    IS
        v_id PLS_INTEGER;
    BEGIN

        SELECT id_llave_cifrado
        INTO v_id
        FROM CP_LLAVE_CIFRADO
        WHERE activa = 'S';

        RETURN v_id;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_sin_llave_activa,
                'No existe una llave de cifrado activa.'
            );
    END id_llave_activa;


    FUNCTION leer_llave(
        p_id IN PLS_INTEGER
    ) RETURN RAW
    IS
        v_llave RAW(32);
    BEGIN

        SELECT llave
        INTO v_llave
        FROM CP_LLAVE_CIFRADO
        WHERE id_llave_cifrado = p_id;

        RETURN v_llave;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_llave_inexistente,
                'La llave indicada por el bloque no existe.'
            );
    END leer_llave;


    PROCEDURE generar_llave
    IS
    BEGIN

        UPDATE CP_LLAVE_CIFRADO
        SET activa = 'N'
        WHERE activa = 'S';

        INSERT INTO CP_LLAVE_CIFRADO (llave, activa)
        VALUES (DBMS_CRYPTO.RANDOMBYTES(c_largo_llave), 'S');

    EXCEPTION
        WHEN OTHERS THEN
            PKG_CP_ERROR.registrar_excepcion(c_modulo, 'generar_llave');
            RAISE;
    END generar_llave;


    FUNCTION cifrar(
        p_texto IN VARCHAR2
    ) RETURN RAW
    IS
        v_id      PLS_INTEGER;
        v_llave   RAW(32);
        v_iv      RAW(16);
        v_cifrado RAW(2000);
    BEGIN

        IF p_texto IS NULL OR LENGTHB(p_texto) > c_max_bytes_texto THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_texto_invalido,
                'El texto a cifrar esta vacio o supera '
                    || c_max_bytes_texto || ' bytes.'
            );
        END IF;

        v_id    := id_llave_activa;
        v_llave := leer_llave(v_id);

        v_iv := DBMS_CRYPTO.RANDOMBYTES(c_largo_iv);

        v_cifrado := DBMS_CRYPTO.ENCRYPT(
            src => UTL_I18N.STRING_TO_RAW(p_texto, 'AL32UTF8'),
            typ => c_modo,
            key => v_llave,
            iv  => v_iv
        );

        RETURN UTL_RAW.CONCAT(
            UTL_RAW.CAST_FROM_BINARY_INTEGER(v_id),
            v_iv,
            v_cifrado
        );

    END cifrar;


    FUNCTION descifrar(
        p_bloque IN RAW
    ) RETURN VARCHAR2
    IS
        v_id      PLS_INTEGER;
        v_llave   RAW(32);
        v_iv      RAW(16);
        v_cifrado RAW(2000);
        v_plano   RAW(2000);
    BEGIN

        IF NVL(UTL_RAW.LENGTH(p_bloque), 0) < c_largo_minimo THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_no_descifra,
                'El bloque cifrado no es valido.'
            );
        END IF;

        v_id      := UTL_RAW.CAST_TO_BINARY_INTEGER(
                         UTL_RAW.SUBSTR(p_bloque, 1, c_largo_id));
        v_iv      := UTL_RAW.SUBSTR(p_bloque, c_largo_id + 1, c_largo_iv);
        v_cifrado := UTL_RAW.SUBSTR(p_bloque, c_largo_id + c_largo_iv + 1);

        v_llave := leer_llave(v_id);

        BEGIN
            v_plano := DBMS_CRYPTO.DECRYPT(
                src => v_cifrado,
                typ => c_modo,
                key => v_llave,
                iv  => v_iv
            );
            RETURN UTL_I18N.RAW_TO_CHAR(v_plano, 'AL32UTF8');
        EXCEPTION
            WHEN OTHERS THEN
                PKG_CP_ERROR.lanzar(
                    c_modulo,
                    c_err_no_descifra,
                    'No se pudo descifrar el bloque.',
                    SQLERRM
                );
        END;

    END descifrar;

END PKG_CP_CRIPTO;
/

-- ============================================================
-- 5. PAQUETE PKG_CP_PARAMETRO (ESPECIFICACION)
-- ============================================================
-- Lee y guarda los valores de CP_PARAMETRO, descifrando los sensibles.

CREATE OR REPLACE PACKAGE PKG_CP_PARAMETRO AUTHID DEFINER AS

    FUNCTION obtener_texto(
        p_codigo IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION obtener_numero(
        p_codigo IN VARCHAR2
    ) RETURN NUMBER;

    PROCEDURE guardar(
        p_codigo IN VARCHAR2,
        p_valor  IN VARCHAR2
    );

    PROCEDURE guardar_cifrado(
        p_codigo      IN VARCHAR2,
        p_secreto     IN VARCHAR2,
        p_modulo      IN VARCHAR2 DEFAULT 'SEGURIDAD',
        p_descripcion IN VARCHAR2 DEFAULT NULL
    );

END PKG_CP_PARAMETRO;
/

-- ============================================================
-- 6. PAQUETE PKG_CP_PARAMETRO (CUERPO)
-- ============================================================
-- Valida el tipo del valor y no confirma la transaccion del llamador.

CREATE OR REPLACE PACKAGE BODY PKG_CP_PARAMETRO AS

    c_modulo CONSTANT VARCHAR2(20) := 'PARAMETRO';

    c_max_bytes_valor CONSTANT PLS_INTEGER := 500;

    c_err_no_existe       CONSTANT PLS_INTEGER := -20210;
    c_err_tipo_invalido   CONSTANT PLS_INTEGER := -20211;
    c_err_modo_incorrecto CONSTANT PLS_INTEGER := -20212;
    c_err_valor_invalido  CONSTANT PLS_INTEGER := -20213;


    FUNCTION normalizar(
        p_codigo IN VARCHAR2
    ) RETURN VARCHAR2
    IS
        v_codigo VARCHAR2(60) := UPPER(TRIM(p_codigo));
    BEGIN

        IF v_codigo IS NULL THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_valor_invalido,
                'El codigo del parametro esta vacio.'
            );
        END IF;

        RETURN v_codigo;

    END normalizar;


    FUNCTION leer_fila(
        p_codigo IN VARCHAR2
    ) RETURN CP_PARAMETRO%ROWTYPE
    IS
        v_codigo VARCHAR2(60) := normalizar(p_codigo);
        v_fila   CP_PARAMETRO%ROWTYPE;
    BEGIN

        SELECT *
        INTO v_fila
        FROM CP_PARAMETRO
        WHERE codigo_parametro = v_codigo;

        RETURN v_fila;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_no_existe,
                'El parametro ' || v_codigo || ' no existe.'
            );
    END leer_fila;


    FUNCTION convertir_numero(
        p_codigo IN VARCHAR2,
        p_texto  IN VARCHAR2
    ) RETURN NUMBER
    IS
        v_numero NUMBER;
    BEGIN

        BEGIN
            v_numero := TO_NUMBER(
                p_texto,
                '999999999999999D999999',
                'NLS_NUMERIC_CHARACTERS=''.,'''
            );
        EXCEPTION
            WHEN OTHERS THEN
                PKG_CP_ERROR.lanzar(
                    c_modulo,
                    c_err_tipo_invalido,
                    'El valor del parametro ' || p_codigo
                        || ' no es un numero valido.'
                );
        END;

        RETURN v_numero;

    END convertir_numero;


    FUNCTION valor_en_claro(
        p_fila IN CP_PARAMETRO%ROWTYPE
    ) RETURN VARCHAR2
    IS
    BEGIN

        IF p_fila.es_cifrado = 'S' THEN
            RETURN PKG_CP_CRIPTO.descifrar(p_fila.valor_cifrado);
        END IF;

        RETURN p_fila.valor;

    END valor_en_claro;


    FUNCTION obtener_texto(
        p_codigo IN VARCHAR2
    ) RETURN VARCHAR2
    IS
        v_fila CP_PARAMETRO%ROWTYPE := leer_fila(p_codigo);
    BEGIN

        RETURN valor_en_claro(v_fila);

    EXCEPTION
        WHEN OTHERS THEN
            PKG_CP_ERROR.registrar_inesperado(c_modulo);
            RAISE;
    END obtener_texto;


    FUNCTION obtener_numero(
        p_codigo IN VARCHAR2
    ) RETURN NUMBER
    IS
        v_fila CP_PARAMETRO%ROWTYPE := leer_fila(p_codigo);
    BEGIN

        IF v_fila.tipo_dato <> 'NUMERO' THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_tipo_invalido,
                'El parametro ' || v_fila.codigo_parametro
                    || ' no es de tipo NUMERO.'
            );
        END IF;

        RETURN convertir_numero(v_fila.codigo_parametro, valor_en_claro(v_fila));

    EXCEPTION
        WHEN OTHERS THEN
            PKG_CP_ERROR.registrar_inesperado(c_modulo);
            RAISE;
    END obtener_numero;


    PROCEDURE guardar(
        p_codigo IN VARCHAR2,
        p_valor  IN VARCHAR2
    )
    IS
        v_fila   CP_PARAMETRO%ROWTYPE := leer_fila(p_codigo);
        v_numero NUMBER;
    BEGIN

        IF v_fila.es_cifrado = 'S' THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_modo_incorrecto,
                'El parametro ' || v_fila.codigo_parametro
                    || ' es cifrado: use guardar_cifrado.'
            );
        END IF;

        IF p_valor IS NULL OR LENGTHB(p_valor) > c_max_bytes_valor THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_valor_invalido,
                'El valor de ' || v_fila.codigo_parametro
                    || ' esta vacio o supera ' || c_max_bytes_valor || ' bytes.'
            );
        END IF;

        IF v_fila.tipo_dato = 'NUMERO' THEN
            v_numero := convertir_numero(v_fila.codigo_parametro, p_valor);
        END IF;

        UPDATE CP_PARAMETRO
        SET valor = p_valor,
            fecha_modificacion = SYSTIMESTAMP
        WHERE id_parametro = v_fila.id_parametro;

    EXCEPTION
        WHEN OTHERS THEN
            PKG_CP_ERROR.registrar_inesperado(c_modulo);
            RAISE;
    END guardar;


    PROCEDURE guardar_cifrado(
        p_codigo      IN VARCHAR2,
        p_secreto     IN VARCHAR2,
        p_modulo      IN VARCHAR2 DEFAULT 'SEGURIDAD',
        p_descripcion IN VARCHAR2 DEFAULT NULL
    )
    IS
        v_codigo VARCHAR2(60) := normalizar(p_codigo);
        v_bloque RAW(2000);
        v_existe PLS_INTEGER;
    BEGIN

        v_bloque := PKG_CP_CRIPTO.cifrar(p_secreto);

        UPDATE CP_PARAMETRO
        SET valor_cifrado = v_bloque,
            fecha_modificacion = SYSTIMESTAMP
        WHERE codigo_parametro = v_codigo
          AND es_cifrado = 'S';

        IF SQL%ROWCOUNT = 0 THEN

            SELECT COUNT(*)
            INTO v_existe
            FROM CP_PARAMETRO
            WHERE codigo_parametro = v_codigo;

            IF v_existe > 0 THEN
                PKG_CP_ERROR.lanzar(
                    c_modulo,
                    c_err_modo_incorrecto,
                    'El parametro ' || v_codigo || ' no es cifrado: use guardar.'
                );
            END IF;

            INSERT INTO CP_PARAMETRO (
                codigo_parametro,
                modulo,
                tipo_dato,
                es_cifrado,
                valor_cifrado,
                descripcion
            )
            VALUES (
                v_codigo,
                UPPER(p_modulo),
                'TEXTO',
                'S',
                v_bloque,
                NVL(p_descripcion, 'Valor sensible cifrado.')
            );

        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            PKG_CP_ERROR.registrar_inesperado(c_modulo);
            RAISE;
    END guardar_cifrado;

END PKG_CP_PARAMETRO;
/

-- ============================================================
-- 7. PAQUETE PKG_CP_CLAVE_ROL (ESPECIFICACION)
-- ============================================================
-- Entrega la clave de un rol solo al paquete PKG_CP_SESION.

CREATE OR REPLACE PACKAGE PKG_CP_CLAVE_ROL AUTHID DEFINER AS

    FUNCTION codigo_parametro(
        p_rol IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION obtener(
        p_rol IN VARCHAR2
    ) RETURN VARCHAR2
    ACCESSIBLE BY (PACKAGE PKG_CP_SESION);

END PKG_CP_CLAVE_ROL;
/

-- ============================================================
-- 8. PAQUETE PKG_CP_CLAVE_ROL (CUERPO)
-- ============================================================
-- Verifica que el usuario conectado tenga el rol antes de descifrar.

CREATE OR REPLACE PACKAGE BODY PKG_CP_CLAVE_ROL AS

    c_modulo CONSTANT VARCHAR2(20) := 'CLAVE_ROL';

    c_prefijo CONSTANT VARCHAR2(10) := 'CLAVE_';

    c_err_sin_rol CONSTANT PLS_INTEGER := -20223;


    FUNCTION codigo_parametro(
        p_rol IN VARCHAR2
    ) RETURN VARCHAR2
    IS
    BEGIN

        RETURN c_prefijo || UPPER(TRIM(p_rol));

    END codigo_parametro;


    FUNCTION obtener(
        p_rol IN VARCHAR2
    ) RETURN VARCHAR2
    ACCESSIBLE BY (PACKAGE PKG_CP_SESION)
    IS
        v_rol     VARCHAR2(30)  := UPPER(TRIM(p_rol));
        v_usuario VARCHAR2(128) := SYS_CONTEXT('USERENV', 'SESSION_USER');
        v_existe  PLS_INTEGER;
    BEGIN

        SELECT COUNT(*)
        INTO v_existe
        FROM SYS.DBA_ROLE_PRIVS
        WHERE grantee = v_usuario
          AND granted_role = v_rol;

        IF v_existe = 0 THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_sin_rol,
                'El usuario ' || v_usuario
                    || ' no tiene concedido el rol solicitado.'
            );
        END IF;

        RETURN PKG_CP_PARAMETRO.obtener_texto(codigo_parametro(v_rol));

    EXCEPTION
        WHEN OTHERS THEN
            PKG_CP_ERROR.registrar_inesperado(c_modulo);
            RAISE;
    END obtener;

END PKG_CP_CLAVE_ROL;
/

-- ============================================================
-- 9. PAQUETE PKG_CP_SEGURIDAD (ESPECIFICACION)
-- ============================================================
-- Asigna claves a los roles de negocio y las guarda cifradas.

CREATE OR REPLACE PACKAGE PKG_CP_SEGURIDAD AUTHID CURRENT_USER AS

    PROCEDURE asignar_clave_rol(
        p_rol   IN VARCHAR2,
        p_clave IN VARCHAR2 DEFAULT NULL
    );

    PROCEDURE asignar_claves_roles;

END PKG_CP_SEGURIDAD;
/

-- ============================================================
-- 10. PAQUETE PKG_CP_SEGURIDAD (CUERPO)
-- ============================================================
-- Sin clave indicada genera una aleatoria. El ALTER ROLE confirma
-- la transaccion (DDL) y si falla se deshace el guardado.
-- La clave mide maximo 30 caracteres (limite de Oracle).

CREATE OR REPLACE PACKAGE BODY PKG_CP_SEGURIDAD AS

    c_modulo CONSTANT VARCHAR2(20) := 'SEGURIDAD';

    c_roles CONSTANT VARCHAR2(200) :=
        ' ROL_CP_GERENTE ROL_CP_JEFE_DEPARTAMENTO'
        || ' ROL_CP_JEFE_PROVEEDURIA ROL_CP_DIGITADOR ';

    c_patron_clave CONSTANT VARCHAR2(40) := '^[A-Za-z0-9_#$.-]{8,30}$';

    c_err_rol_invalido   CONSTANT PLS_INTEGER := -20220;
    c_err_clave_invalida CONSTANT PLS_INTEGER := -20221;
    c_err_no_asigna      CONSTANT PLS_INTEGER := -20222;


    PROCEDURE validar_rol(
        p_rol IN VARCHAR2
    )
    IS
    BEGIN

        IF p_rol IS NULL OR INSTR(c_roles, ' ' || p_rol || ' ') = 0 THEN
            CP_POS.PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_rol_invalido,
                'El rol indicado no es un rol de negocio valido.'
            );
        END IF;

    END validar_rol;


    FUNCTION generar_clave
    RETURN VARCHAR2
    IS
    BEGIN

        RETURN RAWTOHEX(DBMS_CRYPTO.RANDOMBYTES(15));

    END generar_clave;


    PROCEDURE asignar_clave_rol(
        p_rol   IN VARCHAR2,
        p_clave IN VARCHAR2 DEFAULT NULL
    )
    IS
        v_rol   VARCHAR2(30) := UPPER(TRIM(p_rol));
        v_clave VARCHAR2(64);
    BEGIN

        validar_rol(v_rol);

        v_clave := NVL(p_clave, generar_clave);

        IF NOT REGEXP_LIKE(v_clave, c_patron_clave) THEN
            CP_POS.PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_clave_invalida,
                'La clave indicada no cumple el formato permitido.'
            );
        END IF;

        CP_POS.PKG_CP_PARAMETRO.guardar_cifrado(
            CP_POS.PKG_CP_CLAVE_ROL.codigo_parametro(v_rol),
            v_clave,
            'SEGURIDAD',
            'Clave cifrada del rol ' || v_rol || '.'
        );

        BEGIN
            EXECUTE IMMEDIATE 'ALTER ROLE '
                || DBMS_ASSERT.SIMPLE_SQL_NAME(v_rol)
                || ' IDENTIFIED BY "' || v_clave || '"';
        EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK;
                CP_POS.PKG_CP_ERROR.lanzar(
                    c_modulo,
                    c_err_no_asigna,
                    'No se pudo asignar la clave al rol ' || v_rol || '.',
                    SQLERRM
                );
        END;

    EXCEPTION
        WHEN OTHERS THEN
            CP_POS.PKG_CP_ERROR.registrar_inesperado(c_modulo);
            RAISE;
    END asignar_clave_rol;


    PROCEDURE asignar_claves_roles
    IS
    BEGIN

        FOR i IN 1 .. REGEXP_COUNT(c_roles, '[^ ]+') LOOP
            asignar_clave_rol(REGEXP_SUBSTR(c_roles, '[^ ]+', 1, i));
        END LOOP;

    END asignar_claves_roles;

END PKG_CP_SEGURIDAD;
/

-- ============================================================
-- 11. PAQUETE PKG_CP_SESION (ESPECIFICACION)
-- ============================================================
-- Activa un rol de negocio en la sesion del usuario que lo llama.

CREATE OR REPLACE PACKAGE PKG_CP_SESION AUTHID CURRENT_USER AS

    PROCEDURE activar_rol(
        p_rol IN VARCHAR2
    );

END PKG_CP_SESION;
/

-- ============================================================
-- 12. PAQUETE PKG_CP_SESION (CUERPO)
-- ============================================================
-- Derechos del invocador: solo asi se puede ejecutar SET ROLE.

CREATE OR REPLACE PACKAGE BODY PKG_CP_SESION AS

    c_rol_base CONSTANT VARCHAR2(30) := 'ROL_CP_CONEXION';

    c_err_no_activa CONSTANT PLS_INTEGER := -20224;


    PROCEDURE activar_rol(
        p_rol IN VARCHAR2
    )
    IS
        v_rol   VARCHAR2(30) := UPPER(TRIM(p_rol));
        v_clave VARCHAR2(200);
    BEGIN

        v_clave := CP_POS.PKG_CP_CLAVE_ROL.obtener(v_rol);

        BEGIN
            DBMS_SESSION.SET_ROLE(
                c_rol_base || ', '
                    || DBMS_ASSERT.SIMPLE_SQL_NAME(v_rol)
                    || ' IDENTIFIED BY "' || v_clave || '"'
            );
        EXCEPTION
            WHEN OTHERS THEN
                RAISE_APPLICATION_ERROR(
                    c_err_no_activa,
                    'No se pudo activar el rol ' || v_rol || ': ' || SQLERRM
                );
        END;

    END activar_rol;

END PKG_CP_SESION;
/

-- ============================================================
-- 13. PRIVILEGIOS DE EJECUCION PARA LOS USUARIOS
-- ============================================================
-- Todo usuario con el rol base puede activar sus roles de negocio.

GRANT EXECUTE ON PKG_CP_SESION TO ROL_CP_CONEXION;

GRANT EXECUTE ON PKG_CP_CLAVE_ROL TO ROL_CP_CONEXION;

-- ============================================================
-- 14. VERIFICACION
-- ============================================================
-- Los paquetes deben estar VALID y user_errors no debe devolver filas.

SELECT object_name, object_type, status
FROM user_objects
WHERE object_name LIKE 'PKG_CP_%'
ORDER BY object_name, object_type;

SELECT name, type, line, text
FROM user_errors
WHERE name LIKE 'PKG_CP_%';

-- ============================================================
-- 15. LLAVE INICIAL
-- ============================================================
-- Se crea solo si la tabla CP_LLAVE_CIFRADO esta vacia.

SET SERVEROUTPUT ON SIZE UNLIMITED

DECLARE
    v_total PLS_INTEGER;
BEGIN

    SELECT COUNT(*) INTO v_total FROM CP_LLAVE_CIFRADO;

    IF v_total = 0 THEN
        PKG_CP_CRIPTO.generar_llave;
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Llave inicial creada.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Ya existen llaves: no se crea otra.');
    END IF;

END;
/

-- ============================================================
-- 16. CLAVES INICIALES DE LOS ROLES
-- ============================================================
-- Se asignan claves aleatorias solo si faltan las de los 4 roles.

DECLARE
    v_total PLS_INTEGER;
BEGIN

    SELECT COUNT(*)
    INTO v_total
    FROM CP_PARAMETRO
    WHERE codigo_parametro LIKE 'CLAVE\_ROL\_CP\_%' ESCAPE '\';

    IF v_total < 4 THEN
        PKG_CP_SEGURIDAD.asignar_claves_roles;
        DBMS_OUTPUT.PUT_LINE('Claves iniciales de los roles asignadas.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Los roles ya tienen clave: no se asignan otras.');
    END IF;

END;
/

-- ============================================================
-- 17. PRUEBA DE PKG_CP_CRIPTO
-- ============================================================
-- Las 12 pruebas deben salir OK. La rotacion de llave se deshace.

DECLARE
    v_texto    CONSTANT VARCHAR2(30) := 'Gerente#2026';
    v_antes    NUMBER;
    v_errores  NUMBER;
    v_bloque_1 RAW(2000);
    v_bloque_2 RAW(2000);
    v_nuevo    RAW(2000);
    v_basura   VARCHAR2(100);

    PROCEDURE reportar(
        p_prueba IN VARCHAR2,
        p_ok     IN BOOLEAN
    )
    IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(
            RPAD(p_prueba, 58, '.') || CASE WHEN p_ok THEN ' OK' ELSE ' FALLA' END
        );
    END reportar;

    FUNCTION codigo_de(
        p_bloque IN RAW
    ) RETURN NUMBER
    IS
        v_resultado VARCHAR2(100);
    BEGIN
        v_resultado := PKG_CP_CRIPTO.descifrar(p_bloque);
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN SQLCODE;
    END codigo_de;

BEGIN

    SELECT NVL(MAX(id_bitacora_error), 0) INTO v_antes FROM CP_BITACORA_ERROR;

    v_bloque_1 := PKG_CP_CRIPTO.cifrar(v_texto);
    v_bloque_2 := PKG_CP_CRIPTO.cifrar(v_texto);

    reportar('1. El bloque mide 36 bytes (4 + 16 + 16)',
             UTL_RAW.LENGTH(v_bloque_1) = 36);
    reportar('2. Mismo texto, bloques distintos (IV aleatorio)',
             v_bloque_1 <> v_bloque_2);
    reportar('3. Descifra el primer bloque',
             PKG_CP_CRIPTO.descifrar(v_bloque_1) = v_texto);
    reportar('4. Descifra el segundo bloque',
             PKG_CP_CRIPTO.descifrar(v_bloque_2) = v_texto);

    PKG_CP_CRIPTO.generar_llave;
    v_nuevo := PKG_CP_CRIPTO.cifrar(v_texto);

    reportar('5. Tras rotar, el bloque nuevo usa otra llave',
             UTL_RAW.SUBSTR(v_nuevo, 1, 4) <> UTL_RAW.SUBSTR(v_bloque_1, 1, 4));
    reportar('6. Tras rotar, descifra el bloque viejo',
             PKG_CP_CRIPTO.descifrar(v_bloque_1) = v_texto);
    reportar('7. Tras rotar, descifra el bloque nuevo',
             PKG_CP_CRIPTO.descifrar(v_nuevo) = v_texto);

    reportar('8. Bloque demasiado corto da -20202',
             codigo_de(UTL_RAW.SUBSTR(v_bloque_1, 1, 30)) = -20202);
    reportar('9. Bloque con largo invalido da -20202',
             codigo_de(UTL_RAW.CONCAT(v_bloque_1, HEXTORAW('FF'))) = -20202);
    reportar('10. Llave inexistente en el bloque da -20203',
             codigo_de(UTL_RAW.CONCAT(HEXTORAW('7FFFFFFF'),
                                      UTL_RAW.SUBSTR(v_bloque_1, 5))) = -20203);

    BEGIN
        v_basura := RAWTOHEX(PKG_CP_CRIPTO.cifrar(NULL));
        reportar('11. Cifrar texto nulo da -20201', FALSE);
    EXCEPTION
        WHEN OTHERS THEN
            reportar('11. Cifrar texto nulo da -20201', SQLCODE = -20201);
    END;

    ROLLBACK;

    SELECT COUNT(*)
    INTO v_errores
    FROM CP_BITACORA_ERROR
    WHERE id_bitacora_error > v_antes
      AND modulo = 'CRIPTO';

    reportar('12. Los 4 errores quedaron en la bitacora', v_errores = 4);

    DELETE FROM CP_BITACORA_ERROR
    WHERE id_bitacora_error > v_antes
      AND modulo = 'CRIPTO';

    COMMIT;

END;
/

SELECT id_llave_cifrado, activa FROM CP_LLAVE_CIFRADO ORDER BY id_llave_cifrado;

-- ============================================================
-- 18. PRUEBA DE PKG_CP_PARAMETRO
-- ============================================================
-- Las 15 pruebas deben salir OK. Los cambios de la prueba se deshacen.

DECLARE
    v_antes   NUMBER;
    v_errores NUMBER;
    v_filas   NUMBER;
    v_valor   VARCHAR2(100);
    v_cifrado RAW(2000);
    v_claro   VARCHAR2(500);

    PROCEDURE reportar(
        p_prueba IN VARCHAR2,
        p_ok     IN BOOLEAN
    )
    IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(
            RPAD(p_prueba, 58, '.') || CASE WHEN p_ok THEN ' OK' ELSE ' FALLA' END
        );
    END reportar;

    FUNCTION codigo_de(
        p_bloque IN VARCHAR2
    ) RETURN NUMBER
    IS
    BEGIN
        EXECUTE IMMEDIATE p_bloque;
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN SQLCODE;
    END codigo_de;

BEGIN

    SELECT NVL(MAX(id_bitacora_error), 0) INTO v_antes FROM CP_BITACORA_ERROR;

    reportar('1. Lee un numero (UMBRAL_CXC_CLIENTE_PCT = 85)',
             PKG_CP_PARAMETRO.obtener_numero('UMBRAL_CXC_CLIENTE_PCT') = 85);
    reportar('2. Lee el mismo valor como texto',
             PKG_CP_PARAMETRO.obtener_texto('UMBRAL_CXC_CLIENTE_PCT') = '85');
    reportar('3. Acepta el codigo en minusculas',
             PKG_CP_PARAMETRO.obtener_numero('premio_monto_orden') = 100000);

    PKG_CP_PARAMETRO.guardar('PREMIO_MONTO_ORDEN', '150000');
    reportar('4. Guarda un numero y lo lee actualizado',
             PKG_CP_PARAMETRO.obtener_numero('PREMIO_MONTO_ORDEN') = 150000);

    reportar('5. Guardar texto en un numerico da -20211',
             codigo_de(q'[BEGIN PKG_CP_PARAMETRO.guardar('PREMIO_MONTO_ORDEN', 'abc'); END;]') = -20211);
    reportar('6. Parametro inexistente da -20210',
             codigo_de(q'[DECLARE v NUMBER; BEGIN v := PKG_CP_PARAMETRO.obtener_numero('NO_EXISTE'); END;]') = -20210);

    PKG_CP_PARAMETRO.guardar_cifrado('CLAVE_ROL_PRUEBA', 'Gerente#2026');
    reportar('7. Guarda un secreto cifrado y lo lee descifrado',
             PKG_CP_PARAMETRO.obtener_texto('CLAVE_ROL_PRUEBA') = 'Gerente#2026');

    SELECT valor, valor_cifrado
    INTO v_claro, v_cifrado
    FROM CP_PARAMETRO
    WHERE codigo_parametro = 'CLAVE_ROL_PRUEBA';

    reportar('8. En la tabla valor queda vacio y valor_cifrado lleno',
             v_claro IS NULL AND v_cifrado IS NOT NULL);

    PKG_CP_PARAMETRO.guardar_cifrado('CLAVE_ROL_PRUEBA', 'Otra#2026');

    SELECT COUNT(*) INTO v_filas
    FROM CP_PARAMETRO
    WHERE codigo_parametro = 'CLAVE_ROL_PRUEBA';

    reportar('9. Guardar de nuevo actualiza sin duplicar',
             v_filas = 1 AND PKG_CP_PARAMETRO.obtener_texto('CLAVE_ROL_PRUEBA') = 'Otra#2026');

    reportar('10. Pedir como numero un parametro TEXTO da -20211',
             codigo_de(q'[DECLARE v NUMBER; BEGIN v := PKG_CP_PARAMETRO.obtener_numero('CLAVE_ROL_PRUEBA'); END;]') = -20211);
    reportar('11. guardar sobre un parametro cifrado da -20212',
             codigo_de(q'[BEGIN PKG_CP_PARAMETRO.guardar('CLAVE_ROL_PRUEBA', 'x'); END;]') = -20212);
    reportar('12. guardar_cifrado sobre uno en claro da -20212',
             codigo_de(q'[BEGIN PKG_CP_PARAMETRO.guardar_cifrado('UMBRAL_CXC_CLIENTE_PCT', 'x'); END;]') = -20212);
    reportar('13. Guardar un valor nulo da -20213',
             codigo_de(q'[BEGIN PKG_CP_PARAMETRO.guardar('PREMIO_MONTO_ORDEN', NULL); END;]') = -20213);

    SELECT COUNT(*)
    INTO v_errores
    FROM CP_BITACORA_ERROR
    WHERE id_bitacora_error > v_antes
      AND modulo = 'PARAMETRO';

    reportar('14. Los 6 errores quedaron en la bitacora', v_errores = 6);

    ROLLBACK;

    SELECT COUNT(*) INTO v_filas
    FROM CP_PARAMETRO
    WHERE codigo_parametro = 'CLAVE_ROL_PRUEBA';

    reportar('15. El ROLLBACK restauro los datos',
             v_filas = 0
             AND PKG_CP_PARAMETRO.obtener_numero('PREMIO_MONTO_ORDEN') = 100000);

    DELETE FROM CP_BITACORA_ERROR
    WHERE id_bitacora_error > v_antes
      AND modulo = 'PARAMETRO';

    COMMIT;

END;
/

-- ============================================================
-- 19. PRUEBA DE PKG_CP_SEGURIDAD
-- ============================================================
-- Las 8 pruebas deben salir OK. Cambia la clave del rol DIGITADOR.

DECLARE
    v_antes   NUMBER;
    v_errores NUMBER;
    v_filas   NUMBER;
    v_validas NUMBER := 0;
    v_bloque1 RAW(2000);
    v_bloque2 RAW(2000);

    PROCEDURE reportar(
        p_prueba IN VARCHAR2,
        p_ok     IN BOOLEAN
    )
    IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(
            RPAD(p_prueba, 58, '.') || CASE WHEN p_ok THEN ' OK' ELSE ' FALLA' END
        );
    END reportar;

    FUNCTION codigo_de(
        p_bloque IN VARCHAR2
    ) RETURN NUMBER
    IS
    BEGIN
        EXECUTE IMMEDIATE p_bloque;
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN SQLCODE;
    END codigo_de;

BEGIN

    SELECT NVL(MAX(id_bitacora_error), 0) INTO v_antes FROM CP_BITACORA_ERROR;

    SELECT COUNT(*)
    INTO v_filas
    FROM CP_PARAMETRO
    WHERE codigo_parametro LIKE 'CLAVE\_ROL\_CP\_%' ESCAPE '\'
      AND es_cifrado = 'S'
      AND valor IS NULL
      AND valor_cifrado IS NOT NULL;

    reportar('1. Las 4 claves de roles estan guardadas cifradas', v_filas = 4);

    FOR r IN (SELECT codigo_parametro
              FROM CP_PARAMETRO
              WHERE codigo_parametro LIKE 'CLAVE\_ROL\_CP\_%' ESCAPE '\') LOOP
        IF LENGTH(PKG_CP_PARAMETRO.obtener_texto(r.codigo_parametro)) = 30 THEN
            v_validas := v_validas + 1;
        END IF;
    END LOOP;

    reportar('2. Las 4 claves se descifran y miden 30 caracteres', v_validas = 4);

    SELECT valor_cifrado INTO v_bloque1
    FROM CP_PARAMETRO
    WHERE codigo_parametro = 'CLAVE_ROL_CP_DIGITADOR';

    PKG_CP_SEGURIDAD.asignar_clave_rol('rol_cp_digitador');

    SELECT valor_cifrado INTO v_bloque2
    FROM CP_PARAMETRO
    WHERE codigo_parametro = 'CLAVE_ROL_CP_DIGITADOR';

    SELECT COUNT(*)
    INTO v_filas
    FROM CP_PARAMETRO
    WHERE codigo_parametro = 'CLAVE_ROL_CP_DIGITADOR';

    reportar('3. Reasignar cambia la clave sin duplicar la fila',
             v_filas = 1 AND v_bloque1 <> v_bloque2);

    reportar('4. El rol base no admite clave (-20220)',
             codigo_de(q'[BEGIN PKG_CP_SEGURIDAD.asignar_clave_rol('ROL_CP_CONEXION'); END;]') = -20220);
    reportar('5. Un rol inexistente da -20220',
             codigo_de(q'[BEGIN PKG_CP_SEGURIDAD.asignar_clave_rol('DBA'); END;]') = -20220);
    reportar('6. Una clave con caracteres peligrosos da -20221',
             codigo_de(q'[BEGIN PKG_CP_SEGURIDAD.asignar_clave_rol('ROL_CP_GERENTE', 'abc"; DROP USER x; --'); END;]') = -20221);
    reportar('7. Nadie fuera de PKG_CP_SESION lee la clave de un rol',
             codigo_de(q'[DECLARE v VARCHAR2(100); BEGIN v := PKG_CP_CLAVE_ROL.obtener('ROL_CP_GERENTE'); END;]') = -6550);

    SELECT COUNT(*)
    INTO v_errores
    FROM CP_BITACORA_ERROR
    WHERE id_bitacora_error > v_antes
      AND modulo = 'SEGURIDAD';

    reportar('8. Los 3 errores quedaron en la bitacora', v_errores = 3);

    DELETE FROM CP_BITACORA_ERROR
    WHERE id_bitacora_error > v_antes
      AND modulo = 'SEGURIDAD';

    COMMIT;

END;
/

-- ============================================================
-- 20. PRUEBA DE PKG_CP_ERROR
-- ============================================================
-- El ROLLBACK borra el parametro temporal pero no los errores.

DECLARE
    v_numero NUMBER;
BEGIN

    INSERT INTO CP_PARAMETRO (codigo_parametro, modulo, tipo_dato, valor, descripcion)
    VALUES ('PRUEBA_TEMPORAL', 'PRUEBA', 'TEXTO', 'x', 'Fila temporal de prueba.');

    PKG_CP_ERROR.registrar('PRUEBA_PKG_ERROR', -20999,
                           'Error de prueba manual', 'Detalle de prueba');

    BEGIN
        v_numero := TO_NUMBER('abc');
    EXCEPTION
        WHEN OTHERS THEN
            PKG_CP_ERROR.registrar_excepcion('PRUEBA_PKG_ERROR', 'conversion invalida');
    END;

    PKG_CP_ERROR.registrar('PRUEBA_PKG_ERROR', -20998, RPAD('X', 5000, 'X'));

    ROLLBACK;

END;
/

SELECT id_bitacora_error,
       codigo_error,
       SUBSTR(mensaje_error, 1, 50) AS mensaje,
       LENGTH(mensaje_error)        AS largo
FROM CP_BITACORA_ERROR
WHERE modulo = 'PRUEBA_PKG_ERROR'
ORDER BY id_bitacora_error;

SELECT COUNT(*) AS filas_temporales
FROM CP_PARAMETRO
WHERE codigo_parametro = 'PRUEBA_TEMPORAL';

DELETE FROM CP_BITACORA_ERROR
WHERE modulo = 'PRUEBA_PKG_ERROR';

COMMIT;




