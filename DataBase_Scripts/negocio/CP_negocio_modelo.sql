-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- BASE DE DATOS: Oracle 21c
-- SCRIPT: 26_negocio_modelo.sql
-- DESCRIPCION: Cambios de modelo de la Fase 4 (negocio) en un solo
--              script. No edita los archivos de la Parte 1: todo se
--              agrega con ALTER TABLE / CREATE sobre lo existente.
--              Cada sentencia se omite si el objeto ya existe, asi
--              que el script se puede volver a ejecutar.
--
--              Secciones (se van agregando conforme se cierra cada
--              decision de diseno):
--                1. Cierre diario (columnas de cantidades)
--                2. Promociones (tipo de promocion)
--                3. Indices de fecha para las consultas de la fase
--
-- EJECUTAR COMO: CP_POS en XEPDB1 (despues del script 25).
--                Se puede volver a ejecutar completo las veces
--                que haga falta.
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED

-- ============================================================
-- 1. CIERRE DIARIO: CANTIDADES VENDIDAS Y DEVUELTAS
-- ============================================================
-- El enunciado pide en el cierre: fecha, cantidad vendida,
-- devoluciones y total; y en el detalle: cajero, cantidad vendida
-- y devoluciones. Las tablas ya guardan los importes en colones.
-- El detalle ya trae cantidad_ventas y cantidad_devoluciones, que
-- cuentan documentos (facturas y devoluciones). Se agregan:
--   * en el cierre: esos mismos dos conteos, para no perderlos al
--     sumar por sucursal;
--   * en cierre y detalle: unidades_vendidas y unidades_devueltas,
--     que son la suma de las cantidades de producto.
-- Asi el cierre responde a las dos lecturas de "cantidad vendida".

DECLARE
    -- Ejecuta una sentencia DDL y la omite si el objeto ya existe,
    -- para que el script sea idempotente (se puede repetir).
    PROCEDURE run_ddl(p_sql IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE p_sql;
        DBMS_OUTPUT.PUT_LINE('OK      : ' || SUBSTR(p_sql, 1, 90));
    EXCEPTION
        WHEN OTHERS THEN
            -- -1430 columna ya existe, -955 nombre en uso,
            -- -2260 y -2261 llave ya existe, -2264 restriccion con
            -- ese nombre, -2275 llave foranea ya existe.
            IF SQLCODE IN (-1430, -955, -2260, -2261, -2264, -2275) THEN
                DBMS_OUTPUT.PUT_LINE('OMITIDO : ' || SUBSTR(p_sql, 1, 90));
            ELSE
                RAISE;
            END IF;
    END run_ddl;
BEGIN
    -- Cierre diario por sucursal
    run_ddl('ALTER TABLE CP_CIERRE_DIARIO ADD (cantidad_ventas NUMBER DEFAULT 0 NOT NULL)');
    run_ddl('ALTER TABLE CP_CIERRE_DIARIO ADD (cantidad_devoluciones NUMBER DEFAULT 0 NOT NULL)');
    run_ddl('ALTER TABLE CP_CIERRE_DIARIO ADD (unidades_vendidas NUMBER(14,2) DEFAULT 0 NOT NULL)');
    run_ddl('ALTER TABLE CP_CIERRE_DIARIO ADD (unidades_devueltas NUMBER(14,2) DEFAULT 0 NOT NULL)');

    run_ddl('ALTER TABLE CP_CIERRE_DIARIO ADD CONSTRAINT CK_CP_CIERRE_CANT_V CHECK (cantidad_ventas >= 0)');
    run_ddl('ALTER TABLE CP_CIERRE_DIARIO ADD CONSTRAINT CK_CP_CIERRE_CANT_D CHECK (cantidad_devoluciones >= 0)');
    run_ddl('ALTER TABLE CP_CIERRE_DIARIO ADD CONSTRAINT CK_CP_CIERRE_UNID_V CHECK (unidades_vendidas >= 0)');
    run_ddl('ALTER TABLE CP_CIERRE_DIARIO ADD CONSTRAINT CK_CP_CIERRE_UNID_D CHECK (unidades_devueltas >= 0)');

    -- Detalle del cierre por cajero
    run_ddl('ALTER TABLE CP_DETALLE_CIERRE_DIARIO ADD (unidades_vendidas NUMBER(14,2) DEFAULT 0 NOT NULL)');
    run_ddl('ALTER TABLE CP_DETALLE_CIERRE_DIARIO ADD (unidades_devueltas NUMBER(14,2) DEFAULT 0 NOT NULL)');

    run_ddl('ALTER TABLE CP_DETALLE_CIERRE_DIARIO ADD CONSTRAINT CK_CP_DET_CIERRE_UV CHECK (unidades_vendidas >= 0)');
    run_ddl('ALTER TABLE CP_DETALLE_CIERRE_DIARIO ADD CONSTRAINT CK_CP_DET_CIERRE_UD CHECK (unidades_devueltas >= 0)');
END;
/

COMMENT ON COLUMN CP_CIERRE_DIARIO.cantidad_ventas IS
'Numero de facturas de venta (sin anuladas) incluidas en el cierre.';
COMMENT ON COLUMN CP_CIERRE_DIARIO.cantidad_devoluciones IS
'Numero de devoluciones de venta procesadas incluidas en el cierre.';
COMMENT ON COLUMN CP_CIERRE_DIARIO.unidades_vendidas IS
'Suma de las unidades de producto vendidas en las facturas del cierre.';
COMMENT ON COLUMN CP_CIERRE_DIARIO.unidades_devueltas IS
'Suma de las unidades de producto devueltas en las devoluciones del cierre.';
COMMENT ON COLUMN CP_DETALLE_CIERRE_DIARIO.unidades_vendidas IS
'Suma de las unidades de producto vendidas por el cajero en el cierre.';
COMMENT ON COLUMN CP_DETALLE_CIERRE_DIARIO.unidades_devueltas IS
'Suma de las unidades de producto devueltas por el cajero en el cierre.';

-- Verificacion: las columnas nuevas deben aparecer con valor por defecto 0
SELECT table_name, column_name, data_type, data_precision AS prec,
       data_scale AS scale, nullable
FROM   user_tab_columns
WHERE  table_name IN ('CP_CIERRE_DIARIO', 'CP_DETALLE_CIERRE_DIARIO')
AND    column_name IN ('CANTIDAD_VENTAS', 'CANTIDAD_DEVOLUCIONES',
                       'UNIDADES_VENDIDAS', 'UNIDADES_DEVUELTAS')
ORDER  BY table_name, column_name;

-- ============================================================
-- 2. PROMOCIONES: TIPO DE PROMOCION
-- ============================================================
-- El enunciado pide que existan tipos de promociones. La tabla
-- CP_TIPO_PROMOCION ya existia pero estaba suelta: CP_PROMOCION no
-- tenia como apuntarle. Esta seccion:
--   * carga los dos tipos que el paquete PKG_CP_PROMOCION sabe
--     calcular (script 30);
--   * agrega CP_PROMOCION.id_tipo_promocion con su llave foranea e
--     indice;
--   * asigna el tipo POR CANTIDAD a las promociones que ya existen
--     (todas tienen un solo patrocinador, asi que cualquiera de los
--     dos tipos da el mismo resultado) y luego deja la columna
--     NOT NULL: una promocion sin tipo no se puede calcular.
-- La cantidad de patrocinadores necesaria para una accion NO se
-- agrega aqui: ya vive en CP_PROMOCION_PATROCINADOR.cantidad_requerida
-- (una por producto patrocinador). Repetirla en CP_PROMOCION seria
-- guardar el mismo dato en dos lugares.

MERGE INTO CP_TIPO_PROMOCION t
USING (
    SELECT 'POR CANTIDAD DE PATROCINADORES' AS nombre,
           'Cada patrocinador suma por separado: veces = suma de '
           || 'FLOOR(cantidad comprada / cantidad requerida).' AS descripcion
    FROM dual
    UNION ALL
    SELECT 'COMBO DE PATROCINADORES',
           'Se necesitan todos los patrocinadores de la regla: veces = '
           || 'minimo de FLOOR(cantidad comprada / cantidad requerida).'
    FROM dual
) s
ON (t.nombre_tipo_promocion = s.nombre)
WHEN MATCHED THEN
    UPDATE SET t.descripcion = s.descripcion
    WHERE DECODE(t.descripcion, s.descripcion, 0, 1) = 1
WHEN NOT MATCHED THEN
    INSERT (nombre_tipo_promocion, descripcion)
    VALUES (s.nombre, s.descripcion);

COMMIT;

DECLARE
    v_rows NUMBER;

    -- Misma idea que en la seccion 1: si el objeto ya existe se omite.
    PROCEDURE run_ddl(p_sql IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE p_sql;
        DBMS_OUTPUT.PUT_LINE('OK      : ' || SUBSTR(p_sql, 1, 90));
    EXCEPTION
        WHEN OTHERS THEN
            -- -1430 columna ya existe, -955 nombre en uso, -1408 ya hay
            -- un indice con esas columnas, -1442 la columna ya es
            -- NOT NULL, -2275 llave foranea ya existe.
            IF SQLCODE IN (-1430, -955, -1408, -1442, -2275) THEN
                DBMS_OUTPUT.PUT_LINE('OMITIDO : ' || SUBSTR(p_sql, 1, 90));
            ELSE
                RAISE;
            END IF;
    END run_ddl;
BEGIN
    run_ddl('ALTER TABLE CP_PROMOCION ADD (id_tipo_promocion NUMBER)');

    -- El UPDATE va con EXECUTE IMMEDIATE porque la columna no existe
    -- cuando Oracle compila este bloque (en la primera ejecucion).
    EXECUTE IMMEDIATE
        'UPDATE CP_PROMOCION
         SET id_tipo_promocion = (SELECT id_tipo_promocion
                                  FROM CP_TIPO_PROMOCION
                                  WHERE nombre_tipo_promocion = :tipo)
         WHERE id_tipo_promocion IS NULL'
        USING 'POR CANTIDAD DE PATROCINADORES';
    v_rows := SQL%ROWCOUNT;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Promociones existentes con tipo asignado: ' || v_rows);

    run_ddl('ALTER TABLE CP_PROMOCION MODIFY (id_tipo_promocion NOT NULL)');
    run_ddl('ALTER TABLE CP_PROMOCION ADD CONSTRAINT FK_CP_PROMOCION_TIPO '
            || 'FOREIGN KEY (id_tipo_promocion) '
            || 'REFERENCES CP_TIPO_PROMOCION (id_tipo_promocion)');
    run_ddl('CREATE INDEX IX_CP_PROMOCION_TIPO ON CP_PROMOCION (id_tipo_promocion) '
            || 'TABLESPACE CP_POS_INDICES');
END;
/

COMMENT ON COLUMN CP_PROMOCION.id_tipo_promocion IS
'Tipo de promocion: define como se cuentan los patrocinadores para obtener las acciones.';

-- Verificacion: cada promocion debe salir con su tipo
SELECT p.nombre_promocion, t.nombre_tipo_promocion
FROM   CP_PROMOCION p
JOIN   CP_TIPO_PROMOCION t
  ON   t.id_tipo_promocion = p.id_tipo_promocion
ORDER  BY p.id_promocion;

-- ============================================================
-- 3. INDICES DE FECHA PARA LAS CONSULTAS DE LA FASE
-- ============================================================
-- El EXPLAIN PLAN del script 32 mostro que ninguna de las columnas de
-- fecha que filtran los procesos de la fase tiene indice. Los paquetes
-- ya escriben esos filtros como rangos (>= y <) y no como
-- TRUNC(columna), justamente para que Oracle pueda usar un indice:
--   CP_LOTE_PRODUCTO.fecha_vencimiento  productos por vencer y descuentos
--   CP_LOTE_PRODUCTO.fecha_ingreso      mas de 6 meses en bodega y descuentos
--   CP_FACTURA_VENTA (id_sucursal, fecha_emision)  cierre diario por sucursal
--   CP_FACTURA_VENTA.fecha_emision      periodo de la premiacion
--   CP_DEVOLUCION_VENTA.fecha_devolucion  devoluciones del cierre
-- Con las tablas pequenas de prueba el optimizador puede seguir
-- prefiriendo leerlas completas (es mas barato); los indices sirven
-- cuando las tablas crecen.

DECLARE
    PROCEDURE run_ddl(p_sql IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE p_sql;
        DBMS_OUTPUT.PUT_LINE('OK      : ' || SUBSTR(p_sql, 1, 90));
    EXCEPTION
        WHEN OTHERS THEN
            -- -955 nombre en uso, -1408 ya hay un indice con esas columnas
            IF SQLCODE IN (-955, -1408) THEN
                DBMS_OUTPUT.PUT_LINE('OMITIDO : ' || SUBSTR(p_sql, 1, 90));
            ELSE
                RAISE;
            END IF;
    END run_ddl;
BEGIN
    run_ddl('CREATE INDEX IX_CP_LOTE_PROD_VENCE ON CP_LOTE_PRODUCTO (fecha_vencimiento) '
            || 'TABLESPACE CP_POS_INDICES');
    run_ddl('CREATE INDEX IX_CP_LOTE_PROD_INGRESO ON CP_LOTE_PRODUCTO (fecha_ingreso) '
            || 'TABLESPACE CP_POS_INDICES');
    run_ddl('CREATE INDEX IX_CP_FACT_VENTA_SUC_FECHA ON CP_FACTURA_VENTA (id_sucursal, fecha_emision) '
            || 'TABLESPACE CP_POS_INDICES');
    run_ddl('CREATE INDEX IX_CP_FACT_VENTA_FECHA ON CP_FACTURA_VENTA (fecha_emision) '
            || 'TABLESPACE CP_POS_INDICES');
    run_ddl('CREATE INDEX IX_CP_DEV_VENTA_FECHA ON CP_DEVOLUCION_VENTA (fecha_devolucion) '
            || 'TABLESPACE CP_POS_INDICES');
END;
/

-- Verificacion: deben salir los cinco indices en VALID
SELECT index_name, table_name, status
FROM   user_indexes
WHERE  index_name IN ('IX_CP_LOTE_PROD_VENCE', 'IX_CP_LOTE_PROD_INGRESO',
                      'IX_CP_FACT_VENTA_SUC_FECHA', 'IX_CP_FACT_VENTA_FECHA',
                      'IX_CP_DEV_VENTA_FECHA')
ORDER  BY index_name;
