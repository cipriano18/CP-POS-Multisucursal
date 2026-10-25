-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- BASE DE DATOS: Oracle 21c
-- SCRIPT: 21_facturacion_inventario.sql
-- DESCRIPCION: Inventario automatico. Columna reingresa_inventario
--              en CP_MOTIVO_DEVOLUCION, paquete PKG_CP_INVENTARIO
--              (salida FEFO en las ventas, entrada por cada lote de
--              compra, reintegro y retiro al anular facturas y
--              movimiento al procesar devoluciones) y sus triggers,
--              con pruebas.
--
-- EJECUTAR COMO: CP_POS en XEPDB1 (despues de los scripts 15 y 20).
--                Se puede volver a ejecutar completo las veces
--                que haga falta.
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED

-- ============================================================
-- 1. COLUMNA REINGRESA_INVENTARIO
-- ============================================================

DECLARE
    v_existe NUMBER;
BEGIN

    SELECT COUNT(*)
    INTO v_existe
    FROM USER_TAB_COLUMNS
    WHERE table_name = 'CP_MOTIVO_DEVOLUCION'
      AND column_name = 'REINGRESA_INVENTARIO';

    IF v_existe = 0 THEN

        EXECUTE IMMEDIATE
            'ALTER TABLE CP_MOTIVO_DEVOLUCION ADD ('
            || 'reingresa_inventario CHAR(1) DEFAULT ''S'' NOT NULL)';

        EXECUTE IMMEDIATE
            'ALTER TABLE CP_MOTIVO_DEVOLUCION ADD CONSTRAINT '
            || 'CK_CP_MOTIVO_DEVOLUCION_REINGRESA '
            || 'CHECK (reingresa_inventario IN (''S'', ''N''))';

        EXECUTE IMMEDIATE
            'UPDATE CP_MOTIVO_DEVOLUCION SET reingresa_inventario = ''N'' '
            || 'WHERE nombre_motivo_devolucion IN '
            || '(''PRODUCTO DANADO'', ''PRODUCTO VENCIDO'', ''CALIDAD DEL PRODUCTO'')';

        COMMIT;

    END IF;

END;
/

COMMENT ON COLUMN CP_MOTIVO_DEVOLUCION.reingresa_inventario IS
'S = el producto devuelto por este motivo vuelve a quedar disponible en el inventario, N = no vuelve (danado, vencido o sin la calidad esperada).';

SELECT nombre_motivo_devolucion, reingresa_inventario
FROM CP_MOTIVO_DEVOLUCION
ORDER BY nombre_motivo_devolucion;

-- ============================================================
-- 2. PAQUETE PKG_CP_INVENTARIO (ESPECIFICACION)
-- ============================================================

CREATE OR REPLACE PACKAGE PKG_CP_INVENTARIO AUTHID DEFINER AS

    PROCEDURE descontar_venta(
        p_id_factura  IN NUMBER,
        p_id_detalle  IN NUMBER,
        p_id_producto IN NUMBER,
        p_cantidad    IN NUMBER
    )
    ACCESSIBLE BY (TRIGGER TRG_CP_VENTA_LINEA_INVENTARIO);

    PROCEDURE rechazar_cambio_linea_venta
    ACCESSIBLE BY (TRIGGER TRG_CP_VENTA_LINEA_INVENTARIO);

    FUNCTION es_operacion_interna RETURN BOOLEAN
    ACCESSIBLE BY (TRIGGER TRG_CP_VENTA_LOTE_PROTEGIDO);

    PROCEDURE rechazar_escritura_directa
    ACCESSIBLE BY (TRIGGER TRG_CP_VENTA_LOTE_PROTEGIDO);

    PROCEDURE sincronizar_factura_venta(
        p_id_factura      IN NUMBER,
        p_id_sucursal     IN NUMBER,
        p_id_usuario      IN NUMBER,
        p_estado_anterior IN NUMBER,
        p_estado_nuevo    IN NUMBER
    )
    ACCESSIBLE BY (TRIGGER TRG_CP_VENTA_INVENTARIO_ESTADO);

    PROCEDURE ingresar_lote(
        p_id_lote          IN NUMBER,
        p_id_detalle_compra IN NUMBER,
        p_cantidad         IN NUMBER
    )
    ACCESSIBLE BY (TRIGGER TRG_CP_LOTE_INVENTARIO);

    PROCEDURE validar_lotes_detalle(
        p_id_detalle_compra IN NUMBER
    )
    ACCESSIBLE BY (TRIGGER TRG_CP_LOTE_INVENTARIO);

    PROCEDURE rechazar_cambio_lote
    ACCESSIBLE BY (TRIGGER TRG_CP_LOTE_INVENTARIO);

    PROCEDURE sincronizar_factura_compra(
        p_id_factura      IN NUMBER,
        p_id_almacen      IN NUMBER,
        p_id_usuario      IN NUMBER,
        p_estado_anterior IN NUMBER,
        p_estado_nuevo    IN NUMBER
    )
    ACCESSIBLE BY (TRIGGER TRG_CP_COMPRA_INVENTARIO_ESTADO);

    PROCEDURE sincronizar_devolucion_venta(
        p_id_devolucion   IN NUMBER,
        p_id_factura      IN NUMBER,
        p_id_usuario      IN NUMBER,
        p_estado_anterior IN NUMBER,
        p_estado_nuevo    IN NUMBER
    )
    ACCESSIBLE BY (TRIGGER TRG_CP_DEV_VENTA_INVENTARIO);

    PROCEDURE sincronizar_devolucion_compra(
        p_id_devolucion   IN NUMBER,
        p_id_factura      IN NUMBER,
        p_id_usuario      IN NUMBER,
        p_estado_anterior IN NUMBER,
        p_estado_nuevo    IN NUMBER
    )
    ACCESSIBLE BY (TRIGGER TRG_CP_DEV_COMPRA_INVENTARIO);

    PROCEDURE validar_devolucion_venta_editable(
        p_id_devolucion IN NUMBER
    )
    ACCESSIBLE BY (TRIGGER TRG_CP_DEV_VENTA_DET_EDITABLE);

    PROCEDURE validar_devolucion_compra_editable(
        p_id_devolucion IN NUMBER
    )
    ACCESSIBLE BY (TRIGGER TRG_CP_DEV_COMPRA_DET_EDITABLE);

END PKG_CP_INVENTARIO;
/

-- ============================================================
-- 3. PAQUETE PKG_CP_INVENTARIO (CUERPO)
-- ============================================================

CREATE OR REPLACE PACKAGE BODY PKG_CP_INVENTARIO AS

    c_modulo CONSTANT VARCHAR2(20) := 'INVENTARIO';

    c_estado_activo    CONSTANT VARCHAR2(30) := 'ACTIVO';
    c_estado_anulada   CONSTANT VARCHAR2(30) := 'ANULADA';
    c_estado_procesada CONSTANT VARCHAR2(30) := 'PROCESADA';

    c_err_sin_almacen        CONSTANT PLS_INTEGER := -20270;
    c_err_varios_almacenes   CONSTANT PLS_INTEGER := -20271;
    c_err_insuficiente       CONSTANT PLS_INTEGER := -20272;
    c_err_sin_stock_venta    CONSTANT PLS_INTEGER := -20273;
    c_err_factura_anulada    CONSTANT PLS_INTEGER := -20274;
    c_err_lote_venta_directo CONSTANT PLS_INTEGER := -20275;
    c_err_lotes_exceden      CONSTANT PLS_INTEGER := -20276;
    c_err_linea_inmutable    CONSTANT PLS_INTEGER := -20277;
    c_err_lote_inmutable     CONSTANT PLS_INTEGER := -20278;
    c_err_dev_procesada      CONSTANT PLS_INTEGER := -20279;
    c_err_reactivar          CONSTANT PLS_INTEGER := -20280;
    c_err_dev_nace_procesada CONSTANT PLS_INTEGER := -20281;
    c_err_ocupado            CONSTANT PLS_INTEGER := -20282;
    c_err_sin_estado         CONSTANT PLS_INTEGER := -20283;

    e_ocupado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_ocupado, -30006);

    g_interno BOOLEAN := FALSE;


    -- Busca el id de un estado de factura de venta por su nombre (-20283 si no existe).
    FUNCTION id_estado_venta(
        p_nombre IN VARCHAR2
    ) RETURN NUMBER
    IS
        v_id CP_ESTADO_FACTURA_VENTA.id_estado_factura_venta%TYPE;
    BEGIN

        SELECT id_estado_factura_venta
        INTO v_id
        FROM CP_ESTADO_FACTURA_VENTA
        WHERE nombre_estado_factura = p_nombre;

        RETURN v_id;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_sin_estado,
                'No existe el estado de factura de venta ' || p_nombre || '.'
            );
    END id_estado_venta;


    -- Busca el id de un estado de factura de compra por su nombre (-20283 si no existe).
    FUNCTION id_estado_compra(
        p_nombre IN VARCHAR2
    ) RETURN NUMBER
    IS
        v_id CP_ESTADO_FACTURA_COMPRA.id_estado_factura_compra%TYPE;
    BEGIN

        SELECT id_estado_factura_compra
        INTO v_id
        FROM CP_ESTADO_FACTURA_COMPRA
        WHERE nombre_estado_factura = p_nombre;

        RETURN v_id;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_sin_estado,
                'No existe el estado de factura de compra ' || p_nombre || '.'
            );
    END id_estado_compra;


    -- Busca el id de un estado de devolucion por su nombre (-20283 si no existe).
    FUNCTION id_estado_devolucion(
        p_nombre IN VARCHAR2
    ) RETURN NUMBER
    IS
        v_id CP_ESTADO_DEVOLUCION.id_estado_devolucion%TYPE;
    BEGIN

        SELECT id_estado_devolucion
        INTO v_id
        FROM CP_ESTADO_DEVOLUCION
        WHERE nombre_estado_devolucion = p_nombre;

        RETURN v_id;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_sin_estado,
                'No existe el estado de devolucion ' || p_nombre || '.'
            );
    END id_estado_devolucion;


    -- Devuelve el unico almacen activo de la sucursal: el inventario de venta se mueve ahi.
    -- Falla con -20270 si no tiene ninguno y con -20271 si tiene mas de uno.
    FUNCTION almacen_de_sucursal(
        p_id_sucursal IN NUMBER
    ) RETURN NUMBER
    IS
        v_total NUMBER;
        v_id    NUMBER;
    BEGIN

        SELECT COUNT(*), MIN(a.id_almacen)
        INTO v_total, v_id
        FROM CP_ALMACEN a
        JOIN CP_ESTADO e
          ON e.id_estado = a.id_estado
        WHERE a.id_sucursal = p_id_sucursal
          AND e.nombre = c_estado_activo;

        IF v_total = 0 THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_sin_almacen,
                'La sucursal ' || p_id_sucursal || ' no tiene un almacen activo.'
            );
        ELSIF v_total > 1 THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_varios_almacenes,
                'La sucursal ' || p_id_sucursal
                || ' tiene mas de un almacen activo y no se sabe de cual mover el inventario.'
            );
        END IF;

        RETURN v_id;

    END almacen_de_sucursal;


    -- Unico punto que cambia CP_INVENTARIO_ALMACEN. Bloquea la fila con FOR UPDATE WAIT 5
    -- (-20282 si otra sesion la tiene), valida que la cantidad no quede negativa (-20272) y
    -- aplica el movimiento. La bitacora de inventario la escribe el trigger de la Parte 1.
    PROCEDURE mover_stock(
        p_id_almacen IN NUMBER,
        p_id_lote    IN NUMBER,
        p_delta      IN NUMBER,
        p_id_usuario IN NUMBER
    )
    IS
        v_id_inventario  CP_INVENTARIO_ALMACEN.id_inventario_almacen%TYPE;
        v_cantidad       CP_INVENTARIO_ALMACEN.cantidad_actual%TYPE;
        v_usuario_previo NUMBER;
    BEGIN

        IF p_delta = 0 THEN
            RETURN;
        END IF;

        BEGIN

            SELECT id_inventario_almacen, cantidad_actual
            INTO v_id_inventario, v_cantidad
            FROM CP_INVENTARIO_ALMACEN
            WHERE id_almacen = p_id_almacen
              AND id_lote_producto = p_id_lote
            FOR UPDATE WAIT 5;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN

                IF p_delta < 0 THEN
                    PKG_CP_ERROR.lanzar(
                        c_modulo,
                        c_err_insuficiente,
                        'El lote ' || p_id_lote || ' no tiene inventario en el almacen '
                        || p_id_almacen || '.'
                    );
                END IF;

                INSERT INTO CP_INVENTARIO_ALMACEN
                    (id_almacen, id_lote_producto, cantidad_actual, fecha_actualizacion)
                VALUES
                    (p_id_almacen, p_id_lote, 0, SYSTIMESTAMP)
                RETURNING id_inventario_almacen, cantidad_actual
                INTO v_id_inventario, v_cantidad;

            WHEN e_ocupado THEN
                PKG_CP_ERROR.lanzar(
                    c_modulo,
                    c_err_ocupado,
                    'El inventario del lote ' || p_id_lote
                    || ' esta siendo modificado por otra sesion. Intente de nuevo.'
                );
        END;

        IF v_cantidad + p_delta < 0 THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_insuficiente,
                'Inventario insuficiente del lote ' || p_id_lote || ' en el almacen '
                || p_id_almacen || ': disponible ' || v_cantidad
                || ', requerido ' || ABS(p_delta) || '.'
            );
        END IF;

        v_usuario_previo := PKG_CP_CONTEXTO.g_id_usuario;

        IF v_usuario_previo IS NULL THEN
            PKG_CP_CONTEXTO.g_id_usuario := p_id_usuario;
        END IF;

        BEGIN

            UPDATE CP_INVENTARIO_ALMACEN
            SET cantidad_actual = v_cantidad + p_delta,
                fecha_actualizacion = SYSTIMESTAMP
            WHERE id_inventario_almacen = v_id_inventario;

        EXCEPTION
            WHEN OTHERS THEN
                PKG_CP_CONTEXTO.g_id_usuario := v_usuario_previo;
                RAISE;
        END;

        PKG_CP_CONTEXTO.g_id_usuario := v_usuario_previo;

    END mover_stock;


    -- Guarda de que lote salio cada cantidad vendida. La bandera g_interno permite esta
    -- escritura, que de otro modo bloquea TRG_CP_VENTA_LOTE_PROTEGIDO.
    PROCEDURE registrar_lote_venta(
        p_id_detalle IN NUMBER,
        p_id_lote    IN NUMBER,
        p_cantidad   IN NUMBER
    )
    IS
    BEGIN

        g_interno := TRUE;

        INSERT INTO CP_DETALLE_VENTA_LOTE
            (id_detalle_venta_producto, id_lote_producto, cantidad)
        VALUES
            (p_id_detalle, p_id_lote, p_cantidad);

        g_interno := FALSE;

    EXCEPTION
        WHEN OTHERS THEN
            g_interno := FALSE;
            RAISE;
    END registrar_lote_venta;


    -- Salida FEFO: toma primero los lotes que vencen antes (los vencidos no se venden) y
    -- descuenta lote por lote hasta cubrir la cantidad; si no alcanza, -20273.
    -- Bloquea los lotes con FOR UPDATE WAIT 5. Solo lo llama el trigger de la linea de venta.
    PROCEDURE descontar_venta(
        p_id_factura  IN NUMBER,
        p_id_detalle  IN NUMBER,
        p_id_producto IN NUMBER,
        p_cantidad    IN NUMBER
    )
    ACCESSIBLE BY (TRIGGER TRG_CP_VENTA_LINEA_INVENTARIO)
    IS
        CURSOR c_lotes(
            p_almacen  NUMBER,
            p_producto NUMBER
        ) IS
            SELECT ia.id_lote_producto,
                   ia.cantidad_actual
            FROM CP_INVENTARIO_ALMACEN ia
            JOIN CP_LOTE_PRODUCTO lp
              ON lp.id_lote_producto = ia.id_lote_producto
            JOIN CP_DETALLE_COMPRA dc
              ON dc.id_detalle_compra = lp.id_detalle_compra
            JOIN CP_PRODUCTO_PROVEEDOR pp
              ON pp.id_producto_proveedor = dc.id_producto_proveedor
            WHERE ia.id_almacen = p_almacen
              AND pp.id_producto = p_producto
              AND ia.cantidad_actual > 0
              AND (lp.fecha_vencimiento IS NULL
                   OR lp.fecha_vencimiento >= TRUNC(SYSDATE))
            ORDER BY lp.fecha_vencimiento NULLS LAST,
                     lp.fecha_ingreso,
                     lp.id_lote_producto
            FOR UPDATE OF ia.cantidad_actual WAIT 5;

        v_id_sucursal NUMBER;
        v_id_usuario  NUMBER;
        v_id_estado   NUMBER;
        v_id_almacen  NUMBER;
        v_pendiente   NUMBER := p_cantidad;
        v_tomar       NUMBER;
    BEGIN

        SELECT id_sucursal, id_usuario, id_estado_factura_venta
        INTO v_id_sucursal, v_id_usuario, v_id_estado
        FROM CP_FACTURA_VENTA
        WHERE id_factura_venta = p_id_factura;

        IF v_id_estado = id_estado_venta(c_estado_anulada) THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_factura_anulada,
                'No se pueden agregar lineas a una factura anulada.'
            );
        END IF;

        v_id_almacen := almacen_de_sucursal(v_id_sucursal);

        BEGIN

            FOR r IN c_lotes(v_id_almacen, p_id_producto) LOOP

                EXIT WHEN v_pendiente <= 0;

                v_tomar := LEAST(r.cantidad_actual, v_pendiente);

                mover_stock(v_id_almacen, r.id_lote_producto, -v_tomar, v_id_usuario);
                registrar_lote_venta(p_id_detalle, r.id_lote_producto, v_tomar);

                v_pendiente := v_pendiente - v_tomar;

            END LOOP;

        EXCEPTION
            WHEN e_ocupado THEN
                PKG_CP_ERROR.lanzar(
                    c_modulo,
                    c_err_ocupado,
                    'El inventario del producto ' || p_id_producto
                    || ' esta siendo modificado por otra sesion. Intente de nuevo.'
                );
        END;

        IF v_pendiente > 0 THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_sin_stock_venta,
                'Inventario insuficiente del producto ' || p_id_producto
                || ' en el almacen ' || v_id_almacen
                || ': faltan ' || v_pendiente || ' unidades vigentes.'
            );
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            PKG_CP_ERROR.registrar_inesperado(c_modulo, 'linea de venta ' || p_id_detalle);
            RAISE;
    END descontar_venta;


    -- Una linea de venta ya descontada no se modifica ni se elimina (-20277);
    -- para corregirla se anula la factura.
    PROCEDURE rechazar_cambio_linea_venta
    ACCESSIBLE BY (TRIGGER TRG_CP_VENTA_LINEA_INVENTARIO)
    IS
    BEGIN

        PKG_CP_ERROR.lanzar(
            c_modulo,
            c_err_linea_inmutable,
            'Las lineas de una factura de venta no se modifican ni se eliminan; anule la factura.'
        );

    END rechazar_cambio_linea_venta;


    -- Indica si el cambio al detalle por lote lo esta haciendo este mismo paquete.
    FUNCTION es_operacion_interna RETURN BOOLEAN
    ACCESSIBLE BY (TRIGGER TRG_CP_VENTA_LOTE_PROTEGIDO)
    IS
    BEGIN

        RETURN g_interno;

    END es_operacion_interna;


    -- El detalle por lote solo lo escribe el paquete; cualquier otra escritura se rechaza (-20275).
    PROCEDURE rechazar_escritura_directa
    ACCESSIBLE BY (TRIGGER TRG_CP_VENTA_LOTE_PROTEGIDO)
    IS
    BEGIN

        PKG_CP_ERROR.lanzar(
            c_modulo,
            c_err_lote_venta_directo,
            'Los lotes de una venta los asigna el sistema; no se escriben directamente.'
        );

    END rechazar_escritura_directa;


    -- Al anular una venta devuelve al inventario, lote por lote, lo que salio de el,
    -- sin contar lo que ya volvio por devoluciones procesadas.
    PROCEDURE reintegrar_venta(
        p_id_factura  IN NUMBER,
        p_id_sucursal IN NUMBER,
        p_id_usuario  IN NUMBER
    )
    IS
        v_id_almacen NUMBER;
        v_procesada  NUMBER;
    BEGIN

        v_id_almacen := almacen_de_sucursal(p_id_sucursal);
        v_procesada  := id_estado_devolucion(c_estado_procesada);

        FOR r IN (
            SELECT dvl.id_lote_producto,
                   dvl.cantidad - NVL((
                       SELECT SUM(d.cantidad_devuelta)
                       FROM CP_DETALLE_DEVOLUCION_VENTA d
                       JOIN CP_DEVOLUCION_VENTA dv
                         ON dv.id_devolucion_venta = d.id_devolucion_venta
                       WHERE d.id_detalle_venta_lote = dvl.id_detalle_venta_lote
                         AND dv.id_estado_devolucion = v_procesada
                   ), 0) AS por_reintegrar
            FROM CP_DETALLE_VENTA_LOTE dvl
            JOIN CP_DETALLE_VENTA_PRODUCTO dvp
              ON dvp.id_detalle_venta_producto = dvl.id_detalle_venta_producto
            WHERE dvp.id_factura_venta = p_id_factura
            ORDER BY dvl.id_lote_producto, dvl.id_detalle_venta_lote
        ) LOOP

            IF r.por_reintegrar > 0 THEN
                mover_stock(v_id_almacen, r.id_lote_producto, r.por_reintegrar, p_id_usuario);
            END IF;

        END LOOP;

    END reintegrar_venta;


    -- Al anular la factura reintegra su inventario. Una factura anulada no se
    -- reactiva (-20280).
    PROCEDURE sincronizar_factura_venta(
        p_id_factura      IN NUMBER,
        p_id_sucursal     IN NUMBER,
        p_id_usuario      IN NUMBER,
        p_estado_anterior IN NUMBER,
        p_estado_nuevo    IN NUMBER
    )
    ACCESSIBLE BY (TRIGGER TRG_CP_VENTA_INVENTARIO_ESTADO)
    IS
        v_anulada NUMBER;
    BEGIN

        IF p_estado_nuevo = NVL(p_estado_anterior, -1) THEN
            RETURN;
        END IF;

        v_anulada := id_estado_venta(c_estado_anulada);

        IF p_estado_anterior = v_anulada THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_reactivar,
                'Una factura de venta anulada no se puede reactivar.'
            );
        ELSIF p_estado_nuevo = v_anulada THEN
            reintegrar_venta(p_id_factura, p_id_sucursal, p_id_usuario);
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            PKG_CP_ERROR.registrar_inesperado(c_modulo, 'factura de venta ' || p_id_factura);
            RAISE;
    END sincronizar_factura_venta;


    -- Cada lote recibido suma su cantidad al inventario del almacen de recepcion de la compra.
    -- No se aceptan lotes en una compra anulada (-20274).
    PROCEDURE ingresar_lote(
        p_id_lote           IN NUMBER,
        p_id_detalle_compra IN NUMBER,
        p_cantidad          IN NUMBER
    )
    ACCESSIBLE BY (TRIGGER TRG_CP_LOTE_INVENTARIO)
    IS
        v_id_almacen NUMBER;
        v_id_usuario NUMBER;
        v_id_estado  NUMBER;
    BEGIN

        SELECT fc.id_almacen_recepcion, fc.id_usuario, fc.id_estado_factura_compra
        INTO v_id_almacen, v_id_usuario, v_id_estado
        FROM CP_DETALLE_COMPRA dc
        JOIN CP_FACTURA_COMPRA fc
          ON fc.id_factura_compra = dc.id_factura_compra
        WHERE dc.id_detalle_compra = p_id_detalle_compra;

        IF v_id_estado = id_estado_compra(c_estado_anulada) THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_factura_anulada,
                'No se pueden registrar lotes en una factura de compra anulada.'
            );
        END IF;

        mover_stock(v_id_almacen, p_id_lote, p_cantidad, v_id_usuario);

    EXCEPTION
        WHEN OTHERS THEN
            PKG_CP_ERROR.registrar_inesperado(c_modulo, 'lote ' || p_id_lote);
            RAISE;
    END ingresar_lote;


    -- Comprueba que los lotes de una linea de compra no sumen mas que la cantidad facturada
    -- (-20276). Se ejecuta al terminar la sentencia, cuando ya existen todos los lotes.
    PROCEDURE validar_lotes_detalle(
        p_id_detalle_compra IN NUMBER
    )
    ACCESSIBLE BY (TRIGGER TRG_CP_LOTE_INVENTARIO)
    IS
        v_cantidad NUMBER;
        v_recibida NUMBER;
    BEGIN

        BEGIN

            SELECT cantidad
            INTO v_cantidad
            FROM CP_DETALLE_COMPRA
            WHERE id_detalle_compra = p_id_detalle_compra
            FOR UPDATE WAIT 5;

        EXCEPTION
            WHEN e_ocupado THEN
                PKG_CP_ERROR.lanzar(
                    c_modulo,
                    c_err_ocupado,
                    'La linea de compra ' || p_id_detalle_compra
                    || ' esta siendo modificada por otra sesion. Intente de nuevo.'
                );
        END;

        SELECT NVL(SUM(cantidad_recibida), 0)
        INTO v_recibida
        FROM CP_LOTE_PRODUCTO
        WHERE id_detalle_compra = p_id_detalle_compra;

        IF v_recibida > v_cantidad THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_lotes_exceden,
                'Los lotes de la linea de compra ' || p_id_detalle_compra
                || ' suman ' || v_recibida || ' y la linea facturo ' || v_cantidad || '.'
            );
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            PKG_CP_ERROR.registrar_inesperado(c_modulo, 'linea de compra ' || p_id_detalle_compra);
            RAISE;
    END validar_lotes_detalle;


    -- Un lote ya registrado no cambia de cantidad ni de linea y no se elimina (-20278).
    PROCEDURE rechazar_cambio_lote
    ACCESSIBLE BY (TRIGGER TRG_CP_LOTE_INVENTARIO)
    IS
    BEGIN

        PKG_CP_ERROR.lanzar(
            c_modulo,
            c_err_lote_inmutable,
            'La cantidad y la linea de un lote no se modifican y un lote no se elimina.'
        );

    END rechazar_cambio_lote;


    -- Al anular una compra saca del inventario lo recibido que aun no se haya devuelto
    -- al proveedor.
    PROCEDURE retirar_compra(
        p_id_factura IN NUMBER,
        p_id_almacen IN NUMBER,
        p_id_usuario IN NUMBER
    )
    IS
        v_procesada NUMBER;
    BEGIN

        v_procesada := id_estado_devolucion(c_estado_procesada);

        FOR r IN (
            SELECT lp.id_lote_producto,
                   lp.cantidad_recibida - NVL((
                       SELECT SUM(d.cantidad)
                       FROM CP_DETALLE_DEVOLUCION_COMPRA d
                       JOIN CP_DEVOLUCION_COMPRA dco
                         ON dco.id_devolucion_compra = d.id_devolucion_compra
                       WHERE d.id_lote_producto = lp.id_lote_producto
                         AND dco.id_estado_devolucion = v_procesada
                   ), 0) AS por_retirar
            FROM CP_LOTE_PRODUCTO lp
            JOIN CP_DETALLE_COMPRA dc
              ON dc.id_detalle_compra = lp.id_detalle_compra
            WHERE dc.id_factura_compra = p_id_factura
            ORDER BY lp.id_lote_producto
        ) LOOP

            IF r.por_retirar > 0 THEN
                mover_stock(p_id_almacen, r.id_lote_producto, -r.por_retirar, p_id_usuario);
            END IF;

        END LOOP;

    END retirar_compra;


    -- Al anular la factura retira su inventario. Una factura anulada no se
    -- reactiva (-20280).
    PROCEDURE sincronizar_factura_compra(
        p_id_factura      IN NUMBER,
        p_id_almacen      IN NUMBER,
        p_id_usuario      IN NUMBER,
        p_estado_anterior IN NUMBER,
        p_estado_nuevo    IN NUMBER
    )
    ACCESSIBLE BY (TRIGGER TRG_CP_COMPRA_INVENTARIO_ESTADO)
    IS
        v_anulada NUMBER;
    BEGIN

        IF p_estado_nuevo = NVL(p_estado_anterior, -1) THEN
            RETURN;
        END IF;

        v_anulada := id_estado_compra(c_estado_anulada);

        IF p_estado_anterior = v_anulada THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_reactivar,
                'Una factura de compra anulada no se puede reactivar.'
            );
        ELSIF p_estado_nuevo = v_anulada THEN
            retirar_compra(p_id_factura, p_id_almacen, p_id_usuario);
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            PKG_CP_ERROR.registrar_inesperado(c_modulo, 'factura de compra ' || p_id_factura);
            RAISE;
    END sincronizar_factura_compra;


    -- Reingresa al inventario lo devuelto, lote por lote, solo cuando el motivo
    -- de la linea lo permite (reingresa_inventario = 'S').
    PROCEDURE procesar_devolucion_venta(
        p_id_devolucion IN NUMBER,
        p_id_factura    IN NUMBER,
        p_id_usuario    IN NUMBER
    )
    IS
        v_id_sucursal NUMBER;
        v_id_almacen  NUMBER;
    BEGIN

        SELECT id_sucursal
        INTO v_id_sucursal
        FROM CP_FACTURA_VENTA
        WHERE id_factura_venta = p_id_factura;

        v_id_almacen := almacen_de_sucursal(v_id_sucursal);

        FOR r IN (
            SELECT dvl.id_lote_producto,
                   d.cantidad_devuelta,
                   m.reingresa_inventario
            FROM CP_DETALLE_DEVOLUCION_VENTA d
            JOIN CP_DETALLE_VENTA_LOTE dvl
              ON dvl.id_detalle_venta_lote = d.id_detalle_venta_lote
            JOIN CP_MOTIVO_DEVOLUCION m
              ON m.id_motivo_devolucion = d.id_motivo_devolucion
            WHERE d.id_devolucion_venta = p_id_devolucion
            ORDER BY dvl.id_lote_producto, d.id_detalle_devolucion_venta
        ) LOOP

            IF r.reingresa_inventario = 'S' THEN
                mover_stock(v_id_almacen, r.id_lote_producto, r.cantidad_devuelta, p_id_usuario);
            END IF;

        END LOOP;

    END procesar_devolucion_venta;


    -- Saca del inventario los lotes devueltos al proveedor.
    PROCEDURE procesar_devolucion_compra(
        p_id_devolucion IN NUMBER,
        p_id_factura    IN NUMBER,
        p_id_usuario    IN NUMBER
    )
    IS
        v_id_almacen NUMBER;
    BEGIN

        SELECT id_almacen_recepcion
        INTO v_id_almacen
        FROM CP_FACTURA_COMPRA
        WHERE id_factura_compra = p_id_factura;

        FOR r IN (
            SELECT id_lote_producto,
                   cantidad
            FROM CP_DETALLE_DEVOLUCION_COMPRA
            WHERE id_devolucion_compra = p_id_devolucion
            ORDER BY id_lote_producto, id_detalle_devolucion_compra
        ) LOOP

            mover_stock(v_id_almacen, r.id_lote_producto, -r.cantidad, p_id_usuario);

        END LOOP;

    END procesar_devolucion_compra;


    -- Al pasar la devolucion a PROCESADA mueve el inventario. Una devolucion
    -- procesada no se reabre (-20279) y no puede nacer procesada (-20281): primero
    -- se registra con su detalle y despues se procesa.
    PROCEDURE sincronizar_devolucion_venta(
        p_id_devolucion   IN NUMBER,
        p_id_factura      IN NUMBER,
        p_id_usuario      IN NUMBER,
        p_estado_anterior IN NUMBER,
        p_estado_nuevo    IN NUMBER
    )
    ACCESSIBLE BY (TRIGGER TRG_CP_DEV_VENTA_INVENTARIO)
    IS
        v_procesada NUMBER;
    BEGIN

        IF p_estado_nuevo = NVL(p_estado_anterior, -1) THEN
            RETURN;
        END IF;

        v_procesada := id_estado_devolucion(c_estado_procesada);

        IF p_estado_anterior = v_procesada THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_dev_procesada,
                'Una devolucion procesada no se puede reabrir.'
            );
        ELSIF p_estado_nuevo = v_procesada THEN

            IF p_estado_anterior IS NULL THEN
                PKG_CP_ERROR.lanzar(
                    c_modulo,
                    c_err_dev_nace_procesada,
                    'Una devolucion se registra primero y se procesa despues de cargar su detalle.'
                );
            END IF;

            procesar_devolucion_venta(p_id_devolucion, p_id_factura, p_id_usuario);

        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            PKG_CP_ERROR.registrar_inesperado(c_modulo, 'devolucion de venta ' || p_id_devolucion);
            RAISE;
    END sincronizar_devolucion_venta;


    -- Igual que sincronizar_devolucion_venta, para devoluciones de compra.
    PROCEDURE sincronizar_devolucion_compra(
        p_id_devolucion   IN NUMBER,
        p_id_factura      IN NUMBER,
        p_id_usuario      IN NUMBER,
        p_estado_anterior IN NUMBER,
        p_estado_nuevo    IN NUMBER
    )
    ACCESSIBLE BY (TRIGGER TRG_CP_DEV_COMPRA_INVENTARIO)
    IS
        v_procesada NUMBER;
    BEGIN

        IF p_estado_nuevo = NVL(p_estado_anterior, -1) THEN
            RETURN;
        END IF;

        v_procesada := id_estado_devolucion(c_estado_procesada);

        IF p_estado_anterior = v_procesada THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_dev_procesada,
                'Una devolucion procesada no se puede reabrir.'
            );
        ELSIF p_estado_nuevo = v_procesada THEN

            IF p_estado_anterior IS NULL THEN
                PKG_CP_ERROR.lanzar(
                    c_modulo,
                    c_err_dev_nace_procesada,
                    'Una devolucion se registra primero y se procesa despues de cargar su detalle.'
                );
            END IF;

            procesar_devolucion_compra(p_id_devolucion, p_id_factura, p_id_usuario);

        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            PKG_CP_ERROR.registrar_inesperado(c_modulo, 'devolucion de compra ' || p_id_devolucion);
            RAISE;
    END sincronizar_devolucion_compra;


    -- Impide cambiar el detalle de una devolucion de venta ya procesada (-20279).
    PROCEDURE validar_devolucion_venta_editable(
        p_id_devolucion IN NUMBER
    )
    ACCESSIBLE BY (TRIGGER TRG_CP_DEV_VENTA_DET_EDITABLE)
    IS
        v_estado NUMBER;
    BEGIN

        SELECT id_estado_devolucion
        INTO v_estado
        FROM CP_DEVOLUCION_VENTA
        WHERE id_devolucion_venta = p_id_devolucion;

        IF v_estado = id_estado_devolucion(c_estado_procesada) THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_dev_procesada,
                'El detalle de una devolucion procesada no se modifica.'
            );
        END IF;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END validar_devolucion_venta_editable;


    -- Impide cambiar el detalle de una devolucion de compra ya procesada (-20279).
    PROCEDURE validar_devolucion_compra_editable(
        p_id_devolucion IN NUMBER
    )
    ACCESSIBLE BY (TRIGGER TRG_CP_DEV_COMPRA_DET_EDITABLE)
    IS
        v_estado NUMBER;
    BEGIN

        SELECT id_estado_devolucion
        INTO v_estado
        FROM CP_DEVOLUCION_COMPRA
        WHERE id_devolucion_compra = p_id_devolucion;

        IF v_estado = id_estado_devolucion(c_estado_procesada) THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_dev_procesada,
                'El detalle de una devolucion procesada no se modifica.'
            );
        END IF;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END validar_devolucion_compra_editable;

END PKG_CP_INVENTARIO;
/

-- ============================================================
-- 4. TRIGGERS DE VENTAS
-- ============================================================

-- Cada linea de venta nueva descuenta el inventario por FEFO; cambiarla o borrarla se rechaza.
CREATE OR REPLACE TRIGGER TRG_CP_VENTA_LINEA_INVENTARIO
AFTER INSERT OR DELETE OR UPDATE OF cantidad, id_producto, id_factura_venta
ON CP_DETALLE_VENTA_PRODUCTO
FOR EACH ROW
BEGIN

    IF INSERTING THEN
        PKG_CP_INVENTARIO.descontar_venta(
            :NEW.id_factura_venta,
            :NEW.id_detalle_venta_producto,
            :NEW.id_producto,
            :NEW.cantidad
        );
    ELSE
        PKG_CP_INVENTARIO.rechazar_cambio_linea_venta;
    END IF;

END TRG_CP_VENTA_LINEA_INVENTARIO;
/

-- El detalle por lote solo puede escribirlo PKG_CP_INVENTARIO.
CREATE OR REPLACE TRIGGER TRG_CP_VENTA_LOTE_PROTEGIDO
BEFORE INSERT OR UPDATE OR DELETE
ON CP_DETALLE_VENTA_LOTE
FOR EACH ROW
BEGIN

    IF NOT PKG_CP_INVENTARIO.es_operacion_interna THEN
        PKG_CP_INVENTARIO.rechazar_escritura_directa;
    END IF;

END TRG_CP_VENTA_LOTE_PROTEGIDO;
/

-- Al anular una factura de venta reintegra su inventario.
CREATE OR REPLACE TRIGGER TRG_CP_VENTA_INVENTARIO_ESTADO
AFTER UPDATE OF id_estado_factura_venta
ON CP_FACTURA_VENTA
FOR EACH ROW
BEGIN

    PKG_CP_INVENTARIO.sincronizar_factura_venta(
        :NEW.id_factura_venta,
        :NEW.id_sucursal,
        :NEW.id_usuario,
        :OLD.id_estado_factura_venta,
        :NEW.id_estado_factura_venta
    );

END TRG_CP_VENTA_INVENTARIO_ESTADO;
/

-- ============================================================
-- 5. TRIGGERS DE COMPRAS
-- ============================================================

-- Trigger compuesto: cada lote nuevo suma su cantidad al inventario (por fila) y al
-- terminar la sentencia se comprueba que los lotes no excedan la linea de compra
-- (por fila aun no existirian los demas lotes del mismo INSERT).
CREATE OR REPLACE TRIGGER TRG_CP_LOTE_INVENTARIO
FOR INSERT OR UPDATE OR DELETE
ON CP_LOTE_PRODUCTO
COMPOUND TRIGGER

    TYPE t_ids IS TABLE OF NUMBER INDEX BY PLS_INTEGER;

    g_detalles t_ids;

    AFTER EACH ROW IS
    BEGIN

        IF INSERTING THEN

            PKG_CP_INVENTARIO.ingresar_lote(
                :NEW.id_lote_producto,
                :NEW.id_detalle_compra,
                :NEW.cantidad_recibida
            );

            g_detalles(:NEW.id_detalle_compra) := :NEW.id_detalle_compra;

        ELSIF DELETING THEN

            PKG_CP_INVENTARIO.rechazar_cambio_lote;

        ELSIF :NEW.cantidad_recibida <> :OLD.cantidad_recibida
              OR :NEW.id_detalle_compra <> :OLD.id_detalle_compra THEN

            PKG_CP_INVENTARIO.rechazar_cambio_lote;

        END IF;

    END AFTER EACH ROW;

    AFTER STATEMENT IS
        v_id PLS_INTEGER;
    BEGIN

        v_id := g_detalles.FIRST;

        WHILE v_id IS NOT NULL LOOP
            PKG_CP_INVENTARIO.validar_lotes_detalle(g_detalles(v_id));
            v_id := g_detalles.NEXT(v_id);
        END LOOP;

        g_detalles.DELETE;

    END AFTER STATEMENT;

END TRG_CP_LOTE_INVENTARIO;
/

-- Al anular una factura de compra retira su inventario.
CREATE OR REPLACE TRIGGER TRG_CP_COMPRA_INVENTARIO_ESTADO
AFTER UPDATE OF id_estado_factura_compra
ON CP_FACTURA_COMPRA
FOR EACH ROW
BEGIN

    PKG_CP_INVENTARIO.sincronizar_factura_compra(
        :NEW.id_factura_compra,
        :NEW.id_almacen_recepcion,
        :NEW.id_usuario,
        :OLD.id_estado_factura_compra,
        :NEW.id_estado_factura_compra
    );

END TRG_CP_COMPRA_INVENTARIO_ESTADO;
/

-- ============================================================
-- 6. TRIGGERS DE DEVOLUCIONES
-- ============================================================

-- Al pasar una devolucion de venta a PROCESADA mueve el inventario.
CREATE OR REPLACE TRIGGER TRG_CP_DEV_VENTA_INVENTARIO
AFTER INSERT OR UPDATE OF id_estado_devolucion
ON CP_DEVOLUCION_VENTA
FOR EACH ROW
BEGIN

    PKG_CP_INVENTARIO.sincronizar_devolucion_venta(
        :NEW.id_devolucion_venta,
        :NEW.id_factura_venta,
        :NEW.id_usuario,
        :OLD.id_estado_devolucion,
        :NEW.id_estado_devolucion
    );

END TRG_CP_DEV_VENTA_INVENTARIO;
/

-- Al pasar una devolucion de compra a PROCESADA mueve el inventario.
CREATE OR REPLACE TRIGGER TRG_CP_DEV_COMPRA_INVENTARIO
AFTER INSERT OR UPDATE OF id_estado_devolucion
ON CP_DEVOLUCION_COMPRA
FOR EACH ROW
BEGIN

    PKG_CP_INVENTARIO.sincronizar_devolucion_compra(
        :NEW.id_devolucion_compra,
        :NEW.id_factura_compra,
        :NEW.id_usuario,
        :OLD.id_estado_devolucion,
        :NEW.id_estado_devolucion
    );

END TRG_CP_DEV_COMPRA_INVENTARIO;
/

-- Impide cambiar el detalle de una devolucion de venta ya procesada.
CREATE OR REPLACE TRIGGER TRG_CP_DEV_VENTA_DET_EDITABLE
BEFORE INSERT OR UPDATE OR DELETE
ON CP_DETALLE_DEVOLUCION_VENTA
FOR EACH ROW
BEGIN

    IF INSERTING THEN
        PKG_CP_INVENTARIO.validar_devolucion_venta_editable(:NEW.id_devolucion_venta);
    ELSIF DELETING THEN
        PKG_CP_INVENTARIO.validar_devolucion_venta_editable(:OLD.id_devolucion_venta);
    ELSE
        PKG_CP_INVENTARIO.validar_devolucion_venta_editable(:OLD.id_devolucion_venta);
        PKG_CP_INVENTARIO.validar_devolucion_venta_editable(:NEW.id_devolucion_venta);
    END IF;

END TRG_CP_DEV_VENTA_DET_EDITABLE;
/

-- Impide cambiar el detalle de una devolucion de compra ya procesada.
CREATE OR REPLACE TRIGGER TRG_CP_DEV_COMPRA_DET_EDITABLE
BEFORE INSERT OR UPDATE OR DELETE
ON CP_DETALLE_DEVOLUCION_COMPRA
FOR EACH ROW
BEGIN

    IF INSERTING THEN
        PKG_CP_INVENTARIO.validar_devolucion_compra_editable(:NEW.id_devolucion_compra);
    ELSIF DELETING THEN
        PKG_CP_INVENTARIO.validar_devolucion_compra_editable(:OLD.id_devolucion_compra);
    ELSE
        PKG_CP_INVENTARIO.validar_devolucion_compra_editable(:OLD.id_devolucion_compra);
        PKG_CP_INVENTARIO.validar_devolucion_compra_editable(:NEW.id_devolucion_compra);
    END IF;

END TRG_CP_DEV_COMPRA_DET_EDITABLE;
/

-- ============================================================
-- 7. VERIFICACION
-- ============================================================

SELECT trigger_name, table_name, status
FROM user_triggers
WHERE trigger_name IN (
    'TRG_CP_VENTA_LINEA_INVENTARIO', 'TRG_CP_VENTA_LOTE_PROTEGIDO',
    'TRG_CP_VENTA_INVENTARIO_ESTADO', 'TRG_CP_LOTE_INVENTARIO',
    'TRG_CP_COMPRA_INVENTARIO_ESTADO', 'TRG_CP_DEV_VENTA_INVENTARIO',
    'TRG_CP_DEV_COMPRA_INVENTARIO', 'TRG_CP_DEV_VENTA_DET_EDITABLE',
    'TRG_CP_DEV_COMPRA_DET_EDITABLE'
)
ORDER BY trigger_name;

SELECT object_name, object_type, status
FROM user_objects
WHERE object_name = 'PKG_CP_INVENTARIO'
ORDER BY object_type;

SELECT name, type, line, text
FROM user_errors
WHERE name = 'PKG_CP_INVENTARIO'
   OR name IN (
    'TRG_CP_VENTA_LINEA_INVENTARIO', 'TRG_CP_VENTA_LOTE_PROTEGIDO',
    'TRG_CP_VENTA_INVENTARIO_ESTADO', 'TRG_CP_LOTE_INVENTARIO',
    'TRG_CP_COMPRA_INVENTARIO_ESTADO', 'TRG_CP_DEV_VENTA_INVENTARIO',
    'TRG_CP_DEV_COMPRA_INVENTARIO', 'TRG_CP_DEV_VENTA_DET_EDITABLE',
    'TRG_CP_DEV_COMPRA_DET_EDITABLE'
)
ORDER BY name, type, sequence;

-- ============================================================
-- 8. PRUEBAS DE INVENTARIO
-- ============================================================

DECLARE
    v_antes         NUMBER;
    v_esperados     NUMBER := 0;
    v_errores       NUMBER;
    v_id_almacen    NUMBER;
    v_id_sucursal   NUMBER;
    v_id_producto   NUMBER;
    v_id_pp         NUMBER;
    v_id_proveedor  NUMBER;
    v_id_negocio    NUMBER;
    v_id_cliente    NUMBER;
    v_id_usuario    NUMBER;
    v_activos       NUMBER;
    v_stock_previo  NUMBER;
    v_fc_registrada NUMBER;
    v_fc_anulada    NUMBER;
    v_fv_emitida    NUMBER;
    v_fv_anulada    NUMBER;
    v_ed_solicitada NUMBER;
    v_ed_procesada  NUMBER;
    v_motivo_si     NUMBER;
    v_motivo_no     NUMBER;
    v_ultima        NUMBER;
    v_codigo        NUMBER;
    v_previo        NUMBER;
    v_fc1           NUMBER;
    v_fc2           NUMBER;
    v_dc1           NUMBER;
    v_dc2           NUMBER;
    v_la            NUMBER;
    v_lb            NUMBER;
    v_lc            NUMBER;
    v_lx            NUMBER;
    v_ld            NUMBER;
    v_f1            NUMBER;
    v_f2            NUMBER;
    v_det1          NUMBER;
    v_dvl_lb        NUMBER;
    v_dvl_lc        NUMBER;
    v_dev_a         NUMBER;
    v_dev_b         NUMBER;
    v_dev_c         NUMBER;
    v_dev_d         NUMBER;
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

    FUNCTION provoca(
        p_obtenido IN NUMBER,
        p_esperado IN NUMBER
    ) RETURN BOOLEAN
    IS
    BEGIN
        v_esperados := v_esperados + 1;
        RETURN p_obtenido = p_esperado;
    END provoca;

    FUNCTION ejecutar(
        p_sql IN VARCHAR2
    ) RETURN NUMBER
    IS
    BEGIN
        v_ultimo_error := NULL;
        EXECUTE IMMEDIATE p_sql;
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            v_ultimo_error := SUBSTR(SQLERRM, 1, 300);
            RETURN SQLCODE;
    END ejecutar;

    FUNCTION stock(
        p_lote IN NUMBER
    ) RETURN NUMBER
    IS
        v_total NUMBER;
    BEGIN
        SELECT NVL(SUM(cantidad_actual), 0)
        INTO v_total
        FROM CP_INVENTARIO_ALMACEN
        WHERE id_almacen = v_id_almacen
          AND id_lote_producto = p_lote;
        RETURN v_total;
    END stock;

    FUNCTION entradas_bitacora RETURN NUMBER
    IS
        v_total NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_total
        FROM CP_BITACORA_INVENTARIO
        WHERE id_almacen = v_id_almacen
          AND id_lote_producto IN (v_la, v_lb, v_lc, v_lx)
          AND cantidad_anterior = 0
          AND id_usuario = v_id_usuario;
        RETURN v_total;
    END entradas_bitacora;

    FUNCTION lotes_de_detalle(
        p_detalle IN NUMBER
    ) RETURN NUMBER
    IS
        v_total NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_total
        FROM CP_LOTE_PRODUCTO
        WHERE id_detalle_compra = p_detalle;
        RETURN v_total;
    END lotes_de_detalle;

    FUNCTION lotes_de_venta(
        p_factura IN NUMBER
    ) RETURN NUMBER
    IS
        v_total NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_total
        FROM CP_DETALLE_VENTA_LOTE dvl
        JOIN CP_DETALLE_VENTA_PRODUCTO dvp
          ON dvp.id_detalle_venta_producto = dvl.id_detalle_venta_producto
        WHERE dvp.id_factura_venta = p_factura;
        RETURN v_total;
    END lotes_de_venta;

    FUNCTION vendido_de(
        p_factura IN NUMBER,
        p_lote    IN NUMBER
    ) RETURN NUMBER
    IS
        v_total NUMBER;
    BEGIN
        SELECT NVL(SUM(dvl.cantidad), 0)
        INTO v_total
        FROM CP_DETALLE_VENTA_LOTE dvl
        JOIN CP_DETALLE_VENTA_PRODUCTO dvp
          ON dvp.id_detalle_venta_producto = dvl.id_detalle_venta_producto
        WHERE dvp.id_factura_venta = p_factura
          AND dvl.id_lote_producto = p_lote;
        RETURN v_total;
    END vendido_de;

    FUNCTION dvl_de(
        p_factura IN NUMBER,
        p_lote    IN NUMBER
    ) RETURN NUMBER
    IS
        v_id NUMBER;
    BEGIN
        SELECT MIN(dvl.id_detalle_venta_lote)
        INTO v_id
        FROM CP_DETALLE_VENTA_LOTE dvl
        JOIN CP_DETALLE_VENTA_PRODUCTO dvp
          ON dvp.id_detalle_venta_producto = dvl.id_detalle_venta_producto
        WHERE dvp.id_factura_venta = p_factura
          AND dvl.id_lote_producto = p_lote;
        RETURN v_id;
    END dvl_de;

    FUNCTION estado_dev_compra(
        p_dev IN NUMBER
    ) RETURN NUMBER
    IS
        v_id NUMBER;
    BEGIN
        SELECT id_estado_devolucion
        INTO v_id
        FROM CP_DEVOLUCION_COMPRA
        WHERE id_devolucion_compra = p_dev;
        RETURN v_id;
    END estado_dev_compra;

    FUNCTION nueva_factura_compra(
        p_numero IN VARCHAR2
    ) RETURN NUMBER
    IS
    BEGIN
        INSERT INTO CP_FACTURA_COMPRA
            (id_proveedor, id_negocio, id_almacen_recepcion, id_usuario,
             id_estado_factura_compra, numero_factura, fecha_emision,
             fecha_recepcion, subtotal, descuento_total, impuesto_total, total)
        VALUES
            (v_id_proveedor, v_id_negocio, v_id_almacen, v_id_usuario,
             v_fc_registrada, p_numero, SYSDATE, SYSDATE, 0, 0, 0, 0)
        RETURNING id_factura_compra INTO v_ultima;
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            v_ultimo_error := SUBSTR(SQLERRM, 1, 300);
            v_ultima := NULL;
            RETURN SQLCODE;
    END nueva_factura_compra;

    FUNCTION linea_compra(
        p_factura  IN NUMBER,
        p_cantidad IN NUMBER
    ) RETURN NUMBER
    IS
    BEGIN
        INSERT INTO CP_DETALLE_COMPRA
            (id_factura_compra, id_producto_proveedor, cantidad,
             precio_costo_unitario, monto_descuento, porcentaje_impuesto,
             monto_impuesto, subtotal_linea, total_linea)
        VALUES
            (p_factura, v_id_pp, p_cantidad, 100, 0, 0, 0,
             p_cantidad * 100, p_cantidad * 100)
        RETURNING id_detalle_compra INTO v_ultima;
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            v_ultimo_error := SUBSTR(SQLERRM, 1, 300);
            v_ultima := NULL;
            RETURN SQLCODE;
    END linea_compra;

    FUNCTION nuevo_lote(
        p_detalle     IN NUMBER,
        p_numero      IN VARCHAR2,
        p_cantidad    IN NUMBER,
        p_ingreso     IN DATE,
        p_vencimiento IN DATE
    ) RETURN NUMBER
    IS
    BEGIN
        INSERT INTO CP_LOTE_PRODUCTO
            (id_detalle_compra, numero_lote, cantidad_recibida,
             fecha_ingreso, fecha_vencimiento)
        VALUES
            (p_detalle, p_numero, p_cantidad, p_ingreso, p_vencimiento)
        RETURNING id_lote_producto INTO v_ultima;
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            v_ultimo_error := SUBSTR(SQLERRM, 1, 300);
            v_ultima := NULL;
            RETURN SQLCODE;
    END nuevo_lote;

    FUNCTION nueva_factura_venta(
        p_numero IN VARCHAR2
    ) RETURN NUMBER
    IS
    BEGIN
        INSERT INTO CP_FACTURA_VENTA
            (id_cliente, id_sucursal, id_usuario, id_estado_factura_venta,
             numero_factura, fecha_emision, subtotal, descuento_total,
             impuesto_total, total)
        VALUES
            (v_id_cliente, v_id_sucursal, v_id_usuario, v_fv_emitida,
             p_numero, SYSDATE, 0, 0, 0, 0)
        RETURNING id_factura_venta INTO v_ultima;
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            v_ultimo_error := SUBSTR(SQLERRM, 1, 300);
            v_ultima := NULL;
            RETURN SQLCODE;
    END nueva_factura_venta;

    FUNCTION linea_venta(
        p_factura  IN NUMBER,
        p_cantidad IN NUMBER
    ) RETURN NUMBER
    IS
    BEGIN
        INSERT INTO CP_DETALLE_VENTA_PRODUCTO
            (id_factura_venta, id_producto, cantidad, precio_unitario,
             porcentaje_descuento, monto_descuento, porcentaje_impuesto,
             monto_impuesto, subtotal, total)
        VALUES
            (p_factura, v_id_producto, p_cantidad, 1000, 0, 0, 0, 0,
             p_cantidad * 1000, p_cantidad * 1000);
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            v_ultimo_error := SUBSTR(SQLERRM, 1, 300);
            RETURN SQLCODE;
    END linea_venta;

    FUNCTION nueva_devolucion_venta(
        p_factura IN NUMBER,
        p_estado  IN NUMBER
    ) RETURN NUMBER
    IS
    BEGIN
        INSERT INTO CP_DEVOLUCION_VENTA
            (id_factura_venta, id_estado_devolucion, id_usuario,
             fecha_devolucion, monto_total, observacion)
        VALUES
            (p_factura, p_estado, v_id_usuario, SYSDATE, 0, 'TEST-INV')
        RETURNING id_devolucion_venta INTO v_ultima;
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            v_ultimo_error := SUBSTR(SQLERRM, 1, 300);
            v_ultima := NULL;
            RETURN SQLCODE;
    END nueva_devolucion_venta;

    FUNCTION detalle_dev_venta(
        p_dev      IN NUMBER,
        p_dvl      IN NUMBER,
        p_motivo   IN NUMBER,
        p_cantidad IN NUMBER
    ) RETURN NUMBER
    IS
    BEGIN
        INSERT INTO CP_DETALLE_DEVOLUCION_VENTA
            (id_devolucion_venta, id_detalle_venta_lote, id_motivo_devolucion,
             cantidad_devuelta, monto_devolucion)
        VALUES
            (p_dev, p_dvl, p_motivo, p_cantidad, 0);
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            v_ultimo_error := SUBSTR(SQLERRM, 1, 300);
            RETURN SQLCODE;
    END detalle_dev_venta;

    FUNCTION nueva_devolucion_compra(
        p_factura IN NUMBER,
        p_estado  IN NUMBER
    ) RETURN NUMBER
    IS
    BEGIN
        INSERT INTO CP_DEVOLUCION_COMPRA
            (id_factura_compra, id_estado_devolucion, id_usuario,
             fecha_devolucion, observacion)
        VALUES
            (p_factura, p_estado, v_id_usuario, SYSDATE, 'TEST-INV')
        RETURNING id_devolucion_compra INTO v_ultima;
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            v_ultimo_error := SUBSTR(SQLERRM, 1, 300);
            v_ultima := NULL;
            RETURN SQLCODE;
    END nueva_devolucion_compra;

    FUNCTION detalle_dev_compra(
        p_dev      IN NUMBER,
        p_lote     IN NUMBER,
        p_motivo   IN NUMBER,
        p_cantidad IN NUMBER
    ) RETURN NUMBER
    IS
    BEGIN
        INSERT INTO CP_DETALLE_DEVOLUCION_COMPRA
            (id_devolucion_compra, id_lote_producto, id_motivo_devolucion,
             cantidad, monto_devolucion)
        VALUES
            (p_dev, p_lote, p_motivo, p_cantidad, 0);
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            v_ultimo_error := SUBSTR(SQLERRM, 1, 300);
            RETURN SQLCODE;
    END detalle_dev_compra;

BEGIN

    SELECT NVL(MAX(id_bitacora_error), 0) INTO v_antes FROM CP_BITACORA_ERROR;

    SELECT a.id_almacen, a.id_sucursal
    INTO v_id_almacen, v_id_sucursal
    FROM CP_ALMACEN a
    WHERE a.nombre_almacen = 'Almacen Alajuela';

    SELECT p.id_producto, pp.id_producto_proveedor, pp.id_proveedor
    INTO v_id_producto, v_id_pp, v_id_proveedor
    FROM CP_PRODUCTO p
    JOIN CP_PRODUCTO_PROVEEDOR pp
      ON pp.id_producto = p.id_producto
    WHERE p.codigo_producto = 'PROD001'
    ORDER BY pp.id_producto_proveedor
    FETCH FIRST 1 ROW ONLY;

    SELECT COUNT(*)
    INTO v_activos
    FROM CP_ALMACEN a
    JOIN CP_ESTADO e
      ON e.id_estado = a.id_estado
    WHERE a.id_sucursal = v_id_sucursal
      AND e.nombre = 'ACTIVO';

    SELECT NVL(SUM(ia.cantidad_actual), 0)
    INTO v_stock_previo
    FROM CP_INVENTARIO_ALMACEN ia
    JOIN CP_LOTE_PRODUCTO lp
      ON lp.id_lote_producto = ia.id_lote_producto
    JOIN CP_DETALLE_COMPRA dc
      ON dc.id_detalle_compra = lp.id_detalle_compra
    JOIN CP_PRODUCTO_PROVEEDOR pp2
      ON pp2.id_producto_proveedor = dc.id_producto_proveedor
    WHERE ia.id_almacen = v_id_almacen
      AND pp2.id_producto = v_id_producto;

    IF v_activos <> 1 OR v_stock_previo <> 0 THEN
        DBMS_OUTPUT.PUT_LINE(
            'Pruebas omitidas: Almacen Alajuela debe ser el unico almacen activo de su sucursal y no tener stock de PROD001.'
        );
        RETURN;
    END IF;

    SELECT MIN(id_negocio) INTO v_id_negocio FROM CP_NEGOCIO;
    SELECT MIN(id_cliente) INTO v_id_cliente FROM CP_CLIENTE;
    SELECT MIN(id_usuario) INTO v_id_usuario FROM CP_USUARIO;

    SELECT id_estado_factura_compra INTO v_fc_registrada
    FROM CP_ESTADO_FACTURA_COMPRA WHERE nombre_estado_factura = 'REGISTRADA';

    SELECT id_estado_factura_compra INTO v_fc_anulada
    FROM CP_ESTADO_FACTURA_COMPRA WHERE nombre_estado_factura = 'ANULADA';

    SELECT id_estado_factura_venta INTO v_fv_emitida
    FROM CP_ESTADO_FACTURA_VENTA WHERE nombre_estado_factura = 'EMITIDA';

    SELECT id_estado_factura_venta INTO v_fv_anulada
    FROM CP_ESTADO_FACTURA_VENTA WHERE nombre_estado_factura = 'ANULADA';

    SELECT id_estado_devolucion INTO v_ed_solicitada
    FROM CP_ESTADO_DEVOLUCION WHERE nombre_estado_devolucion = 'SOLICITADA';

    SELECT id_estado_devolucion INTO v_ed_procesada
    FROM CP_ESTADO_DEVOLUCION WHERE nombre_estado_devolucion = 'PROCESADA';

    SELECT id_motivo_devolucion INTO v_motivo_si
    FROM CP_MOTIVO_DEVOLUCION WHERE nombre_motivo_devolucion = 'PRODUCTO INCORRECTO';

    SELECT id_motivo_devolucion INTO v_motivo_no
    FROM CP_MOTIVO_DEVOLUCION WHERE nombre_motivo_devolucion = 'PRODUCTO DANADO';

    -- Compra y lotes
    v_codigo := nueva_factura_compra('TEST-INV-C1');
    v_fc1 := v_ultima;
    v_codigo := linea_compra(v_fc1, 65);
    v_dc1 := v_ultima;

    v_codigo := nuevo_lote(v_dc1, 'TEST-LA', 20, TRUNC(SYSDATE), TRUNC(SYSDATE) + 60);
    v_la := v_ultima;
    v_codigo := nuevo_lote(v_dc1, 'TEST-LB', 25, TRUNC(SYSDATE), TRUNC(SYSDATE) + 120);
    v_lb := v_ultima;
    v_codigo := nuevo_lote(v_dc1, 'TEST-LC', 15, TRUNC(SYSDATE), NULL);
    v_lc := v_ultima;
    v_codigo := nuevo_lote(v_dc1, 'TEST-LX', 5, TRUNC(SYSDATE) - 30, TRUNC(SYSDATE) - 1);
    v_lx := v_ultima;

    reportar('1. Cada lote registrado suma su cantidad al inventario',
             stock(v_la) = 20 AND stock(v_lb) = 25 AND stock(v_lc) = 15 AND stock(v_lx) = 5);

    reportar('2. Cada entrada queda en la bitacora con el usuario de la factura',
             entradas_bitacora = 4);

    reportar('3. Lotes que suman mas que la linea de compra dan -20276',
             provoca(nuevo_lote(v_dc1, 'TEST-LZ', 1, TRUNC(SYSDATE), NULL), -20276)
             AND lotes_de_detalle(v_dc1) = 4);

    reportar('4. Modificar la cantidad de un lote da -20278',
             provoca(ejecutar('UPDATE CP_LOTE_PRODUCTO SET cantidad_recibida = 1 WHERE id_lote_producto = ' || v_la), -20278)
             AND stock(v_la) = 20);

    reportar('5. Eliminar un lote con inventario es rechazado',
             ejecutar('DELETE FROM CP_LOTE_PRODUCTO WHERE id_lote_producto = ' || v_la) IN (-2292, -20278)
             AND stock(v_la) = 20);

    reportar('6. Corregir la fecha de vencimiento de un lote si se permite',
             ejecutar('UPDATE CP_LOTE_PRODUCTO SET fecha_vencimiento = fecha_vencimiento + 1 WHERE id_lote_producto = ' || v_la) = 0);

    -- Ventas con FEFO
    v_codigo := nueva_factura_venta('TEST-INV-V1');
    v_f1 := v_ultima;
    v_codigo := linea_venta(v_f1, 30);

    reportar('7. Venta de 30 sale primero del lote que vence antes',
             v_codigo = 0 AND stock(v_la) = 0 AND stock(v_lb) = 15);

    reportar('8. La venta registra los lotes usados: 20 del primero y 10 del segundo',
             lotes_de_venta(v_f1) = 2 AND vendido_de(v_f1, v_la) = 20 AND vendido_de(v_f1, v_lb) = 10);

    reportar('9. El lote vencido no se toca',
             stock(v_lx) = 5);

    v_codigo := nueva_factura_venta('TEST-INV-V2');
    v_f2 := v_ultima;

    reportar('10. Venta mayor al inventario da -20273 y no cambia nada',
             provoca(linea_venta(v_f2, 100000), -20273)
             AND stock(v_lb) = 15 AND stock(v_lc) = 15 AND lotes_de_venta(v_f2) = 0);

    v_codigo := linea_venta(v_f2, 20);

    reportar('11. Venta de 20 pasa al siguiente lote y el sin vencimiento va al final',
             v_codigo = 0 AND stock(v_lb) = 0 AND stock(v_lc) = 10
             AND vendido_de(v_f2, v_lb) = 15 AND vendido_de(v_f2, v_lc) = 5);

    reportar('12. Pedir 11 con 10 vigentes da -20273 (el vencido no cuenta)',
             provoca(linea_venta(v_f2, 11), -20273) AND stock(v_lx) = 5 AND stock(v_lc) = 10);

    SELECT MIN(id_detalle_venta_producto)
    INTO v_det1
    FROM CP_DETALLE_VENTA_PRODUCTO
    WHERE id_factura_venta = v_f1;

    reportar('13. Modificar la cantidad de una linea de venta da -20277',
             provoca(ejecutar('UPDATE CP_DETALLE_VENTA_PRODUCTO SET cantidad = 1 WHERE id_detalle_venta_producto = ' || v_det1), -20277));

    reportar('14. Eliminar una linea de venta con lotes es rechazado',
             ejecutar('DELETE FROM CP_DETALLE_VENTA_PRODUCTO WHERE id_detalle_venta_producto = ' || v_det1) IN (-2292, -20277)
             AND lotes_de_venta(v_f1) = 2);

    reportar('15. Escribir directo en CP_DETALLE_VENTA_LOTE da -20275',
             provoca(ejecutar('INSERT INTO CP_DETALLE_VENTA_LOTE (id_detalle_venta_producto, id_lote_producto, cantidad) VALUES ('
                              || v_det1 || ', ' || v_la || ', 1)'), -20275));

    -- Devoluciones de venta
    v_dvl_lc := dvl_de(v_f2, v_lc);
    v_dvl_lb := dvl_de(v_f2, v_lb);

    v_codigo := nueva_devolucion_venta(v_f2, v_ed_solicitada);
    v_dev_a := v_ultima;
    v_codigo := detalle_dev_venta(v_dev_a, v_dvl_lc, v_motivo_si, 2);
    v_previo := stock(v_lc);
    v_codigo := ejecutar('UPDATE CP_DEVOLUCION_VENTA SET id_estado_devolucion = ' || v_ed_procesada
                         || ' WHERE id_devolucion_venta = ' || v_dev_a);

    reportar('16. Devolucion solicitada no mueve inventario; procesada con motivo S suma',
             v_previo = 10 AND v_codigo = 0 AND stock(v_lc) = 12);

    v_codigo := nueva_devolucion_venta(v_f2, v_ed_solicitada);
    v_dev_b := v_ultima;
    v_codigo := detalle_dev_venta(v_dev_b, v_dvl_lb, v_motivo_no, 1);
    v_codigo := ejecutar('UPDATE CP_DEVOLUCION_VENTA SET id_estado_devolucion = ' || v_ed_procesada
                         || ' WHERE id_devolucion_venta = ' || v_dev_b);

    reportar('17. Devolucion por producto danado no vuelve al inventario',
             v_codigo = 0 AND stock(v_lb) = 0);

    reportar('18. Modificar el detalle de una devolucion procesada da -20279',
             provoca(ejecutar('UPDATE CP_DETALLE_DEVOLUCION_VENTA SET cantidad_devuelta = 1 WHERE id_devolucion_venta = ' || v_dev_a), -20279));

    reportar('19. Una devolucion no puede nacer PROCESADA (-20281)',
             provoca(nueva_devolucion_venta(v_f2, v_ed_procesada), -20281));

    reportar('20. Reabrir una devolucion procesada da -20279',
             provoca(ejecutar('UPDATE CP_DEVOLUCION_VENTA SET id_estado_devolucion = ' || v_ed_solicitada
                              || ' WHERE id_devolucion_venta = ' || v_dev_a), -20279));

    -- Anulacion de ventas
    reportar('21. Anular la factura 1 devuelve al inventario lo que salio',
             ejecutar('UPDATE CP_FACTURA_VENTA SET id_estado_factura_venta = ' || v_fv_anulada
                      || ' WHERE id_factura_venta = ' || v_f1) = 0
             AND stock(v_la) = 20 AND stock(v_lb) = 10);

    reportar('22. Reactivar una factura anulada da -20280',
             provoca(ejecutar('UPDATE CP_FACTURA_VENTA SET id_estado_factura_venta = ' || v_fv_emitida
                              || ' WHERE id_factura_venta = ' || v_f1), -20280));

    reportar('23. Agregar una linea a una factura anulada da -20274',
             provoca(linea_venta(v_f1, 1), -20274) AND stock(v_la) = 20);

    reportar('24. Anular la factura 2 reintegra lo vendido menos lo devuelto',
             ejecutar('UPDATE CP_FACTURA_VENTA SET id_estado_factura_venta = ' || v_fv_anulada
                      || ' WHERE id_factura_venta = ' || v_f2) = 0
             AND stock(v_lb) = 24 AND stock(v_lc) = 15);

    -- Devoluciones de compra
    v_codigo := nueva_devolucion_compra(v_fc1, v_ed_solicitada);
    v_dev_c := v_ultima;
    v_codigo := detalle_dev_compra(v_dev_c, v_lc, v_motivo_no, 4);
    v_codigo := ejecutar('UPDATE CP_DEVOLUCION_COMPRA SET id_estado_devolucion = ' || v_ed_procesada
                         || ' WHERE id_devolucion_compra = ' || v_dev_c);

    reportar('25. Devolucion de compra procesada baja el inventario',
             v_codigo = 0 AND stock(v_lc) = 11);

    v_codigo := nueva_devolucion_compra(v_fc1, v_ed_solicitada);
    v_dev_d := v_ultima;
    v_codigo := detalle_dev_compra(v_dev_d, v_lb, v_motivo_no, 25);

    reportar('26. Devolver mas de lo que hay da -20272 y la devolucion sigue solicitada',
             provoca(ejecutar('UPDATE CP_DEVOLUCION_COMPRA SET id_estado_devolucion = ' || v_ed_procesada
                              || ' WHERE id_devolucion_compra = ' || v_dev_d), -20272)
             AND estado_dev_compra(v_dev_d) = v_ed_solicitada AND stock(v_lb) = 24);

    -- Anulacion de compras
    reportar('27. Anular una compra con lotes ya vendidos da -20272 y no cambia nada',
             provoca(ejecutar('UPDATE CP_FACTURA_COMPRA SET id_estado_factura_compra = ' || v_fc_anulada
                              || ' WHERE id_factura_compra = ' || v_fc1), -20272)
             AND stock(v_la) = 20 AND stock(v_lb) = 24);

    v_codigo := nueva_factura_compra('TEST-INV-C2');
    v_fc2 := v_ultima;
    v_codigo := linea_compra(v_fc2, 10);
    v_dc2 := v_ultima;
    v_codigo := nuevo_lote(v_dc2, 'TEST-LD', 10, TRUNC(SYSDATE), NULL);
    v_ld := v_ultima;
    v_previo := stock(v_ld);

    reportar('28. Anular una compra sin salidas retira sus lotes del inventario',
             v_previo = 10
             AND ejecutar('UPDATE CP_FACTURA_COMPRA SET id_estado_factura_compra = ' || v_fc_anulada
                          || ' WHERE id_factura_compra = ' || v_fc2) = 0
             AND stock(v_ld) = 0);

    reportar('29. Registrar un lote en una compra anulada da -20274',
             provoca(nuevo_lote(v_dc2, 'TEST-LE', 1, TRUNC(SYSDATE), NULL), -20274));

    ROLLBACK;

    SELECT COUNT(*)
    INTO v_errores
    FROM CP_BITACORA_ERROR
    WHERE id_bitacora_error > v_antes
      AND modulo = 'INVENTARIO';

    reportar('30. Los ' || v_esperados || ' errores provocados quedaron en la bitacora',
             v_errores >= v_esperados);

    DELETE FROM CP_BITACORA_ERROR
    WHERE id_bitacora_error > v_antes
      AND modulo = 'INVENTARIO';

    COMMIT;

END;
/
