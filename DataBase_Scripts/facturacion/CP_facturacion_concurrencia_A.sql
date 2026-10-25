-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- BASE DE DATOS: Oracle 21c
-- SCRIPT: 24_facturacion_concurrencia_A.sql
-- DESCRIPCION: Prueba de concurrencia, SESION A. Vende 1 unidad de
--              un producto con inventario y NO confirma la
--              transaccion: deja bloqueadas las filas de inventario
--              del producto para que la sesion B (script 24, parte B)
--              pruebe la espera y el error -20282.
--
-- EJECUTAR COMO: CP_POS en XEPDB1, en una conexion propia (sesion A).
--                Dejar esta conexion abierta, sin COMMIT, mientras se
--                ejecuta la sesion B. Al terminar escribir ROLLBACK.
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED

-- ============================================================
-- 1. VENTA SIN CONFIRMAR
-- ============================================================

DECLARE
    v_almacen    NUMBER;
    v_sucursal   NUMBER;
    v_producto   NUMBER;
    v_cliente    NUMBER;
    v_usuario    NUMBER;
    v_emitida    NUMBER;
    v_factura    NUMBER;
    v_stock_ant  NUMBER;
    v_stock_des  NUMBER;
BEGIN

    SELECT v.id_almacen, a.id_sucursal, v.id_producto
    INTO v_almacen, v_sucursal, v_producto
    FROM VW_CP_INVENTARIO_ACTUAL v
    JOIN CP_ALMACEN a
      ON a.id_almacen = v.id_almacen
    JOIN CP_ESTADO e
      ON e.id_estado = a.id_estado
    WHERE e.nombre = 'ACTIVO'
      AND v.cantidad_actual > 0
      AND (v.fecha_vencimiento IS NULL OR v.fecha_vencimiento >= TRUNC(SYSDATE))
      AND (SELECT COUNT(*)
           FROM CP_ALMACEN a2
           JOIN CP_ESTADO e2
             ON e2.id_estado = a2.id_estado
           WHERE a2.id_sucursal = a.id_sucursal
             AND e2.nombre = 'ACTIVO') = 1
    GROUP BY v.id_almacen, a.id_sucursal, v.id_producto
    HAVING SUM(v.cantidad_actual) >= 3
    ORDER BY SUM(v.cantidad_actual) DESC, v.id_producto, v.id_almacen
    FETCH FIRST 1 ROW ONLY;

    SELECT MIN(id_cliente) INTO v_cliente FROM CP_CLIENTE;
    SELECT MIN(id_usuario) INTO v_usuario FROM CP_USUARIO;

    SELECT id_estado_factura_venta INTO v_emitida
    FROM CP_ESTADO_FACTURA_VENTA
    WHERE nombre_estado_factura = 'EMITIDA';

    SELECT SUM(cantidad_actual) INTO v_stock_ant
    FROM VW_CP_INVENTARIO_ACTUAL
    WHERE id_almacen = v_almacen
      AND id_producto = v_producto;

    INSERT INTO CP_FACTURA_VENTA
        (id_cliente, id_sucursal, id_usuario, id_estado_factura_venta,
         numero_factura, fecha_emision, subtotal, descuento_total,
         impuesto_total, total)
    VALUES
        (v_cliente, v_sucursal, v_usuario, v_emitida,
         'TCONC-A', SYSDATE, 0, 0, 0, 0)
    RETURNING id_factura_venta INTO v_factura;

    INSERT INTO CP_DETALLE_VENTA_PRODUCTO
        (id_factura_venta, id_producto, cantidad, precio_unitario,
         porcentaje_descuento, monto_descuento, porcentaje_impuesto,
         monto_impuesto, subtotal, total)
    VALUES
        (v_factura, v_producto, 1, 1000, 0, 0, 0, 0, 1000, 1000);

    SELECT SUM(cantidad_actual) INTO v_stock_des
    FROM VW_CP_INVENTARIO_ACTUAL
    WHERE id_almacen = v_almacen
      AND id_producto = v_producto;

    DBMS_OUTPUT.PUT_LINE('Producto ................ ' || v_producto);
    DBMS_OUTPUT.PUT_LINE('Almacen ................. ' || v_almacen);
    DBMS_OUTPUT.PUT_LINE('Inventario antes ........ ' || v_stock_ant);
    DBMS_OUTPUT.PUT_LINE('Inventario en esta sesion ' || v_stock_des);
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Venta TCONC-A registrada SIN confirmar.');
    DBMS_OUTPUT.PUT_LINE('Deje esta conexion abierta y ejecute ahora la sesion B.');
    DBMS_OUTPUT.PUT_LINE('Al terminar, escriba ROLLBACK en esta conexion.');

END;
/


ROLLBACK;