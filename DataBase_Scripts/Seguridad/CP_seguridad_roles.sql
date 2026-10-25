-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- BASE DE DATOS: Oracle 21c
-- SCRIPT: 12_seguridad_roles.sql
-- DESCRIPCION: Creacion del rol base de conexion y de los cuatro
--              roles de negocio (Gerente, Jefe de Departamento,
--              Jefe de Proveeduria y Digitador), y permisos para
--              que CP_POS administre sus claves.
--
-- EJECUTAR COMO: SYS en XEPDB1
-- ============================================================

SET SERVEROUTPUT ON

-- ============================================================
-- 1. CREACION DE LOS ROLES
-- ============================================================

DECLARE
    PROCEDURE create_role_if_missing (
        p_name IN VARCHAR2
    ) IS
    BEGIN
        EXECUTE IMMEDIATE 'CREATE ROLE '
            || DBMS_ASSERT.SIMPLE_SQL_NAME(p_name);
        DBMS_OUTPUT.PUT_LINE('Rol ' || p_name || ' creado.');
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -1921 THEN
                DBMS_OUTPUT.PUT_LINE('Rol ' || p_name || ' ya existe.');
            ELSE
                RAISE;
            END IF;
    END create_role_if_missing;
BEGIN
    create_role_if_missing('ROL_CP_CONEXION');
    create_role_if_missing('ROL_CP_GERENTE');
    create_role_if_missing('ROL_CP_JEFE_DEPARTAMENTO');
    create_role_if_missing('ROL_CP_JEFE_PROVEEDURIA');
    create_role_if_missing('ROL_CP_DIGITADOR');
END;
/

-- ============================================================
-- 2. PRIVILEGIO DE SISTEMA DEL ROL BASE
-- ============================================================

GRANT CREATE SESSION TO ROL_CP_CONEXION;

-- ============================================================
-- 3. ADMINISTRACION DE LOS ROLES DE NEGOCIO POR CP_POS
-- ============================================================
-- Permite a CP_POS cambiar la clave de estos 4 roles y consultar
-- quien los tiene concedidos, sin recibir ALTER ANY ROLE.

GRANT ROL_CP_GERENTE TO CP_POS WITH ADMIN OPTION;

GRANT ROL_CP_JEFE_DEPARTAMENTO TO CP_POS WITH ADMIN OPTION;

GRANT ROL_CP_JEFE_PROVEEDURIA TO CP_POS WITH ADMIN OPTION;

GRANT ROL_CP_DIGITADOR TO CP_POS WITH ADMIN OPTION;

GRANT SELECT ON SYS.DBA_ROLE_PRIVS TO CP_POS;

-- ============================================================
-- 4. VERIFICACION
-- ============================================================

SELECT role, password_required
FROM dba_roles
WHERE role LIKE 'ROL_CP_%'
ORDER BY role;

SELECT grantee, privilege, admin_option
FROM dba_sys_privs
WHERE grantee LIKE 'ROL_CP_%'
ORDER BY grantee, privilege;

SELECT grantee, granted_role, admin_option
FROM dba_role_privs
WHERE grantee = 'CP_POS'
  AND granted_role LIKE 'ROL_CP_%'
ORDER BY granted_role;

SELECT grantee, owner, table_name, privilege
FROM dba_tab_privs
WHERE grantee = 'CP_POS'
  AND table_name = 'DBA_ROLE_PRIVS';
