-- ============================================================
-- JOB: JOB_CP_REVISION_DESCUENTOS
-- MODULO: negocio/CP_negocio_descuento.sql
-- REQUISITOS: ejecutar como CP_POS despues de instalar el paquete indicado.
-- NOTA: este archivo es la definicion individual para entrega/administracion.
--       El script de modulo tambien crea este job; ejecute solo una definicion
--       cuando instale o reconstruya el job, no ambas consecutivamente.
-- ============================================================
BEGIN
    BEGIN
        DBMS_SCHEDULER.DROP_JOB('JOB_CP_REVISION_DESCUENTOS', force => TRUE);
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -27475 THEN
                RAISE;
            END IF;
    END;

    DBMS_SCHEDULER.CREATE_JOB(
        job_name        => 'JOB_CP_REVISION_DESCUENTOS',
        job_type        => 'PLSQL_BLOCK',
        job_action      => 'BEGIN PKG_CP_DESCUENTO.run_weekly_check; END;',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=WEEKLY;BYDAY=MON;BYHOUR=5;BYMINUTE=30;BYSECOND=0',
        enabled         => TRUE,
        auto_drop       => FALSE,
        comments        => 'Revision semanal de descuentos planeados: agrega o desactiva productos.'
    );
END;
/

SELECT job_name, enabled, state, repeat_interval, next_run_date
FROM   user_scheduler_jobs
WHERE  job_name = 'JOB_CP_REVISION_DESCUENTOS';
