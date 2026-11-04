
BEGIN
    SYS.DBMS_SCHEDULER.CREATE_JOB(
        job_name        => 'CP_POS.JOB_CP_ALERTA_CXP_GERENTE',
        job_type        => 'STORED_PROCEDURE',
        job_action      => 'PRC_CP_ALERTA_CXP_GERENTE',
        start_date      => SYSTIMESTAMP + INTERVAL '2' MINUTE,
        repeat_interval => 'FREQ=MINUTELY;INTERVAL=15',
        enabled         => TRUE,
        auto_drop       => FALSE,
        comments        => 'Notifica al gerente en un unico correo agrupado cuando los proveedores alcanzan el umbral de credito configurado.'
    );
END;
/
