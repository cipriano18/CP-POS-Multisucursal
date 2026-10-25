-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- BASE DE DATOS: Oracle 21c
-- SCRIPT: 24_facturacion_concurrencia_B.sql
-- DESCRIPCION: Prueba de concurrencia, SESION B. Intenta vender 1
--              unidad del mismo producto mientras la sesion A tiene
--              una venta sin confirmar. Mide cuanto espera y que
--              error recibe. Siempre termina con ROLLBACK.
--
-- EJECUTAR COMO: CP_POS en XEPDB1, en otra conexion distinta a la
--                de la sesion A. Se ejecuta dos veces:
--                  1) con la sesion A todavia sin confirmar
--                     (espera unos 5 segundos y da -20282);
--                  2) despues de escribir ROLLBACK en la sesion A
--                     (la venta se registra de inmediato).
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED

-- ============================================================
-- 1. INTENTO DE VENTA CONCURRENTE
-- ============================================================

DECLARE
    v_almacen    NUMBER;
    v_sucursal   NUMBER;
    v_producto   NUMBER;
    v_cliente    NUMBER;
    v_usuario    NUMBER;
    v_emitida    NUMBER;
    v_factura    NUMBER;
    v_inicio     NUMBER;
    v_segundos   NUMBER;
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

    INSERT INTO CP_FACTURA_VENTA
        (id_cliente, id_sucursal, id_usuario, id_estado_factura_venta,
         numero_factura, fecha_emision, subtotal, descuento_total,
         impuesto_total, total)
    VALUES
        (v_cliente, v_sucursal, v_usuario, v_emitida,
         'TCONC-B', SYSDATE, 0, 0, 0, 0)
    RETURNING id_factura_venta INTO v_factura;

    DBMS_OUTPUT.PUT_LINE('Producto ' || v_producto || ', almacen ' || v_almacen
                         || ': intentando vender 1 unidad...');

    v_inicio := DBMS_UTILITY.GET_TIME;

    BEGIN

        INSERT INTO CP_DETALLE_VENTA_PRODUCTO
            (id_factura_venta, id_producto, cantidad, precio_unitario,
             porcentaje_descuento, monto_descuento, porcentaje_impuesto,
             monto_impuesto, subtotal, total)
        VALUES
            (v_factura, v_producto, 1, 1000, 0, 0, 0, 0, 1000, 1000);

        v_segundos := (DBMS_UTILITY.GET_TIME - v_inicio) / 100;

        DBMS_OUTPUT.PUT_LINE('RESULTADO: venta registrada en ' || v_segundos || ' segundos.');
        DBMS_OUTPUT.PUT_LINE('La sesion A no tenia bloqueado el inventario.');

    EXCEPTION
        WHEN OTHERS THEN

            v_segundos := (DBMS_UTILITY.GET_TIME - v_inicio) / 100;

            DBMS_OUTPUT.PUT_LINE('RESULTADO: espero ' || v_segundos
                                 || ' segundos y recibio el error ' || SQLCODE);
            DBMS_OUTPUT.PUT_LINE(SUBSTR(SQLERRM, 1, 200));

    END;

    ROLLBACK;

    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Sesion B deshecha con ROLLBACK.');

END;
/
