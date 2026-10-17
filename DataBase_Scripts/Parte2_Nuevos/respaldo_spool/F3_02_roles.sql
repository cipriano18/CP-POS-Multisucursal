-- ============================================================
-- FASE 3 - SEGURIDAD
-- SCRIPT: F3_02_roles.sql
-- EJECUTAR COMO: SYS en XEPDB1
-- ============================================================

-- Configuración de salida
SET SERVEROUTPUT ON
SET PAGESIZE 100
SET LINESIZE 120
SET FEEDBACK OFF
COLUMN role FORMAT A26
COLUMN password_required FORMAT A18
COLUMN grantee FORMAT A26
COLUMN privilege FORMAT A20

SPOOL "C:\Users\jafet\Documents\UNA\2026 II CICLO\Admin BD\ProyectoParte2\Resultado_roles.txt"

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
-- VERIFICACION
-- ============================================================

SELECT role, password_required
FROM dba_roles
WHERE role LIKE 'ROL_CP_%'
ORDER BY role;

SELECT grantee, privilege, admin_option
FROM dba_sys_privs
WHERE grantee LIKE 'ROL_CP_%'
ORDER BY grantee, privilege;

SPOOL OFF
SET FEEDBACK ON
