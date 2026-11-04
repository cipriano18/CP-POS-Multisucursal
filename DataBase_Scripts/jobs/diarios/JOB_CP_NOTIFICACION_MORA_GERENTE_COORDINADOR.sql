
BEGIN
    SYS.DBMS_SCHEDULER.CREATE_JOB(
        job_name        => 'CP_POS.JOB_CP_NOTIFICACION_MORA_GERENTE_COORDINADOR',
        job_type        => 'STORED_PROCEDURE',
        job_action      => 'PRC_CP_NOTIFICACION_MORA_GERENTE_COORDINADOR',
        start_date      => SYSTIMESTAMP + INTERVAL '2' MINUTE,
        repeat_interval => 'FREQ=MINUTELY;INTERVAL=15',
        enabled         => TRUE,
        auto_drop       => FALSE,
        comments        => 'Genera un reporte agrupado de clientes en mora para gerente y coordinador.'
    );
END;
/
