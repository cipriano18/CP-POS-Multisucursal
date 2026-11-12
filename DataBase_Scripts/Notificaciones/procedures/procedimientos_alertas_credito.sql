CREATE OR REPLACE PROCEDURE PRC_CP_ALERTA_CREDITO_85
AUTHID DEFINER
IS
    v_id_configuracion NUMBER;
    v_id_destinatario  NUMBER;

    -- Porcentaje del limite de credito que dispara la alerta (parametrizado)
    v_umbral           NUMBER := PKG_CP_PARAMETRO.obtener_numero('UMBRAL_CXC_CLIENTE_PCT');
BEGIN

    /* ============================================================
       1. Obtener configuracion de correo activa
       ============================================================ */
    SELECT MIN(id_configuracion_correo)
    INTO v_id_configuracion
    FROM CP_CONFIGURACION_CORREO
    WHERE activo = 'S';

    IF v_id_configuracion IS NULL THEN
        RAISE_APPLICATION_ERROR(
            -20101,
            'No existe una configuracion de correo activa.'
        );
    END IF;


    /* ============================================================
       2. Buscar creditos con uso >= UMBRAL_CXC_CLIENTE_PCT
          El saldo se calcula:
          total factura - abonos realizados
       ============================================================ */
    FOR r IN (
        SELECT
            cc.id_credito_cliente,
            cc.id_cliente,
            cc.limite_credito,

            SUM(
                GREATEST(
                    fv.total - NVL(ab.total_abonado, 0),
                    0
                )
            ) AS saldo_pendiente,

            ROUND(
                (
                    SUM(
                        GREATEST(
                            fv.total - NVL(ab.total_abonado, 0),
                            0
                        )
                    )
                    / cc.limite_credito
                ) * 100,
                2
            ) AS porcentaje_uso,

            MAX(c.valor_contacto) AS correo_cliente

        FROM CP_CREDITO_CLIENTE cc

        INNER JOIN CP_CUENTA_COBRAR ccc
            ON ccc.id_credito_cliente = cc.id_credito_cliente

        INNER JOIN CP_FACTURA_VENTA fv
            ON fv.id_factura_venta = ccc.id_factura_venta

        INNER JOIN CP_ESTADO_CUENTA_COBRAR ecc
            ON ecc.id_estado_cuenta_cobrar =
               ccc.id_estado_cuenta_cobrar

        LEFT JOIN (
            SELECT
                id_cuenta_cobrar,
                SUM(monto_abono) AS total_abonado
            FROM CP_ABONO_CUENTA_COBRAR
            GROUP BY id_cuenta_cobrar
        ) ab
            ON ab.id_cuenta_cobrar = ccc.id_cuenta_cobrar

        INNER JOIN CP_CLIENTE_PERSONA cp
            ON cp.id_cliente = cc.id_cliente

        INNER JOIN CP_PERSONA_CONTACTO pc
            ON pc.id_persona = cp.id_persona
           AND pc.es_principal = 'S'

        INNER JOIN CP_CONTACTO c
            ON c.id_contacto = pc.id_contacto

        INNER JOIN CP_TIPO_DE_CONTACTO tc
            ON tc.id_tipo_contacto = c.id_tipo_contacto
           AND UPPER(TRIM(tc.nombre_tipo_contacto)) = 'CORREO'

        WHERE cc.id_estado_credito = (
                  SELECT MIN(ec.id_estado_credito)
                  FROM CP_ESTADO_CREDITO ec
                  WHERE UPPER(TRIM(ec.nombre_estado_credito)) = 'ACTIVO'
              )

          AND cc.limite_credito > 0

          AND UPPER(TRIM(ecc.nombre_estado_cuenta_cobrar))
              IN ('PENDIENTE', 'PARCIAL', 'VENCIDA')

        GROUP BY
            cc.id_credito_cliente,
            cc.id_cliente,
            cc.limite_credito

        HAVING
            (
                SUM(
                    GREATEST(
                        fv.total - NVL(ab.total_abonado, 0),
                        0
                    )
                )
                / cc.limite_credito
            ) >= v_umbral / 100
    )
    LOOP

        /* ========================================================
           3. Crear/activar destinatario para el correo
           ======================================================== */

        MERGE INTO CP_DESTINATARIO_NOTIFICACION d
        USING (
            SELECT
                c.id_contacto
            FROM CP_CLIENTE_PERSONA cp
            INNER JOIN CP_PERSONA_CONTACTO pc
                ON pc.id_persona = cp.id_persona
               AND pc.es_principal = 'S'
            INNER JOIN CP_CONTACTO c
                ON c.id_contacto = pc.id_contacto
            INNER JOIN CP_TIPO_DE_CONTACTO tc
                ON tc.id_tipo_contacto = c.id_tipo_contacto
            WHERE cp.id_cliente = r.id_cliente
              AND UPPER(TRIM(tc.nombre_tipo_contacto)) = 'CORREO'
        ) x
        ON (d.id_contacto = x.id_contacto)

        WHEN MATCHED THEN
            UPDATE SET d.activo = 'S'

        WHEN NOT MATCHED THEN
            INSERT (
                id_contacto,
                activo
            )
            VALUES (
                x.id_contacto,
                'S'
            );


        /* ========================================================
           4. Obtener ID del destinatario
           ======================================================== */

        SELECT d.id_destinatario
        INTO v_id_destinatario
        FROM CP_DESTINATARIO_NOTIFICACION d
        INNER JOIN CP_CONTACTO c
            ON c.id_contacto = d.id_contacto
        INNER JOIN CP_TIPO_DE_CONTACTO tc
            ON tc.id_tipo_contacto = c.id_tipo_contacto
        INNER JOIN CP_PERSONA_CONTACTO pc
            ON pc.id_contacto = c.id_contacto
           AND pc.es_principal = 'S'
        INNER JOIN CP_CLIENTE_PERSONA cp
            ON cp.id_persona = pc.id_persona
        WHERE cp.id_cliente = r.id_cliente
          AND UPPER(TRIM(tc.nombre_tipo_contacto)) = 'CORREO'
          AND d.activo = 'S';


        /* ========================================================
           5. Crear notificacion si no existe una igual hoy
           ======================================================== */

        INSERT INTO CP_NOTIFICACION (
            id_configuracion_correo,
            asunto,
            mensaje,
            tipo_notificacion
        )
        SELECT
            v_id_configuracion,

            'Alerta de credito >= ' || v_umbral || '% - Credito '
                || r.id_credito_cliente,

            'Estimado cliente.' || CHR(10) || CHR(10)
                || 'Su credito numero '
                || r.id_credito_cliente
                || ' presenta un nivel de utilizacion de '
                || TO_CHAR(r.porcentaje_uso, 'FM990D00')
                || '%.' || CHR(10) || CHR(10)

                || 'Limite de credito: '
                || TO_CHAR(
                       r.limite_credito,
                       'FM999G999G999G990D00'
                   )
                || CHR(10)

                || 'Saldo pendiente: '
                || TO_CHAR(
                       r.saldo_pendiente,
                       'FM999G999G999G990D00'
                   )
                || CHR(10) || CHR(10)

                || 'Este mensaje corresponde a una alerta '
                || 'automatica del sistema CP-POS.',

            'ALERTA_CREDITO_85'

        FROM DUAL

        WHERE NOT EXISTS (
            SELECT 1
            FROM CP_NOTIFICACION n
            WHERE n.tipo_notificacion = 'ALERTA_CREDITO_85'
              AND n.asunto =
                    'Alerta de credito >= ' || v_umbral || '% - Credito '
                    || r.id_credito_cliente
              AND TRUNC(CAST(n.fecha_creacion AS DATE))
                    = TRUNC(SYSDATE)
        );


        /* ========================================================
           6. Relacionar la notificacion con el destinatario
           ======================================================== */

        INSERT INTO CP_NOTIFICACION_DESTINATARIO (
            id_notificacion,
            id_destinatario,
            estado_envio
        )
        SELECT
            n.id_notificacion,
            v_id_destinatario,
            'PENDIENTE'
        FROM CP_NOTIFICACION n
        WHERE n.tipo_notificacion = 'ALERTA_CREDITO_85'
          AND n.asunto =
                'Alerta de credito >= ' || v_umbral || '% - Credito '
                || r.id_credito_cliente
          AND TRUNC(CAST(n.fecha_creacion AS DATE))
                = TRUNC(SYSDATE)

          AND NOT EXISTS (
              SELECT 1
              FROM CP_NOTIFICACION_DESTINATARIO nd
              WHERE nd.id_notificacion = n.id_notificacion
                AND nd.id_destinatario = v_id_destinatario
          );

    END LOOP;


    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END PRC_CP_ALERTA_CREDITO_85;
/