BEGIN
    SYS.DBMS_SCHEDULER.CREATE_JOB(
        job_name        => 'CP_POS.JOB_CP_ALERTA_CXP_COORDINADOR',
        job_type        => 'STORED_PROCEDURE',
        job_action      => 'PRC_CP_ALERTA_CXP_COORDINADOR',
        start_date      => SYSTIMESTAMP + INTERVAL '3' MINUTE,
        repeat_interval => 'FREQ=MINUTELY;INTERVAL=15',
        enabled         => TRUE,
        auto_drop       => FALSE,
        comments        => 'Notifica al coordinador cuando proveedores alcanzan el umbral de credito en cuentas por pagar'
    );
END;
/