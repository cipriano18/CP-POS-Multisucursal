-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- BASE DE DATOS: Oracle 21c
-- SCRIPT: 37_seguridad_pruebas_perfil.sql
-- DESCRIPCION: Prueba de seguridad del perfil de contrasenas, de
--              los roles y de los privilegios. Usa un usuario
--              temporal (CP_PRUEBA_PERFIL) con el perfil
--              PRF_CP_USUARIO para provocar el bloqueo por
--              intentos fallidos, la expiracion y la reutilizacion
--              de claves sin tocar los usuarios reales USR_CP_*.
--              Comprueba que ningun rol del sistema usa DBA,
--              CONNECT ni RESOURCE y muestra la diferencia entre
--              privilegios de sistema y de objeto. Al final borra
--              el usuario temporal.
--
-- EJECUTAR COMO: SYS dentro del contenedor de Oracle, con @:
--                  sqlplus -s / as sysdba @CP_seguridad_pruebas_perfil.sql
--                En el entorno del proyecto es el contenedor de la
--                base primaria (dg-primaria), PDB ORCLPDB1.
--                El script se conecta varias veces como el usuario
--                de prueba y vuelve a SYS con "/ AS SYSDBA", por eso
--                debe correr dentro del contenedor y con @ (no por
--                entrada estandar). Las claves del usuario de prueba
--                se generan al azar y no se muestran.
--                Se puede volver a ejecutar.
-- REQUISITOS: scripts 11 al 16; la prueba 20 necesita el 36.
-- ============================================================

SET ECHO OFF
SET VERIFY OFF
SET FEEDBACK OFF
SET LINESIZE 200
SET PAGESIZE 100
SET SERVEROUTPUT ON SIZE UNLIMITED
WHENEVER SQLERROR CONTINUE

-- Conexion de administrador, PDB del proyecto y usuario temporal.
-- pdb_name es la PDB de la base primaria del Data Guard (ORCLPDB1);
-- en una instalacion con Oracle XE se cambia por XEPDB1.
DEFINE admin_connect = "/ AS SYSDBA"
DEFINE pdb_name = ORCLPDB1
DEFINE pdb_service = "//localhost:1521/&pdb_name"
DEFINE test_user = CP_PRUEBA_PERFIL

-- Cada intento de conexion guarda el usuario conectado en una
-- variable; si la conexion falla la variable queda en NONE
COLUMN login_a NEW_VALUE login_unlocked NOPRINT
COLUMN login_b NEW_VALUE login_locked NOPRINT
COLUMN pwd_a NEW_VALUE pwd_1 NOPRINT
COLUMN pwd_b NEW_VALUE pwd_2 NOPRINT
COLUMN start_utc NEW_VALUE test_start NOPRINT

DEFINE login_unlocked = NONE
DEFINE login_locked = NONE

CONNECT &admin_connect
ALTER SESSION SET CONTAINER = &pdb_name;
SET SERVEROUTPUT ON SIZE UNLIMITED

-- ============================================================
-- 0. CLAVES DEL USUARIO DE PRUEBA
-- ============================================================
-- Dos claves aleatorias que cumplen ORA12C_VERIFY_FUNCTION (letras
-- y numeros, 16 caracteres). TERMOUT OFF evita que se impriman.

SET TERMOUT OFF
SELECT 'Pp_' || DBMS_RANDOM.STRING('X', 12) || '7' AS pwd_a,
       'Qq_' || DBMS_RANDOM.STRING('X', 12) || '3' AS pwd_b,
       TO_CHAR(SYS_EXTRACT_UTC(SYSTIMESTAMP), 'YYYY-MM-DD HH24:MI:SS') AS start_utc
FROM dual;
SET TERMOUT ON

-- ============================================================
-- 1. CONFIGURACION DEL PERFIL
-- ============================================================

PROMPT
PROMPT === 1. Perfil de contrasenas PRF_CP_USUARIO ===

DECLARE
    v_count PLS_INTEGER;

    -- Limite configurado de un recurso del perfil
    FUNCTION limit_of (
        p_profile  IN VARCHAR2,
        p_resource IN VARCHAR2
    ) RETURN VARCHAR2 IS
        v_limit dba_profiles.limit%TYPE;
    BEGIN
        SELECT limit
        INTO v_limit
        FROM dba_profiles
        WHERE profile = p_profile
          AND resource_name = p_resource;
        RETURN v_limit;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END limit_of;

    PROCEDURE report (
        p_number IN PLS_INTEGER,
        p_text   IN VARCHAR2,
        p_ok     IN BOOLEAN,
        p_detail IN VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(
            RPAD(p_number || '. ' || p_text, 68, '.') || ' '
            || CASE WHEN p_ok THEN 'OK' ELSE 'FALLA' END
            || CASE WHEN p_detail IS NOT NULL THEN ' (' || p_detail || ')' END);
    END report;

    -- Compara el limite real con el esperado
    PROCEDURE check_limit (
        p_number   IN PLS_INTEGER,
        p_resource IN VARCHAR2,
        p_expected IN VARCHAR2
    ) IS
        v_limit VARCHAR2(128) := limit_of('PRF_CP_USUARIO', p_resource);
    BEGIN
        report(p_number, p_resource || ' = ' || p_expected,
               v_limit = p_expected, v_limit);
    END check_limit;
BEGIN
    check_limit(1, 'FAILED_LOGIN_ATTEMPTS', '3');
    check_limit(2, 'PASSWORD_LOCK_TIME', '1');
    check_limit(3, 'PASSWORD_LIFE_TIME', '90');
    check_limit(4, 'PASSWORD_GRACE_TIME', '7');
    check_limit(5, 'PASSWORD_REUSE_MAX', '5');
    check_limit(6, 'PASSWORD_REUSE_TIME', '365');
    check_limit(7, 'PASSWORD_VERIFY_FUNCTION', 'ORA12C_VERIFY_FUNCTION');

    SELECT COUNT(*)
    INTO v_count
    FROM dba_users
    WHERE username IN ('USR_CP_GERENTE', 'USR_CP_JEFE_DEPTO',
                       'USR_CP_JEFE_PROVEEDURIA', 'USR_CP_DIGITADOR')
      AND profile = 'PRF_CP_USUARIO';

    report(8, 'Los 4 usuarios USR_CP_* usan PRF_CP_USUARIO',
           v_count = 4, v_count || ' de 4');

    SELECT COUNT(*)
    INTO v_count
    FROM dba_users
    WHERE username = 'CP_POS'
      AND profile = 'PRF_CP_SERVICIO';

    report(9, 'CP_POS (cuenta de servicio) usa PRF_CP_SERVICIO', v_count = 1);
END;
/

-- ============================================================
-- 2. USUARIO DE PRUEBA
-- ============================================================
-- Solo recibe el rol base ROL_CP_CONEXION (CREATE SESSION y el EXECUTE
-- de PKG_CP_SESION para activar roles).

PROMPT
PROMPT === 2. Usuario de prueba CP_PRUEBA_PERFIL ===

DECLARE
    v_count   PLS_INTEGER;
    v_status  dba_users.account_status%TYPE;
    v_profile dba_users.profile%TYPE;
    v_expiry  DATE;

    PROCEDURE report (
        p_number IN PLS_INTEGER,
        p_text   IN VARCHAR2,
        p_ok     IN BOOLEAN,
        p_detail IN VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(
            RPAD(p_number || '. ' || p_text, 68, '.') || ' '
            || CASE WHEN p_ok THEN 'OK' ELSE 'FALLA' END
            || CASE WHEN p_detail IS NOT NULL THEN ' (' || p_detail || ')' END);
    END report;
BEGIN
    -- Si quedo de una corrida anterior se borra antes de crearlo
    SELECT COUNT(*)
    INTO v_count
    FROM dba_users
    WHERE username = '&test_user';

    IF v_count > 0 THEN
        EXECUTE IMMEDIATE 'DROP USER &test_user CASCADE';
    END IF;

    EXECUTE IMMEDIATE 'CREATE USER &test_user IDENTIFIED BY "&pwd_1"'
        || ' PROFILE PRF_CP_USUARIO';
    EXECUTE IMMEDIATE 'GRANT ROL_CP_CONEXION TO &test_user';

    SELECT account_status, profile, expiry_date
    INTO v_status, v_profile, v_expiry
    FROM dba_users
    WHERE username = '&test_user';

    report(10, 'El usuario nuevo queda OPEN con PRF_CP_USUARIO',
           v_status = 'OPEN' AND v_profile = 'PRF_CP_USUARIO', v_status);

    -- PASSWORD_LIFE_TIME 90: la clave vence 90 dias despues de crearla
    report(11, 'Su clave vence en 90 dias (expiry_date)',
           v_expiry BETWEEN SYSDATE + 89 AND SYSDATE + 91,
           TO_CHAR(v_expiry, 'YYYY-MM-DD'));
END;
/

-- ============================================================
-- 3. PRIVILEGIOS DE SISTEMA CONTRA PRIVILEGIOS DE OBJETO
-- ============================================================
-- Conectado como el usuario de prueba: sin CREATE TABLE (privilegio
-- de sistema) no puede crear tablas en ningun esquema, y sin SELECT
-- sobre una tabla (privilegio de objeto) no puede leer esa tabla.

PROMPT
PROMPT === 3. Privilegios de sistema y de objeto (como el usuario de prueba) ===

CONNECT &test_user/"&pwd_1"@&pdb_service
SET SERVEROUTPUT ON SIZE UNLIMITED

DECLARE
    v_roles PLS_INTEGER;
    v_first VARCHAR2(128);
    v_code  PLS_INTEGER;

    -- Ejecuta una sentencia y devuelve 0 o el codigo de error
    FUNCTION code_of (
        p_sql IN VARCHAR2
    ) RETURN PLS_INTEGER IS
    BEGIN
        EXECUTE IMMEDIATE p_sql;
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN SQLCODE;
    END code_of;

    -- Ejecuta una consulta de conteo y devuelve 0 o el codigo de error
    FUNCTION query_code_of (
        p_sql IN VARCHAR2
    ) RETURN PLS_INTEGER IS
        v_total NUMBER;
    BEGIN
        EXECUTE IMMEDIATE p_sql INTO v_total;
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN SQLCODE;
    END query_code_of;

    PROCEDURE report (
        p_number IN PLS_INTEGER,
        p_text   IN VARCHAR2,
        p_ok     IN BOOLEAN,
        p_detail IN VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(
            RPAD(p_number || '. ' || p_text, 68, '.') || ' '
            || CASE WHEN p_ok THEN 'OK' ELSE 'FALLA' END
            || CASE WHEN p_detail IS NOT NULL THEN ' (' || p_detail || ')' END);
    END report;
BEGIN
    report(12, 'Se conecta con su clave', USER = '&test_user', USER);

    SELECT COUNT(*), MIN(role)
    INTO v_roles, v_first
    FROM session_roles;

    report(13, 'Solo tiene activo ROL_CP_CONEXION',
           v_roles = 1 AND v_first = 'ROL_CP_CONEXION', v_first);

    v_code := code_of('CREATE TABLE cp_prueba_tabla (id NUMBER)');
    report(14, 'CREATE TABLE negado: falta privilegio de sistema',
           v_code = -1031, v_code);

    v_code := query_code_of('SELECT COUNT(*) FROM CP_POS.CP_TIPO_NEGOCIO');
    report(15, 'Leer CP_TIPO_NEGOCIO negado: falta privilegio de objeto',
           v_code = -942, v_code);
END;
/

-- SYS le concede un privilegio de objeto sobre una sola tabla

CONNECT &admin_connect
ALTER SESSION SET CONTAINER = &pdb_name;
SET SERVEROUTPUT ON SIZE UNLIMITED

GRANT SELECT ON CP_POS.CP_TIPO_NEGOCIO TO &test_user;

CONNECT &test_user/"&pwd_1"@&pdb_service
SET SERVEROUTPUT ON SIZE UNLIMITED

DECLARE
    FUNCTION code_of (
        p_sql IN VARCHAR2
    ) RETURN PLS_INTEGER IS
    BEGIN
        EXECUTE IMMEDIATE p_sql;
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN SQLCODE;
    END code_of;

    FUNCTION query_code_of (
        p_sql IN VARCHAR2
    ) RETURN PLS_INTEGER IS
        v_total NUMBER;
    BEGIN
        EXECUTE IMMEDIATE p_sql INTO v_total;
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN SQLCODE;
    END query_code_of;

    PROCEDURE report (
        p_number IN PLS_INTEGER,
        p_text   IN VARCHAR2,
        p_ok     IN BOOLEAN,
        p_detail IN VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(
            RPAD(p_number || '. ' || p_text, 68, '.') || ' '
            || CASE WHEN p_ok THEN 'OK' ELSE 'FALLA' END
            || CASE WHEN p_detail IS NOT NULL THEN ' (' || p_detail || ')' END);
    END report;
BEGIN
    report(16, 'Con GRANT SELECT sobre la tabla ya puede leerla',
           query_code_of('SELECT COUNT(*) FROM CP_POS.CP_TIPO_NEGOCIO') = 0);

    -- El privilegio de objeto no da ninguna capacidad general
    report(17, 'Pero sigue sin poder crear tablas (-1031)',
           code_of('CREATE TABLE cp_prueba_tabla (id NUMBER)') = -1031);
END;
/

CONNECT &admin_connect
ALTER SESSION SET CONTAINER = &pdb_name;
SET SERVEROUTPUT ON SIZE UNLIMITED

REVOKE SELECT ON CP_POS.CP_TIPO_NEGOCIO FROM &test_user;

-- ============================================================
-- 4. BLOQUEO AUTOMATICO POR INTENTOS FALLIDOS
-- ============================================================
-- FAILED_LOGIN_ATTEMPTS 3: al tercer intento fallido seguido Oracle
-- bloquea la cuenta durante PASSWORD_LOCK_TIME (1 dia). Los errores
-- ORA-01017 y ORA-28000 que imprime SQL*Plus son la evidencia.

PROMPT
PROMPT === 4. Bloqueo por intentos fallidos ===
PROMPT Tres conexiones con una clave incorrecta (se espera ORA-01017):

CONNECT &test_user/"&pwd_1.x"@&pdb_service
CONNECT &test_user/"&pwd_1.x"@&pdb_service
CONNECT &test_user/"&pwd_1.x"@&pdb_service

PROMPT Conexion con la clave correcta (se espera ORA-28000, cuenta bloqueada):

CONNECT &test_user/"&pwd_1"@&pdb_service
SELECT USER AS login_b FROM dual;

CONNECT &admin_connect
ALTER SESSION SET CONTAINER = &pdb_name;
SET SERVEROUTPUT ON SIZE UNLIMITED

DECLARE
    v_status dba_users.account_status%TYPE;
    v_lock   DATE;
    v_failed NUMBER;
    v_policy PLS_INTEGER;
    v_audit  PLS_INTEGER;

    PROCEDURE report (
        p_number IN PLS_INTEGER,
        p_text   IN VARCHAR2,
        p_ok     IN BOOLEAN,
        p_detail IN VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(
            RPAD(p_number || '. ' || p_text, 68, '.') || ' '
            || CASE WHEN p_ok THEN 'OK' ELSE 'FALLA' END
            || CASE WHEN p_detail IS NOT NULL THEN ' (' || p_detail || ')' END);
    END report;
BEGIN
    SELECT account_status, lock_date
    INTO v_status, v_lock
    FROM dba_users
    WHERE username = '&test_user';

    -- LCOUNT es el contador interno de intentos fallidos seguidos
    SELECT lcount
    INTO v_failed
    FROM sys.user$
    WHERE name = '&test_user';

    report(18, 'Tras 3 claves incorrectas la cuenta queda bloqueada',
           v_status LIKE 'LOCKED%', v_status);

    report(19, 'Oracle conto los intentos fallidos (USER$.LCOUNT)',
           v_failed >= 3, v_failed);

    report(20, 'Con la clave correcta ya no puede entrar (ORA-28000)',
           '&login_locked' = 'NONE');

    -- La politica POL_CP_ACCESO_FALLIDO (script 36) audita los
    -- inicios de sesion que fallan
    SELECT COUNT(*)
    INTO v_policy
    FROM audit_unified_enabled_policies
    WHERE policy_name = 'POL_CP_ACCESO_FALLIDO';

    IF v_policy = 0 THEN
        DBMS_OUTPUT.PUT_LINE(
            RPAD('21. La auditoria registro los intentos fallidos', 68, '.')
            || ' OMITIDA (falta el script 36)');
    ELSE
        BEGIN
            DBMS_AUDIT_MGMT.FLUSH_UNIFIED_AUDIT_TRAIL;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;

        SELECT COUNT(*)
        INTO v_audit
        FROM unified_audit_trail
        WHERE dbusername = '&test_user'
          AND action_name = 'LOGON'
          AND return_code IN (1017, 28000)
          AND event_timestamp_utc >= TO_TIMESTAMP('&test_start', 'YYYY-MM-DD HH24:MI:SS');

        report(21, 'La auditoria registro los intentos fallidos',
               v_audit >= 3, v_audit || ' registros');
    END IF;

    DBMS_OUTPUT.PUT_LINE('    Bloqueada desde ' || TO_CHAR(v_lock, 'YYYY-MM-DD HH24:MI')
        || '; se desbloquea sola el ' || TO_CHAR(v_lock + 1, 'YYYY-MM-DD HH24:MI')
        || ' (PASSWORD_LOCK_TIME = 1 dia).');
END;
/

-- El administrador puede desbloquearla antes de tiempo

ALTER USER &test_user ACCOUNT UNLOCK;

CONNECT &test_user/"&pwd_1"@&pdb_service
SELECT USER AS login_a FROM dual;

CONNECT &admin_connect
ALTER SESSION SET CONTAINER = &pdb_name;
SET SERVEROUTPUT ON SIZE UNLIMITED

DECLARE
    v_status dba_users.account_status%TYPE;

    PROCEDURE report (
        p_number IN PLS_INTEGER,
        p_text   IN VARCHAR2,
        p_ok     IN BOOLEAN,
        p_detail IN VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(
            RPAD(p_number || '. ' || p_text, 68, '.') || ' '
            || CASE WHEN p_ok THEN 'OK' ELSE 'FALLA' END
            || CASE WHEN p_detail IS NOT NULL THEN ' (' || p_detail || ')' END);
    END report;
BEGIN
    SELECT account_status
    INTO v_status
    FROM dba_users
    WHERE username = '&test_user';

    report(22, 'ACCOUNT UNLOCK la reabre y vuelve a conectarse',
           v_status = 'OPEN' AND '&login_unlocked' = '&test_user', v_status);
END;
/

-- ============================================================
-- 5. COMPLEJIDAD, REUTILIZACION Y EXPIRACION DE CLAVES
-- ============================================================

PROMPT
PROMPT === 5. Complejidad, reutilizacion y expiracion de claves ===

DECLARE
    v_status dba_users.account_status%TYPE;
    v_code   PLS_INTEGER;

    FUNCTION code_of (
        p_sql IN VARCHAR2
    ) RETURN PLS_INTEGER IS
    BEGIN
        EXECUTE IMMEDIATE p_sql;
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN SQLCODE;
    END code_of;

    PROCEDURE report (
        p_number IN PLS_INTEGER,
        p_text   IN VARCHAR2,
        p_ok     IN BOOLEAN,
        p_detail IN VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(
            RPAD(p_number || '. ' || p_text, 68, '.') || ' '
            || CASE WHEN p_ok THEN 'OK' ELSE 'FALLA' END
            || CASE WHEN p_detail IS NOT NULL THEN ' (' || p_detail || ')' END);
    END report;
BEGIN
    -- ORA12C_VERIFY_FUNCTION: minimo 8 caracteres, letras y numeros
    v_code := code_of('ALTER USER &test_user IDENTIFIED BY "abc1"');
    report(23, 'Clave corta rechazada (ORA-28003)', v_code = -28003, v_code);

    v_code := code_of('ALTER USER &test_user IDENTIFIED BY "SoloLetrasLargas"');
    report(24, 'Clave sin numeros rechazada (ORA-28003)', v_code = -28003, v_code);

    v_code := code_of('ALTER USER &test_user IDENTIFIED BY "&pwd_2"');
    report(25, 'Cambio a una clave nueva que cumple el perfil', v_code = 0, v_code);

    -- PASSWORD_REUSE_MAX 5 y PASSWORD_REUSE_TIME 365: una clave usada
    -- no se repite hasta pasar 5 cambios y 365 dias
    v_code := code_of('ALTER USER &test_user IDENTIFIED BY "&pwd_1"');
    report(26, 'Volver a la clave anterior es rechazado (ORA-28007)',
           v_code = -28007, v_code);

    v_code := code_of('ALTER USER &test_user IDENTIFIED BY "&pwd_2"');
    report(27, 'Repetir la clave actual es rechazado (ORA-28007)',
           v_code = -28007, v_code);

    -- Una clave vencida obliga a cambiarla en el siguiente inicio de
    -- sesion (ORA-28001); aqui se fuerza el vencimiento sin esperar
    -- los 90 dias
    v_code := code_of('ALTER USER &test_user PASSWORD EXPIRE');

    SELECT account_status
    INTO v_status
    FROM dba_users
    WHERE username = '&test_user';

    report(28, 'PASSWORD EXPIRE deja la cuenta EXPIRED',
           v_code = 0 AND v_status = 'EXPIRED', v_status);
END;
/

-- ============================================================
-- 6. ROLES CON PERMISOS MINIMOS
-- ============================================================

PROMPT
PROMPT === 6. Roles y privilegios del sistema ===

DECLARE
    v_count PLS_INTEGER;
    v_sys   PLS_INTEGER;
    v_obj   PLS_INTEGER;
    v_pkg   PLS_INTEGER;
    v_ok    BOOLEAN := TRUE;

    PROCEDURE report (
        p_number IN PLS_INTEGER,
        p_text   IN VARCHAR2,
        p_ok     IN BOOLEAN,
        p_detail IN VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(
            RPAD(p_number || '. ' || p_text, 68, '.') || ' '
            || CASE WHEN p_ok THEN 'OK' ELSE 'FALLA' END
            || CASE WHEN p_detail IS NOT NULL THEN ' (' || p_detail || ')' END);
    END report;
BEGIN
    -- Se recorre toda la cadena de roles (un rol puede tener otros)
    SELECT COUNT(*)
    INTO v_count
    FROM (SELECT granted_role
          FROM dba_role_privs
          START WITH grantee LIKE 'ROL\_CP\_%' ESCAPE '\'
                  OR grantee LIKE 'USR\_CP\_%' ESCAPE '\'
                  OR grantee = 'CP_POS'
          CONNECT BY NOCYCLE PRIOR granted_role = grantee)
    WHERE granted_role IN ('DBA', 'CONNECT', 'RESOURCE');

    report(29, 'Nadie del sistema tiene DBA, CONNECT ni RESOURCE',
           v_count = 0, v_count || ' concesiones');

    SELECT COUNT(*)
    INTO v_count
    FROM dba_roles
    WHERE role IN ('ROL_CP_GERENTE', 'ROL_CP_JEFE_DEPARTAMENTO',
                   'ROL_CP_JEFE_PROVEEDURIA', 'ROL_CP_DIGITADOR')
      AND authentication_type = 'PASSWORD';

    report(30, 'Los 4 roles de negocio estan protegidos con clave',
           v_count = 4, v_count || ' de 4');

    SELECT COUNT(*)
    INTO v_count
    FROM dba_role_privs
    WHERE grantee LIKE 'USR\_CP\_%' ESCAPE '\'
      AND default_role = 'YES'
      AND granted_role <> 'ROL_CP_CONEXION';

    report(31, 'Los USR_CP_* solo tienen ROL_CP_CONEXION por defecto',
           v_count = 0);

    -- Privilegios de sistema: acciones generales (CREATE SESSION).
    -- Privilegios de objeto: acciones sobre un objeto concreto.
    -- ROL_CP_CONEXION tiene ademas EXECUTE sobre PKG_CP_SESION y
    -- PKG_CP_CLAVE_ROL (script 15): PKG_CP_SESION es AUTHID
    -- CURRENT_USER (SET ROLE solo funciona con derechos del invocador),
    -- asi que quien activa su rol necesita EXECUTE sobre ambos; la
    -- clave no queda expuesta porque PKG_CP_CLAVE_ROL.obtener es
    -- ACCESSIBLE BY (PACKAGE PKG_CP_SESION). Cualquier otro privilegio
    -- de objeto es una falla.
    SELECT COUNT(*)
    INTO v_sys
    FROM dba_sys_privs
    WHERE grantee = 'ROL_CP_CONEXION';

    SELECT COUNT(*)
    INTO v_count
    FROM dba_sys_privs
    WHERE grantee = 'ROL_CP_CONEXION'
      AND privilege = 'CREATE SESSION';

    SELECT COUNT(*)
    INTO v_obj
    FROM dba_tab_privs
    WHERE grantee = 'ROL_CP_CONEXION';

    SELECT COUNT(*)
    INTO v_pkg
    FROM dba_tab_privs
    WHERE grantee = 'ROL_CP_CONEXION'
      AND owner = 'CP_POS'
      AND table_name IN ('PKG_CP_SESION', 'PKG_CP_CLAVE_ROL')
      AND privilege = 'EXECUTE';

    report(32, 'ROL_CP_CONEXION: CREATE SESSION y EXECUTE de sesion',
           v_sys = 1 AND v_count = 1 AND v_obj = 2 AND v_pkg = 2,
           v_sys || ' de sistema, ' || v_obj || ' de objeto');

    FOR r IN (SELECT role
              FROM dba_roles
              WHERE role IN ('ROL_CP_GERENTE', 'ROL_CP_JEFE_DEPARTAMENTO',
                             'ROL_CP_JEFE_PROVEEDURIA', 'ROL_CP_DIGITADOR')) LOOP
        SELECT COUNT(*) INTO v_sys FROM dba_sys_privs WHERE grantee = r.role;
        SELECT COUNT(*) INTO v_obj FROM dba_tab_privs WHERE grantee = r.role;

        IF v_sys > 0 OR v_obj = 0 THEN
            v_ok := FALSE;
        END IF;
    END LOOP;

    report(33, 'Roles de negocio: 0 de sistema y solo de objeto', v_ok);

    SELECT COUNT(*)
    INTO v_count
    FROM (SELECT grantee FROM dba_sys_privs WHERE grantee LIKE 'USR\_CP\_%' ESCAPE '\'
          UNION ALL
          SELECT grantee FROM dba_tab_privs WHERE grantee LIKE 'USR\_CP\_%' ESCAPE '\');

    report(34, 'Los USR_CP_* no tienen privilegios directos',
           v_count = 0, v_count || ' privilegios');
END;
/

PROMPT
PROMPT Privilegios por rol (sistema contra objeto):

COLUMN rol FORMAT A26
COLUMN privilegios_sistema FORMAT 9999 HEADING 'SISTEMA'
COLUMN privilegios_objeto FORMAT 9999 HEADING 'OBJETO'

SELECT r.role AS rol,
       (SELECT COUNT(*) FROM dba_sys_privs s WHERE s.grantee = r.role) AS privilegios_sistema,
       (SELECT COUNT(*) FROM dba_tab_privs t WHERE t.grantee = r.role) AS privilegios_objeto
FROM dba_roles r
WHERE r.role LIKE 'ROL\_CP\_%' ESCAPE '\'
ORDER BY r.role;

PROMPT
PROMPT Privilegios de objeto por tipo:

COLUMN grantee FORMAT A26
COLUMN privilege FORMAT A12

SELECT grantee, privilege, COUNT(*) AS total
FROM dba_tab_privs
WHERE grantee LIKE 'ROL\_CP\_%' ESCAPE '\'
GROUP BY grantee, privilege
ORDER BY grantee, privilege;

PROMPT
PROMPT Privilegios de sistema del propietario CP_POS:

COLUMN privilege FORMAT A30

SELECT privilege
FROM dba_sys_privs
WHERE grantee = 'CP_POS'
ORDER BY privilege;

PROMPT
PROMPT Estado de las cuentas reales:

COLUMN username FORMAT A26
COLUMN profile FORMAT A18
COLUMN account_status FORMAT A18

SELECT username, profile, account_status,
       TO_CHAR(expiry_date, 'YYYY-MM-DD') AS vence,
       TO_CHAR(lock_date, 'YYYY-MM-DD') AS bloqueo
FROM dba_users
WHERE username LIKE 'USR\_CP\_%' ESCAPE '\'
   OR username = 'CP_POS'
ORDER BY username;

-- ============================================================
-- 7. LIMPIEZA
-- ============================================================

PROMPT
PROMPT === 7. Limpieza ===

DECLARE
    v_count PLS_INTEGER;
BEGIN
    EXECUTE IMMEDIATE 'DROP USER &test_user CASCADE';

    SELECT COUNT(*)
    INTO v_count
    FROM dba_users
    WHERE username = '&test_user';

    DBMS_OUTPUT.PUT_LINE(
        RPAD('35. Se borro el usuario de prueba', 68, '.') || ' '
        || CASE WHEN v_count = 0 THEN 'OK' ELSE 'FALLA' END);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(
            RPAD('35. Se borro el usuario de prueba', 68, '.') || ' FALLA ('
            || SQLCODE || ')');
END;
/

UNDEFINE pwd_1
UNDEFINE pwd_2
UNDEFINE test_start
UNDEFINE login_locked
UNDEFINE login_unlocked
