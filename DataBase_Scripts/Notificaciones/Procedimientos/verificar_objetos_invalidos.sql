
-- ============================================================
-- PROYECTO: CP-POS MULTISUCURSAL
-- ARCHIVO: verificar_objetos_invalidos.sql
-- DESCRIPCION:
-- Verifica si existen objetos invalidos en el esquema CP_POS.
-- Si encuentra inconsistencias, envia una alerta al correo
-- configurado en CP_PARAMETRO.
-- PARAMETRO: CORREO_ALERTAS_BD
-- EJECUCION: Diaria, mediante Oracle Scheduler a las 2:00 p. m.
-- ============================================================

CREATE OR REPLACE PROCEDURE verificar_objetos_invalidos
AS
    v_cantidad NUMBER;
    v_mensaje  VARCHAR2(4000);
    v_correo   VARCHAR2(300);
BEGIN
    -- Contar los objetos invalidos del esquema.
    SELECT COUNT(*)
      INTO v_cantidad
      FROM USER_OBJECTS
     WHERE STATUS = 'INVALID'
       AND OBJECT_NAME <> 'VERIFICAR_OBJETOS_INVALIDOS';

    IF v_cantidad > 0 THEN

        -- Construir el mensaje de alerta.
        v_mensaje :=
            'ALERTA DE OBJETOS INVALIDOS' || CHR(10) ||
            'Esquema: ' || USER || CHR(10) ||
            'Cantidad de objetos invalidos: ' || v_cantidad;

        -- Obtener el correo desde CP_PARAMETRO.
        v_correo := PKG_CP_PARAMETRO.obtener_texto(
            'CORREO_ALERTAS_BD'
        );

        -- Validar que el correo este configurado.
        IF TRIM(v_correo) IS NULL THEN
            RAISE_APPLICATION_ERROR(
                -20051,
                'No se ha configurado el correo de alertas'
            );
        END IF;

        -- Enviar la alerta al correo configurado.
        PKG_CP_NOTIFICACIONES.enviar_correo(
            p_destinatario => v_correo,
            p_asunto       => 'Alerta: objetos invalidos en CP-POS',
            p_mensaje      => v_mensaje
        );

        DBMS_OUTPUT.PUT_LINE(
            'Alerta enviada al correo: ' || v_correo
        );

    ELSE
        DBMS_OUTPUT.PUT_LINE(
            'Verificacion correcta: no existen objetos invalidos.'
        );
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(
            'Error al verificar objetos invalidos: ' || SQLERRM
        );
        RAISE;
END verificar_objetos_invalidos;
/
