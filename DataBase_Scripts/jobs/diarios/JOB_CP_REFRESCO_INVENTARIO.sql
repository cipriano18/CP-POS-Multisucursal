-- ============================================================
-- JOB: JOB_CP_REFRESCO_INVENTARIO
-- MODULO: negocio/CP_negocio_vistas_materializadas.sql
-- REQUISITOS: ejecutar como CP_POS despues de instalar el paquete indicado.
-- NOTA: este archivo es la definicion individual para entrega/administracion.
--       El script de modulo tambien crea este job; ejecute solo una definicion
--       cuando instale o reconstruya el job, no ambas consecutivamente.
-- ============================================================
BEGIN
    BEGIN
        DBMS_SCHEDULER.DROP_JOB('JOB_CP_REFRESCO_INVENTARIO', force => TRUE);
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -27475 THEN
                RAISE;
            END IF;
    END;

    DBMS_SCHEDULER.CREATE_JOB(
        job_name        => 'JOB_CP_REFRESCO_INVENTARIO',
        job_type        => 'PLSQL_BLOCK',
        job_action      => 'BEGIN PKG_CP_REPORTE.refresh_inventory; END;',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=HOURLY;BYMINUTE=5;BYSECOND=0',
        enabled         => TRUE,
        auto_drop       => FALSE,
        comments        => 'Refresco completo de MV_CP_INVENTARIO_CONSOLIDADO.'
    );
END;
/

SELECT job_name, enabled, state, repeat_interval, next_run_date
FROM   user_scheduler_jobs
WHERE  job_name = 'JOB_CP_REFRESCO_INVENTARIO';
