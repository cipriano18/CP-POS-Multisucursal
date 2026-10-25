-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- BASE DE DATOS: Oracle 21c
-- SCRIPT: 18_facturacion_cuentas.sql
-- DESCRIPCION: Monto y saldo de las cuentas por cobrar y por
--              pagar (CP_CUENTA_COBRAR y CP_CUENTA_PAGAR) con sus
--              restricciones y comentarios, y retiro de
--              TRG_CP_ABONO_COBRAR_LIMITE y TRG_CP_ABONO_PAGAR_LIMITE.
--              Cambia tablas: se ejecuta una sola vez. El paquete y
--              los triggers que mantienen el saldo estan en el 20.
--
-- EJECUTAR COMO: CP_POS en XEPDB1 (despues de la instalacion
--                completa de la base)
-- ============================================================

-- ============================================================
-- 1. COLUMNAS DE CP_CUENTA_COBRAR
-- ============================================================
-- monto_total copia el total de la factura y saldo_pendiente es
-- lo que falta por cobrar. Se agregan sin NOT NULL, se llenan con
-- los datos existentes y despues se vuelven obligatorias.

ALTER TABLE CP_CUENTA_COBRAR ADD (
    monto_total     NUMBER(14,2),
    saldo_pendiente NUMBER(14,2)
);

UPDATE CP_CUENTA_COBRAR cc
SET cc.monto_total = (
        SELECT fv.total
        FROM CP_FACTURA_VENTA fv
        WHERE fv.id_factura_venta = cc.id_factura_venta
    ),
    cc.saldo_pendiente = (
        SELECT fv.total
        FROM CP_FACTURA_VENTA fv
        WHERE fv.id_factura_venta = cc.id_factura_venta
    ) - NVL((
        SELECT SUM(a.monto_abono)
        FROM CP_ABONO_CUENTA_COBRAR a
        WHERE a.id_cuenta_cobrar = cc.id_cuenta_cobrar
    ), 0);

COMMIT;

ALTER TABLE CP_CUENTA_COBRAR MODIFY (
    monto_total     NOT NULL,
    saldo_pendiente NOT NULL
);

ALTER TABLE CP_CUENTA_COBRAR
ADD CONSTRAINT CK_CP_CUENTA_COBRAR_MONTO_TOTAL
CHECK (monto_total >= 0);

ALTER TABLE CP_CUENTA_COBRAR
ADD CONSTRAINT CK_CP_CUENTA_COBRAR_SALDO
CHECK (saldo_pendiente >= 0 AND saldo_pendiente <= monto_total);

-- ============================================================
-- 2. COLUMNAS DE CP_CUENTA_PAGAR
-- ============================================================

ALTER TABLE CP_CUENTA_PAGAR ADD (
    monto_total     NUMBER(14,2),
    saldo_pendiente NUMBER(14,2)
);

UPDATE CP_CUENTA_PAGAR cp
SET cp.monto_total = (
        SELECT fc.total
        FROM CP_FACTURA_COMPRA fc
        WHERE fc.id_factura_compra = cp.id_factura_compra
    ),
    cp.saldo_pendiente = (
        SELECT fc.total
        FROM CP_FACTURA_COMPRA fc
        WHERE fc.id_factura_compra = cp.id_factura_compra
    ) - NVL((
        SELECT SUM(a.monto_abono)
        FROM CP_ABONO_CUENTA_PAGAR a
        WHERE a.id_cuenta_pagar = cp.id_cuenta_pagar
    ), 0);

COMMIT;

ALTER TABLE CP_CUENTA_PAGAR MODIFY (
    monto_total     NOT NULL,
    saldo_pendiente NOT NULL
);

ALTER TABLE CP_CUENTA_PAGAR
ADD CONSTRAINT CK_CP_CUENTA_PAGAR_MONTO_TOTAL
CHECK (monto_total >= 0);

ALTER TABLE CP_CUENTA_PAGAR
ADD CONSTRAINT CK_CP_CUENTA_PAGAR_SALDO
CHECK (saldo_pendiente >= 0 AND saldo_pendiente <= monto_total);

-- ============================================================
-- 3. COMENTARIOS
-- ============================================================

COMMENT ON COLUMN CP_CUENTA_COBRAR.monto_total IS
'Monto original de la cuenta: copia del total de la factura de venta.';

COMMENT ON COLUMN CP_CUENTA_COBRAR.saldo_pendiente IS
'Monto que falta por cobrar. Lo actualiza PKG_CP_CUENTA con cada abono; nunca es negativo ni supera monto_total.';

COMMENT ON COLUMN CP_CUENTA_PAGAR.monto_total IS
'Monto original de la cuenta: copia del total de la factura de compra.';

COMMENT ON COLUMN CP_CUENTA_PAGAR.saldo_pendiente IS
'Monto que falta por pagar. Lo actualiza PKG_CP_CUENTA con cada abono; nunca es negativo ni supera monto_total.';

-- ============================================================
-- 4. RETIRO DE LOS TRIGGERS DE LIMITE DE ABONOS
-- ============================================================
-- Revisaban todas las cuentas en cada insercion. Ahora lo cubren
-- las restricciones CK_CP_CUENTA_*_SALDO y PKG_CP_CUENTA.

DROP TRIGGER TRG_CP_ABONO_COBRAR_LIMITE;

DROP TRIGGER TRG_CP_ABONO_PAGAR_LIMITE;

-- ============================================================
-- 5. VERIFICACION
-- ============================================================
-- Deben salir 4 columnas y 4 restricciones.

SELECT table_name, column_name, data_type, data_precision, data_scale, nullable
FROM user_tab_columns
WHERE table_name IN ('CP_CUENTA_COBRAR', 'CP_CUENTA_PAGAR')
  AND column_name IN ('MONTO_TOTAL', 'SALDO_PENDIENTE')
ORDER BY table_name, column_name;

SELECT table_name, constraint_name, search_condition_vc
FROM user_constraints
WHERE constraint_name IN ('CK_CP_CUENTA_COBRAR_MONTO_TOTAL',
                          'CK_CP_CUENTA_COBRAR_SALDO',
                          'CK_CP_CUENTA_PAGAR_MONTO_TOTAL',
                          'CK_CP_CUENTA_PAGAR_SALDO')
ORDER BY table_name, constraint_name;
