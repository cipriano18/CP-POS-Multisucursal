-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- BASE DE DATOS: Oracle 21c
-- SCRIPT: 19_facturacion_credito_pagar.sql
-- DESCRIPCION: Columna id_credito_proveedor en CP_CUENTA_PAGAR,
--              con su llave foranea, indice y comentario, para que
--              cada cuenta por pagar quede ligada a la linea de
--              credito del proveedor igual que la cuenta por cobrar
--              lo esta a la del cliente. Cambia tablas: se
--              ejecuta una sola vez.
--
-- EJECUTAR COMO: CP_POS en XEPDB1 (despues del script 18 y antes
--                del 20)
-- ============================================================

-- ============================================================
-- 1. COLUMNA DE CP_CUENTA_PAGAR
-- ============================================================
-- Se agrega sin NOT NULL, se llena con el credito mas reciente del
-- proveedor en el negocio de cada factura y despues se vuelve
-- obligatoria. Si alguna cuenta existente no tiene credito, el
-- MODIFY falla y avisa cual es el problema.

ALTER TABLE CP_CUENTA_PAGAR ADD (
    id_credito_proveedor NUMBER
);

UPDATE CP_CUENTA_PAGAR cp
SET cp.id_credito_proveedor = (
        SELECT cr.id_credito_proveedor
        FROM CP_FACTURA_COMPRA fc
        JOIN CP_CREDITO_PROVEEDOR cr
          ON cr.id_proveedor = fc.id_proveedor
         AND cr.id_negocio = fc.id_negocio
        WHERE fc.id_factura_compra = cp.id_factura_compra
        ORDER BY cr.fecha_autorizacion DESC, cr.id_credito_proveedor DESC
        FETCH FIRST 1 ROW ONLY
    );

COMMIT;

ALTER TABLE CP_CUENTA_PAGAR MODIFY (id_credito_proveedor NOT NULL);

ALTER TABLE CP_CUENTA_PAGAR
ADD CONSTRAINT FK_CP_CUENTA_PAGAR_CREDITO
FOREIGN KEY (id_credito_proveedor)
REFERENCES CP_CREDITO_PROVEEDOR (id_credito_proveedor);

CREATE INDEX IX_CP_CTA_PAGAR_CREDITO
ON CP_CUENTA_PAGAR (id_credito_proveedor)
TABLESPACE CP_POS_INDICES;

-- ============================================================
-- 2. COMENTARIO
-- ============================================================

COMMENT ON COLUMN CP_CUENTA_PAGAR.id_credito_proveedor IS
'Linea de credito del proveedor a la que pertenece la cuenta; el saldo pendiente de todas sus cuentas no anuladas no puede pasar del limite.';

-- ============================================================
-- 3. VERIFICACION
-- ============================================================
-- Debe salir la columna con NULLABLE = N y la llave foranea.

SELECT column_name, data_type, nullable
FROM user_tab_columns
WHERE table_name = 'CP_CUENTA_PAGAR'
  AND column_name = 'ID_CREDITO_PROVEEDOR';

SELECT constraint_name, constraint_type, status
FROM user_constraints
WHERE constraint_name = 'FK_CP_CUENTA_PAGAR_CREDITO';
