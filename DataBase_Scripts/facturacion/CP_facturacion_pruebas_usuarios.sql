-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- BASE DE DATOS: Oracle 21c
-- SCRIPT: 23_facturacion_pruebas_usuarios.sql
-- DESCRIPCION: Pruebas de facturacion e inventario con usuarios
--              reales. Cada usuario activa su rol y prueba solo lo
--              que su rol permite (vender, comprar, devolver) y
--              comprueba que lo demas le es negado, tanto con INSERT
--              y UPDATE directos como a traves de la API
--              PKG_CP_FACTURACION. El inventario y el costo cambian por
--              los triggers, sin que el usuario tenga privilegios sobre
--              CP_INVENTARIO_ALMACEN. No crea objetos; todo se deshace
--              con ROLLBACK al final.
--
-- EJECUTAR COMO: cada uno de los usuarios USR_CP_GERENTE,
--                USR_CP_JEFE_DEPTO, USR_CP_JEFE_PROVEEDURIA y
--                USR_CP_DIGITADOR (el mismo script, una vez por
--                usuario, cada uno en su conexion de XEPDB1).
--                Requiere los scripts 16, 20, 21, 22 y 25 ya ejecutados.
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED

-- ============================================================
-- 1. IDENTIFICACION DEL USUARIO DE LA PRUEBA
-- ============================================================

VARIABLE v_role VARCHAR2(30)

BEGIN
    :v_role := CASE USER
        WHEN 'USR_CP_GERENTE' THEN 'ROL_CP_GERENTE'
        WHEN 'USR_CP_JEFE_DEPTO' THEN 'ROL_CP_JEFE_DEPARTAMENTO'
        WHEN 'USR_CP_JEFE_PROVEEDURIA' THEN 'ROL_CP_JEFE_PROVEEDURIA'
        WHEN 'USR_CP_DIGITADOR' THEN 'ROL_CP_DIGITADOR'
    END;

    DBMS_OUTPUT.PUT_LINE('Usuario conectado ........ ' || USER);
    DBMS_OUTPUT.PUT_LINE('Rol de negocio ........... ' || :v_role);
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
END;
/

-- ============================================================
-- 2. ACTIVACION DEL ROL DE NEGOCIO
-- ============================================================

BEGIN
    CP_POS.PKG_CP_SESION.activar_rol(:v_role);
    DBMS_OUTPUT.PUT_LINE('Rol activado correctamente.');
END;
/

-- ============================================================
-- 3. PRUEBAS DE FACTURACION E INVENTARIO
-- ============================================================

DECLARE
    v_vende        BOOLEAN := USER IN ('USR_CP_DIGITADOR', 'USR_CP_JEFE_DEPTO');
    v_compra       BOOLEAN := USER = 'USR_CP_JEFE_PROVEEDURIA';
    v_devuelve     BOOLEAN := USER = 'USR_CP_JEFE_DEPTO';
    v_sufijo       VARCHAR2(3) := SUBSTR(USER, 8, 3);

    v_msg          VARCHAR2(300);
    v_code         PLS_INTEGER;
    v_code2        PLS_INTEGER;
    v_code3        PLS_INTEGER;

    v_cliente      NUMBER;
    v_usuario      NUMBER;
    v_negocio      NUMBER;
    v_est_emitida  NUMBER;
    v_est_anulada  NUMBER;
    v_est_c_reg    NUMBER;
    v_est_c_anul   NUMBER;
    v_ed_solic     NUMBER;
    v_ed_proces    NUMBER;
    v_motivo       NUMBER;

    v_almacen      NUMBER;
    v_sucursal     NUMBER;
    v_producto     NUMBER;
    v_lote         NUMBER;
    v_stock_ini    NUMBER;
    v_stock_aux    NUMBER;

    v_f_venta      NUMBER;
    v_det_venta    NUMBER;
    v_dvl          NUMBER;
    v_dev          NUMBER;

    v_pp           NUMBER;
    v_proveedor    NUMBER;
    v_prod_compra  NUMBER;
    v_costo        NUMBER;
    v_alm_compra   NUMBER;
    v_stock_c_ini  NUMBER;
    v_f_compra     NUMBER;
    v_det_compra   NUMBER;

    v_f_api        NUMBER;
    v_c_api        NUMBER;

    FUNCTION lit(
        p_valor IN NUMBER
    ) RETURN VARCHAR2
    IS
    BEGIN
        RETURN NVL(REPLACE(TO_CHAR(p_valor), ',', '.'), 'NULL');
    END lit;

    FUNCTION run(
        p_sql IN VARCHAR2
    ) RETURN PLS_INTEGER
    IS
    BEGIN
        v_msg := NULL;
        EXECUTE IMMEDIATE p_sql;
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            v_msg := SUBSTR(SQLERRM, 1, 300);
            RETURN SQLCODE;
    END run;

    FUNCTION num(
        p_sql IN VARCHAR2
    ) RETURN NUMBER
    IS
        v_valor NUMBER;
    BEGIN
        v_msg := NULL;
        EXECUTE IMMEDIATE p_sql INTO v_valor;
        RETURN v_valor;
    EXCEPTION
        WHEN OTHERS THEN
            v_msg := SUBSTR(SQLERRM, 1, 300);
            RETURN NULL;
    END num;

    FUNCTION negado(
        p_code IN PLS_INTEGER
    ) RETURN BOOLEAN
    IS
    BEGIN
        RETURN p_code IN (-1031, -942);
    END negado;

    -- Como negado, pero tambien acepta -6550: un rol sin EXECUTE sobre
    -- el paquete (el GERENTE) ni siquiera puede invocar la API.
    FUNCTION api_negado(
        p_code IN PLS_INTEGER
    ) RETURN BOOLEAN
    IS
    BEGIN
        RETURN negado(p_code) OR p_code = -6550;
    END api_negado;

    FUNCTION stock_de(
        p_almacen  IN NUMBER,
        p_producto IN NUMBER
    ) RETURN NUMBER
    IS
    BEGIN
        RETURN num('SELECT NVL(SUM(cantidad_actual), 0) FROM CP_POS.VW_CP_INVENTARIO_ACTUAL'
                   || ' WHERE id_almacen = ' || lit(p_almacen)
                   || ' AND id_producto = ' || lit(p_producto));
    END stock_de;

    PROCEDURE reportar(
        p_numero IN PLS_INTEGER,
        p_texto  IN VARCHAR2,
        p_ok     IN BOOLEAN,
        p_code   IN PLS_INTEGER DEFAULT NULL
    )
    IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(
            RPAD(p_numero || '. ' || p_texto, 70, '.') || ' '
            || CASE WHEN p_ok THEN 'OK' ELSE 'FALLA' END
            || CASE WHEN p_code IS NOT NULL AND p_code <> 0 THEN ' (' || p_code || ')' END
        );
        IF NOT p_ok AND v_msg IS NOT NULL THEN
            DBMS_OUTPUT.PUT_LINE('      ultimo error: ' || v_msg);
        END IF;
    END reportar;

    PROCEDURE no_aplica(
        p_numero IN PLS_INTEGER,
        p_texto  IN VARCHAR2
    )
    IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(
            RPAD(p_numero || '. ' || p_texto, 70, '.') || ' no aplica a este rol'
        );
    END no_aplica;

    PROCEDURE omitir(
        p_numero IN PLS_INTEGER,
        p_texto  IN VARCHAR2,
        p_motivo IN VARCHAR2
    )
    IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(
            RPAD(p_numero || '. ' || p_texto, 70, '.') || ' omitida: ' || p_motivo
        );
    END omitir;

    -- Llamadas a la API PKG_CP_FACTURACION. Se ejecutan como bloques
    -- dinamicos para que el script compile aunque el usuario no tenga
    -- permisos sobre el paquete; siempre con p_commit => FALSE.

    FUNCTION api_venta(
        p_numero   IN VARCHAR2,
        p_cantidad IN NUMBER,
        p_producto IN NUMBER,
        p_sucursal IN NUMBER
    ) RETURN PLS_INTEGER
    IS
    BEGIN
        RETURN run('DECLARE v_l CP_POS.PKG_CP_FACTURACION.t_lineas_venta; v_id NUMBER; BEGIN '
                   || 'v_l(1).id_producto := ' || lit(p_producto) || '; '
                   || 'v_l(1).cantidad := ' || lit(p_cantidad) || '; '
                   || 'v_l(1).precio_unitario := 1000; '
                   || 'CP_POS.PKG_CP_FACTURACION.registrar_venta('
                   || 'p_id_cliente => ' || lit(v_cliente)
                   || ', p_id_sucursal => ' || lit(p_sucursal)
                   || ', p_id_usuario => ' || lit(v_usuario)
                   || ', p_numero_factura => ''' || p_numero || ''''
                   || ', p_lineas => v_l, p_id_factura => v_id, p_commit => FALSE); END;');
    END api_venta;

    FUNCTION api_anular_venta(
        p_factura IN NUMBER
    ) RETURN PLS_INTEGER
    IS
    BEGIN
        RETURN run('BEGIN CP_POS.PKG_CP_FACTURACION.anular_venta(p_id_factura => '
                   || lit(p_factura) || ', p_commit => FALSE); END;');
    END api_anular_venta;

    FUNCTION api_devolver_venta(
        p_factura IN NUMBER,
        p_dvl     IN NUMBER,
        p_motivo  IN NUMBER
    ) RETURN PLS_INTEGER
    IS
    BEGIN
        RETURN run('DECLARE v_l CP_POS.PKG_CP_FACTURACION.t_lineas_dev_venta; v_id NUMBER; BEGIN '
                   || 'v_l(1).id_detalle_venta_lote := ' || lit(p_dvl) || '; '
                   || 'v_l(1).id_motivo_devolucion := ' || lit(p_motivo) || '; '
                   || 'v_l(1).cantidad := 1; '
                   || 'CP_POS.PKG_CP_FACTURACION.registrar_devolucion_venta('
                   || 'p_id_factura => ' || lit(p_factura)
                   || ', p_id_usuario => ' || lit(v_usuario)
                   || ', p_lineas => v_l, p_id_devolucion => v_id, p_commit => FALSE); END;');
    END api_devolver_venta;

    FUNCTION api_compra(
        p_numero    IN VARCHAR2,
        p_lote      IN VARCHAR2,
        p_pp        IN NUMBER,
        p_proveedor IN NUMBER,
        p_negocio   IN NUMBER,
        p_almacen   IN NUMBER,
        p_costo     IN NUMBER
    ) RETURN PLS_INTEGER
    IS
    BEGIN
        RETURN run('DECLARE v_l CP_POS.PKG_CP_FACTURACION.t_lineas_compra; v_id NUMBER; BEGIN '
                   || 'v_l(1).id_producto_proveedor := ' || lit(p_pp) || '; '
                   || 'v_l(1).cantidad := 5; '
                   || 'v_l(1).precio_costo_unitario := ' || lit(p_costo) || '; '
                   || 'v_l(1).numero_lote := ''' || p_lote || '''; '
                   || 'CP_POS.PKG_CP_FACTURACION.registrar_compra('
                   || 'p_id_proveedor => ' || lit(p_proveedor)
                   || ', p_id_negocio => ' || lit(p_negocio)
                   || ', p_id_almacen_recepcion => ' || lit(p_almacen)
                   || ', p_id_usuario => ' || lit(v_usuario)
                   || ', p_numero_factura => ''' || p_numero || ''''
                   || ', p_lineas => v_l, p_id_factura => v_id, p_commit => FALSE); END;');
    END api_compra;

    FUNCTION api_anular_compra(
        p_factura IN NUMBER
    ) RETURN PLS_INTEGER
    IS
    BEGIN
        RETURN run('BEGIN CP_POS.PKG_CP_FACTURACION.anular_compra(p_id_factura => '
                   || lit(p_factura) || ', p_commit => FALSE); END;');
    END api_anular_compra;

BEGIN

    -- Datos que el usuario puede leer con sus propios privilegios
    v_cliente := num('SELECT MIN(id_cliente) FROM CP_POS.CP_FACTURA_VENTA');
    v_usuario := num('SELECT MIN(id_usuario) FROM CP_POS.CP_FACTURA_VENTA');
    v_negocio := num('SELECT MIN(id_negocio) FROM CP_POS.CP_NEGOCIO');

    v_est_emitida := num('SELECT id_estado_factura_venta FROM CP_POS.CP_ESTADO_FACTURA_VENTA'
                         || ' WHERE nombre_estado_factura = ''EMITIDA''');
    v_est_anulada := num('SELECT id_estado_factura_venta FROM CP_POS.CP_ESTADO_FACTURA_VENTA'
                         || ' WHERE nombre_estado_factura = ''ANULADA''');
    v_est_c_reg := num('SELECT id_estado_factura_compra FROM CP_POS.CP_ESTADO_FACTURA_COMPRA'
                       || ' WHERE nombre_estado_factura = ''REGISTRADA''');
    v_est_c_anul := num('SELECT id_estado_factura_compra FROM CP_POS.CP_ESTADO_FACTURA_COMPRA'
                        || ' WHERE nombre_estado_factura = ''ANULADA''');
    v_ed_solic := num('SELECT id_estado_devolucion FROM CP_POS.CP_ESTADO_DEVOLUCION'
                      || ' WHERE nombre_estado_devolucion = ''SOLICITADA''');
    v_ed_proces := num('SELECT id_estado_devolucion FROM CP_POS.CP_ESTADO_DEVOLUCION'
                       || ' WHERE nombre_estado_devolucion = ''PROCESADA''');
    v_motivo := num('SELECT id_motivo_devolucion FROM CP_POS.CP_MOTIVO_DEVOLUCION'
                    || ' WHERE nombre_motivo_devolucion = ''PRODUCTO INCORRECTO''');

    -- Un producto con inventario vendible en un almacen que sea el unico activo de su sucursal
    BEGIN
        EXECUTE IMMEDIATE
            'SELECT v.id_almacen, a.id_sucursal, v.id_producto, MIN(v.id_lote_producto)'
            || ' FROM CP_POS.VW_CP_INVENTARIO_ACTUAL v'
            || ' JOIN CP_POS.CP_ALMACEN a ON a.id_almacen = v.id_almacen'
            || ' JOIN CP_POS.CP_ESTADO e ON e.id_estado = a.id_estado'
            || ' WHERE e.nombre = ''ACTIVO'''
            || ' AND v.cantidad_actual > 0'
            || ' AND (v.fecha_vencimiento IS NULL OR v.fecha_vencimiento >= TRUNC(SYSDATE))'
            || ' AND (SELECT COUNT(*) FROM CP_POS.CP_ALMACEN a2'
            || '      JOIN CP_POS.CP_ESTADO e2 ON e2.id_estado = a2.id_estado'
            || '      WHERE a2.id_sucursal = a.id_sucursal AND e2.nombre = ''ACTIVO'') = 1'
            || ' GROUP BY v.id_almacen, a.id_sucursal, v.id_producto'
            || ' HAVING SUM(v.cantidad_actual) >= 3'
            || ' ORDER BY SUM(v.cantidad_actual) DESC'
            || ' FETCH FIRST 1 ROW ONLY'
            INTO v_almacen, v_sucursal, v_producto, v_lote;
        v_stock_ini := stock_de(v_almacen, v_producto);
    EXCEPTION
        WHEN OTHERS THEN
            v_almacen := NULL;
            v_msg := SUBSTR(SQLERRM, 1, 300);
    END;

    -- 1 y 2: lo que todos los roles comparten
    reportar(1, 'Lee el inventario por VW_CP_INVENTARIO_ACTUAL',
             num('SELECT COUNT(*) FROM CP_POS.VW_CP_INVENTARIO_ACTUAL') IS NOT NULL);

    v_code := run('UPDATE CP_POS.CP_INVENTARIO_ALMACEN SET cantidad_actual = cantidad_actual WHERE 1 = 0');

    reportar(2, 'No puede modificar CP_INVENTARIO_ALMACEN directamente',
             negado(v_code), v_code);

    -- 3 a 8: ventas y devoluciones de venta
    IF v_vende THEN

        IF v_almacen IS NULL THEN
            omitir(3, 'Registra una factura de venta', 'no hay inventario vendible para probar');
            omitir(4, 'La linea de venta descuenta 1 unidad del inventario', 'sin inventario');
            omitir(5, 'Escribir directo en CP_DETALLE_VENTA_LOTE da -20275', 'sin inventario');
            omitir(6, 'Vender mas de lo que hay da -20273 y no cambia nada', 'sin inventario');
        ELSE

            v_code := run('INSERT INTO CP_POS.CP_FACTURA_VENTA'
                          || ' (id_cliente, id_sucursal, id_usuario, id_estado_factura_venta,'
                          || '  numero_factura, fecha_emision, subtotal, descuento_total,'
                          || '  impuesto_total, total)'
                          || ' VALUES (' || lit(v_cliente) || ', ' || lit(v_sucursal) || ', '
                          || lit(v_usuario) || ', ' || lit(v_est_emitida) || ', ''TU-'
                          || v_sufijo || '-V'', SYSDATE, 0, 0, 0, 0)');

            v_f_venta := num('SELECT id_factura_venta FROM CP_POS.CP_FACTURA_VENTA'
                             || ' WHERE numero_factura = ''TU-' || v_sufijo || '-V''');

            reportar(3, 'Registra una factura de venta',
                     v_code = 0 AND v_f_venta IS NOT NULL, v_code);

            v_code := run('INSERT INTO CP_POS.CP_DETALLE_VENTA_PRODUCTO'
                          || ' (id_factura_venta, id_producto, cantidad, precio_unitario,'
                          || '  porcentaje_descuento, monto_descuento, porcentaje_impuesto,'
                          || '  monto_impuesto, subtotal, total)'
                          || ' VALUES (' || lit(v_f_venta) || ', ' || lit(v_producto)
                          || ', 1, 1000, 0, 0, 0, 0, 1000, 1000)');

            reportar(4, 'La linea de venta descuenta 1 unidad del inventario',
                     v_code = 0 AND stock_de(v_almacen, v_producto) = v_stock_ini - 1, v_code);

            v_det_venta := num('SELECT MIN(id_detalle_venta_producto)'
                               || ' FROM CP_POS.CP_DETALLE_VENTA_PRODUCTO'
                               || ' WHERE id_factura_venta = ' || lit(v_f_venta));

            v_code := run('INSERT INTO CP_POS.CP_DETALLE_VENTA_LOTE'
                          || ' (id_detalle_venta_producto, id_lote_producto, cantidad)'
                          || ' VALUES (' || lit(v_det_venta) || ', ' || lit(v_lote) || ', 1)');

            reportar(5, 'Escribir directo en CP_DETALLE_VENTA_LOTE da -20275',
                     v_code = -20275, v_code);

            v_stock_aux := stock_de(v_almacen, v_producto);

            v_code := run('INSERT INTO CP_POS.CP_DETALLE_VENTA_PRODUCTO'
                          || ' (id_factura_venta, id_producto, cantidad, precio_unitario,'
                          || '  porcentaje_descuento, monto_descuento, porcentaje_impuesto,'
                          || '  monto_impuesto, subtotal, total)'
                          || ' VALUES (' || lit(v_f_venta) || ', ' || lit(v_producto)
                          || ', 1000000, 1000, 0, 0, 0, 0, 1000, 1000)');

            reportar(6, 'Vender mas de lo que hay da -20273 y no cambia nada',
                     v_code = -20273 AND stock_de(v_almacen, v_producto) = v_stock_aux, v_code);

        END IF;

    ELSE

        v_code := run('INSERT INTO CP_POS.CP_FACTURA_VENTA'
                      || ' (id_cliente, id_sucursal, id_usuario, id_estado_factura_venta,'
                      || '  numero_factura, fecha_emision, subtotal, descuento_total,'
                      || '  impuesto_total, total)'
                      || ' VALUES (1, 1, 1, 1, ''TU-' || v_sufijo || '-V'', SYSDATE, 0, 0, 0, 0)');

        reportar(3, 'No puede registrar facturas de venta', negado(v_code), v_code);
        no_aplica(4, 'La linea de venta descuenta 1 unidad del inventario');
        no_aplica(5, 'Escribir directo en CP_DETALLE_VENTA_LOTE da -20275');
        no_aplica(6, 'Vender mas de lo que hay da -20273 y no cambia nada');

    END IF;

    -- 7: devoluciones de venta
    IF v_devuelve THEN

        IF v_f_venta IS NULL THEN
            omitir(7, 'Devolucion: solicitada no mueve, procesada reingresa', 'no hay venta de prueba');
        ELSE

            v_dvl := num('SELECT MIN(dvl.id_detalle_venta_lote)'
                         || ' FROM CP_POS.CP_DETALLE_VENTA_LOTE dvl'
                         || ' JOIN CP_POS.CP_DETALLE_VENTA_PRODUCTO dvp'
                         || ' ON dvp.id_detalle_venta_producto = dvl.id_detalle_venta_producto'
                         || ' WHERE dvp.id_factura_venta = ' || lit(v_f_venta));

            v_code := run('INSERT INTO CP_POS.CP_DEVOLUCION_VENTA'
                          || ' (id_factura_venta, id_estado_devolucion, id_usuario,'
                          || '  fecha_devolucion, monto_total, observacion)'
                          || ' VALUES (' || lit(v_f_venta) || ', ' || lit(v_ed_solic) || ', '
                          || lit(v_usuario) || ', SYSDATE, 0, ''TEST-USR'')');

            v_dev := num('SELECT MAX(id_devolucion_venta) FROM CP_POS.CP_DEVOLUCION_VENTA'
                         || ' WHERE id_factura_venta = ' || lit(v_f_venta));

            v_code2 := run('INSERT INTO CP_POS.CP_DETALLE_DEVOLUCION_VENTA'
                           || ' (id_devolucion_venta, id_detalle_venta_lote, id_motivo_devolucion,'
                           || '  cantidad_devuelta, monto_devolucion)'
                           || ' VALUES (' || lit(v_dev) || ', ' || lit(v_dvl) || ', '
                           || lit(v_motivo) || ', 1, 0)');

            v_stock_aux := stock_de(v_almacen, v_producto);

            v_code3 := run('UPDATE CP_POS.CP_DEVOLUCION_VENTA SET id_estado_devolucion = '
                           || lit(v_ed_proces) || ' WHERE id_devolucion_venta = ' || lit(v_dev));

            reportar(7, 'Devolucion: solicitada no mueve, procesada reingresa',
                     v_code = 0 AND v_code2 = 0 AND v_code3 = 0
                     AND v_stock_aux = v_stock_ini - 1
                     AND stock_de(v_almacen, v_producto) = v_stock_ini,
                     CASE WHEN v_code <> 0 THEN v_code WHEN v_code2 <> 0 THEN v_code2 ELSE v_code3 END);

        END IF;

    ELSE

        v_code := run('INSERT INTO CP_POS.CP_DEVOLUCION_VENTA'
                      || ' (id_factura_venta, id_estado_devolucion, id_usuario,'
                      || '  fecha_devolucion, monto_total, observacion)'
                      || ' VALUES (1, 1, 1, SYSDATE, 0, ''TEST-USR'')');

        reportar(7, 'No puede registrar devoluciones de venta', negado(v_code), v_code);

    END IF;

    -- 8: anular la venta
    IF v_vende AND v_f_venta IS NOT NULL THEN

        v_code := run('UPDATE CP_POS.CP_FACTURA_VENTA SET id_estado_factura_venta = '
                      || lit(v_est_anulada) || ' WHERE id_factura_venta = ' || lit(v_f_venta));

        reportar(8, 'Anular la venta deja el inventario como estaba',
                 v_code = 0 AND stock_de(v_almacen, v_producto) = v_stock_ini, v_code);

    ELSIF v_vende THEN
        omitir(8, 'Anular la venta deja el inventario como estaba', 'no hay venta de prueba');
    ELSE
        no_aplica(8, 'Anular la venta deja el inventario como estaba');
    END IF;

    -- 9 a 11: compras
    IF v_compra THEN

        BEGIN
            EXECUTE IMMEDIATE
                'SELECT id_producto_proveedor, id_proveedor, id_producto, precio_costo_actual'
                || ' FROM CP_POS.CP_PRODUCTO_PROVEEDOR'
                || ' ORDER BY id_producto_proveedor FETCH FIRST 1 ROW ONLY'
                INTO v_pp, v_proveedor, v_prod_compra, v_costo;
            v_alm_compra := num('SELECT MIN(id_almacen) FROM CP_POS.CP_ALMACEN');
            v_stock_c_ini := stock_de(v_alm_compra, v_prod_compra);
        EXCEPTION
            WHEN OTHERS THEN
                v_pp := NULL;
                v_msg := SUBSTR(SQLERRM, 1, 300);
        END;

        IF v_pp IS NULL THEN
            omitir(9, 'Una compra con costo nuevo actualiza el costo del proveedor', 'sin producto-proveedor');
            omitir(10, 'El lote registrado suma 5 al inventario', 'sin producto-proveedor');
            omitir(11, 'Anular la compra retira el lote y deja el costo nuevo', 'sin producto-proveedor');
        ELSE

            v_code := run('INSERT INTO CP_POS.CP_FACTURA_COMPRA'
                          || ' (id_proveedor, id_negocio, id_almacen_recepcion, id_usuario,'
                          || '  id_estado_factura_compra, numero_factura, fecha_emision,'
                          || '  fecha_recepcion, subtotal, descuento_total, impuesto_total, total)'
                          || ' VALUES (' || lit(v_proveedor) || ', ' || lit(v_negocio) || ', '
                          || lit(v_alm_compra) || ', ' || lit(v_usuario) || ', '
                          || lit(v_est_c_reg) || ', ''TU-' || v_sufijo || '-C'', SYSDATE, SYSDATE,'
                          || ' 0, 0, 0, 0)');

            v_f_compra := num('SELECT id_factura_compra FROM CP_POS.CP_FACTURA_COMPRA'
                              || ' WHERE numero_factura = ''TU-' || v_sufijo || '-C''');

            v_code2 := run('INSERT INTO CP_POS.CP_DETALLE_COMPRA'
                           || ' (id_factura_compra, id_producto_proveedor, cantidad,'
                           || '  precio_costo_unitario, monto_descuento, porcentaje_impuesto,'
                           || '  monto_impuesto, subtotal_linea, total_linea)'
                           || ' VALUES (' || lit(v_f_compra) || ', ' || lit(v_pp) || ', 5, '
                           || lit(v_costo + 10) || ', 0, 0, 0, '
                           || lit(5 * (v_costo + 10)) || ', ' || lit(5 * (v_costo + 10)) || ')');

            reportar(9, 'Una compra con costo nuevo actualiza el costo del proveedor',
                     v_code = 0 AND v_code2 = 0
                     AND num('SELECT precio_costo_actual FROM CP_POS.CP_PRODUCTO_PROVEEDOR'
                             || ' WHERE id_producto_proveedor = ' || lit(v_pp)) = v_costo + 10,
                     CASE WHEN v_code <> 0 THEN v_code ELSE v_code2 END);

            v_det_compra := num('SELECT MIN(id_detalle_compra) FROM CP_POS.CP_DETALLE_COMPRA'
                                || ' WHERE id_factura_compra = ' || lit(v_f_compra));

            v_code := run('INSERT INTO CP_POS.CP_LOTE_PRODUCTO'
                          || ' (id_detalle_compra, numero_lote, cantidad_recibida,'
                          || '  fecha_ingreso, fecha_vencimiento)'
                          || ' VALUES (' || lit(v_det_compra) || ', ''TU-' || v_sufijo
                          || '-L'', 5, TRUNC(SYSDATE), NULL)');

            reportar(10, 'El lote registrado suma 5 al inventario',
                     v_code = 0 AND stock_de(v_alm_compra, v_prod_compra) = v_stock_c_ini + 5,
                     v_code);

            v_code := run('UPDATE CP_POS.CP_FACTURA_COMPRA SET id_estado_factura_compra = '
                          || lit(v_est_c_anul) || ' WHERE id_factura_compra = ' || lit(v_f_compra));

            reportar(11, 'Anular la compra retira el lote y deja el costo nuevo',
                     v_code = 0 AND stock_de(v_alm_compra, v_prod_compra) = v_stock_c_ini
                     AND num('SELECT precio_costo_actual FROM CP_POS.CP_PRODUCTO_PROVEEDOR'
                             || ' WHERE id_producto_proveedor = ' || lit(v_pp)) = v_costo + 10,
                     v_code);

        END IF;

    ELSE

        v_code := run('INSERT INTO CP_POS.CP_FACTURA_COMPRA'
                      || ' (id_proveedor, id_negocio, id_almacen_recepcion, id_usuario,'
                      || '  id_estado_factura_compra, numero_factura, fecha_emision,'
                      || '  fecha_recepcion, subtotal, descuento_total, impuesto_total, total)'
                      || ' VALUES (1, 1, 1, 1, 1, ''TU-' || v_sufijo || '-C'', SYSDATE, SYSDATE,'
                      || ' 0, 0, 0, 0)');

        reportar(9, 'No puede registrar facturas de compra', negado(v_code), v_code);
        no_aplica(10, 'El lote registrado suma 5 al inventario');
        no_aplica(11, 'Anular la compra retira el lote y deja el costo nuevo');

    END IF;

    -- 12 a 15: API de ventas, devoluciones y anulaciones
    IF v_vende THEN

        IF v_almacen IS NULL THEN
            omitir(12, 'API: registrar_venta descuenta 1 unidad', 'no hay inventario vendible para probar');
            omitir(13, 'API: vender mas de lo que hay da -20273 y no deja nada', 'sin inventario');
            omitir(14, 'API: devolucion de venta', 'sin inventario');
            omitir(15, 'API: anular_venta deja el inventario como estaba', 'sin inventario');
        ELSE

            v_code := api_venta('TU-' || v_sufijo || '-A', 1, v_producto, v_sucursal);

            v_f_api := num('SELECT id_factura_venta FROM CP_POS.CP_FACTURA_VENTA'
                           || ' WHERE numero_factura = ''TU-' || v_sufijo || '-A''');

            reportar(12, 'API: registrar_venta descuenta 1 unidad',
                     v_code = 0 AND v_f_api IS NOT NULL
                     AND stock_de(v_almacen, v_producto) = v_stock_ini - 1, v_code);

            v_stock_aux := stock_de(v_almacen, v_producto);

            v_code := api_venta('TU-' || v_sufijo || '-B', 1000000, v_producto, v_sucursal);

            reportar(13, 'API: vender mas de lo que hay da -20273 y no deja nada',
                     v_code = -20273 AND stock_de(v_almacen, v_producto) = v_stock_aux
                     AND num('SELECT COUNT(*) FROM CP_POS.CP_FACTURA_VENTA'
                             || ' WHERE numero_factura = ''TU-' || v_sufijo || '-B''') = 0,
                     v_code);

            v_dvl := num('SELECT MIN(dvl.id_detalle_venta_lote)'
                         || ' FROM CP_POS.CP_DETALLE_VENTA_LOTE dvl'
                         || ' JOIN CP_POS.CP_DETALLE_VENTA_PRODUCTO dvp'
                         || ' ON dvp.id_detalle_venta_producto = dvl.id_detalle_venta_producto'
                         || ' WHERE dvp.id_factura_venta = ' || lit(v_f_api));

            v_code := api_devolver_venta(v_f_api, v_dvl, v_motivo);

            IF v_devuelve THEN
                reportar(14, 'API: la devolucion de venta reingresa la unidad',
                         v_code = 0 AND stock_de(v_almacen, v_producto) = v_stock_ini, v_code);
            ELSE
                reportar(14, 'API: no puede registrar devoluciones de venta',
                         negado(v_code), v_code);
            END IF;

            v_code := api_anular_venta(v_f_api);

            reportar(15, 'API: anular_venta deja el inventario como estaba',
                     v_code = 0 AND stock_de(v_almacen, v_producto) = v_stock_ini, v_code);

        END IF;

    ELSE

        v_code := api_venta('TU-' || v_sufijo || '-A', 1, v_producto, v_sucursal);
        reportar(12, 'API: no puede registrar ventas', api_negado(v_code), v_code);

        v_code := api_anular_venta(num('SELECT MIN(id_factura_venta) FROM CP_POS.CP_FACTURA_VENTA'));
        reportar(13, 'API: no puede anular ventas', api_negado(v_code), v_code);

        no_aplica(14, 'API: devolucion de venta');
        no_aplica(15, 'API: anular_venta deja el inventario como estaba');

    END IF;

    -- 16 y 17: API de compras
    IF v_compra THEN

        IF v_pp IS NULL THEN
            omitir(16, 'API: registrar_compra suma 5 unidades y actualiza el costo', 'sin producto-proveedor');
            omitir(17, 'API: anular_compra retira el lote', 'sin producto-proveedor');
        ELSE

            v_code := api_compra('TU-' || v_sufijo || '-D', 'TU-' || v_sufijo || '-M',
                                 v_pp, v_proveedor, v_negocio, v_alm_compra, v_costo + 20);

            v_c_api := num('SELECT id_factura_compra FROM CP_POS.CP_FACTURA_COMPRA'
                           || ' WHERE numero_factura = ''TU-' || v_sufijo || '-D''');

            reportar(16, 'API: registrar_compra suma 5 unidades y actualiza el costo',
                     v_code = 0 AND v_c_api IS NOT NULL
                     AND stock_de(v_alm_compra, v_prod_compra) = v_stock_c_ini + 5
                     AND num('SELECT precio_costo_actual FROM CP_POS.CP_PRODUCTO_PROVEEDOR'
                             || ' WHERE id_producto_proveedor = ' || lit(v_pp)) = v_costo + 20,
                     v_code);

            v_code := api_anular_compra(v_c_api);

            reportar(17, 'API: anular_compra retira el lote',
                     v_code = 0 AND stock_de(v_alm_compra, v_prod_compra) = v_stock_c_ini, v_code);

        END IF;

    ELSE

        v_code := api_compra('TU-' || v_sufijo || '-D', 'TU-' || v_sufijo || '-M',
                             1, 1, 1, 1, 100);
        reportar(16, 'API: no puede registrar compras', api_negado(v_code), v_code);

        v_code := api_anular_compra(num('SELECT MIN(id_factura_compra) FROM CP_POS.CP_FACTURA_COMPRA'));
        reportar(17, 'API: no puede anular compras', api_negado(v_code), v_code);

    END IF;

    ROLLBACK;

END;
/

-- ============================================================
-- 4. ROLES ACTIVOS AL FINAL
-- ============================================================
-- Deben aparecer ROL_CP_CONEXION y el rol de negocio del usuario.

SELECT USER AS usuario, role AS rol_activo
FROM session_roles
ORDER BY role;
