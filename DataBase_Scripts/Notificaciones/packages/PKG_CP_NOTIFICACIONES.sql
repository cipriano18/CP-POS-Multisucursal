
CREATE OR REPLACE PACKAGE PKG_CP_NOTIFICACIONES AS

    -- Envía un correo electrónico.
    PROCEDURE enviar_correo(
        p_destinatario IN VARCHAR2,
        p_asunto       IN VARCHAR2,
        p_mensaje      IN VARCHAR2
    );

    -- Procesa las notificaciones pendientes.
    PROCEDURE procesar_pendientes;

    -- Registra una notificación y su destinatario.
    -- No realiza COMMIT.
    PROCEDURE encolar(
        p_tipo    IN VARCHAR2,
        p_asunto  IN VARCHAR2,
        p_mensaje IN VARCHAR2,
        p_correo  IN VARCHAR2
    );

END PKG_CP_NOTIFICACIONES;
/
