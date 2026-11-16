-- ============================================================
-- JOB: JOB_CP_MONITOREO_SESIONES
-- MODULO: Notificaciones/CP_notificaciones_paquetes.sql
-- REQUISITOS: ejecutar como CP_POS despues de instalar el paquete indicado.
-- NOTA: este archivo es la definicion individual para entrega/administracion.
--       El script de modulo tambien crea este job; ejecute solo una definicion
--       cuando instale o reconstruya el job, no ambas consecutivamente.
-- ============================================================
BEGIN
    BEGIN
        DBMS_SCHEDULER.DROP_JOB('JOB_CP_MONITOREO_SESIONES', force => TRUE);
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -27475 THEN
                RAISE;
            END IF;
    END;

    DBMS_SCHEDULER.CREATE_JOB(
        job_name        => 'JOB_CP_MONITOREO_SESIONES',
        job_type        => 'PLSQL_BLOCK',
        job_action      => 'BEGIN PKG_CP_MONITOREO.check_sessions; END;',
        start_date      => SYSTIMESTAMP AT TIME ZONE 'America/Costa_Rica',
        repeat_interval => 'FREQ=MINUTELY;INTERVAL=15',
        enabled         => TRUE,
        auto_drop       => FALSE,
        comments        => 'Uso de sesiones y procesos, y sesiones bloqueadas.'
    );
END;
/

SELECT job_name, enabled, state, repeat_interval, next_run_date
FROM   user_scheduler_jobs
WHERE  job_name = 'JOB_CP_MONITOREO_SESIONES';
