-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- BASE DE DATOS: Oracle 21c
-- SCRIPT: 17_seguridad_pruebas_usuarios.sql
-- DESCRIPCION: Pruebas de seguridad con usuarios reales. Comprueba
--              que el usuario solo tiene el rol base al conectar,
--              que no puede activar su rol de negocio ni leer su
--              clave por su cuenta, que PKG_CP_SESION.activar_rol
--              le da los permisos de su rol y nada mas.
--
-- EJECUTAR COMO: cada uno de los usuarios USR_CP_GERENTE,
--                USR_CP_JEFE_DEPTO, USR_CP_JEFE_PROVEEDURIA y
--                USR_CP_DIGITADOR (el mismo script, una vez por
--                usuario, cada uno en su conexion de XEPDB1)
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED

-- ============================================================
-- 1. IDENTIFICACION DEL USUARIO DE LA PRUEBA
-- ============================================================
-- Segun el usuario conectado se elige su rol, un rol ajeno, una
-- tabla que su rol puede leer y otra que no. Los valores quedan
-- en variables de enlace que usan los bloques siguientes.

VARIABLE v_role VARCHAR2(30)
VARIABLE v_other VARCHAR2(30)
VARIABLE v_allowed VARCHAR2(60)
VARIABLE v_denied VARCHAR2(60)

BEGIN
    :v_role := CASE USER
        WHEN 'USR_CP_GERENTE' THEN 'ROL_CP_GERENTE'
        WHEN 'USR_CP_JEFE_DEPTO' THEN 'ROL_CP_JEFE_DEPARTAMENTO'
        WHEN 'USR_CP_JEFE_PROVEEDURIA' THEN 'ROL_CP_JEFE_PROVEEDURIA'
        WHEN 'USR_CP_DIGITADOR' THEN 'ROL_CP_DIGITADOR'
    END;

    :v_other := CASE USER
        WHEN 'USR_CP_GERENTE' THEN 'ROL_CP_DIGITADOR'
        ELSE 'ROL_CP_GERENTE'
    END;

    :v_allowed := CASE USER
        WHEN 'USR_CP_GERENTE' THEN 'CP_POS.CP_BITACORA_ERROR'
        WHEN 'USR_CP_JEFE_DEPTO' THEN 'CP_POS.CP_CIERRE_DIARIO'
        WHEN 'USR_CP_JEFE_PROVEEDURIA' THEN 'CP_POS.CP_FACTURA_COMPRA'
        WHEN 'USR_CP_DIGITADOR' THEN 'CP_POS.CP_FACTURA_VENTA'
    END;

    :v_denied := CASE USER
        WHEN 'USR_CP_GERENTE' THEN 'CP_POS.CP_USUARIO'
        WHEN 'USR_CP_JEFE_DEPTO' THEN 'CP_POS.CP_BITACORA_ERROR'
        WHEN 'USR_CP_JEFE_PROVEEDURIA' THEN 'CP_POS.CP_CIERRE_DIARIO'
        WHEN 'USR_CP_DIGITADOR' THEN 'CP_POS.CP_FACTURA_COMPRA'
    END;

    DBMS_OUTPUT.PUT_LINE('Usuario conectado ........ ' || USER);
    DBMS_OUTPUT.PUT_LINE('Rol de negocio ........... ' || :v_role);
    DBMS_OUTPUT.PUT_LINE('Tabla que si puede leer .. ' || :v_allowed);
    DBMS_OUTPUT.PUT_LINE('Tabla que no puede leer .. ' || :v_denied);
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
END;
/

-- ============================================================
-- 2. ANTES DE ACTIVAR EL ROL DE NEGOCIO
-- ============================================================

DECLARE
    v_role    VARCHAR2(30) := :v_role;
    v_roles   PLS_INTEGER;
    v_primero VARCHAR2(30);

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
        p_code   IN PLS_INTEGER DEFAULT NULL
    ) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(
            RPAD(p_number || '. ' || p_text, 62, '.') || ' '
            || CASE WHEN p_ok THEN 'OK' ELSE 'FALLA' END
            || CASE WHEN p_code IS NOT NULL THEN ' (' || p_code || ')' END
        );
    END report;

    PROCEDURE check_denied (
        p_number IN PLS_INTEGER,
        p_text   IN VARCHAR2,
        p_sql    IN VARCHAR2
    ) IS
        v_code PLS_INTEGER := code_of(p_sql);
    BEGIN
        report(p_number, p_text, v_code <> 0, v_code);
    END check_denied;
BEGIN
    SELECT COUNT(*), MIN(role)
    INTO v_roles, v_primero
    FROM session_roles;

    report(1, 'Al conectar solo esta activo ROL_CP_CONEXION',
           v_roles = 1 AND v_primero = 'ROL_CP_CONEXION');

    check_denied(2, 'Sin activar el rol no lee tablas de CP_POS',
        'BEGIN FOR r IN (SELECT 1 FROM CP_POS.CP_TIPO_NEGOCIO WHERE ROWNUM <= 1) LOOP NULL; END LOOP; END;');

    report(3, 'SET ROLE sin la clave es rechazado (ORA-01979)',
           code_of('BEGIN DBMS_SESSION.SET_ROLE(''' || v_role || '''); END;') = -1979);

    report(4, 'No puede leer la clave del rol directamente',
           code_of('DECLARE v VARCHAR2(100); BEGIN v := CP_POS.PKG_CP_CLAVE_ROL.obtener('''
                   || v_role || '''); END;') = -6550);

    report(5, 'No puede ejecutar PKG_CP_CRIPTO',
           code_of('DECLARE v VARCHAR2(100); BEGIN v := CP_POS.PKG_CP_CRIPTO.descifrar(NULL); END;') = -6550);
END;
/

-- ============================================================
-- 3. ACTIVACION DEL ROL CON PKG_CP_SESION
-- ============================================================

BEGIN
    CP_POS.PKG_CP_SESION.activar_rol(:v_role);
    DBMS_OUTPUT.PUT_LINE(
        RPAD('6. activar_rol activa el rol con su clave', 62, '.') || ' OK');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(
            RPAD('6. activar_rol activa el rol con su clave', 62, '.') || ' FALLA');
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/

-- ============================================================
-- 4. DESPUES DE ACTIVAR EL ROL DE NEGOCIO
-- ============================================================

DECLARE
    v_role    VARCHAR2(30) := :v_role;
    v_other   VARCHAR2(30) := :v_other;
    v_allowed VARCHAR2(60) := :v_allowed;
    v_denied  VARCHAR2(60) := :v_denied;
    v_roles   PLS_INTEGER;

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
        p_code   IN PLS_INTEGER DEFAULT NULL
    ) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(
            RPAD(p_number || '. ' || p_text, 62, '.') || ' '
            || CASE WHEN p_ok THEN 'OK' ELSE 'FALLA' END
            || CASE WHEN p_code IS NOT NULL THEN ' (' || p_code || ')' END
        );
    END report;

    FUNCTION read_sql (
        p_table IN VARCHAR2
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN 'BEGIN FOR r IN (SELECT 1 FROM ' || p_table
            || ' WHERE ROWNUM <= 1) LOOP NULL; END LOOP; END;';
    END read_sql;

    PROCEDURE check_allowed (
        p_number IN PLS_INTEGER,
        p_text   IN VARCHAR2,
        p_table  IN VARCHAR2
    ) IS
        v_code PLS_INTEGER := code_of(read_sql(p_table));
    BEGIN
        report(p_number, p_text, v_code = 0, v_code);
    END check_allowed;

    PROCEDURE check_denied (
        p_number IN PLS_INTEGER,
        p_text   IN VARCHAR2,
        p_sql    IN VARCHAR2
    ) IS
        v_code PLS_INTEGER := code_of(p_sql);
    BEGIN
        report(p_number, p_text, v_code <> 0, v_code);
    END check_denied;
BEGIN
    SELECT COUNT(*)
    INTO v_roles
    FROM session_roles
    WHERE role IN ('ROL_CP_CONEXION', v_role);

    report(7, 'Quedan activos el rol base y su rol de negocio',
           v_roles = 2);

    check_allowed(8, 'Lee una tabla de catalogo (CP_TIPO_NEGOCIO)',
                  'CP_POS.CP_TIPO_NEGOCIO');

    check_allowed(9, 'Lee la tabla propia de su rol', v_allowed);

    check_denied(10, 'No lee la tabla ajena a su rol', read_sql(v_denied));

    check_denied(11, 'No puede borrar datos (sin privilegio DELETE)',
        'BEGIN DELETE FROM CP_POS.CP_TIPO_NEGOCIO; END;');

    check_denied(12, 'No lee CP_PARAMETRO (claves de los roles)',
        read_sql('CP_POS.CP_PARAMETRO'));

    report(13, 'Pedir un rol que no es suyo da -20223',
           code_of('BEGIN CP_POS.PKG_CP_SESION.activar_rol(''' || v_other || '''); END;') = -20223);

    ROLLBACK;
END;
/

-- ============================================================
-- 5. ROLES ACTIVOS AL FINAL
-- ============================================================
-- Deben aparecer ROL_CP_CONEXION y el rol de negocio del usuario.

SELECT USER AS usuario, role AS rol_activo
FROM session_roles
ORDER BY role;
