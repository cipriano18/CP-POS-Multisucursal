-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- BASE DE DATOS: Oracle 21c
-- SCRIPT: 32_negocio_explain.sql
-- DESCRIPCION: Analisis con EXPLAIN PLAN de las consultas de los
--              requerimientos funcionales: Fase 4 y padron (CP_01 a
--              CP_09), facturacion (credito y salida FEFO, CP_10 a CP_12),
--              alertas (CP_13 a CP_16) y la comparacion de cada vista
--              materializada con su calculo en vivo (CP_17 a CP_20).
--              Cada sentencia es la misma que ejecuta su paquete; las
--              variables PL/SQL del paquete se reemplazan por valores
--              del mismo tipo (TRUNC(SYSDATE), los parametros por
--              defecto y el primer id existente), porque EXPLAIN PLAN
--              solo necesita la forma de la sentencia.
--
--              1. Estadisticas al dia de las tablas que se analizan
--                 (el optimizador decide con ellas).
--              2. EXPLAIN PLAN de las 20 sentencias.
--              3. Plan completo de cada una (DBMS_XPLAN).
--              4. Resumen: costo, tablas leidas completas e indices, y
--                 el ahorro de las vistas materializadas.
--
--              No modifica datos: EXPLAIN PLAN no ejecuta la sentencia.
--
-- EJECUTAR COMO: CP_POS en XEPDB1, despues de los scripts 27 al 31, del
--                modulo del padron, del 34 y de
--                Notificaciones/CP_notificaciones_paquetes.sql. Se puede
--                volver a ejecutar.
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET SQLBLANKLINES ON
SET LINESIZE 200
SET PAGESIZE 0
SET LONG 100000

-- ============================================================
-- 1. ESTADISTICAS DE LAS TABLAS ANALIZADAS
-- ============================================================

BEGIN
    FOR t IN (SELECT table_name
              FROM user_tables
              WHERE table_name IN (
                    'CP_LOTE_PRODUCTO', 'CP_INVENTARIO_ALMACEN', 'CP_ALMACEN',
                    'CP_SUCURSAL', 'CP_PRODUCTO', 'CP_DESCUENTO',
                    'CP_ESTADO_DESCUENTO', 'CP_DESCUENTO_PRODUCTO',
                    'CP_DESCUENTO_VENCIMIENTO', 'CP_DESCUENTO_FECHA_INGRESO',
                    'CP_DESCUENTO_FAMILIA', 'CP_DESCUENTO_PROVEEDOR',
                    'CP_PRODUCTO_PROVEEDOR', 'CP_FACTURA_VENTA',
                    'CP_ESTADO_FACTURA_VENTA', 'CP_DETALLE_VENTA_PRODUCTO',
                    'CP_DEVOLUCION_VENTA', 'CP_ESTADO_DEVOLUCION',
                    'CP_DETALLE_DEVOLUCION_VENTA', 'CP_CLIENTE',
                    'CP_ESTADO_CLIENTE', 'CP_CLIENTE_PERSONA', 'CP_PERSONA',
                    'CP_PADRON_NACIONAL', 'CP_PROMOCION', 'CP_REGLA_PROMOCION',
                    'CP_PROMOCION_PATROCINADOR', 'CP_TIPO_PROMOCION',
                    'CP_ORDEN_PREMIO_CLIENTE', 'CP_DETALLE_CIERRE_DIARIO',
                    'CP_CUENTA_COBRAR', 'CP_ESTADO_CUENTA_COBRAR',
                    'CP_CUENTA_PAGAR', 'CP_ESTADO_CUENTA_PAGAR',
                    'CP_CREDITO_CLIENTE', 'CP_CREDITO_PROVEEDOR',
                    'CP_ABONO_CUENTA_COBRAR', 'CP_ESTADO_CREDITO', 'CP_NEGOCIO',
                    'CP_PROVEEDOR', 'CP_CLIENTE_EMPRESA', 'CP_PERSONA_CONTACTO',
                    'CP_CLIENTE_EMPRESA_CONTACTO', 'CP_CONTACTO',
                    'CP_TIPO_DE_CONTACTO', 'CP_DETALLE_COMPRA',
                    'MV_CP_VENTAS_MENSUALES', 'MV_CP_INVENTARIO_CONSOLIDADO')
              ORDER BY table_name) LOOP
        DBMS_STATS.GATHER_TABLE_STATS(ownname => USER, tabname => t.table_name, cascade => TRUE);
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Estadisticas actualizadas.');
END;
/

DELETE FROM plan_table WHERE statement_id LIKE 'CP\_%' ESCAPE '\';
COMMIT;

-- ============================================================
-- 2. EXPLAIN PLAN DE LAS SENTENCIAS
-- ============================================================

-- CP_01 Productos por vencer (PKG_CP_VENCIMIENTO.expiring_lots)
EXPLAIN PLAN SET STATEMENT_ID = 'CP_01_POR_VENCER' FOR
SELECT s.nombre_sucursal, v.nombre_almacen, v.nombre_producto, v.numero_lote,
       v.fecha_ingreso, v.fecha_vencimiento, v.cantidad_actual
FROM VW_CP_INVENTARIO_ACTUAL v
JOIN CP_ALMACEN a
  ON a.id_almacen = v.id_almacen
JOIN CP_SUCURSAL s
  ON s.id_sucursal = a.id_sucursal
WHERE v.cantidad_actual > 0
  AND v.fecha_vencimiento >= TRUNC(SYSDATE)
  AND v.fecha_vencimiento <  TRUNC(SYSDATE) + 7 + 1
ORDER BY v.fecha_vencimiento, s.nombre_sucursal, v.nombre_producto, v.numero_lote;

-- CP_02 Productos con mas de 6 meses en bodega (PKG_CP_VENCIMIENTO.stale_lots)
EXPLAIN PLAN SET STATEMENT_ID = 'CP_02_ANTIGUOS' FOR
SELECT s.nombre_sucursal, v.nombre_almacen, v.nombre_producto, v.numero_lote,
       v.fecha_ingreso, v.fecha_vencimiento, v.cantidad_actual
FROM VW_CP_INVENTARIO_ACTUAL v
JOIN CP_ALMACEN a
  ON a.id_almacen = v.id_almacen
JOIN CP_SUCURSAL s
  ON s.id_sucursal = a.id_sucursal
WHERE v.cantidad_actual > 0
  AND v.fecha_ingreso < ADD_MONTHS(TRUNC(SYSDATE), -6)
ORDER BY v.fecha_ingreso, s.nombre_sucursal, v.nombre_producto, v.numero_lote;

-- CP_03 Descuentos programados (PKG_CP_DESCUENTO.apply_scheduled_discounts)
EXPLAIN PLAN SET STATEMENT_ID = 'CP_03_DESCUENTOS' FOR
MERGE INTO CP_DESCUENTO_PRODUCTO t
USING (
    WITH evaluated AS (
        SELECT d.id_descuento, d.id_negocio, d.fecha_inicio, d.fecha_final
        FROM CP_DESCUENTO d
        JOIN CP_ESTADO_DESCUENTO e
          ON e.id_estado_descuento = d.id_estado_descuento
        WHERE e.nombre_estado_descuento IN ('ACTIVO', 'PROGRAMADO')
          AND (d.fecha_final IS NULL OR d.fecha_final >= TRUNC(SYSDATE))
    ),
    stock AS (
        SELECT s.id_negocio, v.id_producto, v.fecha_ingreso, v.fecha_vencimiento
        FROM VW_CP_INVENTARIO_ACTUAL v
        JOIN CP_ALMACEN a
          ON a.id_almacen = v.id_almacen
        JOIN CP_SUCURSAL s
          ON s.id_sucursal = a.id_sucursal
        WHERE v.cantidad_actual > 0
    ),
    qualifying AS (
        SELECT DISTINCT ev.id_descuento, st.id_producto, ev.fecha_inicio, ev.fecha_final
        FROM evaluated ev
        JOIN stock st
          ON st.id_negocio = ev.id_negocio
        JOIN CP_PRODUCTO p
          ON p.id_producto = st.id_producto
        WHERE (
                EXISTS (SELECT 1
                        FROM CP_DESCUENTO_VENCIMIENTO dv
                        WHERE dv.id_descuento = ev.id_descuento
                          AND st.fecha_vencimiento >= TRUNC(SYSDATE)
                          AND st.fecha_vencimiento < TRUNC(SYSDATE) + dv.dias_antes_vencimiento + 1)
                OR EXISTS (SELECT 1
                           FROM CP_DESCUENTO_FECHA_INGRESO di
                           WHERE di.id_descuento = ev.id_descuento
                             AND st.fecha_ingreso >= di.fecha_ingreso_desde
                             AND st.fecha_ingreso < di.fecha_ingreso_hasta + 1)
              )
          AND (
                NOT EXISTS (SELECT 1
                            FROM CP_DESCUENTO_FAMILIA df
                            WHERE df.id_descuento = ev.id_descuento)
                OR EXISTS (SELECT 1
                           FROM CP_DESCUENTO_FAMILIA df
                           WHERE df.id_descuento = ev.id_descuento
                             AND df.id_familia_producto = p.id_familia_producto)
              )
          AND (
                NOT EXISTS (SELECT 1
                            FROM CP_DESCUENTO_PROVEEDOR dpv
                            WHERE dpv.id_descuento = ev.id_descuento)
                OR EXISTS (SELECT 1
                           FROM CP_DESCUENTO_PROVEEDOR dpv
                           JOIN CP_PRODUCTO_PROVEEDOR pp
                             ON pp.id_proveedor = dpv.id_proveedor
                           WHERE dpv.id_descuento = ev.id_descuento
                             AND pp.id_producto = p.id_producto)
              )
    )
    SELECT id_descuento, id_producto,
           MAX(qualifies)    AS qualifies,
           MAX(fecha_inicio) AS fecha_inicio,
           MAX(fecha_final)  AS fecha_final
    FROM (
        SELECT id_descuento, id_producto, 1 AS qualifies, fecha_inicio, fecha_final
        FROM qualifying
        UNION ALL
        SELECT dp.id_descuento, dp.id_producto, 0, NULL, NULL
        FROM CP_DESCUENTO_PRODUCTO dp
        WHERE dp.activo = 'S'
          AND dp.id_descuento IN (SELECT id_descuento FROM evaluated)
    )
    GROUP BY id_descuento, id_producto
) s
ON (t.id_descuento = s.id_descuento AND t.id_producto = s.id_producto)
WHEN MATCHED THEN
    UPDATE SET
        t.activo       = CASE WHEN s.qualifies = 1 THEN 'S' ELSE 'N' END,
        t.fecha_inicio = CASE WHEN s.qualifies = 1 THEN s.fecha_inicio ELSE t.fecha_inicio END,
        t.fecha_fin    = CASE WHEN s.qualifies = 1 THEN s.fecha_final ELSE t.fecha_fin END
    WHERE t.activo <> CASE WHEN s.qualifies = 1 THEN 'S' ELSE 'N' END
       OR (s.qualifies = 1
           AND (DECODE(t.fecha_inicio, s.fecha_inicio, 0, 1) = 1
                OR DECODE(t.fecha_fin, s.fecha_final, 0, 1) = 1))
WHEN NOT MATCHED THEN
    INSERT (id_descuento, id_producto, fecha_inicio, fecha_fin, activo)
    VALUES (s.id_descuento, s.id_producto, s.fecha_inicio, s.fecha_final, 'S');

-- CP_04 Acciones de promocion de una factura (PKG_CP_PROMOCION.invoice_actions)
EXPLAIN PLAN SET STATEMENT_ID = 'CP_04_PROMOCION' FOR
SELECT *
FROM VW_CP_ACCIONES_PROMOCION
WHERE id_factura_venta = 1;

-- CP_05 Los 10 mejores clientes (PKG_CP_PREMIACION.run_awards)
EXPLAIN PLAN SET STATEMENT_ID = 'CP_05_PREMIACION' FOR
INSERT INTO CP_ORDEN_PREMIO_CLIENTE
    (id_ejecucion_premiacion, id_cliente, posicion, monto_premio)
SELECT 1, r.id_cliente, r.posicion, 100000
FROM (
    SELECT v.id_cliente,
           ROW_NUMBER() OVER (ORDER BY SUM(v.total_neto) DESC,
                                       COUNT(*) DESC,
                                       v.id_cliente) AS posicion
    FROM VW_CP_VENTA_NETA_FACTURA v
    JOIN CP_CLIENTE c
      ON c.id_cliente = v.id_cliente
    JOIN CP_ESTADO_CLIENTE ec
      ON ec.id_estado_cliente = c.id_estado_cliente
    WHERE v.fecha_emision >= ADD_MONTHS(TRUNC(SYSDATE), -6)
      AND v.fecha_emision <  TRUNC(SYSDATE)
      AND c.es_cliente_defecto = 'N'
      AND ec.nombre_estado_cliente = 'ACTIVO'
    GROUP BY v.id_cliente
    HAVING SUM(v.total_neto) > 0
) r
WHERE r.posicion <= 10;

-- CP_06 Detalle del cierre diario por cajero (PKG_CP_CIERRE.close_branch_day)
EXPLAIN PLAN SET STATEMENT_ID = 'CP_06_CIERRE' FOR
INSERT INTO CP_DETALLE_CIERRE_DIARIO (
    id_cierre_diario, id_usuario, cantidad_ventas, cantidad_devoluciones,
    unidades_vendidas, unidades_devueltas, total_ventas, total_devoluciones
)
SELECT 1,
       NVL(s.id_usuario, r.id_usuario),
       NVL(s.invoice_count, 0),
       NVL(r.return_count, 0),
       NVL(s.units_sold, 0),
       NVL(r.units_returned, 0),
       NVL(s.total_sales, 0),
       NVL(r.total_returns, 0)
FROM (
        SELECT fv.id_usuario,
               COUNT(*)      AS invoice_count,
               SUM(fv.total) AS total_sales,
               SUM((SELECT SUM(dv.cantidad)
                    FROM CP_DETALLE_VENTA_PRODUCTO dv
                    WHERE dv.id_factura_venta = fv.id_factura_venta)) AS units_sold
        FROM CP_FACTURA_VENTA fv
        JOIN CP_ESTADO_FACTURA_VENTA ef
          ON ef.id_estado_factura_venta = fv.id_estado_factura_venta
        WHERE fv.id_sucursal = 1
          AND fv.fecha_emision >= TRUNC(SYSDATE) - 1
          AND fv.fecha_emision <  TRUNC(SYSDATE)
          AND ef.nombre_estado_factura <> 'ANULADA'
        GROUP BY fv.id_usuario
     ) s
FULL OUTER JOIN (
        SELECT dev.id_usuario,
               COUNT(*)             AS return_count,
               SUM(dev.monto_total) AS total_returns,
               SUM((SELECT SUM(dd.cantidad_devuelta)
                    FROM CP_DETALLE_DEVOLUCION_VENTA dd
                    WHERE dd.id_devolucion_venta = dev.id_devolucion_venta)) AS units_returned
        FROM CP_DEVOLUCION_VENTA dev
        JOIN CP_ESTADO_DEVOLUCION ed
          ON ed.id_estado_devolucion = dev.id_estado_devolucion
        JOIN CP_FACTURA_VENTA fv
          ON fv.id_factura_venta = dev.id_factura_venta
        WHERE fv.id_sucursal = 1
          AND dev.fecha_devolucion >= TRUNC(SYSDATE) - 1
          AND dev.fecha_devolucion <  TRUNC(SYSDATE)
          AND ed.nombre_estado_devolucion = 'PROCESADA'
        GROUP BY dev.id_usuario
     ) r
  ON r.id_usuario = s.id_usuario;

-- CP_07 Buscar una cedula en el padron (PKG_CP_PADRON.find_padron_id y el trigger)
EXPLAIN PLAN SET STATEMENT_ID = 'CP_07_PADRON_CEDULA' FOR
SELECT id_padron
FROM CP_PADRON_NACIONAL
WHERE cedula = '101110111';

-- CP_08 Enlazar las personas con el padron (PKG_CP_PADRON.link_persons)
EXPLAIN PLAN SET STATEMENT_ID = 'CP_08_PADRON_ENLACE' FOR
UPDATE CP_PERSONA p
SET p.id_padron = (SELECT pn.id_padron
                   FROM CP_PADRON_NACIONAL pn
                   WHERE pn.cedula = PKG_CP_PADRON.normalize_id(p.identificacion))
WHERE DECODE(p.id_padron,
             (SELECT pn.id_padron
              FROM CP_PADRON_NACIONAL pn
              WHERE pn.cedula = PKG_CP_PADRON.normalize_id(p.identificacion)),
             0, 1) = 1;

-- CP_09 Datos del padron de un cliente (VW_CP_CLIENTE_PADRON)
EXPLAIN PLAN SET STATEMENT_ID = 'CP_09_CLIENTE_PADRON' FOR
SELECT *
FROM VW_CP_CLIENTE_PADRON
WHERE id_cliente = 1;

-- CP_10 Credito usado de un cliente al facturar (PKG_CP_CREDITO.validar_cliente)
EXPLAIN PLAN SET STATEMENT_ID = 'CP_10_CREDITO_CLIENTE' FOR
SELECT NVL(SUM(cc.saldo_pendiente), 0)
FROM CP_CUENTA_COBRAR cc
JOIN CP_ESTADO_CUENTA_COBRAR ec
  ON ec.id_estado_cuenta_cobrar = cc.id_estado_cuenta_cobrar
WHERE cc.id_credito_cliente = 1
  AND ec.nombre_estado_cuenta_cobrar <> 'ANULADA';

-- CP_11 Credito usado con un proveedor al comprar (PKG_CP_CREDITO.validar_proveedor)
EXPLAIN PLAN SET STATEMENT_ID = 'CP_11_CREDITO_PROVEEDOR' FOR
SELECT NVL(SUM(cp.saldo_pendiente), 0)
FROM CP_CUENTA_PAGAR cp
JOIN CP_ESTADO_CUENTA_PAGAR ep
  ON ep.id_estado_cuenta_pagar = cp.id_estado_cuenta_pagar
WHERE cp.id_credito_proveedor = 1
  AND ep.nombre_estado_cuenta_pagar <> 'ANULADA';

-- CP_12 Salida de inventario FEFO de una venta (PKG_CP_INVENTARIO.descontar_venta)
EXPLAIN PLAN SET STATEMENT_ID = 'CP_12_SALIDA_FEFO' FOR
SELECT ia.id_lote_producto,
       ia.cantidad_actual
FROM CP_INVENTARIO_ALMACEN ia
JOIN CP_LOTE_PRODUCTO lp
  ON lp.id_lote_producto = ia.id_lote_producto
JOIN CP_DETALLE_COMPRA dc
  ON dc.id_detalle_compra = lp.id_detalle_compra
JOIN CP_PRODUCTO_PROVEEDOR pp
  ON pp.id_producto_proveedor = dc.id_producto_proveedor
WHERE ia.id_almacen = 1
  AND pp.id_producto = 1
  AND ia.cantidad_actual > 0
  AND (lp.fecha_vencimiento IS NULL
       OR lp.fecha_vencimiento >= TRUNC(SYSDATE))
ORDER BY lp.fecha_vencimiento NULLS LAST,
         lp.fecha_ingreso,
         lp.id_lote_producto
FOR UPDATE OF ia.cantidad_actual WAIT 5;

-- CP_13 Clientes con el 85 % de su credito (PKG_CP_ALERTA.customer_credits_over)
EXPLAIN PLAN SET STATEMENT_ID = 'CP_13_ALERTA_CREDITO' FOR
SELECT u.id_credito_cliente, u.id_cliente, u.nombre_cliente, u.correo,
       u.limite_credito, u.saldo_utilizado, u.porcentaje_uso
FROM VW_CP_CREDITO_CLIENTE_USO u
WHERE u.estado_credito = 'ACTIVO'
  AND u.limite_credito > 0
  AND u.saldo_utilizado > 0
  AND u.saldo_utilizado >= u.limite_credito * 85 / 100
ORDER BY u.saldo_utilizado / u.limite_credito DESC, u.id_credito_cliente;

-- CP_14 Proveedores con el 70 % de su credito (PKG_CP_ALERTA.supplier_credits_over)
EXPLAIN PLAN SET STATEMENT_ID = 'CP_14_ALERTA_PROVEEDOR' FOR
SELECT u.id_credito_proveedor, u.id_proveedor, u.razon_social, u.nombre_negocio,
       u.limite_credito, u.saldo_utilizado, u.porcentaje_uso
FROM VW_CP_CREDITO_PROVEEDOR_USO u
WHERE u.estado_credito = 'ACTIVO'
  AND u.limite_credito > 0
  AND u.saldo_utilizado > 0
  AND u.saldo_utilizado >= u.limite_credito * 70 / 100
ORDER BY u.saldo_utilizado / u.limite_credito DESC, u.id_credito_proveedor;

-- CP_15 Clientes en mora (PKG_CP_ALERTA.overdue_customers)
EXPLAIN PLAN SET STATEMENT_ID = 'CP_15_ALERTA_MORA' FOR
SELECT m.id_cliente, m.nombre_cliente, m.correo, m.cuentas_abiertas,
       m.saldo_pendiente, m.vencimiento_mas_antiguo, m.ultimo_pago,
       m.fecha_referencia,
       TRUNC(SYSDATE) - TRUNC(m.fecha_referencia) AS dias_sin_pago
FROM VW_CP_CLIENTE_MORA m
WHERE TRUNC(SYSDATE) - TRUNC(m.fecha_referencia) > 30
ORDER BY m.fecha_referencia, m.id_cliente;

-- CP_16 Productos vencidos con existencia (PKG_CP_ALERTA.expired_lots)
EXPLAIN PLAN SET STATEMENT_ID = 'CP_16_ALERTA_VENCIDOS' FOR
SELECT s.nombre_sucursal, a.nombre_almacen, p.codigo_producto, p.nombre_producto,
       lp.numero_lote, lp.fecha_vencimiento, ia.cantidad_actual,
       ia.cantidad_actual * dc.precio_costo_unitario
FROM CP_INVENTARIO_ALMACEN ia
JOIN CP_ALMACEN a
  ON a.id_almacen = ia.id_almacen
JOIN CP_SUCURSAL s
  ON s.id_sucursal = a.id_sucursal
JOIN CP_LOTE_PRODUCTO lp
  ON lp.id_lote_producto = ia.id_lote_producto
JOIN CP_DETALLE_COMPRA dc
  ON dc.id_detalle_compra = lp.id_detalle_compra
JOIN CP_PRODUCTO_PROVEEDOR pp
  ON pp.id_producto_proveedor = dc.id_producto_proveedor
JOIN CP_PRODUCTO p
  ON p.id_producto = pp.id_producto
WHERE lp.fecha_vencimiento < TRUNC(SYSDATE)
  AND ia.cantidad_actual > 0
ORDER BY lp.fecha_vencimiento, s.nombre_sucursal, p.nombre_producto, lp.numero_lote;

-- CP_17 y CP_18: las ventas del mes calculadas en vivo y leidas de la vista
-- materializada (script 34). La diferencia de costo es lo que ahorra la MV.
EXPLAIN PLAN SET STATEMENT_ID = 'CP_17_VENTAS_MES_VIVO' FOR
SELECT periodo, nombre_sucursal, cantidad_facturas, total_ventas, total_neto
FROM VW_CP_VENTAS_MENSUALES
WHERE mes = TRUNC(SYSDATE, 'MM');

EXPLAIN PLAN SET STATEMENT_ID = 'CP_18_VENTAS_MES_MV' FOR
SELECT periodo, nombre_sucursal, cantidad_facturas, total_ventas, total_neto
FROM MV_CP_VENTAS_MENSUALES
WHERE mes = TRUNC(SYSDATE, 'MM');

-- CP_19 y CP_20: lo mismo para el inventario consolidado de una sucursal
EXPLAIN PLAN SET STATEMENT_ID = 'CP_19_INVENTARIO_VIVO' FOR
SELECT nombre_producto, existencia_total, valor_costo, proximo_vencimiento
FROM VW_CP_INVENTARIO_CONSOLIDADO
WHERE id_sucursal = 1;

EXPLAIN PLAN SET STATEMENT_ID = 'CP_20_INVENTARIO_MV' FOR
SELECT nombre_producto, existencia_total, valor_costo, proximo_vencimiento
FROM MV_CP_INVENTARIO_CONSOLIDADO
WHERE id_sucursal = 1;

-- ============================================================
-- 3. PLAN COMPLETO DE CADA SENTENCIA
-- ============================================================

SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'CP_01_POR_VENCER', 'TYPICAL'));
SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'CP_02_ANTIGUOS', 'TYPICAL'));
SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'CP_03_DESCUENTOS', 'TYPICAL'));
SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'CP_04_PROMOCION', 'TYPICAL'));
SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'CP_05_PREMIACION', 'TYPICAL'));
SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'CP_06_CIERRE', 'TYPICAL'));
SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'CP_07_PADRON_CEDULA', 'TYPICAL'));
SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'CP_08_PADRON_ENLACE', 'TYPICAL'));
SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'CP_09_CLIENTE_PADRON', 'TYPICAL'));
SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'CP_10_CREDITO_CLIENTE', 'TYPICAL'));
SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'CP_11_CREDITO_PROVEEDOR', 'TYPICAL'));
SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'CP_12_SALIDA_FEFO', 'TYPICAL'));
SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'CP_13_ALERTA_CREDITO', 'TYPICAL'));
SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'CP_14_ALERTA_PROVEEDOR', 'TYPICAL'));
SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'CP_15_ALERTA_MORA', 'TYPICAL'));
SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'CP_16_ALERTA_VENCIDOS', 'TYPICAL'));
SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'CP_17_VENTAS_MES_VIVO', 'TYPICAL'));
SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'CP_18_VENTAS_MES_MV', 'TYPICAL'));
SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'CP_19_INVENTARIO_VIVO', 'TYPICAL'));
SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'CP_20_INVENTARIO_MV', 'TYPICAL'));

-- ============================================================
-- 4. RESUMEN POR SENTENCIA
-- ============================================================
-- Costo total del plan, tablas que se leen completas (TABLE ACCESS
-- FULL) e indices usados con su forma de acceso.

SET PAGESIZE 100
COLUMN sentencia      FORMAT A26
COLUMN costo          FORMAT 9999999
COLUMN tablas_full    FORMAT A60
COLUMN indices_usados FORMAT A90

SELECT p.statement_id AS sentencia,
       MAX(CASE WHEN p.id = 0 THEN p.cost END) AS costo,
       LISTAGG(DISTINCT CASE WHEN p.operation = 'TABLE ACCESS' AND p.options = 'FULL'
                             THEN p.object_name END, ', ')
           WITHIN GROUP (ORDER BY p.object_name) AS tablas_full,
       LISTAGG(DISTINCT CASE WHEN p.operation = 'INDEX'
                             THEN p.object_name || ' (' || p.options || ')' END, ', ')
           WITHIN GROUP (ORDER BY p.object_name) AS indices_usados
FROM plan_table p
WHERE p.statement_id LIKE 'CP\_%' ESCAPE '\'
GROUP BY p.statement_id
ORDER BY p.statement_id;

-- Filas por tabla, para leer los costos en contexto
SELECT table_name, num_rows, last_analyzed
FROM user_tables
WHERE table_name IN ('CP_LOTE_PRODUCTO', 'CP_INVENTARIO_ALMACEN', 'CP_FACTURA_VENTA',
                     'CP_DETALLE_VENTA_PRODUCTO', 'CP_DEVOLUCION_VENTA', 'CP_CLIENTE',
                     'CP_PERSONA', 'CP_PADRON_NACIONAL', 'CP_DESCUENTO_PRODUCTO',
                     'CP_CUENTA_COBRAR', 'CP_CUENTA_PAGAR', 'CP_CREDITO_CLIENTE',
                     'CP_CREDITO_PROVEEDOR', 'MV_CP_VENTAS_MENSUALES',
                     'MV_CP_INVENTARIO_CONSOLIDADO')
ORDER BY table_name;

-- Lo que ahorra cada vista materializada: costo del calculo en vivo frente
-- al de leer la materializada (la MV paga ese costo una vez por refresco)
COLUMN consulta FORMAT A24
SELECT 'Ventas del mes'            AS consulta,
       MAX(CASE WHEN statement_id = 'CP_17_VENTAS_MES_VIVO' THEN cost END) AS costo_en_vivo,
       MAX(CASE WHEN statement_id = 'CP_18_VENTAS_MES_MV'   THEN cost END) AS costo_mv
FROM plan_table
WHERE id = 0 AND statement_id IN ('CP_17_VENTAS_MES_VIVO', 'CP_18_VENTAS_MES_MV')
UNION ALL
SELECT 'Inventario de sucursal',
       MAX(CASE WHEN statement_id = 'CP_19_INVENTARIO_VIVO' THEN cost END),
       MAX(CASE WHEN statement_id = 'CP_20_INVENTARIO_MV'   THEN cost END)
FROM plan_table
WHERE id = 0 AND statement_id IN ('CP_19_INVENTARIO_VIVO', 'CP_20_INVENTARIO_MV');
