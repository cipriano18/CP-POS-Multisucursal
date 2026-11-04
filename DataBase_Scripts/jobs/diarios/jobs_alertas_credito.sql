BEGIN
    SYS.DBMS_SCHEDULER.CREATE_JOB(
        job_name        => 'CP_POS.JOB_CP_ALERTA_CREDITO_85',
        job_type        => 'STORED_PROCEDURE',
        job_action      => 'PRC_CP_ALERTA_CREDITO_85',
        start_date      => SYSTIMESTAMP + INTERVAL '1' MINUTE,
        repeat_interval => 'FREQ=MINUTELY;INTERVAL=15',
        enabled         => TRUE,
        auto_drop       => FALSE,
        comments        => 'Detecta creditos con utilizacion igual o superior al 85% cada 15 minutos'
    );
END;
/