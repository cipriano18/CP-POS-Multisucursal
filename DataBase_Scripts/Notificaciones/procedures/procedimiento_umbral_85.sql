CREATE OR REPLACE PROCEDURE PRC_CP_ALERTA_CXP_COORDINADOR
IS
    v_correo              VARCHAR2(300);
    v_umbral              NUMBER;
    v_id_contacto         NUMBER;
    v_id_destinatario     NUMBER;
    v_id_configuracion    NUMBER;
    v_id_notificacion     NUMBER;
    v_cantidad            NUMBER := 0;
    v_mensaje             VARCHAR2(32767);
    v_existe              NUMBER;

BEGIN
    -- 1. Leer parámetros
    v_correo := TRIM(
        PKG_CP_PARAMETRO.obtener_texto('CORREO_ALERTAS_BD')
    );

    v_umbral :=
        PKG_CP_PARAMETRO.obtener_numero(
            'UMBRAL_CXP_COORDINADOR_PCT'
        );

    IF v_correo IS NULL OR v_umbral <= 0 THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'El correo o el umbral del coordinador no son validos.'
        );
    END IF;

    -- 2. Evitar duplicar la notificación diaria
    SELECT COUNT(*)
    INTO v_existe
    FROM CP_NOTIFICACION
    WHERE tipo_notificacion = 'ALERTA_CXP_COORDINADOR_85'
      AND TRUNC(fecha_creacion) = TRUNC(SYSDATE);

    IF v_existe > 0 THEN
        RETURN;
    END IF;

    -- 3. Obtener la configuración de correo activa
    SELECT MIN(id_configuracion_correo)
    INTO v_id_configuracion
    FROM CP_CONFIGURACION_CORREO
    WHERE activo = 'S';

    IF v_id_configuracion IS NULL THEN
        RAISE_APPLICATION_ERROR(
            -20002,
            'No existe una configuracion de correo activa.'
        );
    END IF;

    -- 4. Buscar los proveedores que alcanzaron el umbral
    v_mensaje :=
        'REPORTE DE CUENTAS POR PAGAR' || CHR(10) ||
        'Proveedores que alcanzaron el ' ||
        TO_CHAR(v_umbral) || '% o mas de su limite de credito.' ||
        CHR(10) || CHR(10);

    FOR r IN (
        WITH ABONOS AS (
            SELECT
                id_cuenta_pagar,
                SUM(monto_abono) AS total_abonado
            FROM CP_ABONO_CUENTA_PAGAR
            GROUP BY id_cuenta_pagar
        ),
        SALDOS AS (
            SELECT
                cp.id_factura_compra,
                SUM(
                    GREATEST(
                        fc.total - NVL(a.total_abonado, 0),
                        0
                    )
                ) AS saldo_pendiente
            FROM CP_CUENTA_PAGAR cp
            JOIN CP_FACTURA_COMPRA fc
                ON fc.id_factura_compra = cp.id_factura_compra
            LEFT JOIN ABONOS a
                ON a.id_cuenta_pagar = cp.id_cuenta_pagar
            JOIN CP_ESTADO_CUENTA_PAGAR ec
                ON ec.id_estado_cuenta_pagar =
                   cp.id_estado_cuenta_pagar
            WHERE UPPER(ec.nombre_estado_cuenta_pagar)
                  IN ('PENDIENTE', 'PARCIAL', 'VENCIDA')
            GROUP BY cp.id_factura_compra
        )
        SELECT
            p.id_proveedor,
            p.razon_social,
            cr.id_credito_proveedor,
            cr.limite_credito,
            SUM(s.saldo_pendiente) AS saldo_pendiente,
            ROUND(
                SUM(s.saldo_pendiente) /
                NULLIF(cr.limite_credito, 0) * 100,
                2
            ) AS porcentaje_utilizado
        FROM CP_CREDITO_PROVEEDOR cr
        JOIN CP_PROVEEDOR p
            ON p.id_proveedor = cr.id_proveedor
        JOIN CP_ESTADO_CREDITO e
            ON e.id_estado_credito = cr.id_estado_credito
        JOIN CP_FACTURA_COMPRA fc
            ON fc.id_proveedor = p.id_proveedor
           AND fc.id_negocio = cr.id_negocio
        JOIN SALDOS s
            ON s.id_factura_compra = fc.id_factura_compra
        WHERE UPPER(e.nombre_estado_credito) = 'ACTIVO'
          AND cr.limite_credito > 0
        GROUP BY
            p.id_proveedor,
            p.razon_social,
            cr.id_credito_proveedor,
            cr.limite_credito
        HAVING SUM(s.saldo_pendiente) >=
               cr.limite_credito * (v_umbral / 100)
        ORDER BY porcentaje_utilizado DESC
    )
    LOOP
        v_cantidad := v_cantidad + 1;

        v_mensaje := v_mensaje ||
            'Proveedor: ' || r.razon_social || CHR(10) ||
            'Limite de credito: ' ||
                TO_CHAR(r.limite_credito, 'FM999G999G999G990D00') ||
                CHR(10) ||
            'Saldo pendiente: ' ||
                TO_CHAR(r.saldo_pendiente, 'FM999G999G999G990D00') ||
                CHR(10) ||
            'Porcentaje utilizado: ' ||
                TO_CHAR(r.porcentaje_utilizado) || '%' ||
                CHR(10) ||
            '----------------------------------------' ||
            CHR(10);
    END LOOP;

    -- 5. Si no hay proveedores, no genera notificacion
    IF v_cantidad = 0 THEN
        RETURN;
    END IF;

    v_mensaje := v_mensaje ||
        CHR(10) || 'Total de creditos que alcanzaron el umbral: ' ||
        TO_CHAR(v_cantidad);

    -- 6. Buscar o registrar el contacto de correo del coordinador
    BEGIN
        SELECT c.id_contacto
        INTO v_id_contacto
        FROM CP_CONTACTO c
        JOIN CP_TIPO_DE_CONTACTO tc
            ON tc.id_tipo_contacto = c.id_tipo_contacto
        WHERE UPPER(tc.nombre_tipo_contacto) = 'CORREO'
          AND LOWER(TRIM(c.valor_contacto)) = LOWER(v_correo)
          AND ROWNUM = 1;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            SELECT id_tipo_contacto
            INTO v_id_contacto
            FROM CP_TIPO_DE_CONTACTO
            WHERE UPPER(nombre_tipo_contacto) = 'CORREO';

            INSERT INTO CP_CONTACTO (
                id_tipo_contacto,
                valor_contacto
            )
            VALUES (
                v_id_contacto,
                v_correo
            )
            RETURNING id_contacto INTO v_id_contacto;
    END;

    -- 7. Registrar o activar el destinatario
    MERGE INTO CP_DESTINATARIO_NOTIFICACION d
    USING (
        SELECT v_id_contacto AS id_contacto
        FROM dual
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

    -- 8. Crear una sola notificacion agrupada
    INSERT INTO CP_NOTIFICACION (
        id_configuracion_correo,
        asunto,
        mensaje,
        tipo_notificacion
    )
    VALUES (
        v_id_configuracion,
        'Alerta: proveedores con credito utilizado igual o superior al umbral',
        v_mensaje,
        'ALERTA_CXP_COORDINADOR_85'
    )
    RETURNING id_notificacion INTO v_id_notificacion;

    -- 9. Registrar destinatario pendiente de envio
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
            'PRC_CP_ALERTA_CXP_COORDINADOR'
        );
        RAISE;
END PRC_CP_ALERTA_CXP_COORDINADOR;
/