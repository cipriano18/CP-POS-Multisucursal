CREATE OR REPLACE PROCEDURE PRC_CP_ALERTA_MORA_CLIENTES
AS
    v_id_destinatario       CP_DESTINATARIO_NOTIFICACION.ID_DESTINATARIO%TYPE;
    v_id_notificacion       CP_NOTIFICACION.ID_NOTIFICACION%TYPE;
    v_id_configuracion      CP_CONFIGURACION_CORREO.ID_CONFIGURACION_CORREO%TYPE;
    v_asunto                CP_NOTIFICACION.ASUNTO%TYPE;
    v_mensaje               CP_NOTIFICACION.MENSAJE%TYPE;

    CURSOR c_clientes_mora IS
        WITH ULTIMO_PAGO AS (
            SELECT
                fv.id_cliente,
                MAX(a.fecha_abono) AS fecha_ultimo_pago,
                MIN(c.fecha_creacion) AS fecha_primera_cuenta
            FROM CP_FACTURA_VENTA fv
            JOIN CP_CUENTA_COBRAR c
                ON c.id_factura_venta = fv.id_factura_venta
            LEFT JOIN CP_ABONO_CUENTA_COBRAR a
                ON a.id_cuenta_cobrar = c.id_cuenta_cobrar
            GROUP BY fv.id_cliente
        ),
        CLIENTES_VENCIDOS AS (
            SELECT DISTINCT
                fv.id_cliente
            FROM CP_FACTURA_VENTA fv
            JOIN CP_CUENTA_COBRAR c
                ON c.id_factura_venta = fv.id_factura_venta
            JOIN CP_ESTADO_CUENTA_COBRAR ec
                ON ec.id_estado_cuenta_cobrar =
                   c.id_estado_cuenta_cobrar
            WHERE ec.nombre_estado_cuenta_cobrar
                  IN ('PENDIENTE', 'PARCIAL', 'VENCIDA')
              AND c.fecha_vencimiento < TRUNC(SYSDATE)
        )
        SELECT
            cv.id_cliente,
            NVL(up.fecha_ultimo_pago, up.fecha_primera_cuenta)
                AS fecha_referencia,
            pc.id_contacto,
            co.valor_contacto
        FROM CLIENTES_VENCIDOS cv
        JOIN ULTIMO_PAGO up
            ON up.id_cliente = cv.id_cliente
        JOIN CP_CLIENTE_PERSONA cp
            ON cp.id_cliente = cv.id_cliente
        JOIN CP_PERSONA_CONTACTO pc
            ON pc.id_persona = cp.id_persona
           AND pc.es_principal = 'S'
        JOIN CP_CONTACTO co
            ON co.id_contacto = pc.id_contacto
        JOIN CP_TIPO_DE_CONTACTO tc
            ON tc.id_tipo_contacto = co.id_tipo_contacto
        WHERE tc.nombre_tipo_contacto = 'CORREO'
          AND NVL(up.fecha_ultimo_pago, up.fecha_primera_cuenta)
              < TRUNC(SYSDATE) - 30
          AND EXISTS (
              SELECT 1
              FROM CP_CONFIGURACION_CORREO cc
              WHERE cc.activo = 'S'
          );

BEGIN
    SELECT MIN(id_configuracion_correo)
    INTO v_id_configuracion
    FROM CP_CONFIGURACION_CORREO
    WHERE activo = 'S';

    IF v_id_configuracion IS NULL THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'No existe una configuracion de correo activa.'
        );
    END IF;

    FOR r IN c_clientes_mora LOOP

        v_asunto :=
            'Aviso de mora - Cliente ' || r.id_cliente;

        v_mensaje :=
            'Estimado cliente:' || CHR(10) || CHR(10) ||
            'Le informamos que registra una o mas cuentas por cobrar vencidas.' ||
            CHR(10) ||
            'Su ultimo abono registrado, o la fecha de creacion de su primera cuenta si nunca ha abonado, supera los 30 dias.' ||
            CHR(10) || CHR(10) ||
            'Por favor, comuniquese con nuestro negocio para regularizar su situacion.' ||
            CHR(10) || CHR(10) ||
            'Gracias por su atencion.';

        -- Evitar duplicar la alerta del mismo cliente el mismo dia.
        DECLARE
            v_existe NUMBER;
        BEGIN
            SELECT COUNT(*)
            INTO v_existe
            FROM CP_NOTIFICACION
            WHERE tipo_notificacion = 'ALERTA_MORA_CLIENTE'
              AND asunto = v_asunto
              AND fecha_creacion >= TRUNC(SYSDATE)
              AND fecha_creacion < TRUNC(SYSDATE) + 1;

            IF v_existe = 0 THEN

                MERGE INTO CP_DESTINATARIO_NOTIFICACION d
                USING (
                    SELECT r.id_contacto AS id_contacto
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
                WHERE id_contacto = r.id_contacto;

                INSERT INTO CP_NOTIFICACION (
                    id_configuracion_correo,
                    asunto,
                    mensaje,
                    tipo_notificacion
                )
                VALUES (
                    v_id_configuracion,
                    v_asunto,
                    v_mensaje,
                    'ALERTA_MORA_CLIENTE'
                )
                RETURNING id_notificacion
                INTO v_id_notificacion;

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

            END IF;
        END;

    END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END PRC_CP_ALERTA_MORA_CLIENTES;
/