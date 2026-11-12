-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- BASE DE DATOS: Oracle 21c
-- SCRIPT: 27_negocio_cierre.sql
-- DESCRIPCION: Cierre diario automatico. Paquete PKG_CP_CIERRE:
--              por cada sucursal y fecha suma las ventas (sin las
--              anuladas) y las devoluciones procesadas, con el
--              detalle por cajero, y guarda el resultado en
--              CP_CIERRE_DIARIO y CP_DETALLE_CIERRE_DIARIO.
--              Repetir el cierre de una fecha lo recalcula, no lo
--              duplica. El cierre masivo (el que corre el job) deja
--              en cola un solo aviso agrupado, con todas las
--              sucursales del dia, para el coordinador y el gerente,
--              por medio de PKG_CP_AVISO (script 26A).
--
-- EJECUTAR COMO: CP_POS en XEPDB1 (despues de los scripts 15, 26 y 26A). Incluye
--                el job diario (00:30) y lo lanza una vez al final.
--                Se puede volver a ejecutar completo las veces
--                que haga falta.
--
-- ERRORES PROPIOS (tramo -20300 a -20309):
--   -20300 la sucursal no existe
--   -20301 no se puede cerrar una fecha futura
--   -20302 el cierre de esa sucursal y fecha esta siendo
--          modificado por otra sesion
--   -20303 el cierre masivo termino con sucursales que fallaron
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED

-- ============================================================
-- 1. PAQUETE PKG_CP_CIERRE (ESPECIFICACION)
-- ============================================================

CREATE OR REPLACE PACKAGE PKG_CP_CIERRE AUTHID DEFINER AS

    -- Cierra el dia p_fecha de una sucursal y devuelve el id del
    -- cierre. Con p_commit => FALSE deja la transaccion abierta.
    PROCEDURE close_branch_day(
        p_id_sucursal IN  NUMBER,
        p_fecha       IN  DATE,
        p_id_cierre   OUT NUMBER,
        p_commit      IN  BOOLEAN DEFAULT TRUE
    );

    -- Cierra todas las sucursales (sin fecha, el dia anterior) y deja
    -- en cola un solo aviso con todos los cierres del dia para el
    -- coordinador y el gerente. Si una sucursal falla sigue con las
    -- demas, la menciona en el aviso y al final lanza -20303. Con
    -- p_commit => FALSE no confirma nada (lo usan las pruebas).
    PROCEDURE close_all_branches(
        p_fecha  IN DATE    DEFAULT TRUNC(SYSDATE) - 1,
        p_commit IN BOOLEAN DEFAULT TRUE
    );

    -- Arma el texto del cierre de una sucursal (para consultarlo).
    FUNCTION build_message(
        p_id_cierre IN NUMBER
    ) RETURN VARCHAR2;

    -- Arma el aviso agrupado del dia: todos los cierres de esa fecha.
    FUNCTION build_day_message(
        p_fecha IN DATE
    ) RETURN CLOB;

END PKG_CP_CIERRE;
/

-- ============================================================
-- 2. PAQUETE PKG_CP_CIERRE (CUERPO)
-- ============================================================

CREATE OR REPLACE PACKAGE BODY PKG_CP_CIERRE AS

    c_modulo CONSTANT VARCHAR2(20) := 'CIERRE';

    -- Tipo con el que el aviso queda en CP_NOTIFICACION
    c_tipo_aviso CONSTANT VARCHAR2(50) := 'CIERRE_DIARIO';

    c_estado_venta_anulada CONSTANT VARCHAR2(30) := 'ANULADA';
    c_estado_dev_procesada CONSTANT VARCHAR2(30) := 'PROCESADA';

    c_err_sucursal  CONSTANT PLS_INTEGER := -20300;
    c_err_futura    CONSTANT PLS_INTEGER := -20301;
    c_err_ocupado   CONSTANT PLS_INTEGER := -20302;
    c_err_parcial   CONSTANT PLS_INTEGER := -20303;

    -- ORA-30006: recurso ocupado (vencio el WAIT del FOR UPDATE)
    e_ocupado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_ocupado, -30006);


    -- Verifica que la sucursal exista y que la fecha no sea futura.
    PROCEDURE validate_request(
        p_id_sucursal IN NUMBER,
        p_day         IN DATE
    )
    IS
        v_exists NUMBER;
    BEGIN

        SELECT COUNT(*)
        INTO v_exists
        FROM CP_SUCURSAL
        WHERE id_sucursal = p_id_sucursal;

        IF v_exists = 0 THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_sucursal,
                'La sucursal ' || p_id_sucursal || ' no existe.'
            );
        END IF;

        -- Se permite cerrar el dia de hoy (para demostrarlo), no uno futuro
        IF p_day > TRUNC(SYSDATE) THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_futura,
                'No se puede cerrar una fecha futura: '
                || TO_CHAR(p_day, 'DD/MM/YYYY') || '.'
            );
        END IF;

    END validate_request;


    -- Crea el encabezado del cierre. Si ya existe uno para esa
    -- sucursal y fecha lo bloquea y borra su detalle, para recalcularlo
    -- sin duplicar filas (la llave unica es sucursal + fecha).
    FUNCTION open_closing(
        p_id_sucursal IN NUMBER,
        p_day         IN DATE
    ) RETURN NUMBER
    IS
        v_id_cierre CP_CIERRE_DIARIO.id_cierre_diario%TYPE;
    BEGIN

        BEGIN

            INSERT INTO CP_CIERRE_DIARIO (id_sucursal, fecha_cierre)
            VALUES (p_id_sucursal, p_day)
            RETURNING id_cierre_diario INTO v_id_cierre;

        EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN

                SELECT id_cierre_diario
                INTO v_id_cierre
                FROM CP_CIERRE_DIARIO
                WHERE id_sucursal = p_id_sucursal
                  AND fecha_cierre = p_day
                FOR UPDATE WAIT 5;

                DELETE FROM CP_DETALLE_CIERRE_DIARIO
                WHERE id_cierre_diario = v_id_cierre;

        END;

        RETURN v_id_cierre;

    EXCEPTION
        WHEN e_ocupado THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_ocupado,
                'El cierre de la sucursal ' || p_id_sucursal || ' del '
                || TO_CHAR(p_day, 'DD/MM/YYYY')
                || ' esta siendo modificado por otra sesion. Intente de nuevo.'
            );
    END open_closing;


    -- Llena el detalle: una fila por cajero con sus ventas y devoluciones.
    -- Ventas: facturas de la sucursal emitidas ese dia, sin las anuladas
    -- (una factura DEVUELTA sigue contando como venta; su devolucion se
    -- resta aparte). Devoluciones: las PROCESADAS de ese dia; la sucursal
    -- sale de la factura porque la devolucion no la guarda, y el cajero
    -- es quien registro la devolucion. Se usa un rango de fechas (>= y <)
    -- en lugar de TRUNC(columna) para no inutilizar un indice.
    PROCEDURE fill_detail(
        p_id_cierre   IN NUMBER,
        p_id_sucursal IN NUMBER,
        p_day         IN DATE
    )
    IS
    BEGIN

        INSERT INTO CP_DETALLE_CIERRE_DIARIO (
            id_cierre_diario,
            id_usuario,
            cantidad_ventas,
            cantidad_devoluciones,
            unidades_vendidas,
            unidades_devueltas,
            total_ventas,
            total_devoluciones
        )
        SELECT p_id_cierre,
               NVL(s.id_usuario, r.id_usuario),
               NVL(s.invoice_count, 0),
               NVL(r.return_count, 0),
               NVL(s.units_sold, 0),
               NVL(r.units_returned, 0),
               NVL(s.total_sales, 0),
               NVL(r.total_returns, 0)
        FROM (
                SELECT fv.id_usuario,
                       COUNT(*)      AS invoice_count,
                       SUM(fv.total) AS total_sales,
                       SUM((SELECT SUM(dv.cantidad)
                            FROM CP_DETALLE_VENTA_PRODUCTO dv
                            WHERE dv.id_factura_venta = fv.id_factura_venta)
                       )             AS units_sold
                FROM CP_FACTURA_VENTA fv
                JOIN CP_ESTADO_FACTURA_VENTA ef
                  ON ef.id_estado_factura_venta = fv.id_estado_factura_venta
                WHERE fv.id_sucursal = p_id_sucursal
                  AND fv.fecha_emision >= p_day
                  AND fv.fecha_emision <  p_day + 1
                  AND ef.nombre_estado_factura <> c_estado_venta_anulada
                GROUP BY fv.id_usuario
             ) s
        FULL OUTER JOIN (
                SELECT dev.id_usuario,
                       COUNT(*)            AS return_count,
                       SUM(dev.monto_total) AS total_returns,
                       SUM((SELECT SUM(dd.cantidad_devuelta)
                            FROM CP_DETALLE_DEVOLUCION_VENTA dd
                            WHERE dd.id_devolucion_venta = dev.id_devolucion_venta)
                       )                   AS units_returned
                FROM CP_DEVOLUCION_VENTA dev
                JOIN CP_ESTADO_DEVOLUCION ed
                  ON ed.id_estado_devolucion = dev.id_estado_devolucion
                JOIN CP_FACTURA_VENTA fv
                  ON fv.id_factura_venta = dev.id_factura_venta
                WHERE fv.id_sucursal = p_id_sucursal
                  AND dev.fecha_devolucion >= p_day
                  AND dev.fecha_devolucion <  p_day + 1
                  AND ed.nombre_estado_devolucion = c_estado_dev_procesada
                GROUP BY dev.id_usuario
             ) r
          ON r.id_usuario = s.id_usuario;

    END fill_detail;


    -- El encabezado se calcula sumando el detalle: asi los totales del
    -- cierre y los del detalle nunca pueden diferir (una sola fuente).
    PROCEDURE refresh_header(
        p_id_cierre IN NUMBER
    )
    IS
    BEGIN

        UPDATE CP_CIERRE_DIARIO c
        SET c.fecha_ejecucion = SYSTIMESTAMP,
            (c.cantidad_ventas,
             c.cantidad_devoluciones,
             c.unidades_vendidas,
             c.unidades_devueltas,
             c.total_ventas,
             c.total_devoluciones) =
            (SELECT NVL(SUM(d.cantidad_ventas), 0),
                    NVL(SUM(d.cantidad_devoluciones), 0),
                    NVL(SUM(d.unidades_vendidas), 0),
                    NVL(SUM(d.unidades_devueltas), 0),
                    NVL(SUM(d.total_ventas), 0),
                    NVL(SUM(d.total_devoluciones), 0)
             FROM CP_DETALLE_CIERRE_DIARIO d
             WHERE d.id_cierre_diario = c.id_cierre_diario)
        WHERE c.id_cierre_diario = p_id_cierre;

    END refresh_header;


    FUNCTION build_message(
        p_id_cierre IN NUMBER
    ) RETURN VARCHAR2
    IS
        c_nls CONSTANT VARCHAR2(40) := 'NLS_NUMERIC_CHARACTERS=''.,''';
        c_fmt CONSTANT VARCHAR2(30) := 'FM999,999,999,990.00';

        v_branch   CP_SUCURSAL.nombre_sucursal%TYPE;
        v_day      CP_CIERRE_DIARIO.fecha_cierre%TYPE;
        v_header   CP_CIERRE_DIARIO%ROWTYPE;
        v_text     VARCHAR2(32767);
    BEGIN

        SELECT *
        INTO v_header
        FROM CP_CIERRE_DIARIO
        WHERE id_cierre_diario = p_id_cierre;

        SELECT nombre_sucursal
        INTO v_branch
        FROM CP_SUCURSAL
        WHERE id_sucursal = v_header.id_sucursal;

        v_day := v_header.fecha_cierre;

        v_text := 'Cierre diario de ' || v_branch || ' del '
            || TO_CHAR(v_day, 'DD/MM/YYYY') || CHR(10)
            || 'Ventas: ' || v_header.cantidad_ventas || ' facturas, '
            || TO_CHAR(v_header.unidades_vendidas, c_fmt, c_nls)
            || ' unidades, CRC ' || TO_CHAR(v_header.total_ventas, c_fmt, c_nls) || CHR(10)
            || 'Devoluciones: ' || v_header.cantidad_devoluciones || ', '
            || TO_CHAR(v_header.unidades_devueltas, c_fmt, c_nls)
            || ' unidades, CRC ' || TO_CHAR(v_header.total_devoluciones, c_fmt, c_nls) || CHR(10)
            || 'Neto: CRC '
            || TO_CHAR(v_header.total_ventas - v_header.total_devoluciones, c_fmt, c_nls)
            || CHR(10) || CHR(10) || 'Detalle por cajero:' || CHR(10);

        FOR r IN (
            SELECT u.nombre_usuario, d.*
            FROM CP_DETALLE_CIERRE_DIARIO d
            JOIN CP_USUARIO u ON u.id_usuario = d.id_usuario
            WHERE d.id_cierre_diario = p_id_cierre
            ORDER BY u.nombre_usuario
        ) LOOP
            v_text := v_text || '- ' || r.nombre_usuario || ': '
                || r.cantidad_ventas || ' facturas, '
                || TO_CHAR(r.unidades_vendidas, c_fmt, c_nls)
                || ' unidades, CRC ' || TO_CHAR(r.total_ventas, c_fmt, c_nls)
                || '; devoluciones ' || r.cantidad_devoluciones || ', '
                || TO_CHAR(r.unidades_devueltas, c_fmt, c_nls)
                || ' unidades, CRC ' || TO_CHAR(r.total_devoluciones, c_fmt, c_nls)
                || CHR(10);
        END LOOP;

        RETURN v_text;

    END build_message;


    FUNCTION build_day_message(
        p_fecha IN DATE
    ) RETURN CLOB
    IS
        v_day   DATE := TRUNC(p_fecha);
        v_count PLS_INTEGER := 0;
        v_text  CLOB;
    BEGIN

        FOR r IN (
            SELECT c.id_cierre_diario
            FROM CP_CIERRE_DIARIO c
            JOIN CP_SUCURSAL s
              ON s.id_sucursal = c.id_sucursal
            WHERE c.fecha_cierre = v_day
            ORDER BY s.nombre_sucursal
        ) LOOP
            v_count := v_count + 1;
            v_text := v_text || CHR(10) || RPAD('-', 60, '-') || CHR(10)
                      || build_message(r.id_cierre_diario);
        END LOOP;

        RETURN 'Cierre diario del ' || TO_CHAR(v_day, 'DD/MM/YYYY')
               || ': ' || v_count || ' sucursal(es)' || CHR(10)
               || CASE WHEN v_count = 0
                       THEN 'No hay cierres registrados para esa fecha.' || CHR(10)
                  END
               || v_text;

    END build_day_message;


    PROCEDURE close_branch_day(
        p_id_sucursal IN  NUMBER,
        p_fecha       IN  DATE,
        p_id_cierre   OUT NUMBER,
        p_commit      IN  BOOLEAN DEFAULT TRUE
    )
    IS
        v_day DATE := TRUNC(p_fecha);
    BEGIN

        SAVEPOINT sp_close_branch_day;

        validate_request(p_id_sucursal, v_day);

        p_id_cierre := open_closing(p_id_sucursal, v_day);
        fill_detail(p_id_cierre, p_id_sucursal, v_day);
        refresh_header(p_id_cierre);
        -- El aviso no sale aqui sino en close_all_branches: uno por dia
        -- con todas las sucursales, no uno por sucursal.

        IF p_commit THEN
            COMMIT;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            -- Se deshace solo lo de este cierre; lo anterior de la sesion queda
            ROLLBACK TO SAVEPOINT sp_close_branch_day;
            p_id_cierre := NULL;
            PKG_CP_ERROR.registrar_inesperado(
                c_modulo,
                'sucursal=' || p_id_sucursal || ' fecha='
                || TO_CHAR(p_fecha, 'DD/MM/YYYY')
            );
            RAISE;
    END close_branch_day;


    PROCEDURE close_all_branches(
        p_fecha  IN DATE    DEFAULT TRUNC(SYSDATE) - 1,
        p_commit IN BOOLEAN DEFAULT TRUE
    )
    IS
        v_id_cierre NUMBER;
        v_failed    PLS_INTEGER := 0;
        v_message   CLOB;
    BEGIN

        FOR r IN (SELECT id_sucursal FROM CP_SUCURSAL ORDER BY id_sucursal) LOOP
            BEGIN
                -- Cada sucursal confirma por separado: si una falla, las otras se guardan
                close_branch_day(r.id_sucursal, p_fecha, v_id_cierre, p_commit);
            EXCEPTION
                WHEN OTHERS THEN
                    -- close_branch_day ya dejo el error en la bitacora
                    v_failed := v_failed + 1;
            END;
        END LOOP;

        -- Un solo aviso agrupado por dia. Va antes del error parcial para
        -- que las sucursales que si cerraron se informen igual. Ni armar
        -- el texto ni encolarlo puede detener el cierre: queue_notice no
        -- lanza errores y un fallo al armar el texto solo se registra.
        BEGIN
            v_message := build_day_message(p_fecha);
        EXCEPTION
            WHEN OTHERS THEN
                PKG_CP_ERROR.registrar_inesperado(
                    c_modulo,
                    'texto del aviso del ' || TO_CHAR(TRUNC(p_fecha), 'DD/MM/YYYY')
                );
                v_message := NULL;
        END;

        IF v_message IS NOT NULL THEN
            IF v_failed > 0 THEN
                v_message := v_message || CHR(10) || 'ATENCION: ' || v_failed
                    || ' sucursal(es) no se pudieron cerrar. Revise CP_BITACORA_ERROR (modulo CIERRE).'
                    || CHR(10);
            END IF;

            PKG_CP_AVISO.queue_notice(
                p_type    => c_tipo_aviso,
                p_subject => 'Cierre diario del ' || TO_CHAR(TRUNC(p_fecha), 'DD/MM/YYYY'),
                p_message => v_message
            );
        END IF;

        IF p_commit THEN
            COMMIT;
        END IF;

        -- Se avisa al final para que el job quede marcado como fallido
        IF v_failed > 0 THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_parcial,
                'El cierre del ' || TO_CHAR(TRUNC(p_fecha), 'DD/MM/YYYY')
                || ' fallo en ' || v_failed || ' sucursal(es). Revise CP_BITACORA_ERROR.'
            );
        END IF;

    END close_all_branches;

END PKG_CP_CIERRE;
/

SHOW ERRORS PACKAGE BODY PKG_CP_CIERRE

-- ============================================================
-- 3. PRUEBAS DEL CIERRE
-- ============================================================
-- Todas deben salir OK. Se ejecutan como CP_POS con p_commit => FALSE
-- y todo se deshace con ROLLBACK, salvo la ultima parte (cierre
-- masivo), que confirma de verdad y limpia lo que creo. Las ventas y
-- la devolucion se registran con la API de facturacion (script 25),
-- asi se prueba el cierre sobre datos que los triggers ya procesaron.
-- Como el dia de hoy puede traer datos reales, se mide el cambio
-- (cierre antes de las ventas de prueba contra cierre despues).
-- Solo se borran de la bitacora los errores provocados a proposito.
-- Los avisos se apagan durante las pruebas (PKG_CP_AVISO.set_enabled)
-- para no dejar correos reales en cola; la prueba 19 los enciende con
-- el cierre masivo sin confirmar, y el ROLLBACK lo deshace.

DECLARE
    v_antes       NUMBER;
    v_notif_antes NUMBER;
    v_ok          NUMBER := 0;
    v_falla       NUMBER := 0;
    v_status      VARCHAR2(12);
    v_day_text    CLOB;
    v_notices     NUMBER;

    v_almacen     NUMBER;
    v_sucursal    NUMBER;
    v_producto    NUMBER;
    v_cliente     NUMBER;
    v_user1       NUMBER;
    v_user2       NUMBER;
    v_motivo      NUMBER;
    v_branch_name CP_SUCURSAL.nombre_sucursal%TYPE;
    v_user2_name  CP_USUARIO.nombre_usuario%TYPE;

    v_today       DATE := TRUNC(SYSDATE);
    v_empty_day   CONSTANT DATE := DATE '2000-01-02';
    v_mass_day    CONSTANT DATE := DATE '2000-01-03';
    v_stamp       VARCHAR2(20) := TO_CHAR(SYSDATE, 'MMDDHH24MISS');

    v_id_empty    NUMBER;
    v_id_empty2   NUMBER;
    v_id_base     NUMBER;
    v_id_after    NUMBER;
    v_id_yest     NUMBER;
    v_f1          NUMBER;
    v_f2          NUMBER;
    v_f3          NUMBER;
    v_dev         NUMBER;
    v_dev_amount  NUMBER;
    v_dvl         NUMBER;
    v_code        NUMBER;
    v_codes_ok    BOOLEAN;
    v_count       NUMBER;
    v_expected    NUMBER;
    v_branches    NUMBER;
    v_text        VARCHAR2(32767);

    v_empty       CP_CIERRE_DIARIO%ROWTYPE;
    v_base        CP_CIERRE_DIARIO%ROWTYPE;
    v_after       CP_CIERRE_DIARIO%ROWTYPE;
    v_yest        CP_CIERRE_DIARIO%ROWTYPE;
    v_base_u1     CP_DETALLE_CIERRE_DIARIO%ROWTYPE;
    v_base_u2     CP_DETALLE_CIERRE_DIARIO%ROWTYPE;
    v_after_u1    CP_DETALLE_CIERRE_DIARIO%ROWTYPE;
    v_after_u2    CP_DETALLE_CIERRE_DIARIO%ROWTYPE;

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

    -- Consultas de apoyo ------------------------------------------------

    FUNCTION header_of(
        p_id IN NUMBER
    ) RETURN CP_CIERRE_DIARIO%ROWTYPE
    IS
        v_row CP_CIERRE_DIARIO%ROWTYPE;
    BEGIN
        SELECT * INTO v_row FROM CP_CIERRE_DIARIO WHERE id_cierre_diario = p_id;
        RETURN v_row;
    END header_of;

    -- Si el cajero no tiene fila en el detalle, devuelve ceros
    FUNCTION detail_of(
        p_id   IN NUMBER,
        p_user IN NUMBER
    ) RETURN CP_DETALLE_CIERRE_DIARIO%ROWTYPE
    IS
        v_row CP_DETALLE_CIERRE_DIARIO%ROWTYPE;
    BEGIN
        SELECT * INTO v_row
        FROM CP_DETALLE_CIERRE_DIARIO
        WHERE id_cierre_diario = p_id AND id_usuario = p_user;
        RETURN v_row;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_row.cantidad_ventas := 0;
            v_row.cantidad_devoluciones := 0;
            v_row.unidades_vendidas := 0;
            v_row.unidades_devueltas := 0;
            v_row.total_ventas := 0;
            v_row.total_devoluciones := 0;
            RETURN v_row;
    END detail_of;

    FUNCTION count_headers(
        p_branch IN NUMBER,
        p_day    IN DATE
    ) RETURN NUMBER
    IS
        v_total NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_total
        FROM CP_CIERRE_DIARIO
        WHERE id_sucursal = p_branch AND fecha_cierre = p_day;
        RETURN v_total;
    END count_headers;

    -- Envoltorios de la API: devuelven 0 o el codigo de error ----------

    FUNCTION close_day(
        p_branch IN  NUMBER,
        p_day    IN  DATE,
        p_id     OUT NUMBER
    ) RETURN NUMBER
    IS
    BEGIN
        PKG_CP_CIERRE.close_branch_day(
            p_id_sucursal => p_branch,
            p_fecha       => p_day,
            p_id_cierre   => p_id,
            p_commit      => FALSE
        );
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN SQLCODE;
    END close_day;

    FUNCTION sell(
        p_number IN  VARCHAR2,
        p_qty    IN  NUMBER,
        p_price  IN  NUMBER,
        p_id     OUT NUMBER
    ) RETURN NUMBER
    IS
        v_lines PKG_CP_FACTURACION.t_lineas_venta;
    BEGIN
        v_lines(1).id_producto := v_producto;
        v_lines(1).cantidad := p_qty;
        v_lines(1).precio_unitario := p_price;
        PKG_CP_FACTURACION.registrar_venta(
            p_id_cliente     => v_cliente,
            p_id_sucursal    => v_sucursal,
            p_id_usuario     => v_user1,
            p_numero_factura => p_number,
            p_lineas         => v_lines,
            p_id_factura     => p_id,
            p_a_credito      => FALSE,
            p_commit         => FALSE
        );
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            p_id := NULL;
            RETURN SQLCODE;
    END sell;

    -- La devolucion la registra v_user2 (otro cajero distinto del que vendio)
    FUNCTION give_back(
        p_invoice IN  NUMBER,
        p_dvl     IN  NUMBER,
        p_qty     IN  NUMBER,
        p_id      OUT NUMBER
    ) RETURN NUMBER
    IS
        v_lines PKG_CP_FACTURACION.t_lineas_dev_venta;
    BEGIN
        v_lines(1).id_detalle_venta_lote := p_dvl;
        v_lines(1).id_motivo_devolucion := v_motivo;
        v_lines(1).cantidad := p_qty;
        PKG_CP_FACTURACION.registrar_devolucion_venta(
            p_id_factura    => p_invoice,
            p_id_usuario    => v_user2,
            p_lineas        => v_lines,
            p_id_devolucion => p_id,
            p_commit        => FALSE
        );
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            p_id := NULL;
            RETURN SQLCODE;
    END give_back;

BEGIN

    SELECT NVL(MAX(id_bitacora_error), 0) INTO v_antes FROM CP_BITACORA_ERROR;
    SELECT NVL(MAX(id_notificacion), 0) INTO v_notif_antes FROM CP_NOTIFICACION;

    PKG_CP_AVISO.set_enabled(FALSE);

    -- Producto con stock en una sucursal con un solo almacen activo
    -- (el mismo criterio de las pruebas del script 25)
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

    SELECT MIN(id_cliente) INTO v_cliente FROM CP_CLIENTE;

    SELECT id_usuario INTO v_user1
    FROM CP_USUARIO ORDER BY id_usuario FETCH FIRST 1 ROW ONLY;

    SELECT id_usuario, nombre_usuario INTO v_user2, v_user2_name
    FROM CP_USUARIO ORDER BY id_usuario OFFSET 1 ROW FETCH NEXT 1 ROW ONLY;

    SELECT id_motivo_devolucion INTO v_motivo
    FROM CP_MOTIVO_DEVOLUCION WHERE nombre_motivo_devolucion = 'PRODUCTO INCORRECTO';

    SELECT nombre_sucursal INTO v_branch_name
    FROM CP_SUCURSAL WHERE id_sucursal = v_sucursal;

    -- ------------------------------------------------------------
    -- A. Un dia sin movimientos
    -- ------------------------------------------------------------
    v_code := close_day(v_sucursal, v_empty_day, v_id_empty);

    IF v_code = 0 THEN
        v_empty := header_of(v_id_empty);
        SELECT COUNT(*) INTO v_count
        FROM CP_DETALLE_CIERRE_DIARIO WHERE id_cierre_diario = v_id_empty;
    END IF;

    reportar('1. Un dia sin movimientos cierra en ceros y sin detalle',
             v_code = 0
             AND v_empty.cantidad_ventas = 0 AND v_empty.cantidad_devoluciones = 0
             AND v_empty.unidades_vendidas = 0 AND v_empty.unidades_devueltas = 0
             AND v_empty.total_ventas = 0 AND v_empty.total_devoluciones = 0
             AND v_count = 0);

    v_code := close_day(v_sucursal, v_empty_day, v_id_empty2);

    reportar('2. Cerrar dos veces el mismo dia no duplica el cierre',
             v_code = 0 AND v_id_empty2 = v_id_empty
             AND count_headers(v_sucursal, v_empty_day) = 1);

    -- ------------------------------------------------------------
    -- B. Un dia con ventas y una devolucion
    -- ------------------------------------------------------------
    -- Cierre de hoy ANTES de las ventas de prueba: es la base de comparacion
    v_code := close_day(v_sucursal, v_today, v_id_base);
    v_base := header_of(v_id_base);
    v_base_u1 := detail_of(v_id_base, v_user1);
    v_base_u2 := detail_of(v_id_base, v_user2);

    v_codes_ok := sell('T27-1-' || v_stamp, 2, 1000, v_f1) = 0
              AND sell('T27-2-' || v_stamp, 1, 500, v_f2) = 0
              AND sell('T27-3-' || v_stamp, 1, 700, v_f3) = 0;

    IF v_codes_ok THEN
        -- La tercera venta se anula: no debe entrar al cierre
        PKG_CP_FACTURACION.anular_venta(p_id_factura => v_f3, p_commit => FALSE);

        SELECT MIN(dvl.id_detalle_venta_lote) INTO v_dvl
        FROM CP_DETALLE_VENTA_LOTE dvl
        JOIN CP_DETALLE_VENTA_PRODUCTO dvp
          ON dvp.id_detalle_venta_producto = dvl.id_detalle_venta_producto
        WHERE dvp.id_factura_venta = v_f1;

        v_codes_ok := give_back(v_f1, v_dvl, 1, v_dev) = 0;
    END IF;

    IF v_codes_ok THEN
        SELECT monto_total INTO v_dev_amount
        FROM CP_DEVOLUCION_VENTA WHERE id_devolucion_venta = v_dev;
    END IF;

    reportar('3. La API registro 3 ventas (una anulada) y 1 devolucion de prueba',
             v_codes_ok AND v_dev IS NOT NULL);

    v_code := close_day(v_sucursal, v_today, v_id_after);

    IF v_code = 0 THEN
        v_after := header_of(v_id_after);
        v_after_u1 := detail_of(v_id_after, v_user1);
        v_after_u2 := detail_of(v_id_after, v_user2);
    END IF;

    reportar('4. Recerrar el mismo dia reutiliza el cierre y no lo duplica',
             v_code = 0 AND v_id_after = v_id_base
             AND count_headers(v_sucursal, v_today) = 1);

    reportar('5. Cuenta 2 facturas: la anulada no entra',
             v_after.cantidad_ventas - v_base.cantidad_ventas = 2);

    reportar('6. Suma las unidades vendidas (2 + 1)',
             v_after.unidades_vendidas - v_base.unidades_vendidas = 3);

    reportar('7. Suma el total de ventas (2000 + 500)',
             v_after.total_ventas - v_base.total_ventas = 2500);

    reportar('8. Cuenta la devolucion procesada, sus unidades y su monto',
             v_after.cantidad_devoluciones - v_base.cantidad_devoluciones = 1
             AND v_after.unidades_devueltas - v_base.unidades_devueltas = 1
             AND v_after.total_devoluciones - v_base.total_devoluciones = v_dev_amount);

    reportar('9. El cajero que vendio tiene 2 facturas y 3 unidades en su detalle',
             v_after_u1.cantidad_ventas - v_base_u1.cantidad_ventas = 2
             AND v_after_u1.unidades_vendidas - v_base_u1.unidades_vendidas = 3
             AND v_after_u1.total_ventas - v_base_u1.total_ventas = 2500);

    reportar('10. El cajero que solo devolvio sale con 0 ventas y 1 devolucion',
             v_after_u2.cantidad_ventas - v_base_u2.cantidad_ventas = 0
             AND v_after_u2.cantidad_devoluciones - v_base_u2.cantidad_devoluciones = 1
             AND v_after_u2.unidades_devueltas - v_base_u2.unidades_devueltas = 1
             AND v_after_u2.total_devoluciones - v_base_u2.total_devoluciones = v_dev_amount);

    -- Con GROUP BY, si el HAVING no se cumple no hay filas (no un cero),
    -- por eso se cuenta sobre una subconsulta.
    SELECT COUNT(*) INTO v_count
    FROM (SELECT 1
          FROM CP_DETALLE_CIERRE_DIARIO d
          WHERE d.id_cierre_diario = v_id_after
          GROUP BY d.id_cierre_diario
          HAVING SUM(d.cantidad_ventas) = v_after.cantidad_ventas
            AND SUM(d.cantidad_devoluciones) = v_after.cantidad_devoluciones
            AND SUM(d.unidades_vendidas) = v_after.unidades_vendidas
            AND SUM(d.unidades_devueltas) = v_after.unidades_devueltas
            AND SUM(d.total_ventas) = v_after.total_ventas
            AND SUM(d.total_devoluciones) = v_after.total_devoluciones);

    reportar('11. El encabezado es exactamente la suma del detalle',
             v_count = 1);

    -- Contraste independiente: ayer se cuenta con otra consulta distinta
    v_code := close_day(v_sucursal, v_today - 1, v_id_yest);

    SELECT COUNT(*) INTO v_expected
    FROM CP_FACTURA_VENTA fv
    JOIN CP_ESTADO_FACTURA_VENTA ef
      ON ef.id_estado_factura_venta = fv.id_estado_factura_venta
    WHERE fv.id_sucursal = v_sucursal
      AND fv.fecha_emision >= v_today - 1
      AND fv.fecha_emision <  v_today
      AND ef.nombre_estado_factura <> 'ANULADA';

    IF v_code = 0 THEN
        v_yest := header_of(v_id_yest);
    END IF;

    reportar('12. Ayer es otro cierre y no cuenta las ventas de hoy',
             v_code = 0 AND v_id_yest <> v_id_base
             AND v_yest.cantidad_ventas = v_expected);

    v_text := PKG_CP_CIERRE.build_message(v_id_after);

    reportar('13. El mensaje trae la sucursal, el detalle y al cajero de la devolucion',
             INSTR(v_text, v_branch_name) > 0
             AND INSTR(v_text, 'Detalle por cajero') > 0
             AND INSTR(v_text, v_user2_name) > 0);

    -- ------------------------------------------------------------
    -- C. Errores propios
    -- ------------------------------------------------------------
    reportar('14. Una sucursal inexistente da -20300',
             close_day(-1, v_today, v_id_empty2) = -20300);

    reportar('15. Una fecha futura da -20301',
             close_day(v_sucursal, v_today + 5, v_id_empty2) = -20301);

    SELECT COUNT(*) INTO v_count
    FROM CP_BITACORA_ERROR
    WHERE id_bitacora_error > v_antes AND modulo = 'CIERRE';

    reportar('16. Los 2 errores quedaron UNA sola vez en la bitacora',
             v_count = 2);

    SELECT COUNT(*) INTO v_count FROM CP_FACTURA_VENTA WHERE id_factura_venta = v_f1;

    reportar('17. Un error deshace solo su cierre: la venta pendiente sigue',
             v_count = 1);

    -- ------------------------------------------------------------
    -- D. Aviso agrupado del dia
    -- ------------------------------------------------------------
    v_day_text := PKG_CP_CIERRE.build_day_message(v_today);

    reportar('18. El aviso del dia agrupa los cierres y trae la sucursal de prueba',
             DBMS_LOB.INSTR(v_day_text, 'Cierre diario del ' || TO_CHAR(v_today, 'DD/MM/YYYY')) > 0
             AND DBMS_LOB.INSTR(v_day_text, v_branch_name) > 0
             AND DBMS_LOB.INSTR(v_day_text, 'Detalle por cajero') > 0);

    -- Avisos encendidos y sin confirmar: el cierre masivo deja su aviso
    -- en cola o, si el modulo de correo no esta listo, registra por que
    -- no pudo. En ningun caso se detiene el cierre.
    PKG_CP_AVISO.set_enabled(TRUE);
    BEGIN
        PKG_CP_CIERRE.close_all_branches(v_empty_day, p_commit => FALSE);
        v_codes_ok := TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            v_codes_ok := FALSE;
    END;
    v_status := PKG_CP_AVISO.last_status;
    PKG_CP_AVISO.set_enabled(FALSE);

    SELECT COUNT(*) INTO v_count
    FROM CP_NOTIFICACION
    WHERE id_notificacion > v_notif_antes
      AND tipo_notificacion = 'CIERRE_DIARIO';

    DBMS_OUTPUT.PUT_LINE('   estado del aviso del cierre: ' || NVL(v_status, '<ninguno>'));

    reportar('19. El cierre masivo deja un aviso en cola o registra por que no pudo',
             v_codes_ok
             AND ((v_status = 'ENCOLADO' AND v_count = 1)
                  OR (v_status = 'FALLIDO' AND v_count = 0)));

    -- ------------------------------------------------------------
    -- E. Limpieza de lo pendiente
    -- ------------------------------------------------------------
    ROLLBACK;

    SELECT COUNT(*) INTO v_count FROM CP_FACTURA_VENTA WHERE id_factura_venta = v_f1;

    SELECT COUNT(*) INTO v_notices
    FROM CP_NOTIFICACION
    WHERE id_notificacion > v_notif_antes
      AND tipo_notificacion = 'CIERRE_DIARIO';

    reportar('20. El ROLLBACK deja la base sin los datos de prueba ni el aviso',
             v_count = 0 AND count_headers(v_sucursal, v_empty_day) = 0
             AND v_notices = 0);

    DELETE FROM CP_BITACORA_ERROR
    WHERE id_bitacora_error > v_antes
      AND modulo IN ('CIERRE', 'AVISO', 'PARAMETRO');
    COMMIT;

    -- ------------------------------------------------------------
    -- F. Cierre masivo: confirma de verdad, por eso va al final
    --    (con los avisos apagados: no deja correo del 03/01/2000)
    -- ------------------------------------------------------------
    SELECT COUNT(*) INTO v_branches FROM CP_SUCURSAL;

    PKG_CP_CIERRE.close_all_branches(v_mass_day);

    SELECT COUNT(*) INTO v_count FROM CP_CIERRE_DIARIO WHERE fecha_cierre = v_mass_day;

    reportar('21. El cierre masivo crea un cierre por sucursal',
             v_count = v_branches);

    PKG_CP_CIERRE.close_all_branches(v_mass_day);

    SELECT COUNT(*) INTO v_count FROM CP_CIERRE_DIARIO WHERE fecha_cierre = v_mass_day;

    reportar('22. Repetir el cierre masivo no duplica nada',
             v_count = v_branches);

    DELETE FROM CP_DETALLE_CIERRE_DIARIO
    WHERE id_cierre_diario IN (SELECT id_cierre_diario
                               FROM CP_CIERRE_DIARIO
                               WHERE fecha_cierre = v_mass_day);
    DELETE FROM CP_CIERRE_DIARIO WHERE fecha_cierre = v_mass_day;
    COMMIT;

    PKG_CP_AVISO.set_enabled(TRUE);

    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'Resultado: ' || v_ok || ' OK, '
                         || v_falla || ' FALLA');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        PKG_CP_AVISO.set_enabled(TRUE);
        DBMS_OUTPUT.PUT_LINE('ERROR en las pruebas: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        RAISE;
END;
/

-- ============================================================
-- 4. JOB DIARIO DEL CIERRE
-- ============================================================
-- Corre todos los dias a las 00:30 y cierra el dia anterior de todas
-- las sucursales (asi no se pierde ninguna venta de ultima hora).
-- Se vuelve a crear en cada ejecucion del script (primero se borra).
-- Cada corrida deja en cola el aviso del dia (al relanzar el script
-- tambien se reenvia el del dia anterior). A peticion del profesor se
-- puede cerrar cualquier fecha (tambien manda su aviso) con:
--   EXEC PKG_CP_CIERRE.close_all_branches(DATE '2026-11-09');
-- o lanzar el job al instante con:
--   EXEC DBMS_SCHEDULER.RUN_JOB('JOB_CP_CIERRE_DIARIO', FALSE);

BEGIN

    BEGIN
        DBMS_SCHEDULER.DROP_JOB('JOB_CP_CIERRE_DIARIO', force => TRUE);
    EXCEPTION
        WHEN OTHERS THEN
            -- ORA-27475: el job no existe todavia, no es un error
            IF SQLCODE != -27475 THEN
                RAISE;
            END IF;
    END;

    DBMS_SCHEDULER.CREATE_JOB(
        job_name        => 'JOB_CP_CIERRE_DIARIO',
        job_type        => 'PLSQL_BLOCK',
        job_action      => 'BEGIN PKG_CP_CIERRE.close_all_branches; END;',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=DAILY;BYHOUR=0;BYMINUTE=30;BYSECOND=0',
        enabled         => TRUE,
        comments        => 'Cierre diario de todas las sucursales (cierra el dia anterior).'
    );

END;
/

-- Lanza el job una vez y espera para ver su resultado en el historial
BEGIN
    DBMS_SCHEDULER.RUN_JOB('JOB_CP_CIERRE_DIARIO', FALSE);
    DBMS_SESSION.SLEEP(5);
END;
/

SELECT job_name, enabled, state, repeat_interval, next_run_date
FROM   user_scheduler_jobs
WHERE  job_name = 'JOB_CP_CIERRE_DIARIO';

SELECT job_name, status, actual_start_date, run_duration, errors
FROM   user_scheduler_job_run_details
WHERE  job_name = 'JOB_CP_CIERRE_DIARIO'
ORDER  BY log_date DESC
FETCH FIRST 3 ROWS ONLY;
