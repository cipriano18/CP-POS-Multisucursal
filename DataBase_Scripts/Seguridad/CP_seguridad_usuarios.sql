-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- BASE DE DATOS: Oracle 21c
-- SCRIPT: 16_seguridad_usuarios.sql
-- DESCRIPCION: Creacion de un usuario de base de datos por cada
--              rol de negocio. Cada usuario recibe el rol base
--              como unico rol por defecto; su rol de negocio se
--              activa con PKG_CP_SESION.activar_rol.
--
-- EJECUTAR COMO: SYS en XEPDB1 (despues del script 15)
-- ============================================================

SET SERVEROUTPUT ON
SET VERIFY OFF

-- ============================================================
-- 1. CREACION DE LOS USUARIOS Y CONCESION DE ROLES
-- ============================================================
-- Si el usuario no existe se crea con una clave aleatoria
-- temporal que se reemplaza en la seccion 2.

DECLARE
    PROCEDURE prepare_user (
        p_user IN VARCHAR2,
        p_role IN VARCHAR2
    ) IS
        v_exists PLS_INTEGER;
    BEGIN
        SELECT COUNT(*)
        INTO v_exists
        FROM dba_users
        WHERE username = p_user;

        IF v_exists = 0 THEN
            EXECUTE IMMEDIATE 'CREATE USER '
                || DBMS_ASSERT.SIMPLE_SQL_NAME(p_user)
                || ' IDENTIFIED BY "Zq9#'
                || RAWTOHEX(DBMS_CRYPTO.RANDOMBYTES(13)) || '"'
                || ' PROFILE PRF_CP_USUARIO';
            DBMS_OUTPUT.PUT_LINE('Usuario ' || p_user || ' creado.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Usuario ' || p_user || ' ya existe.');
        END IF;

        EXECUTE IMMEDIATE 'GRANT ROL_CP_CONEXION, '
            || DBMS_ASSERT.SIMPLE_SQL_NAME(p_role)
            || ' TO ' || DBMS_ASSERT.SIMPLE_SQL_NAME(p_user);

        EXECUTE IMMEDIATE 'ALTER USER '
            || DBMS_ASSERT.SIMPLE_SQL_NAME(p_user)
            || ' DEFAULT ROLE ROL_CP_CONEXION';
    END prepare_user;
BEGIN
    prepare_user('USR_CP_GERENTE', 'ROL_CP_GERENTE');
    prepare_user('USR_CP_JEFE_DEPTO', 'ROL_CP_JEFE_DEPARTAMENTO');
    prepare_user('USR_CP_JEFE_PROVEEDURIA', 'ROL_CP_JEFE_PROVEEDURIA');
    prepare_user('USR_CP_DIGITADOR', 'ROL_CP_DIGITADOR');
END;
/

-- ============================================================
-- 2. ASIGNACION DE LAS CLAVES
-- ============================================================
-- Oracle pide una clave por usuario (4 en total) al ejecutar y
-- no quedan guardadas en ningun archivo. Deben tener de 8 a 30
-- caracteres, con letras, numeros y un caracter especial (por
-- ejemplo #), sin comillas, y no contener el nombre del usuario. Si alguna no cumple la verificacion del
-- perfil, Oracle lo informa aqui y basta con volver a ejecutar.

ALTER USER USR_CP_GERENTE IDENTIFIED BY "&clave_gerente" ACCOUNT UNLOCK;

ALTER USER USR_CP_JEFE_DEPTO IDENTIFIED BY "&clave_jefe_depto" ACCOUNT UNLOCK;

ALTER USER USR_CP_JEFE_PROVEEDURIA IDENTIFIED BY "&clave_jefe_prov" ACCOUNT UNLOCK;

ALTER USER USR_CP_DIGITADOR IDENTIFIED BY "&clave_digitador" ACCOUNT UNLOCK;

UNDEFINE clave_gerente
UNDEFINE clave_jefe_depto
UNDEFINE clave_jefe_prov
UNDEFINE clave_digitador

-- ============================================================
-- 3. VERIFICACION
-- ============================================================
-- Los 4 usuarios deben estar OPEN con el perfil PRF_CP_USUARIO.

SELECT username, profile, account_status
FROM dba_users
WHERE username LIKE 'USR_CP_%'
ORDER BY username;

-- default_role debe ser YES solo para ROL_CP_CONEXION.

SELECT grantee, granted_role, default_role
FROM dba_role_privs
WHERE grantee LIKE 'USR_CP_%'
ORDER BY grantee, granted_role;

-- Los usuarios no deben tener privilegios directos (no rows selected).

SELECT grantee, privilege
FROM dba_sys_privs
WHERE grantee LIKE 'USR_CP_%';

SELECT grantee, owner, table_name, privilege
FROM dba_tab_privs
WHERE grantee LIKE 'USR_CP_%';
