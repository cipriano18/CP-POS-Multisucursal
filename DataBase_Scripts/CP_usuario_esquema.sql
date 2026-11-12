
-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- BASE DE DATOS: Oracle 21c
-- SCRIPT: 02_usuario_esquema.sql
-- DESCRIPCION: Creacion del usuario y esquema CP_POS
--              y asignacion de privilegios necesarios
--              para los entregables 1 y 2.
--
-- EJECUTAR COMO: SYS en XEPDB1
-- ============================================================


-- ============================================================
-- 1. CREACION DEL USUARIO
-- ============================================================

CREATE USER CP_POS
IDENTIFIED BY "CP_POS_2026"
DEFAULT TABLESPACE CP_POS_DATOS
TEMPORARY TABLESPACE TEMP
QUOTA UNLIMITED ON CP_POS_DATOS
QUOTA UNLIMITED ON CP_POS_INDICES
QUOTA UNLIMITED ON CP_POS_AUDITORIA;


-- ============================================================
-- 2. PERMISO PARA INICIAR SESION
-- ============================================================

GRANT CREATE SESSION TO CP_POS;


-- ============================================================
-- 3. PERMISO PARA CREAR TABLAS
-- ============================================================

GRANT CREATE TABLE TO CP_POS;


-- ============================================================
-- 4. PERMISO PARA CREAR SECUENCIAS
-- ============================================================

GRANT CREATE SEQUENCE TO CP_POS;


-- ============================================================
-- 5. PERMISO PARA CREAR VISTAS
-- ============================================================

GRANT CREATE VIEW TO CP_POS;


-- ============================================================
-- 6. PERMISO PARA CREAR PROCEDIMIENTOS,
--    FUNCIONES Y PAQUETES
-- ============================================================

GRANT CREATE PROCEDURE TO CP_POS;


-- ============================================================
-- 7. PERMISO PARA CREAR TRIGGERS
-- ============================================================

GRANT CREATE TRIGGER TO CP_POS;


-- ============================================================
-- 8. PERMISO PARA CREAR TAREAS AUTOMATICAS
--    MEDIANTE DBMS_SCHEDULER
-- ============================================================

GRANT CREATE JOB TO CP_POS;


-- ============================================================
-- 9. PERMISO PARA CREAR VISTAS MATERIALIZADAS
-- ============================================================

GRANT CREATE MATERIALIZED VIEW TO CP_POS;


-- ============================================================
-- 10. PERMISOS PARA MONITOREO DE LA BASE DE DATOS
-- ============================================================

-- Consultar el uso de los tablespaces.
GRANT SELECT ON SYS.DBA_TABLESPACE_USAGE_METRICS TO CP_POS;

-- Consultar objetos e identificar objetos invalidos.
GRANT SELECT ON SYS.DBA_OBJECTS TO CP_POS;

-- Consultar informacion de los indices.
GRANT SELECT ON SYS.DBA_INDEXES TO CP_POS;

-- Consultar las sesiones de la base de datos.
GRANT SELECT ON SYS.V_$SESSION TO CP_POS;

-- Calcular la ocupacion de cada tablespace (verificar_tablespaces).
-- Van directo al usuario y no por un rol: un procedimiento almacenado
-- (AUTHID DEFINER) solo ve los privilegios dados directamente a su
-- dueno; los que llegan por un rol se ignoran al compilar.
GRANT SELECT ON SYS.DBA_DATA_FILES TO CP_POS;
GRANT SELECT ON SYS.DBA_FREE_SPACE TO CP_POS;

-- Uso de sesiones y procesos frente a su limite
-- (PKG_CP_MONITOREO.sessions_report). Se usa V$PARAMETER y no
-- V$RESOURCE_LIMIT porque dentro de una PDB este no informa limites.
GRANT SELECT ON SYS.V_$PARAMETER TO CP_POS;
GRANT SELECT ON SYS.V_$PROCESS TO CP_POS;


-- ============================================================
-- 11. PERMISO PARA CIFRADO DE INFORMACION
--     MEDIANTE DBMS_CRYPTO
-- ============================================================

GRANT EXECUTE ON SYS.DBMS_CRYPTO TO CP_POS;


-- ============================================================
-- 12. PERMISO PARA UTILIZAR DBMS_SCHEDULER
-- ============================================================

GRANT EXECUTE ON SYS.DBMS_SCHEDULER TO CP_POS;


-- ============================================================
-- 13. PERMISO PARA UTILIZAR UTL_SMTP
--     ENVIO DE CORREOS DESDE ORACLE
-- ============================================================

GRANT EXECUTE ON SYS.UTL_SMTP TO CP_POS;


-- ============================================================
-- 14. PERMISO PARA UTILIZAR UTL_TCP
--     COMUNICACIONES DE RED DESDE ORACLE
-- ============================================================

GRANT EXECUTE ON SYS.UTL_TCP TO CP_POS;


-- ============================================================
-- 15. PERMISO PARA UTILIZAR DBMS_LOCK
--     EVITA QUE DOS EJECUCIONES PROCESEN LA COLA DE CORREOS
--     A LA VEZ (PKG_CP_NOTIFICACIONES.procesar_pendientes)
-- ============================================================

GRANT EXECUTE ON SYS.DBMS_LOCK TO CP_POS;


-- ============================================================
-- 16. PERMISO DE RED PARA EL SERVIDOR DE CORREO (ACL)
--     Tener EXECUTE sobre UTL_SMTP no basta: desde Oracle 11g
--     cada conexion de red necesita una entrada de control de
--     acceso. Se da solo a CP_POS, solo hacia el servidor SMTP y
--     solo en el puerto 587 (STARTTLS), no acceso de red general.
--     'resolve' permite traducir el nombre del servidor a IP.
--     Si se cambia de proveedor de correo, cambiar el host aqui y
--     en CP_notificaciones_configuracion.sql.
-- ============================================================

BEGIN
    DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
        host       => 'smtp.gmail.com',
        lower_port => 587,
        upper_port => 587,
        ace        => XS$ACE_TYPE(
            privilege_list => XS$NAME_LIST('connect'),
            principal_name => 'CP_POS',
            principal_type => XS_ACL.PTYPE_DB
        )
    );

    DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
        host => 'smtp.gmail.com',
        ace  => XS$ACE_TYPE(
            privilege_list => XS$NAME_LIST('resolve'),
            principal_name => 'CP_POS',
            principal_type => XS_ACL.PTYPE_DB
        )
    );
END;
/

-- Verificacion de los permisos de red de CP_POS
SELECT host, lower_port, upper_port, privilege
FROM   dba_host_aces
WHERE  principal = 'CP_POS'
ORDER  BY host, privilege;
