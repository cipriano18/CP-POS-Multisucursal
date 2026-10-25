
-- ============================================================
-- PROYECTO: CP-POS MULTISUCURSAL
-- ARCHIVO: verificar_tablespaces.sql
-- DESCRIPCION:
-- Verifica el porcentaje de ocupacion de los tablespaces
-- permanentes de la base de datos.
-- Si alguno alcanza o supera el 85%, envia una alerta
-- al correo configurado en CP_PARAMETRO.
-- PARAMETRO: CORREO_ALERTAS_BD
-- ============================================================

CREATE OR REPLACE PROCEDURE verificar_tablespaces
AS
    v_mensaje   VARCHAR2(32767);
    v_correo    VARCHAR2(300);
    v_cantidad  NUMBER := 0;
BEGIN
    v_mensaje :=
        'ALERTA DE ESPACIO EN TABLESPACES' || CHR(10) ||
        'Base de datos: ' ||
        SYS_CONTEXT('USERENV', 'DB_NAME') || CHR(10) ||
        'Contenedor: ' ||
        SYS_CONTEXT('USERENV', 'CON_NAME') || CHR(10) ||
        'Umbral: 85%' || CHR(10) || CHR(10);

    -- Revisar tablespaces permanentes.
    -- Se considera la capacidad maxima de los archivos
    -- cuando tienen AUTOEXTEND habilitado.

    FOR r IN (
        WITH archivos AS (
            SELECT
                TABLESPACE_NAME,
                SUM(BYTES) AS bytes_asignados,
                SUM(
                    CASE
                        WHEN AUTOEXTENSIBLE = 'YES'
                        THEN GREATEST(BYTES, MAXBYTES)
                        ELSE BYTES
                    END
                ) AS bytes_maximos
            FROM DBA_DATA_FILES
            GROUP BY TABLESPACE_NAME
        ),
        libres AS (
            SELECT
                TABLESPACE_NAME,
                SUM(BYTES) AS bytes_libres
            FROM DBA_FREE_SPACE
            GROUP BY TABLESPACE_NAME
        )
        SELECT
            a.TABLESPACE_NAME,
            ROUND(
                (a.bytes_asignados -
                 NVL(l.bytes_libres, 0)) /
                NULLIF(a.bytes_maximos, 0) * 100,
                2
            ) AS PORCENTAJE_USO
        FROM archivos a
        LEFT JOIN libres l
            ON a.TABLESPACE_NAME = l.TABLESPACE_NAME
        WHERE
            (a.bytes_asignados -
             NVL(l.bytes_libres, 0)) /
            NULLIF(a.bytes_maximos, 0) * 100 >= 85
        ORDER BY PORCENTAJE_USO DESC
    )
    LOOP
        v_cantidad := v_cantidad + 1;

        v_mensaje := v_mensaje ||
            'Tablespace: ' || r.TABLESPACE_NAME || CHR(10) ||
            'Porcentaje de uso: ' ||
            TO_CHAR(r.PORCENTAJE_USO) || '%' ||
            CHR(10) || CHR(10);
    END LOOP;

    IF v_cantidad > 0 THEN

        -- Obtener destinatario configurado.
        v_correo := PKG_CP_PARAMETRO.obtener_texto(
            'CORREO_ALERTAS_BD'
        );

        IF TRIM(v_correo) IS NULL THEN
            RAISE_APPLICATION_ERROR(
                -20053,
                'No se ha configurado el correo de alertas'
            );
        END IF;

        -- Enviar un solo correo con los tablespaces afectados.
        PKG_CP_NOTIFICACIONES.enviar_correo(
            p_destinatario => v_correo,
            p_asunto       => 'Alerta: tablespaces al 85% en CP-POS',
            p_mensaje      => SUBSTR(v_mensaje, 1, 4000)
        );

        DBMS_OUTPUT.PUT_LINE(
            'Alerta enviada. Tablespaces afectados: ' ||
            v_cantidad
        );

    ELSE
        DBMS_OUTPUT.PUT_LINE(
            'Verificacion correcta: ningun tablespace ' ||
            'permanente alcanza el 85% de ocupacion.'
        );
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(
            'Error al verificar tablespaces: ' || SQLERRM
        );
        RAISE;
END verificar_tablespaces;
/
