-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- BASE DE DATOS: Oracle 21c
-- SCRIPT: 13_seguridad_privilegios.sql
-- DESCRIPCION: Asignacion de privilegios sobre objetos a los roles
--              de negocio segun el principio de minimo privilegio
--              (requiere que tablas, secuencias y vistas ya existan).
--
-- EJECUTAR COMO: SYS en XEPDB1
--                Es re-ejecutable: correr al final, despues de cada
--                script que cree tablas nuevas (por ejemplo el 14).
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED

-- ============================================================
-- 1. ASIGNACION DE PRIVILEGIOS SOBRE OBJETOS A LOS ROLES
-- ============================================================

DECLARE
    c_owner CONSTANT VARCHAR2(30) := 'CP_POS';

    c_system_tables CONSTANT VARCHAR2(300) :=
        ' CP_CUENTA_COBRAR CP_CUENTA_PAGAR CP_INVENTARIO_ALMACEN'
        || ' CP_EJECUCION_PREMIACION CP_ORDEN_PREMIO_CLIENTE ';

    c_modules CONSTANT VARCHAR2(500) :=
        'CATALOGOS ESTRUCTURA PERSONAS CLIENTES CREDITOS_CLIENTE '
        || 'PROVEEDORES PRODUCTOS PRECIOS INVENTARIO COMPRAS VENTAS '
        || 'DEVOLUCIONES_VENTA PROMOCIONES CIERRE PADRON AUDITORIA '
        || 'SEGURIDAD_APP SISTEMA';

    v_total        PLS_INTEGER := 0;
    v_unclassified PLS_INTEGER := 0;
    v_all          VARCHAR2(8000) := ' ';

    FUNCTION module_objects (
        p_module IN VARCHAR2
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN CASE p_module
            WHEN 'CATALOGOS' THEN
                'CP_TIPO_NEGOCIO CP_ESTADO CP_TIPO_OPERACION CP_PROVINCIA '
                || 'CP_CANTON CP_DISTRITO CP_TIPO_DIRECCION CP_NACIONALIDAD '
                || 'CP_SEXO CP_ESTADO_CIVIL CP_ESCOLARIDAD CP_TIPO_RESIDENCIA '
                || 'CP_TIPO_DE_CONTACTO CP_PUESTO CP_EMPRESA_LABORAL '
                || 'CP_TIPO_ALMACEN CP_TIPO_CLIENTE CP_ESTADO_CLIENTE '
                || 'CP_ESTADO_CREDITO CP_ESTADO_CUENTA_COBRAR '
                || 'CP_ESTADO_CUENTA_PAGAR CP_ESTADO_DESCUENTO '
                || 'CP_ESTADO_DEVOLUCION CP_ESTADO_FACTURA_COMPRA '
                || 'CP_ESTADO_FACTURA_VENTA CP_ESTADO_PROMOCION '
                || 'CP_ESTADO_TRASLADO CP_TIPO_PAGO CP_IMPUESTO '
                || 'CP_FAMILIA_PRODUCTO CP_MOTIVO_DEVOLUCION CP_TIPO_PROMOCION'
            WHEN 'ESTRUCTURA' THEN
                'CP_NEGOCIO CP_SUCURSAL CP_ALMACEN'
            WHEN 'PERSONAS' THEN
                'CP_PERSONA CP_PERSONA_CONTACTO CP_PERSONA_DIRECCION '
                || 'CP_PERSONA_EMPLEO CP_CONTACTO CP_DIRECCION'
            WHEN 'CLIENTES' THEN
                'CP_CLIENTE CP_CLIENTE_PERSONA CP_CLIENTE_EMPRESA '
                || 'CP_CLIENTE_EMPRESA_DIRECCION CP_CLIENTE_EMPRESA_CONTACTO'
            WHEN 'CREDITOS_CLIENTE' THEN
                'CP_CREDITO_CLIENTE VW_CP_CREDITOS_CLIENTES'
            WHEN 'PROVEEDORES' THEN
                'CP_PROVEEDOR CP_PROVEEDOR_DIRECCION CP_PROVEEDOR_CONTACTO '
                || 'CP_CREDITO_PROVEEDOR CP_PRODUCTO_PROVEEDOR '
                || 'VW_CP_CREDITOS_PROVEEDORES'
            WHEN 'PRODUCTOS' THEN
                'CP_PRODUCTO CP_CODIGO_BARRA CP_SERVICIO'
            WHEN 'PRECIOS' THEN
                'CP_PRODUCTO_NEGOCIO VW_CP_PRODUCTOS_PRECIOS'
            WHEN 'INVENTARIO' THEN
                'CP_LOTE_PRODUCTO CP_INVENTARIO_ALMACEN CP_TRASLADO '
                || 'CP_DETALLE_TRASLADO VW_CP_INVENTARIO_ACTUAL '
                || 'VW_CP_PRODUCTOS_POR_VENCER'
            WHEN 'COMPRAS' THEN
                'CP_FACTURA_COMPRA CP_DETALLE_COMPRA CP_CUENTA_PAGAR '
                || 'CP_ABONO_CUENTA_PAGAR CP_DEVOLUCION_COMPRA '
                || 'CP_DETALLE_DEVOLUCION_COMPRA CP_NOTA_CREDITO_PROVEEDOR '
                || 'VW_CP_COMPRAS VW_CP_CUENTAS_PAGAR'
            WHEN 'VENTAS' THEN
                'CP_FACTURA_VENTA CP_DETALLE_VENTA_PRODUCTO '
                || 'CP_DETALLE_VENTA_SERVICIO CP_DETALLE_VENTA_LOTE '
                || 'CP_PAGO_FACTURA_VENTA CP_CUENTA_COBRAR '
                || 'CP_ABONO_CUENTA_COBRAR VW_CP_VENTAS '
                || 'VW_CP_DETALLE_VENTA_LOTES VW_CP_CUENTAS_COBRAR'
            WHEN 'DEVOLUCIONES_VENTA' THEN
                'CP_DEVOLUCION_VENTA CP_DETALLE_DEVOLUCION_VENTA '
                || 'CP_NOTA_CREDITO_CLIENTE'
            WHEN 'PROMOCIONES' THEN
                'CP_PROMOCION CP_ACCION_PROMOCION CP_REGLA_PROMOCION '
                || 'CP_PROMOCION_PATROCINADOR CP_PROMOCION_PREMIO CP_DESCUENTO '
                || 'CP_DESCUENTO_FAMILIA CP_DESCUENTO_PROVEEDOR '
                || 'CP_DESCUENTO_FECHA_INGRESO CP_DESCUENTO_VENCIMIENTO '
                || 'CP_DESCUENTO_APLICADO CP_DESCUENTO_PRODUCTO '
                || 'CP_EJECUCION_PREMIACION CP_ORDEN_PREMIO_CLIENTE'
            WHEN 'CIERRE' THEN
                'CP_CIERRE_DIARIO CP_DETALLE_CIERRE_DIARIO'
            WHEN 'PADRON' THEN
                'CP_PADRON_NACIONAL'
            WHEN 'AUDITORIA' THEN
                'CP_BITACORA_PRECIO CP_BITACORA_TRASLADO CP_BITACORA_INVENTARIO '
                || 'CP_BITACORA_VENTA CP_BITACORA_CREDITO_CLIENTE '
                || 'CP_BITACORA_CREDITO_PROVEEDOR CP_BITACORA_DEVOLUCION_VENTA '
                || 'CP_BITACORA_DEVOLUCION_COMPRA CP_BITACORA_ACCESO '
                || 'CP_BITACORA_CLIENTE CP_BITACORA_COSTO_PRODUCTO '
                || 'CP_BITACORA_DESCUENTO CP_BITACORA_ERROR '
                || 'CP_BITACORA_PROMOCION CP_BITACORA_PROVEEDOR'
            WHEN 'SEGURIDAD_APP' THEN
                'CP_USUARIO CP_ROL CP_PERMISO CP_ROL_PERMISO'
            WHEN 'SISTEMA' THEN
                'CP_CONFIGURACION_CORREO CP_DESTINATARIO_NOTIFICACION '
                || 'CP_NOTIFICACION CP_NOTIFICACION_DESTINATARIO '
                || 'CP_LLAVE_CIFRADO CP_PARAMETRO'
            ELSE NULL
        END;
    END module_objects;

    PROCEDURE grant_object (
        p_privilege IN VARCHAR2,
        p_object    IN VARCHAR2,
        p_role      IN VARCHAR2
    ) IS
    BEGIN
        EXECUTE IMMEDIATE 'GRANT ' || p_privilege
            || ' ON ' || c_owner || '.' || DBMS_ASSERT.SIMPLE_SQL_NAME(p_object)
            || ' TO ' || DBMS_ASSERT.SIMPLE_SQL_NAME(p_role);
        v_total := v_total + 1;
    END grant_object;

    PROCEDURE revoke_all (
        p_role IN VARCHAR2
    ) IS
    BEGIN
        FOR r IN (SELECT privilege, table_name
                  FROM dba_tab_privs
                  WHERE grantee = p_role
                    AND owner = c_owner) LOOP
            EXECUTE IMMEDIATE 'REVOKE ' || r.privilege
                || ' ON ' || c_owner || '.' || DBMS_ASSERT.SIMPLE_SQL_NAME(r.table_name)
                || ' FROM ' || DBMS_ASSERT.SIMPLE_SQL_NAME(p_role);
        END LOOP;
    END revoke_all;

    PROCEDURE apply_access (
        p_role   IN VARCHAR2,
        p_module IN VARCHAR2,
        p_level  IN VARCHAR2
    ) IS
        v_list   VARCHAR2(4000) := module_objects(p_module);
        v_object VARCHAR2(128);
        v_index  PLS_INTEGER := 1;
    BEGIN
        IF v_list IS NULL OR p_level NOT IN ('L', 'LE') THEN
            RAISE_APPLICATION_ERROR(-20100,
                'Modulo o nivel invalido: ' || p_module || '/' || p_level);
        END IF;
        LOOP
            v_object := REGEXP_SUBSTR(v_list, '[^ ]+', 1, v_index);
            EXIT WHEN v_object IS NULL;
            grant_object('SELECT', v_object, p_role);
            IF p_level = 'LE'
               AND v_object NOT LIKE 'VW\_%' ESCAPE '\'
               AND INSTR(c_system_tables, ' ' || v_object || ' ') = 0 THEN
                grant_object('INSERT', v_object, p_role);
                grant_object('UPDATE', v_object, p_role);
                grant_object('SELECT', 'SEQ_' || v_object, p_role);
            END IF;
            v_index := v_index + 1;
        END LOOP;
    END apply_access;
BEGIN
    revoke_all('ROL_CP_GERENTE');
    revoke_all('ROL_CP_JEFE_DEPARTAMENTO');
    revoke_all('ROL_CP_JEFE_PROVEEDURIA');
    revoke_all('ROL_CP_DIGITADOR');

    apply_access('ROL_CP_DIGITADOR', 'CATALOGOS',          'L');
    apply_access('ROL_CP_DIGITADOR', 'ESTRUCTURA',         'L');
    apply_access('ROL_CP_DIGITADOR', 'PERSONAS',           'LE');
    apply_access('ROL_CP_DIGITADOR', 'CLIENTES',           'LE');
    apply_access('ROL_CP_DIGITADOR', 'CREDITOS_CLIENTE',   'L');
    apply_access('ROL_CP_DIGITADOR', 'PRODUCTOS',          'L');
    apply_access('ROL_CP_DIGITADOR', 'PRECIOS',            'L');
    apply_access('ROL_CP_DIGITADOR', 'INVENTARIO',         'L');
    apply_access('ROL_CP_DIGITADOR', 'VENTAS',             'LE');
    apply_access('ROL_CP_DIGITADOR', 'DEVOLUCIONES_VENTA', 'L');
    apply_access('ROL_CP_DIGITADOR', 'PROMOCIONES',        'L');
    apply_access('ROL_CP_DIGITADOR', 'PADRON',             'L');

    apply_access('ROL_CP_JEFE_PROVEEDURIA', 'CATALOGOS',   'L');
    apply_access('ROL_CP_JEFE_PROVEEDURIA', 'ESTRUCTURA',  'L');
    apply_access('ROL_CP_JEFE_PROVEEDURIA', 'PERSONAS',    'LE');
    apply_access('ROL_CP_JEFE_PROVEEDURIA', 'PROVEEDORES', 'LE');
    apply_access('ROL_CP_JEFE_PROVEEDURIA', 'PRODUCTOS',   'LE');
    apply_access('ROL_CP_JEFE_PROVEEDURIA', 'PRECIOS',     'L');
    apply_access('ROL_CP_JEFE_PROVEEDURIA', 'INVENTARIO',  'LE');
    apply_access('ROL_CP_JEFE_PROVEEDURIA', 'COMPRAS',     'LE');
    apply_access('ROL_CP_JEFE_PROVEEDURIA', 'VENTAS',      'L');
    apply_access('ROL_CP_JEFE_PROVEEDURIA', 'PROMOCIONES', 'L');

    apply_access('ROL_CP_JEFE_DEPARTAMENTO', 'CATALOGOS',          'L');
    apply_access('ROL_CP_JEFE_DEPARTAMENTO', 'ESTRUCTURA',         'L');
    apply_access('ROL_CP_JEFE_DEPARTAMENTO', 'PERSONAS',           'LE');
    apply_access('ROL_CP_JEFE_DEPARTAMENTO', 'CLIENTES',           'LE');
    apply_access('ROL_CP_JEFE_DEPARTAMENTO', 'CREDITOS_CLIENTE',   'LE');
    apply_access('ROL_CP_JEFE_DEPARTAMENTO', 'PROVEEDORES',        'L');
    apply_access('ROL_CP_JEFE_DEPARTAMENTO', 'PRODUCTOS',          'L');
    apply_access('ROL_CP_JEFE_DEPARTAMENTO', 'PRECIOS',            'LE');
    apply_access('ROL_CP_JEFE_DEPARTAMENTO', 'INVENTARIO',         'L');
    apply_access('ROL_CP_JEFE_DEPARTAMENTO', 'COMPRAS',            'L');
    apply_access('ROL_CP_JEFE_DEPARTAMENTO', 'VENTAS',             'LE');
    apply_access('ROL_CP_JEFE_DEPARTAMENTO', 'DEVOLUCIONES_VENTA', 'LE');
    apply_access('ROL_CP_JEFE_DEPARTAMENTO', 'PROMOCIONES',        'LE');
    apply_access('ROL_CP_JEFE_DEPARTAMENTO', 'CIERRE',             'L');
    apply_access('ROL_CP_JEFE_DEPARTAMENTO', 'PADRON',             'L');

    apply_access('ROL_CP_GERENTE', 'CATALOGOS',          'L');
    apply_access('ROL_CP_GERENTE', 'ESTRUCTURA',         'L');
    apply_access('ROL_CP_GERENTE', 'PERSONAS',           'L');
    apply_access('ROL_CP_GERENTE', 'CLIENTES',           'L');
    apply_access('ROL_CP_GERENTE', 'CREDITOS_CLIENTE',   'L');
    apply_access('ROL_CP_GERENTE', 'PROVEEDORES',        'L');
    apply_access('ROL_CP_GERENTE', 'PRODUCTOS',          'L');
    apply_access('ROL_CP_GERENTE', 'PRECIOS',            'L');
    apply_access('ROL_CP_GERENTE', 'INVENTARIO',         'L');
    apply_access('ROL_CP_GERENTE', 'COMPRAS',            'L');
    apply_access('ROL_CP_GERENTE', 'VENTAS',             'L');
    apply_access('ROL_CP_GERENTE', 'DEVOLUCIONES_VENTA', 'L');
    apply_access('ROL_CP_GERENTE', 'PROMOCIONES',        'L');
    apply_access('ROL_CP_GERENTE', 'CIERRE',             'L');
    apply_access('ROL_CP_GERENTE', 'PADRON',             'L');
    apply_access('ROL_CP_GERENTE', 'AUDITORIA',          'L');

    -- La API de facturacion (script 25) es un paquete, no una tabla:
    -- revoke_all le quita el EXECUTE a los roles, asi que se otorga de nuevo.
    -- Solo lo reciben los roles que registran documentos.
    FOR r IN (SELECT object_name
              FROM dba_objects
              WHERE owner = c_owner
                AND object_name = 'PKG_CP_FACTURACION'
                AND object_type = 'PACKAGE') LOOP
        grant_object('EXECUTE', r.object_name, 'ROL_CP_DIGITADOR');
        grant_object('EXECUTE', r.object_name, 'ROL_CP_JEFE_DEPARTAMENTO');
        grant_object('EXECUTE', r.object_name, 'ROL_CP_JEFE_PROVEEDURIA');
    END LOOP;

    FOR i IN 1 .. REGEXP_COUNT(c_modules, '[^ ]+') LOOP
        v_all := v_all || module_objects(REGEXP_SUBSTR(c_modules, '[^ ]+', 1, i)) || ' ';
    END LOOP;

    FOR t IN (SELECT table_name
              FROM dba_tables
              WHERE owner = c_owner
              ORDER BY table_name) LOOP
        IF INSTR(v_all, ' ' || t.table_name || ' ') = 0 THEN
            DBMS_OUTPUT.PUT_LINE('SIN CLASIFICAR: ' || t.table_name);
            v_unclassified := v_unclassified + 1;
        END IF;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('Privilegios otorgados: ' || v_total);
    DBMS_OUTPUT.PUT_LINE('Tablas sin clasificar: ' || v_unclassified);
END;
/

-- ============================================================
-- 2. VERIFICACION
-- ============================================================

SELECT grantee, privilege, COUNT(*) AS total
FROM dba_tab_privs
WHERE owner = 'CP_POS'
  AND grantee LIKE 'ROL_CP_%'
GROUP BY grantee, privilege
ORDER BY grantee, privilege;

SELECT grantee, table_name, privilege
FROM dba_tab_privs
WHERE owner = 'CP_POS'
  AND grantee LIKE 'ROL_CP_%'
  AND (privilege = 'DELETE'
       OR table_name IN ('CP_USUARIO', 'CP_CONFIGURACION_CORREO',
                       'CP_LLAVE_CIFRADO', 'CP_PARAMETRO'));
