-- ============================================================
-- JOB: JOB_CP_PROCESAR_NOTIFICACIONES
-- DESCRIPCION:
-- Procesa las notificaciones pendientes cada 15 minutos.
-- PROCEDIMIENTO:
-- PKG_CP_NOTIFICACIONES.PROCESAR_PENDIENTES
-- ============================================================

BEGIN
    DBMS_SCHEDULER.CREATE_JOB(
        job_name        => 'JOB_CP_PROCESAR_NOTIFICACIONES',
        job_type        => 'STORED_PROCEDURE',
        job_action      => 'PKG_CP_NOTIFICACIONES.PROCESAR_PENDIENTES',
        number_of_arguments => 0,
        repeat_interval => 'FREQ=MINUTELY;INTERVAL=15',
        enabled         => FALSE,
        auto_drop       => FALSE,
        comments        => 'Procesa notificaciones pendientes cada 15 minutos'
    );

    DBMS_SCHEDULER.ENABLE('JOB_CP_PROCESAR_NOTIFICACIONES');
END;
/
