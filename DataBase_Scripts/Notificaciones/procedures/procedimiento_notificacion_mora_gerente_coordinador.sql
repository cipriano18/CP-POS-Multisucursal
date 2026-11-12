
CREATE OR REPLACE PROCEDURE PRC_CP_NOTIFICACION_MORA_GERENTE_COORDINADOR
AS
    v_correo             VARCHAR2(320);
    v_id_tipo_contacto   CP_TIPO_DE_CONTACTO.ID_TIPO_CONTACTO%TYPE;
    v_id_contacto        CP_CONTACTO.ID_CONTACTO%TYPE;
    v_id_configuracion   CP_CONFIGURACION_CORREO.ID_CONFIGURACION_CORREO%TYPE;
    v_id_destinatario    CP_DESTINATARIO_NOTIFICACION.ID_DESTINATARIO%TYPE;
    v_id_notificacion    CP_NOTIFICACION.ID_NOTIFICACION%TYPE;
    v_mensaje            VARCHAR2(32767);
    v_cantidad           NUMBER := 0;

    -- Dias sin abonar para considerar moroso a un cliente (parametrizado;
    -- el cursor lo lee al abrirse, por eso se declara antes que el).
    v_dias               NUMBER := PKG_CP_PARAMETRO.obtener_numero('MOROSIDAD_DIAS_SIN_PAGO');

    CURSOR c_clientes IS
        WITH ABONOS AS (
            SELECT cc.id_cuenta_cobrar,
                   SUM(a.monto_abono) AS total_abonado,
                   MAX(a.fecha_abono) AS ultimo_abono
            FROM CP_CUENTA_COBRAR cc
            LEFT JOIN CP_ABONO_CUENTA_COBRAR a
              ON a.id_cuenta_cobrar = cc.id_cuenta_cobrar
            GROUP BY cc.id_cuenta_cobrar
        ),
        CUENTAS_CLIENTE AS (
            SELECT fv.id_cliente,
                   MAX(a.ultimo_abono) AS fecha_ultimo_abono,
                   MIN(cc.fecha_creacion) AS fecha_primera_cuenta
            FROM CP_CUENTA_COBRAR cc
            JOIN CP_FACTURA_VENTA fv
              ON fv.id_factura_venta = cc.id_factura_venta
            LEFT JOIN ABONOS a
              ON a.id_cuenta_cobrar = cc.id_cuenta_cobrar
            GROUP BY fv.id_cliente
        ),
        CLIENTES_MORA AS (
            SELECT fv.id_cliente,
                   COUNT(DISTINCT cc.id_cuenta_cobrar) AS cantidad_cuentas,
                   SUM(
                       GREATEST(
                           fv.total - NVL(a.total_abonado, 0),
                           0
                       )
                   ) AS saldo_pendiente,
                   MIN(cc.fecha_vencimiento) AS vencimiento_mas_antiguo
            FROM CP_CUENTA_COBRAR cc
            JOIN CP_FACTURA_VENTA fv
              ON fv.id_factura_venta = cc.id_factura_venta
            LEFT JOIN ABONOS a
              ON a.id_cuenta_cobrar = cc.id_cuenta_cobrar
            JOIN CP_ESTADO_CUENTA_COBRAR ec
              ON ec.id_estado_cuenta_cobrar =
                 cc.id_estado_cuenta_cobrar
            WHERE UPPER(ec.nombre_estado_cuenta_cobrar)
                  IN ('PENDIENTE', 'PARCIAL', 'VENCIDA')
              AND cc.fecha_vencimiento < TRUNC(SYSDATE)
            GROUP BY fv.id_cliente
        )
        SELECT cl.id_cliente,
               TRIM(
                   NVL(p.primer_nombre, '') || ' ' ||
                   NVL(p.segundo_nombre, '') || ' ' ||
                   NVL(p.primer_apellido, '') || ' ' ||
                   NVL(p.segundo_apellido, '')
               ) AS nombre_cliente,
               cm.cantidad_cuentas,
               cm.saldo_pendiente,
               cm.vencimiento_mas_antiguo,
               NVL(
                   cc.fecha_ultimo_abono,
                   cc.fecha_primera_cuenta
               ) AS fecha_referencia,
               TRUNC(SYSDATE) -
               TRUNC(
                   NVL(
                       cc.fecha_ultimo_abono,
                       cc.fecha_primera_cuenta
                   )
               ) AS dias_sin_abonar
        FROM CLIENTES_MORA cm
        JOIN CUENTAS_CLIENTE cc
          ON cc.id_cliente = cm.id_cliente
        JOIN CP_CLIENTE cl
          ON cl.id_cliente = cm.id_cliente
        JOIN CP_CLIENTE_PERSONA cp
          ON cp.id_cliente = cl.id_cliente
        JOIN CP_PERSONA p
          ON p.id_persona = cp.id_persona
        WHERE NVL(
                  cc.fecha_ultimo_abono,
                  cc.fecha_primera_cuenta
              ) < TRUNC(SYSDATE) - v_dias
        ORDER BY dias_sin_abonar DESC;

BEGIN
    v_correo := PKG_CP_PARAMETRO.obtener_texto('CORREO_ALERTAS_BD');

    IF v_correo IS NULL THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'No esta configurado CORREO_ALERTAS_BD.'
        );
    END IF;

    -- Evitar generar mas de una notificacion diaria.
    SELECT COUNT(*)
      INTO v_cantidad
      FROM CP_NOTIFICACION
     WHERE tipo_notificacion = 'ALERTA_MORA_GERENTE_COORDINADOR'
       AND fecha_creacion >= TRUNC(SYSDATE)
       AND fecha_creacion < TRUNC(SYSDATE) + 1;

    IF v_cantidad > 0 THEN
        RETURN;
    END IF;

    -- Obtener el tipo de contacto CORREO.
    SELECT MIN(id_tipo_contacto)
      INTO v_id_tipo_contacto
      FROM CP_TIPO_DE_CONTACTO
     WHERE UPPER(nombre_tipo_contacto) = 'CORREO';

    IF v_id_tipo_contacto IS NULL THEN
        RAISE_APPLICATION_ERROR(
            -20002,
            'No existe el tipo de contacto CORREO.'
        );
    END IF;

    -- Buscar o registrar el correo configurado.
    BEGIN
        SELECT id_contacto
          INTO v_id_contacto
          FROM CP_CONTACTO
         WHERE id_tipo_contacto = v_id_tipo_contacto
           AND LOWER(valor_contacto) = LOWER(v_correo)
           AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO CP_CONTACTO (
                id_tipo_contacto,
                valor_contacto
            )
            VALUES (
                v_id_tipo_contacto,
                v_correo
            )
            RETURNING id_contacto INTO v_id_contacto;
    END;

    -- Obtener una configuracion de correo activa.
    SELECT MIN(id_configuracion_correo)
      INTO v_id_configuracion
      FROM CP_CONFIGURACION_CORREO
     WHERE activo = 'S';

    IF v_id_configuracion IS NULL THEN
        RAISE_APPLICATION_ERROR(
            -20003,
            'No existe una configuracion de correo activa.'
        );
    END IF;

    v_mensaje :=
        'REPORTE DE CLIENTES EN MORA' ||
        CHR(10) || CHR(10) ||
        'Notificacion dirigida al gerente y al coordinador.' ||
        CHR(10) ||
        'Se muestran clientes con cuentas vencidas y mas de ' || v_dias || ' dias ' ||
        'sin realizar abonos.' ||
        CHR(10) || CHR(10);

    v_cantidad := 0;

    FOR r IN c_clientes LOOP
        v_cantidad := v_cantidad + 1;

        v_mensaje := v_mensaje ||
            'Cliente: ' || r.nombre_cliente || CHR(10) ||
            'ID cliente: ' || r.id_cliente || CHR(10) ||
            'Cuentas vencidas pendientes: ' ||
                r.cantidad_cuentas || CHR(10) ||
            'Saldo pendiente: ' ||
                TO_CHAR(
                    r.saldo_pendiente,
                    'FM999G999G999G990D00'
                ) || CHR(10) ||
            'Vencimiento mas antiguo: ' ||
                TO_CHAR(r.vencimiento_mas_antiguo, 'DD/MM/YYYY') ||
                CHR(10) ||
            'Fecha de referencia del ultimo abono: ' ||
                TO_CHAR(r.fecha_referencia, 'DD/MM/YYYY') ||
                CHR(10) ||
            'Dias sin abonar: ' || r.dias_sin_abonar ||
                CHR(10) ||
            '----------------------------------------' || CHR(10);
    END LOOP;

    -- No generar notificacion si no hay clientes que cumplan.
    IF v_cantidad = 0 THEN
        RETURN;
    END IF;

    v_mensaje := v_mensaje ||
        CHR(10) ||
        'Total de clientes en mora: ' || v_cantidad;

    -- Activar o registrar el destinatario.
    MERGE INTO CP_DESTINATARIO_NOTIFICACION d
    USING (
        SELECT v_id_contacto AS id_contacto
        FROM DUAL
    ) x
    ON (d.id_contacto = x.id_contacto)
    WHEN MATCHED THEN
        UPDATE SET d.activo = 'S'
    WHEN NOT MATCHED THEN
        INSERT (id_contacto, activo)
        VALUES (x.id_contacto, 'S');

    SELECT id_destinatario
      INTO v_id_destinatario
      FROM CP_DESTINATARIO_NOTIFICACION
     WHERE id_contacto = v_id_contacto;

    -- Crear una unica notificacion agrupada.
    INSERT INTO CP_NOTIFICACION (
        id_configuracion_correo,
        asunto,
        mensaje,
        tipo_notificacion
    )
    VALUES (
        v_id_configuracion,
        'Reporte de clientes en mora - Gerencia y Coordinacion',
        v_mensaje,
        'ALERTA_MORA_GERENTE_COORDINADOR'
    )
    RETURNING id_notificacion INTO v_id_notificacion;

    INSERT INTO CP_NOTIFICACION_DESTINATARIO (
        id_notificacion,
        id_destinatario,
        estado_envio
    )
    VALUES (
        v_id_notificacion,
        v_id_destinatario,
        'PENDIENTE'
    );

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        PKG_CP_ERROR.registrar_inesperado(
            'PRC_CP_NOTIFICACION_MORA_GERENTE_COORDINADOR',
            SQLERRM
        );
        RAISE;
END;
/
