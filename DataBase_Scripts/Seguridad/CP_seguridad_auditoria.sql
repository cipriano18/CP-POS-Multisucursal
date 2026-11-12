-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- BASE DE DATOS: Oracle 21c
-- SCRIPT: 36_seguridad_auditoria.sql
-- DESCRIPCION: Auditoria de operaciones criticas con la auditoria
--              unificada de Oracle (CREATE AUDIT POLICY). Complementa las
--              bitacoras: un trigger registra QUE cambio en el negocio;
--              la auditoria del motor registra QUIEN lo hizo en la base
--              (usuario de base de datos, usuario del sistema operativo,
--              equipo, programa, sentencia y si fue exitosa), aunque el
--              cambio se haga por fuera de la aplicacion.
--              Tres politicas:
--              - POL_CP_DATOS_CRITICOS: facturas, cuentas y abonos,
--                creditos, precios y costos, inventario, parametros,
--                llaves de cifrado, configuracion del correo y cualquier
--                cambio o borrado en las bitacoras.
--              - POL_CP_SEGURIDAD: usuarios, roles, perfiles, permisos y
--                activacion de roles (SET ROLE).
--              - POL_CP_ACCESO_FALLIDO: inicios de sesion fallidos.
--
-- EJECUTAR COMO: SYS en XEPDB1, despues del 35 (las tablas deben existir).
--                Se puede volver a ejecutar: borra y crea las politicas.
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED

-- ============================================================
-- 1. MODO DE AUDITORIA
-- ============================================================
-- FALSE = modo mixto (el de una instalacion normal). Las politicas
-- unificadas funcionan igual; solo cambia si la auditoria tradicional
-- sigue activa al mismo tiempo.

SELECT parameter, value
FROM   v$option
WHERE  parameter = 'Unified Auditing';

-- ============================================================
-- 2. BORRADO PREVIO DE LAS POLITICAS
-- ============================================================

BEGIN
    FOR p IN (SELECT DISTINCT policy_name
              FROM audit_unified_enabled_policies
              WHERE policy_name IN ('POL_CP_DATOS_CRITICOS', 'POL_CP_SEGURIDAD',
                                    'POL_CP_ACCESO_FALLIDO')) LOOP
        EXECUTE IMMEDIATE 'NOAUDIT POLICY ' || p.policy_name;
    END LOOP;

    FOR p IN (SELECT DISTINCT policy_name
              FROM audit_unified_policies
              WHERE policy_name IN ('POL_CP_DATOS_CRITICOS', 'POL_CP_SEGURIDAD',
                                    'POL_CP_ACCESO_FALLIDO')) LOOP
        EXECUTE IMMEDIATE 'DROP AUDIT POLICY ' || p.policy_name;
    END LOOP;
END;
/

-- ============================================================
-- 3. POLITICA DE DATOS CRITICOS
-- ============================================================
-- No se audita la lectura de las tablas de negocio (seria ruido); si la
-- de CP_LLAVE_CIFRADO, porque leer la llave es leer todos los secretos.
-- CP_BITACORA_ERROR queda fuera del UPDATE/DELETE: las pruebas borran
-- ahi los errores que provocan a proposito.

CREATE AUDIT POLICY POL_CP_DATOS_CRITICOS
    ACTIONS
        INSERT ON CP_POS.CP_FACTURA_VENTA,
        UPDATE ON CP_POS.CP_FACTURA_VENTA,
        DELETE ON CP_POS.CP_FACTURA_VENTA,
        INSERT ON CP_POS.CP_FACTURA_COMPRA,
        UPDATE ON CP_POS.CP_FACTURA_COMPRA,
        DELETE ON CP_POS.CP_FACTURA_COMPRA,
        UPDATE ON CP_POS.CP_CUENTA_COBRAR,
        DELETE ON CP_POS.CP_CUENTA_COBRAR,
        UPDATE ON CP_POS.CP_CUENTA_PAGAR,
        DELETE ON CP_POS.CP_CUENTA_PAGAR,
        INSERT ON CP_POS.CP_ABONO_CUENTA_COBRAR,
        UPDATE ON CP_POS.CP_ABONO_CUENTA_COBRAR,
        DELETE ON CP_POS.CP_ABONO_CUENTA_COBRAR,
        INSERT ON CP_POS.CP_ABONO_CUENTA_PAGAR,
        UPDATE ON CP_POS.CP_ABONO_CUENTA_PAGAR,
        DELETE ON CP_POS.CP_ABONO_CUENTA_PAGAR,
        INSERT ON CP_POS.CP_CREDITO_CLIENTE,
        UPDATE ON CP_POS.CP_CREDITO_CLIENTE,
        DELETE ON CP_POS.CP_CREDITO_CLIENTE,
        INSERT ON CP_POS.CP_CREDITO_PROVEEDOR,
        UPDATE ON CP_POS.CP_CREDITO_PROVEEDOR,
        DELETE ON CP_POS.CP_CREDITO_PROVEEDOR,
        UPDATE ON CP_POS.CP_PRODUCTO_NEGOCIO,
        UPDATE ON CP_POS.CP_PRODUCTO_PROVEEDOR,
        UPDATE ON CP_POS.CP_INVENTARIO_ALMACEN,
        DELETE ON CP_POS.CP_INVENTARIO_ALMACEN,
        INSERT ON CP_POS.CP_PARAMETRO,
        UPDATE ON CP_POS.CP_PARAMETRO,
        DELETE ON CP_POS.CP_PARAMETRO,
        SELECT ON CP_POS.CP_LLAVE_CIFRADO,
        INSERT ON CP_POS.CP_LLAVE_CIFRADO,
        UPDATE ON CP_POS.CP_LLAVE_CIFRADO,
        DELETE ON CP_POS.CP_LLAVE_CIFRADO,
        INSERT ON CP_POS.CP_CONFIGURACION_CORREO,
        UPDATE ON CP_POS.CP_CONFIGURACION_CORREO,
        DELETE ON CP_POS.CP_CONFIGURACION_CORREO,
        UPDATE ON CP_POS.CP_BITACORA_VENTA,
        DELETE ON CP_POS.CP_BITACORA_VENTA,
        UPDATE ON CP_POS.CP_BITACORA_COMPRA,
        DELETE ON CP_POS.CP_BITACORA_COMPRA,
        UPDATE ON CP_POS.CP_BITACORA_INVENTARIO,
        DELETE ON CP_POS.CP_BITACORA_INVENTARIO,
        UPDATE ON CP_POS.CP_BITACORA_PRECIO,
        DELETE ON CP_POS.CP_BITACORA_PRECIO,
        UPDATE ON CP_POS.CP_BITACORA_COSTO_PRODUCTO,
        DELETE ON CP_POS.CP_BITACORA_COSTO_PRODUCTO,
        UPDATE ON CP_POS.CP_BITACORA_CLIENTE,
        DELETE ON CP_POS.CP_BITACORA_CLIENTE,
        UPDATE ON CP_POS.CP_BITACORA_PROVEEDOR,
        DELETE ON CP_POS.CP_BITACORA_PROVEEDOR,
        UPDATE ON CP_POS.CP_BITACORA_PROMOCION,
        DELETE ON CP_POS.CP_BITACORA_PROMOCION,
        UPDATE ON CP_POS.CP_BITACORA_DESCUENTO,
        DELETE ON CP_POS.CP_BITACORA_DESCUENTO,
        UPDATE ON CP_POS.CP_BITACORA_CREDITO_CLIENTE,
        DELETE ON CP_POS.CP_BITACORA_CREDITO_CLIENTE,
        UPDATE ON CP_POS.CP_BITACORA_CREDITO_PROVEEDOR,
        DELETE ON CP_POS.CP_BITACORA_CREDITO_PROVEEDOR;

-- ============================================================
-- 4. POLITICA DE SEGURIDAD Y DE ACCESOS FALLIDOS
-- ============================================================
-- SET ROLE registra cada activacion de un rol con su clave
-- (PKG_CP_SESION, script 17).

CREATE AUDIT POLICY POL_CP_SEGURIDAD
    ACTIONS
        CREATE USER, ALTER USER, DROP USER,
        CREATE ROLE, ALTER ROLE, DROP ROLE,
        CREATE PROFILE, ALTER PROFILE, DROP PROFILE,
        GRANT, REVOKE,
        SET ROLE;

CREATE AUDIT POLICY POL_CP_ACCESO_FALLIDO
    ACTIONS LOGON;

-- ============================================================
-- 5. ACTIVACION
-- ============================================================

AUDIT POLICY POL_CP_DATOS_CRITICOS;
AUDIT POLICY POL_CP_SEGURIDAD;
AUDIT POLICY POL_CP_ACCESO_FALLIDO WHENEVER NOT SUCCESSFUL;

-- ============================================================
-- 6. PRUEBAS
-- ============================================================
-- Un UPDATE que no cambia nada sobre CP_PARAMETRO (y se deshace) y un rol
-- que se crea y se borra deben quedar en la auditoria. Se cuentan los
-- registros antes y despues, sin depender de la zona horaria.

DECLARE
    v_ok     NUMBER := 0;
    v_falla  NUMBER := 0;
    v_count  NUMBER;
    v_before NUMBER;
    v_after  NUMBER;

    PROCEDURE reportar(
        p_prueba IN VARCHAR2,
        p_ok     IN BOOLEAN
    )
    IS
    BEGIN
        IF p_ok THEN
            v_ok := v_ok + 1;
        ELSE
            v_falla := v_falla + 1;
        END IF;
        DBMS_OUTPUT.PUT_LINE(
            RPAD(p_prueba, 76, '.') || CASE WHEN p_ok THEN ' OK' ELSE ' FALLA' END
        );
    END reportar;

    PROCEDURE flush_trail
    IS
    BEGIN
        -- En 21c los registros se escriben al momento; en versiones con
        -- escritura diferida esto los vacia a la tabla. Si no aplica, se ignora.
        DBMS_AUDIT_MGMT.FLUSH_UNIFIED_AUDIT_TRAIL;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END flush_trail;

    FUNCTION audited(
        p_policy IN VARCHAR2,
        p_action IN VARCHAR2,
        p_object IN VARCHAR2
    ) RETURN NUMBER
    IS
        v_total NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_total
        FROM unified_audit_trail
        WHERE unified_audit_policies LIKE '%' || p_policy || '%'
          AND action_name = p_action
          AND (p_object IS NULL OR object_name = p_object);
        RETURN v_total;
    END audited;

BEGIN

    SELECT COUNT(DISTINCT policy_name) INTO v_count
    FROM audit_unified_enabled_policies
    WHERE policy_name IN ('POL_CP_DATOS_CRITICOS', 'POL_CP_SEGURIDAD',
                          'POL_CP_ACCESO_FALLIDO');

    reportar('1. Las tres politicas existen y estan activas', v_count = 3);

    SELECT COUNT(*) INTO v_count
    FROM audit_unified_enabled_policies
    WHERE policy_name = 'POL_CP_ACCESO_FALLIDO'
      AND failure = 'YES' AND success = 'NO';

    reportar('2. Los accesos solo se auditan cuando fallan', v_count >= 1);

    flush_trail;
    v_before := audited('POL_CP_DATOS_CRITICOS', 'UPDATE', 'CP_PARAMETRO');

    UPDATE CP_POS.CP_PARAMETRO
    SET valor = valor
    WHERE codigo_parametro = 'TABLESPACE_UMBRAL_PCT';
    ROLLBACK;

    flush_trail;
    v_after := audited('POL_CP_DATOS_CRITICOS', 'UPDATE', 'CP_PARAMETRO');

    reportar('3. Un cambio en CP_PARAMETRO queda auditado aunque se deshaga',
             v_after > v_before);

    flush_trail;
    v_before := audited('POL_CP_SEGURIDAD', 'CREATE ROLE', NULL)
              + audited('POL_CP_SEGURIDAD', 'DROP ROLE', NULL);

    EXECUTE IMMEDIATE 'CREATE ROLE ROL_CP_T_AUDITORIA';
    EXECUTE IMMEDIATE 'DROP ROLE ROL_CP_T_AUDITORIA';

    flush_trail;
    v_after := audited('POL_CP_SEGURIDAD', 'CREATE ROLE', NULL)
             + audited('POL_CP_SEGURIDAD', 'DROP ROLE', NULL);

    reportar('4. Crear y borrar un rol quedan auditados (2 registros)',
             v_after - v_before >= 2);

    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'Resultado: ' || v_ok || ' OK, '
                         || v_falla || ' FALLA');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        BEGIN
            EXECUTE IMMEDIATE 'DROP ROLE ROL_CP_T_AUDITORIA';
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
        DBMS_OUTPUT.PUT_LINE('ERROR en las pruebas: ' || SQLERRM);
        RAISE;
END;
/

-- ============================================================
-- 7. CONSULTAS PARA LA DEFENSA
-- ============================================================

-- Politicas activas y a quien aplican
SELECT policy_name, enabled_option, entity_name, success, failure
FROM   audit_unified_enabled_policies
WHERE  policy_name LIKE 'POL_CP_%'
ORDER  BY policy_name;

-- Cuantas acciones cubre cada politica
SELECT policy_name, COUNT(*) AS acciones
FROM   audit_unified_policies
WHERE  policy_name LIKE 'POL_CP_%'
GROUP  BY policy_name
ORDER  BY policy_name;

-- Ultimos 20 registros: quien, desde donde, que y si fue exitoso
-- (return_code 0 = exitoso; 1017 = clave incorrecta al iniciar sesion)
SELECT event_timestamp, dbusername, os_username, userhost, client_program_name,
       action_name, object_schema, object_name, return_code, unified_audit_policies
FROM   unified_audit_trail
WHERE  unified_audit_policies LIKE '%POL_CP_%'
ORDER  BY event_timestamp DESC
FETCH FIRST 20 ROWS ONLY;
