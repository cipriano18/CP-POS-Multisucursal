BEGIN
    SYS.DBMS_SCHEDULER.CREATE_JOB(
        job_name        => 'CP_POS.JOB_CP_ALERTA_MORA_CLIENTES',
        job_type        => 'STORED_PROCEDURE',
        job_action      => 'PRC_CP_ALERTA_MORA_CLIENTES',
        start_date      => SYSTIMESTAMP + INTERVAL '2' MINUTE,
        repeat_interval => 'FREQ=MINUTELY;INTERVAL=15',
        enabled         => TRUE,
        auto_drop       => FALSE,
        comments        => 'Detecta clientes con cuentas vencidas y mas de 30 dias sin abonar, con correo principal registrado'
    );
END;
/