CREATE OR REPLACE PROCEDURE PRC_CP_NOTIFICACION_PRODUCTOS_VENCIDOS_COORD
AS
    v_id_notificacion       CP_NOTIFICACION.ID_NOTIFICACION%TYPE;
    v_id_configuracion      CP_CONFIGURACION_CORREO.ID_CONFIGURACION_CORREO%TYPE;
    v_correo_alertas        VARCHAR2(320);
    v_mensaje               CLOB;
    v_total_lotes           NUMBER := 0;
    v_total_productos       NUMBER := 0;
    v_total_unidades        NUMBER := 0;
    v_hay_productos         BOOLEAN := FALSE;

BEGIN
    -- Obtener el correo configurado para las alertas.
    v_correo_alertas :=
        PKG_CP_PARAMETRO.obtener_texto('CORREO_ALERTAS_BD');

    -- Evitar generar más de una alerta diaria.
    SELECT COUNT(*)
      INTO v_total_lotes
      FROM CP_NOTIFICACION
     WHERE TIPO_NOTIFICACION = 'ALERTA_PRODUCTOS_VENCIDOS_COORD'
       AND FECHA_CREACION >= TRUNC(SYSDATE)
       AND FECHA_CREACION < TRUNC(SYSDATE) + 1;

    IF v_total_lotes > 0 THEN
        RETURN;
    END IF;

    -- Obtener una configuración de correo activa.
    SELECT MIN(ID_CONFIGURACION_CORREO)
      INTO v_id_configuracion
      FROM CP_CONFIGURACION_CORREO
     WHERE ACTIVO = 'S';

    IF v_id_configuracion IS NULL THEN
        RETURN;
    END IF;

    v_mensaje :=
        'REPORTE DE PRODUCTOS VENCIDOS' || CHR(10) ||
        'Fecha del reporte: ' ||
        TO_CHAR(SYSDATE, 'DD/MM/YYYY') || CHR(10) ||
        '----------------------------------------' || CHR(10);

    -- Recorrer los lotes vencidos que aún tienen existencias.
    FOR r IN (
        SELECT
            p.ID_PRODUCTO,
            p.CODIGO_PRODUCTO,
            p.NOMBRE_PRODUCTO,
            lp.NUMERO_LOTE,
            lp.FECHA_VENCIMIENTO,
            ia.ID_ALMACEN,
            SUM(ia.CANTIDAD_ACTUAL) AS CANTIDAD_DISPONIBLE
        FROM CP_LOTE_PRODUCTO lp
        INNER JOIN CP_DETALLE_COMPRA dc
            ON dc.ID_DETALLE_COMPRA = lp.ID_DETALLE_COMPRA
        INNER JOIN CP_PRODUCTO_PROVEEDOR pp
            ON pp.ID_PRODUCTO_PROVEEDOR = dc.ID_PRODUCTO_PROVEEDOR
        INNER JOIN CP_PRODUCTO p
            ON p.ID_PRODUCTO = pp.ID_PRODUCTO
        INNER JOIN CP_INVENTARIO_ALMACEN ia
            ON ia.ID_LOTE_PRODUCTO = lp.ID_LOTE_PRODUCTO
        WHERE lp.FECHA_VENCIMIENTO < TRUNC(SYSDATE)
          AND NVL(ia.CANTIDAD_ACTUAL, 0) > 0
        GROUP BY
            p.ID_PRODUCTO,
            p.CODIGO_PRODUCTO,
            p.NOMBRE_PRODUCTO,
            lp.NUMERO_LOTE,
            lp.FECHA_VENCIMIENTO,
            ia.ID_ALMACEN
        ORDER BY
            lp.FECHA_VENCIMIENTO,
            p.NOMBRE_PRODUCTO
    )
    LOOP
        v_hay_productos := TRUE;
        v_total_lotes := v_total_lotes + 1;
        v_total_unidades := v_total_unidades + r.CANTIDAD_DISPONIBLE;

        v_mensaje := v_mensaje ||
            CHR(10) ||
            'Producto: ' || r.NOMBRE_PRODUCTO || CHR(10) ||
            'Código: ' || r.CODIGO_PRODUCTO || CHR(10) ||
            'Lote: ' || r.NUMERO_LOTE || CHR(10) ||
            'Vencimiento: ' ||
                TO_CHAR(r.FECHA_VENCIMIENTO, 'DD/MM/YYYY') || CHR(10) ||
            'Almacén: ' || r.ID_ALMACEN || CHR(10) ||
            'Cantidad disponible: ' ||
                TO_CHAR(r.CANTIDAD_DISPONIBLE) || CHR(10) ||
            '----------------------------------------' || CHR(10);
    END LOOP;

    -- No generar notificación si no hay productos vencidos con existencias.
    IF NOT v_hay_productos THEN
        RETURN;
    END IF;

    -- Contar productos diferentes.
    SELECT COUNT(DISTINCT p.ID_PRODUCTO)
      INTO v_total_productos
      FROM CP_LOTE_PRODUCTO lp
      INNER JOIN CP_DETALLE_COMPRA dc
          ON dc.ID_DETALLE_COMPRA = lp.ID_DETALLE_COMPRA
      INNER JOIN CP_PRODUCTO_PROVEEDOR pp
          ON pp.ID_PRODUCTO_PROVEEDOR = dc.ID_PRODUCTO_PROVEEDOR
      INNER JOIN CP_PRODUCTO p
          ON p.ID_PRODUCTO = pp.ID_PRODUCTO
      INNER JOIN CP_INVENTARIO_ALMACEN ia
          ON ia.ID_LOTE_PRODUCTO = lp.ID_LOTE_PRODUCTO
     WHERE lp.FECHA_VENCIMIENTO < TRUNC(SYSDATE)
       AND NVL(ia.CANTIDAD_ACTUAL, 0) > 0;

    v_mensaje := v_mensaje ||
        CHR(10) ||
        'RESUMEN' || CHR(10) ||
        'Productos diferentes: ' || v_total_productos || CHR(10) ||
        'Registros de producto/lote/almacén: ' || v_total_lotes || CHR(10) ||
        'Total de unidades vencidas en inventario: ' ||
            TO_CHAR(v_total_unidades) || CHR(10);

    -- Crear la notificación.
    INSERT INTO CP_NOTIFICACION (
        ID_CONFIGURACION_CORREO,
        ASUNTO,
        MENSAJE,
        TIPO_NOTIFICACION,
        FECHA_CREACION
    )
    VALUES (
        v_id_configuracion,
        'Alerta: productos vencidos en inventario',
        v_mensaje,
        'ALERTA_PRODUCTOS_VENCIDOS_COORD',
        SYSDATE
    )
    RETURNING ID_NOTIFICACION INTO v_id_notificacion;

    -- Registrar destinatarios activos que coincidan con el correo de alertas.
    INSERT INTO CP_NOTIFICACION_DESTINATARIO (
        ID_NOTIFICACION,
        ID_DESTINATARIO,
        ESTADO_ENVIO
    )
    SELECT
        v_id_notificacion,
        d.ID_DESTINATARIO,
        'PENDIENTE'
    FROM CP_DESTINATARIO_NOTIFICACION d
    INNER JOIN CP_CONTACTO c
        ON c.ID_CONTACTO = d.ID_CONTACTO
    INNER JOIN CP_TIPO_DE_CONTACTO tc
        ON tc.ID_TIPO_CONTACTO = c.ID_TIPO_CONTACTO
    WHERE d.ACTIVO = 'S'
      AND UPPER(tc.NOMBRE_TIPO_CONTACTO) = 'CORREO'
      AND LOWER(c.VALOR_CONTACTO) = LOWER(v_correo_alertas);

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END PRC_CP_NOTIFICACION_PRODUCTOS_VENCIDOS_COORD;
/