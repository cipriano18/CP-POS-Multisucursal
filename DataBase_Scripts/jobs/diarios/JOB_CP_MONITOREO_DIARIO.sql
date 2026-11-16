-- ============================================================
-- JOB: JOB_CP_MONITOREO_DIARIO
-- MODULO: Notificaciones/CP_notificaciones_paquetes.sql
-- REQUISITOS: ejecutar como CP_POS despues de instalar el paquete indicado.
-- NOTA: este archivo es la definicion individual para entrega/administracion.
--       El script de modulo tambien crea este job; ejecute solo una definicion
--       cuando instale o reconstruya el job, no ambas consecutivamente.
-- ============================================================
BEGIN
    BEGIN
        DBMS_SCHEDULER.DROP_JOB('JOB_CP_MONITOREO_DIARIO', force => TRUE);
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -27475 THEN
                RAISE;
            END IF;
    END;

    DBMS_SCHEDULER.CREATE_JOB(
        job_name        => 'JOB_CP_MONITOREO_DIARIO',
        job_type        => 'PLSQL_BLOCK',
        job_action      => 'BEGIN PKG_CP_MONITOREO.run_daily; END;',
        start_date      => SYSTIMESTAMP AT TIME ZONE 'America/Costa_Rica',
        repeat_interval => 'FREQ=DAILY;BYHOUR=6;BYMINUTE=30;BYSECOND=0',
        enabled         => TRUE,
        auto_drop       => FALSE,
        comments        => 'Crecimiento, tablespaces, objetos invalidos, indices y errores.'
    );
END;
/

SELECT job_name, enabled, state, repeat_interval, next_run_date
FROM   user_scheduler_jobs
WHERE  job_name = 'JOB_CP_MONITOREO_DIARIO';
