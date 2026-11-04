-- ============================================================
-- PROYECTO: CP-POS MULTISUCURSAL
-- ARCHIVO: verificar_indices.sql
-- DESCRIPCION:
-- Verifica indices UNUSABLE en el esquema CP_POS.
-- Incluye indices normales y particiones de indices.
-- Si encuentra problemas, envia una alerta al correo
-- configurado en CP_PARAMETRO.
-- PARAMETRO: CORREO_ALERTAS_BD
-- ============================================================

CREATE OR REPLACE PROCEDURE verificar_indices
AS
    v_cantidad NUMBER;
    v_mensaje  VARCHAR2(4000);
    v_correo   VARCHAR2(300);
BEGIN

    -- Contar indices y particiones de indices inutilizables.
    SELECT SUM(cantidad)
      INTO v_cantidad
      FROM (
          SELECT COUNT(*) AS cantidad
            FROM USER_INDEXES
           WHERE STATUS = 'UNUSABLE'

          UNION ALL

          SELECT COUNT(*)
            FROM USER_IND_PARTITIONS
           WHERE STATUS = 'UNUSABLE'

          UNION ALL

          SELECT COUNT(*)
            FROM USER_IND_SUBPARTITIONS
           WHERE STATUS = 'UNUSABLE'
      );

    IF v_cantidad > 0 THEN

        v_mensaje :=
            'ALERTA DE INDICES CON PROBLEMAS' || CHR(10) ||
            'Esquema: ' || USER || CHR(10) ||
            'Cantidad de indices o particiones inutilizables: '
            || v_cantidad;

        -- Obtener el destinatario configurado.
        v_correo := PKG_CP_PARAMETRO.obtener_texto(
            'CORREO_ALERTAS_BD'
        );

        IF TRIM(v_correo) IS NULL THEN
            RAISE_APPLICATION_ERROR(
                -20052,
                'No se ha configurado el correo de alertas'
            );
        END IF;

        -- Enviar correo solamente si existen problemas.
        PKG_CP_NOTIFICACIONES.enviar_correo(
            p_destinatario => v_correo,
            p_asunto       => 'Alerta: indices con problemas en CP-POS',
            p_mensaje      => v_mensaje
        );

        DBMS_OUTPUT.PUT_LINE(
            'Alerta de indices enviada correctamente.'
        );

    ELSE

        DBMS_OUTPUT.PUT_LINE(
            'Verificacion correcta: no existen indices inutilizables.'
        );

    END IF;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(
            'Error al verificar indices: ' || SQLERRM
        );
        RAISE;
END verificar_indices;
/