CREATE OR REPLACE PACKAGE BODY PKG_CP_NOTIFICACIONES AS

    PROCEDURE enviar_correo(
        p_destinatario IN VARCHAR2,
        p_asunto       IN VARCHAR2,
        p_mensaje      IN VARCHAR2
    )
    AS
        v_conexion  UTL_SMTP.CONNECTION;
        v_servidor  VARCHAR2(200);
        v_puerto    NUMBER;
        v_usuario   VARCHAR2(200);
        v_clave_raw RAW(2000);
        v_clave     VARCHAR2(200);
        v_tls       CHAR(1);
        v_conectado BOOLEAN := FALSE;
    BEGIN
        SELECT SERVIDOR_SMTP,
               PUERTO_SMTP,
               USUARIO_SMTP,
               CLAVE_CIFRADA,
               REQUIERE_TLS
          INTO v_servidor,
               v_puerto,
               v_usuario,
               v_clave_raw,
               v_tls
          FROM CP_CONFIGURACION_CORREO
         WHERE ACTIVO = 'S'
           AND ROWNUM = 1;

        v_clave := PKG_CP_CRIPTO.descifrar(v_clave_raw);

        v_conexion := UTL_SMTP.OPEN_CONNECTION(
            host => v_servidor,
            port => v_puerto,
            tx_timeout => 30,
            wallet_path => 'file:/opt/oracle/wallets/smtp',
            secure_connection_before_smtp => FALSE
        );

        v_conectado := TRUE;

        UTL_SMTP.EHLO(v_conexion, 'localhost');

        IF v_tls = 'S' THEN
            UTL_SMTP.STARTTLS(v_conexion);
            UTL_SMTP.EHLO(v_conexion, 'localhost');
        ELSE
            RAISE_APPLICATION_ERROR(
                -20050,
                'La configuracion SMTP debe utilizar TLS.'
            );
        END IF;

        UTL_SMTP.AUTH(
            c        => v_conexion,
            username => v_usuario,
            password => v_clave,
            schemes  => 'LOGIN'
        );

        UTL_SMTP.MAIL(v_conexion, v_usuario);
        UTL_SMTP.RCPT(v_conexion, p_destinatario);

        UTL_SMTP.OPEN_DATA(v_conexion);

        UTL_SMTP.WRITE_DATA(
            v_conexion,
            'From: ' || v_usuario || UTL_TCP.CRLF ||
            'To: ' || p_destinatario || UTL_TCP.CRLF ||
            'Subject: ' || p_asunto || UTL_TCP.CRLF ||
            'Content-Type: text/plain; charset=UTF-8' ||
            UTL_TCP.CRLF ||
            UTL_TCP.CRLF ||
            p_mensaje
        );

        UTL_SMTP.CLOSE_DATA(v_conexion);
        UTL_SMTP.QUIT(v_conexion);

        v_conectado := FALSE;

        DBMS_OUTPUT.PUT_LINE(
            'CORREO ENVIADO A: ' || p_destinatario
        );

    EXCEPTION
        WHEN OTHERS THEN
            IF v_conectado THEN
                BEGIN
                    UTL_SMTP.QUIT(v_conexion);
                EXCEPTION
                    WHEN OTHERS THEN NULL;
                END;
            END IF;

            RAISE;
    END enviar_correo;


    PROCEDURE procesar_pendientes
    AS
        v_enviados NUMBER := 0;
        v_errores  NUMBER := 0;
        v_error    VARCHAR2(1000);

        v_lock_result NUMBER;
        v_release_result NUMBER;
        v_lock_id CONSTANT INTEGER := 108240321;
        v_lock_obtenido BOOLEAN := FALSE;

        PROCEDURE liberar_bloqueo
        AS
        BEGIN
            IF v_lock_obtenido THEN
                v_release_result := DBMS_LOCK.RELEASE(
                    id => v_lock_id
                );

                v_lock_obtenido := FALSE;

                IF v_release_result <> 0 THEN
                    RAISE_APPLICATION_ERROR(
                        -20056,
                        'No se pudo liberar el bloqueo de notificaciones.'
                    );
                END IF;
            END IF;
        END liberar_bloqueo;

    BEGIN
        -- Bloqueo exclusivo de la ejecucion.
        -- No se libera mediante COMMIT ni ROLLBACK.
        v_lock_result := DBMS_LOCK.REQUEST(
            id                => v_lock_id,
            lockmode          => DBMS_LOCK.X_MODE,
            timeout           => 0,
            release_on_commit => FALSE
        );

        IF v_lock_result = 1 THEN
            DBMS_OUTPUT.PUT_LINE(
                'Ya existe otra ejecucion procesando notificaciones.'
            );
            RETURN;
        ELSIF v_lock_result <> 0 THEN
            RAISE_APPLICATION_ERROR(
                -20055,
                'No se pudo obtener el bloqueo. Codigo: ' ||
                v_lock_result
            );
        END IF;

        v_lock_obtenido := TRUE;

        FOR r IN (
            SELECT ND.ID_NOTIFICACION_DESTINATARIO,
                   C.VALOR_CONTACTO AS CORREO,
                   N.ASUNTO,
                   N.MENSAJE
              FROM CP_NOTIFICACION_DESTINATARIO ND
              JOIN CP_NOTIFICACION N
                ON N.ID_NOTIFICACION = ND.ID_NOTIFICACION
              JOIN CP_DESTINATARIO_NOTIFICACION D
                ON D.ID_DESTINATARIO = ND.ID_DESTINATARIO
              JOIN CP_CONTACTO C
                ON C.ID_CONTACTO = D.ID_CONTACTO
             WHERE ND.ESTADO_ENVIO = 'PENDIENTE'
               AND D.ACTIVO = 'S'
             ORDER BY ND.ID_NOTIFICACION_DESTINATARIO
        )
        LOOP
            BEGIN
                enviar_correo(
                    p_destinatario => r.CORREO,
                    p_asunto       => r.ASUNTO,
                    p_mensaje      => r.MENSAJE
                );

                UPDATE CP_NOTIFICACION_DESTINATARIO
                   SET ESTADO_ENVIO = 'ENVIADO',
                       FECHA_ENVIO = SYSTIMESTAMP,
                       DETALLE_ERROR = NULL
                 WHERE ID_NOTIFICACION_DESTINATARIO =
                       r.ID_NOTIFICACION_DESTINATARIO
                   AND ESTADO_ENVIO = 'PENDIENTE';

                COMMIT;

                v_enviados := v_enviados + 1;

            EXCEPTION
                WHEN OTHERS THEN
                    v_error := SUBSTR(SQLERRM, 1, 1000);

                    ROLLBACK;

                    UPDATE CP_NOTIFICACION_DESTINATARIO
                       SET ESTADO_ENVIO = 'ERROR',
                           DETALLE_ERROR = v_error
                     WHERE ID_NOTIFICACION_DESTINATARIO =
                           r.ID_NOTIFICACION_DESTINATARIO
                       AND ESTADO_ENVIO = 'PENDIENTE';

                    COMMIT;

                    v_errores := v_errores + 1;
            END;
        END LOOP;

        liberar_bloqueo;

        DBMS_OUTPUT.PUT_LINE(
            'NOTIFICACIONES ENVIADAS: ' || v_enviados
        );

        DBMS_OUTPUT.PUT_LINE(
            'NOTIFICACIONES CON ERROR: ' || v_errores
        );

    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                v_error_original VARCHAR2(4000) := SQLERRM;
            BEGIN
                ROLLBACK;

                BEGIN
                    liberar_bloqueo;
                EXCEPTION
                    WHEN OTHERS THEN
                        DBMS_OUTPUT.PUT_LINE(
                            'Error al liberar el bloqueo: ' || SQLERRM
                        );
                END;

                DBMS_OUTPUT.PUT_LINE(
                    'Error al procesar las notificaciones pendientes: ' ||
                    v_error_original
                );

                RAISE;
            END;
    END procesar_pendientes;


    PROCEDURE encolar(
        p_tipo    IN VARCHAR2,
        p_asunto  IN VARCHAR2,
        p_mensaje IN VARCHAR2,
        p_correo  IN VARCHAR2
    )
    AS
        v_id_configuracion NUMBER;
        v_id_contacto      NUMBER;
        v_id_destinatario  NUMBER;
        v_id_notificacion  NUMBER;
    BEGIN
        -- Validar los datos recibidos.
        IF p_correo IS NULL OR TRIM(p_correo) IS NULL THEN
            RAISE_APPLICATION_ERROR(
                -20060,
                'El correo del destinatario es obligatorio.'
            );
        END IF;

        IF p_asunto IS NULL OR p_mensaje IS NULL THEN
            RAISE_APPLICATION_ERROR(
                -20061,
                'El asunto y el mensaje son obligatorios.'
            );
        END IF;

        -- Obtener la configuracion de correo activa.
        SELECT ID_CONFIGURACION_CORREO
          INTO v_id_configuracion
          FROM CP_CONFIGURACION_CORREO
         WHERE ACTIVO = 'S'
           AND ROWNUM = 1;

        -- Buscar el contacto correspondiente al correo.
        SELECT ID_CONTACTO
          INTO v_id_contacto
          FROM CP_CONTACTO
         WHERE LOWER(TRIM(VALOR_CONTACTO)) =
               LOWER(TRIM(p_correo));

        -- Buscar el destinatario activo asociado al contacto.
        SELECT ID_DESTINATARIO
          INTO v_id_destinatario
          FROM CP_DESTINATARIO_NOTIFICACION
         WHERE ID_CONTACTO = v_id_contacto
           AND ACTIVO = 'S';

        -- Insertar la notificacion. El id lo pone el DEFAULT de la
        -- columna (SEQ_CP_NOTIFICACION.NEXTVAL) y RETURNING devuelve
        -- exactamente ese valor. No se usa SELECT MAX(...): con dos
        -- sesiones encolando a la vez, MAX puede devolver el id de la
        -- otra sesion y el destinatario quedaria en el aviso equivocado.
        INSERT INTO CP_NOTIFICACION (
            ID_CONFIGURACION_CORREO,
            ASUNTO,
            MENSAJE,
            TIPO_NOTIFICACION,
            FECHA_CREACION
        ) VALUES (
            v_id_configuracion,
            p_asunto,
            p_mensaje,
            p_tipo,
            SYSTIMESTAMP
        )
        RETURNING ID_NOTIFICACION INTO v_id_notificacion;

        -- Insertar la relacion con el destinatario (su id tambien sale
        -- del DEFAULT con SEQ_CP_NOTIFICACION_DESTINATARIO.NEXTVAL).
        INSERT INTO CP_NOTIFICACION_DESTINATARIO (
            ID_NOTIFICACION,
            ID_DESTINATARIO,
            ESTADO_ENVIO
        ) VALUES (
            v_id_notificacion,
            v_id_destinatario,
            'PENDIENTE'
        );

        DBMS_OUTPUT.PUT_LINE(
            'Notificacion registrada como PENDIENTE para: ' ||
            p_correo
        );

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(
                -20062,
                'No existe una configuracion activa, un contacto o un destinatario para el correo indicado.'
            );

        WHEN TOO_MANY_ROWS THEN
            RAISE_APPLICATION_ERROR(
                -20063,
                'Se encontraron varios registros para la configuracion o el destinatario.'
            );
    END encolar;

END PKG_CP_NOTIFICACIONES;
/

SHOW ERRORS PACKAGE BODY PKG_CP_NOTIFICACIONES
