-- ============================================================
-- PROYECTO: CP-POS MULTISUCURSAL
-- ARCHIVO: verificacion_objetos_invalidos.sql
-- DESCRIPCION:
-- Programa la verificacion diaria de objetos invalidos.
-- Si encuentra inconsistencias, envia una alerta al correo
-- configurado en el parametro CORREO_ALERTAS_BD.
--
-- FRECUENCIA: Todos los dias a las 2:00 p. m.
-- ZONA HORARIA: Costa Rica
-- ============================================================

BEGIN
    -- Si el trabajo ya existe, actualizar su horario.
    -- Si no existe, crearlo.

    DECLARE
        v_existe NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO v_existe
          FROM USER_SCHEDULER_JOBS
         WHERE JOB_NAME = 'JOB_CP_VERIFICAR_OBJETOS_INVALIDOS';

        IF v_existe = 0 THEN

            DBMS_SCHEDULER.CREATE_JOB(
                job_name        => 'JOB_CP_VERIFICAR_OBJETOS_INVALIDOS',
                job_type        => 'STORED_PROCEDURE',
                job_action      => 'VERIFICAR_OBJETOS_INVALIDOS',
                start_date      => SYSTIMESTAMP
                                   AT TIME ZONE 'America/Costa_Rica',
                repeat_interval => 'FREQ=DAILY;BYHOUR=14;BYMINUTE=0;BYSECOND=0',
                enabled         => TRUE,
                auto_drop       => FALSE,
                comments        => 'Verificacion diaria de objetos invalidos'
            );

            DBMS_OUTPUT.PUT_LINE(
                'Trabajo creado para las 2:00 p. m.'
            );

        ELSE

            DBMS_SCHEDULER.SET_ATTRIBUTE(
                name      => 'JOB_CP_VERIFICAR_OBJETOS_INVALIDOS',
                attribute => 'repeat_interval',
                value     => 'FREQ=DAILY;BYHOUR=14;BYMINUTE=0;BYSECOND=0'
            );

            DBMS_SCHEDULER.SET_ATTRIBUTE(
                name      => 'JOB_CP_VERIFICAR_OBJETOS_INVALIDOS',
                attribute => 'start_date',
                value     => SYSTIMESTAMP
                             AT TIME ZONE 'America/Costa_Rica'
            );

            DBMS_SCHEDULER.ENABLE(
                'JOB_CP_VERIFICAR_OBJETOS_INVALIDOS'
            );

            DBMS_OUTPUT.PUT_LINE(
                'Trabajo actualizado para las 2:00 p. m.'
            );

        END IF;
    END;
END;
/