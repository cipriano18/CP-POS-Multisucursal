-- ============================================================
-- FASE 3 - SEGURIDAD
-- SCRIPT: F3_01_perfiles.sql
-- EJECUTAR COMO: SYS en XEPDB1
-- ============================================================

-- Configuración de salida
SET SERVEROUTPUT ON
SET PAGESIZE 100
SET LINESIZE 120
SET FEEDBACK OFF
COLUMN profile FORMAT A18
COLUMN resource_name FORMAT A26
COLUMN limit FORMAT A26
COLUMN username FORMAT A12
COLUMN account_status FORMAT A14

SPOOL "C:\Users\jafet\Documents\UNA\2026 II CICLO\Admin BD\ProyectoParte2\Resultado_perfiles.txt"

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
-- 2. ASIGNACION DEL PERFIL DE SERVICIO AL DUEÑO DEL ESQUEMA
-- ============================================================

ALTER USER CP_POS PROFILE PRF_CP_SERVICIO;

-- ============================================================
-- VERIFICACION
-- ============================================================

SELECT profile, resource_name, limit
FROM dba_profiles
WHERE profile LIKE 'PRF_CP_%'
  AND resource_type = 'PASSWORD'
ORDER BY profile, resource_name;

SELECT username, profile, account_status, expiry_date
FROM dba_users
WHERE username = 'CP_POS';

SPOOL OFF
SET FEEDBACK ON
