
-- ============================================================
-- PROYECTO: CP-POS MULTISUCURSAL
-- ARCHIVO: programar_verificacion_indices.sql
-- DESCRIPCION:
-- Programa la verificacion diaria de indices inutilizables.
-- Si encuentra inconsistencias, el procedimiento envia
-- una alerta al correo configurado en CP_PARAMETRO.
--
-- FRECUENCIA: Todos los dias a las 2:00 p. m.
-- ZONA HORARIA: Costa Rica
-- ============================================================

DECLARE
    v_existe NUMBER;
BEGIN
    -- Verificar si el job ya existe.
    SELECT COUNT(*)
      INTO v_existe
      FROM USER_SCHEDULER_JOBS
     WHERE JOB_NAME = 'JOB_CP_VERIFICAR_INDICES';

    IF v_existe = 0 THEN

        -- Crear el job.
        DBMS_SCHEDULER.CREATE_JOB(
            job_name        => 'JOB_CP_VERIFICAR_INDICES',
            job_type        => 'STORED_PROCEDURE',
            job_action      => 'VERIFICAR_INDICES',
            start_date      => SYSTIMESTAMP
                               AT TIME ZONE 'America/Costa_Rica',
            repeat_interval => 'FREQ=DAILY;BYHOUR=14;BYMINUTE=0;BYSECOND=0',
            enabled         => TRUE,
            auto_drop       => FALSE,
            comments        => 'Verificacion diaria de indices en CP_POS'
        );

        DBMS_OUTPUT.PUT_LINE(
            'Job de indices creado correctamente.'
        );

    ELSE

        -- Actualizar el horario si el job ya existe.
        DBMS_SCHEDULER.SET_ATTRIBUTE(
            name      => 'JOB_CP_VERIFICAR_INDICES',
            attribute => 'start_date',
            value     => SYSTIMESTAMP
                         AT TIME ZONE 'America/Costa_Rica'
        );

        DBMS_SCHEDULER.SET_ATTRIBUTE(
            name      => 'JOB_CP_VERIFICAR_INDICES',
            attribute => 'repeat_interval',
            value     => 'FREQ=DAILY;BYHOUR=14;BYMINUTE=0;BYSECOND=0'
        );

        DBMS_SCHEDULER.ENABLE(
            'JOB_CP_VERIFICAR_INDICES'
        );

        DBMS_OUTPUT.PUT_LINE(
            'Job de indices actualizado correctamente.'
        );

    END IF;
END;
/
