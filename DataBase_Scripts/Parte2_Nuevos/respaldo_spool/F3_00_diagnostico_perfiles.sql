-- ============================================================
-- FASE 3 - SEGURIDAD
-- SCRIPT: F3_00_diagnostico_perfiles.sql
-- EJECUTAR COMO: SYS en XEPDB1
-- ============================================================

-- Configuración de salida
SET PAGESIZE 100
SET LINESIZE 140
SET FEEDBACK OFF
COLUMN profile FORMAT A20
COLUMN resource_name FORMAT A28
COLUMN limit FORMAT A20
COLUMN username FORMAT A15
COLUMN account_status FORMAT A15
COLUMN object_name FORMAT A32

SPOOL "C:\Users\jafet\Documents\UNA\2026 II CICLO\Admin BD\ProyectoParte2\Resultado_diagnostico_perfiles.txt"

-- Contenedor actual
SHOW CON_NAME

-- Límites de contraseña por perfil
SELECT profile, resource_name, limit
FROM dba_profiles
WHERE resource_type = 'PASSWORD'
ORDER BY profile, resource_name;

-- Estado de la cuenta CP_POS
SELECT username, profile, account_status, expiry_date, lock_date
FROM dba_users
WHERE username = 'CP_POS';

-- Funciones de complejidad de contraseña disponibles
SELECT object_name, status
FROM dba_objects
WHERE object_type = 'FUNCTION'
  AND (object_name LIKE 'ORA12C%' OR object_name LIKE 'ORA_%VERIFY%' OR object_name LIKE 'VERIFY_FUNCTION%');

-- Límites de recursos activos
SHOW PARAMETER resource_limit

SPOOL OFF
SET FEEDBACK ON
