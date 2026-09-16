-- ============================================================
-- 10_vistas.sql
-- VISTAS DEL SISTEMA CP_POS
-- ============================================================


-- ============================================================
-- VISTA 1. VW_CP_INVENTARIO_ACTUAL
-- ============================================================
-- Permite consultar las existencias por almacen y lote.

CREATE OR REPLACE VIEW VW_CP_INVENTARIO_ACTUAL AS
SELECT
    ia.id_inventario_almacen,
    a.id_almacen,
    a.nombre_almacen,
    p.id_producto,
    p.codigo_producto,
    p.nombre_producto,
    lp.id_lote_producto,
    lp.numero_lote,
    lp.fecha_ingreso,
    lp.fecha_vencimiento,
    ia.cantidad_actual,
    ia.fecha_actualizacion
FROM CP_INVENTARIO_ALMACEN ia
JOIN CP_ALMACEN a
    ON a.id_almacen = ia.id_almacen
JOIN CP_LOTE_PRODUCTO lp
    ON lp.id_lote_producto = ia.id_lote_producto
JOIN CP_DETALLE_COMPRA dc
    ON dc.id_detalle_compra = lp.id_detalle_compra
JOIN CP_PRODUCTO_PROVEEDOR pp
    ON pp.id_producto_proveedor = dc.id_producto_proveedor
JOIN CP_PRODUCTO p
    ON p.id_producto = pp.id_producto;


-- ============================================================
-- VISTA 2. VW_CP_PRODUCTOS_PRECIOS
-- ============================================================
-- Muestra el precio actual y configuracion comercial
-- de cada producto por negocio.

CREATE OR REPLACE VIEW VW_CP_PRODUCTOS_PRECIOS AS
SELECT
    pn.id_producto_negocio,
    p.id_producto,
    p.codigo_producto,
    p.nombre_producto,
    n.id_negocio,
    n.nombre_negocio,
    pn.porcentaje_utilidad,
    pn.descuento_maximo,
    pn.precio_venta_actual
FROM CP_PRODUCTO_NEGOCIO pn
JOIN CP_PRODUCTO p
    ON p.id_producto = pn.id_producto
JOIN CP_NEGOCIO n
    ON n.id_negocio = pn.id_negocio;


-- ============================================================
-- VISTA 3. VW_CP_VENTAS
-- ============================================================
-- Resume las facturas de venta con cliente,
-- sucursal, usuario y estado.

CREATE OR REPLACE VIEW VW_CP_VENTAS AS
SELECT
    fv.id_factura_venta,
    fv.numero_factura,
    fv.fecha_emision,
    fv.id_cliente,
    fv.id_sucursal,
    s.nombre_sucursal,
    fv.id_usuario,
    u.nombre_usuario,
    fv.id_estado_factura_venta,
    efv.nombre_estado_factura,
    fv.subtotal,
    fv.descuento_total,
    fv.impuesto_total,
    fv.total
FROM CP_FACTURA_VENTA fv
JOIN CP_CLIENTE c
    ON c.id_cliente = fv.id_cliente
JOIN CP_SUCURSAL s
    ON s.id_sucursal = fv.id_sucursal
JOIN CP_USUARIO u
    ON u.id_usuario = fv.id_usuario
JOIN CP_ESTADO_FACTURA_VENTA efv
    ON efv.id_estado_factura_venta = fv.id_estado_factura_venta;


-- ============================================================
-- VISTA 4. VW_CP_DETALLE_VENTA_LOTES
-- ============================================================
-- Permite conocer que lotes fueron utilizados
-- para vender cada producto.

CREATE OR REPLACE VIEW VW_CP_DETALLE_VENTA_LOTES AS
SELECT
    fv.id_factura_venta,
    fv.numero_factura,
    dvp.id_detalle_venta_producto,
    p.id_producto,
    p.codigo_producto,
    p.nombre_producto,
    dvl.id_detalle_venta_lote,
    lp.id_lote_producto,
    lp.numero_lote,
    lp.fecha_vencimiento,
    dvl.cantidad
FROM CP_DETALLE_VENTA_LOTE dvl
JOIN CP_DETALLE_VENTA_PRODUCTO dvp
    ON dvp.id_detalle_venta_producto = dvl.id_detalle_venta_producto
JOIN CP_FACTURA_VENTA fv
    ON fv.id_factura_venta = dvp.id_factura_venta
JOIN CP_PRODUCTO p
    ON p.id_producto = dvp.id_producto
JOIN CP_LOTE_PRODUCTO lp
    ON lp.id_lote_producto = dvl.id_lote_producto;


-- ============================================================
-- VISTA 5. VW_CP_COMPRAS
-- ============================================================
-- Resume las compras realizadas a proveedores.

CREATE OR REPLACE VIEW VW_CP_COMPRAS AS
SELECT
    fc.id_factura_compra,
    fc.numero_factura,
    fc.fecha_emision,
    fc.fecha_recepcion,
    p.id_proveedor,
    p.razon_social AS proveedor,
    n.id_negocio,
    n.nombre_negocio AS negocio,
    a.id_almacen,
    a.nombre_almacen,
    u.id_usuario,
    u.nombre_usuario,
    efc.nombre_estado_factura,
    fc.subtotal,
    fc.descuento_total,
    fc.impuesto_total,
    fc.total
FROM CP_FACTURA_COMPRA fc
JOIN CP_PROVEEDOR p
    ON p.id_proveedor = fc.id_proveedor
JOIN CP_NEGOCIO n
    ON n.id_negocio = fc.id_negocio
JOIN CP_ALMACEN a
    ON a.id_almacen = fc.id_almacen_recepcion
JOIN CP_USUARIO u
    ON u.id_usuario = fc.id_usuario
JOIN CP_ESTADO_FACTURA_COMPRA efc
    ON efc.id_estado_factura_compra = fc.id_estado_factura_compra;


-- ============================================================
-- CONSULTAS DE PRUEBA
-- ============================================================

SELECT * FROM VW_CP_INVENTARIO_ACTUAL;

SELECT * FROM VW_CP_PRODUCTOS_PRECIOS;

SELECT * FROM VW_CP_VENTAS;

SELECT * FROM VW_CP_DETALLE_VENTA_LOTES;

SELECT * FROM VW_CP_COMPRAS;


-- ============================================================
-- VISTA 6. VW_CP_CUENTAS_PAGAR
-- ============================================================
-- Muestra las cuentas por pagar a proveedores,
-- el total abonado y el saldo pendiente.

CREATE OR REPLACE VIEW VW_CP_CUENTAS_PAGAR AS
SELECT
    cp.id_cuenta_pagar,
    fc.id_factura_compra,
    fc.numero_factura,
    p.id_proveedor,
    p.razon_social AS proveedor,
    cp.fecha_creacion,
    cp.fecha_vencimiento,
    ecp.nombre_estado_cuenta_pagar,
    fc.total AS total_factura,
    NVL(SUM(ap.monto_abono), 0) AS total_abonado,
    fc.total - NVL(SUM(ap.monto_abono), 0) AS saldo_pendiente
FROM CP_CUENTA_PAGAR cp
JOIN CP_FACTURA_COMPRA fc
    ON fc.id_factura_compra = cp.id_factura_compra
JOIN CP_PROVEEDOR p
    ON p.id_proveedor = fc.id_proveedor
JOIN CP_ESTADO_CUENTA_PAGAR ecp
    ON ecp.id_estado_cuenta_pagar = cp.id_estado_cuenta_pagar
LEFT JOIN CP_ABONO_CUENTA_PAGAR ap
    ON ap.id_cuenta_pagar = cp.id_cuenta_pagar
GROUP BY
    cp.id_cuenta_pagar,
    fc.id_factura_compra,
    fc.numero_factura,
    p.id_proveedor,
    p.razon_social,
    cp.fecha_creacion,
    cp.fecha_vencimiento,
    ecp.nombre_estado_cuenta_pagar,
    fc.total;


-- ============================================================
-- VISTA 7. VW_CP_CUENTAS_COBRAR
-- ============================================================
-- Muestra las cuentas por cobrar de los clientes,
-- lo abonado y el saldo pendiente.

CREATE OR REPLACE VIEW VW_CP_CUENTAS_COBRAR AS
SELECT
    cc.id_cuenta_cobrar,
    fv.id_factura_venta,
    fv.numero_factura,
    cc.id_credito_cliente,
    fv.id_cliente,
    cc.fecha_creacion,
    cc.fecha_vencimiento,
    ecc.nombre_estado_cuenta_cobrar,
    fv.total AS total_factura,
    NVL(SUM(ac.monto_abono), 0) AS total_abonado,
    fv.total - NVL(SUM(ac.monto_abono), 0) AS saldo_pendiente
FROM CP_CUENTA_COBRAR cc
JOIN CP_FACTURA_VENTA fv
    ON fv.id_factura_venta = cc.id_factura_venta
JOIN CP_ESTADO_CUENTA_COBRAR ecc
    ON ecc.id_estado_cuenta_cobrar = cc.id_estado_cuenta_cobrar
LEFT JOIN CP_ABONO_CUENTA_COBRAR ac
    ON ac.id_cuenta_cobrar = cc.id_cuenta_cobrar
GROUP BY
    cc.id_cuenta_cobrar,
    fv.id_factura_venta,
    fv.numero_factura,
    cc.id_credito_cliente,
    fv.id_cliente,
    cc.fecha_creacion,
    cc.fecha_vencimiento,
    ecc.nombre_estado_cuenta_cobrar,
    fv.total;


-- ============================================================
-- VISTA 8. VW_CP_CREDITOS_CLIENTES
-- ============================================================
-- Muestra los limites de credito autorizados
-- a los clientes por negocio.

CREATE OR REPLACE VIEW VW_CP_CREDITOS_CLIENTES AS
SELECT
    cc.id_credito_cliente,
    cc.id_cliente,
    n.id_negocio,
    n.nombre_negocio AS negocio,
    ec.nombre_estado_credito,
    cc.limite_credito,
    cc.fecha_autorizacion,
    cc.fecha_vencimiento
FROM CP_CREDITO_CLIENTE cc
JOIN CP_NEGOCIO n
    ON n.id_negocio = cc.id_negocio
JOIN CP_ESTADO_CREDITO ec
    ON ec.id_estado_credito = cc.id_estado_credito;


-- ============================================================
-- VISTA 9. VW_CP_CREDITOS_PROVEEDORES
-- ============================================================
-- Muestra los limites de credito que cada proveedor
-- ofrece al negocio.

CREATE OR REPLACE VIEW VW_CP_CREDITOS_PROVEEDORES AS
SELECT
    cp.id_credito_proveedor,
    p.id_proveedor,
    p.razon_social AS proveedor,
    n.id_negocio,
    n.nombre_negocio AS negocio,
    ec.nombre_estado_credito,
    cp.limite_credito,
    cp.fecha_autorizacion,
    cp.fecha_vencimiento
FROM CP_CREDITO_PROVEEDOR cp
JOIN CP_PROVEEDOR p
    ON p.id_proveedor = cp.id_proveedor
JOIN CP_NEGOCIO n
    ON n.id_negocio = cp.id_negocio
JOIN CP_ESTADO_CREDITO ec
    ON ec.id_estado_credito = cp.id_estado_credito;


-- ============================================================
-- VISTA 10. VW_CP_PRODUCTOS_POR_VENCER
-- ============================================================
-- Muestra los lotes que tienen fecha de vencimiento,
-- junto con el producto y la cantidad disponible.

CREATE OR REPLACE VIEW VW_CP_PRODUCTOS_POR_VENCER AS
SELECT
    p.id_producto,
    p.codigo_producto,
    p.nombre_producto,
    lp.id_lote_producto,
    lp.numero_lote,
    lp.fecha_ingreso,
    lp.fecha_vencimiento,
    a.id_almacen,
    a.nombre_almacen,
    ia.cantidad_actual,
    TRUNC(lp.fecha_vencimiento) - TRUNC(SYSDATE)
        AS dias_para_vencer
FROM CP_LOTE_PRODUCTO lp
JOIN CP_DETALLE_COMPRA dc
    ON dc.id_detalle_compra = lp.id_detalle_compra
JOIN CP_PRODUCTO_PROVEEDOR pp
    ON pp.id_producto_proveedor = dc.id_producto_proveedor
JOIN CP_PRODUCTO p
    ON p.id_producto = pp.id_producto
JOIN CP_INVENTARIO_ALMACEN ia
    ON ia.id_lote_producto = lp.id_lote_producto
JOIN CP_ALMACEN a
    ON a.id_almacen = ia.id_almacen
WHERE lp.fecha_vencimiento IS NOT NULL
  AND ia.cantidad_actual > 0;


-- ============================================================
-- PRUEBAS DE LAS VISTAS 6 A 10
-- ============================================================

SELECT * FROM VW_CP_CUENTAS_PAGAR;

SELECT * FROM VW_CP_CUENTAS_COBRAR;

SELECT * FROM VW_CP_CREDITOS_CLIENTES;

SELECT * FROM VW_CP_CREDITOS_PROVEEDORES;

SELECT * FROM VW_CP_PRODUCTOS_POR_VENCER
ORDER BY dias_para_vencer;
