# Jobs de Oracle Scheduler — CP-POS Multisucursal

## Estado de esta carpeta

Esta carpeta incluye un archivo SQL por cada uno de los 11 jobs activos. Los scripts de los módulos `Notificaciones/`, `negocio/` y `Padron/` también crean esos jobs durante la instalación. Los archivos de aquí permiten entregar y administrar cada definición individual; al instalar, ejecute el script del módulo o el SQL individual, no ambos consecutivamente. Los scripts obsoletos se excluyeron de la entrega.

El orden vigente está en `../../ORDEN_EJECUCION.md`, `../../negocio/ORDEN_EJECUCION.md` y `../../Notificaciones/README.md`.

## Jobs vigentes

Cada archivo individual contiene el bloque `DBMS_SCHEDULER.CREATE_JOB` correspondiente. Requiere que el paquete llamado por el job ya exista y esté válido.

| Job | Lo crea | Frecuencia |
|---|---|---|
| `JOB_CP_PROCESAR_NOTIFICACIONES` | `JOB_CP_PROCESAR_NOTIFICACIONES.sql` (también en `Notificaciones/CP_notificaciones_paquetes.sql`) | Cada 15 minutos; envía la cola de correo. |
| `JOB_CP_ALERTAS_NEGOCIO` | `JOB_CP_ALERTAS_NEGOCIO.sql` (`Notificaciones/CP_notificaciones_paquetes.sql`) | Diario a las 07:00. Consolida las alertas de negocio. |
| `JOB_CP_MONITOREO_DIARIO` | `JOB_CP_MONITOREO_DIARIO.sql` (`Notificaciones/CP_notificaciones_paquetes.sql`) | Diario a las 06:30. Consolida objetos inválidos, índices, tablespaces y otros indicadores. |
| `JOB_CP_MONITOREO_SESIONES` | `JOB_CP_MONITOREO_SESIONES.sql` (`Notificaciones/CP_notificaciones_paquetes.sql`) | Cada 15 minutos. |
| `JOB_CP_CIERRE_DIARIO` | `JOB_CP_CIERRE_DIARIO.sql` (`negocio/CP_negocio_cierre.sql`) | Diario a las 00:30. |
| `JOB_CP_REVISION_DESCUENTOS` | `JOB_CP_REVISION_DESCUENTOS.sql` (`negocio/CP_negocio_descuento.sql`) | Lunes a las 05:30. |
| `JOB_CP_REPORTE_INVENTARIO_SEMANAL` | `JOB_CP_REPORTE_INVENTARIO_SEMANAL.sql` (`negocio/CP_negocio_vencimiento.sql`) | Lunes a las 06:00. |
| `JOB_CP_PREMIACION_CLIENTES` | `JOB_CP_PREMIACION_CLIENTES.sql` (`negocio/CP_negocio_premiacion.sql`) | Diario a la 01:15; el período se controla mediante parámetros. |
| `JOB_CP_REFRESCO_VENTAS_MENSUALES` | `JOB_CP_REFRESCO_VENTAS_MENSUALES.sql` (`negocio/CP_negocio_vistas_materializadas.sql`) | Diario a las 00:45. |
| `JOB_CP_REFRESCO_INVENTARIO` | `JOB_CP_REFRESCO_INVENTARIO.sql` (`negocio/CP_negocio_vistas_materializadas.sql`) | Cada hora, al minuto 5. |
| `JOB_CP_CARGA_PADRON` | `JOB_CP_CARGA_PADRON.sql` (`Padron/CP_padron_nacional.sql`) | Mensual, día 1 a las 02:00. |

Los horarios son los definidos en los scripts de la versión documentada. La zona horaria efectiva puede depender de la configuración de Oracle Scheduler.

## Verificar estado y próximas ejecuciones

Conéctese como `CP_POS` a la PDB del proyecto y consulte:

```sql
SELECT job_name,
       enabled,
       state,
       repeat_interval,
       last_start_date,
       next_run_date,
       run_count,
       failure_count
FROM user_scheduler_jobs
WHERE job_name LIKE 'JOB\_CP%' ESCAPE '\'
ORDER BY job_name;
```

Para revisar el historial:

```sql
SELECT job_name,
       status,
       error#,
       actual_start_date,
       run_duration,
       additional_info
FROM user_scheduler_job_run_details
WHERE job_name LIKE 'JOB\_CP%' ESCAPE '\'
ORDER BY actual_start_date DESC
FETCH FIRST 50 ROWS ONLY;
```

Un job habilitado puede tener `RUN_COUNT = 0` si todavía no llega su próxima fecha programada. Compruebe `ENABLED`, `STATE`, `NEXT_RUN_DATE` y el historial antes de considerarlo fallido.

## Privilegios y seguridad

Los jobs pertenecen al esquema `CP_POS`; no se deben crear bajo `SYS`. Si `CP_POS` no puede crear un job nuevo, el administrador debe comprobar el privilegio `CREATE JOB` en la PDB. No vuelva a otorgar privilegios ni ejecute scripts administrativos sin revisar primero el estado actual.

No incluya contraseñas, claves SMTP ni secretos en scripts, bitácoras o repositorios.
