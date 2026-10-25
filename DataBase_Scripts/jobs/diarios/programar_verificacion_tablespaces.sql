
-- ============================================================
-- PROYECTO: CP-POS MULTISUCURSAL
-- ARCHIVO: programar_verificacion_tablespaces.sql
-- DESCRIPCION:
-- Programa la verificacion diaria de tablespaces.
-- FRECUENCIA: Todos los dias a las 2:00 p. m.
-- ZONA HORARIA: Costa Rica
-- ============================================================

DECLARE
    v_existe NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_existe
      FROM USER_SCHEDULER_JOBS
     WHERE JOB_NAME = 'JOB_CP_VERIFICAR_TABLESPACES';

    IF v_existe = 0 THEN

        DBMS_SCHEDULER.CREATE_JOB(
            job_name        => 'JOB_CP_VERIFICAR_TABLESPACES',
            job_type        => 'STORED_PROCEDURE',
            job_action      => 'VERIFICAR_TABLESPACES',
            start_date      => SYSTIMESTAMP
                               AT TIME ZONE 'America/Costa_Rica',
            repeat_interval => 'FREQ=DAILY;BYHOUR=14;BYMINUTE=0;BYSECOND=0',
            enabled         => TRUE,
            auto_drop       => FALSE,
            comments        => 'Verificacion diaria de tablespaces'
        );

        DBMS_OUTPUT.PUT_LINE(
            'Job de tablespaces creado correctamente.'
        );

    ELSE

        DBMS_SCHEDULER.SET_ATTRIBUTE(
            name      => 'JOB_CP_VERIFICAR_TABLESPACES',
            attribute => 'start_date',
            value     => SYSTIMESTAMP
                         AT TIME ZONE 'America/Costa_Rica'
        );

        DBMS_SCHEDULER.SET_ATTRIBUTE(
            name      => 'JOB_CP_VERIFICAR_TABLESPACES',
            attribute => 'repeat_interval',
            value     => 'FREQ=DAILY;BYHOUR=14;BYMINUTE=0;BYSECOND=0'
        );

        DBMS_SCHEDULER.ENABLE(
            'JOB_CP_VERIFICAR_TABLESPACES'
        );

        DBMS_OUTPUT.PUT_LINE(
            'Job de tablespaces actualizado correctamente.'
        );

    END IF;
END;
/
