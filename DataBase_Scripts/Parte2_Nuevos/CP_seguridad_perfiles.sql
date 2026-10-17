-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- BASE DE DATOS: Oracle 21c
-- SCRIPT: 11_seguridad_perfiles.sql
-- DESCRIPCION: Creacion de los perfiles de seguridad de contrasenas
--              (usuarios interactivos y cuentas de servicio) y
--              asignacion del perfil de servicio al usuario CP_POS.
--
-- EJECUTAR COMO: SYS en XEPDB1
-- ============================================================

SET SERVEROUTPUT ON

-- ============================================================
-- 1. CREACION DE LOS PERFILES
-- ============================================================

DECLARE
    PROCEDURE upsert_profile (
        p_name   IN VARCHAR2,
        p_limits IN VARCHAR2
    ) IS
    BEGIN
        EXECUTE IMMEDIATE 'CREATE PROFILE '
            || DBMS_ASSERT.SIMPLE_SQL_NAME(p_name)
            || ' LIMIT ' || p_limits;
        DBMS_OUTPUT.PUT_LINE('Perfil ' || p_name || ' creado.');
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -2379 THEN
                EXECUTE IMMEDIATE 'ALTER PROFILE '
                    || DBMS_ASSERT.SIMPLE_SQL_NAME(p_name)
                    || ' LIMIT ' || p_limits;
                DBMS_OUTPUT.PUT_LINE('Perfil ' || p_name || ' actualizado.');
            ELSE
                RAISE;
            END IF;
    END upsert_profile;
BEGIN
    upsert_profile('PRF_CP_USUARIO',
        'FAILED_LOGIN_ATTEMPTS 3 '
        || 'PASSWORD_LOCK_TIME 1 '
        || 'PASSWORD_LIFE_TIME 90 '
        || 'PASSWORD_GRACE_TIME 7 '
        || 'PASSWORD_REUSE_MAX 5 '
        || 'PASSWORD_REUSE_TIME 365 '
        || 'PASSWORD_VERIFY_FUNCTION ORA12C_VERIFY_FUNCTION');

    upsert_profile('PRF_CP_SERVICIO',
        'FAILED_LOGIN_ATTEMPTS 10 '
        || 'PASSWORD_LOCK_TIME 1/24 '
        || 'PASSWORD_LIFE_TIME UNLIMITED '
        || 'INACTIVE_ACCOUNT_TIME UNLIMITED');
END;
/

-- ============================================================
-- 2. ASIGNACION DEL PERFIL DE SERVICIO AL DUENO DEL ESQUEMA
-- ============================================================

ALTER USER CP_POS PROFILE PRF_CP_SERVICIO;

-- ============================================================
-- 3. VERIFICACION
-- ============================================================

SELECT profile, resource_name, limit
FROM dba_profiles
WHERE profile LIKE 'PRF_CP_%'
  AND resource_type = 'PASSWORD'
ORDER BY profile, resource_name;

SELECT username, profile, account_status, expiry_date
FROM dba_users
WHERE username = 'CP_POS';
