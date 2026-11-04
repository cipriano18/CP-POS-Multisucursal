BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
        JOB_NAME        => 'JOB_CP_NOTIFICACION_PRODUCTOS_VENCIDOS_COORD',
        JOB_TYPE        => 'STORED_PROCEDURE',
        JOB_ACTION      => 'PRC_CP_NOTIFICACION_PRODUCTOS_VENCIDOS_COORD',
        START_DATE      => SYSTIMESTAMP,
        REPEAT_INTERVAL => 'FREQ=MINUTELY;INTERVAL=15',
        ENABLED         => FALSE,
        COMMENTS        => 'Notifica al coordinador sobre productos vencidos con existencias en inventario.'
    );
END;
/

