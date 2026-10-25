
# Jobs de monitoreo diario — CP-POS Multisucursal

## 1. Descripción

Este módulo contiene los trabajos automáticos encargados de
ejecutar diariamente las verificaciones de mantenimiento de
la base de datos CP-POS Multisucursal.

Los trabajos se implementan mediante `DBMS_SCHEDULER`
de Oracle 21c XE.

Se realizan tres verificaciones:

- Objetos inválidos del esquema CP_POS.
- Índices en estado UNUSABLE.
- Tablespaces permanentes con ocupación igual o superior al 85 %.

Cuando se detecta una inconsistencia, el procedimiento
correspondiente envía una notificación al correo configurado
en el parámetro `CORREO_ALERTAS_BD`.

## 2. Requisitos previos

Antes de ejecutar los jobs se requiere:

1. Tener Oracle Database 21c XE funcionando.
2. Conectarse a `XEPDB1` con el usuario `CP_POS`.
3. Tener creados y compilados los procedimientos:
   - `VERIFICAR_OBJETOS_INVALIDOS`
   - `VERIFICAR_INDICES`
   - `VERIFICAR_TABLESPACES`
4. Tener configurado el envío de correos mediante
   `PKG_CP_NOTIFICACIONES`.
5. Tener configurado el parámetro `CORREO_ALERTAS_BD`.
6. Contar con el privilegio `CREATE JOB`.

El administrador puede otorgar el privilegio ejecutando
en XEPDB1:

```sql
GRANT CREATE JOB TO CP_POS;
```

## 3. Archivos del módulo

| Archivo | Función |
|---------|---------|
| `programar_verificacion_objetos_invalidos.sql` | Programa la revisión de objetos inválidos. |
| `programar_verificacion_indices.sql` | Programa la revisión de índices inutilizables. |
| `programar_verificacion_tablespaces.sql` | Programa la revisión de ocupación de tablespaces. |

## 4. Instalación de los jobs

Desde PL/SQL Developer, conectado como `CP_POS`:

1. Abrir `programar_verificacion_objetos_invalidos.sql`.
2. Ejecutar el script.
3. Abrir `programar_verificacion_indices.sql`.
4. Ejecutar el script.
5. Abrir `programar_verificacion_tablespaces.sql`.
6. Ejecutar el script.

Los tres trabajos quedan programados para ejecutarse
todos los días a las **2:00 p. m., hora de Costa Rica**.

La programación utiliza:

```sql
repeat_interval => 'FREQ=DAILY;BYHOUR=14;BYMINUTE=0;BYSECOND=0'
```

Y la zona horaria:

```sql
SYSTIMESTAMP AT TIME ZONE 'America/Costa_Rica'
```

## 5. Verificar que los jobs estén creados

Ejecutar:

```sql
SELECT
    JOB_NAME,
    ENABLED,
    STATE,
    NEXT_RUN_DATE
FROM USER_SCHEDULER_JOBS
WHERE JOB_NAME IN (
    'JOB_CP_VERIFICAR_OBJETOS_INVALIDOS',
    'JOB_CP_VERIFICAR_INDICES',
    'JOB_CP_VERIFICAR_TABLESPACES'
)
ORDER BY JOB_NAME;
```

Se debe verificar que:

- Los tres jobs aparezcan registrados.
- `ENABLED` sea `TRUE`.
- `NEXT_RUN_DATE` corresponda a las 2:00 p. m.
  de Costa Rica.

## 6. Ejecutar manualmente los jobs

Para comprobar su funcionamiento sin esperar al
horario programado, ejecutar cada trabajo por separado.

### Objetos inválidos

```sql
BEGIN
    DBMS_SCHEDULER.RUN_JOB(
        job_name => 'JOB_CP_VERIFICAR_OBJETOS_INVALIDOS',
        use_current_session => TRUE
    );
END;
/
```

### Índices

```sql
BEGIN
    DBMS_SCHEDULER.RUN_JOB(
        job_name => 'JOB_CP_VERIFICAR_INDICES',
        use_current_session => TRUE
    );
END;
/
```

### Tablespaces

```sql
BEGIN
    DBMS_SCHEDULER.RUN_JOB(
        job_name => 'JOB_CP_VERIFICAR_TABLESPACES',
        use_current_session => TRUE
    );
END;
/
```

Estas ejecuciones manuales no modifican el horario
de los trabajos.

## 7. Consultar cuántas veces se han ejecutado

```sql
SELECT
    JOB_NAME,
    RUN_COUNT AS VECES_EJECUTADO,
    FAILURE_COUNT AS VECES_FALLIDAS,
    LAST_START_DATE AS ULTIMA_EJECUCION,
    NEXT_RUN_DATE AS PROXIMA_EJECUCION
FROM USER_SCHEDULER_JOBS
WHERE JOB_NAME LIKE 'JOB_CP_VERIFICAR_%'
ORDER BY JOB_NAME;
```

Esta consulta permite verificar la cantidad de
ejecuciones registradas para cada trabajo.

## 8. Consultar el historial de ejecuciones

```sql
SELECT
    JOB_NAME,
    ACTUAL_START_DATE AS FECHA_EJECUCION,
    STATUS AS RESULTADO,
    RUN_DURATION AS DURACION,
    ERROR# AS CODIGO_ERROR
FROM USER_SCHEDULER_JOB_RUN_DETAILS
WHERE JOB_NAME LIKE 'JOB_CP_VERIFICAR_%'
ORDER BY ACTUAL_START_DATE DESC;
```

Estados principales:

- `SUCCEEDED`: ejecución correcta.
- `FAILED`: ejecución con error.
- `STOPPED`: ejecución detenida.

El historial está sujeto a la política de retención
configurada en Oracle Scheduler.

## 9. Funcionamiento con Docker

Los jobs se almacenan dentro de Oracle Database.

- No necesitan que PL/SQL Developer esté abierto.
- Se ejecutan mientras Oracle esté funcionando y
  Scheduler esté habilitado.
- No se ejecutan cuando el contenedor está detenido.
- Al reiniciar Oracle, los jobs conservan su programación.
- Una ejecución perdida durante una detención no debe
  considerarse recuperada sin comprobar el historial.

## 10. Solución de problemas

### ORA-27486: insufficient privileges

El usuario no tiene autorización para crear el job.

Un administrador debe ejecutar:

```sql
GRANT CREATE JOB TO CP_POS;
```

### ORA-27477: job already exists

El trabajo ya está creado.

Se debe utilizar el bloque de actualización del
script correspondiente, en lugar de volver a crearlo.

### El job aparece como FAILED

Consultar el historial de ejecuciones:

```sql
SELECT
    JOB_NAME,
    STATUS,
    ERROR#,
    ADDITIONAL_INFO
FROM USER_SCHEDULER_JOB_RUN_DETAILS
WHERE STATUS = 'FAILED'
ORDER BY ACTUAL_START_DATE DESC;
```

Revisar el código de error y verificar que el
procedimiento correspondiente esté compilado y
tenga los permisos necesarios.

## 11. Consideraciones de seguridad

- Los jobs pertenecen al usuario `CP_POS`.
- No se deben crear objetos del proyecto bajo `SYS`.
- Los privilegios administrativos deben ser otorgados
  únicamente por usuarios autorizados.
- Las credenciales de correo no deben incluirse en GitHub.
- El destinatario se obtiene mediante el parámetro
  `CORREO_ALERTAS_BD`.

## 12. Resultado esperado

Al finalizar la instalación:

- Los tres jobs estarán registrados en Oracle Scheduler.
- Se ejecutarán diariamente a las 2:00 p. m.
- Cada job invocará su procedimiento correspondiente.
- Se enviarán alertas únicamente cuando se detecten
  inconsistencias.
- El administrador podrá consultar el estado, la cantidad
  de ejecuciones y el historial de cada trabajo.
