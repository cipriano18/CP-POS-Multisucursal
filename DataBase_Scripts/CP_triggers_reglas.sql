-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- BASE DE DATOS: Oracle 21c
-- SCRIPT: 07_triggers_reglas.sql
-- DESCRIPCION: Reglas de negocio y bitacoras del sistema
-- USUARIO: CP_POS
-- ============================================================


-- ============================================================
-- PAQUETE PARA IDENTIFICAR AL USUARIO DEL SISTEMA
-- ============================================================

CREATE OR REPLACE PACKAGE PKG_CP_CONTEXTO AS

    g_id_usuario NUMBER;

    PROCEDURE establecer_usuario(
        p_id_usuario NUMBER
    );

    PROCEDURE limpiar_usuario;

END PKG_CP_CONTEXTO;
/

CREATE OR REPLACE PACKAGE BODY PKG_CP_CONTEXTO AS

    PROCEDURE establecer_usuario(
        p_id_usuario NUMBER
    )
    IS
        v_cantidad NUMBER;
    BEGIN

        SELECT COUNT(*)
        INTO v_cantidad
        FROM CP_USUARIO
        WHERE id_usuario = p_id_usuario;

        IF v_cantidad = 0 THEN
            RAISE_APPLICATION_ERROR(
                -20020,
                'El usuario indicado no existe.'
            );
        END IF;

        g_id_usuario := p_id_usuario;

    END establecer_usuario;


    PROCEDURE limpiar_usuario
    IS
    BEGIN
        g_id_usuario := NULL;
    END limpiar_usuario;

END PKG_CP_CONTEXTO;
/


-- ============================================================
-- REGLA 1
-- TABLA 36. CP_NEGOCIO
-- Solo puede existir un tipo de negocio por instancia
-- ============================================================

CREATE OR REPLACE TRIGGER TRG_CP_NEGOCIO_TIPO_INSTANCIA
AFTER INSERT OR UPDATE OF id_tipo_negocio
ON CP_NEGOCIO
DECLARE
    v_cantidad NUMBER;
BEGIN

    SELECT COUNT(DISTINCT id_tipo_negocio)
    INTO v_cantidad
    FROM CP_NEGOCIO;

    IF v_cantidad > 1 THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'Solo puede existir un tipo de negocio por instancia.'
        );
    END IF;

END;
/


-- ============================================================
-- REGLA 2
-- TABLA 47. CP_ALMACEN
-- Solo puede existir un almacen CENTRAL
-- ============================================================

CREATE OR REPLACE TRIGGER TRG_CP_ALMACEN_CENTRAL_UNICO
AFTER INSERT OR UPDATE OF id_tipo_almacen
ON CP_ALMACEN
DECLARE
    v_cantidad NUMBER;
BEGIN

    SELECT COUNT(*)
    INTO v_cantidad
    FROM CP_ALMACEN A
    JOIN CP_TIPO_ALMACEN TA
      ON TA.id_tipo_almacen = A.id_tipo_almacen
    WHERE UPPER(TRIM(TA.nombre_tipo_almacen)) = 'CENTRAL';

    IF v_cantidad > 1 THEN
        RAISE_APPLICATION_ERROR(
            -20002,
            'Solo puede existir un almacen central.'
        );
    END IF;

END;
/


-- ============================================================
-- REGLA 3
-- TABLA 29. CP_CLIENTE
-- Solo puede existir un cliente por defecto
-- ============================================================

CREATE OR REPLACE TRIGGER TRG_CP_CLIENTE_DEFECTO_UNICO
AFTER INSERT OR UPDATE OF es_cliente_defecto
ON CP_CLIENTE
DECLARE
    v_cantidad NUMBER;
BEGIN

    SELECT COUNT(*)
    INTO v_cantidad
    FROM CP_CLIENTE
    WHERE es_cliente_defecto = 'S';

    IF v_cantidad > 1 THEN
        RAISE_APPLICATION_ERROR(
            -20003,
            'Solo puede existir un cliente por defecto.'
        );
    END IF;

END;
/


-- ============================================================
-- REGLA 4A
-- TABLA 30. CP_CLIENTE_PERSONA
-- Un cliente no puede ser persona y empresa al mismo tiempo
-- ============================================================

CREATE OR REPLACE TRIGGER TRG_CP_CLI_PERSONA_EXCLUSIVO
BEFORE INSERT OR UPDATE OF id_cliente
ON CP_CLIENTE_PERSONA
FOR EACH ROW
DECLARE
    v_cantidad NUMBER;
BEGIN

    SELECT COUNT(*)
    INTO v_cantidad
    FROM CP_CLIENTE_EMPRESA
    WHERE id_cliente = :NEW.id_cliente;

    IF v_cantidad > 0 THEN
        RAISE_APPLICATION_ERROR(
            -20004,
            'El cliente ya se encuentra registrado como empresa.'
        );
    END IF;

END;
/


-- ============================================================
-- REGLA 4B
-- TABLA 31. CP_CLIENTE_EMPRESA
-- Un cliente no puede ser empresa y persona al mismo tiempo
-- ============================================================

CREATE OR REPLACE TRIGGER TRG_CP_CLI_EMPRESA_EXCLUSIVO
BEFORE INSERT OR UPDATE OF id_cliente
ON CP_CLIENTE_EMPRESA
FOR EACH ROW
DECLARE
    v_cantidad NUMBER;
BEGIN

    SELECT COUNT(*)
    INTO v_cantidad
    FROM CP_CLIENTE_PERSONA
    WHERE id_cliente = :NEW.id_cliente;

    IF v_cantidad > 0 THEN
        RAISE_APPLICATION_ERROR(
            -20005,
            'El cliente ya se encuentra registrado como persona.'
        );
    END IF;

END;
/


-- ============================================================
-- REGLA 5
-- TABLA 50. CP_TRASLADO
-- El almacen de origen y destino deben ser diferentes
-- ============================================================

CREATE OR REPLACE TRIGGER TRG_CP_TRASLADO_ALMACENES
BEFORE INSERT OR UPDATE OF
    id_almacen_origen,
    id_almacen_destino
ON CP_TRASLADO
FOR EACH ROW
BEGIN

    IF :NEW.id_almacen_origen = :NEW.id_almacen_destino THEN

        RAISE_APPLICATION_ERROR(
            -20006,
            'El almacen de origen y destino deben ser diferentes.'
        );

    END IF;

END;
/


-- ============================================================
-- REGLA 6
-- TABLA 51. CP_DETALLE_TRASLADO
-- No trasladar mas cantidad de la disponible
-- ============================================================

CREATE OR REPLACE TRIGGER TRG_CP_TRASLADO_STOCK
BEFORE INSERT OR UPDATE OF
    cantidad,
    id_lote_producto,
    id_traslado
ON CP_DETALLE_TRASLADO
FOR EACH ROW
DECLARE
    v_almacen_origen NUMBER;
    v_stock          NUMBER(12,2);
BEGIN

    SELECT id_almacen_origen
    INTO v_almacen_origen
    FROM CP_TRASLADO
    WHERE id_traslado = :NEW.id_traslado;

    SELECT cantidad_actual
    INTO v_stock
    FROM CP_INVENTARIO_ALMACEN
    WHERE id_almacen = v_almacen_origen
      AND id_lote_producto = :NEW.id_lote_producto
    FOR UPDATE;

    IF :NEW.cantidad > v_stock THEN

        RAISE_APPLICATION_ERROR(
            -20007,
            'No existe suficiente inventario para realizar el traslado.'
        );

    END IF;

EXCEPTION

    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(
            -20008,
            'El lote no posee inventario en el almacen de origen.'
        );

END;
/


-- ============================================================
-- REGLA 7
-- TABLA 48. CP_INVENTARIO_ALMACEN
-- El inventario nunca puede quedar negativo
-- ============================================================

CREATE OR REPLACE TRIGGER TRG_CP_INVENTARIO_NO_NEGATIVO
BEFORE INSERT OR UPDATE OF cantidad_actual
ON CP_INVENTARIO_ALMACEN
FOR EACH ROW
BEGIN

    IF :NEW.cantidad_actual < 0 THEN

        RAISE_APPLICATION_ERROR(
            -20009,
            'La cantidad actual del inventario no puede ser negativa.'
        );

    END IF;

END;
/


-- ============================================================
-- REGLA 8
-- TABLA 57. CP_ABONO_CUENTA_PAGAR
-- Los abonos acumulados no pueden superar la factura
-- ============================================================

CREATE OR REPLACE TRIGGER TRG_CP_ABONO_PAGAR_LIMITE
AFTER INSERT OR UPDATE OF monto_abono, id_cuenta_pagar
ON CP_ABONO_CUENTA_PAGAR
DECLARE
    v_cantidad NUMBER;
BEGIN

    SELECT COUNT(*)
    INTO v_cantidad
    FROM (
        SELECT
            CP.id_cuenta_pagar
        FROM CP_CUENTA_PAGAR CP
        JOIN CP_FACTURA_COMPRA FC
          ON FC.id_factura_compra = CP.id_factura_compra
        LEFT JOIN CP_ABONO_CUENTA_PAGAR A
          ON A.id_cuenta_pagar = CP.id_cuenta_pagar
        GROUP BY
            CP.id_cuenta_pagar,
            FC.total
        HAVING NVL(SUM(A.monto_abono), 0) > FC.total
    );

    IF v_cantidad > 0 THEN

        RAISE_APPLICATION_ERROR(
            -20010,
            'Los abonos no pueden superar el total de la cuenta por pagar.'
        );

    END IF;

END;
/


-- ============================================================
-- REGLA 9
-- TABLA 70. CP_ABONO_CUENTA_COBRAR
-- Los abonos acumulados no pueden superar la factura
-- ============================================================

CREATE OR REPLACE TRIGGER TRG_CP_ABONO_COBRAR_LIMITE
AFTER INSERT OR UPDATE OF monto_abono, id_cuenta_cobrar
ON CP_ABONO_CUENTA_COBRAR
DECLARE
    v_cantidad NUMBER;
BEGIN

    SELECT COUNT(*)
    INTO v_cantidad
    FROM (
        SELECT
            CC.id_cuenta_cobrar
        FROM CP_CUENTA_COBRAR CC
        JOIN CP_FACTURA_VENTA FV
          ON FV.id_factura_venta = CC.id_factura_venta
        LEFT JOIN CP_ABONO_CUENTA_COBRAR A
          ON A.id_cuenta_cobrar = CC.id_cuenta_cobrar
        GROUP BY
            CC.id_cuenta_cobrar,
            FV.total
        HAVING NVL(SUM(A.monto_abono), 0) > FV.total
    );

    IF v_cantidad > 0 THEN

        RAISE_APPLICATION_ERROR(
            -20011,
            'Los abonos no pueden superar el total de la cuenta por cobrar.'
        );

    END IF;

END;
/


-- ============================================================
-- REGLA 10
-- TABLA 87. CP_DETALLE_DEVOLUCION_VENTA
-- No devolver mas cantidad de la originalmente vendida
-- ============================================================

CREATE OR REPLACE TRIGGER TRG_CP_DEV_VENTA_CANTIDAD
AFTER INSERT OR UPDATE OF
    cantidad_devuelta,
    id_detalle_venta_lote
ON CP_DETALLE_DEVOLUCION_VENTA
DECLARE
    v_cantidad NUMBER;
BEGIN

    SELECT COUNT(*)
    INTO v_cantidad
    FROM (
        SELECT
            D.id_detalle_venta_lote
        FROM CP_DETALLE_DEVOLUCION_VENTA D
        JOIN CP_DETALLE_VENTA_LOTE V
          ON V.id_detalle_venta_lote =
             D.id_detalle_venta_lote
        GROUP BY
            D.id_detalle_venta_lote,
            V.cantidad
        HAVING SUM(D.cantidad_devuelta) > V.cantidad
    );

    IF v_cantidad > 0 THEN

        RAISE_APPLICATION_ERROR(
            -20012,
            'La cantidad devuelta no puede superar la cantidad vendida.'
        );

    END IF;

END;
/


-- ============================================================
-- REGLA 11
-- TABLA 90. CP_DETALLE_DEVOLUCION_COMPRA
-- No devolver mas cantidad de la recibida
-- ============================================================

CREATE OR REPLACE TRIGGER TRG_CP_DEV_COMPRA_CANTIDAD
AFTER INSERT OR UPDATE OF
    cantidad,
    id_lote_producto
ON CP_DETALLE_DEVOLUCION_COMPRA
DECLARE
    v_cantidad NUMBER;
BEGIN

    SELECT COUNT(*)
    INTO v_cantidad
    FROM (
        SELECT
            D.id_lote_producto
        FROM CP_DETALLE_DEVOLUCION_COMPRA D
        JOIN CP_LOTE_PRODUCTO L
          ON L.id_lote_producto = D.id_lote_producto
        GROUP BY
            D.id_lote_producto,
            L.cantidad_recibida
        HAVING SUM(D.cantidad) > L.cantidad_recibida
    );

    IF v_cantidad > 0 THEN

        RAISE_APPLICATION_ERROR(
            -20013,
            'La cantidad devuelta no puede superar la cantidad recibida.'
        );

    END IF;

END;
/


-- ============================================================
-- REGLA 12
-- TABLA 44. CP_PRODUCTO_NEGOCIO
-- Registrar cambios del precio de venta
-- ============================================================

CREATE OR REPLACE TRIGGER TRG_CP_PRODUCTO_NEGOCIO_PRECIO
AFTER UPDATE OF precio_venta_actual
ON CP_PRODUCTO_NEGOCIO
FOR EACH ROW
DECLARE
    v_id_tipo_operacion NUMBER;
BEGIN

    IF NVL(:OLD.precio_venta_actual, -1) <>
       NVL(:NEW.precio_venta_actual, -1)
    THEN

        IF PKG_CP_CONTEXTO.g_id_usuario IS NULL THEN
            RAISE_APPLICATION_ERROR(
                -20014,
                'Debe establecerse el usuario antes de modificar el precio.'
            );
        END IF;

        SELECT id_tipo_operacion
        INTO v_id_tipo_operacion
        FROM CP_TIPO_OPERACION
        WHERE UPPER(TRIM(nombre_tipo_operacion)) = 'MODIFICACION';

        INSERT INTO CP_BITACORA_PRECIO (
            id_producto_negocio,
            id_usuario,
            id_tipo_operacion,
            precio_anterior,
            precio_nuevo,
            fecha_cambio,
            motivo_cambio
        )
        VALUES (
            :NEW.id_producto_negocio,
            PKG_CP_CONTEXTO.g_id_usuario,
            v_id_tipo_operacion,
            :OLD.precio_venta_actual,
            :NEW.precio_venta_actual,
            SYSTIMESTAMP,
            'Cambio de precio de venta'
        );

    END IF;

END;
/


-- ============================================================
-- REGLA 13
-- TABLA 48. CP_INVENTARIO_ALMACEN
-- Registrar cambios de inventario
-- ============================================================

CREATE OR REPLACE TRIGGER TRG_CP_BITACORA_INVENTARIO
AFTER UPDATE OF cantidad_actual
ON CP_INVENTARIO_ALMACEN
FOR EACH ROW
DECLARE
    v_id_tipo_operacion NUMBER;
BEGIN

    IF NVL(:OLD.cantidad_actual, -1) <>
       NVL(:NEW.cantidad_actual, -1)
    THEN

        IF PKG_CP_CONTEXTO.g_id_usuario IS NULL THEN
            RAISE_APPLICATION_ERROR(
                -20015,
                'Debe establecerse el usuario antes de modificar inventario.'
            );
        END IF;

        SELECT id_tipo_operacion
        INTO v_id_tipo_operacion
        FROM CP_TIPO_OPERACION
        WHERE UPPER(TRIM(nombre_tipo_operacion)) = 'MODIFICACION';

        INSERT INTO CP_BITACORA_INVENTARIO (
            id_almacen,
            id_lote_producto,
            id_usuario,
            id_tipo_operacion,
            cantidad_anterior,
            cantidad_nueva,
            fecha_operacion,
            tabla_referencia,
            id_referencia,
            motivo
        )
        VALUES (
            :NEW.id_almacen,
            :NEW.id_lote_producto,
            PKG_CP_CONTEXTO.g_id_usuario,
            v_id_tipo_operacion,
            :OLD.cantidad_actual,
            :NEW.cantidad_actual,
            SYSTIMESTAMP,
            'CP_INVENTARIO_ALMACEN',
            :NEW.id_inventario_almacen,
            'Cambio de cantidad en inventario'
        );

    END IF;

END;
/


-- ============================================================
-- REGLA 14
-- TABLA 50. CP_TRASLADO
-- Registrar cambios de estado del traslado
-- ============================================================

CREATE OR REPLACE TRIGGER TRG_CP_BITACORA_TRASLADO
AFTER UPDATE OF id_estado_traslado
ON CP_TRASLADO
FOR EACH ROW
DECLARE
    v_id_tipo_operacion NUMBER;
    v_id_usuario        NUMBER;
BEGIN

    IF NVL(:OLD.id_estado_traslado, -1) <>
       NVL(:NEW.id_estado_traslado, -1)
    THEN

        SELECT id_tipo_operacion
        INTO v_id_tipo_operacion
        FROM CP_TIPO_OPERACION
        WHERE UPPER(TRIM(nombre_tipo_operacion)) = 'MODIFICACION';

        v_id_usuario :=
            NVL(
                :NEW.id_usuario_recibe,
                :NEW.id_usuario_solicita
            );

        INSERT INTO CP_BITACORA_TRASLADO (
            id_traslado,
            id_usuario,
            id_tipo_operacion,
            id_estado_anterior,
            id_estado_nuevo,
            fecha_cambio,
            observacion
        )
        VALUES (
            :NEW.id_traslado,
            v_id_usuario,
            v_id_tipo_operacion,
            :OLD.id_estado_traslado,
            :NEW.id_estado_traslado,
            SYSTIMESTAMP,
            'Cambio de estado del traslado'
        );

    END IF;

END;
/


-- ============================================================
-- REGLA 15
-- TABLA 59. CP_FACTURA_VENTA
-- Registrar cambios importantes realizados en una venta
-- ============================================================

CREATE OR REPLACE TRIGGER TRG_CP_BITACORA_VENTA
AFTER UPDATE OF
    id_estado_factura_venta,
    total
ON CP_FACTURA_VENTA
FOR EACH ROW
DECLARE
    v_id_tipo_operacion NUMBER;
BEGIN

    IF NVL(:OLD.id_estado_factura_venta, -1) <>
       NVL(:NEW.id_estado_factura_venta, -1)
       OR
       NVL(:OLD.total, -1) <>
       NVL(:NEW.total, -1)
    THEN

        SELECT id_tipo_operacion
        INTO v_id_tipo_operacion
        FROM CP_TIPO_OPERACION
        WHERE UPPER(TRIM(nombre_tipo_operacion)) = 'MODIFICACION';

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
            :NEW.id_usuario,
            v_id_tipo_operacion,
            :OLD.id_estado_factura_venta,
            :NEW.id_estado_factura_venta,
            :OLD.total,
            :NEW.total,
            SYSTIMESTAMP,
            'Modificacion de factura de venta'
        );

    END IF;

END;
/


-- ============================================================
-- REGLA 16
-- TABLA 67. CP_CREDITO_CLIENTE
-- Registrar cambios del limite de credito del cliente
-- ============================================================

CREATE OR REPLACE TRIGGER TRG_CP_BIT_CREDITO_CLIENTE
AFTER UPDATE OF limite_credito
ON CP_CREDITO_CLIENTE
FOR EACH ROW
DECLARE
    v_id_tipo_operacion NUMBER;
BEGIN

    IF NVL(:OLD.limite_credito, -1) <>
       NVL(:NEW.limite_credito, -1)
    THEN

        IF PKG_CP_CONTEXTO.g_id_usuario IS NULL THEN
            RAISE_APPLICATION_ERROR(
                -20016,
                'Debe establecerse el usuario antes de modificar el credito.'
            );
        END IF;

        SELECT id_tipo_operacion
        INTO v_id_tipo_operacion
        FROM CP_TIPO_OPERACION
        WHERE UPPER(TRIM(nombre_tipo_operacion)) = 'MODIFICACION';

        INSERT INTO CP_BITACORA_CREDITO_CLIENTE (
            id_credito_cliente,
            id_usuario,
            id_tipo_operacion,
            limite_anterior,
            limite_nuevo,
            fecha_operacion,
            motivo
        )
        VALUES (
            :NEW.id_credito_cliente,
            PKG_CP_CONTEXTO.g_id_usuario,
            v_id_tipo_operacion,
            :OLD.limite_credito,
            :NEW.limite_credito,
            SYSTIMESTAMP,
            'Cambio en el limite de credito del cliente'
        );

    END IF;

END;
/


-- ============================================================
-- REGLA 17
-- TABLA 38. CP_CREDITO_PROVEEDOR
-- Registrar cambios del limite de credito del proveedor
-- ============================================================

CREATE OR REPLACE TRIGGER TRG_CP_BIT_CREDITO_PROVEEDOR
AFTER UPDATE OF limite_credito
ON CP_CREDITO_PROVEEDOR
FOR EACH ROW
DECLARE
    v_id_tipo_operacion NUMBER;
BEGIN

    IF NVL(:OLD.limite_credito, -1) <>
       NVL(:NEW.limite_credito, -1)
    THEN

        IF PKG_CP_CONTEXTO.g_id_usuario IS NULL THEN
            RAISE_APPLICATION_ERROR(
                -20017,
                'Debe establecerse el usuario antes de modificar el credito.'
            );
        END IF;

        SELECT id_tipo_operacion
        INTO v_id_tipo_operacion
        FROM CP_TIPO_OPERACION
        WHERE UPPER(TRIM(nombre_tipo_operacion)) = 'MODIFICACION';

        INSERT INTO CP_BITACORA_CREDITO_PROVEEDOR (
            id_credito_proveedor,
            id_usuario,
            id_tipo_operacion,
            limite_anterior,
            limite_nuevo,
            fecha_operacion,
            motivo
        )
        VALUES (
            :NEW.id_credito_proveedor,
            PKG_CP_CONTEXTO.g_id_usuario,
            v_id_tipo_operacion,
            :OLD.limite_credito,
            :NEW.limite_credito,
            SYSTIMESTAMP,
            'Cambio en el limite de credito del proveedor'
        );

    END IF;

END;
/


-- ============================================================
-- REGLA 18
-- TABLA 86. CP_DEVOLUCION_VENTA
-- Registrar cambios de estado de devolucion de venta
-- ============================================================

CREATE OR REPLACE TRIGGER TRG_CP_BIT_DEVOLUCION_VENTA
AFTER UPDATE OF id_estado_devolucion
ON CP_DEVOLUCION_VENTA
FOR EACH ROW
DECLARE
    v_id_tipo_operacion NUMBER;
BEGIN

    IF NVL(:OLD.id_estado_devolucion, -1) <>
       NVL(:NEW.id_estado_devolucion, -1)
    THEN

        SELECT id_tipo_operacion
        INTO v_id_tipo_operacion
        FROM CP_TIPO_OPERACION
        WHERE UPPER(TRIM(nombre_tipo_operacion)) = 'MODIFICACION';

        INSERT INTO CP_BITACORA_DEVOLUCION_VENTA (
            id_devolucion_venta,
            id_usuario,
            id_tipo_operacion,
            id_estado_anterior,
            id_estado_nuevo,
            fecha_operacion,
            motivo
        )
        VALUES (
            :NEW.id_devolucion_venta,
            :NEW.id_usuario,
            v_id_tipo_operacion,
            :OLD.id_estado_devolucion,
            :NEW.id_estado_devolucion,
            SYSTIMESTAMP,
            'Cambio de estado de devolucion de venta'
        );

    END IF;

END;
/


-- ============================================================
-- REGLA 19
-- TABLA 89. CP_DEVOLUCION_COMPRA
-- Registrar cambios de estado de devolucion de compra
-- ============================================================

CREATE OR REPLACE TRIGGER TRG_CP_BIT_DEVOLUCION_COMPRA
AFTER UPDATE OF id_estado_devolucion
ON CP_DEVOLUCION_COMPRA
FOR EACH ROW
DECLARE
    v_id_tipo_operacion NUMBER;
BEGIN

    IF NVL(:OLD.id_estado_devolucion, -1) <>
       NVL(:NEW.id_estado_devolucion, -1)
    THEN

        SELECT id_tipo_operacion
        INTO v_id_tipo_operacion
        FROM CP_TIPO_OPERACION
        WHERE UPPER(TRIM(nombre_tipo_operacion)) = 'MODIFICACION';

        INSERT INTO CP_BITACORA_DEVOLUCION_COMPRA (
            id_devolucion_compra,
            id_usuario,
            id_tipo_operacion,
            id_estado_anterior,
            id_estado_nuevo,
            fecha_operacion,
            motivo
        )
        VALUES (
            :NEW.id_devolucion_compra,
            :NEW.id_usuario,
            v_id_tipo_operacion,
            :OLD.id_estado_devolucion,
            :NEW.id_estado_devolucion,
            SYSTIMESTAMP,
            'Cambio de estado de devolucion de compra'
        );

    END IF;

END;
/