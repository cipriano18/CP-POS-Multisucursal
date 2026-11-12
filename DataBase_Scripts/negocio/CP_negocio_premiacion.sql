-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- BASE DE DATOS: Oracle 21c
-- SCRIPT: 31_negocio_premiacion.sql
-- DESCRIPCION: Premiacion de los mejores clientes. Vista
--              VW_CP_VENTA_NETA_FACTURA (lo que dejo cada factura:
--              total menos devoluciones procesadas) y paquete
--              PKG_CP_PREMIACION: cada PREMIO_PERIODO_MESES meses
--              elige los PREMIO_CANTIDAD_CLIENTES clientes que mas
--              compraron y les emite una orden de compra por
--              PREMIO_MONTO_ORDEN. Incluye el job diario y pruebas.
--
-- REGLAS DE LA PREMIACION:
--   * Periodo: los ultimos PREMIO_PERIODO_MESES meses hasta el dia
--     anterior a la corrida (dias completos).
--   * Medida: compra neta = total de las facturas no anuladas del
--     periodo menos las devoluciones PROCESADAS de esas facturas. Las
--     facturas a credito pendientes tambien cuentan: son compras.
--   * Solo clientes ACTIVO y nunca el cliente por defecto (el de las
--     ventas de contado sin cliente, que si no ganaria siempre).
--   * Desempate: mayor compra neta, luego mas facturas, luego
--     id_cliente; asi el resultado es siempre el mismo. Si hay menos
--     clientes con compra neta positiva que el parametro, se premia a
--     los que haya.
--   * Un periodo que se cruza con uno ya premiado no se vuelve a
--     premiar.
--
-- JOB: diario. El intervalo de DBMS_SCHEDULER no lee parametros, asi
-- que el job corre todos los dias y solo premia cuando el periodo
-- nuevo ya no se cruza con el ultimo premiado (cada
-- PREMIO_PERIODO_MESES meses). Cambiar el parametro no obliga a
-- recrear el job. Si nunca se ha premiado, la primera corrida premia.
--
-- El aviso al coordinador (build_message) se deja en cola con
-- PKG_CP_AVISO (script 26A) dentro de la misma transaccion: si la
-- premiacion se deshace, el aviso tambien. Un aviso que no se puede
-- encolar no deshace la premiacion.
--
-- ERRORES PROPIOS (tramo -20330 a -20339):
--   -20330 no se puede premiar con una fecha futura
--   -20331 el periodo ya fue premiado (se cruza con otro)
--   -20332 otra sesion esta premiando en este momento
--   -20333 parametro de premiacion invalido
--   -20334 la ejecucion de premiacion no existe
--
-- EJECUTAR COMO: CP_POS en XEPDB1 (despues de los scripts 15, 25 y 26A).
--                Se puede volver a ejecutar completo las veces
--                que haga falta.
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED

-- ============================================================
-- 1. VISTA VW_CP_VENTA_NETA_FACTURA
-- ============================================================
-- Una fila por factura de venta no anulada con lo que realmente dejo.
-- Es la unica fuente de la medida: la usan la premiacion y su aviso.
-- No filtra clientes, para que el aviso de una premiacion vieja siga
-- mostrando los mismos montos aunque un cliente cambie de estado.

CREATE OR REPLACE VIEW VW_CP_VENTA_NETA_FACTURA AS
SELECT f.id_factura_venta,
       f.id_cliente,
       f.fecha_emision,
       f.total,
       NVL(dv.total_devuelto, 0)           AS total_devuelto,
       f.total - NVL(dv.total_devuelto, 0) AS total_neto
FROM CP_FACTURA_VENTA f
JOIN CP_ESTADO_FACTURA_VENTA ef
  ON ef.id_estado_factura_venta = f.id_estado_factura_venta
LEFT JOIN (
    SELECT d.id_factura_venta, SUM(d.monto_total) AS total_devuelto
    FROM CP_DEVOLUCION_VENTA d
    JOIN CP_ESTADO_DEVOLUCION ed
      ON ed.id_estado_devolucion = d.id_estado_devolucion
    WHERE ed.nombre_estado_devolucion = 'PROCESADA'
    GROUP BY d.id_factura_venta
) dv
  ON dv.id_factura_venta = f.id_factura_venta
WHERE ef.nombre_estado_factura <> 'ANULADA';

COMMENT ON TABLE VW_CP_VENTA_NETA_FACTURA IS
'Facturas de venta no anuladas con su total, lo devuelto (devoluciones procesadas) y el neto.';
COMMENT ON COLUMN VW_CP_VENTA_NETA_FACTURA.total_neto IS
'Total de la factura menos sus devoluciones procesadas: la medida de la premiacion.';

-- ============================================================
-- 2. PAQUETE PKG_CP_PREMIACION (ESPECIFICACION)
-- ============================================================

CREATE OR REPLACE PACKAGE PKG_CP_PREMIACION AUTHID DEFINER AS

    -- Premia el periodo que termina el dia anterior a p_run_date y
    -- devuelve el id de la ejecucion. Con p_commit => FALSE deja la
    -- transaccion abierta.
    PROCEDURE run_awards(
        p_run_date     IN  DATE,
        p_id_ejecucion OUT NUMBER,
        p_commit       IN  BOOLEAN DEFAULT TRUE
    );

    -- 'S' si el periodo que terminaria el dia anterior a p_today no se
    -- cruza con ninguno ya premiado; 'N' si todavia no toca.
    FUNCTION is_due(
        p_today IN DATE
    ) RETURN VARCHAR2;

    -- Premia solo si toca. Es lo que ejecuta el job diario.
    PROCEDURE run_if_due(
        p_today  IN DATE    DEFAULT TRUNC(SYSDATE),
        p_commit IN BOOLEAN DEFAULT TRUE
    );

    -- Texto del aviso al coordinador con los clientes premiados.
    FUNCTION build_message(
        p_id_ejecucion IN NUMBER
    ) RETURN VARCHAR2;

END PKG_CP_PREMIACION;
/

-- ============================================================
-- 3. PAQUETE PKG_CP_PREMIACION (CUERPO)
-- ============================================================

CREATE OR REPLACE PACKAGE BODY PKG_CP_PREMIACION AS

    c_modulo CONSTANT VARCHAR2(20) := 'PREMIACION';

    -- Tipo con el que el aviso queda en CP_NOTIFICACION
    c_tipo_aviso CONSTANT VARCHAR2(50) := 'PREMIACION_CLIENTES';

    c_estado_cliente_activo CONSTANT VARCHAR2(30) := 'ACTIVO';

    c_err_futura    CONSTANT PLS_INTEGER := -20330;
    c_err_premiado  CONSTANT PLS_INTEGER := -20331;
    c_err_ocupado   CONSTANT PLS_INTEGER := -20332;
    c_err_parametro CONSTANT PLS_INTEGER := -20333;
    c_err_ejecucion CONSTANT PLS_INTEGER := -20334;

    -- ORA-00054: el recurso esta ocupado y se pidio NOWAIT
    e_ocupado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_ocupado, -54);


    -- Lee un parametro entero positivo (o cero si p_allow_zero).
    FUNCTION whole_parameter(
        p_code       IN VARCHAR2,
        p_allow_zero IN BOOLEAN DEFAULT FALSE
    ) RETURN NUMBER
    IS
        v_value NUMBER := PKG_CP_PARAMETRO.obtener_numero(p_code);
    BEGIN
        IF v_value IS NULL
           OR v_value <> TRUNC(v_value)
           OR v_value < 0
           OR (v_value = 0 AND NOT p_allow_zero) THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_parametro,
                'El parametro ' || p_code || ' debe ser un entero positivo.'
            );
        END IF;
        RETURN v_value;
    END whole_parameter;


    -- Primer dia del periodo que termina el dia anterior a p_day.
    FUNCTION period_start(
        p_day IN DATE
    ) RETURN DATE
    IS
    BEGIN
        RETURN ADD_MONTHS(p_day, -whole_parameter('PREMIO_PERIODO_MESES'));
    END period_start;


    -- TRUE si [p_start, p_end] se cruza con un periodo ya premiado.
    FUNCTION period_overlaps(
        p_start IN DATE,
        p_end   IN DATE
    ) RETURN BOOLEAN
    IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM CP_EJECUCION_PREMIACION
        WHERE fecha_inicio_periodo <= p_end
          AND fecha_fin_periodo >= p_start;
        RETURN v_count > 0;
    END period_overlaps;


    -- Deja en cola el aviso al coordinador con los clientes premiados,
    -- sin COMMIT (lo confirma run_awards junto con la premiacion). Ni
    -- armar el texto ni encolarlo puede deshacer la premiacion: un
    -- fallo aqui solo queda en la bitacora.
    PROCEDURE notify_awards(
        p_id_ejecucion IN NUMBER
    )
    IS
        v_start DATE;
        v_end   DATE;
    BEGIN
        SELECT fecha_inicio_periodo, fecha_fin_periodo
        INTO v_start, v_end
        FROM CP_EJECUCION_PREMIACION
        WHERE id_ejecucion_premiacion = p_id_ejecucion;

        PKG_CP_AVISO.queue_notice(
            p_type    => c_tipo_aviso,
            p_subject => 'Clientes premiados del ' || TO_CHAR(v_start, 'DD/MM/YYYY')
                         || ' al ' || TO_CHAR(v_end, 'DD/MM/YYYY'),
            p_message => build_message(p_id_ejecucion)
        );
    EXCEPTION
        WHEN OTHERS THEN
            PKG_CP_ERROR.registrar_inesperado(
                c_modulo,
                'aviso de la ejecucion ' || p_id_ejecucion
            );
    END notify_awards;


    PROCEDURE run_awards(
        p_run_date     IN  DATE,
        p_id_ejecucion OUT NUMBER,
        p_commit       IN  BOOLEAN DEFAULT TRUE
    )
    IS
        v_day     DATE := TRUNC(p_run_date);
        v_start   DATE;
        v_end     DATE;
        v_limit   NUMBER;
        v_amount  NUMBER;
        v_awarded NUMBER;
    BEGIN

        SAVEPOINT sp_run_awards;

        IF v_day IS NULL OR v_day > TRUNC(SYSDATE) THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_futura,
                'No se puede premiar con una fecha futura o vacia: '
                || NVL(TO_CHAR(v_day, 'DD/MM/YYYY'), '<NULL>') || '.'
            );
        END IF;

        -- Dos corridas a la vez podrian premiar el mismo periodo: el
        -- bloqueo de la tabla de ejecuciones las pone en fila. NOWAIT:
        -- si otra sesion la tiene, se avisa en vez de esperar.
        -- ROLLBACK TO SAVEPOINT libera el bloqueo si algo falla despues.
        BEGIN
            LOCK TABLE CP_EJECUCION_PREMIACION IN EXCLUSIVE MODE NOWAIT;
        EXCEPTION
            WHEN e_ocupado THEN
                PKG_CP_ERROR.lanzar(
                    c_modulo,
                    c_err_ocupado,
                    'Otra sesion esta premiando en este momento; intente de nuevo.'
                );
        END;

        v_start  := period_start(v_day);
        v_end    := v_day - 1;
        v_limit  := whole_parameter('PREMIO_CANTIDAD_CLIENTES');
        v_amount := whole_parameter('PREMIO_MONTO_ORDEN', p_allow_zero => TRUE);

        IF period_overlaps(v_start, v_end) THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_premiado,
                'El periodo del ' || TO_CHAR(v_start, 'DD/MM/YYYY') || ' al '
                || TO_CHAR(v_end, 'DD/MM/YYYY') || ' ya fue premiado.'
            );
        END IF;

        INSERT INTO CP_EJECUCION_PREMIACION
            (fecha_inicio_periodo, fecha_fin_periodo, monto_premio, cantidad_premiados)
        VALUES
            (v_start, v_end, v_amount, 0)
        RETURNING id_ejecucion_premiacion INTO p_id_ejecucion;

        -- Ranking en una sola sentencia: compra neta por cliente del
        -- periodo (rango >= y < para no inutilizar un indice de fecha),
        -- posicion con el desempate fijo, y los primeros v_limit.
        INSERT INTO CP_ORDEN_PREMIO_CLIENTE
            (id_ejecucion_premiacion, id_cliente, posicion, monto_premio)
        SELECT p_id_ejecucion, r.id_cliente, r.posicion, v_amount
        FROM (
            SELECT v.id_cliente,
                   ROW_NUMBER() OVER (ORDER BY SUM(v.total_neto) DESC,
                                               COUNT(*) DESC,
                                               v.id_cliente) AS posicion
            FROM VW_CP_VENTA_NETA_FACTURA v
            JOIN CP_CLIENTE c
              ON c.id_cliente = v.id_cliente
            JOIN CP_ESTADO_CLIENTE ec
              ON ec.id_estado_cliente = c.id_estado_cliente
            WHERE v.fecha_emision >= v_start
              AND v.fecha_emision <  v_end + 1
              AND c.es_cliente_defecto = 'N'
              AND ec.nombre_estado_cliente = c_estado_cliente_activo
            GROUP BY v.id_cliente
            HAVING SUM(v.total_neto) > 0
        ) r
        WHERE r.posicion <= v_limit;

        v_awarded := SQL%ROWCOUNT;

        UPDATE CP_EJECUCION_PREMIACION
        SET cantidad_premiados = v_awarded
        WHERE id_ejecucion_premiacion = p_id_ejecucion;

        notify_awards(p_id_ejecucion);

        IF p_commit THEN
            COMMIT;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            -- Se deshace solo esta corrida; lo anterior de la sesion queda
            ROLLBACK TO SAVEPOINT sp_run_awards;
            p_id_ejecucion := NULL;
            PKG_CP_ERROR.registrar_inesperado(
                c_modulo,
                'fecha=' || TO_CHAR(p_run_date, 'DD/MM/YYYY')
            );
            RAISE;
    END run_awards;


    FUNCTION is_due(
        p_today IN DATE
    ) RETURN VARCHAR2
    IS
        v_day DATE := TRUNC(p_today);
    BEGIN
        IF period_overlaps(period_start(v_day), v_day - 1) THEN
            RETURN 'N';
        END IF;
        RETURN 'S';
    EXCEPTION
        WHEN OTHERS THEN
            PKG_CP_ERROR.registrar_inesperado(
                c_modulo,
                'is_due fecha=' || TO_CHAR(p_today, 'DD/MM/YYYY')
            );
            RAISE;
    END is_due;


    PROCEDURE run_if_due(
        p_today  IN DATE    DEFAULT TRUNC(SYSDATE),
        p_commit IN BOOLEAN DEFAULT TRUE
    )
    IS
        v_id NUMBER;
    BEGIN
        IF is_due(p_today) = 'S' THEN
            run_awards(p_today, v_id, p_commit);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            -- run_awards ya registro su error; aqui solo lo inesperado
            PKG_CP_ERROR.registrar_inesperado(
                c_modulo,
                'run_if_due fecha=' || TO_CHAR(p_today, 'DD/MM/YYYY')
            );
            RAISE;
    END run_if_due;


    FUNCTION build_message(
        p_id_ejecucion IN NUMBER
    ) RETURN VARCHAR2
    IS
        c_nls CONSTANT VARCHAR2(40) := 'NLS_NUMERIC_CHARACTERS=''.,''';
        c_fmt CONSTANT VARCHAR2(30) := 'FM999,999,999,990.00';

        v_exec CP_EJECUCION_PREMIACION%ROWTYPE;
        v_text VARCHAR2(32767);
    BEGIN

        BEGIN
            SELECT * INTO v_exec
            FROM CP_EJECUCION_PREMIACION
            WHERE id_ejecucion_premiacion = p_id_ejecucion;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                PKG_CP_ERROR.lanzar(
                    c_modulo,
                    c_err_ejecucion,
                    'La ejecucion de premiacion '
                    || NVL(TO_CHAR(p_id_ejecucion), '<NULL>') || ' no existe.'
                );
        END;

        v_text := 'Premiacion de los mejores clientes del '
            || TO_CHAR(v_exec.fecha_inicio_periodo, 'DD/MM/YYYY') || ' al '
            || TO_CHAR(v_exec.fecha_fin_periodo, 'DD/MM/YYYY') || CHR(10)
            || 'Clientes premiados: ' || v_exec.cantidad_premiados
            || ', con una orden de compra de CRC '
            || TO_CHAR(v_exec.monto_premio, c_fmt, c_nls) || ' cada uno.';

        IF v_exec.cantidad_premiados = 0 THEN
            RETURN v_text || CHR(10) || 'Ningun cliente tuvo compras netas en el periodo.';
        END IF;

        v_text := v_text || CHR(10);

        FOR r IN (
            SELECT o.posicion,
                   o.id_cliente,
                   COALESCE(
                       (SELECT TRIM(p.primer_nombre || ' ' || p.primer_apellido
                                    || ' ' || p.segundo_apellido)
                        FROM CP_CLIENTE_PERSONA cp
                        JOIN CP_PERSONA p ON p.id_persona = cp.id_persona
                        WHERE cp.id_cliente = o.id_cliente),
                       (SELECT e.razon_social
                        FROM CP_CLIENTE_EMPRESA e
                        WHERE e.id_cliente = o.id_cliente),
                       'Cliente ' || o.id_cliente) AS nombre,
                   (SELECT SUM(v.total_neto)
                    FROM VW_CP_VENTA_NETA_FACTURA v
                    WHERE v.id_cliente = o.id_cliente
                      AND v.fecha_emision >= v_exec.fecha_inicio_periodo
                      AND v.fecha_emision <  v_exec.fecha_fin_periodo + 1) AS neto,
                   (SELECT COUNT(*)
                    FROM VW_CP_VENTA_NETA_FACTURA v
                    WHERE v.id_cliente = o.id_cliente
                      AND v.fecha_emision >= v_exec.fecha_inicio_periodo
                      AND v.fecha_emision <  v_exec.fecha_fin_periodo + 1) AS facturas
            FROM CP_ORDEN_PREMIO_CLIENTE o
            WHERE o.id_ejecucion_premiacion = p_id_ejecucion
            ORDER BY o.posicion
        ) LOOP
            v_text := v_text || CHR(10) || r.posicion || '. ' || r.nombre
                || ' (cliente ' || r.id_cliente || '): compra neta CRC '
                || TO_CHAR(r.neto, c_fmt, c_nls) || ' en ' || r.facturas
                || CASE WHEN r.facturas = 1 THEN ' factura' ELSE ' facturas' END;
        END LOOP;

        RETURN v_text;

    EXCEPTION
        WHEN OTHERS THEN
            PKG_CP_ERROR.registrar_inesperado(c_modulo, 'ejecucion=' || p_id_ejecucion);
            RAISE;
    END build_message;

END PKG_CP_PREMIACION;
/

SHOW ERRORS PACKAGE BODY PKG_CP_PREMIACION

-- ============================================================
-- 4. PRUEBAS DE LA PREMIACION
-- ============================================================
-- Todas deben salir OK. Se ejecutan como CP_POS y todo se deshace con
-- ROLLBACK (compras, ventas y premiaciones con p_commit => FALSE). Las
-- ventas de prueba se registran con la API de facturacion y luego se
-- les mueve la fecha de emision a la segunda mitad del 2000, un
-- periodo sin datos reales: la corrida del 01/01/2001 premia del
-- 01/07/2000 al 31/12/2000. Precio de 1000 por unidad, sin impuesto.
--
--   c1: 10 unidades                                  -> 10 000, 1 factura
--   c2: 4 + 4 unidades, y 30 el 30/06/2000 (fuera)   ->  8 000, 2 facturas
--   c3: 8 unidades el 31/12/2000 a las 21:36, y 20
--       en otra factura que se anula                 ->  8 000, 1 factura
--   c4: 12 unidades devueltas por completo           ->      0
--   c5: 15 unidades, y luego el cliente pasa a INACTIVO
--   cliente por defecto: 50 unidades
-- Esperado: 1 c1, 2 c2 (gana el empate por tener mas facturas), 3 c3;
-- c4, c5 y el cliente por defecto quedan fuera.

DECLARE
    TYPE t_ids IS TABLE OF NUMBER INDEX BY PLS_INTEGER;

    v_antes       NUMBER;
    v_notif_antes NUMBER;
    v_ok          NUMBER := 0;
    v_falla       NUMBER := 0;
    v_status      VARCHAR2(12);
    v_notices     NUMBER;
    v_notice_ok   BOOLEAN;

    v_run_date    CONSTANT DATE := DATE '2001-01-01';
    v_stamp       VARCHAR2(20) := TO_CHAR(SYSDATE, 'MMDDHH24MISS');

    v_almacen     NUMBER;
    v_sucursal    NUMBER;
    v_negocio     NUMBER;
    v_user        NUMBER;
    v_pp          NUMBER;
    v_prov        NUMBER;
    v_product     NUMBER;
    v_motivo      NUMBER;
    v_default     NUMBER;
    v_c           t_ids;

    v_data_ok     BOOLEAN := TRUE;
    v_inv         NUMBER;
    v_inv_c4      NUMBER;
    v_inv_c3x     NUMBER;
    v_dev         NUMBER;
    v_exec        NUMBER;
    v_exec2       NUMBER;
    v_code        NUMBER;
    v_count       NUMBER;
    v_amount      NUMBER;
    v_text        VARCHAR2(32767);
    v_name_c1     VARCHAR2(200);
    v_first       NUMBER;
    v_fifth       NUMBER;
    v_e           CP_EJECUCION_PREMIACION%ROWTYPE;

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

    -- Venta de contado de p_qty unidades a 1000 con fecha de emision p_date
    FUNCTION sell(
        p_client IN NUMBER,
        p_qty    IN NUMBER,
        p_date   IN DATE,
        p_suffix IN VARCHAR2
    ) RETURN NUMBER
    IS
        v_lines PKG_CP_FACTURACION.t_lineas_venta;
        v_id    NUMBER;
    BEGIN
        v_lines(1).id_producto := v_product;
        v_lines(1).cantidad := p_qty;
        v_lines(1).precio_unitario := 1000;

        PKG_CP_FACTURACION.registrar_venta(
            p_id_cliente     => p_client,
            p_id_sucursal    => v_sucursal,
            p_id_usuario     => v_user,
            p_numero_factura => 'T31-' || p_suffix || '-' || v_stamp,
            p_lineas         => v_lines,
            p_id_factura     => v_id,
            p_a_credito      => FALSE,
            p_commit         => FALSE
        );

        UPDATE CP_FACTURA_VENTA
        SET fecha_emision = p_date
        WHERE id_factura_venta = v_id;

        RETURN v_id;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('  venta ' || p_suffix || ': ' || SQLERRM);
            v_data_ok := FALSE;
            RETURN NULL;
    END sell;

    -- Posicion del cliente en la ejecucion; NULL si no fue premiado
    FUNCTION position_of(
        p_exec   IN NUMBER,
        p_client IN NUMBER
    ) RETURN NUMBER
    IS
        v_pos NUMBER;
    BEGIN
        SELECT MAX(posicion) INTO v_pos
        FROM CP_ORDEN_PREMIO_CLIENTE
        WHERE id_ejecucion_premiacion = p_exec
          AND id_cliente = p_client;
        RETURN v_pos;
    END position_of;

    -- Ejecuciones de prueba (periodos del 2000 y el 2001)
    FUNCTION test_executions RETURN NUMBER
    IS
        v_rows NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_rows
        FROM CP_EJECUCION_PREMIACION
        WHERE fecha_fin_periodo < DATE '2002-01-01';
        RETURN v_rows;
    END test_executions;

BEGIN

    SELECT NVL(MAX(id_bitacora_error), 0) INTO v_antes FROM CP_BITACORA_ERROR;
    SELECT NVL(MAX(id_notificacion), 0) INTO v_notif_antes FROM CP_NOTIFICACION;

    -- Los avisos se apagan durante las pruebas para no dejar correos
    -- reales en cola; la prueba 19 los enciende sin confirmar.
    PKG_CP_AVISO.set_enabled(FALSE);

    -- Sucursal con un solo almacen activo (el inventario de venta sale de ahi)
    SELECT a.id_almacen, a.id_sucursal, s.id_negocio
    INTO v_almacen, v_sucursal, v_negocio
    FROM CP_ALMACEN a
    JOIN CP_ESTADO e
      ON e.id_estado = a.id_estado
    JOIN CP_SUCURSAL s
      ON s.id_sucursal = a.id_sucursal
    WHERE e.nombre = 'ACTIVO'
      AND (SELECT COUNT(*)
           FROM CP_ALMACEN a2
           JOIN CP_ESTADO e2
             ON e2.id_estado = a2.id_estado
           WHERE a2.id_sucursal = a.id_sucursal
             AND e2.nombre = 'ACTIVO') = 1
    ORDER BY a.id_almacen
    FETCH FIRST 1 ROW ONLY;

    SELECT MIN(id_usuario) INTO v_user FROM CP_USUARIO;

    SELECT id_producto_proveedor, id_proveedor, id_producto
    INTO v_pp, v_prov, v_product
    FROM CP_PRODUCTO_PROVEEDOR
    ORDER BY id_producto_proveedor
    FETCH FIRST 1 ROW ONLY;

    SELECT id_motivo_devolucion INTO v_motivo
    FROM CP_MOTIVO_DEVOLUCION WHERE nombre_motivo_devolucion = 'PRODUCTO INCORRECTO';

    SELECT MAX(id_cliente) INTO v_default
    FROM CP_CLIENTE WHERE es_cliente_defecto = 'S';

    -- Cinco clientes activos que no son el cliente por defecto
    FOR r IN (SELECT c.id_cliente
              FROM CP_CLIENTE c
              JOIN CP_ESTADO_CLIENTE ec
                ON ec.id_estado_cliente = c.id_estado_cliente
              WHERE c.es_cliente_defecto = 'N'
                AND ec.nombre_estado_cliente = 'ACTIVO'
              ORDER BY c.id_cliente
              FETCH FIRST 5 ROWS ONLY) LOOP
        v_c(v_c.COUNT + 1) := r.id_cliente;
    END LOOP;

    IF v_c.COUNT < 4 THEN
        RAISE_APPLICATION_ERROR(-20999,
            'Las pruebas necesitan al menos 4 clientes activos que no sean el cliente por defecto.');
    END IF;

    -- Compra de 200 unidades al almacen de la sucursal de prueba
    DECLARE
        v_lots PKG_CP_FACTURACION.t_lineas_compra;
        v_buy  NUMBER;
    BEGIN
        v_lots(1).id_producto_proveedor := v_pp;
        v_lots(1).cantidad := 200;
        v_lots(1).precio_costo_unitario := 500;
        v_lots(1).numero_lote := 'T31-' || v_stamp;
        v_lots(1).fecha_vencimiento := TRUNC(SYSDATE) + 60;

        PKG_CP_FACTURACION.registrar_compra(
            p_id_proveedor         => v_prov,
            p_id_negocio           => v_negocio,
            p_id_almacen_recepcion => v_almacen,
            p_id_usuario           => v_user,
            p_numero_factura       => 'T31-C-' || v_stamp,
            p_lineas               => v_lots,
            p_id_factura           => v_buy,
            p_a_credito            => FALSE,
            p_commit               => FALSE
        );
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('  compra: ' || SQLERRM);
            v_data_ok := FALSE;
    END;

    -- Ventas del escenario (ver la tabla de arriba)
    v_inv := sell(v_c(1), 10, DATE '2000-08-10', '1');
    v_inv := sell(v_c(2),  4, DATE '2000-09-01', '2A');
    v_inv := sell(v_c(2),  4, DATE '2000-09-02', '2B');
    v_inv := sell(v_c(2), 30, DATE '2000-06-30', '2X');
    v_inv := sell(v_c(3),  8, DATE '2000-12-31' + 0.9, '3');
    v_inv_c3x := sell(v_c(3), 20, DATE '2000-10-02', '3X');
    v_inv_c4 := sell(v_c(4), 12, DATE '2000-11-01', '4');

    IF v_c.COUNT >= 5 THEN
        v_inv := sell(v_c(5), 15, DATE '2000-08-15', '5');
    END IF;

    IF v_default IS NOT NULL THEN
        v_inv := sell(v_default, 50, DATE '2000-12-01', 'D');
    END IF;

    -- La segunda factura de c3 se anula y la de c4 se devuelve entera
    BEGIN
        IF v_inv_c3x IS NOT NULL THEN
            PKG_CP_FACTURACION.anular_venta(p_id_factura => v_inv_c3x, p_commit => FALSE);
        END IF;

        IF v_inv_c4 IS NOT NULL THEN
            DECLARE
                v_back PKG_CP_FACTURACION.t_lineas_dev_venta;
            BEGIN
                FOR r IN (SELECT dvl.id_detalle_venta_lote, dvl.cantidad
                          FROM CP_DETALLE_VENTA_LOTE dvl
                          JOIN CP_DETALLE_VENTA_PRODUCTO dvp
                            ON dvp.id_detalle_venta_producto = dvl.id_detalle_venta_producto
                          WHERE dvp.id_factura_venta = v_inv_c4) LOOP
                    v_back(v_back.COUNT + 1).id_detalle_venta_lote := r.id_detalle_venta_lote;
                    v_back(v_back.COUNT).id_motivo_devolucion := v_motivo;
                    v_back(v_back.COUNT).cantidad := r.cantidad;
                END LOOP;

                PKG_CP_FACTURACION.registrar_devolucion_venta(
                    p_id_factura    => v_inv_c4,
                    p_id_usuario    => v_user,
                    p_lineas        => v_back,
                    p_id_devolucion => v_dev,
                    p_commit        => FALSE
                );
            END;
        END IF;

        -- c5 deja de estar activo despues de comprar
        IF v_c.COUNT >= 5 THEN
            v_fifth := v_c(5);

            UPDATE CP_CLIENTE
            SET id_estado_cliente = (SELECT id_estado_cliente FROM CP_ESTADO_CLIENTE
                                     WHERE nombre_estado_cliente = 'INACTIVO')
            WHERE id_cliente = v_fifth;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('  anulacion o devolucion: ' || SQLERRM);
            v_data_ok := FALSE;
    END;

    reportar('1. La compra, las ventas, la anulacion y la devolucion de prueba',
             v_data_ok);

    v_amount := PKG_CP_PARAMETRO.obtener_numero('PREMIO_MONTO_ORDEN');

    -- ------------------------------------------------------------
    -- A. Validaciones
    -- ------------------------------------------------------------
    BEGIN
        PKG_CP_PREMIACION.run_awards(TRUNC(SYSDATE) + 1, v_exec, FALSE);
        v_code := 0;
    EXCEPTION
        WHEN OTHERS THEN
            v_code := SQLCODE;
    END;

    reportar('2. Una fecha futura se rechaza con -20330', v_code = -20330);

    -- ------------------------------------------------------------
    -- B. Corte por cantidad de clientes, y ROLLBACK TO SAVEPOINT
    -- ------------------------------------------------------------
    SAVEPOINT sp_cut;

    UPDATE CP_PARAMETRO SET valor = '2'
    WHERE codigo_parametro = 'PREMIO_CANTIDAD_CLIENTES';

    PKG_CP_PREMIACION.run_awards(v_run_date, v_exec, FALSE);

    SELECT COUNT(*) INTO v_count
    FROM CP_ORDEN_PREMIO_CLIENTE WHERE id_ejecucion_premiacion = v_exec;

    reportar('3. Con el parametro en 2 solo se premia a los 2 primeros',
             v_count = 2
             AND position_of(v_exec, v_c(1)) = 1
             AND position_of(v_exec, v_c(2)) = 2);

    ROLLBACK TO SAVEPOINT sp_cut;

    reportar('4. ROLLBACK TO SAVEPOINT deshace la corrida y el parametro',
             test_executions = 0
             AND PKG_CP_PARAMETRO.obtener_numero('PREMIO_CANTIDAD_CLIENTES') <> 2);

    -- ------------------------------------------------------------
    -- C. Corrida completa del periodo 01/07/2000 - 31/12/2000
    -- ------------------------------------------------------------
    PKG_CP_PREMIACION.run_awards(v_run_date, v_exec, FALSE);

    SELECT * INTO v_e
    FROM CP_EJECUCION_PREMIACION WHERE id_ejecucion_premiacion = v_exec;

    SELECT COUNT(*) INTO v_count
    FROM CP_ORDEN_PREMIO_CLIENTE WHERE id_ejecucion_premiacion = v_exec;

    reportar('5. El periodo va del 01/07/2000 al 31/12/2000 y cuenta las ordenes',
             v_e.fecha_inicio_periodo = DATE '2000-07-01'
             AND v_e.fecha_fin_periodo = DATE '2000-12-31'
             AND v_e.cantidad_premiados = v_count
             AND v_count = 3);

    reportar('6. El que mas compro queda primero (c1)',
             position_of(v_exec, v_c(1)) = 1);

    reportar('7. Empate en monto: gana el que tiene mas facturas (c2 antes que c3)',
             position_of(v_exec, v_c(2)) = 2
             AND position_of(v_exec, v_c(3)) = 3);

    reportar('8. La factura fuera del periodo no cuenta (c2 no sube al primero)',
             position_of(v_exec, v_c(2)) = 2);

    reportar('9. La anulada no suma y el ultimo dia (con hora) si cuenta (c3)',
             position_of(v_exec, v_c(3)) = 3);

    reportar('10. Devuelta por completo no deja compra neta (c4 fuera)',
             position_of(v_exec, v_c(4)) IS NULL);

    IF v_c.COUNT >= 5 THEN
        reportar('11. Un cliente que no esta ACTIVO no se premia (c5)',
                 position_of(v_exec, v_c(5)) IS NULL);
    ELSE
        omitir('11. Un cliente que no esta ACTIVO no se premia (c5)');
    END IF;

    IF v_default IS NOT NULL THEN
        reportar('12. El cliente por defecto nunca se premia',
                 position_of(v_exec, v_default) IS NULL);
    ELSE
        omitir('12. El cliente por defecto nunca se premia');
    END IF;

    SELECT COUNT(*) INTO v_count
    FROM CP_ORDEN_PREMIO_CLIENTE
    WHERE id_ejecucion_premiacion = v_exec
      AND monto_premio <> v_amount;

    reportar('13. Cada orden lleva el monto de PREMIO_MONTO_ORDEN',
             v_count = 0 AND v_e.monto_premio = v_amount);

    -- ------------------------------------------------------------
    -- D. No se premia dos veces y el job sabe cuando toca
    -- ------------------------------------------------------------
    BEGIN
        PKG_CP_PREMIACION.run_awards(v_run_date, v_exec2, FALSE);
        v_code := 0;
    EXCEPTION
        WHEN OTHERS THEN
            v_code := SQLCODE;
    END;

    reportar('14. Repetir el mismo periodo da -20331 y no crea otra ejecucion',
             v_code = -20331 AND test_executions = 1);

    reportar('15. Toca de nuevo solo al cumplirse los meses (30/06 no, 01/07 si)',
             PKG_CP_PREMIACION.is_due(DATE '2001-06-30') = 'N'
             AND PKG_CP_PREMIACION.is_due(DATE '2001-07-01') = 'S');

    PKG_CP_PREMIACION.run_if_due(DATE '2001-06-30', FALSE);
    v_count := test_executions;
    PKG_CP_PREMIACION.run_if_due(DATE '2001-07-01', FALSE);
    PKG_CP_PREMIACION.run_if_due(DATE '2001-07-02', FALSE);

    reportar('16. El job diario premia una sola vez por periodo',
             v_count = 1 AND test_executions = 2);

    -- ------------------------------------------------------------
    -- E. Aviso al coordinador
    -- ------------------------------------------------------------
    v_text := PKG_CP_PREMIACION.build_message(v_exec);

    v_first := v_c(1);

    SELECT MAX(COALESCE(
               (SELECT p.primer_nombre
                FROM CP_CLIENTE_PERSONA cp
                JOIN CP_PERSONA p ON p.id_persona = cp.id_persona
                WHERE cp.id_cliente = v_first),
               (SELECT e.razon_social
                FROM CP_CLIENTE_EMPRESA e
                WHERE e.id_cliente = v_first)))
    INTO v_name_c1
    FROM dual;

    reportar('17. El aviso trae el periodo, el monto y al cliente en primer lugar',
             INSTR(v_text, '01/07/2000 al 31/12/2000') > 0
             AND INSTR(v_text, '10,000.00') > 0
             AND INSTR(v_text, '1. ' || v_name_c1) > 0);

    DBMS_OUTPUT.PUT_LINE(CHR(10) || v_text || CHR(10));

    BEGIN
        v_text := PKG_CP_PREMIACION.build_message(-1);
        v_code := 0;
    EXCEPTION
        WHEN OTHERS THEN
            v_code := SQLCODE;
    END;

    reportar('18. El aviso de una ejecucion que no existe da -20334',
             v_code = -20334);

    -- Avisos encendidos y sin confirmar: el 01/01/2002 toca premiar el
    -- segundo semestre del 2001 (sin ventas, 0 premiados) y el aviso
    -- queda en cola o, si el modulo de correo no esta listo, se registra
    -- por que no pudo. La premiacion se guarda igual.
    PKG_CP_AVISO.set_enabled(TRUE);
    v_count := test_executions;
    BEGIN
        PKG_CP_PREMIACION.run_if_due(DATE '2002-01-01', FALSE);
        v_notice_ok := TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            v_notice_ok := FALSE;
    END;
    v_status := PKG_CP_AVISO.last_status;
    PKG_CP_AVISO.set_enabled(FALSE);

    SELECT COUNT(*) INTO v_notices
    FROM CP_NOTIFICACION
    WHERE id_notificacion > v_notif_antes
      AND tipo_notificacion = 'PREMIACION_CLIENTES';

    DBMS_OUTPUT.PUT_LINE('   estado del aviso de la premiacion: ' || NVL(v_status, '<ninguno>'));

    reportar('19. La premiacion deja su aviso en cola o registra por que no pudo',
             v_notice_ok AND test_executions = v_count + 1
             AND ((v_status = 'ENCOLADO' AND v_notices = 1)
                  OR (v_status = 'FALLIDO' AND v_notices = 0)));

    -- ------------------------------------------------------------
    -- F. Limpieza
    -- ------------------------------------------------------------
    SELECT COUNT(*) INTO v_count
    FROM CP_BITACORA_ERROR
    WHERE id_bitacora_error > v_antes
      AND modulo = 'PREMIACION'
      AND codigo_error NOT IN (-20330, -20331, -20334);

    reportar('20. No quedaron errores inesperados en la bitacora',
             v_count = 0);

    ROLLBACK;

    SELECT COUNT(*) INTO v_count
    FROM CP_FACTURA_VENTA WHERE numero_factura LIKE 'T31-%';

    SELECT COUNT(*) INTO v_notices
    FROM CP_NOTIFICACION
    WHERE id_notificacion > v_notif_antes
      AND tipo_notificacion = 'PREMIACION_CLIENTES';

    reportar('21. El ROLLBACK deja la base sin premiaciones, ventas ni avisos de prueba',
             test_executions = 0 AND v_count = 0 AND v_notices = 0);

    -- Errores provocados a proposito por las pruebas 2, 14 y 18, y los
    -- del aviso de la prueba 19: no son fallas reales y se borran para
    -- que la bitacora no acumule una copia en cada corrida del script.
    DELETE FROM CP_BITACORA_ERROR
    WHERE id_bitacora_error > v_antes
      AND (modulo IN ('AVISO', 'PARAMETRO')
           OR (modulo = 'PREMIACION' AND codigo_error IN (-20330, -20331, -20334)));
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
-- 5. JOB DIARIO DE PREMIACION
-- ============================================================
-- Corre todos los dias a la 01:15 y solo premia cuando se cumplio el
-- periodo (PKG_CP_PREMIACION.run_if_due). Si nunca se ha premiado, su
-- primera corrida premia. Se vuelve a crear en cada ejecucion del
-- script (primero se borra). A diferencia de los otros jobs, este
-- script NO lo lanza al final: una corrida crearia una premiacion real.
-- Para la defensa:
--   EXEC DBMS_SCHEDULER.RUN_JOB('JOB_CP_PREMIACION_CLIENTES', FALSE);
-- o, para ver el aviso de la ultima premiacion:
--   SELECT PKG_CP_PREMIACION.build_message(MAX(id_ejecucion_premiacion))
--   FROM CP_EJECUCION_PREMIACION;

BEGIN

    BEGIN
        DBMS_SCHEDULER.DROP_JOB('JOB_CP_PREMIACION_CLIENTES', force => TRUE);
    EXCEPTION
        WHEN OTHERS THEN
            -- ORA-27475: el job no existe todavia, no es un error
            IF SQLCODE != -27475 THEN
                RAISE;
            END IF;
    END;

    DBMS_SCHEDULER.CREATE_JOB(
        job_name        => 'JOB_CP_PREMIACION_CLIENTES',
        job_type        => 'PLSQL_BLOCK',
        job_action      => 'BEGIN PKG_CP_PREMIACION.run_if_due; END;',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=DAILY;BYHOUR=1;BYMINUTE=15;BYSECOND=0',
        enabled         => TRUE,
        comments        => 'Premia a los mejores clientes cuando se cumple PREMIO_PERIODO_MESES.'
    );

END;
/

SELECT job_name, enabled, state, repeat_interval, next_run_date
FROM   user_scheduler_jobs
WHERE  job_name = 'JOB_CP_PREMIACION_CLIENTES';

-- Hoy toca premiar? (S = la proxima corrida del job premia)
SELECT PKG_CP_PREMIACION.is_due(TRUNC(SYSDATE)) AS toca_hoy
FROM   dual;
