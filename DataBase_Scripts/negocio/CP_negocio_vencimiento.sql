-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- BASE DE DATOS: Oracle 21c
-- SCRIPT: 28_negocio_vencimiento.sql
-- DESCRIPCION: Reporte semanal de inventario para mercadeo. Paquete
--              PKG_CP_VENCIMIENTO: arma, en un solo mensaje y en dos
--              secciones separadas, (1) los lotes con existencia que
--              vencen dentro de la ventana parametrizada y (2) los
--              lotes con existencia que llevan en bodega mas de los
--              meses parametrizados. El reporte se deja en cola para
--              el coordinador por medio de PKG_CP_AVISO (script 26A).
--              Incluye el job semanal y pruebas.
--
-- PARAMETROS (CP_PARAMETRO):
--   VENCIMIENTO_VENTANA_DIAS  (7)  dias hacia adelante para "por vencer"
--   ANTIGUEDAD_BODEGA_MESES   (6)  meses para "mucho tiempo en bodega"
--
-- EJECUTAR COMO: CP_POS en XEPDB1 (despues de los scripts 15, 25 y 26A).
--                Se puede volver a ejecutar completo las veces
--                que haga falta.
--
-- ERRORES PROPIOS (tramo -20310 a -20319):
--   -20310 un parametro del reporte no es un entero mayor que cero
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED

-- ============================================================
-- 1. PAQUETE PKG_CP_VENCIMIENTO (ESPECIFICACION)
-- ============================================================

CREATE OR REPLACE PACKAGE PKG_CP_VENCIMIENTO AUTHID DEFINER AS

    -- Forma de cada fila de las dos listas (un lote en un almacen)
    TYPE t_lot_row IS RECORD (
        nombre_sucursal   CP_SUCURSAL.nombre_sucursal%TYPE,
        nombre_almacen    CP_ALMACEN.nombre_almacen%TYPE,
        nombre_producto   CP_PRODUCTO.nombre_producto%TYPE,
        numero_lote       CP_LOTE_PRODUCTO.numero_lote%TYPE,
        fecha_ingreso     DATE,
        fecha_vencimiento DATE,
        cantidad_actual   NUMBER
    );

    -- Lotes con existencia que vencen desde p_today hasta p_today mas
    -- la ventana (inclusive). Los ya vencidos no aparecen: de esos se
    -- encarga el aviso de productos vencidos. Quien llama cierra el cursor.
    FUNCTION expiring_lots(
        p_today IN DATE DEFAULT TRUNC(SYSDATE)
    ) RETURN SYS_REFCURSOR;

    -- Lotes con existencia que ingresaron hace MAS de los meses del
    -- parametro (con exactamente esos meses todavia no cuentan).
    FUNCTION stale_lots(
        p_today IN DATE DEFAULT TRUNC(SYSDATE)
    ) RETURN SYS_REFCURSOR;

    -- Arma el texto del reporte con las dos secciones por separado.
    FUNCTION build_report(
        p_today IN DATE DEFAULT TRUNC(SYSDATE)
    ) RETURN CLOB;

    -- Procedimiento semanal: arma el reporte y se lo notifica al
    -- coordinador. Es el que ejecuta el job.
    PROCEDURE send_weekly_report(
        p_today  IN DATE    DEFAULT TRUNC(SYSDATE),
        p_commit IN BOOLEAN DEFAULT TRUE
    );

END PKG_CP_VENCIMIENTO;
/

-- ============================================================
-- 2. PAQUETE PKG_CP_VENCIMIENTO (CUERPO)
-- ============================================================

CREATE OR REPLACE PACKAGE BODY PKG_CP_VENCIMIENTO AS

    c_modulo CONSTANT VARCHAR2(20) := 'VENCIMIENTO';

    -- Tipo con el que el aviso queda en CP_NOTIFICACION
    c_tipo_aviso CONSTANT VARCHAR2(50) := 'REPORTE_INVENTARIO';

    c_err_parametro CONSTANT PLS_INTEGER := -20310;

    -- Maximo de lineas por seccion en el mensaje; el total siempre es completo
    c_max_lines CONSTANT PLS_INTEGER := 200;


    -- Lee un parametro entero mayor que cero. Un valor en 0 o negativo
    -- dejaria el reporte vacio sin avisar, por eso se rechaza.
    FUNCTION positive_parameter(
        p_codigo IN VARCHAR2
    ) RETURN NUMBER
    IS
        v_value NUMBER;
    BEGIN

        v_value := PKG_CP_PARAMETRO.obtener_numero(p_codigo);

        IF v_value IS NULL OR v_value < 1 OR v_value <> TRUNC(v_value) THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_parametro,
                'El parametro ' || p_codigo || ' debe ser un entero mayor que cero.'
            );
        END IF;

        RETURN v_value;

    END positive_parameter;


    FUNCTION format_quantity(
        p_quantity IN NUMBER
    ) RETURN VARCHAR2
    IS
    BEGIN
        RETURN TO_CHAR(p_quantity, 'FM999,999,990.00',
                       'NLS_NUMERIC_CHARACTERS=''.,''');
    END format_quantity;


    FUNCTION expiring_lots(
        p_today IN DATE DEFAULT TRUNC(SYSDATE)
    ) RETURN SYS_REFCURSOR
    IS
        v_cursor SYS_REFCURSOR;
        v_today  DATE   := TRUNC(p_today);
        v_days   NUMBER := positive_parameter('VENCIMIENTO_VENTANA_DIAS');
    BEGIN

        -- Rango (>= y <) en lugar de TRUNC(columna) para no inutilizar un indice
        OPEN v_cursor FOR
            SELECT s.nombre_sucursal,
                   v.nombre_almacen,
                   v.nombre_producto,
                   v.numero_lote,
                   v.fecha_ingreso,
                   v.fecha_vencimiento,
                   v.cantidad_actual
            FROM VW_CP_INVENTARIO_ACTUAL v
            JOIN CP_ALMACEN a
              ON a.id_almacen = v.id_almacen
            JOIN CP_SUCURSAL s
              ON s.id_sucursal = a.id_sucursal
            WHERE v.cantidad_actual > 0
              AND v.fecha_vencimiento >= v_today
              AND v.fecha_vencimiento <  v_today + v_days + 1
            ORDER BY v.fecha_vencimiento, s.nombre_sucursal,
                     v.nombre_producto, v.numero_lote;

        RETURN v_cursor;

    END expiring_lots;


    FUNCTION stale_lots(
        p_today IN DATE DEFAULT TRUNC(SYSDATE)
    ) RETURN SYS_REFCURSOR
    IS
        v_cursor SYS_REFCURSOR;
        v_today  DATE   := TRUNC(p_today);
        v_months NUMBER := positive_parameter('ANTIGUEDAD_BODEGA_MESES');
    BEGIN

        OPEN v_cursor FOR
            SELECT s.nombre_sucursal,
                   v.nombre_almacen,
                   v.nombre_producto,
                   v.numero_lote,
                   v.fecha_ingreso,
                   v.fecha_vencimiento,
                   v.cantidad_actual
            FROM VW_CP_INVENTARIO_ACTUAL v
            JOIN CP_ALMACEN a
              ON a.id_almacen = v.id_almacen
            JOIN CP_SUCURSAL s
              ON s.id_sucursal = a.id_sucursal
            WHERE v.cantidad_actual > 0
              AND v.fecha_ingreso < ADD_MONTHS(v_today, -v_months)
            ORDER BY v.fecha_ingreso, s.nombre_sucursal,
                     v.nombre_producto, v.numero_lote;

        RETURN v_cursor;

    END stale_lots;


    -- Recorre un cursor de lotes y agrega al texto una seccion con su
    -- titulo, el total de lotes y unidades, y las lineas (hasta el maximo).
    PROCEDURE append_section(
        p_text        IN OUT NOCOPY CLOB,
        p_title       IN VARCHAR2,
        p_cursor      IN OUT SYS_REFCURSOR,
        p_show_expiry IN BOOLEAN
    )
    IS
        v_row   t_lot_row;
        v_lots  PLS_INTEGER := 0;
        v_units NUMBER      := 0;
        v_lines CLOB;
    BEGIN

        LOOP
            FETCH p_cursor INTO v_row;
            EXIT WHEN p_cursor%NOTFOUND;

            v_lots  := v_lots + 1;
            v_units := v_units + v_row.cantidad_actual;

            IF v_lots <= c_max_lines THEN
                v_lines := v_lines
                    || '- ' || v_row.nombre_sucursal || ' / ' || v_row.nombre_almacen
                    || ': ' || v_row.nombre_producto
                    || ' (lote ' || v_row.numero_lote || '), '
                    || CASE
                           WHEN p_show_expiry
                           THEN 'vence ' || TO_CHAR(v_row.fecha_vencimiento, 'DD/MM/YYYY')
                           ELSE 'ingreso ' || TO_CHAR(v_row.fecha_ingreso, 'DD/MM/YYYY')
                       END
                    || ', ' || format_quantity(v_row.cantidad_actual) || ' unidades'
                    || CHR(10);
            END IF;
        END LOOP;

        CLOSE p_cursor;

        p_text := p_text || p_title || ': ' || v_lots || ' lotes, '
                  || format_quantity(v_units) || ' unidades' || CHR(10);

        IF v_lots = 0 THEN
            p_text := p_text || '  Ninguno.' || CHR(10);
        ELSE
            p_text := p_text || v_lines;
            IF v_lots > c_max_lines THEN
                p_text := p_text || '... y ' || (v_lots - c_max_lines)
                          || ' lotes mas (ver la consulta en la base de datos).'
                          || CHR(10);
            END IF;
        END IF;

    END append_section;


    FUNCTION build_report(
        p_today IN DATE DEFAULT TRUNC(SYSDATE)
    ) RETURN CLOB
    IS
        v_today  DATE := TRUNC(p_today);
        v_days   NUMBER := positive_parameter('VENCIMIENTO_VENTANA_DIAS');
        v_months NUMBER := positive_parameter('ANTIGUEDAD_BODEGA_MESES');
        v_cursor SYS_REFCURSOR;
        v_text   CLOB;
    BEGIN

        v_text := 'Reporte semanal de inventario del '
                  || TO_CHAR(v_today, 'DD/MM/YYYY') || CHR(10) || CHR(10);

        v_cursor := expiring_lots(v_today);
        append_section(
            v_text,
            '1. Productos que vencen en los proximos ' || v_days || ' dias',
            v_cursor,
            TRUE
        );

        v_text := v_text || CHR(10);

        v_cursor := stale_lots(v_today);
        append_section(
            v_text,
            '2. Productos con mas de ' || v_months || ' meses en bodega',
            v_cursor,
            FALSE
        );

        RETURN v_text;

    END build_report;


    PROCEDURE send_weekly_report(
        p_today  IN DATE    DEFAULT TRUNC(SYSDATE),
        p_commit IN BOOLEAN DEFAULT TRUE
    )
    IS
        v_report CLOB;
    BEGIN

        SAVEPOINT sp_send_weekly_report;

        v_report := build_report(p_today);

        -- Queda en cola sin confirmar: el COMMIT de abajo lo confirma
        -- junto con lo demas. queue_notice no lanza errores; si no puede
        -- encolar, lo registra y el reporte termina igual.
        PKG_CP_AVISO.queue_notice(
            p_type    => c_tipo_aviso,
            p_subject => 'Reporte semanal de inventario del '
                         || TO_CHAR(TRUNC(p_today), 'DD/MM/YYYY'),
            p_message => v_report
        );

        IF p_commit THEN
            COMMIT;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            -- Se deshace solo lo de este reporte; lo anterior de la sesion queda
            ROLLBACK TO SAVEPOINT sp_send_weekly_report;
            PKG_CP_ERROR.registrar_inesperado(
                c_modulo,
                'fecha=' || TO_CHAR(p_today, 'DD/MM/YYYY')
            );
            RAISE;
    END send_weekly_report;

END PKG_CP_VENCIMIENTO;
/

SHOW ERRORS PACKAGE BODY PKG_CP_VENCIMIENTO

-- ============================================================
-- 3. PRUEBAS DEL REPORTE
-- ============================================================
-- Todas deben salir OK. Se ejecutan como CP_POS y todo se deshace con
-- ROLLBACK. Se compra un lote de prueba con la API de facturacion
-- (vence en 30 dias, ingresa hoy) y se mueve la fecha "de hoy" que
-- recibe el paquete para probar cada frontera sin esperar al calendario.
-- Solo se borran de la bitacora los errores provocados a proposito.
-- Los avisos se apagan durante las pruebas (PKG_CP_AVISO.set_enabled)
-- para no dejar correos reales en cola; la prueba 13 los enciende con
-- el procedimiento semanal sin confirmar, y el ROLLBACK lo deshace.

DECLARE
    v_antes       NUMBER;
    v_notif_antes NUMBER;
    v_ok          NUMBER := 0;
    v_falla       NUMBER := 0;
    v_status      VARCHAR2(12);
    v_notices     NUMBER;

    v_prov        NUMBER;
    v_neg         NUMBER;
    v_pp          NUMBER;
    v_alm         NUMBER;
    v_user        NUMBER;
    v_invoice     NUMBER;
    v_lots        PKG_CP_FACTURACION.t_lineas_compra;

    v_today       DATE   := TRUNC(SYSDATE);
    v_stamp       VARCHAR2(20) := TO_CHAR(SYSDATE, 'MMDDHH24MISS');
    v_lot_number  VARCHAR2(50);
    v_count       NUMBER;
    v_text        CLOB;
    v_code        NUMBER;
    v_codes_ok    BOOLEAN;
    v_zeroed      BOOLEAN := FALSE;
    v_lot_id      NUMBER;
    v_reason      NUMBER;
    v_return_id   NUMBER;
    v_returns     PKG_CP_FACTURACION.t_lineas_dev_compra;

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

    -- Indica si el lote de prueba aparece en la lista pedida
    FUNCTION lot_listed(
        p_kind  IN VARCHAR2,
        p_today IN DATE
    ) RETURN BOOLEAN
    IS
        v_cursor SYS_REFCURSOR;
        v_row    PKG_CP_VENCIMIENTO.t_lot_row;
        v_found  BOOLEAN := FALSE;
    BEGIN
        IF p_kind = 'EXPIRING' THEN
            v_cursor := PKG_CP_VENCIMIENTO.expiring_lots(p_today);
        ELSE
            v_cursor := PKG_CP_VENCIMIENTO.stale_lots(p_today);
        END IF;

        LOOP
            FETCH v_cursor INTO v_row;
            EXIT WHEN v_cursor%NOTFOUND;
            IF v_row.numero_lote = v_lot_number THEN
                v_found := TRUE;
                EXIT;
            END IF;
        END LOOP;

        CLOSE v_cursor;
        RETURN v_found;
    END lot_listed;

    FUNCTION report_code(
        p_today IN DATE
    ) RETURN NUMBER
    IS
        v_report CLOB;
    BEGIN
        v_report := PKG_CP_VENCIMIENTO.build_report(p_today);
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN SQLCODE;
    END report_code;

BEGIN

    SELECT NVL(MAX(id_bitacora_error), 0) INTO v_antes FROM CP_BITACORA_ERROR;
    SELECT NVL(MAX(id_notificacion), 0) INTO v_notif_antes FROM CP_NOTIFICACION;

    PKG_CP_AVISO.set_enabled(FALSE);

    -- Datos para la compra del lote de prueba (primer proveedor con credito)
    SELECT id_proveedor, id_negocio
    INTO v_prov, v_neg
    FROM CP_CREDITO_PROVEEDOR
    ORDER BY id_credito_proveedor
    FETCH FIRST 1 ROW ONLY;

    SELECT MIN(id_producto_proveedor) INTO v_pp
    FROM CP_PRODUCTO_PROVEEDOR WHERE id_proveedor = v_prov;

    SELECT MIN(a.id_almacen) INTO v_alm
    FROM CP_ALMACEN a
    JOIN CP_SUCURSAL s ON s.id_sucursal = a.id_sucursal
    WHERE s.id_negocio = v_neg;

    SELECT MIN(id_usuario) INTO v_user FROM CP_USUARIO;

    v_lot_number := 'T28-' || v_stamp;

    v_lots(1).id_producto_proveedor := v_pp;
    v_lots(1).cantidad := 5;
    v_lots(1).precio_costo_unitario := 1000;
    v_lots(1).porcentaje_descuento := 0;
    v_lots(1).porcentaje_impuesto := 0;
    v_lots(1).numero_lote := v_lot_number;
    v_lots(1).fecha_vencimiento := v_today + 30;

    BEGIN
        PKG_CP_FACTURACION.registrar_compra(
            p_id_proveedor         => v_prov,
            p_id_negocio           => v_neg,
            p_id_almacen_recepcion => v_alm,
            p_id_usuario           => v_user,
            p_numero_factura       => 'T28-C-' || v_stamp,
            p_lineas               => v_lots,
            p_id_factura           => v_invoice,
            p_a_credito            => FALSE,
            p_commit               => FALSE
        );
        v_codes_ok := TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            v_codes_ok := FALSE;
    END;

    SELECT NVL(SUM(cantidad_actual), 0) INTO v_count
    FROM VW_CP_INVENTARIO_ACTUAL WHERE numero_lote = v_lot_number;

    reportar('1. La compra de prueba dejo un lote de 5 unidades en inventario',
             v_codes_ok AND v_count = 5);

    -- ------------------------------------------------------------
    -- A. Fronteras de "por vencer" (el lote vence en hoy + 30)
    -- ------------------------------------------------------------
    reportar('2. Faltando 7 dias entra en por vencer (limite inclusive)',
             lot_listed('EXPIRING', v_today + 23));
    reportar('3. Faltando 8 dias todavia no entra',
             NOT lot_listed('EXPIRING', v_today + 22));
    reportar('4. Faltando 3 dias entra',
             lot_listed('EXPIRING', v_today + 27));
    reportar('5. Si vence hoy todavia entra',
             lot_listed('EXPIRING', v_today + 30));
    reportar('6. Un lote ya vencido no entra (es de otro aviso)',
             NOT lot_listed('EXPIRING', v_today + 31));

    -- ------------------------------------------------------------
    -- B. Fronteras de antiguedad (el lote ingreso hoy)
    -- ------------------------------------------------------------
    reportar('7. Con exactamente 6 meses todavia no es antiguo',
             NOT lot_listed('STALE', ADD_MONTHS(v_today, 6)));
    reportar('8. Con 6 meses y un dia ya es antiguo',
             lot_listed('STALE', ADD_MONTHS(v_today, 6) + 1));

    -- ------------------------------------------------------------
    -- C. Parametros
    -- ------------------------------------------------------------
    PKG_CP_PARAMETRO.guardar('VENCIMIENTO_VENTANA_DIAS', '10');
    v_codes_ok := lot_listed('EXPIRING', v_today + 20);
    PKG_CP_PARAMETRO.guardar('VENCIMIENTO_VENTANA_DIAS', '7');

    reportar('9. La ventana es un parametro: con 10 dias entra el que vence en 10',
             v_codes_ok AND NOT lot_listed('EXPIRING', v_today + 20));

    PKG_CP_PARAMETRO.guardar('ANTIGUEDAD_BODEGA_MESES', '3');
    v_codes_ok := lot_listed('STALE', ADD_MONTHS(v_today, 3) + 1);
    PKG_CP_PARAMETRO.guardar('ANTIGUEDAD_BODEGA_MESES', '6');

    reportar('10. Los meses son un parametro: con 3 meses ya es antiguo',
             v_codes_ok AND NOT lot_listed('STALE', ADD_MONTHS(v_today, 3) + 1));

    -- ------------------------------------------------------------
    -- D. El mensaje y el procedimiento semanal
    -- ------------------------------------------------------------
    v_text := PKG_CP_VENCIMIENTO.build_report(v_today + 23);

    reportar('11. El mensaje trae las dos secciones por separado y el lote',
             DBMS_LOB.INSTR(v_text, 'Reporte semanal de inventario') > 0
             AND DBMS_LOB.INSTR(v_text, '1. Productos que vencen en los proximos 7 dias') > 0
             AND DBMS_LOB.INSTR(v_text, '2. Productos con mas de 6 meses en bodega') > 0
             AND DBMS_LOB.INSTR(v_text, v_lot_number) > 0);

    BEGIN
        PKG_CP_VENCIMIENTO.send_weekly_report(v_today + 23, FALSE);
        v_codes_ok := TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            v_codes_ok := FALSE;
    END;

    reportar('12. El procedimiento semanal corre sin error y sin confirmar',
             v_codes_ok);

    -- Avisos encendidos y sin confirmar: el reporte queda en cola o, si
    -- el modulo de correo no esta listo, se registra por que no pudo.
    PKG_CP_AVISO.set_enabled(TRUE);
    BEGIN
        PKG_CP_VENCIMIENTO.send_weekly_report(v_today + 23, FALSE);
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
      AND tipo_notificacion = 'REPORTE_INVENTARIO';

    DBMS_OUTPUT.PUT_LINE('   estado del aviso del reporte: ' || NVL(v_status, '<ninguno>'));

    reportar('13. El reporte deja un aviso en cola o registra por que no pudo',
             v_codes_ok
             AND ((v_status = 'ENCOLADO' AND v_count = 1)
                  OR (v_status = 'FALLIDO' AND v_count = 0)));

    -- ------------------------------------------------------------
    -- E. Parametro invalido
    -- ------------------------------------------------------------
    PKG_CP_PARAMETRO.guardar('VENCIMIENTO_VENTANA_DIAS', '0');
    v_code := report_code(v_today);
    PKG_CP_PARAMETRO.guardar('VENCIMIENTO_VENTANA_DIAS', '7');

    reportar('14. Una ventana en 0 da -20310', v_code = -20310);

    PKG_CP_PARAMETRO.guardar('ANTIGUEDAD_BODEGA_MESES', '0');
    v_code := report_code(v_today);
    PKG_CP_PARAMETRO.guardar('ANTIGUEDAD_BODEGA_MESES', '6');

    reportar('15. Unos meses en 0 dan -20310', v_code = -20310);

    SELECT COUNT(*) INTO v_count
    FROM CP_BITACORA_ERROR
    WHERE id_bitacora_error > v_antes AND modulo = 'VENCIMIENTO';

    reportar('16. Los 2 errores quedaron UNA sola vez en la bitacora',
             v_count = 2);

    -- ------------------------------------------------------------
    -- F. Sin existencia no se lista
    -- ------------------------------------------------------------
    -- Se devuelve todo el lote al proveedor con la API: el inventario queda en 0
    -- (un UPDATE directo al inventario lo bloquean los triggers de proteccion)
    BEGIN
        SELECT id_lote_producto INTO v_lot_id
        FROM CP_LOTE_PRODUCTO WHERE numero_lote = v_lot_number;

        SELECT id_motivo_devolucion INTO v_reason
        FROM CP_MOTIVO_DEVOLUCION WHERE nombre_motivo_devolucion = 'PRODUCTO DANADO';

        v_returns(1).id_lote_producto := v_lot_id;
        v_returns(1).id_motivo_devolucion := v_reason;
        v_returns(1).cantidad := 5;

        PKG_CP_FACTURACION.registrar_devolucion_compra(
            p_id_factura    => v_invoice,
            p_id_usuario    => v_user,
            p_lineas        => v_returns,
            p_id_devolucion => v_return_id,
            p_commit        => FALSE
        );

        SELECT NVL(SUM(cantidad_actual), 0) INTO v_count
        FROM VW_CP_INVENTARIO_ACTUAL WHERE numero_lote = v_lot_number;

        v_zeroed := v_count = 0;
    EXCEPTION
        WHEN OTHERS THEN
            v_zeroed := FALSE;
    END;

    IF v_zeroed THEN
        reportar('17. Un lote sin existencia no se lista en ninguna seccion',
                 NOT lot_listed('EXPIRING', v_today + 23)
                 AND NOT lot_listed('STALE', ADD_MONTHS(v_today, 6) + 1));
    ELSE
        DBMS_OUTPUT.PUT_LINE(
            RPAD('17. Un lote sin existencia no se lista en ninguna seccion', 72, '.')
            || ' omitida (no se pudo devolver el lote al proveedor)');
    END IF;

    -- ------------------------------------------------------------
    -- G. Limpieza
    -- ------------------------------------------------------------
    ROLLBACK;

    SELECT COUNT(*) INTO v_count
    FROM CP_LOTE_PRODUCTO WHERE numero_lote = v_lot_number;

    SELECT COUNT(*) INTO v_notices
    FROM CP_NOTIFICACION
    WHERE id_notificacion > v_notif_antes
      AND tipo_notificacion = 'REPORTE_INVENTARIO';

    reportar('18. El ROLLBACK deja la base sin el lote ni el aviso, y con los parametros originales',
             v_count = 0 AND v_notices = 0
             AND PKG_CP_PARAMETRO.obtener_numero('VENCIMIENTO_VENTANA_DIAS') = 7
             AND PKG_CP_PARAMETRO.obtener_numero('ANTIGUEDAD_BODEGA_MESES') = 6);

    DELETE FROM CP_BITACORA_ERROR
    WHERE id_bitacora_error > v_antes
      AND modulo IN ('VENCIMIENTO', 'AVISO', 'PARAMETRO');
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
-- 4. JOB SEMANAL DEL REPORTE
-- ============================================================
-- Corre cada lunes a las 06:00. Se vuelve a crear en cada ejecucion
-- del script (primero se borra). Cada corrida deja el reporte en cola
-- para el coordinador (al relanzar el script tambien se envia uno).
-- A peticion del profesor:
--   EXEC PKG_CP_VENCIMIENTO.send_weekly_report;
-- o lanzar el job al instante con:
--   EXEC DBMS_SCHEDULER.RUN_JOB('JOB_CP_REPORTE_INVENTARIO_SEMANAL', FALSE);

BEGIN

    BEGIN
        DBMS_SCHEDULER.DROP_JOB('JOB_CP_REPORTE_INVENTARIO_SEMANAL', force => TRUE);
    EXCEPTION
        WHEN OTHERS THEN
            -- ORA-27475: el job no existe todavia, no es un error
            IF SQLCODE != -27475 THEN
                RAISE;
            END IF;
    END;

    DBMS_SCHEDULER.CREATE_JOB(
        job_name        => 'JOB_CP_REPORTE_INVENTARIO_SEMANAL',
        job_type        => 'PLSQL_BLOCK',
        job_action      => 'BEGIN PKG_CP_VENCIMIENTO.send_weekly_report; END;',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=WEEKLY;BYDAY=MON;BYHOUR=6;BYMINUTE=0;BYSECOND=0',
        enabled         => TRUE,
        comments        => 'Reporte semanal de productos por vencer y con mucho tiempo en bodega.'
    );

END;
/

-- Lanza el job una vez y espera para ver su resultado en el historial
BEGIN
    DBMS_SCHEDULER.RUN_JOB('JOB_CP_REPORTE_INVENTARIO_SEMANAL', FALSE);
    DBMS_SESSION.SLEEP(5);
END;
/

SELECT job_name, enabled, state, repeat_interval, next_run_date
FROM   user_scheduler_jobs
WHERE  job_name = 'JOB_CP_REPORTE_INVENTARIO_SEMANAL';

SELECT job_name, status, actual_start_date, run_duration, errors
FROM   user_scheduler_job_run_details
WHERE  job_name = 'JOB_CP_REPORTE_INVENTARIO_SEMANAL'
ORDER  BY log_date DESC
FETCH FIRST 3 ROWS ONLY;
