-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- BASE DE DATOS: Oracle 21c
-- SCRIPT: 35_negocio_bitacoras.sql
-- DESCRIPCION: Completa la bitacora de facturacion. Los triggers de la
--              Parte 1 solo registran los cambios de estado o de total
--              de las ventas; aqui se agrega:
--              - TRG_CP_BIT_VENTA_CREACION: la creacion de cada factura
--                de venta queda en CP_BITACORA_VENTA.
--              - CP_BITACORA_COMPRA y TRG_CP_BIT_COMPRA: creacion y cada
--                cambio de estado o de total de las facturas de compra.
--              - TRG_CP_FACTURA_VENTA_SIN_BORRADO y
--                TRG_CP_FACTURA_COMPRA_SIN_BORRADO: una factura no se borra,
--                se anula (y la anulacion queda en la bitacora).
--              El usuario registrado es el de la sesion de la aplicacion
--              (PKG_CP_CONTEXTO) y, si no hay, el de la factura. Quien
--              hizo el cambio en la base lo registra ademas la auditoria
--              del motor (script 36).
--
-- EJECUTAR COMO: CP_POS en XEPDB1 (despues de los scripts 15 y 25).
--                Se puede volver a ejecutar completo; la tabla solo se
--                crea si falta. Despues correr el 13 y el 36 como SYS.
--
-- ERRORES PROPIOS (tramo -20240 a -20249):
--   -20240 una factura no se puede borrar
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED

-- ============================================================
-- 1. TABLA CP_BITACORA_COMPRA
-- ============================================================
-- Misma forma que CP_BITACORA_VENTA, pero el estado y el total anteriores
-- quedan en NULL en la creacion (no habia un valor anterior). Un indice
-- por cada llave foranea, como el resto del modelo.

DECLARE
    v_count NUMBER;

    PROCEDURE run(
        p_sql IN VARCHAR2
    )
    IS
    BEGIN
        EXECUTE IMMEDIATE p_sql;
    END run;
BEGIN

    SELECT COUNT(*) INTO v_count
    FROM user_sequences WHERE sequence_name = 'SEQ_CP_BITACORA_COMPRA';

    IF v_count = 0 THEN
        run('CREATE SEQUENCE SEQ_CP_BITACORA_COMPRA START WITH 1 INCREMENT BY 1 NOCACHE');
    END IF;

    SELECT COUNT(*) INTO v_count
    FROM user_tables WHERE table_name = 'CP_BITACORA_COMPRA';

    IF v_count = 0 THEN
        run(q'[
            CREATE TABLE CP_BITACORA_COMPRA (
                id_bitacora_compra NUMBER
                    DEFAULT SEQ_CP_BITACORA_COMPRA.NEXTVAL
                    NOT NULL,
                id_factura_compra  NUMBER NOT NULL,
                id_usuario         NUMBER NOT NULL,
                id_tipo_operacion  NUMBER NOT NULL,
                id_estado_anterior NUMBER,
                id_estado_nuevo    NUMBER NOT NULL,
                total_anterior     NUMBER(14,2),
                total_nuevo        NUMBER(14,2) NOT NULL,
                fecha_operacion    TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
                motivo             VARCHAR2(250),
                CONSTRAINT PK_CP_BITACORA_COMPRA
                    PRIMARY KEY (id_bitacora_compra)
                    USING INDEX TABLESPACE CP_POS_INDICES,
                CONSTRAINT CK_CP_BITACORA_COMPRA_TOTAL_ANTERIOR
                    CHECK (total_anterior >= 0),
                CONSTRAINT CK_CP_BITACORA_COMPRA_TOTAL_NUEVO
                    CHECK (total_nuevo >= 0)
            ) TABLESPACE CP_POS_AUDITORIA]');

        run('ALTER TABLE CP_BITACORA_COMPRA ADD CONSTRAINT FK_CP_BIT_COMPRA_FACTURA '
            || 'FOREIGN KEY (id_factura_compra) REFERENCES CP_FACTURA_COMPRA (id_factura_compra)');
        run('ALTER TABLE CP_BITACORA_COMPRA ADD CONSTRAINT FK_CP_BIT_COMPRA_USUARIO '
            || 'FOREIGN KEY (id_usuario) REFERENCES CP_USUARIO (id_usuario)');
        run('ALTER TABLE CP_BITACORA_COMPRA ADD CONSTRAINT FK_CP_BIT_COMPRA_OPERACION '
            || 'FOREIGN KEY (id_tipo_operacion) REFERENCES CP_TIPO_OPERACION (id_tipo_operacion)');
        run('ALTER TABLE CP_BITACORA_COMPRA ADD CONSTRAINT FK_CP_BIT_COMPRA_EST_ANT '
            || 'FOREIGN KEY (id_estado_anterior) REFERENCES CP_ESTADO_FACTURA_COMPRA (id_estado_factura_compra)');
        run('ALTER TABLE CP_BITACORA_COMPRA ADD CONSTRAINT FK_CP_BIT_COMPRA_EST_NUE '
            || 'FOREIGN KEY (id_estado_nuevo) REFERENCES CP_ESTADO_FACTURA_COMPRA (id_estado_factura_compra)');

        run('CREATE INDEX IX_CP_BIT_COMPRA_FACTURA ON CP_BITACORA_COMPRA (id_factura_compra) TABLESPACE CP_POS_INDICES');
        run('CREATE INDEX IX_CP_BIT_COMPRA_USUARIO ON CP_BITACORA_COMPRA (id_usuario) TABLESPACE CP_POS_INDICES');
        run('CREATE INDEX IX_CP_BIT_COMPRA_OPERACION ON CP_BITACORA_COMPRA (id_tipo_operacion) TABLESPACE CP_POS_INDICES');
        run('CREATE INDEX IX_CP_BIT_COMPRA_EST_ANT ON CP_BITACORA_COMPRA (id_estado_anterior) TABLESPACE CP_POS_INDICES');
        run('CREATE INDEX IX_CP_BIT_COMPRA_EST_NUE ON CP_BITACORA_COMPRA (id_estado_nuevo) TABLESPACE CP_POS_INDICES');

        run(q'[COMMENT ON TABLE CP_BITACORA_COMPRA IS
            'Bitacora de las facturas de compra: creacion y cambios de estado o de total (TRG_CP_BIT_COMPRA)']');
        run(q'[COMMENT ON COLUMN CP_BITACORA_COMPRA.id_usuario IS
            'Usuario de la aplicacion que hizo la operacion; si la sesion no lo indica, el de la factura']');
        run(q'[COMMENT ON COLUMN CP_BITACORA_COMPRA.id_estado_anterior IS
            'Estado antes del cambio; NULL en la creacion']');
        run(q'[COMMENT ON COLUMN CP_BITACORA_COMPRA.total_anterior IS
            'Total antes del cambio; NULL en la creacion']');
    END IF;

END;
/

-- ============================================================
-- 2. CREACION DE LAS FACTURAS DE VENTA
-- ============================================================
-- CP_BITACORA_VENTA (Parte 1) exige estado y total anteriores: en la
-- creacion el estado anterior es el mismo nuevo y el total anterior es 0.

CREATE OR REPLACE TRIGGER TRG_CP_BIT_VENTA_CREACION
AFTER INSERT ON CP_FACTURA_VENTA
FOR EACH ROW
DECLARE
    v_tipo CP_TIPO_OPERACION.id_tipo_operacion%TYPE;
BEGIN

    SELECT id_tipo_operacion
    INTO v_tipo
    FROM CP_TIPO_OPERACION
    WHERE UPPER(TRIM(nombre_tipo_operacion)) = 'CREACION';

    INSERT INTO CP_BITACORA_VENTA (
        id_factura_venta,
        id_usuario,
        id_tipo_operacion,
        id_estado_anterior,
        id_estado_nuevo,
        total_anterior,
        total_nuevo,
        fecha_operacion,
        motivo
    )
    VALUES (
        :NEW.id_factura_venta,
        NVL(PKG_CP_CONTEXTO.g_id_usuario, :NEW.id_usuario),
        v_tipo,
        :NEW.id_estado_factura_venta,
        :NEW.id_estado_factura_venta,
        0,
        :NEW.total,
        SYSTIMESTAMP,
        'Creacion de la factura de venta ' || :NEW.numero_factura
    );

END;
/

-- ============================================================
-- 3. BITACORA DE LAS FACTURAS DE COMPRA
-- ============================================================

CREATE OR REPLACE TRIGGER TRG_CP_BIT_COMPRA
AFTER INSERT OR UPDATE OF id_estado_factura_compra, total ON CP_FACTURA_COMPRA
FOR EACH ROW
DECLARE
    v_tipo      CP_TIPO_OPERACION.id_tipo_operacion%TYPE;
    v_operacion CP_TIPO_OPERACION.nombre_tipo_operacion%TYPE;
    v_motivo    VARCHAR2(250);
BEGIN

    -- Un UPDATE que deja igual el estado y el total no es un cambio
    IF UPDATING
       AND NVL(:OLD.id_estado_factura_compra, -1) = NVL(:NEW.id_estado_factura_compra, -1)
       AND NVL(:OLD.total, -1) = NVL(:NEW.total, -1) THEN
        RETURN;
    END IF;

    -- INSERTING es un predicado de PL/SQL: se evalua aqui y no dentro
    -- de las sentencias SQL, que no lo conocen (ORA-00920)
    IF INSERTING THEN
        v_operacion := 'CREACION';
        v_motivo := 'Creacion de la factura de compra ' || :NEW.numero_factura;
    ELSE
        v_operacion := 'MODIFICACION';
        v_motivo := 'Cambio de la factura de compra ' || :NEW.numero_factura;
    END IF;

    SELECT id_tipo_operacion
    INTO v_tipo
    FROM CP_TIPO_OPERACION
    WHERE UPPER(TRIM(nombre_tipo_operacion)) = v_operacion;

    INSERT INTO CP_BITACORA_COMPRA (
        id_factura_compra,
        id_usuario,
        id_tipo_operacion,
        id_estado_anterior,
        id_estado_nuevo,
        total_anterior,
        total_nuevo,
        fecha_operacion,
        motivo
    )
    VALUES (
        :NEW.id_factura_compra,
        NVL(PKG_CP_CONTEXTO.g_id_usuario, :NEW.id_usuario),
        v_tipo,
        :OLD.id_estado_factura_compra,
        :NEW.id_estado_factura_compra,
        :OLD.total,
        :NEW.total,
        SYSTIMESTAMP,
        v_motivo
    );

END;
/

-- ============================================================
-- 4. LAS FACTURAS NO SE BORRAN
-- ============================================================
-- Una factura borrada desapareceria de la bitacora (su llave foranea lo
-- impide) y de las cuentas. La forma correcta es anularla con
-- PKG_CP_FACTURACION, y la anulacion queda registrada como cambio de estado.

CREATE OR REPLACE TRIGGER TRG_CP_FACTURA_VENTA_SIN_BORRADO
BEFORE DELETE ON CP_FACTURA_VENTA
FOR EACH ROW
BEGIN
    PKG_CP_ERROR.lanzar(
        'BITACORA',
        -20240,
        'La factura de venta ' || :OLD.numero_factura
            || ' no se puede borrar: se anula con PKG_CP_FACTURACION.anular_venta.'
    );
END;
/

CREATE OR REPLACE TRIGGER TRG_CP_FACTURA_COMPRA_SIN_BORRADO
BEFORE DELETE ON CP_FACTURA_COMPRA
FOR EACH ROW
BEGIN
    PKG_CP_ERROR.lanzar(
        'BITACORA',
        -20240,
        'La factura de compra ' || :OLD.numero_factura
            || ' no se puede borrar: se anula con PKG_CP_FACTURACION.anular_compra.'
    );
END;
/

-- ============================================================
-- 5. PRUEBAS
-- ============================================================
-- Todas deben salir OK. Una venta y una compra de prueba recorren su vida
-- completa (creacion, anulacion e intento de borrado) sin confirmarse;
-- al final todo se deshace con ROLLBACK y de la bitacora de errores solo
-- se borran los provocados a proposito.

DECLARE
    v_antes     NUMBER;
    v_ok        NUMBER := 0;
    v_falla     NUMBER := 0;
    v_count     NUMBER;
    v_code      NUMBER;
    v_stamp     VARCHAR2(20) := TO_CHAR(SYSDATE, 'MMDDHH24MISS');
    v_creacion  NUMBER;
    v_cambio    NUMBER;
    v_anulada_v NUMBER;
    v_anulada_c NUMBER;

    v_almacen   NUMBER;
    v_sucursal  NUMBER;
    v_producto  NUMBER;
    v_cliente   NUMBER;
    v_usuario   NUMBER;
    v_venta     NUMBER;
    v_total_v   NUMBER;
    v_lines     PKG_CP_FACTURACION.t_lineas_venta;
    v_have_sale BOOLEAN := FALSE;

    v_prov      NUMBER;
    v_neg       NUMBER;
    v_pp        NUMBER;
    v_alm       NUMBER;
    v_compra    NUMBER;
    v_total_c   NUMBER;
    v_lots      PKG_CP_FACTURACION.t_lineas_compra;
    v_have_buy  BOOLEAN := FALSE;

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
            RPAD(p_prueba, 76, '.') || CASE WHEN p_ok THEN ' OK' ELSE ' FALLA' END
        );
    END reportar;

    PROCEDURE omitir(
        p_prueba IN VARCHAR2,
        p_motivo IN VARCHAR2
    )
    IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(RPAD(p_prueba, 76, '.') || ' omitida (' || p_motivo || ')');
    END omitir;

    FUNCTION delete_sale_code RETURN NUMBER
    IS
    BEGIN
        DELETE FROM CP_FACTURA_VENTA WHERE id_factura_venta = v_venta;
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN SQLCODE;
    END delete_sale_code;

    FUNCTION delete_purchase_code RETURN NUMBER
    IS
    BEGIN
        DELETE FROM CP_FACTURA_COMPRA WHERE id_factura_compra = v_compra;
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN SQLCODE;
    END delete_purchase_code;

BEGIN

    SELECT NVL(MAX(id_bitacora_error), 0) INTO v_antes FROM CP_BITACORA_ERROR;

    SELECT id_tipo_operacion INTO v_creacion
    FROM CP_TIPO_OPERACION WHERE UPPER(TRIM(nombre_tipo_operacion)) = 'CREACION';
    SELECT id_tipo_operacion INTO v_cambio
    FROM CP_TIPO_OPERACION WHERE UPPER(TRIM(nombre_tipo_operacion)) = 'MODIFICACION';
    SELECT id_estado_factura_venta INTO v_anulada_v
    FROM CP_ESTADO_FACTURA_VENTA WHERE nombre_estado_factura = 'ANULADA';
    SELECT id_estado_factura_compra INTO v_anulada_c
    FROM CP_ESTADO_FACTURA_COMPRA WHERE nombre_estado_factura = 'ANULADA';

    -- ------------------------------------------------------------
    -- A. Estructura
    -- ------------------------------------------------------------
    SELECT COUNT(*) INTO v_count
    FROM user_triggers
    WHERE trigger_name IN ('TRG_CP_BIT_VENTA_CREACION', 'TRG_CP_BIT_COMPRA',
                           'TRG_CP_FACTURA_VENTA_SIN_BORRADO',
                           'TRG_CP_FACTURA_COMPRA_SIN_BORRADO')
      AND status = 'ENABLED';

    SELECT COUNT(*) + v_count INTO v_count
    FROM user_tables
    WHERE table_name = 'CP_BITACORA_COMPRA' AND tablespace_name = 'CP_POS_AUDITORIA';

    reportar('1. Los 4 triggers estan habilitados y CP_BITACORA_COMPRA esta en CP_POS_AUDITORIA',
             v_count = 5);

    -- ------------------------------------------------------------
    -- B. Vida de una factura de venta
    -- ------------------------------------------------------------
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
        HAVING SUM(v.cantidad_actual) >= 1
        ORDER BY SUM(v.cantidad_actual) DESC, v.id_producto, v.id_almacen
        FETCH FIRST 1 ROW ONLY;

        SELECT MIN(id_cliente) INTO v_cliente FROM CP_CLIENTE;
        SELECT MIN(id_usuario) INTO v_usuario FROM CP_USUARIO;

        v_lines(1).id_producto := v_producto;
        v_lines(1).cantidad := 1;
        v_lines(1).precio_unitario := 1000;

        PKG_CP_FACTURACION.registrar_venta(
            p_id_cliente     => v_cliente,
            p_id_sucursal    => v_sucursal,
            p_id_usuario     => v_usuario,
            p_numero_factura => 'T35-V-' || v_stamp,
            p_lineas         => v_lines,
            p_id_factura     => v_venta,
            p_a_credito      => FALSE,
            p_commit         => FALSE
        );

        SELECT total INTO v_total_v FROM CP_FACTURA_VENTA WHERE id_factura_venta = v_venta;
        v_have_sale := TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('no se pudo registrar la venta de prueba: ' || SQLERRM);
    END;

    IF v_have_sale THEN
        SELECT COUNT(*) INTO v_count
        FROM CP_BITACORA_VENTA
        WHERE id_factura_venta = v_venta
          AND id_tipo_operacion = v_creacion
          AND total_anterior = 0
          AND total_nuevo = v_total_v
          AND id_usuario = v_usuario;

        reportar('2. Crear una venta deja UNA fila de CREACION con su total y usuario',
                 v_count = 1);

        PKG_CP_FACTURACION.anular_venta(v_venta, p_commit => FALSE);

        SELECT COUNT(*) INTO v_count
        FROM CP_BITACORA_VENTA
        WHERE id_factura_venta = v_venta
          AND id_tipo_operacion = v_cambio
          AND id_estado_nuevo = v_anulada_v
          AND id_estado_anterior <> id_estado_nuevo;

        reportar('3. Anular la venta deja el cambio de estado a ANULADA',
                 v_count >= 1);

        v_code := delete_sale_code;
        SELECT COUNT(*) INTO v_count FROM CP_FACTURA_VENTA WHERE id_factura_venta = v_venta;

        reportar('4. Borrar la venta da -20240 y la factura sigue ahi',
                 v_code = -20240 AND v_count = 1);
    ELSE
        omitir('2 a 4. Vida de una factura de venta', 'no se pudo registrar la venta: ver la linea anterior');
    END IF;

    -- ------------------------------------------------------------
    -- C. Vida de una factura de compra
    -- ------------------------------------------------------------
    BEGIN
        SELECT id_proveedor, id_negocio
        INTO v_prov, v_neg
        FROM CP_CREDITO_PROVEEDOR
        WHERE id_proveedor IN (SELECT id_proveedor FROM CP_PRODUCTO_PROVEEDOR)
        ORDER BY id_credito_proveedor
        FETCH FIRST 1 ROW ONLY;

        SELECT MIN(id_producto_proveedor) INTO v_pp
        FROM CP_PRODUCTO_PROVEEDOR WHERE id_proveedor = v_prov;

        SELECT MIN(a.id_almacen) INTO v_alm
        FROM CP_ALMACEN a
        JOIN CP_SUCURSAL s ON s.id_sucursal = a.id_sucursal
        WHERE s.id_negocio = v_neg;

        SELECT MIN(id_usuario) INTO v_usuario FROM CP_USUARIO;

        v_lots(1).id_producto_proveedor := v_pp;
        v_lots(1).cantidad := 2;
        v_lots(1).precio_costo_unitario := 500;
        v_lots(1).porcentaje_descuento := 0;
        v_lots(1).porcentaje_impuesto := 0;
        v_lots(1).numero_lote := 'T35-L-' || v_stamp;
        v_lots(1).fecha_vencimiento := TRUNC(SYSDATE) + 365;

        PKG_CP_FACTURACION.registrar_compra(
            p_id_proveedor         => v_prov,
            p_id_negocio           => v_neg,
            p_id_almacen_recepcion => v_alm,
            p_id_usuario           => v_usuario,
            p_numero_factura       => 'T35-C-' || v_stamp,
            p_lineas               => v_lots,
            p_id_factura           => v_compra,
            p_a_credito            => FALSE,
            p_commit               => FALSE
        );

        SELECT total INTO v_total_c FROM CP_FACTURA_COMPRA WHERE id_factura_compra = v_compra;
        v_have_buy := TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('no se pudo registrar la compra de prueba: ' || SQLERRM);
    END;

    IF v_have_buy THEN
        SELECT COUNT(*) INTO v_count
        FROM CP_BITACORA_COMPRA
        WHERE id_factura_compra = v_compra
          AND id_tipo_operacion = v_creacion
          AND id_estado_anterior IS NULL
          AND total_anterior IS NULL
          AND total_nuevo = v_total_c
          AND id_usuario = v_usuario;

        reportar('5. Crear una compra deja UNA fila de CREACION con su total y usuario',
                 v_count = 1);

        PKG_CP_FACTURACION.anular_compra(v_compra, p_commit => FALSE);

        SELECT COUNT(*) INTO v_count
        FROM CP_BITACORA_COMPRA
        WHERE id_factura_compra = v_compra
          AND id_tipo_operacion = v_cambio
          AND id_estado_nuevo = v_anulada_c
          AND id_estado_anterior <> id_estado_nuevo;

        reportar('6. Anular la compra deja el cambio de estado a ANULADA',
                 v_count >= 1);

        UPDATE CP_FACTURA_COMPRA
        SET total = total
        WHERE id_factura_compra = v_compra;

        SELECT COUNT(*) INTO v_count
        FROM CP_BITACORA_COMPRA WHERE id_factura_compra = v_compra;

        reportar('7. Un UPDATE que no cambia estado ni total no agrega filas',
                 v_count = 2);

        v_code := delete_purchase_code;
        SELECT COUNT(*) INTO v_count FROM CP_FACTURA_COMPRA WHERE id_factura_compra = v_compra;

        reportar('8. Borrar la compra da -20240 y la factura sigue ahi',
                 v_code = -20240 AND v_count = 1);
    ELSE
        omitir('5 a 8. Vida de una factura de compra', 'no se pudo registrar la compra: ver la linea anterior');
    END IF;

    SELECT COUNT(*) INTO v_count
    FROM CP_BITACORA_ERROR
    WHERE id_bitacora_error > v_antes AND codigo_error = -20240;

    reportar('9. Cada borrado rechazado quedo UNA sola vez en la bitacora de errores',
             v_count = CASE WHEN v_have_sale THEN 1 ELSE 0 END
                     + CASE WHEN v_have_buy THEN 1 ELSE 0 END);

    -- ------------------------------------------------------------
    -- D. Limpieza
    -- ------------------------------------------------------------
    ROLLBACK;

    SELECT COUNT(*) INTO v_count
    FROM CP_FACTURA_VENTA WHERE numero_factura = 'T35-V-' || v_stamp;

    SELECT COUNT(*) + v_count INTO v_count
    FROM CP_FACTURA_COMPRA WHERE numero_factura = 'T35-C-' || v_stamp;

    reportar('10. El ROLLBACK deja la base sin las facturas de prueba ni sus bitacoras',
             v_count = 0);

    DELETE FROM CP_BITACORA_ERROR
    WHERE id_bitacora_error > v_antes
      AND modulo = 'BITACORA';
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
-- 6. VERIFICACION
-- ============================================================

SELECT trigger_name, table_name, triggering_event, status
FROM   user_triggers
WHERE  trigger_name IN ('TRG_CP_BITACORA_VENTA', 'TRG_CP_BIT_VENTA_CREACION',
                        'TRG_CP_BIT_COMPRA', 'TRG_CP_FACTURA_VENTA_SIN_BORRADO',
                        'TRG_CP_FACTURA_COMPRA_SIN_BORRADO')
ORDER  BY table_name, trigger_name;

SELECT object_name, object_type, status
FROM   user_objects
WHERE  object_name IN ('CP_BITACORA_COMPRA', 'SEQ_CP_BITACORA_COMPRA')
ORDER  BY object_name;

-- FK sin indice en la tabla nueva (esperado: ninguna fila)
SELECT c.constraint_name, cc.column_name
FROM   user_constraints c
JOIN   user_cons_columns cc
  ON   cc.constraint_name = c.constraint_name
WHERE  c.table_name = 'CP_BITACORA_COMPRA'
  AND  c.constraint_type = 'R'
  AND  NOT EXISTS (SELECT 1 FROM user_ind_columns ic
                   WHERE ic.table_name = c.table_name
                     AND ic.column_name = cc.column_name
                     AND ic.column_position = 1);
