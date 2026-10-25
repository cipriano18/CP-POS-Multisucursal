-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- BASE DE DATOS: Oracle 21c
-- SCRIPT: 25_facturacion_transacciones.sql
-- DESCRIPCION: API transaccional de facturacion. Paquete
--              PKG_CP_FACTURACION con las operaciones completas de
--              venta, compra, anulacion, abono y devolucion. Cada
--              operacion es una unidad de trabajo: abre un SAVEPOINT,
--              hace todos sus cambios (los triggers descuentan el
--              inventario, crean las cuentas y registran el costo) y,
--              si algo falla, deshace solo lo suyo con ROLLBACK TO
--              SAVEPOINT. Si todo sale bien confirma con COMMIT, salvo
--              que quien llama pida p_commit => FALSE para agrupar
--              varias operaciones en una sola transaccion.
--              Sobre un documento existente (anular, abonar, devolver)
--              toma un bloqueo FOR UPDATE NOWAIT: si otra sesion lo
--              esta usando falla de inmediato con -20291.
--
-- EJECUTAR COMO: CP_POS en XEPDB1 (despues de los scripts 18 a 22).
--                Se puede volver a ejecutar completo las veces que
--                haga falta.
--
-- NOTA SOBRE LAS TRANSACCIONES
--   La logica que ejecutan los triggers (descontar inventario, crear
--   cuentas, registrar costos) NO puede llevar COMMIT, ROLLBACK ni
--   SAVEPOINT: Oracle lo prohibe dentro de un trigger (ORA-04092).
--   Por eso el control de la transaccion vive aqui, en el paquete
--   que invoca la operacion.
--
-- NOTA SOBRE EL MODELO
--   Este script no cambia el modelo. El diagrama y el diccionario de
--   datos deben actualizarse con los cambios de los scripts 11 a 22
--   (ver ORDEN_EJECUCION.md).
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED

-- ============================================================
-- 1. PAQUETE PKG_CP_FACTURACION (ESPECIFICACION)
-- ============================================================
-- AUTHID CURRENT_USER: el paquete se ejecuta con los privilegios de
-- quien lo llama. Un usuario solo puede hacer a traves de la API lo
-- que su rol le permite hacer con INSERT y UPDATE directos. Por eso
-- todas las tablas se escriben con el prefijo CP_POS.

CREATE OR REPLACE PACKAGE PKG_CP_FACTURACION AUTHID CURRENT_USER AS

    -- Linea de venta: producto, cantidad, precio y porcentajes (0 a 100).
    TYPE t_linea_venta IS RECORD (
        id_producto          NUMBER,
        cantidad             NUMBER,
        precio_unitario      NUMBER,
        porcentaje_descuento NUMBER := 0,
        porcentaje_impuesto  NUMBER := 0
    );

    TYPE t_lineas_venta IS TABLE OF t_linea_venta INDEX BY PLS_INTEGER;

    -- Linea de compra: producto del proveedor, cantidad, costo y el
    -- lote que se recibe (numero y fecha de vencimiento opcional).
    TYPE t_linea_compra IS RECORD (
        id_producto_proveedor NUMBER,
        cantidad              NUMBER,
        precio_costo_unitario NUMBER,
        porcentaje_descuento  NUMBER := 0,
        porcentaje_impuesto   NUMBER := 0,
        numero_lote           VARCHAR2(50),
        fecha_vencimiento     DATE
    );

    TYPE t_lineas_compra IS TABLE OF t_linea_compra INDEX BY PLS_INTEGER;

    -- Linea de devolucion de venta: lote vendido que se devuelve.
    TYPE t_linea_dev_venta IS RECORD (
        id_detalle_venta_lote NUMBER,
        id_motivo_devolucion  NUMBER,
        cantidad              NUMBER
    );

    TYPE t_lineas_dev_venta IS TABLE OF t_linea_dev_venta INDEX BY PLS_INTEGER;

    -- Linea de devolucion de compra: lote recibido que se devuelve.
    TYPE t_linea_dev_compra IS RECORD (
        id_lote_producto     NUMBER,
        id_motivo_devolucion NUMBER,
        cantidad             NUMBER
    );

    TYPE t_lineas_dev_compra IS TABLE OF t_linea_dev_compra INDEX BY PLS_INTEGER;

    -- Registra una venta completa (cabecera y lineas). De contado queda
    -- EMITIDA; a credito queda PENDIENTE y se valida el limite.
    PROCEDURE registrar_venta(
        p_id_cliente     IN  NUMBER,
        p_id_sucursal    IN  NUMBER,
        p_id_usuario     IN  NUMBER,
        p_numero_factura IN  VARCHAR2,
        p_lineas         IN  t_lineas_venta,
        p_id_factura     OUT NUMBER,
        p_a_credito      IN  BOOLEAN DEFAULT FALSE,
        p_commit         IN  BOOLEAN DEFAULT TRUE
    );

    -- Registra una compra completa con el lote que recibe cada linea.
    -- Contado queda REGISTRADA; a credito queda PENDIENTE.
    PROCEDURE registrar_compra(
        p_id_proveedor         IN  NUMBER,
        p_id_negocio           IN  NUMBER,
        p_id_almacen_recepcion IN  NUMBER,
        p_id_usuario           IN  NUMBER,
        p_numero_factura       IN  VARCHAR2,
        p_lineas               IN  t_lineas_compra,
        p_id_factura           OUT NUMBER,
        p_a_credito            IN  BOOLEAN DEFAULT FALSE,
        p_commit               IN  BOOLEAN DEFAULT TRUE
    );

    -- Anula una factura de venta: devuelve el inventario y anula su cuenta.
    PROCEDURE anular_venta(
        p_id_factura IN NUMBER,
        p_commit     IN BOOLEAN DEFAULT TRUE
    );

    -- Anula una factura de compra: retira el inventario y anula su cuenta.
    PROCEDURE anular_compra(
        p_id_factura IN NUMBER,
        p_commit     IN BOOLEAN DEFAULT TRUE
    );

    -- Registra un abono a una cuenta por cobrar.
    PROCEDURE registrar_abono_cobrar(
        p_id_cuenta         IN NUMBER,
        p_id_tipo_pago      IN NUMBER,
        p_id_usuario        IN NUMBER,
        p_monto             IN NUMBER,
        p_numero_referencia IN VARCHAR2 DEFAULT NULL,
        p_commit            IN BOOLEAN  DEFAULT TRUE
    );

    -- Registra un abono a una cuenta por pagar.
    PROCEDURE registrar_abono_pagar(
        p_id_cuenta         IN NUMBER,
        p_id_tipo_pago      IN NUMBER,
        p_id_usuario        IN NUMBER,
        p_monto             IN NUMBER,
        p_numero_referencia IN VARCHAR2 DEFAULT NULL,
        p_commit            IN BOOLEAN  DEFAULT TRUE
    );

    -- Registra y procesa una devolucion de venta (reingresa el
    -- inventario segun el motivo de cada linea).
    PROCEDURE registrar_devolucion_venta(
        p_id_factura    IN  NUMBER,
        p_id_usuario    IN  NUMBER,
        p_lineas        IN  t_lineas_dev_venta,
        p_id_devolucion OUT NUMBER,
        p_commit        IN  BOOLEAN DEFAULT TRUE
    );

    -- Registra y procesa una devolucion de compra (saca los lotes
    -- devueltos del inventario).
    PROCEDURE registrar_devolucion_compra(
        p_id_factura    IN  NUMBER,
        p_id_usuario    IN  NUMBER,
        p_lineas        IN  t_lineas_dev_compra,
        p_id_devolucion OUT NUMBER,
        p_commit        IN  BOOLEAN DEFAULT TRUE
    );

END PKG_CP_FACTURACION;
/

-- ============================================================
-- 2. PAQUETE PKG_CP_FACTURACION (CUERPO)
-- ============================================================

CREATE OR REPLACE PACKAGE BODY PKG_CP_FACTURACION AS

    c_modulo CONSTANT VARCHAR2(20) := 'FACTURACION';

    -- Codigos de error propios de la API.
    c_err_ocupado   CONSTANT PLS_INTEGER := -20291;
    c_err_datos     CONSTANT PLS_INTEGER := -20292;
    c_err_documento CONSTANT PLS_INTEGER := -20293;
    c_err_cantidad  CONSTANT PLS_INTEGER := -20294;

    -- ORA-00054: el registro esta bloqueado y se pidio NOWAIT.
    e_ocupado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_ocupado, -54);

    TYPE t_montos IS RECORD (
        subtotal  NUMBER,
        descuento NUMBER,
        impuesto  NUMBER,
        total     NUMBER
    );

    TYPE t_importes  IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    TYPE t_acumulado IS TABLE OF NUMBER INDEX BY VARCHAR2(40);


    -- Busca el id de un estado por su nombre. Si no existe es un
    -- problema de datos maestros y se informa con -20293.
    FUNCTION id_estado_venta(
        p_nombre IN VARCHAR2
    ) RETURN NUMBER
    IS
        v_id NUMBER;
    BEGIN

        SELECT id_estado_factura_venta
        INTO v_id
        FROM CP_POS.CP_ESTADO_FACTURA_VENTA
        WHERE nombre_estado_factura = p_nombre;

        RETURN v_id;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            CP_POS.PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_documento,
                'No existe el estado de factura de venta ' || p_nombre || '.'
            );
    END id_estado_venta;


    FUNCTION id_estado_compra(
        p_nombre IN VARCHAR2
    ) RETURN NUMBER
    IS
        v_id NUMBER;
    BEGIN

        SELECT id_estado_factura_compra
        INTO v_id
        FROM CP_POS.CP_ESTADO_FACTURA_COMPRA
        WHERE nombre_estado_factura = p_nombre;

        RETURN v_id;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            CP_POS.PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_documento,
                'No existe el estado de factura de compra ' || p_nombre || '.'
            );
    END id_estado_compra;


    FUNCTION id_estado_devolucion(
        p_nombre IN VARCHAR2
    ) RETURN NUMBER
    IS
        v_id NUMBER;
    BEGIN

        SELECT id_estado_devolucion
        INTO v_id
        FROM CP_POS.CP_ESTADO_DEVOLUCION
        WHERE nombre_estado_devolucion = p_nombre;

        RETURN v_id;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            CP_POS.PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_documento,
                'No existe el estado de devolucion ' || p_nombre || '.'
            );
    END id_estado_devolucion;


    -- Bloqueo de la factura de venta con FOR UPDATE NOWAIT. Dos personas
    -- no deben operar el mismo documento a la vez; en lugar de hacer
    -- esperar a la segunda, se le avisa de inmediato (-20291).
    -- Devuelve el estado actual de la factura.
    PROCEDURE bloquear_venta(
        p_id_factura IN  NUMBER,
        p_estado     OUT NUMBER
    )
    IS
    BEGIN

        SELECT id_estado_factura_venta
        INTO p_estado
        FROM CP_POS.CP_FACTURA_VENTA
        WHERE id_factura_venta = p_id_factura
        FOR UPDATE NOWAIT;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            CP_POS.PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_documento,
                'No existe la factura de venta ' || p_id_factura || '.'
            );
        WHEN e_ocupado THEN
            CP_POS.PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_ocupado,
                'La factura de venta ' || p_id_factura
                || ' esta siendo usada por otra sesion. Intente de nuevo.'
            );
    END bloquear_venta;


    -- Igual que bloquear_venta, para facturas de compra.
    PROCEDURE bloquear_compra(
        p_id_factura IN  NUMBER,
        p_estado     OUT NUMBER
    )
    IS
    BEGIN

        SELECT id_estado_factura_compra
        INTO p_estado
        FROM CP_POS.CP_FACTURA_COMPRA
        WHERE id_factura_compra = p_id_factura
        FOR UPDATE NOWAIT;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            CP_POS.PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_documento,
                'No existe la factura de compra ' || p_id_factura || '.'
            );
        WHEN e_ocupado THEN
            CP_POS.PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_ocupado,
                'La factura de compra ' || p_id_factura
                || ' esta siendo usada por otra sesion. Intente de nuevo.'
            );
    END bloquear_compra;


    -- Valida los datos de una linea antes de tocar la base de datos.
    PROCEDURE validar_linea(
        p_posicion IN NUMBER,
        p_cantidad IN NUMBER,
        p_precio   IN NUMBER,
        p_pct_desc IN NUMBER,
        p_pct_imp  IN NUMBER
    )
    IS
    BEGIN

        IF p_cantidad IS NULL OR p_cantidad <= 0 THEN
            CP_POS.PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_datos,
                'Linea ' || p_posicion || ': la cantidad debe ser mayor que cero.'
            );
        END IF;

        IF p_precio IS NULL OR p_precio < 0 THEN
            CP_POS.PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_datos,
                'Linea ' || p_posicion || ': el precio no puede ser negativo.'
            );
        END IF;

        IF NVL(p_pct_desc, 0) NOT BETWEEN 0 AND 100 THEN
            CP_POS.PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_datos,
                'Linea ' || p_posicion || ': el descuento debe estar entre 0 y 100.'
            );
        END IF;

        IF NVL(p_pct_imp, 0) NOT BETWEEN 0 AND 100 THEN
            CP_POS.PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_datos,
                'Linea ' || p_posicion || ': el impuesto debe estar entre 0 y 100.'
            );
        END IF;

    END validar_linea;


    -- Importes de una linea: subtotal, descuento, impuesto (sobre el
    -- monto ya descontado) y total.
    FUNCTION calcular_montos(
        p_cantidad IN NUMBER,
        p_precio   IN NUMBER,
        p_pct_desc IN NUMBER,
        p_pct_imp  IN NUMBER
    ) RETURN t_montos
    IS
        v_montos t_montos;
    BEGIN

        v_montos.subtotal  := ROUND(p_cantidad * p_precio, 2);
        v_montos.descuento := ROUND(v_montos.subtotal * NVL(p_pct_desc, 0) / 100, 2);
        v_montos.impuesto  := ROUND(
            (v_montos.subtotal - v_montos.descuento) * NVL(p_pct_imp, 0) / 100, 2
        );
        v_montos.total     := v_montos.subtotal - v_montos.descuento + v_montos.impuesto;

        RETURN v_montos;

    END calcular_montos;


    -- Venta completa. El SAVEPOINT es lo primero: si cualquier linea
    -- falla (sin stock, limite de credito superado, dato invalido) se
    -- deshace la cabecera y todo lo anterior de esta operacion, sin
    -- tocar lo que la sesion tuviera pendiente antes de llamarla.
    PROCEDURE registrar_venta(
        p_id_cliente     IN  NUMBER,
        p_id_sucursal    IN  NUMBER,
        p_id_usuario     IN  NUMBER,
        p_numero_factura IN  VARCHAR2,
        p_lineas         IN  t_lineas_venta,
        p_id_factura     OUT NUMBER,
        p_a_credito      IN  BOOLEAN DEFAULT FALSE,
        p_commit         IN  BOOLEAN DEFAULT TRUE
    )
    IS
        v_estado NUMBER;
        v_montos t_montos;
        v_subtot NUMBER := 0;
        v_desc   NUMBER := 0;
        v_imp    NUMBER := 0;
        v_total  NUMBER := 0;
        v_i      PLS_INTEGER;
    BEGIN

        SAVEPOINT sp_registrar_venta;

        IF p_numero_factura IS NULL THEN
            CP_POS.PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_datos,
                'La venta necesita un numero de factura.'
            );
        END IF;

        IF p_lineas.COUNT = 0 THEN
            CP_POS.PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_datos,
                'La venta debe tener al menos una linea.'
            );
        END IF;

        -- Primero se valida y se suma todo; la cabecera necesita los
        -- totales finales porque la cuenta por cobrar se crea con ellos.
        v_i := p_lineas.FIRST;

        WHILE v_i IS NOT NULL LOOP

            IF p_lineas(v_i).id_producto IS NULL THEN
                CP_POS.PKG_CP_ERROR.lanzar(
                    c_modulo,
                    c_err_datos,
                    'Linea ' || v_i || ': falta el producto.'
                );
            END IF;

            validar_linea(
                v_i,
                p_lineas(v_i).cantidad,
                p_lineas(v_i).precio_unitario,
                p_lineas(v_i).porcentaje_descuento,
                p_lineas(v_i).porcentaje_impuesto
            );

            v_montos := calcular_montos(
                p_lineas(v_i).cantidad,
                p_lineas(v_i).precio_unitario,
                p_lineas(v_i).porcentaje_descuento,
                p_lineas(v_i).porcentaje_impuesto
            );

            v_subtot := v_subtot + v_montos.subtotal;
            v_desc   := v_desc   + v_montos.descuento;
            v_imp    := v_imp    + v_montos.impuesto;
            v_total  := v_total  + v_montos.total;

            v_i := p_lineas.NEXT(v_i);

        END LOOP;

        IF p_a_credito THEN
            v_estado := id_estado_venta('PENDIENTE');
        ELSE
            v_estado := id_estado_venta('EMITIDA');
        END IF;

        INSERT INTO CP_POS.CP_FACTURA_VENTA
            (id_cliente, id_sucursal, id_usuario, id_estado_factura_venta,
             numero_factura, fecha_emision, subtotal, descuento_total,
             impuesto_total, total)
        VALUES
            (p_id_cliente, p_id_sucursal, p_id_usuario, v_estado,
             p_numero_factura, SYSDATE, v_subtot, v_desc, v_imp, v_total)
        RETURNING id_factura_venta INTO p_id_factura;

        -- Cada INSERT de linea dispara el trigger que descuenta el
        -- inventario por FEFO.
        v_i := p_lineas.FIRST;

        WHILE v_i IS NOT NULL LOOP

            v_montos := calcular_montos(
                p_lineas(v_i).cantidad,
                p_lineas(v_i).precio_unitario,
                p_lineas(v_i).porcentaje_descuento,
                p_lineas(v_i).porcentaje_impuesto
            );

            INSERT INTO CP_POS.CP_DETALLE_VENTA_PRODUCTO
                (id_factura_venta, id_producto, cantidad, precio_unitario,
                 porcentaje_descuento, monto_descuento, porcentaje_impuesto,
                 monto_impuesto, subtotal, total)
            VALUES
                (p_id_factura, p_lineas(v_i).id_producto, p_lineas(v_i).cantidad,
                 p_lineas(v_i).precio_unitario,
                 NVL(p_lineas(v_i).porcentaje_descuento, 0), v_montos.descuento,
                 NVL(p_lineas(v_i).porcentaje_impuesto, 0), v_montos.impuesto,
                 v_montos.subtotal, v_montos.total);

            v_i := p_lineas.NEXT(v_i);

        END LOOP;

        IF p_commit THEN
            COMMIT;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            CP_POS.PKG_CP_ERROR.registrar_inesperado(
                c_modulo, 'registrar_venta ' || p_numero_factura
            );
            ROLLBACK TO SAVEPOINT sp_registrar_venta;
            p_id_factura := NULL;
            RAISE;
    END registrar_venta;


    -- Compra completa. Por cada linea guarda el detalle y el lote
    -- recibido; el trigger del lote suma el inventario y el del detalle
    -- registra el costo. Mismo esquema de SAVEPOINT que la venta.
    PROCEDURE registrar_compra(
        p_id_proveedor         IN  NUMBER,
        p_id_negocio           IN  NUMBER,
        p_id_almacen_recepcion IN  NUMBER,
        p_id_usuario           IN  NUMBER,
        p_numero_factura       IN  VARCHAR2,
        p_lineas               IN  t_lineas_compra,
        p_id_factura           OUT NUMBER,
        p_a_credito            IN  BOOLEAN DEFAULT FALSE,
        p_commit               IN  BOOLEAN DEFAULT TRUE
    )
    IS
        v_estado     NUMBER;
        v_montos     t_montos;
        v_subtot     NUMBER := 0;
        v_desc       NUMBER := 0;
        v_imp        NUMBER := 0;
        v_total      NUMBER := 0;
        v_i          PLS_INTEGER;
        v_id_detalle NUMBER;
    BEGIN

        SAVEPOINT sp_registrar_compra;

        IF p_numero_factura IS NULL THEN
            CP_POS.PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_datos,
                'La compra necesita un numero de factura.'
            );
        END IF;

        IF p_lineas.COUNT = 0 THEN
            CP_POS.PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_datos,
                'La compra debe tener al menos una linea.'
            );
        END IF;

        v_i := p_lineas.FIRST;

        WHILE v_i IS NOT NULL LOOP

            IF p_lineas(v_i).id_producto_proveedor IS NULL
               OR p_lineas(v_i).numero_lote IS NULL THEN
                CP_POS.PKG_CP_ERROR.lanzar(
                    c_modulo,
                    c_err_datos,
                    'Linea ' || v_i || ': faltan el producto del proveedor o el numero de lote.'
                );
            END IF;

            IF p_lineas(v_i).fecha_vencimiento IS NOT NULL
               AND p_lineas(v_i).fecha_vencimiento < TRUNC(SYSDATE) THEN
                CP_POS.PKG_CP_ERROR.lanzar(
                    c_modulo,
                    c_err_datos,
                    'Linea ' || v_i || ': el lote ya esta vencido.'
                );
            END IF;

            validar_linea(
                v_i,
                p_lineas(v_i).cantidad,
                p_lineas(v_i).precio_costo_unitario,
                p_lineas(v_i).porcentaje_descuento,
                p_lineas(v_i).porcentaje_impuesto
            );

            v_montos := calcular_montos(
                p_lineas(v_i).cantidad,
                p_lineas(v_i).precio_costo_unitario,
                p_lineas(v_i).porcentaje_descuento,
                p_lineas(v_i).porcentaje_impuesto
            );

            v_subtot := v_subtot + v_montos.subtotal;
            v_desc   := v_desc   + v_montos.descuento;
            v_imp    := v_imp    + v_montos.impuesto;
            v_total  := v_total  + v_montos.total;

            v_i := p_lineas.NEXT(v_i);

        END LOOP;

        IF p_a_credito THEN
            v_estado := id_estado_compra('PENDIENTE');
        ELSE
            v_estado := id_estado_compra('REGISTRADA');
        END IF;

        INSERT INTO CP_POS.CP_FACTURA_COMPRA
            (id_proveedor, id_negocio, id_almacen_recepcion, id_usuario,
             id_estado_factura_compra, numero_factura, fecha_emision,
             fecha_recepcion, subtotal, descuento_total, impuesto_total, total)
        VALUES
            (p_id_proveedor, p_id_negocio, p_id_almacen_recepcion, p_id_usuario,
             v_estado, p_numero_factura, SYSDATE, SYSDATE,
             v_subtot, v_desc, v_imp, v_total)
        RETURNING id_factura_compra INTO p_id_factura;

        v_i := p_lineas.FIRST;

        WHILE v_i IS NOT NULL LOOP

            v_montos := calcular_montos(
                p_lineas(v_i).cantidad,
                p_lineas(v_i).precio_costo_unitario,
                p_lineas(v_i).porcentaje_descuento,
                p_lineas(v_i).porcentaje_impuesto
            );

            INSERT INTO CP_POS.CP_DETALLE_COMPRA
                (id_factura_compra, id_producto_proveedor, cantidad,
                 precio_costo_unitario, monto_descuento, porcentaje_impuesto,
                 monto_impuesto, subtotal_linea, total_linea)
            VALUES
                (p_id_factura, p_lineas(v_i).id_producto_proveedor,
                 p_lineas(v_i).cantidad, p_lineas(v_i).precio_costo_unitario,
                 v_montos.descuento, NVL(p_lineas(v_i).porcentaje_impuesto, 0),
                 v_montos.impuesto, v_montos.subtotal, v_montos.total)
            RETURNING id_detalle_compra INTO v_id_detalle;

            INSERT INTO CP_POS.CP_LOTE_PRODUCTO
                (id_detalle_compra, numero_lote, cantidad_recibida,
                 fecha_ingreso, fecha_vencimiento)
            VALUES
                (v_id_detalle, p_lineas(v_i).numero_lote, p_lineas(v_i).cantidad,
                 TRUNC(SYSDATE), p_lineas(v_i).fecha_vencimiento);

            v_i := p_lineas.NEXT(v_i);

        END LOOP;

        IF p_commit THEN
            COMMIT;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            CP_POS.PKG_CP_ERROR.registrar_inesperado(
                c_modulo, 'registrar_compra ' || p_numero_factura
            );
            ROLLBACK TO SAVEPOINT sp_registrar_compra;
            p_id_factura := NULL;
            RAISE;
    END registrar_compra;


    -- Anulacion de una venta. Bloquea la factura con NOWAIT y cambia su
    -- estado; los triggers reintegran el inventario y anulan la cuenta
    -- por cobrar (que se niega si ya tiene abonos).
    PROCEDURE anular_venta(
        p_id_factura IN NUMBER,
        p_commit     IN BOOLEAN DEFAULT TRUE
    )
    IS
        v_estado  NUMBER;
        v_anulada NUMBER;
    BEGIN

        SAVEPOINT sp_anular_venta;

        bloquear_venta(p_id_factura, v_estado);
        v_anulada := id_estado_venta('ANULADA');

        IF v_estado = v_anulada THEN
            CP_POS.PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_documento,
                'La factura de venta ' || p_id_factura || ' ya esta anulada.'
            );
        END IF;

        UPDATE CP_POS.CP_FACTURA_VENTA
        SET id_estado_factura_venta = v_anulada
        WHERE id_factura_venta = p_id_factura;

        IF p_commit THEN
            COMMIT;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            CP_POS.PKG_CP_ERROR.registrar_inesperado(
                c_modulo, 'anular_venta ' || p_id_factura
            );
            ROLLBACK TO SAVEPOINT sp_anular_venta;
            RAISE;
    END anular_venta;


    -- Anulacion de una compra. Mismo flujo que anular_venta; los
    -- triggers retiran del inventario lo que aun no se haya devuelto.
    PROCEDURE anular_compra(
        p_id_factura IN NUMBER,
        p_commit     IN BOOLEAN DEFAULT TRUE
    )
    IS
        v_estado  NUMBER;
        v_anulada NUMBER;
    BEGIN

        SAVEPOINT sp_anular_compra;

        bloquear_compra(p_id_factura, v_estado);
        v_anulada := id_estado_compra('ANULADA');

        IF v_estado = v_anulada THEN
            CP_POS.PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_documento,
                'La factura de compra ' || p_id_factura || ' ya esta anulada.'
            );
        END IF;

        UPDATE CP_POS.CP_FACTURA_COMPRA
        SET id_estado_factura_compra = v_anulada
        WHERE id_factura_compra = p_id_factura;

        IF p_commit THEN
            COMMIT;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            CP_POS.PKG_CP_ERROR.registrar_inesperado(
                c_modulo, 'anular_compra ' || p_id_factura
            );
            ROLLBACK TO SAVEPOINT sp_anular_compra;
            RAISE;
    END anular_compra;


    -- Abono a una cuenta por cobrar. Se bloquea con NOWAIT la factura
    -- de la cuenta (dos cajeros no cobran la misma cuenta a la vez) y
    -- se inserta el abono; el trigger descuenta el saldo, actualiza el
    -- estado de la cuenta y cancela la factura al saldarla.
    PROCEDURE registrar_abono_cobrar(
        p_id_cuenta         IN NUMBER,
        p_id_tipo_pago      IN NUMBER,
        p_id_usuario        IN NUMBER,
        p_monto             IN NUMBER,
        p_numero_referencia IN VARCHAR2 DEFAULT NULL,
        p_commit            IN BOOLEAN  DEFAULT TRUE
    )
    IS
        v_id_factura NUMBER;
        v_estado     NUMBER;
    BEGIN

        SAVEPOINT sp_abono_cobrar;

        BEGIN

            SELECT id_factura_venta
            INTO v_id_factura
            FROM CP_POS.CP_CUENTA_COBRAR
            WHERE id_cuenta_cobrar = p_id_cuenta;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                CP_POS.PKG_CP_ERROR.lanzar(
                    c_modulo,
                    c_err_documento,
                    'No existe la cuenta por cobrar ' || p_id_cuenta || '.'
                );
        END;

        bloquear_venta(v_id_factura, v_estado);

        INSERT INTO CP_POS.CP_ABONO_CUENTA_COBRAR
            (id_cuenta_cobrar, id_tipo_pago, id_usuario, monto_abono,
             fecha_abono, numero_referencia)
        VALUES
            (p_id_cuenta, p_id_tipo_pago, p_id_usuario, p_monto,
             SYSTIMESTAMP, p_numero_referencia);

        IF p_commit THEN
            COMMIT;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            CP_POS.PKG_CP_ERROR.registrar_inesperado(
                c_modulo, 'abono a cuenta por cobrar ' || p_id_cuenta
            );
            ROLLBACK TO SAVEPOINT sp_abono_cobrar;
            RAISE;
    END registrar_abono_cobrar;


    -- Abono a una cuenta por pagar. Igual que el de cobrar, sobre la
    -- factura de compra de la cuenta.
    PROCEDURE registrar_abono_pagar(
        p_id_cuenta         IN NUMBER,
        p_id_tipo_pago      IN NUMBER,
        p_id_usuario        IN NUMBER,
        p_monto             IN NUMBER,
        p_numero_referencia IN VARCHAR2 DEFAULT NULL,
        p_commit            IN BOOLEAN  DEFAULT TRUE
    )
    IS
        v_id_factura NUMBER;
        v_estado     NUMBER;
    BEGIN

        SAVEPOINT sp_abono_pagar;

        BEGIN

            SELECT id_factura_compra
            INTO v_id_factura
            FROM CP_POS.CP_CUENTA_PAGAR
            WHERE id_cuenta_pagar = p_id_cuenta;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                CP_POS.PKG_CP_ERROR.lanzar(
                    c_modulo,
                    c_err_documento,
                    'No existe la cuenta por pagar ' || p_id_cuenta || '.'
                );
        END;

        bloquear_compra(v_id_factura, v_estado);

        INSERT INTO CP_POS.CP_ABONO_CUENTA_PAGAR
            (id_cuenta_pagar, id_tipo_pago, id_usuario, monto_abono,
             fecha_abono, numero_referencia)
        VALUES
            (p_id_cuenta, p_id_tipo_pago, p_id_usuario, p_monto,
             SYSTIMESTAMP, p_numero_referencia);

        IF p_commit THEN
            COMMIT;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            CP_POS.PKG_CP_ERROR.registrar_inesperado(
                c_modulo, 'abono a cuenta por pagar ' || p_id_cuenta
            );
            ROLLBACK TO SAVEPOINT sp_abono_pagar;
            RAISE;
    END registrar_abono_pagar;


    -- Devolucion de venta. Valida cada linea contra lo vendido y lo ya
    -- devuelto (-20294 si se excede), guarda la devolucion como
    -- SOLICITADA con su detalle y al final la pasa a PROCESADA: ese
    -- cambio de estado dispara el movimiento de inventario segun el
    -- motivo de cada linea.
    PROCEDURE registrar_devolucion_venta(
        p_id_factura    IN  NUMBER,
        p_id_usuario    IN  NUMBER,
        p_lineas        IN  t_lineas_dev_venta,
        p_id_devolucion OUT NUMBER,
        p_commit        IN  BOOLEAN DEFAULT TRUE
    )
    IS
        v_estado      NUMBER;
        v_i           PLS_INTEGER;
        v_vendido     NUMBER;
        v_previo      NUMBER;
        v_total_linea NUMBER;
        v_cant_linea  NUMBER;
        v_pedido      t_acumulado;
        v_clave       VARCHAR2(40);
        v_importes    t_importes;
        v_total       NUMBER := 0;
        v_solicitada  NUMBER;
        v_procesada   NUMBER;
    BEGIN

        SAVEPOINT sp_devolucion_venta;

        IF p_lineas.COUNT = 0 THEN
            CP_POS.PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_datos,
                'La devolucion debe tener al menos una linea.'
            );
        END IF;

        bloquear_venta(p_id_factura, v_estado);

        IF v_estado = id_estado_venta('ANULADA') THEN
            CP_POS.PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_documento,
                'No se puede devolver sobre una factura anulada.'
            );
        END IF;

        v_i := p_lineas.FIRST;

        WHILE v_i IS NOT NULL LOOP

            IF p_lineas(v_i).id_detalle_venta_lote IS NULL
               OR p_lineas(v_i).id_motivo_devolucion IS NULL
               OR p_lineas(v_i).cantidad IS NULL
               OR p_lineas(v_i).cantidad <= 0 THEN
                CP_POS.PKG_CP_ERROR.lanzar(
                    c_modulo,
                    c_err_datos,
                    'Linea ' || v_i || ': faltan datos o la cantidad no es mayor que cero.'
                );
            END IF;

            BEGIN

                SELECT dvl.cantidad, dvp.total, dvp.cantidad
                INTO v_vendido, v_total_linea, v_cant_linea
                FROM CP_POS.CP_DETALLE_VENTA_LOTE dvl
                JOIN CP_POS.CP_DETALLE_VENTA_PRODUCTO dvp
                  ON dvp.id_detalle_venta_producto = dvl.id_detalle_venta_producto
                WHERE dvl.id_detalle_venta_lote = p_lineas(v_i).id_detalle_venta_lote
                  AND dvp.id_factura_venta = p_id_factura;

            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    CP_POS.PKG_CP_ERROR.lanzar(
                        c_modulo,
                        c_err_datos,
                        'Linea ' || v_i || ': el lote vendido '
                        || p_lineas(v_i).id_detalle_venta_lote
                        || ' no pertenece a la factura ' || p_id_factura || '.'
                    );
            END;

            SELECT NVL(SUM(cantidad_devuelta), 0)
            INTO v_previo
            FROM CP_POS.CP_DETALLE_DEVOLUCION_VENTA
            WHERE id_detalle_venta_lote = p_lineas(v_i).id_detalle_venta_lote;

            -- Si el mismo lote aparece en varias lineas se acumula lo pedido.
            v_clave := TO_CHAR(p_lineas(v_i).id_detalle_venta_lote);

            IF NOT v_pedido.EXISTS(v_clave) THEN
                v_pedido(v_clave) := 0;
            END IF;

            v_pedido(v_clave) := v_pedido(v_clave) + p_lineas(v_i).cantidad;

            IF v_previo + v_pedido(v_clave) > v_vendido THEN
                CP_POS.PKG_CP_ERROR.lanzar(
                    c_modulo,
                    c_err_cantidad,
                    'Linea ' || v_i || ': se vendieron ' || v_vendido
                    || ', ya se devolvieron ' || v_previo
                    || ' y se piden ' || v_pedido(v_clave) || '.'
                );
            END IF;

            v_importes(v_i) := ROUND(
                v_total_linea / v_cant_linea * p_lineas(v_i).cantidad, 2
            );
            v_total := v_total + v_importes(v_i);

            v_i := p_lineas.NEXT(v_i);

        END LOOP;

        -- Las funciones privadas del paquete no se pueden usar dentro de
        -- una sentencia SQL: los ids se obtienen antes en variables.
        v_solicitada := id_estado_devolucion('SOLICITADA');
        v_procesada  := id_estado_devolucion('PROCESADA');

        INSERT INTO CP_POS.CP_DEVOLUCION_VENTA
            (id_factura_venta, id_estado_devolucion, id_usuario,
             fecha_devolucion, monto_total, observacion)
        VALUES
            (p_id_factura, v_solicitada, p_id_usuario,
             SYSDATE, v_total, 'API FACTURACION')
        RETURNING id_devolucion_venta INTO p_id_devolucion;

        v_i := p_lineas.FIRST;

        WHILE v_i IS NOT NULL LOOP

            INSERT INTO CP_POS.CP_DETALLE_DEVOLUCION_VENTA
                (id_devolucion_venta, id_detalle_venta_lote,
                 id_motivo_devolucion, cantidad_devuelta, monto_devolucion)
            VALUES
                (p_id_devolucion, p_lineas(v_i).id_detalle_venta_lote,
                 p_lineas(v_i).id_motivo_devolucion, p_lineas(v_i).cantidad,
                 v_importes(v_i));

            v_i := p_lineas.NEXT(v_i);

        END LOOP;

        UPDATE CP_POS.CP_DEVOLUCION_VENTA
        SET id_estado_devolucion = v_procesada
        WHERE id_devolucion_venta = p_id_devolucion;

        IF p_commit THEN
            COMMIT;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            CP_POS.PKG_CP_ERROR.registrar_inesperado(
                c_modulo, 'devolucion de venta de la factura ' || p_id_factura
            );
            ROLLBACK TO SAVEPOINT sp_devolucion_venta;
            p_id_devolucion := NULL;
            RAISE;
    END registrar_devolucion_venta;


    -- Devolucion de compra. Mismo esquema que la de venta, contra la
    -- cantidad recibida de cada lote; al procesarla se saca del
    -- inventario lo devuelto al proveedor.
    PROCEDURE registrar_devolucion_compra(
        p_id_factura    IN  NUMBER,
        p_id_usuario    IN  NUMBER,
        p_lineas        IN  t_lineas_dev_compra,
        p_id_devolucion OUT NUMBER,
        p_commit        IN  BOOLEAN DEFAULT TRUE
    )
    IS
        v_estado      NUMBER;
        v_i           PLS_INTEGER;
        v_recibido    NUMBER;
        v_previo      NUMBER;
        v_total_linea NUMBER;
        v_cant_linea  NUMBER;
        v_pedido      t_acumulado;
        v_clave       VARCHAR2(40);
        v_importes    t_importes;
        v_solicitada  NUMBER;
        v_procesada   NUMBER;
    BEGIN

        SAVEPOINT sp_devolucion_compra;

        IF p_lineas.COUNT = 0 THEN
            CP_POS.PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_datos,
                'La devolucion debe tener al menos una linea.'
            );
        END IF;

        bloquear_compra(p_id_factura, v_estado);

        IF v_estado = id_estado_compra('ANULADA') THEN
            CP_POS.PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_documento,
                'No se puede devolver sobre una factura anulada.'
            );
        END IF;

        v_i := p_lineas.FIRST;

        WHILE v_i IS NOT NULL LOOP

            IF p_lineas(v_i).id_lote_producto IS NULL
               OR p_lineas(v_i).id_motivo_devolucion IS NULL
               OR p_lineas(v_i).cantidad IS NULL
               OR p_lineas(v_i).cantidad <= 0 THEN
                CP_POS.PKG_CP_ERROR.lanzar(
                    c_modulo,
                    c_err_datos,
                    'Linea ' || v_i || ': faltan datos o la cantidad no es mayor que cero.'
                );
            END IF;

            BEGIN

                SELECT lp.cantidad_recibida, dc.total_linea, dc.cantidad
                INTO v_recibido, v_total_linea, v_cant_linea
                FROM CP_POS.CP_LOTE_PRODUCTO lp
                JOIN CP_POS.CP_DETALLE_COMPRA dc
                  ON dc.id_detalle_compra = lp.id_detalle_compra
                WHERE lp.id_lote_producto = p_lineas(v_i).id_lote_producto
                  AND dc.id_factura_compra = p_id_factura;

            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    CP_POS.PKG_CP_ERROR.lanzar(
                        c_modulo,
                        c_err_datos,
                        'Linea ' || v_i || ': el lote ' || p_lineas(v_i).id_lote_producto
                        || ' no pertenece a la factura ' || p_id_factura || '.'
                    );
            END;

            SELECT NVL(SUM(cantidad), 0)
            INTO v_previo
            FROM CP_POS.CP_DETALLE_DEVOLUCION_COMPRA
            WHERE id_lote_producto = p_lineas(v_i).id_lote_producto;

            v_clave := TO_CHAR(p_lineas(v_i).id_lote_producto);

            IF NOT v_pedido.EXISTS(v_clave) THEN
                v_pedido(v_clave) := 0;
            END IF;

            v_pedido(v_clave) := v_pedido(v_clave) + p_lineas(v_i).cantidad;

            IF v_previo + v_pedido(v_clave) > v_recibido THEN
                CP_POS.PKG_CP_ERROR.lanzar(
                    c_modulo,
                    c_err_cantidad,
                    'Linea ' || v_i || ': se recibieron ' || v_recibido
                    || ', ya se devolvieron ' || v_previo
                    || ' y se piden ' || v_pedido(v_clave) || '.'
                );
            END IF;

            v_importes(v_i) := ROUND(
                v_total_linea / v_cant_linea * p_lineas(v_i).cantidad, 2
            );

            v_i := p_lineas.NEXT(v_i);

        END LOOP;

        v_solicitada := id_estado_devolucion('SOLICITADA');
        v_procesada  := id_estado_devolucion('PROCESADA');

        INSERT INTO CP_POS.CP_DEVOLUCION_COMPRA
            (id_factura_compra, id_estado_devolucion, id_usuario,
             fecha_devolucion, observacion)
        VALUES
            (p_id_factura, v_solicitada, p_id_usuario,
             SYSDATE, 'API FACTURACION')
        RETURNING id_devolucion_compra INTO p_id_devolucion;

        v_i := p_lineas.FIRST;

        WHILE v_i IS NOT NULL LOOP

            INSERT INTO CP_POS.CP_DETALLE_DEVOLUCION_COMPRA
                (id_devolucion_compra, id_lote_producto, id_motivo_devolucion,
                 cantidad, monto_devolucion)
            VALUES
                (p_id_devolucion, p_lineas(v_i).id_lote_producto,
                 p_lineas(v_i).id_motivo_devolucion, p_lineas(v_i).cantidad,
                 v_importes(v_i));

            v_i := p_lineas.NEXT(v_i);

        END LOOP;

        UPDATE CP_POS.CP_DEVOLUCION_COMPRA
        SET id_estado_devolucion = v_procesada
        WHERE id_devolucion_compra = p_id_devolucion;

        IF p_commit THEN
            COMMIT;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            CP_POS.PKG_CP_ERROR.registrar_inesperado(
                c_modulo, 'devolucion de compra de la factura ' || p_id_factura
            );
            ROLLBACK TO SAVEPOINT sp_devolucion_compra;
            p_id_devolucion := NULL;
            RAISE;
    END registrar_devolucion_compra;

END PKG_CP_FACTURACION;
/

SHOW ERRORS PACKAGE PKG_CP_FACTURACION
SHOW ERRORS PACKAGE BODY PKG_CP_FACTURACION

-- ============================================================
-- 3. PERMISOS
-- ============================================================
-- Los tres roles que operan documentos reciben EXECUTE. Lo que cada
-- uno puede hacer realmente lo decide su acceso a las tablas, porque
-- el paquete se ejecuta con los privilegios de quien lo llama. El
-- GERENTE solo consulta y no necesita la API. El script 13 vuelve a
-- otorgar estos permisos si se ejecuta de nuevo.

BEGIN

    FOR r IN (
        SELECT column_value AS rol
        FROM TABLE(SYS.ODCIVARCHAR2LIST(
            'ROL_CP_DIGITADOR',
            'ROL_CP_JEFE_DEPARTAMENTO',
            'ROL_CP_JEFE_PROVEEDURIA'
        ))
    ) LOOP

        BEGIN
            EXECUTE IMMEDIATE
                'GRANT EXECUTE ON CP_POS.PKG_CP_FACTURACION TO ' || r.rol;
            DBMS_OUTPUT.PUT_LINE('EXECUTE otorgado a ' || r.rol);
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('No se pudo otorgar a ' || r.rol || ': ' || SQLERRM);
        END;

    END LOOP;

END;
/

-- ============================================================
-- 4. PRUEBAS DE LA API
-- ============================================================
-- Todas las pruebas deben salir OK. Se ejecutan como CP_POS con
-- p_commit => FALSE y todo se deshace con ROLLBACK, salvo las dos
-- primeras: confirman una venta de verdad (para comprobar el COMMIT)
-- y la compensan con anular_venta, de modo que el inventario queda
-- igual y solo permanece una factura ANULADA con numero T25-C-...
-- La prueba de NOWAIT (23 a 25) necesita una factura EMITIDA ya
-- confirmada; si la base no trae una, el script crea otra (T25-N-...)
-- y la anula al final, de modo que queda una segunda factura ANULADA.
-- Las pruebas de credito se omiten si no se puede crear el credito
-- temporal. Solo se borran de la bitacora los errores provocados a
-- proposito.

DECLARE
    v_antes        NUMBER;
    v_errores      NUMBER;
    v_ok           NUMBER := 0;
    v_falla        NUMBER := 0;

    v_sucursal     NUMBER;
    v_almacen      NUMBER;
    v_producto     NUMBER;
    v_negocio      NUMBER;
    v_cliente      NUMBER;
    v_usuario      NUMBER;
    v_tipo_pago    NUMBER;
    v_motivo_si    NUMBER;
    v_motivo_no    NUMBER;
    v_activo       NUMBER;

    v_cli_credito  NUMBER;
    v_credito_ok   BOOLEAN := FALSE;
    v_prov         NUMBER;
    v_neg_compra   NUMBER;
    v_alm_compra   NUMBER;
    v_pp           NUMBER;
    v_compra_ok    BOOLEAN := FALSE;
    v_provc_ok     BOOLEAN := FALSE;
    v_ajena        NUMBER;
    v_creada       BOOLEAN := FALSE;
    v_dummy        NUMBER;
    v_t0           NUMBER;

    v_stock_ini    NUMBER;
    v_stock_ant    NUMBER;
    v_ultima       NUMBER;
    v_codigo       NUMBER;
    v_numero_c     VARCHAR2(50);

    v_f1           NUMBER;
    v_fc           NUMBER;
    v_f4           NUMBER;
    v_cc           NUMBER;
    v_dvl1         NUMBER;
    v_dvl2         NUMBER;
    v_d1           NUMBER;
    v_c1           NUMBER;
    v_cr           NUMBER;
    v_cp           NUMBER;
    v_lote1        NUMBER;
    v_dc1          NUMBER;

    v_lv           PKG_CP_FACTURACION.t_lineas_venta;
    v_vacia        PKG_CP_FACTURACION.t_lineas_venta;
    v_lc           PKG_CP_FACTURACION.t_lineas_compra;

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
            RPAD(p_prueba, 70, '.') || CASE WHEN p_ok THEN ' OK' ELSE ' FALLA' END
        );
    END reportar;

    PROCEDURE omitir(
        p_prueba IN VARCHAR2
    )
    IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(RPAD(p_prueba, 70, '.') || ' omitida');
    END omitir;

    FUNCTION provoca(
        p_obtenido IN NUMBER,
        p_esperado IN NUMBER
    ) RETURN BOOLEAN
    IS
    BEGIN
        RETURN p_obtenido = p_esperado;
    END provoca;

    -- Consultas de apoyo ------------------------------------------------

    FUNCTION stock_producto RETURN NUMBER
    IS
        v_total NUMBER;
    BEGIN
        SELECT NVL(SUM(cantidad_actual), 0)
        INTO v_total
        FROM VW_CP_INVENTARIO_ACTUAL
        WHERE id_almacen = v_almacen
          AND id_producto = v_producto;
        RETURN v_total;
    END stock_producto;

    FUNCTION stock_lote(
        p_lote IN NUMBER
    ) RETURN NUMBER
    IS
        v_total NUMBER;
    BEGIN
        SELECT NVL(SUM(cantidad_actual), 0)
        INTO v_total
        FROM CP_INVENTARIO_ALMACEN
        WHERE id_lote_producto = p_lote
          AND id_almacen = v_alm_compra;
        RETURN v_total;
    END stock_lote;

    FUNCTION estado_fv(
        p_id IN NUMBER
    ) RETURN VARCHAR2
    IS
        v_nombre VARCHAR2(50);
    BEGIN
        SELECT e.nombre_estado_factura
        INTO v_nombre
        FROM CP_FACTURA_VENTA f
        JOIN CP_ESTADO_FACTURA_VENTA e
          ON e.id_estado_factura_venta = f.id_estado_factura_venta
        WHERE f.id_factura_venta = p_id;
        RETURN v_nombre;
    END estado_fv;

    FUNCTION estado_fc(
        p_id IN NUMBER
    ) RETURN VARCHAR2
    IS
        v_nombre VARCHAR2(50);
    BEGIN
        SELECT e.nombre_estado_factura
        INTO v_nombre
        FROM CP_FACTURA_COMPRA f
        JOIN CP_ESTADO_FACTURA_COMPRA e
          ON e.id_estado_factura_compra = f.id_estado_factura_compra
        WHERE f.id_factura_compra = p_id;
        RETURN v_nombre;
    END estado_fc;

    FUNCTION montos_fv(
        p_id IN NUMBER
    ) RETURN VARCHAR2
    IS
        v_texto VARCHAR2(100);
    BEGIN
        SELECT subtotal || '/' || descuento_total || '/' || impuesto_total || '/' || total
        INTO v_texto
        FROM CP_FACTURA_VENTA
        WHERE id_factura_venta = p_id;
        RETURN v_texto;
    END montos_fv;

    FUNCTION montos_fc(
        p_id IN NUMBER
    ) RETURN VARCHAR2
    IS
        v_texto VARCHAR2(100);
    BEGIN
        SELECT subtotal || '/' || descuento_total || '/' || impuesto_total || '/' || total
        INTO v_texto
        FROM CP_FACTURA_COMPRA
        WHERE id_factura_compra = p_id;
        RETURN v_texto;
    END montos_fc;

    FUNCTION cuenta_cobrar_de(
        p_factura IN NUMBER
    ) RETURN NUMBER
    IS
        v_id NUMBER;
    BEGIN
        SELECT MIN(id_cuenta_cobrar)
        INTO v_id
        FROM CP_CUENTA_COBRAR
        WHERE id_factura_venta = p_factura;
        RETURN v_id;
    END cuenta_cobrar_de;

    FUNCTION saldo_cc(
        p_id IN NUMBER
    ) RETURN NUMBER
    IS
        v_saldo NUMBER;
    BEGIN
        SELECT saldo_pendiente
        INTO v_saldo
        FROM CP_CUENTA_COBRAR
        WHERE id_cuenta_cobrar = p_id;
        RETURN v_saldo;
    END saldo_cc;

    FUNCTION estado_cc(
        p_id IN NUMBER
    ) RETURN VARCHAR2
    IS
        v_nombre VARCHAR2(50);
    BEGIN
        SELECT e.nombre_estado_cuenta_cobrar
        INTO v_nombre
        FROM CP_CUENTA_COBRAR c
        JOIN CP_ESTADO_CUENTA_COBRAR e
          ON e.id_estado_cuenta_cobrar = c.id_estado_cuenta_cobrar
        WHERE c.id_cuenta_cobrar = p_id;
        RETURN v_nombre;
    END estado_cc;

    FUNCTION cuenta_pagar_de(
        p_factura IN NUMBER
    ) RETURN NUMBER
    IS
        v_id NUMBER;
    BEGIN
        SELECT MIN(id_cuenta_pagar)
        INTO v_id
        FROM CP_CUENTA_PAGAR
        WHERE id_factura_compra = p_factura;
        RETURN v_id;
    END cuenta_pagar_de;

    FUNCTION saldo_cp(
        p_id IN NUMBER
    ) RETURN NUMBER
    IS
        v_saldo NUMBER;
    BEGIN
        SELECT saldo_pendiente
        INTO v_saldo
        FROM CP_CUENTA_PAGAR
        WHERE id_cuenta_pagar = p_id;
        RETURN v_saldo;
    END saldo_cp;

    FUNCTION estado_cp(
        p_id IN NUMBER
    ) RETURN VARCHAR2
    IS
        v_nombre VARCHAR2(50);
    BEGIN
        SELECT e.nombre_estado_cuenta_pagar
        INTO v_nombre
        FROM CP_CUENTA_PAGAR c
        JOIN CP_ESTADO_CUENTA_PAGAR e
          ON e.id_estado_cuenta_pagar = c.id_estado_cuenta_pagar
        WHERE c.id_cuenta_pagar = p_id;
        RETURN v_nombre;
    END estado_cp;

    FUNCTION cuenta_fv(
        p_numero IN VARCHAR2
    ) RETURN NUMBER
    IS
        v_total NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_total
        FROM CP_FACTURA_VENTA
        WHERE numero_factura = p_numero;
        RETURN v_total;
    END cuenta_fv;

    FUNCTION cuenta_fc(
        p_numero IN VARCHAR2
    ) RETURN NUMBER
    IS
        v_total NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_total
        FROM CP_FACTURA_COMPRA
        WHERE numero_factura = p_numero;
        RETURN v_total;
    END cuenta_fc;

    FUNCTION cuenta_lotes(
        p_numero IN VARCHAR2
    ) RETURN NUMBER
    IS
        v_total NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_total
        FROM CP_LOTE_PRODUCTO
        WHERE numero_lote = p_numero;
        RETURN v_total;
    END cuenta_lotes;

    FUNCTION lote_venta_de(
        p_factura IN NUMBER
    ) RETURN NUMBER
    IS
        v_id NUMBER;
    BEGIN
        SELECT MIN(dvl.id_detalle_venta_lote)
        INTO v_id
        FROM CP_DETALLE_VENTA_LOTE dvl
        JOIN CP_DETALLE_VENTA_PRODUCTO dvp
          ON dvp.id_detalle_venta_producto = dvl.id_detalle_venta_producto
        WHERE dvp.id_factura_venta = p_factura;
        RETURN v_id;
    END lote_venta_de;

    FUNCTION lote_compra_de(
        p_factura IN NUMBER
    ) RETURN NUMBER
    IS
        v_id NUMBER;
    BEGIN
        SELECT MIN(lp.id_lote_producto)
        INTO v_id
        FROM CP_LOTE_PRODUCTO lp
        JOIN CP_DETALLE_COMPRA dc
          ON dc.id_detalle_compra = lp.id_detalle_compra
        WHERE dc.id_factura_compra = p_factura;
        RETURN v_id;
    END lote_compra_de;

    FUNCTION estado_dev_venta(
        p_id IN NUMBER
    ) RETURN VARCHAR2
    IS
        v_nombre VARCHAR2(50);
    BEGIN
        SELECT e.nombre_estado_devolucion
        INTO v_nombre
        FROM CP_DEVOLUCION_VENTA d
        JOIN CP_ESTADO_DEVOLUCION e
          ON e.id_estado_devolucion = d.id_estado_devolucion
        WHERE d.id_devolucion_venta = p_id;
        RETURN v_nombre;
    END estado_dev_venta;

    FUNCTION monto_dev_venta(
        p_id IN NUMBER
    ) RETURN NUMBER
    IS
        v_monto NUMBER;
    BEGIN
        SELECT monto_total
        INTO v_monto
        FROM CP_DEVOLUCION_VENTA
        WHERE id_devolucion_venta = p_id;
        RETURN v_monto;
    END monto_dev_venta;

    FUNCTION estado_dev_compra(
        p_id IN NUMBER
    ) RETURN VARCHAR2
    IS
        v_nombre VARCHAR2(50);
    BEGIN
        SELECT e.nombre_estado_devolucion
        INTO v_nombre
        FROM CP_DEVOLUCION_COMPRA d
        JOIN CP_ESTADO_DEVOLUCION e
          ON e.id_estado_devolucion = d.id_estado_devolucion
        WHERE d.id_devolucion_compra = p_id;
        RETURN v_nombre;
    END estado_dev_compra;

    FUNCTION cuenta_devoluciones_venta(
        p_factura IN NUMBER
    ) RETURN NUMBER
    IS
        v_total NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_total
        FROM CP_DEVOLUCION_VENTA
        WHERE id_factura_venta = p_factura;
        RETURN v_total;
    END cuenta_devoluciones_venta;

    -- Funciones que se ejecutan en OTRA sesion ------------------------------
    -- Una transaccion autonoma se comporta como una segunda conexion:
    -- no ve lo que la principal no ha confirmado y no comparte sus bloqueos.

    FUNCTION visible_otra_sesion(
        p_numero IN VARCHAR2
    ) RETURN NUMBER
    IS
        PRAGMA AUTONOMOUS_TRANSACTION;
        v_total NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_total
        FROM CP_FACTURA_VENTA
        WHERE numero_factura = p_numero;
        ROLLBACK;
        RETURN v_total;
    END visible_otra_sesion;

    FUNCTION anular_otra_sesion(
        p_factura IN NUMBER
    ) RETURN NUMBER
    IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        PKG_CP_FACTURACION.anular_venta(
            p_id_factura => p_factura,
            p_commit     => FALSE
        );
        ROLLBACK;
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RETURN SQLCODE;
    END anular_otra_sesion;

    -- Envoltorios de la API: devuelven 0 o el codigo de error -------------

    FUNCTION linea_venta(
        p_cantidad IN NUMBER,
        p_precio   IN NUMBER,
        p_desc     IN NUMBER DEFAULT 0,
        p_imp      IN NUMBER DEFAULT 0
    ) RETURN PKG_CP_FACTURACION.t_lineas_venta
    IS
        v_lineas PKG_CP_FACTURACION.t_lineas_venta;
    BEGIN
        v_lineas(1).id_producto := v_producto;
        v_lineas(1).cantidad := p_cantidad;
        v_lineas(1).precio_unitario := p_precio;
        v_lineas(1).porcentaje_descuento := p_desc;
        v_lineas(1).porcentaje_impuesto := p_imp;
        RETURN v_lineas;
    END linea_venta;

    FUNCTION linea_compra(
        p_pp       IN NUMBER,
        p_cantidad IN NUMBER,
        p_costo    IN NUMBER,
        p_imp      IN NUMBER,
        p_lote     IN VARCHAR2,
        p_vence    IN DATE
    ) RETURN PKG_CP_FACTURACION.t_lineas_compra
    IS
        v_lineas PKG_CP_FACTURACION.t_lineas_compra;
    BEGIN
        v_lineas(1).id_producto_proveedor := p_pp;
        v_lineas(1).cantidad := p_cantidad;
        v_lineas(1).precio_costo_unitario := p_costo;
        v_lineas(1).porcentaje_descuento := 0;
        v_lineas(1).porcentaje_impuesto := p_imp;
        v_lineas(1).numero_lote := p_lote;
        v_lineas(1).fecha_vencimiento := p_vence;
        RETURN v_lineas;
    END linea_compra;

    FUNCTION vender(
        p_numero  IN VARCHAR2,
        p_lineas  IN PKG_CP_FACTURACION.t_lineas_venta,
        p_credito IN BOOLEAN DEFAULT FALSE,
        p_cliente IN NUMBER  DEFAULT NULL,
        p_commit  IN BOOLEAN DEFAULT FALSE
    ) RETURN NUMBER
    IS
    BEGIN
        PKG_CP_FACTURACION.registrar_venta(
            p_id_cliente     => NVL(p_cliente, v_cliente),
            p_id_sucursal    => v_sucursal,
            p_id_usuario     => v_usuario,
            p_numero_factura => p_numero,
            p_lineas         => p_lineas,
            p_id_factura     => v_ultima,
            p_a_credito      => p_credito,
            p_commit         => p_commit
        );
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            v_ultima := NULL;
            RETURN SQLCODE;
    END vender;

    FUNCTION comprar(
        p_numero  IN VARCHAR2,
        p_lineas  IN PKG_CP_FACTURACION.t_lineas_compra,
        p_credito IN BOOLEAN DEFAULT FALSE
    ) RETURN NUMBER
    IS
    BEGIN
        PKG_CP_FACTURACION.registrar_compra(
            p_id_proveedor         => v_prov,
            p_id_negocio           => v_neg_compra,
            p_id_almacen_recepcion => v_alm_compra,
            p_id_usuario           => v_usuario,
            p_numero_factura       => p_numero,
            p_lineas               => p_lineas,
            p_id_factura           => v_ultima,
            p_a_credito            => p_credito,
            p_commit               => FALSE
        );
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            v_ultima := NULL;
            RETURN SQLCODE;
    END comprar;

    FUNCTION anular_v(
        p_id IN NUMBER
    ) RETURN NUMBER
    IS
    BEGIN
        PKG_CP_FACTURACION.anular_venta(p_id_factura => p_id, p_commit => FALSE);
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN SQLCODE;
    END anular_v;

    FUNCTION anular_c(
        p_id IN NUMBER
    ) RETURN NUMBER
    IS
    BEGIN
        PKG_CP_FACTURACION.anular_compra(p_id_factura => p_id, p_commit => FALSE);
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN SQLCODE;
    END anular_c;

    FUNCTION abonar_cobrar(
        p_id    IN NUMBER,
        p_monto IN NUMBER
    ) RETURN NUMBER
    IS
    BEGIN
        PKG_CP_FACTURACION.registrar_abono_cobrar(
            p_id_cuenta    => p_id,
            p_id_tipo_pago => v_tipo_pago,
            p_id_usuario   => v_usuario,
            p_monto        => p_monto,
            p_commit       => FALSE
        );
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN SQLCODE;
    END abonar_cobrar;

    FUNCTION abonar_pagar(
        p_id    IN NUMBER,
        p_monto IN NUMBER
    ) RETURN NUMBER
    IS
    BEGIN
        PKG_CP_FACTURACION.registrar_abono_pagar(
            p_id_cuenta    => p_id,
            p_id_tipo_pago => v_tipo_pago,
            p_id_usuario   => v_usuario,
            p_monto        => p_monto,
            p_commit       => FALSE
        );
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN SQLCODE;
    END abonar_pagar;

    FUNCTION devolver_venta(
        p_factura IN NUMBER,
        p_dvl     IN NUMBER,
        p_motivo  IN NUMBER,
        p_cant    IN NUMBER
    ) RETURN NUMBER
    IS
        v_lineas PKG_CP_FACTURACION.t_lineas_dev_venta;
    BEGIN
        v_lineas(1).id_detalle_venta_lote := p_dvl;
        v_lineas(1).id_motivo_devolucion := p_motivo;
        v_lineas(1).cantidad := p_cant;
        PKG_CP_FACTURACION.registrar_devolucion_venta(
            p_id_factura    => p_factura,
            p_id_usuario    => v_usuario,
            p_lineas        => v_lineas,
            p_id_devolucion => v_ultima,
            p_commit        => FALSE
        );
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            v_ultima := NULL;
            RETURN SQLCODE;
    END devolver_venta;

    FUNCTION devolver_compra(
        p_factura IN NUMBER,
        p_lote    IN NUMBER,
        p_motivo  IN NUMBER,
        p_cant    IN NUMBER
    ) RETURN NUMBER
    IS
        v_lineas PKG_CP_FACTURACION.t_lineas_dev_compra;
    BEGIN
        v_lineas(1).id_lote_producto := p_lote;
        v_lineas(1).id_motivo_devolucion := p_motivo;
        v_lineas(1).cantidad := p_cant;
        PKG_CP_FACTURACION.registrar_devolucion_compra(
            p_id_factura    => p_factura,
            p_id_usuario    => v_usuario,
            p_lineas        => v_lineas,
            p_id_devolucion => v_ultima,
            p_commit        => FALSE
        );
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            v_ultima := NULL;
            RETURN SQLCODE;
    END devolver_compra;

BEGIN

    SELECT NVL(MAX(id_bitacora_error), 0) INTO v_antes FROM CP_BITACORA_ERROR;

    -- Producto con stock vigente en una sucursal con un solo almacen
    -- activo (el inventario de venta sale de ese almacen).
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
    HAVING SUM(v.cantidad_actual) >= 6
    ORDER BY SUM(v.cantidad_actual) DESC, v.id_producto, v.id_almacen
    FETCH FIRST 1 ROW ONLY;

    SELECT id_negocio INTO v_negocio FROM CP_SUCURSAL WHERE id_sucursal = v_sucursal;
    SELECT MIN(id_cliente) INTO v_cliente FROM CP_CLIENTE;
    SELECT MIN(id_usuario) INTO v_usuario FROM CP_USUARIO;
    SELECT MIN(id_tipo_pago) INTO v_tipo_pago FROM CP_TIPO_PAGO;

    SELECT id_motivo_devolucion INTO v_motivo_si
    FROM CP_MOTIVO_DEVOLUCION WHERE nombre_motivo_devolucion = 'PRODUCTO INCORRECTO';

    SELECT id_motivo_devolucion INTO v_motivo_no
    FROM CP_MOTIVO_DEVOLUCION WHERE nombre_motivo_devolucion = 'PRODUCTO DANADO';

    SELECT id_estado_credito INTO v_activo
    FROM CP_ESTADO_CREDITO WHERE nombre_estado_credito = 'ACTIVO';

    v_stock_ini := stock_producto;

    -- Datos para las pruebas de compra: primer proveedor con credito.
    BEGIN

        SELECT id_proveedor, id_negocio
        INTO v_prov, v_neg_compra
        FROM CP_CREDITO_PROVEEDOR
        ORDER BY id_credito_proveedor
        FETCH FIRST 1 ROW ONLY;

        SELECT MIN(id_producto_proveedor)
        INTO v_pp
        FROM CP_PRODUCTO_PROVEEDOR
        WHERE id_proveedor = v_prov;

        SELECT MIN(a.id_almacen)
        INTO v_alm_compra
        FROM CP_ALMACEN a
        JOIN CP_SUCURSAL s
          ON s.id_sucursal = a.id_sucursal
        WHERE s.id_negocio = v_neg_compra;

        v_compra_ok := v_pp IS NOT NULL AND v_alm_compra IS NOT NULL;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_compra_ok := FALSE;
    END;

    -- ------------------------------------------------------------
    -- A. COMMIT: la unica venta que se confirma de verdad
    -- ------------------------------------------------------------
    v_numero_c := 'T25-C-' || TO_CHAR(SYSDATE, 'MMDDHH24MISS');

    v_codigo := vender(v_numero_c, linea_venta(1, 1000), FALSE, NULL, TRUE);

    reportar('1. Con p_commit TRUE la venta ya la ve otra sesion',
             v_codigo = 0 AND visible_otra_sesion(v_numero_c) = 1);

    IF v_ultima IS NOT NULL THEN
        v_codigo := 0;
        PKG_CP_FACTURACION.anular_venta(p_id_factura => v_ultima, p_commit => TRUE);
        reportar('2. La venta confirmada se compensa con anular_venta y el stock vuelve',
                 estado_fv(v_ultima) = 'ANULADA' AND stock_producto = v_stock_ini);
    ELSE
        reportar('2. La venta confirmada se compensa con anular_venta y el stock vuelve', FALSE);
    END IF;

    -- Factura EMITIDA y confirmada para la prueba de NOWAIT (seccion E).
    -- La "otra sesion" es una transaccion autonoma y solo ve filas
    -- confirmadas. Si la base no trae una factura EMITIDA ajena a las
    -- pruebas, se crea y confirma una aqui (la sesion aun no tiene nada
    -- pendiente) y se compensa al final con anular_venta.
    SELECT MIN(f.id_factura_venta)
    INTO v_ajena
    FROM CP_FACTURA_VENTA f
    WHERE f.numero_factura NOT LIKE 'T25-%'
      AND f.id_estado_factura_venta = (
          SELECT id_estado_factura_venta
          FROM CP_ESTADO_FACTURA_VENTA
          WHERE nombre_estado_factura = 'EMITIDA'
      );

    IF v_ajena IS NULL THEN
        v_codigo := vender('T25-N-' || TO_CHAR(SYSDATE, 'MMDDHH24MISS'),
                           linea_venta(1, 1000), FALSE, NULL, TRUE);
        IF v_codigo = 0 AND v_ultima IS NOT NULL THEN
            v_ajena := v_ultima;
            v_creada := TRUE;
        END IF;
    END IF;

    -- Credito temporal para las pruebas a credito (se deshace al final).
    BEGIN

        SELECT MIN(c.id_cliente)
        INTO v_cli_credito
        FROM CP_CLIENTE c
        WHERE NOT EXISTS (
            SELECT 1
            FROM CP_CREDITO_CLIENTE cr
            WHERE cr.id_cliente = c.id_cliente
              AND cr.id_negocio = v_negocio
        );

        IF v_cli_credito IS NULL THEN
            SELECT id_cliente
            INTO v_cli_credito
            FROM CP_CREDITO_CLIENTE
            WHERE id_negocio = v_negocio
            ORDER BY id_credito_cliente
            FETCH FIRST 1 ROW ONLY;
        END IF;

        INSERT INTO CP_CREDITO_CLIENTE
            (id_cliente, id_negocio, id_estado_credito, limite_credito,
             fecha_autorizacion, fecha_vencimiento)
        VALUES
            (v_cli_credito, v_negocio, v_activo, 500000, SYSDATE - 10, SYSDATE + 365);

        v_credito_ok := TRUE;

    EXCEPTION
        WHEN OTHERS THEN
            v_credito_ok := FALSE;
            DBMS_OUTPUT.PUT_LINE('Credito temporal de cliente no disponible: ' || SQLERRM);
    END;

    IF v_compra_ok THEN

        BEGIN

            INSERT INTO CP_CREDITO_PROVEEDOR
                (id_proveedor, id_negocio, id_estado_credito, limite_credito,
                 fecha_autorizacion, fecha_vencimiento)
            VALUES
                (v_prov, v_neg_compra, v_activo, 500000, SYSDATE - 10, SYSDATE + 365);

            v_provc_ok := TRUE;

        EXCEPTION
            WHEN OTHERS THEN
                v_provc_ok := FALSE;
                DBMS_OUTPUT.PUT_LINE('Credito temporal de proveedor no disponible: ' || SQLERRM);
        END;

    END IF;

    -- ------------------------------------------------------------
    -- B. VENTAS
    -- ------------------------------------------------------------
    v_stock_ant := stock_producto;

    v_codigo := vender('T25-V1', linea_venta(1, 1000, 10, 13));
    v_f1 := v_ultima;

    reportar('3. Venta de contado: totales 1000/100/117/1017 y estado EMITIDA',
             v_codigo = 0 AND montos_fv(v_f1) = '1000/100/117/1017'
             AND estado_fv(v_f1) = 'EMITIDA');

    reportar('4. La venta descuenta 1 unidad del inventario',
             stock_producto = v_stock_ant - 1);

    reportar('5. Con p_commit FALSE la venta no la ve otra sesion',
             visible_otra_sesion('T25-V1') = 0);

    -- Atomicidad: la segunda linea no tiene stock.
    v_stock_ant := stock_producto;
    v_lv(1).id_producto := v_producto;
    v_lv(1).cantidad := 1;
    v_lv(1).precio_unitario := 1000;
    v_lv(2).id_producto := v_producto;
    v_lv(2).cantidad := 1000000;
    v_lv(2).precio_unitario := 1000;

    v_codigo := vender('T25-V2', v_lv);

    reportar('6. Una linea sin stock hace fallar la venta con -20273',
             provoca(v_codigo, -20273));

    reportar('7. SAVEPOINT: no queda la cabecera ni se descuenta la primera linea',
             cuenta_fv('T25-V2') = 0 AND stock_producto = v_stock_ant);

    reportar('8. El ROLLBACK TO SAVEPOINT no toca la venta anterior sin confirmar',
             cuenta_fv('T25-V1') = 1);

    reportar('9. Una venta sin lineas da -20292',
             provoca(vender('T25-V3', v_vacia), -20292));

    reportar('10. Una cantidad en cero da -20292',
             provoca(vender('T25-V3', linea_venta(0, 1000)), -20292));

    reportar('11. Un descuento mayor que 100 da -20292 y no guarda nada',
             provoca(vender('T25-V3', linea_venta(1, 1000, 150, 0)), -20292)
             AND cuenta_fv('T25-V3') = 0);

    IF v_credito_ok THEN

        v_codigo := vender('T25-VC', linea_venta(1, 1000), TRUE, v_cli_credito);
        v_fc := v_ultima;
        v_cc := cuenta_cobrar_de(v_fc);

        reportar('12. Venta a credito: factura PENDIENTE y cuenta por cobrar de 1000',
                 v_codigo = 0 AND estado_fv(v_fc) = 'PENDIENTE'
                 AND v_cc IS NOT NULL AND saldo_cc(v_cc) = 1000);

        reportar('13. Abono de 400 deja saldo 600 y la cuenta PARCIAL',
                 abonar_cobrar(v_cc, 400) = 0 AND saldo_cc(v_cc) = 600
                 AND estado_cc(v_cc) = 'PARCIAL');

        reportar('14. Abono de 700 sobre saldo 600 da -20252 y el saldo no cambia',
                 provoca(abonar_cobrar(v_cc, 700), -20252) AND saldo_cc(v_cc) = 600);

        reportar('15. Abono de 600 salda la cuenta y cancela la factura',
                 abonar_cobrar(v_cc, 600) = 0 AND estado_cc(v_cc) = 'PAGADA'
                 AND estado_fv(v_fc) = 'CANCELADA');

        reportar('16. Anular una factura con abonos da -20265 y conserva su estado',
                 provoca(anular_v(v_fc), -20265) AND estado_fv(v_fc) = 'CANCELADA');

    ELSE
        omitir('12 a 16. Venta a credito y abonos (sin credito temporal)');
    END IF;

    -- ------------------------------------------------------------
    -- C. DEVOLUCIONES DE VENTA
    -- ------------------------------------------------------------
    v_dvl1 := lote_venta_de(v_f1);
    v_stock_ant := stock_producto;

    v_codigo := devolver_venta(v_f1, v_dvl1, v_motivo_si, 1);
    v_d1 := v_ultima;

    reportar('17. Devolucion que reingresa: PROCESADA y la unidad vuelve al inventario',
             v_codigo = 0 AND estado_dev_venta(v_d1) = 'PROCESADA'
             AND stock_producto = v_stock_ant + 1);

    reportar('18. El monto de la devolucion es el de la linea (1017)',
             monto_dev_venta(v_d1) = 1017);

    reportar('19. Devolver mas de lo vendido da -20294 y no crea otra devolucion',
             provoca(devolver_venta(v_f1, v_dvl1, v_motivo_si, 1), -20294)
             AND cuenta_devoluciones_venta(v_f1) = 1);

    IF v_credito_ok THEN

        v_dvl2 := lote_venta_de(v_fc);
        v_stock_ant := stock_producto;

        v_codigo := devolver_venta(v_fc, v_dvl2, v_motivo_no, 1);

        reportar('20. Devolucion por producto danado no reingresa al inventario',
                 v_codigo = 0 AND estado_dev_venta(v_ultima) = 'PROCESADA'
                 AND stock_producto = v_stock_ant);

    ELSE
        omitir('20. Devolucion por producto danado (sin venta a credito)');
    END IF;

    -- ------------------------------------------------------------
    -- D. ANULACION DE VENTA
    -- ------------------------------------------------------------
    v_codigo := vender('T25-V4', linea_venta(1, 1000));
    v_f4 := v_ultima;
    v_stock_ant := stock_producto;

    reportar('21. Anular una venta devuelve las unidades al inventario',
             v_codigo = 0 AND anular_v(v_f4) = 0 AND estado_fv(v_f4) = 'ANULADA'
             AND stock_producto = v_stock_ant + 1);

    reportar('22. Anular una factura ya anulada da -20293',
             provoca(anular_v(v_f4), -20293));

    -- ------------------------------------------------------------
    -- E. NOWAIT: documento bloqueado por otra sesion
    -- ------------------------------------------------------------
    -- v_ajena se preparo en la seccion A (factura EMITIDA y confirmada).
    IF v_ajena IS NOT NULL THEN

        -- Esta sesion bloquea la factura; la "otra sesion" intenta anularla.
        SELECT id_factura_venta
        INTO v_dummy
        FROM CP_FACTURA_VENTA
        WHERE id_factura_venta = v_ajena
        FOR UPDATE;

        v_t0 := DBMS_UTILITY.GET_TIME;
        v_codigo := anular_otra_sesion(v_ajena);

        reportar('23. NOWAIT: la otra sesion recibe -20291',
                 provoca(v_codigo, -20291));

        reportar('24. NOWAIT: la respuesta es inmediata (menos de 1 segundo)',
                 (DBMS_UTILITY.GET_TIME - v_t0) < 100);

        reportar('25. La factura bloqueada no cambio de estado',
                 estado_fv(v_ajena) = 'EMITIDA');

    ELSE
        omitir('23 a 25. NOWAIT (no hay una factura EMITIDA ajena a las pruebas)');
    END IF;

    -- ------------------------------------------------------------
    -- F. COMPRAS
    -- ------------------------------------------------------------
    IF v_compra_ok THEN

        v_codigo := comprar(
            'T25-C1',
            linea_compra(v_pp, 10, 500, 13, 'T25-L1', TRUNC(SYSDATE) + 90)
        );
        v_c1 := v_ultima;
        v_lote1 := lote_compra_de(v_c1);

        reportar('26. Compra de contado: totales 5000/0/650/5650 y estado REGISTRADA',
                 v_codigo = 0 AND montos_fc(v_c1) = '5000/0/650/5650'
                 AND estado_fc(v_c1) = 'REGISTRADA');

        reportar('27. El lote recibido suma 10 unidades al inventario',
                 v_lote1 IS NOT NULL AND stock_lote(v_lote1) = 10);

        -- Atomicidad: la segunda linea apunta a un producto que no existe.
        v_lc(1).id_producto_proveedor := v_pp;
        v_lc(1).cantidad := 5;
        v_lc(1).precio_costo_unitario := 100;
        v_lc(1).numero_lote := 'T25-L2A';
        v_lc(2).id_producto_proveedor := -1;
        v_lc(2).cantidad := 5;
        v_lc(2).precio_costo_unitario := 100;
        v_lc(2).numero_lote := 'T25-L2B';

        v_codigo := comprar('T25-C2', v_lc);

        reportar('28. Un producto inexistente hace fallar la compra con -2291',
                 provoca(v_codigo, -2291));

        reportar('29. SAVEPOINT: no queda la cabecera ni el lote de la primera linea',
                 cuenta_fc('T25-C2') = 0 AND cuenta_lotes('T25-L2A') = 0);

        reportar('30. Una linea sin numero de lote da -20292',
                 provoca(
                     comprar('T25-C3', linea_compra(v_pp, 1, 100, 0, NULL, NULL)),
                     -20292
                 ));

        IF v_provc_ok THEN

            v_codigo := comprar(
                'T25-CC',
                linea_compra(v_pp, 4, 250, 0, 'T25-L3', NULL),
                TRUE
            );
            v_cr := v_ultima;
            v_cp := cuenta_pagar_de(v_cr);

            reportar('31. Compra a credito: PENDIENTE y cuenta por pagar de 1000',
                     v_codigo = 0 AND estado_fc(v_cr) = 'PENDIENTE'
                     AND v_cp IS NOT NULL AND saldo_cp(v_cp) = 1000);

            reportar('32. Abono de 400 deja saldo 600 y la cuenta PARCIAL',
                     abonar_pagar(v_cp, 400) = 0 AND saldo_cp(v_cp) = 600
                     AND estado_cp(v_cp) = 'PARCIAL');

            reportar('33. Abono de 700 sobre saldo 600 da -20252 y el saldo no cambia',
                     provoca(abonar_pagar(v_cp, 700), -20252) AND saldo_cp(v_cp) = 600);

        ELSE
            omitir('31 a 33. Compra a credito y abonos (sin credito temporal)');
        END IF;

        -- Devolucion de compra y anulacion
        reportar('34. Devolver 4 de 10 unidades al proveedor: PROCESADA y el lote queda en 6',
                 devolver_compra(v_c1, v_lote1, v_motivo_si, 4) = 0
                 AND estado_dev_compra(v_ultima) = 'PROCESADA'
                 AND stock_lote(v_lote1) = 6);

        reportar('35. Devolver mas de lo recibido da -20294 y el lote no cambia',
                 provoca(devolver_compra(v_c1, v_lote1, v_motivo_si, 7), -20294)
                 AND stock_lote(v_lote1) = 6);

        reportar('36. Anular la compra retira lo que queda del lote y queda ANULADA',
                 anular_c(v_c1) = 0 AND estado_fc(v_c1) = 'ANULADA'
                 AND stock_lote(v_lote1) = 0);

        reportar('37. Anular una compra ya anulada da -20293',
                 provoca(anular_c(v_c1), -20293));

    ELSE
        omitir('26 a 37. Compras (no hay proveedor con producto y almacen para probar)');
    END IF;

    -- ------------------------------------------------------------
    -- G. ROLLBACK GENERAL
    -- ------------------------------------------------------------
    ROLLBACK;

    -- Compensa la venta confirmada que se creo para la prueba de NOWAIT:
    -- queda ANULADA y el inventario vuelve a su valor inicial.
    IF v_creada THEN
        PKG_CP_FACTURACION.anular_venta(p_id_factura => v_ajena, p_commit => TRUE);
    END IF;

    reportar('38. El ROLLBACK final deshace todo lo no confirmado',
             cuenta_fv('T25-V1') = 0 AND cuenta_fc('T25-C1') = 0
             AND stock_producto = v_stock_ini);

    SELECT COUNT(*)
    INTO v_errores
    FROM CP_BITACORA_ERROR
    WHERE id_bitacora_error > v_antes
      AND modulo = 'FACTURACION'
      AND codigo_error = -20291;

    reportar('39. El error de NOWAIT (-20291) quedo en la bitacora',
             v_errores = CASE WHEN v_ajena IS NOT NULL THEN 1 ELSE 0 END);

    SELECT COUNT(*)
    INTO v_errores
    FROM CP_BITACORA_ERROR
    WHERE id_bitacora_error > v_antes
      AND modulo = 'FACTURACION'
      AND codigo_error = -2291;

    reportar('40. El error inesperado (-2291) quedo en la bitacora',
             v_errores = CASE WHEN v_compra_ok THEN 1 ELSE 0 END);

    DELETE FROM CP_BITACORA_ERROR
    WHERE id_bitacora_error > v_antes
      AND modulo IN ('FACTURACION', 'CUENTA', 'INVENTARIO', 'CREDITO');

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Pruebas OK: ' || v_ok || ' | FALLA: ' || v_falla);

END;
/
