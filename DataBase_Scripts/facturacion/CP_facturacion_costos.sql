-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- BASE DE DATOS: Oracle 21c
-- SCRIPT: 22_facturacion_costos.sql
-- DESCRIPCION: Historial de costos. Paquete PKG_CP_COSTO y trigger
--              TRG_CP_COMPRA_COSTO_LINEA: cuando una linea de compra
--              trae un costo distinto al costo actual del producto
--              con ese proveedor, se actualiza
--              CP_PRODUCTO_PROVEEDOR.precio_costo_actual y el cambio
--              queda en CP_BITACORA_COSTO_PRODUCTO (lo escribe el
--              trigger TRG_CP_AUD_COSTO_PRODUCTO de la Parte 1).
--              Incluye pruebas.
--
-- EJECUTAR COMO: CP_POS en XEPDB1 (despues de los scripts 15 y 21).
--                Se puede volver a ejecutar completo las veces
--                que haga falta.
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED

-- ============================================================
-- 1. PAQUETE PKG_CP_COSTO (ESPECIFICACION)
-- ============================================================

CREATE OR REPLACE PACKAGE PKG_CP_COSTO AUTHID DEFINER AS

    PROCEDURE registrar_costo_compra(
        p_id_factura            IN NUMBER,
        p_id_producto_proveedor IN NUMBER,
        p_costo_unitario        IN NUMBER
    )
    ACCESSIBLE BY (TRIGGER TRG_CP_COMPRA_COSTO_LINEA);

END PKG_CP_COSTO;
/

-- ============================================================
-- 2. PAQUETE PKG_CP_COSTO (CUERPO)
-- ============================================================

CREATE OR REPLACE PACKAGE BODY PKG_CP_COSTO AS

    c_modulo CONSTANT VARCHAR2(20) := 'COSTO';

    c_estado_anulada CONSTANT VARCHAR2(30) := 'ANULADA';

    c_err_ocupado CONSTANT PLS_INTEGER := -20290;

    e_ocupado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_ocupado, -30006);


    -- Compara el costo de la linea de compra con el costo actual del producto con ese
    -- proveedor; si es distinto lo actualiza (el historial lo escribe el trigger de
    -- auditoria de la Parte 1). Bloquea la fila con FOR UPDATE WAIT 5 (-20290) y no
    -- actua sobre facturas anuladas.
    PROCEDURE registrar_costo_compra(
        p_id_factura            IN NUMBER,
        p_id_producto_proveedor IN NUMBER,
        p_costo_unitario        IN NUMBER
    )
    ACCESSIBLE BY (TRIGGER TRG_CP_COMPRA_COSTO_LINEA)
    IS
        v_id_usuario     CP_FACTURA_COMPRA.id_usuario%TYPE;
        v_estado         CP_ESTADO_FACTURA_COMPRA.nombre_estado_factura%TYPE;
        v_costo_actual   CP_PRODUCTO_PROVEEDOR.precio_costo_actual%TYPE;
        v_usuario_previo NUMBER;
    BEGIN

        -- Una factura anulada no cambia el costo del producto
        SELECT fc.id_usuario, ef.nombre_estado_factura
        INTO v_id_usuario, v_estado
        FROM CP_FACTURA_COMPRA fc
        JOIN CP_ESTADO_FACTURA_COMPRA ef
          ON ef.id_estado_factura_compra = fc.id_estado_factura_compra
        WHERE fc.id_factura_compra = p_id_factura;

        IF v_estado = c_estado_anulada THEN
            RETURN;
        END IF;

        -- Se bloquea el costo para que dos compras simultaneas no se pisen
        BEGIN

            SELECT precio_costo_actual
            INTO v_costo_actual
            FROM CP_PRODUCTO_PROVEEDOR
            WHERE id_producto_proveedor = p_id_producto_proveedor
            FOR UPDATE WAIT 5;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                -- La llave foranea de la linea rechaza el producto inexistente
                RETURN;
            WHEN e_ocupado THEN
                PKG_CP_ERROR.lanzar(
                    c_modulo,
                    c_err_ocupado,
                    'El costo del producto-proveedor ' || p_id_producto_proveedor
                    || ' esta siendo modificado por otra sesion. Intente de nuevo.'
                );
        END;

        IF v_costo_actual = p_costo_unitario THEN
            RETURN;
        END IF;

        -- La bitacora de costos guarda el usuario del contexto; si no hay, el de la factura
        v_usuario_previo := PKG_CP_CONTEXTO.g_id_usuario;

        IF v_usuario_previo IS NULL THEN
            PKG_CP_CONTEXTO.g_id_usuario := v_id_usuario;
        END IF;

        BEGIN

            UPDATE CP_PRODUCTO_PROVEEDOR
            SET precio_costo_actual = p_costo_unitario
            WHERE id_producto_proveedor = p_id_producto_proveedor;

        EXCEPTION
            WHEN OTHERS THEN
                PKG_CP_CONTEXTO.g_id_usuario := v_usuario_previo;
                RAISE;
        END;

        PKG_CP_CONTEXTO.g_id_usuario := v_usuario_previo;

    END registrar_costo_compra;

END PKG_CP_COSTO;
/

-- ============================================================
-- 3. TRIGGER DE LINEAS DE COMPRA
-- ============================================================

-- Cada linea de compra nueva registra su costo en el producto del proveedor.
CREATE OR REPLACE TRIGGER TRG_CP_COMPRA_COSTO_LINEA
AFTER INSERT
ON CP_DETALLE_COMPRA
FOR EACH ROW
BEGIN

    PKG_CP_COSTO.registrar_costo_compra(
        :NEW.id_factura_compra,
        :NEW.id_producto_proveedor,
        :NEW.precio_costo_unitario
    );

END TRG_CP_COMPRA_COSTO_LINEA;
/

-- ============================================================
-- 4. VERIFICACION
-- ============================================================

SELECT trigger_name, table_name, status
FROM user_triggers
WHERE trigger_name = 'TRG_CP_COMPRA_COSTO_LINEA';

SELECT object_name, object_type, status
FROM user_objects
WHERE object_name = 'PKG_CP_COSTO'
ORDER BY object_type;

SELECT name, type, line, text
FROM user_errors
WHERE name IN ('PKG_CP_COSTO', 'TRG_CP_COMPRA_COSTO_LINEA')
ORDER BY name, type, sequence;

-- ============================================================
-- 5. PRUEBAS DE HISTORIAL DE COSTOS
-- ============================================================

DECLARE
    v_antes         NUMBER;
    v_base          NUMBER;
    v_errores       NUMBER;
    v_id_pp         NUMBER;
    v_id_pp2        NUMBER;
    v_id_proveedor  NUMBER;
    v_id_negocio    NUMBER;
    v_id_almacen    NUMBER;
    v_u1            NUMBER;
    v_u2            NUMBER;
    v_fc_registrada NUMBER;
    v_fc_anulada    NUMBER;
    v_c0            NUMBER;
    v_c1            NUMBER;
    v_c2            NUMBER;
    v_c3            NUMBER;
    v_c4            NUMBER;
    v_c5            NUMBER;
    v_c6            NUMBER;
    v_otro_inicial  NUMBER;
    v_cuenta        NUMBER;
    v_f1            NUMBER;
    v_f2            NUMBER;
    v_f3            NUMBER;
    v_f4            NUMBER;
    v_ultima        NUMBER;
    v_codigo        NUMBER;
    v_ultimo_error  VARCHAR2(300);

    PROCEDURE reportar(
        p_prueba IN VARCHAR2,
        p_ok     IN BOOLEAN
    )
    IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(
            RPAD(p_prueba, 70, '.') || CASE WHEN p_ok THEN ' OK' ELSE ' FALLA' END
        );
        IF NOT p_ok AND v_ultimo_error IS NOT NULL THEN
            DBMS_OUTPUT.PUT_LINE('      ultimo error: ' || v_ultimo_error);
        END IF;
    END reportar;

    FUNCTION costo_de(
        p_pp IN NUMBER
    ) RETURN NUMBER
    IS
        v_costo NUMBER;
    BEGIN
        SELECT precio_costo_actual
        INTO v_costo
        FROM CP_PRODUCTO_PROVEEDOR
        WHERE id_producto_proveedor = p_pp;
        RETURN v_costo;
    END costo_de;

    FUNCTION cambios_bitacora RETURN NUMBER
    IS
        v_total NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_total
        FROM CP_BITACORA_COSTO_PRODUCTO
        WHERE id_producto_proveedor = v_id_pp
          AND id_bitacora_costo_producto > v_base;
        RETURN v_total;
    END cambios_bitacora;

    FUNCTION cambio_registrado(
        p_anterior IN NUMBER,
        p_nuevo    IN NUMBER,
        p_usuario  IN NUMBER
    ) RETURN NUMBER
    IS
        v_total NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_total
        FROM CP_BITACORA_COSTO_PRODUCTO
        WHERE id_producto_proveedor = v_id_pp
          AND id_bitacora_costo_producto > v_base
          AND costo_anterior = p_anterior
          AND costo_nuevo = p_nuevo
          AND (p_usuario IS NULL OR id_usuario = p_usuario);
        RETURN v_total;
    END cambio_registrado;

    FUNCTION nueva_factura_compra(
        p_numero IN VARCHAR2,
        p_fecha  IN DATE
    ) RETURN NUMBER
    IS
    BEGIN
        INSERT INTO CP_FACTURA_COMPRA
            (id_proveedor, id_negocio, id_almacen_recepcion, id_usuario,
             id_estado_factura_compra, numero_factura, fecha_emision,
             fecha_recepcion, subtotal, descuento_total, impuesto_total, total)
        VALUES
            (v_id_proveedor, v_id_negocio, v_id_almacen, v_u1,
             v_fc_registrada, p_numero, p_fecha, SYSDATE, 0, 0, 0, 0)
        RETURNING id_factura_compra INTO v_ultima;
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            v_ultimo_error := SUBSTR(SQLERRM, 1, 300);
            v_ultima := NULL;
            RETURN SQLCODE;
    END nueva_factura_compra;

    FUNCTION linea_compra(
        p_factura IN NUMBER,
        p_pp      IN NUMBER,
        p_costo   IN NUMBER
    ) RETURN NUMBER
    IS
    BEGIN
        v_ultimo_error := NULL;
        INSERT INTO CP_DETALLE_COMPRA
            (id_factura_compra, id_producto_proveedor, cantidad,
             precio_costo_unitario, monto_descuento, porcentaje_impuesto,
             monto_impuesto, subtotal_linea, total_linea)
        VALUES
            (p_factura, p_pp, 10, p_costo, 0, 0, 0,
             10 * p_costo, 10 * p_costo);
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            v_ultimo_error := SUBSTR(SQLERRM, 1, 300);
            RETURN SQLCODE;
    END linea_compra;

    FUNCTION anular_compra(
        p_factura IN NUMBER
    ) RETURN NUMBER
    IS
    BEGIN
        v_ultimo_error := NULL;
        UPDATE CP_FACTURA_COMPRA
        SET id_estado_factura_compra = v_fc_anulada
        WHERE id_factura_compra = p_factura;
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            v_ultimo_error := SUBSTR(SQLERRM, 1, 300);
            RETURN SQLCODE;
    END anular_compra;

BEGIN

    SELECT NVL(MAX(id_bitacora_error), 0) INTO v_antes FROM CP_BITACORA_ERROR;
    SELECT NVL(MAX(id_bitacora_costo_producto), 0) INTO v_base FROM CP_BITACORA_COSTO_PRODUCTO;

    SELECT p.id_producto_proveedor, p.id_proveedor
    INTO v_id_pp, v_id_proveedor
    FROM CP_PRODUCTO_PROVEEDOR p
    ORDER BY p.id_producto_proveedor
    FETCH FIRST 1 ROW ONLY;

    BEGIN
        SELECT p.id_producto_proveedor
        INTO v_id_pp2
        FROM CP_PRODUCTO_PROVEEDOR p
        WHERE p.id_producto_proveedor <> v_id_pp
        ORDER BY p.id_producto_proveedor
        FETCH FIRST 1 ROW ONLY;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_id_pp2 := NULL;
    END;

    SELECT MIN(id_negocio) INTO v_id_negocio FROM CP_NEGOCIO;
    SELECT MIN(id_almacen) INTO v_id_almacen FROM CP_ALMACEN;
    SELECT MIN(id_usuario), MAX(id_usuario) INTO v_u1, v_u2 FROM CP_USUARIO;

    SELECT id_estado_factura_compra INTO v_fc_registrada
    FROM CP_ESTADO_FACTURA_COMPRA WHERE nombre_estado_factura = 'REGISTRADA';

    SELECT id_estado_factura_compra INTO v_fc_anulada
    FROM CP_ESTADO_FACTURA_COMPRA WHERE nombre_estado_factura = 'ANULADA';

    v_c0 := costo_de(v_id_pp);
    v_c1 := v_c0 + 50;
    v_c2 := v_c0 + 75;
    v_c3 := v_c0 + 20;
    v_c4 := v_c0 + 30;
    v_c5 := v_c0 + 5;
    v_c6 := v_c0 + 90;

    IF v_id_pp2 IS NOT NULL THEN
        v_otro_inicial := costo_de(v_id_pp2);
    END IF;

    -- Las pruebas parten de un contexto sin usuario, como una sesion nueva
    PKG_CP_CONTEXTO.g_id_usuario := NULL;

    -- Factura F1: costo igual y costo distinto
    v_codigo := nueva_factura_compra('TEST-COSTO-1', SYSDATE);
    v_f1 := v_ultima;

    v_codigo := linea_compra(v_f1, v_id_pp, v_c0);

    reportar('1. Una linea con el costo actual no cambia el costo ni escribe bitacora',
             v_codigo = 0 AND costo_de(v_id_pp) = v_c0 AND cambios_bitacora = 0);

    v_codigo := linea_compra(v_f1, v_id_pp, v_c1);

    reportar('2. Una linea con costo distinto actualiza el costo actual',
             v_codigo = 0 AND costo_de(v_id_pp) = v_c1);

    reportar('3. El cambio queda en la bitacora con costo anterior y nuevo',
             cambio_registrado(v_c0, v_c1, NULL) = 1 AND cambios_bitacora = 1);

    reportar('4. Sin usuario en el contexto, la bitacora guarda el de la factura',
             cambio_registrado(v_c0, v_c1, v_u1) = 1);

    reportar('5. El contexto de usuario queda como estaba despues del trigger',
             PKG_CP_CONTEXTO.g_id_usuario IS NULL);

    PKG_CP_CONTEXTO.g_id_usuario := v_u2;
    v_codigo := linea_compra(v_f1, v_id_pp, v_c2);
    v_cuenta := cambio_registrado(v_c1, v_c2, v_u2);
    PKG_CP_CONTEXTO.g_id_usuario := NULL;

    reportar('6. Con usuario en el contexto, la bitacora guarda ese usuario',
             v_codigo = 0 AND v_cuenta = 1 AND costo_de(v_id_pp) = v_c2);

    -- Factura F2: dos lineas del mismo producto
    v_codigo := nueva_factura_compra('TEST-COSTO-2', SYSDATE);
    v_f2 := v_ultima;

    v_cuenta := cambios_bitacora;
    v_codigo := linea_compra(v_f2, v_id_pp, v_c3);
    v_codigo := v_codigo + linea_compra(v_f2, v_id_pp, v_c4);

    reportar('7. Dos lineas del mismo producto: gana la ultima y se registran los dos cambios',
             v_codigo = 0 AND costo_de(v_id_pp) = v_c4
             AND cambios_bitacora = v_cuenta + 2
             AND cambio_registrado(v_c2, v_c3, NULL) = 1
             AND cambio_registrado(v_c3, v_c4, NULL) = 1);

    -- Factura F3: fecha anterior registrada despues
    v_codigo := nueva_factura_compra('TEST-COSTO-3', SYSDATE - 10);
    v_f3 := v_ultima;
    v_codigo := linea_compra(v_f3, v_id_pp, v_c5);

    reportar('8. Una factura con fecha anterior registrada despues deja su costo (gana la ultima registrada)',
             v_codigo = 0 AND costo_de(v_id_pp) = v_c5
             AND cambio_registrado(v_c4, v_c5, NULL) = 1);

    -- Factura F4: anulada
    v_codigo := nueva_factura_compra('TEST-COSTO-4', SYSDATE);
    v_f4 := v_ultima;
    v_codigo := anular_compra(v_f4);
    v_cuenta := cambios_bitacora;
    v_codigo := v_codigo + linea_compra(v_f4, v_id_pp, v_c6);

    reportar('9. Una linea en una factura anulada no cambia el costo',
             v_codigo = 0 AND costo_de(v_id_pp) = v_c5 AND cambios_bitacora = v_cuenta);

    v_cuenta := cambios_bitacora;
    v_codigo := anular_compra(v_f1);

    reportar('10. Anular una factura no revierte el costo ni escribe bitacora',
             v_codigo = 0 AND costo_de(v_id_pp) = v_c5 AND cambios_bitacora = v_cuenta);

    IF v_id_pp2 IS NULL THEN
        reportar('11. Otro producto-proveedor no se ve afectado (omitida: solo hay uno)', TRUE);
    ELSE
        reportar('11. Otro producto-proveedor no se ve afectado',
                 costo_de(v_id_pp2) = v_otro_inicial);
    END IF;

    ROLLBACK;

    reportar('12. Al deshacer la transaccion el costo vuelve al original',
             costo_de(v_id_pp) = v_c0);

    SELECT COUNT(*)
    INTO v_errores
    FROM CP_BITACORA_ERROR
    WHERE id_bitacora_error > v_antes
      AND modulo = 'COSTO';

    reportar('13. Las pruebas no dejaron errores del modulo COSTO en la bitacora',
             v_errores = 0);

    DELETE FROM CP_BITACORA_ERROR
    WHERE id_bitacora_error > v_antes
      AND modulo = 'COSTO';

    COMMIT;

END;
/
