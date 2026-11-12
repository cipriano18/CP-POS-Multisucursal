-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- BASE DE DATOS: Oracle 21c
-- SCRIPT: 34_negocio_vistas_materializadas.sql
-- DESCRIPCION: Vistas materializadas del requisito 9. Las vistas
--              VW_CP_VENTAS_MENSUALES y VW_CP_INVENTARIO_CONSOLIDADO
--              definen el calculo; MV_CP_VENTAS_MENSUALES y
--              MV_CP_INVENTARIO_CONSOLIDADO guardan su resultado y se
--              refrescan completas a peticion (REFRESH COMPLETE ON
--              DEMAND) con PKG_CP_REPORTE y dos jobs.
--              Ventas: por mes y sucursal, sin facturas anuladas; las
--              devoluciones procesadas cuentan en el mes en que se
--              procesan (la misma regla del cierre diario).
--              Inventario: por sucursal y producto, sumando todos los
--              almacenes y lotes, con el valor al costo de cada lote.
--
-- EJECUTAR COMO: CP_POS en XEPDB1 (despues de los scripts 15, 25 y 27).
--                Se puede volver a ejecutar completo: las vistas
--                materializadas se borran y se crean de nuevo, por eso
--                despues hay que volver a correr el 13 como SYS.
--
-- ERRORES PROPIOS (tramo -20370 a -20379):
--   -20370 la vista materializada no la administra PKG_CP_REPORTE
--   -20371 hay una transaccion abierta y el refresco la confirmaria
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED

-- ============================================================
-- 1. BORRADO PREVIO DE LAS VISTAS MATERIALIZADAS
-- ============================================================
-- Su contenido se calcula de otras tablas, asi que borrarlas no pierde
-- datos. ORA-12003: la vista materializada no existe todavia.

DECLARE
    PROCEDURE drop_mview(
        p_name IN VARCHAR2
    )
    IS
    BEGIN
        EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW ' || DBMS_ASSERT.SIMPLE_SQL_NAME(p_name);
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -12003 THEN
                RAISE;
            END IF;
    END drop_mview;
BEGIN
    drop_mview('MV_CP_VENTAS_MENSUALES');
    drop_mview('MV_CP_INVENTARIO_CONSOLIDADO');
END;
/

-- ============================================================
-- 2. VISTA VW_CP_VENTAS_MENSUALES (CALCULO EN VIVO)
-- ============================================================
-- Ventas: facturas no anuladas, por el mes de emision (una factura
-- DEVUELTA sigue contando como venta). Devoluciones: las PROCESADAS,
-- por el mes en que se procesaron; la sucursal sale de la factura.
-- El FULL OUTER JOIN deja tambien los meses con solo devoluciones.

CREATE OR REPLACE VIEW VW_CP_VENTAS_MENSUALES AS
SELECT NVL(v.mes, d.mes)                                    AS mes,
       TO_CHAR(NVL(v.mes, d.mes), 'YYYY-MM')                AS periodo,
       s.id_sucursal,
       s.nombre_sucursal,
       NVL(v.cantidad_facturas, 0)                          AS cantidad_facturas,
       NVL(v.unidades_vendidas, 0)                          AS unidades_vendidas,
       NVL(v.subtotal, 0)                                   AS subtotal,
       NVL(v.descuento_total, 0)                            AS descuento_total,
       NVL(v.impuesto_total, 0)                             AS impuesto_total,
       NVL(v.total_ventas, 0)                               AS total_ventas,
       NVL(d.cantidad_devoluciones, 0)                      AS cantidad_devoluciones,
       NVL(d.unidades_devueltas, 0)                         AS unidades_devueltas,
       NVL(d.total_devoluciones, 0)                         AS total_devoluciones,
       NVL(v.total_ventas, 0) - NVL(d.total_devoluciones, 0) AS total_neto
FROM (
        SELECT TRUNC(fv.fecha_emision, 'MM') AS mes,
               fv.id_sucursal,
               COUNT(*)                      AS cantidad_facturas,
               SUM(NVL(u.unidades, 0))       AS unidades_vendidas,
               SUM(fv.subtotal)              AS subtotal,
               SUM(fv.descuento_total)       AS descuento_total,
               SUM(fv.impuesto_total)        AS impuesto_total,
               SUM(fv.total)                 AS total_ventas
        FROM CP_FACTURA_VENTA fv
        JOIN CP_ESTADO_FACTURA_VENTA ef
          ON ef.id_estado_factura_venta = fv.id_estado_factura_venta
        LEFT JOIN (
                SELECT id_factura_venta, SUM(cantidad) AS unidades
                FROM CP_DETALLE_VENTA_PRODUCTO
                GROUP BY id_factura_venta
             ) u
          ON u.id_factura_venta = fv.id_factura_venta
        WHERE ef.nombre_estado_factura <> 'ANULADA'
        GROUP BY TRUNC(fv.fecha_emision, 'MM'), fv.id_sucursal
     ) v
FULL OUTER JOIN (
        SELECT TRUNC(dev.fecha_devolucion, 'MM') AS mes,
               fv.id_sucursal,
               COUNT(*)                          AS cantidad_devoluciones,
               SUM(NVL(u.unidades, 0))           AS unidades_devueltas,
               SUM(dev.monto_total)              AS total_devoluciones
        FROM CP_DEVOLUCION_VENTA dev
        JOIN CP_ESTADO_DEVOLUCION ed
          ON ed.id_estado_devolucion = dev.id_estado_devolucion
        JOIN CP_FACTURA_VENTA fv
          ON fv.id_factura_venta = dev.id_factura_venta
        LEFT JOIN (
                SELECT id_devolucion_venta, SUM(cantidad_devuelta) AS unidades
                FROM CP_DETALLE_DEVOLUCION_VENTA
                GROUP BY id_devolucion_venta
             ) u
          ON u.id_devolucion_venta = dev.id_devolucion_venta
        WHERE ed.nombre_estado_devolucion = 'PROCESADA'
        GROUP BY TRUNC(dev.fecha_devolucion, 'MM'), fv.id_sucursal
     ) d
  ON d.mes = v.mes
 AND d.id_sucursal = v.id_sucursal
JOIN CP_SUCURSAL s
  ON s.id_sucursal = NVL(v.id_sucursal, d.id_sucursal);

COMMENT ON TABLE VW_CP_VENTAS_MENSUALES IS
    'Calculo en vivo de las ventas por mes y sucursal; es la definicion de MV_CP_VENTAS_MENSUALES';

-- ============================================================
-- 3. VISTA VW_CP_INVENTARIO_CONSOLIDADO (CALCULO EN VIVO)
-- ============================================================
-- Una fila por sucursal y producto: suma todos los almacenes y lotes.
-- El valor usa el costo de compra de cada lote. Un lote sin fecha de
-- vencimiento no cuenta como vencido ni como proximo a vencer.

CREATE OR REPLACE VIEW VW_CP_INVENTARIO_CONSOLIDADO AS
SELECT a.id_sucursal,
       s.nombre_sucursal,
       p.id_producto,
       p.codigo_producto,
       p.nombre_producto,
       SUM(ia.cantidad_actual)                                   AS existencia_total,
       COUNT(DISTINCT CASE WHEN ia.cantidad_actual > 0
                           THEN ia.id_lote_producto END)         AS lotes_con_existencia,
       COUNT(DISTINCT CASE WHEN ia.cantidad_actual > 0
                           THEN ia.id_almacen END)               AS almacenes_con_existencia,
       SUM(ia.cantidad_actual * dc.precio_costo_unitario)        AS valor_costo,
       MIN(CASE WHEN ia.cantidad_actual > 0
                 AND lp.fecha_vencimiento >= TRUNC(SYSDATE)
                THEN lp.fecha_vencimiento END)                   AS proximo_vencimiento,
       SUM(CASE WHEN lp.fecha_vencimiento < TRUNC(SYSDATE)
                THEN ia.cantidad_actual ELSE 0 END)              AS unidades_vencidas,
       MAX(ia.fecha_actualizacion)                               AS ultima_actualizacion
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
GROUP BY a.id_sucursal,
         s.nombre_sucursal,
         p.id_producto,
         p.codigo_producto,
         p.nombre_producto;

COMMENT ON TABLE VW_CP_INVENTARIO_CONSOLIDADO IS
    'Calculo en vivo del inventario por sucursal y producto; es la definicion de MV_CP_INVENTARIO_CONSOLIDADO';

-- ============================================================
-- 4. VISTA MATERIALIZADA MV_CP_VENTAS_MENSUALES
-- ============================================================

CREATE MATERIALIZED VIEW MV_CP_VENTAS_MENSUALES
    TABLESPACE CP_POS_DATOS
    BUILD IMMEDIATE
    REFRESH COMPLETE ON DEMAND
    DISABLE QUERY REWRITE
AS
SELECT v.mes,
       v.periodo,
       v.id_sucursal,
       v.nombre_sucursal,
       v.cantidad_facturas,
       v.unidades_vendidas,
       v.subtotal,
       v.descuento_total,
       v.impuesto_total,
       v.total_ventas,
       v.cantidad_devoluciones,
       v.unidades_devueltas,
       v.total_devoluciones,
       v.total_neto,
       SYSDATE AS fecha_corte
FROM VW_CP_VENTAS_MENSUALES v;

CREATE UNIQUE INDEX IX_MV_CP_VENTAS_MENSUALES
    ON MV_CP_VENTAS_MENSUALES (mes, id_sucursal)
    TABLESPACE CP_POS_INDICES;

COMMENT ON MATERIALIZED VIEW MV_CP_VENTAS_MENSUALES IS
    'Ventas mensuales por sucursal (requisito 9). Refresco completo a peticion: JOB_CP_REFRESCO_VENTAS_MENSUALES o PKG_CP_REPORTE';
COMMENT ON COLUMN MV_CP_VENTAS_MENSUALES.mes IS 'Primer dia del mes';
COMMENT ON COLUMN MV_CP_VENTAS_MENSUALES.periodo IS 'Mes en formato YYYY-MM';
COMMENT ON COLUMN MV_CP_VENTAS_MENSUALES.cantidad_facturas IS 'Facturas emitidas en el mes, sin las anuladas';
COMMENT ON COLUMN MV_CP_VENTAS_MENSUALES.unidades_vendidas IS 'Unidades de producto vendidas en esas facturas';
COMMENT ON COLUMN MV_CP_VENTAS_MENSUALES.total_ventas IS 'Suma del total de esas facturas';
COMMENT ON COLUMN MV_CP_VENTAS_MENSUALES.cantidad_devoluciones IS 'Devoluciones procesadas en el mes';
COMMENT ON COLUMN MV_CP_VENTAS_MENSUALES.total_devoluciones IS 'Monto de las devoluciones procesadas en el mes';
COMMENT ON COLUMN MV_CP_VENTAS_MENSUALES.total_neto IS 'total_ventas menos total_devoluciones';
COMMENT ON COLUMN MV_CP_VENTAS_MENSUALES.fecha_corte IS 'Momento del ultimo refresco: los datos son de ese momento';

-- ============================================================
-- 5. VISTA MATERIALIZADA MV_CP_INVENTARIO_CONSOLIDADO
-- ============================================================

CREATE MATERIALIZED VIEW MV_CP_INVENTARIO_CONSOLIDADO
    TABLESPACE CP_POS_DATOS
    BUILD IMMEDIATE
    REFRESH COMPLETE ON DEMAND
    DISABLE QUERY REWRITE
AS
SELECT i.id_sucursal,
       i.nombre_sucursal,
       i.id_producto,
       i.codigo_producto,
       i.nombre_producto,
       i.existencia_total,
       i.lotes_con_existencia,
       i.almacenes_con_existencia,
       i.valor_costo,
       i.proximo_vencimiento,
       i.unidades_vencidas,
       i.ultima_actualizacion,
       SYSDATE AS fecha_corte
FROM VW_CP_INVENTARIO_CONSOLIDADO i;

CREATE UNIQUE INDEX IX_MV_CP_INVENTARIO_CONSOLIDADO
    ON MV_CP_INVENTARIO_CONSOLIDADO (id_sucursal, id_producto)
    TABLESPACE CP_POS_INDICES;

COMMENT ON MATERIALIZED VIEW MV_CP_INVENTARIO_CONSOLIDADO IS
    'Inventario consolidado por sucursal y producto (requisito 9). Refresco completo a peticion: JOB_CP_REFRESCO_INVENTARIO o PKG_CP_REPORTE';
COMMENT ON COLUMN MV_CP_INVENTARIO_CONSOLIDADO.existencia_total IS 'Unidades en todos los almacenes y lotes de la sucursal';
COMMENT ON COLUMN MV_CP_INVENTARIO_CONSOLIDADO.lotes_con_existencia IS 'Lotes con unidades disponibles';
COMMENT ON COLUMN MV_CP_INVENTARIO_CONSOLIDADO.almacenes_con_existencia IS 'Almacenes con unidades disponibles';
COMMENT ON COLUMN MV_CP_INVENTARIO_CONSOLIDADO.valor_costo IS 'Existencia por el costo unitario de compra de cada lote';
COMMENT ON COLUMN MV_CP_INVENTARIO_CONSOLIDADO.proximo_vencimiento IS 'Vencimiento mas cercano entre los lotes con existencia que no han vencido';
COMMENT ON COLUMN MV_CP_INVENTARIO_CONSOLIDADO.unidades_vencidas IS 'Unidades de lotes ya vencidos al momento del corte';
COMMENT ON COLUMN MV_CP_INVENTARIO_CONSOLIDADO.fecha_corte IS 'Momento del ultimo refresco: los datos son de ese momento';

-- ============================================================
-- 6. PAQUETE PKG_CP_REPORTE (ESPECIFICACION)
-- ============================================================

CREATE OR REPLACE PACKAGE PKG_CP_REPORTE AUTHID DEFINER AS

    c_mv_ventas     CONSTANT VARCHAR2(30) := 'MV_CP_VENTAS_MENSUALES';
    c_mv_inventario CONSTANT VARCHAR2(30) := 'MV_CP_INVENTARIO_CONSOLIDADO';

    -- Refresca una de las dos vistas materializadas por su nombre.
    PROCEDURE refresh_mview(
        p_name IN VARCHAR2
    );

    -- Lo ejecuta JOB_CP_REFRESCO_VENTAS_MENSUALES.
    PROCEDURE refresh_monthly_sales;

    -- Lo ejecuta JOB_CP_REFRESCO_INVENTARIO.
    PROCEDURE refresh_inventory;

    -- Las dos en una sola transaccion, para la revision a peticion.
    PROCEDURE refresh_all;

END PKG_CP_REPORTE;
/

-- ============================================================
-- 7. PAQUETE PKG_CP_REPORTE (CUERPO)
-- ============================================================
-- DBMS_MVIEW.REFRESH confirma (COMMIT) la transaccion de la sesion, por
-- eso estos procedimientos no llevan SAVEPOINT: no habria a que volver.
-- En su lugar se niegan a refrescar si hay cambios sin confirmar, y nunca
-- se llaman desde los paquetes de negocio.

CREATE OR REPLACE PACKAGE BODY PKG_CP_REPORTE AS

    c_modulo CONSTANT VARCHAR2(20) := 'REPORTE';

    c_err_mview      CONSTANT PLS_INTEGER := -20370;
    c_err_open_trans CONSTANT PLS_INTEGER := -20371;


    PROCEDURE assert_no_open_transaction(
        p_list IN VARCHAR2
    )
    IS
    BEGIN

        IF DBMS_TRANSACTION.LOCAL_TRANSACTION_ID IS NOT NULL THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_open_trans,
                'Hay una transaccion abierta: refrescar ' || p_list
                || ' la confirmaria. Haga COMMIT o ROLLBACK antes de refrescar.'
            );
        END IF;

    END assert_no_open_transaction;


    PROCEDURE do_refresh(
        p_list IN VARCHAR2
    )
    IS
    BEGIN

        assert_no_open_transaction(p_list);

        -- atomic_refresh: el contenido se reemplaza en una sola transaccion;
        -- quien consulta durante el refresco ve los datos anteriores, nunca
        -- la vista vacia
        DBMS_MVIEW.REFRESH(
            list           => p_list,
            method         => 'C',
            atomic_refresh => TRUE
        );

    EXCEPTION
        WHEN OTHERS THEN
            PKG_CP_ERROR.registrar_inesperado(c_modulo, 'vistas=' || p_list);
            RAISE;
    END do_refresh;


    PROCEDURE refresh_mview(
        p_name IN VARCHAR2
    )
    IS
        v_name VARCHAR2(4000) := UPPER(TRIM(p_name));
    BEGIN

        IF v_name IS NULL OR v_name NOT IN (c_mv_ventas, c_mv_inventario) THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_mview,
                'PKG_CP_REPORTE no administra la vista materializada '
                || NVL(SUBSTR(p_name, 1, 128), '(nula)') || '.'
            );
        END IF;

        do_refresh(v_name);

    END refresh_mview;


    PROCEDURE refresh_monthly_sales
    IS
    BEGIN
        do_refresh(c_mv_ventas);
    END refresh_monthly_sales;


    PROCEDURE refresh_inventory
    IS
    BEGIN
        do_refresh(c_mv_inventario);
    END refresh_inventory;


    PROCEDURE refresh_all
    IS
    BEGIN
        do_refresh(c_mv_ventas || ',' || c_mv_inventario);
    END refresh_all;

END PKG_CP_REPORTE;
/

SHOW ERRORS PACKAGE BODY PKG_CP_REPORTE

-- ============================================================
-- 8. PRUEBAS DE LAS VISTAS MATERIALIZADAS
-- ============================================================
-- Todas deben salir OK. El refresco confirma, asi que no se pueden
-- meter datos de prueba y refrescar: se compara cada vista materializada
-- con su vista de calculo. La venta de prueba (11 a 13) nunca se
-- confirma: muestra el desfase y que el refresco se niega a confirmarla.
-- Solo se borran de la bitacora los errores provocados a proposito.

DECLARE
    v_antes     NUMBER;
    v_ok        NUMBER := 0;
    v_falla     NUMBER := 0;
    v_start     DATE;
    v_mark      DATE;
    v_count     NUMBER;
    v_count2    NUMBER;
    v_code      NUMBER;
    v_sum_a     NUMBER;
    v_sum_b     NUMBER;
    v_done      BOOLEAN;

    v_almacen   NUMBER;
    v_sucursal  NUMBER;
    v_producto  NUMBER;
    v_cliente   NUMBER;
    v_usuario   NUMBER;
    v_factura   NUMBER;
    v_numero    VARCHAR2(50) := 'T34-' || TO_CHAR(SYSDATE, 'MMDDHH24MISS');
    v_lines     PKG_CP_FACTURACION.t_lineas_venta;
    v_have_sale BOOLEAN := FALSE;
    v_live      NUMBER;
    v_cached    NUMBER;
    v_open      BOOLEAN;

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
            RPAD(p_prueba, 72, '.') || CASE WHEN p_ok THEN ' OK' ELSE ' FALLA' END
        );
    END reportar;

    FUNCTION refresh_code(
        p_name IN VARCHAR2
    ) RETURN NUMBER
    IS
    BEGIN
        PKG_CP_REPORTE.refresh_mview(p_name);
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN SQLCODE;
    END refresh_code;

    FUNCTION refreshed_since(
        p_name  IN VARCHAR2,
        p_since IN DATE
    ) RETURN BOOLEAN
    IS
        v_date DATE;
    BEGIN
        SELECT last_refresh_date INTO v_date
        FROM user_mviews
        WHERE mview_name = p_name;
        RETURN v_date >= p_since;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END refreshed_since;

    FUNCTION cached_invoices RETURN NUMBER
    IS
        v_total NUMBER;
    BEGIN
        SELECT NVL(SUM(cantidad_facturas), 0) INTO v_total
        FROM MV_CP_VENTAS_MENSUALES
        WHERE mes = TRUNC(SYSDATE, 'MM') AND id_sucursal = v_sucursal;
        RETURN v_total;
    END cached_invoices;

    FUNCTION live_invoices RETURN NUMBER
    IS
        v_total NUMBER;
    BEGIN
        SELECT NVL(SUM(cantidad_facturas), 0) INTO v_total
        FROM VW_CP_VENTAS_MENSUALES
        WHERE mes = TRUNC(SYSDATE, 'MM') AND id_sucursal = v_sucursal;
        RETURN v_total;
    END live_invoices;

BEGIN

    SELECT NVL(MAX(id_bitacora_error), 0) INTO v_antes FROM CP_BITACORA_ERROR;

    -- Un segundo de separacion con la creacion: asi "refrescada desde el
    -- inicio de las pruebas" no se cumple solo por haberla creado
    DBMS_SESSION.SLEEP(1);
    v_start := SYSDATE;

    -- ------------------------------------------------------------
    -- A. Estructura
    -- ------------------------------------------------------------
    SELECT COUNT(*) INTO v_count
    FROM user_mviews
    WHERE mview_name IN (PKG_CP_REPORTE.c_mv_ventas, PKG_CP_REPORTE.c_mv_inventario)
      AND refresh_method = 'COMPLETE'
      AND refresh_mode = 'DEMAND'
      AND rewrite_enabled = 'N';

    reportar('1. Las dos vistas materializadas existen, completas y a peticion',
             v_count = 2);

    SELECT COUNT(*) INTO v_count
    FROM user_tables
    WHERE table_name IN (PKG_CP_REPORTE.c_mv_ventas, PKG_CP_REPORTE.c_mv_inventario)
      AND tablespace_name = 'CP_POS_DATOS';

    SELECT COUNT(*) INTO v_count2
    FROM user_indexes
    WHERE index_name IN ('IX_MV_CP_VENTAS_MENSUALES', 'IX_MV_CP_INVENTARIO_CONSOLIDADO')
      AND uniqueness = 'UNIQUE'
      AND tablespace_name = 'CP_POS_INDICES';

    reportar('2. Datos en CP_POS_DATOS e indice unico en CP_POS_INDICES',
             v_count = 2 AND v_count2 = 2);

    -- ------------------------------------------------------------
    -- B. Refresco
    -- ------------------------------------------------------------
    v_code := refresh_code(PKG_CP_REPORTE.c_mv_ventas);

    reportar('3. refresh_mview refresca las ventas mensuales',
             v_code = 0 AND refreshed_since(PKG_CP_REPORTE.c_mv_ventas, v_start));

    BEGIN
        PKG_CP_REPORTE.refresh_inventory;
        v_done := TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            v_done := FALSE;
    END;

    reportar('4. refresh_inventory refresca el inventario consolidado',
             v_done AND refreshed_since(PKG_CP_REPORTE.c_mv_inventario, v_start));

    DBMS_SESSION.SLEEP(1);
    v_mark := SYSDATE;

    BEGIN
        PKG_CP_REPORTE.refresh_all;
        v_done := TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            v_done := FALSE;
    END;

    reportar('5. refresh_all refresca las dos',
             v_done
             AND refreshed_since(PKG_CP_REPORTE.c_mv_ventas, v_mark)
             AND refreshed_since(PKG_CP_REPORTE.c_mv_inventario, v_mark));

    -- ------------------------------------------------------------
    -- C. Contenido: cada materializada es igual a su calculo en vivo
    -- ------------------------------------------------------------
    SELECT COUNT(*) INTO v_count FROM (
        SELECT mes, id_sucursal, cantidad_facturas, unidades_vendidas, subtotal,
               descuento_total, impuesto_total, total_ventas, cantidad_devoluciones,
               unidades_devueltas, total_devoluciones, total_neto
        FROM MV_CP_VENTAS_MENSUALES
        MINUS
        SELECT mes, id_sucursal, cantidad_facturas, unidades_vendidas, subtotal,
               descuento_total, impuesto_total, total_ventas, cantidad_devoluciones,
               unidades_devueltas, total_devoluciones, total_neto
        FROM VW_CP_VENTAS_MENSUALES
    );

    SELECT COUNT(*) INTO v_count2 FROM (
        SELECT mes, id_sucursal, cantidad_facturas, unidades_vendidas, subtotal,
               descuento_total, impuesto_total, total_ventas, cantidad_devoluciones,
               unidades_devueltas, total_devoluciones, total_neto
        FROM VW_CP_VENTAS_MENSUALES
        MINUS
        SELECT mes, id_sucursal, cantidad_facturas, unidades_vendidas, subtotal,
               descuento_total, impuesto_total, total_ventas, cantidad_devoluciones,
               unidades_devueltas, total_devoluciones, total_neto
        FROM MV_CP_VENTAS_MENSUALES
    );

    reportar('6. Ventas: la materializada coincide fila por fila con el calculo',
             v_count = 0 AND v_count2 = 0);

    SELECT COUNT(*) INTO v_count FROM (
        SELECT id_sucursal, id_producto, existencia_total, lotes_con_existencia,
               almacenes_con_existencia, valor_costo, proximo_vencimiento,
               unidades_vencidas, ultima_actualizacion
        FROM MV_CP_INVENTARIO_CONSOLIDADO
        MINUS
        SELECT id_sucursal, id_producto, existencia_total, lotes_con_existencia,
               almacenes_con_existencia, valor_costo, proximo_vencimiento,
               unidades_vencidas, ultima_actualizacion
        FROM VW_CP_INVENTARIO_CONSOLIDADO
    );

    SELECT COUNT(*) INTO v_count2 FROM (
        SELECT id_sucursal, id_producto, existencia_total, lotes_con_existencia,
               almacenes_con_existencia, valor_costo, proximo_vencimiento,
               unidades_vencidas, ultima_actualizacion
        FROM VW_CP_INVENTARIO_CONSOLIDADO
        MINUS
        SELECT id_sucursal, id_producto, existencia_total, lotes_con_existencia,
               almacenes_con_existencia, valor_costo, proximo_vencimiento,
               unidades_vencidas, ultima_actualizacion
        FROM MV_CP_INVENTARIO_CONSOLIDADO
    );

    reportar('7. Inventario: la materializada coincide fila por fila con el calculo',
             v_count = 0 AND v_count2 = 0);

    SELECT NVL(SUM(total_ventas), 0) INTO v_sum_a FROM MV_CP_VENTAS_MENSUALES;
    SELECT NVL(SUM(total), 0) INTO v_sum_b FROM VW_CP_VENTA_NETA_FACTURA;

    reportar('8. El total vendido es el mismo de VW_CP_VENTA_NETA_FACTURA',
             v_sum_a = v_sum_b);

    SELECT NVL(SUM(existencia_total), 0) INTO v_sum_a FROM MV_CP_INVENTARIO_CONSOLIDADO;
    SELECT NVL(SUM(cantidad_actual), 0) INTO v_sum_b FROM VW_CP_INVENTARIO_ACTUAL;

    reportar('9. La existencia total es la misma de VW_CP_INVENTARIO_ACTUAL',
             v_sum_a = v_sum_b);

    SELECT COUNT(*) INTO v_count FROM MV_CP_VENTAS_MENSUALES WHERE fecha_corte < v_mark;
    SELECT COUNT(*) INTO v_count2 FROM MV_CP_INVENTARIO_CONSOLIDADO WHERE fecha_corte < v_mark;

    reportar('10. La fecha de corte de cada fila es la del ultimo refresco',
             v_count = 0 AND v_count2 = 0);

    -- ------------------------------------------------------------
    -- D. Desfase y transaccion abierta (venta que nunca se confirma)
    -- ------------------------------------------------------------
    -- Producto con existencia en una sucursal con un solo almacen activo
    -- (el mismo criterio de las pruebas de los scripts 25 y 27)
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
        HAVING SUM(v.cantidad_actual) >= 2
        ORDER BY SUM(v.cantidad_actual) DESC, v.id_producto, v.id_almacen
        FETCH FIRST 1 ROW ONLY;

        SELECT MIN(id_cliente) INTO v_cliente FROM CP_CLIENTE;
        SELECT MIN(id_usuario) INTO v_usuario FROM CP_USUARIO;

        v_lines(1).id_producto := v_producto;
        v_lines(1).cantidad := 2;
        v_lines(1).precio_unitario := 1000;

        PKG_CP_FACTURACION.registrar_venta(
            p_id_cliente     => v_cliente,
            p_id_sucursal    => v_sucursal,
            p_id_usuario     => v_usuario,
            p_numero_factura => v_numero,
            p_lineas         => v_lines,
            p_id_factura     => v_factura,
            p_a_credito      => FALSE,
            p_commit         => FALSE
        );

        v_have_sale := TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            v_have_sale := FALSE;
            DBMS_OUTPUT.PUT_LINE('   no se pudo registrar la venta de prueba: ' || SQLERRM);
    END;

    IF v_have_sale THEN

        v_live := live_invoices;
        v_cached := cached_invoices;

        reportar('11. Sin refrescar, el calculo ve la venta nueva y la materializada no',
                 v_live = v_cached + 1);

        v_code := refresh_code(PKG_CP_REPORTE.c_mv_ventas);
        v_open := DBMS_TRANSACTION.LOCAL_TRANSACTION_ID IS NOT NULL;

        SELECT COUNT(*) INTO v_count
        FROM CP_FACTURA_VENTA WHERE numero_factura = v_numero;

        reportar('12. Con la venta sin confirmar el refresco se niega (-20371)',
                 v_code = -20371 AND v_open AND v_count = 1);

        ROLLBACK;

        SELECT COUNT(*) INTO v_count
        FROM CP_FACTURA_VENTA WHERE numero_factura = v_numero;

        reportar('13. Tras el ROLLBACK la venta no existe: el refresco no la confirmo',
                 v_count = 0 AND live_invoices = cached_invoices);

    ELSE
        DBMS_OUTPUT.PUT_LINE(RPAD('11 a 13. Desfase y transaccion abierta', 72, '.')
                             || ' omitidas (sin producto con existencia)');
    END IF;

    -- ------------------------------------------------------------
    -- E. Errores
    -- ------------------------------------------------------------
    reportar('14. Una vista que no administra el paquete da -20370',
             refresh_code('MV_CP_NO_EXISTE') = -20370);

    reportar('15. Un nombre nulo da -20370',
             refresh_code(NULL) = -20370);

    SELECT COUNT(*) INTO v_count
    FROM CP_BITACORA_ERROR
    WHERE id_bitacora_error > v_antes AND modulo = 'REPORTE';

    reportar('16. Cada error provocado quedo UNA sola vez en la bitacora',
             v_count = CASE WHEN v_have_sale THEN 3 ELSE 2 END);

    -- ------------------------------------------------------------
    -- F. Limpieza
    -- ------------------------------------------------------------
    ROLLBACK;

    DELETE FROM CP_BITACORA_ERROR
    WHERE id_bitacora_error > v_antes
      AND modulo = 'REPORTE';
    COMMIT;

    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'Resultado: ' || v_ok || ' OK, '
                         || v_falla || ' FALLA');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR en las pruebas: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        RAISE;
END;
/

-- ============================================================
-- 9. JOBS DE REFRESCO
-- ============================================================
-- Ventas: diario a las 00:45, despues del cierre de las 00:30.
-- Inventario: cada hora, al minuto 5. Se vuelven a crear en cada
-- ejecucion del script (primero se borran).
-- A peticion del profesor:
--   EXEC PKG_CP_REPORTE.refresh_all;
-- o lanzar un job al instante con:
--   EXEC DBMS_SCHEDULER.RUN_JOB('JOB_CP_REFRESCO_INVENTARIO', FALSE);

DECLARE
    PROCEDURE drop_job(
        p_name IN VARCHAR2
    )
    IS
    BEGIN
        DBMS_SCHEDULER.DROP_JOB(p_name, force => TRUE);
    EXCEPTION
        WHEN OTHERS THEN
            -- ORA-27475: el job no existe todavia, no es un error
            IF SQLCODE != -27475 THEN
                RAISE;
            END IF;
    END drop_job;
BEGIN

    drop_job('JOB_CP_REFRESCO_VENTAS_MENSUALES');
    drop_job('JOB_CP_REFRESCO_INVENTARIO');

    DBMS_SCHEDULER.CREATE_JOB(
        job_name        => 'JOB_CP_REFRESCO_VENTAS_MENSUALES',
        job_type        => 'PLSQL_BLOCK',
        job_action      => 'BEGIN PKG_CP_REPORTE.refresh_monthly_sales; END;',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=DAILY;BYHOUR=0;BYMINUTE=45;BYSECOND=0',
        enabled         => TRUE,
        comments        => 'Refresco completo de MV_CP_VENTAS_MENSUALES.'
    );

    DBMS_SCHEDULER.CREATE_JOB(
        job_name        => 'JOB_CP_REFRESCO_INVENTARIO',
        job_type        => 'PLSQL_BLOCK',
        job_action      => 'BEGIN PKG_CP_REPORTE.refresh_inventory; END;',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=HOURLY;BYMINUTE=5;BYSECOND=0',
        enabled         => TRUE,
        comments        => 'Refresco completo de MV_CP_INVENTARIO_CONSOLIDADO.'
    );

END;
/

-- Lanza los dos jobs una vez y espera para ver su resultado en el historial
BEGIN
    DBMS_SCHEDULER.RUN_JOB('JOB_CP_REFRESCO_VENTAS_MENSUALES', FALSE);
    DBMS_SCHEDULER.RUN_JOB('JOB_CP_REFRESCO_INVENTARIO', FALSE);
    DBMS_SESSION.SLEEP(5);
END;
/

-- ============================================================
-- 10. VERIFICACION
-- ============================================================

SELECT job_name, enabled, state, repeat_interval, next_run_date
FROM   user_scheduler_jobs
WHERE  job_name IN ('JOB_CP_REFRESCO_VENTAS_MENSUALES', 'JOB_CP_REFRESCO_INVENTARIO');

SELECT job_name, status, actual_start_date, run_duration, errors
FROM   user_scheduler_job_run_details
WHERE  job_name IN ('JOB_CP_REFRESCO_VENTAS_MENSUALES', 'JOB_CP_REFRESCO_INVENTARIO')
ORDER  BY log_date DESC
FETCH FIRST 4 ROWS ONLY;

SELECT mview_name, refresh_method, refresh_mode, last_refresh_type,
       last_refresh_date, compile_state
FROM   user_mviews
WHERE  mview_name IN ('MV_CP_VENTAS_MENSUALES', 'MV_CP_INVENTARIO_CONSOLIDADO');

SELECT periodo, nombre_sucursal, cantidad_facturas, total_ventas,
       total_devoluciones, total_neto
FROM   MV_CP_VENTAS_MENSUALES
ORDER  BY mes DESC, nombre_sucursal
FETCH FIRST 12 ROWS ONLY;

SELECT nombre_sucursal,
       COUNT(*)              AS productos,
       SUM(existencia_total) AS existencia,
       SUM(valor_costo)      AS valor_costo,
       SUM(unidades_vencidas) AS unidades_vencidas
FROM   MV_CP_INVENTARIO_CONSOLIDADO
GROUP  BY nombre_sucursal
ORDER  BY nombre_sucursal;

SELECT object_name, object_type, status
FROM   user_objects
WHERE  object_name IN ('PKG_CP_REPORTE', 'VW_CP_VENTAS_MENSUALES',
                       'VW_CP_INVENTARIO_CONSOLIDADO', 'MV_CP_VENTAS_MENSUALES',
                       'MV_CP_INVENTARIO_CONSOLIDADO')
ORDER  BY object_name, object_type;
