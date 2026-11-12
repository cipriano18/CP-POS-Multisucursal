-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- BASE DE DATOS: Oracle 21c
-- SCRIPT: 29_negocio_descuento.sql
-- DESCRIPCION: Revision semanal de descuentos planeados. Paquete
--              PKG_CP_DESCUENTO: para cada descuento ACTIVO o
--              PROGRAMADO (y todavia vigente) agrega a
--              CP_DESCUENTO_PRODUCTO los productos con existencia
--              que cumplen sus reglas (cerca de vencer, o ingresados
--              en un rango de fechas). Un producto que deja de
--              cumplir se DESACTIVA (activo = 'N'), no se borra, y si
--              vuelve a cumplir se reactiva. Incluye el job semanal y
--              pruebas.
--
-- REGLAS DE LA REVISION:
--   * Un descuento puede tener regla de vencimiento
--     (CP_DESCUENTO_VENCIMIENTO), de fecha de ingreso
--     (CP_DESCUENTO_FECHA_INGRESO) o ambas: basta cumplir UNA.
--     Sin ninguna regla no agrega productos.
--   * Alcance: si el descuento tiene familias, el producto debe ser
--     de una de ellas; si tiene proveedores, debe ser de uno de ellos;
--     una lista vacia no restringe. Solo cuenta el inventario de los
--     almacenes del negocio del descuento.
--   * Por vencer: el lote vence desde hoy hasta hoy + dias_antes
--     (inclusive). Un lote ya vencido no cuenta.
--   * Cada linea hereda la vigencia (inicio y final) del descuento.
--   * Cada linea agregada, desactivada o reactivada queda en
--     CP_BITACORA_DESCUENTO (trigger TRG_CP_AUD_DESCUENTO_PRODUCTO), asi
--     los cambios automaticos del job tambien dejan rastro.
--
-- EJECUTAR COMO: CP_POS en XEPDB1 (despues de los scripts 15 y 25).
--                Se puede volver a ejecutar completo las veces
--                que haga falta.
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED

-- ============================================================
-- 1. PAQUETE PKG_CP_DESCUENTO (ESPECIFICACION)
-- ============================================================

CREATE OR REPLACE PACKAGE PKG_CP_DESCUENTO AUTHID DEFINER AS

    -- Revisa los descuentos planeados con la fecha p_today y deja en
    -- CP_DESCUENTO_PRODUCTO los productos que cumplen (nuevos o
    -- reactivados) y desactiva los que ya no. Devuelve cuantas filas
    -- cambio; repetir la revision sin cambios en los datos da 0.
    PROCEDURE apply_scheduled_discounts(
        p_today        IN  DATE,
        p_rows_changed OUT NUMBER,
        p_commit       IN  BOOLEAN DEFAULT TRUE
    );

    -- Revision con la fecha de hoy. Es la que ejecuta el job semanal.
    PROCEDURE run_weekly_check;

END PKG_CP_DESCUENTO;
/

-- ============================================================
-- 2. PAQUETE PKG_CP_DESCUENTO (CUERPO)
-- ============================================================

CREATE OR REPLACE PACKAGE BODY PKG_CP_DESCUENTO AS

    c_modulo CONSTANT VARCHAR2(20) := 'DESCUENTO';

    c_estado_activo     CONSTANT VARCHAR2(30) := 'ACTIVO';
    c_estado_programado CONSTANT VARCHAR2(30) := 'PROGRAMADO';


    PROCEDURE apply_scheduled_discounts(
        p_today        IN  DATE,
        p_rows_changed OUT NUMBER,
        p_commit       IN  BOOLEAN DEFAULT TRUE
    )
    IS
        v_today DATE := TRUNC(p_today);
    BEGIN

        SAVEPOINT sp_apply_scheduled_discounts;

        -- Una sola sentencia MERGE hace todo en un paso (y de forma atomica):
        --   evaluated  : descuentos que se revisan hoy
        --   stock      : lotes con existencia, con el negocio de su almacen
        --   qualifying : pares (descuento, producto) que cumplen reglas y alcance
        -- La fuente une los que cumplen (marca 1) con los que ya estaban activos
        -- (marca 0); el MAX por llave deja 1 si cumple y 0 si ya no cumple.
        MERGE INTO CP_DESCUENTO_PRODUCTO t
        USING (
            WITH evaluated AS (
                SELECT d.id_descuento, d.id_negocio, d.fecha_inicio, d.fecha_final
                FROM CP_DESCUENTO d
                JOIN CP_ESTADO_DESCUENTO e
                  ON e.id_estado_descuento = d.id_estado_descuento
                WHERE e.nombre_estado_descuento IN (c_estado_activo, c_estado_programado)
                  AND (d.fecha_final IS NULL OR d.fecha_final >= v_today)
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
                SELECT DISTINCT ev.id_descuento, st.id_producto,
                       ev.fecha_inicio, ev.fecha_final
                FROM evaluated ev
                JOIN stock st
                  ON st.id_negocio = ev.id_negocio
                JOIN CP_PRODUCTO p
                  ON p.id_producto = st.id_producto
                WHERE (
                        -- Regla de vencimiento: vence desde hoy hasta hoy + dias_antes
                        EXISTS (SELECT 1
                                FROM CP_DESCUENTO_VENCIMIENTO dv
                                WHERE dv.id_descuento = ev.id_descuento
                                  AND st.fecha_vencimiento >= v_today
                                  AND st.fecha_vencimiento < v_today + dv.dias_antes_vencimiento + 1)
                        -- Regla de fecha de ingreso: el lote ingreso dentro del rango
                        OR EXISTS (SELECT 1
                                   FROM CP_DESCUENTO_FECHA_INGRESO di
                                   WHERE di.id_descuento = ev.id_descuento
                                     AND st.fecha_ingreso >= di.fecha_ingreso_desde
                                     AND st.fecha_ingreso < di.fecha_ingreso_hasta + 1)
                      )
                  -- Alcance por familia (sin familias no restringe)
                  AND (
                        NOT EXISTS (SELECT 1
                                    FROM CP_DESCUENTO_FAMILIA df
                                    WHERE df.id_descuento = ev.id_descuento)
                        OR EXISTS (SELECT 1
                                   FROM CP_DESCUENTO_FAMILIA df
                                   WHERE df.id_descuento = ev.id_descuento
                                     AND df.id_familia_producto = p.id_familia_producto)
                      )
                  -- Alcance por proveedor (sin proveedores no restringe)
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
                SELECT id_descuento, id_producto, 1 AS qualifies,
                       fecha_inicio, fecha_final
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
                t.fecha_inicio = CASE WHEN s.qualifies = 1 THEN s.fecha_inicio
                                      ELSE t.fecha_inicio END,
                t.fecha_fin    = CASE WHEN s.qualifies = 1 THEN s.fecha_final
                                      ELSE t.fecha_fin END
            -- Solo toca la fila si algo cambia (DECODE trata los NULL como iguales)
            WHERE t.activo <> CASE WHEN s.qualifies = 1 THEN 'S' ELSE 'N' END
               OR (s.qualifies = 1
                   AND (DECODE(t.fecha_inicio, s.fecha_inicio, 0, 1) = 1
                        OR DECODE(t.fecha_fin, s.fecha_final, 0, 1) = 1))
        WHEN NOT MATCHED THEN
            INSERT (id_descuento, id_producto, fecha_inicio, fecha_fin, activo)
            VALUES (s.id_descuento, s.id_producto, s.fecha_inicio, s.fecha_final, 'S');

        p_rows_changed := SQL%ROWCOUNT;

        IF p_commit THEN
            COMMIT;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            -- Se deshace solo lo de esta revision; lo anterior de la sesion queda
            ROLLBACK TO SAVEPOINT sp_apply_scheduled_discounts;
            p_rows_changed := NULL;
            PKG_CP_ERROR.registrar_inesperado(
                c_modulo,
                'fecha=' || TO_CHAR(p_today, 'DD/MM/YYYY')
            );
            RAISE;
    END apply_scheduled_discounts;


    PROCEDURE run_weekly_check
    IS
        v_rows_changed NUMBER;
    BEGIN
        apply_scheduled_discounts(TRUNC(SYSDATE), v_rows_changed);
    END run_weekly_check;

END PKG_CP_DESCUENTO;
/

SHOW ERRORS PACKAGE BODY PKG_CP_DESCUENTO

-- ============================================================
-- 2B. AUDITORIA DE LAS LINEAS DEL DESCUENTO
-- ============================================================
-- TRG_CP_AUD_DESCUENTO (Parte 1) audita el encabezado CP_DESCUENTO, pero
-- no las lineas de CP_DESCUENTO_PRODUCTO, que el job cambia solo. Este
-- trigger las registra en la misma bitacora de descuentos, con el mismo
-- formato (columna=valor) y el prefijo tabla=CP_DESCUENTO_PRODUCTO para
-- distinguirlas del encabezado. En el job no hay usuario de la
-- aplicacion: id_usuario queda NULL, igual que en los triggers de la
-- Parte 1, y significa "proceso automatico".

CREATE OR REPLACE TRIGGER TRG_CP_AUD_DESCUENTO_PRODUCTO
AFTER INSERT OR UPDATE OR DELETE ON CP_DESCUENTO_PRODUCTO
FOR EACH ROW
DECLARE
    v_operacion VARCHAR2(20);
    v_anterior  CLOB;
    v_nuevo     CLOB;

    -- Texto de una linea en el formato de las bitacoras de la Parte 1
    FUNCTION line_text(
        p_id_producto  IN NUMBER,
        p_fecha_inicio IN DATE,
        p_fecha_fin    IN DATE,
        p_activo       IN VARCHAR2
    ) RETURN VARCHAR2
    IS
    BEGIN
        RETURN 'tabla=CP_DESCUENTO_PRODUCTO' || CHR(10) ||
               'id_producto=' || NVL(TO_CHAR(p_id_producto), '<NULL>') || CHR(10) ||
               'fecha_inicio=' || NVL(TO_CHAR(p_fecha_inicio, 'YYYY-MM-DD'), '<NULL>') || CHR(10) ||
               'fecha_fin=' || NVL(TO_CHAR(p_fecha_fin, 'YYYY-MM-DD'), '<NULL>') || CHR(10) ||
               'activo=' || NVL(p_activo, '<NULL>');
    END line_text;
BEGIN
    IF INSERTING THEN
        v_operacion := 'INSERCION';
        v_nuevo := line_text(:NEW.id_producto, :NEW.fecha_inicio, :NEW.fecha_fin, :NEW.activo);
    ELSIF UPDATING THEN
        v_operacion := 'MODIFICACION';
        v_anterior := line_text(:OLD.id_producto, :OLD.fecha_inicio, :OLD.fecha_fin, :OLD.activo);
        v_nuevo := line_text(:NEW.id_producto, :NEW.fecha_inicio, :NEW.fecha_fin, :NEW.activo);
    ELSE
        v_operacion := 'ELIMINACION';
        v_anterior := line_text(:OLD.id_producto, :OLD.fecha_inicio, :OLD.fecha_fin, :OLD.activo);
    END IF;

    INSERT INTO CP_BITACORA_DESCUENTO (
        id_descuento, id_usuario, operacion,
        valor_anterior, valor_nuevo, fecha_hora
    ) VALUES (
        NVL(:NEW.id_descuento, :OLD.id_descuento), PKG_CP_CONTEXTO.g_id_usuario,
        v_operacion, v_anterior, v_nuevo, SYSTIMESTAMP
    );
END;
/

SHOW ERRORS TRIGGER TRG_CP_AUD_DESCUENTO_PRODUCTO

-- ============================================================
-- 3. PRUEBAS DE LA REVISION
-- ============================================================
-- Todas deben salir OK. Se ejecutan como CP_POS y todo se deshace con
-- ROLLBACK (la revision se llama con p_commit => FALSE). Se compra un
-- lote de prueba con la API (vence en 30 dias, ingresa hoy) y se crean
-- descuentos de prueba T29-... con distintas reglas, estados y
-- alcances; la fecha "de hoy" que recibe el paquete se mueve para
-- probar cada frontera. Las pruebas miran solo las lineas de los
-- descuentos de prueba, asi que no importan los descuentos reales.

DECLARE
    v_antes       NUMBER;
    v_ok          NUMBER := 0;
    v_falla       NUMBER := 0;

    v_prov        NUMBER;
    v_other_prov  NUMBER;
    v_neg         NUMBER;
    v_pp          NUMBER;
    v_alm         NUMBER;
    v_user        NUMBER;
    v_invoice     NUMBER;
    v_lots        PKG_CP_FACTURACION.t_lineas_compra;

    v_product     NUMBER;
    v_family      NUMBER;
    v_other_fam   NUMBER;

    v_today       DATE   := TRUNC(SYSDATE);
    v_stamp       VARCHAR2(20) := TO_CHAR(SYSDATE, 'MMDDHH24MISS');
    v_changed     NUMBER;
    v_count       NUMBER;
    v_buy_ok      BOOLEAN;

    d_venc        NUMBER;
    d_ingreso     NUMBER;
    d_otra_fam    NUMBER;
    d_prov_ok     NUMBER;
    d_prov_otro   NUMBER;
    d_final       NUMBER;
    d_sin_reglas  NUMBER;
    d_terminado   NUMBER;
    d_programado  NUMBER;

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

    PROCEDURE omitir(
        p_prueba IN VARCHAR2
    )
    IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(RPAD(p_prueba, 72, '.') || ' omitida');
    END omitir;

    -- Crea un descuento de prueba (10 %) en el negocio del lote
    FUNCTION make_discount(
        p_name  IN VARCHAR2,
        p_state IN VARCHAR2,
        p_start IN DATE,
        p_end   IN DATE
    ) RETURN NUMBER
    IS
        v_state NUMBER;
        v_id    NUMBER;
    BEGIN
        SELECT id_estado_descuento INTO v_state
        FROM CP_ESTADO_DESCUENTO WHERE nombre_estado_descuento = p_state;

        INSERT INTO CP_DESCUENTO
            (id_negocio, id_estado_descuento, nombre_descuento,
             porcentaje_descuento, fecha_inicio, fecha_final)
        VALUES
            (v_neg, v_state, p_name, 10, p_start, p_end)
        RETURNING id_descuento INTO v_id;

        RETURN v_id;
    END make_discount;

    PROCEDURE add_expiry_rule(
        p_discount IN NUMBER,
        p_days     IN NUMBER
    )
    IS
    BEGIN
        INSERT INTO CP_DESCUENTO_VENCIMIENTO (id_descuento, dias_antes_vencimiento)
        VALUES (p_discount, p_days);
    END add_expiry_rule;

    PROCEDURE add_entry_rule(
        p_discount IN NUMBER,
        p_from     IN DATE,
        p_to       IN DATE
    )
    IS
    BEGIN
        INSERT INTO CP_DESCUENTO_FECHA_INGRESO
            (id_descuento, fecha_ingreso_desde, fecha_ingreso_hasta)
        VALUES (p_discount, p_from, p_to);
    END add_entry_rule;

    PROCEDURE add_family(
        p_discount IN NUMBER,
        p_family   IN NUMBER
    )
    IS
    BEGIN
        INSERT INTO CP_DESCUENTO_FAMILIA (id_descuento, id_familia_producto)
        VALUES (p_discount, p_family);
    END add_family;

    PROCEDURE add_supplier(
        p_discount IN NUMBER,
        p_supplier IN NUMBER
    )
    IS
    BEGIN
        INSERT INTO CP_DESCUENTO_PROVEEDOR (id_descuento, id_proveedor)
        VALUES (p_discount, p_supplier);
    END add_supplier;

    -- Revision de prueba: sin confirmar, devuelve cuantas filas cambio
    FUNCTION review(
        p_today IN DATE
    ) RETURN NUMBER
    IS
        v_rows NUMBER;
    BEGIN
        PKG_CP_DESCUENTO.apply_scheduled_discounts(p_today, v_rows, FALSE);
        RETURN v_rows;
    END review;

    -- 'S' o 'N' segun la linea del producto de prueba; NULL si no existe
    FUNCTION line_state(
        p_discount IN NUMBER
    ) RETURN VARCHAR2
    IS
        v_state CP_DESCUENTO_PRODUCTO.activo%TYPE;
    BEGIN
        SELECT activo INTO v_state
        FROM CP_DESCUENTO_PRODUCTO
        WHERE id_descuento = p_discount AND id_producto = v_product;
        RETURN v_state;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END line_state;

    FUNCTION line_total(
        p_discount IN NUMBER
    ) RETURN NUMBER
    IS
        v_total NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_total
        FROM CP_DESCUENTO_PRODUCTO
        WHERE id_descuento = p_discount AND id_producto = v_product;
        RETURN v_total;
    END line_total;

    -- Filas de bitacora de lineas del descuento con esa operacion y texto
    FUNCTION audit_rows(
        p_discount  IN NUMBER,
        p_operation IN VARCHAR2,
        p_text      IN VARCHAR2
    ) RETURN NUMBER
    IS
        v_rows NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_rows
        FROM CP_BITACORA_DESCUENTO
        WHERE id_descuento = p_discount
          AND operacion = p_operation
          AND DBMS_LOB.INSTR(valor_nuevo, 'tabla=CP_DESCUENTO_PRODUCTO') > 0
          AND DBMS_LOB.INSTR(valor_nuevo, p_text) > 0;
        RETURN v_rows;
    END audit_rows;

BEGIN

    SELECT NVL(MAX(id_bitacora_error), 0) INTO v_antes FROM CP_BITACORA_ERROR;

    -- Datos para la compra del lote de prueba (primer proveedor con credito)
    SELECT id_proveedor, id_negocio
    INTO v_prov, v_neg
    FROM CP_CREDITO_PROVEEDOR
    ORDER BY id_credito_proveedor
    FETCH FIRST 1 ROW ONLY;

    SELECT MIN(id_producto_proveedor) INTO v_pp
    FROM CP_PRODUCTO_PROVEEDOR WHERE id_proveedor = v_prov;

    SELECT pp.id_producto, p.id_familia_producto
    INTO v_product, v_family
    FROM CP_PRODUCTO_PROVEEDOR pp
    JOIN CP_PRODUCTO p ON p.id_producto = pp.id_producto
    WHERE pp.id_producto_proveedor = v_pp;

    SELECT MIN(a.id_almacen) INTO v_alm
    FROM CP_ALMACEN a
    JOIN CP_SUCURSAL s ON s.id_sucursal = a.id_sucursal
    WHERE s.id_negocio = v_neg;

    SELECT MIN(id_usuario) INTO v_user FROM CP_USUARIO;

    SELECT MIN(id_familia_producto) INTO v_other_fam
    FROM CP_FAMILIA_PRODUCTO WHERE id_familia_producto <> v_family;

    SELECT MIN(id_proveedor) INTO v_other_prov
    FROM CP_PROVEEDOR WHERE id_proveedor <> v_prov;

    v_lots(1).id_producto_proveedor := v_pp;
    v_lots(1).cantidad := 5;
    v_lots(1).precio_costo_unitario := 1000;
    v_lots(1).porcentaje_descuento := 0;
    v_lots(1).porcentaje_impuesto := 0;
    v_lots(1).numero_lote := 'T29-' || v_stamp;
    v_lots(1).fecha_vencimiento := v_today + 30;

    BEGIN
        PKG_CP_FACTURACION.registrar_compra(
            p_id_proveedor         => v_prov,
            p_id_negocio           => v_neg,
            p_id_almacen_recepcion => v_alm,
            p_id_usuario           => v_user,
            p_numero_factura       => 'T29-C-' || v_stamp,
            p_lineas               => v_lots,
            p_id_factura           => v_invoice,
            p_a_credito            => FALSE,
            p_commit               => FALSE
        );
        v_buy_ok := TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            v_buy_ok := FALSE;
    END;

    reportar('1. La compra de prueba dejo un lote con existencia',
             v_buy_ok);

    -- Descuentos de prueba (cada uno con una regla, estado o alcance distinto)
    d_venc := make_discount('T29-VENC-' || v_stamp, 'ACTIVO', v_today, v_today + 90);
    add_expiry_rule(d_venc, 7);
    add_family(d_venc, v_family);

    d_ingreso := make_discount('T29-INGRESO-' || v_stamp, 'ACTIVO', v_today, v_today + 90);
    add_entry_rule(d_ingreso, v_today - 1, v_today + 1);
    add_family(d_ingreso, v_family);

    d_prov_ok := make_discount('T29-PROV-OK-' || v_stamp, 'ACTIVO', v_today, v_today + 90);
    add_entry_rule(d_prov_ok, v_today - 1, v_today + 1);
    add_family(d_prov_ok, v_family);
    add_supplier(d_prov_ok, v_prov);

    d_final := make_discount('T29-FINAL-' || v_stamp, 'FINALIZADO', v_today, v_today + 90);
    add_entry_rule(d_final, v_today - 1, v_today + 1);
    add_family(d_final, v_family);

    d_sin_reglas := make_discount('T29-SINREGLAS-' || v_stamp, 'ACTIVO', v_today, v_today + 90);
    add_family(d_sin_reglas, v_family);

    d_terminado := make_discount('T29-TERMINADO-' || v_stamp, 'ACTIVO', v_today - 60, v_today - 1);
    add_entry_rule(d_terminado, v_today - 1, v_today + 1);
    add_family(d_terminado, v_family);

    d_programado := make_discount('T29-PROGRAMADO-' || v_stamp, 'PROGRAMADO', v_today + 10, v_today + 90);
    add_entry_rule(d_programado, v_today - 1, v_today + 1);
    add_family(d_programado, v_family);

    IF v_other_fam IS NOT NULL THEN
        d_otra_fam := make_discount('T29-OTRAFAM-' || v_stamp, 'ACTIVO', v_today, v_today + 90);
        add_entry_rule(d_otra_fam, v_today - 1, v_today + 1);
        add_family(d_otra_fam, v_other_fam);
    END IF;

    IF v_other_prov IS NOT NULL THEN
        d_prov_otro := make_discount('T29-PROV-OTRO-' || v_stamp, 'ACTIVO', v_today, v_today + 90);
        add_entry_rule(d_prov_otro, v_today - 1, v_today + 1);
        add_family(d_prov_otro, v_family);
        add_supplier(d_prov_otro, v_other_prov);
    END IF;

    -- ------------------------------------------------------------
    -- A. Primera revision con la fecha de hoy
    -- ------------------------------------------------------------
    v_changed := review(v_today);

    reportar('2. Regla de vencimiento: faltando 30 dias (regla de 7) no se agrega',
             line_state(d_venc) IS NULL);

    reportar('3. Regla de fecha de ingreso: el producto del lote se agrega activo',
             line_state(d_ingreso) = 'S');

    SELECT COUNT(*) INTO v_count
    FROM CP_DESCUENTO_PRODUCTO dp
    JOIN CP_DESCUENTO d ON d.id_descuento = dp.id_descuento
    WHERE dp.id_descuento = d_ingreso AND dp.id_producto = v_product
      AND dp.fecha_inicio = d.fecha_inicio AND dp.fecha_fin = d.fecha_final;

    reportar('4. La linea hereda la vigencia del descuento',
             v_count = 1);

    reportar('5. Un descuento PROGRAMADO tambien se prepara por adelantado',
             line_state(d_programado) = 'S');

    reportar('6. Un descuento FINALIZADO no se revisa',
             line_state(d_final) IS NULL);

    reportar('7. Un descuento cuya vigencia ya termino no se revisa',
             line_state(d_terminado) IS NULL);

    reportar('8. Un descuento sin reglas no agrega productos',
             line_state(d_sin_reglas) IS NULL);

    IF d_otra_fam IS NOT NULL THEN
        reportar('9. Alcance por familia: otra familia no recibe el producto',
                 line_state(d_otra_fam) IS NULL);
    ELSE
        omitir('9. Alcance por familia: otra familia no recibe el producto');
    END IF;

    reportar('10. Alcance por proveedor: el proveedor del lote recibe el producto',
             line_state(d_prov_ok) = 'S');

    IF d_prov_otro IS NOT NULL THEN
        reportar('11. Alcance por proveedor: otro proveedor no recibe el producto',
                 line_state(d_prov_otro) IS NULL);
    ELSE
        omitir('11. Alcance por proveedor: otro proveedor no recibe el producto');
    END IF;

    -- ------------------------------------------------------------
    -- B. Regla de vencimiento moviendo la fecha de hoy
    -- ------------------------------------------------------------
    v_changed := review(v_today + 23);

    reportar('12. Faltando 7 dias el producto se agrega (limite inclusive)',
             line_state(d_venc) = 'S');

    v_changed := review(v_today + 23);

    reportar('13. Repetir la revision no cambia nada ni duplica filas',
             v_changed = 0 AND line_total(d_venc) = 1);

    v_changed := review(v_today + 10);

    reportar('14. Si deja de cumplir se desactiva, no se borra',
             line_state(d_venc) = 'N' AND line_total(d_venc) = 1);

    v_changed := review(v_today + 27);

    reportar('15. Si vuelve a cumplir se reactiva sin duplicar',
             line_state(d_venc) = 'S' AND line_total(d_venc) = 1);

    v_changed := review(v_today + 31);

    reportar('16. Una vez vencido el lote ya no califica y se desactiva',
             line_state(d_venc) = 'N');

    -- ------------------------------------------------------------
    -- C. Bitacora de las lineas
    -- ------------------------------------------------------------
    reportar('17. La bitacora registra la linea agregada (INSERCION)',
             audit_rows(d_ingreso, 'INSERCION', 'id_producto=' || v_product || CHR(10)) = 1);

    reportar('18. La bitacora registra la desactivacion (MODIFICACION, activo=N)',
             audit_rows(d_venc, 'MODIFICACION', 'activo=N') >= 1);

    -- ------------------------------------------------------------
    -- D. Limpieza
    -- ------------------------------------------------------------
    SELECT COUNT(*) INTO v_count
    FROM CP_BITACORA_ERROR
    WHERE id_bitacora_error > v_antes AND modulo = 'DESCUENTO';

    reportar('19. Ninguna revision dejo errores en la bitacora',
             v_count = 0);

    ROLLBACK;

    SELECT COUNT(*) INTO v_count
    FROM CP_DESCUENTO WHERE nombre_descuento LIKE 'T29-%';

    reportar('20. El ROLLBACK deja la base sin los descuentos de prueba',
             v_count = 0);

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
-- 4. JOB SEMANAL DE DESCUENTOS
-- ============================================================
-- Corre cada lunes a las 05:30 (antes del reporte de inventario de las
-- 06:00). Se vuelve a crear en cada ejecucion del script (primero se
-- borra). A peticion del profesor:
--   EXEC PKG_CP_DESCUENTO.run_weekly_check;
-- o lanzar el job al instante con:
--   EXEC DBMS_SCHEDULER.RUN_JOB('JOB_CP_REVISION_DESCUENTOS', FALSE);

BEGIN

    BEGIN
        DBMS_SCHEDULER.DROP_JOB('JOB_CP_REVISION_DESCUENTOS', force => TRUE);
    EXCEPTION
        WHEN OTHERS THEN
            -- ORA-27475: el job no existe todavia, no es un error
            IF SQLCODE != -27475 THEN
                RAISE;
            END IF;
    END;

    DBMS_SCHEDULER.CREATE_JOB(
        job_name        => 'JOB_CP_REVISION_DESCUENTOS',
        job_type        => 'PLSQL_BLOCK',
        job_action      => 'BEGIN PKG_CP_DESCUENTO.run_weekly_check; END;',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=WEEKLY;BYDAY=MON;BYHOUR=5;BYMINUTE=30;BYSECOND=0',
        enabled         => TRUE,
        comments        => 'Revision semanal de descuentos planeados: agrega o desactiva productos.'
    );

END;
/

-- Lanza el job una vez y espera para ver su resultado en el historial
BEGIN
    DBMS_SCHEDULER.RUN_JOB('JOB_CP_REVISION_DESCUENTOS', FALSE);
    DBMS_SESSION.SLEEP(5);
END;
/

SELECT job_name, enabled, state, repeat_interval, next_run_date
FROM   user_scheduler_jobs
WHERE  job_name = 'JOB_CP_REVISION_DESCUENTOS';

SELECT job_name, status, actual_start_date, run_duration, errors
FROM   user_scheduler_job_run_details
WHERE  job_name = 'JOB_CP_REVISION_DESCUENTOS'
ORDER  BY log_date DESC
FETCH FIRST 3 ROWS ONLY;
