# Jobs de monitoreo y notificaciones — CP-POS Multisucursal

## 1. Descripción

Este módulo contiene los trabajos automáticos encargados de ejecutar procesos de monitoreo y notificaciones del sistema CP-POS Multisucursal.

Los trabajos se implementan mediante `DBMS_SCHEDULER` de Oracle Database 21c XE.

El módulo contempla dos grupos de procesos:

**A. Monitoreo diario de la base de datos**
- Verificación de objetos inválidos del esquema CP_POS.
- Verificación de índices en estado `UNUSABLE`.
- Verificación de ocupación de tablespaces permanentes.

**B. Procesos automáticos de notificación**
- Alertas de crédito de clientes.
- Alertas de cuentas por pagar al coordinador.
- Alertas de límite de crédito de proveedores al gerente.
- Alertas de mora de clientes.
- Notificación de productos vencidos al coordinador.

Cuando se detecta una condición que requiere notificación, los procedimientos registran la notificación y sus destinatarios para que `PKG_CP_NOTIFICACIONES` gestione el envío mediante la configuración SMTP de Oracle.

---

## 2. Requisitos previos

Antes de ejecutar los jobs se requiere:

1. Tener Oracle Database 21c XE funcionando.
2. Tener iniciado el contenedor Docker de Oracle.
3. Conectarse a `XEPDB1` con el usuario `CP_POS`.
4. Tener creados y compilados los procedimientos y paquetes correspondientes.
5. Tener configurado el envío de correos mediante `PKG_CP_NOTIFICACIONES`.
6. Tener configurado el parámetro `CORREO_ALERTAS_BD`.
7. Tener configurados los destinatarios y la cuenta de correo remitente.
8. Contar con el privilegio `CREATE JOB`.

El administrador puede otorgar el privilegio ejecutando en `XEPDB1`:

```sql
GRANT CREATE JOB TO CP_POS;
```

Los procedimientos y jobs del proyecto deben crearse bajo el usuario `CP_POS`, no bajo `SYS`.

---

## 3. Estructura de archivos del módulo

Los archivos de programación de trabajos se encuentran en:

`DataBase_Scripts/jobs/diarios/`

| Archivo | Función |
|---|---|
| `programar_verificacion_indices.sql` | Programa la revisión diaria de índices inutilizables. |
| `programar_verificacion_tablespaces.sql` | Programa la revisión diaria de ocupación de tablespaces. |
| `verificacion_objetos_invalidos.sql` | Implementa la verificación de objetos inválidos. |
| `jobs_alertas_credito.sql` | Programa la alerta de crédito de clientes. |
| `JOB_CP_ALERTA_CXP_COORDINADOR.sql` | Programa la alerta de cuentas por pagar al coordinador. |
| `JOB_CP_ALERTA_CXP_GERENTE.sql` | Programa la alerta de límite de crédito de proveedores al gerente. |
| `JOB_CP_ALERTA_MORA.sql` | Programa la alerta de mora de clientes. |
| `JOB_CP_NOTIFICACION_MORA_GERENTE_COORDINADOR.sql` | Programa la notificación de mora dirigida al gerente y al coordinador. |
| `JOB_CP_NOTIFICACION_PRODUCTOS_VENCIDOS_COORDINADOR.sql` | Programa la notificación de productos vencidos al coordinador. |

Los procedimientos que invocan estos trabajos se encuentran en las carpetas correspondientes de `Notificaciones/procedures` y en los archivos de procedimientos de monitoreo.

---

## 4. Horarios de ejecución

El módulo utiliza dos modalidades de programación.

### 4.1. Monitoreos diarios

Los siguientes procesos se ejecutan todos los días a las **2:00 p. m., hora de Costa Rica**:

- Verificación de objetos inválidos.
- Verificación de índices inutilizables.
- Verificación de ocupación de tablespaces.

La programación diaria utiliza el siguiente intervalo:

```sql
'FREQ=DAILY;BYHOUR=14;BYMINUTE=0;BYSECOND=0'
```

La zona horaria utilizada es:

```sql
'America/Costa_Rica'
```

### 4.2. Procesos de notificación

Los procesos de notificación de crédito, cuentas por pagar, mora y productos vencidos se programan para ejecutarse cada 15 minutos.

El intervalo utilizado es:

```sql
'FREQ=MINUTELY;INTERVAL=15'
```

Los procedimientos incluyen controles para evitar generar notificaciones repetidas durante el mismo día, cuando corresponde.

---

## 5. Instalación de los monitoreos diarios

Desde PL/SQL Developer, conectado como `CP_POS`:

1. Abrir `verificacion_objetos_invalidos.sql` y ejecutar el script.
2. Abrir `programar_verificacion_indices.sql` y ejecutar el script.
3. Abrir `programar_verificacion_tablespaces.sql` y ejecutar el script.

Los tres procesos deben quedar registrados y habilitados en Oracle Scheduler.

---

## 6. Instalación de los jobs de notificaciones

Desde PL/SQL Developer, conectado como `CP_POS`, ejecutar los archivos correspondientes:

1. `jobs_alertas_credito.sql`
2. `JOB_CP_ALERTA_CXP_COORDINADOR.sql`
3. `JOB_CP_ALERTA_CXP_GERENTE.sql`
4. `JOB_CP_ALERTA_MORA.sql`
5. `JOB_CP_NOTIFICACION_MORA_GERENTE_COORDINADOR.sql`
6. `JOB_CP_NOTIFICACION_PRODUCTOS_VENCIDOS_COORDINADOR.sql`

Antes de ejecutar cada archivo, verificar que el procedimiento invocado esté creado y compilado correctamente.

Los jobs ejecutan sus procedimientos de forma automática cada 15 minutos.

---

## 7. Descripción de los procesos de notificación

### 7.1. Alerta de crédito de clientes

Identifica clientes cuyo saldo pendiente alcanza o supera el 85 % del límite de crédito permitido.

Cuando se cumple la condición, se genera una notificación dirigida al cliente correspondiente.

### 7.2. Alerta de cuentas por pagar al coordinador

Identifica proveedores cuyo nivel de utilización de crédito alcanza o supera el umbral configurado para el coordinador.

La notificación contiene la información de los proveedores que cumplen la condición.

### 7.3. Alerta de cuentas por pagar al gerente

Identifica proveedores cuyo nivel de utilización de crédito alcanza o supera el umbral configurado para el gerente.

La notificación se genera de forma agrupada para incluir a todos los proveedores que cumplen la condición.

### 7.4. Notificación de mora de clientes

Identifica clientes que mantienen cuentas pendientes y cuyo último pago tiene más de un mes de antigüedad.

Cuando el cliente nunca ha realizado pagos, se utiliza la fecha de creación de la cuenta como referencia.

La notificación se dirige a los destinatarios configurados para el proceso.

### 7.5. Notificación de productos vencidos

Identifica productos con lotes vencidos que todavía mantienen existencias en inventario.

La notificación dirigida al coordinador incluye:

- Código y nombre del producto.
- Número de lote.
- Fecha de vencimiento.
- Almacén.
- Cantidad disponible.
- Resumen de productos, registros y unidades vencidas.

El objetivo es proporcionar información para que el coordinador determine las acciones correspondientes.

---

## 8. Verificar que los jobs estén creados

Ejecutar:

```sql
SELECT
    JOB_NAME,
    ENABLED,
    STATE,
    REPEAT_INTERVAL,
    NEXT_RUN_DATE
FROM USER_SCHEDULER_JOBS
WHERE JOB_NAME LIKE 'JOB_CP%'
   OR JOB_NAME LIKE 'JOB%ALERTA%'
ORDER BY JOB_NAME;
```

Se debe verificar que:

- Los trabajos aparezcan registrados.
- `ENABLED` sea `TRUE`.
- `STATE` refleje el estado correspondiente.
- `REPEAT_INTERVAL` coincida con la programación esperada.
- `NEXT_RUN_DATE` muestre la próxima ejecución.

Para revisar los trabajos de monitoreo diario, consultar también los nombres específicos de esos jobs en `USER_SCHEDULER_JOBS`.

---

## 9. Ejecutar manualmente los jobs

Para comprobar el funcionamiento sin esperar al horario programado, se puede ejecutar cada trabajo manualmente.

Ejemplo para el job de productos vencidos:

```sql
BEGIN
    DBMS_SCHEDULER.RUN_JOB(
        job_name => 'JOB_CP_NOTIFICACION_PRODUCTOS_VENCIDOS_COORD',
        use_current_session => TRUE
    );
END;
/
```

Ejemplo para la alerta de cuentas por pagar al coordinador:

```sql
BEGIN
    DBMS_SCHEDULER.RUN_JOB(
        job_name => 'JOB_CP_ALERTA_CXP_COORDINADOR',
        use_current_session => TRUE
    );
END;
/
```

Para los demás procesos, sustituir el nombre del job por el correspondiente.

Estas ejecuciones manuales no modifican el horario programado.

---

## 10. Consultar las ejecuciones de los jobs

Para consultar la cantidad de ejecuciones:

```sql
SELECT
    JOB_NAME,
    RUN_COUNT AS VECES_EJECUTADO,
    FAILURE_COUNT AS VECES_FALLIDAS,
    LAST_START_DATE AS ULTIMA_EJECUCION,
    NEXT_RUN_DATE AS PROXIMA_EJECUCION
FROM USER_SCHEDULER_JOBS
WHERE JOB_NAME LIKE 'JOB%'
ORDER BY JOB_NAME;
```

Para consultar el historial:

```sql
SELECT
    JOB_NAME,
    ACTUAL_START_DATE AS FECHA_EJECUCION,
    STATUS AS RESULTADO,
    RUN_DURATION AS DURACION,
    ERROR# AS CODIGO_ERROR,
    ADDITIONAL_INFO
FROM USER_SCHEDULER_JOB_RUN_DETAILS
WHERE JOB_NAME LIKE 'JOB%'
ORDER BY ACTUAL_START_DATE DESC;
```

Estados principales:

- `SUCCEEDED`: ejecución correcta.
- `FAILED`: ejecución con error.
- `STOPPED`: ejecución detenida.

El historial está sujeto a la política de retención configurada en Oracle Scheduler.

---

## 11. Funcionamiento con Docker

Los jobs se almacenan dentro de Oracle Database.

- No necesitan que PL/SQL Developer esté abierto.
- Se ejecutan mientras Oracle esté funcionando y Scheduler esté habilitado.
- No se ejecutan cuando el contenedor está detenido.
- Al reiniciar Oracle, los jobs conservan su programación.
- Una ejecución perdida durante una detención no debe considerarse recuperada sin comprobar el historial.

Es importante mantener el contenedor de Oracle en ejecución para que los procesos automáticos puedan cumplirse.

---

## 12. Solución de problemas

### ORA-27486: insufficient privileges

El usuario no tiene autorización para crear el job.

Un administrador debe ejecutar:

```sql
GRANT CREATE JOB TO CP_POS;
```

### ORA-27477: job already exists

El trabajo ya está creado.

Se debe verificar su existencia antes de ejecutar nuevamente un bloque `CREATE_JOB`.

Si se requiere modificar su programación, actualizar el job existente en lugar de intentar crearlo otra vez.

### El job aparece como FAILED

Consultar el historial:

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

Revisar el código de error y verificar que el procedimiento correspondiente esté compilado y tenga los permisos necesarios.

### No llega el correo de notificación

Verificar:

1. Que el procedimiento haya generado la notificación.
2. Que exista un destinatario activo.
3. Que el parámetro `CORREO_ALERTAS_BD` tenga un correo válido.
4. Que la configuración SMTP esté activa.
5. Que `PKG_CP_NOTIFICACIONES` pueda procesar las notificaciones pendientes.
6. Que el historial del job no registre errores.

---

## 13. Consideraciones de seguridad

- Los jobs pertenecen al usuario `CP_POS`.
- No se deben crear objetos del proyecto bajo `SYS`.
- Los privilegios administrativos deben ser otorgados únicamente por usuarios autorizados.
- Las credenciales de correo no deben incluirse en GitHub.
- El destinatario se obtiene mediante el parámetro `CORREO_ALERTAS_BD`.
- La contraseña SMTP debe mantenerse protegida mediante el mecanismo de almacenamiento seguro implementado en la base de datos.

---

## 14. Resultado esperado

Al finalizar la instalación:

- Los tres procesos de monitoreo diario estarán registrados en Oracle Scheduler.
- Los monitoreos diarios se ejecutarán a las 2:00 p. m., hora de Costa Rica.
- Los procesos de notificación estarán programados cada 15 minutos.
- Cada job invocará el procedimiento correspondiente.
- Las notificaciones se registrarán para su posterior procesamiento y envío.
- Se enviarán alertas cuando se detecten las condiciones establecidas.
- El administrador podrá consultar el estado, la cantidad de ejecuciones y el historial de cada trabajo.

---

**Proyecto:** CP-POS Multisucursal  
**Base de datos:** Oracle Database 21c XE  
**Esquema:** CP_POS  
**Herramienta de programación:** DBMS_SCHEDULER  
**Entorno:** Docker y PL/SQL Developer