# Procedimientos de monitoreo y notificaciones — CP-POS Multisucursal

## 1. Descripción

Este módulo contiene los procedimientos almacenados encargados de realizar verificaciones sobre la base de datos Oracle Database 21c XE y generar notificaciones relacionadas con el funcionamiento y la operación del sistema CP-POS Multisucursal.

Su objetivo es detectar situaciones que requieren atención, como:

- Objetos inválidos en el esquema.
- Índices inutilizables.
- Tablespaces con ocupación igual o superior al 85 %.
- Clientes que alcanzan determinados niveles de utilización de crédito.
- Clientes con cuentas por cobrar en mora.
- Proveedores que alcanzan determinados niveles de utilización de crédito.
- Productos vencidos que todavía mantienen existencias en inventario.
- Situaciones de mora que requieren notificación a los responsables correspondientes.

Los procedimientos pertenecen al esquema `CP_POS` y utilizan los paquetes y parámetros del sistema de notificaciones del proyecto.

Algunos procedimientos se ejecutan manualmente durante las pruebas y otros son invocados automáticamente mediante Oracle `DBMS_SCHEDULER`.

---

## 2. Archivos del módulo

Los archivos existentes en este directorio son:

| Archivo | Funcionalidad |
|---|---|
| `procedimientos_alertas_credito.sql` | Procedimientos relacionados con alertas de crédito de clientes. |
| `procedimientos_alertas_mora.sql` | Procedimientos relacionados con la detección de clientes en mora. |
| `procedimiento_notificacion_mora_gerente_coordinador.sql` | Notificaciones agrupadas de mora para gerente y coordinador. |
| `procedimiento_notificacion_productos_vencidos_coordinador.sql` | Notificación de productos vencidos al coordinador. |
| `procedimiento_umbral_70.sql` | Alerta de utilización de crédito de proveedores con umbral del 70 %. |
| `procedimiento_umbral_85.sql` | Alerta de utilización de crédito de proveedores con umbral del 85 %. |
| `verificar_objetos_invalidos.sql` | Detecta objetos inválidos del esquema `CP_POS`. |
| `verificar_indices.sql` | Detecta índices o particiones de índices inutilizables. |
| `verificar_tablespaces.sql` | Detecta tablespaces permanentes con ocupación igual o superior al 85 %. |
| `README.md` | Documentación de los procedimientos del módulo. |

---

## 3. Requisitos previos

Antes de instalar o ejecutar los procedimientos, se requiere:

1. Tener Oracle Database 21c XE funcionando.
2. Tener creado el esquema `CP_POS`.
3. Conectarse a la base de datos `XEPDB1`.
4. Tener configurado el envío de correos.
5. Tener compilado el paquete `PKG_CP_NOTIFICACIONES`.
6. Tener compilado el paquete `PKG_CP_PARAMETRO`.
7. Tener registrado el parámetro `CORREO_ALERTAS_BD`.
8. Tener configuradas las cuentas de correo y los destinatarios utilizados por el sistema.
9. Tener los permisos necesarios para consultar las vistas administrativas de Oracle cuando se ejecuten las verificaciones de tablespaces.

La configuración general del correo se documenta en:

`DataBase_Scripts/Notifications/README.md`

---

## 4. Paquetes y parámetros utilizados

### 4.1. Paquete de notificaciones

Los procedimientos utilizan el paquete:

`PKG_CP_NOTIFICACIONES`

Este paquete centraliza las operaciones de envío y procesamiento de notificaciones del sistema.

Entre las operaciones utilizadas por los procedimientos se encuentra:

`PKG_CP_NOTIFICACIONES.enviar_correo(...)`

Los procedimientos que trabajan con notificaciones almacenadas también utilizan las tablas del módulo de notificaciones y el proceso encargado de enviar los mensajes pendientes.

### 4.2. Paquete de parámetros

Se utiliza:

`PKG_CP_PARAMETRO`

Este paquete permite obtener valores de configuración registrados en `CP_PARAMETRO`.

Por ejemplo:

```sql
PKG_CP_PARAMETRO.obtener_texto('CORREO_ALERTAS_BD')
```

### 4.3. Parámetros de configuración

Entre los parámetros utilizados por las alertas se encuentran:

| Parámetro | Función |
|---|---|
| `CORREO_ALERTAS_BD` | Dirección de correo utilizada para las alertas de base de datos y notificaciones que emplean este destinatario. |
| `UMBRAL_CXP_COORDINADOR_PCT` | Porcentaje de utilización de crédito de proveedores para generar la alerta al coordinador. |
| `UMBRAL_CXP_GERENTE_PCT` | Porcentaje de utilización de crédito de proveedores para generar la alerta al gerente. |

Los umbrales de crédito de proveedores se encuentran configurados inicialmente en 85 % para el coordinador y 70 % para el gerente.

Los valores deben consultarse desde `CP_PARAMETRO`, en lugar de mantenerlos directamente dentro del código de los procedimientos.

---

## 5. Instalación de los procedimientos

Desde PL/SQL Developer:

1. Conectarse como `CP_POS` a `XEPDB1`.
2. Abrir el archivo SQL correspondiente.
3. Ejecutar el script para crear o actualizar los procedimientos.
4. Revisar los mensajes de ejecución.
5. Comprobar que los procedimientos estén compilados correctamente.
6. Consultar `USER_ERRORS` si alguno presenta errores.

Los archivos utilizan instrucciones de creación o actualización de objetos, por lo que pueden ejecutarse nuevamente cuando sea necesario actualizar su código.

Se recomienda instalar primero los paquetes de notificaciones y parámetros, ya que los procedimientos dependen de ellos.

---

## 6. Verificar que los procedimientos estén compilados

Ejecutar:

```sql
SELECT
    OBJECT_NAME,
    OBJECT_TYPE,
    STATUS
FROM USER_OBJECTS
WHERE OBJECT_TYPE = 'PROCEDURE'
ORDER BY OBJECT_NAME;
```

### Resultado esperado

Los procedimientos deben aparecer con:

`STATUS = VALID`

Si alguno aparece como `INVALID`, consultar los errores:

```sql
SELECT
    NAME,
    TYPE,
    LINE,
    POSITION,
    TEXT
FROM USER_ERRORS
ORDER BY NAME, SEQUENCE;
```

Los errores deben corregirse antes de programar o ejecutar los procedimientos automáticamente.

---

# PARTE I. PROCEDIMIENTOS DE MONITOREO DE BASE DE DATOS

## 7. Verificación de objetos inválidos

### Objetivo

Detectar objetos inválidos pertenecientes al esquema `CP_POS`.

El procedimiento utiliza la vista `USER_OBJECTS` y revisa los objetos cuyo estado sea `INVALID`.

Se excluye el propio procedimiento `VERIFICAR_OBJETOS_INVALIDOS` del conteo.

### Procedimiento

`VERIFICAR_OBJETOS_INVALIDOS`

### Archivo

`verificar_objetos_invalidos.sql`

### Ejecución manual

```sql
BEGIN
    verificar_objetos_invalidos;
END;
/
```

### Resultado esperado sin inconsistencias

```text
Verificacion correcta: no existen objetos invalidos.
```

### Resultado cuando existen inconsistencias

El procedimiento obtiene el correo configurado mediante:

```sql
PKG_CP_PARAMETRO.obtener_texto('CORREO_ALERTAS_BD')
```

Posteriormente envía una alerta utilizando el servicio de notificaciones.

El correo informa:

- El esquema revisado.
- La cantidad de objetos inválidos detectados.

### Consultar los objetos inválidos

```sql
SELECT
    OBJECT_NAME,
    OBJECT_TYPE,
    STATUS
FROM USER_OBJECTS
WHERE STATUS = 'INVALID'
ORDER BY OBJECT_TYPE, OBJECT_NAME;
```

### Prueba controlada

Para comprobar la detección, puede crearse un procedimiento de prueba que haga referencia a un objeto inexistente.

Esta prueba debe realizarse únicamente en un ambiente de desarrollo.

```sql
CREATE OR REPLACE PROCEDURE PRUEBA_OBJETO_INVALIDO
AS
BEGIN
    TABLA_QUE_NO_EXISTE;
END;
/
```

Oracle puede dejar el procedimiento en estado `INVALID` debido a los errores de compilación.

Ejecutar:

```sql
BEGIN
    verificar_objetos_invalidos;
END;
/
```

Se espera recibir un correo de alerta.

### Limpieza de la prueba

```sql
DROP PROCEDURE PRUEBA_OBJETO_INVALIDO;
```

Comprobar nuevamente que no existan objetos inválidos.

**Importante:** no dejar objetos de prueba inválidos en la base de datos, ya que provocarían alertas en las siguientes verificaciones.

---

## 8. Verificación de índices

### Objetivo

Detectar índices inutilizables en las tablas del esquema `CP_POS`.

El procedimiento utiliza:

- `USER_INDEXES`
- `USER_IND_PARTITIONS`
- `USER_IND_SUBPARTITIONS`

Se comprueba si existen índices o particiones con estado `UNUSABLE`.

### Procedimiento

`VERIFICAR_INDICES`

### Archivo

`verificar_indices.sql`

### Ejecución manual

```sql
BEGIN
    verificar_indices;
END;
/
```

### Resultado esperado sin inconsistencias

```text
Verificacion correcta: no existen indices inutilizables.
```

### Consultar el estado de los índices

```sql
SELECT
    INDEX_NAME,
    TABLE_NAME,
    STATUS
FROM USER_INDEXES
ORDER BY TABLE_NAME, INDEX_NAME;
```

Para consultar particiones inutilizables:

```sql
SELECT
    INDEX_NAME,
    PARTITION_NAME,
    STATUS
FROM USER_IND_PARTITIONS
WHERE STATUS = 'UNUSABLE';
```

Para consultar subparticiones inutilizables:

```sql
SELECT
    INDEX_NAME,
    SUBPARTITION_NAME,
    STATUS
FROM USER_IND_SUBPARTITIONS
WHERE STATUS = 'UNUSABLE';
```

### Resultado cuando existen inconsistencias

El procedimiento envía un correo que indica:

- El esquema revisado.
- La cantidad de índices o particiones inutilizables.

Si no existen inconsistencias, no se envía ningún correo.

### Alcance de la verificación

El procedimiento revisa los índices del esquema `CP_POS`, no los de otros usuarios de Oracle.

La detección del estado `UNUSABLE` no equivale a una verificación física completa de corrupción de índices.

---

## 9. Verificación de tablespaces

### Objetivo

Detectar tablespaces permanentes cuya ocupación alcance o supere el 85 % de la capacidad considerada.

El procedimiento utiliza:

- `DBA_DATA_FILES`
- `DBA_FREE_SPACE`

Calcula el espacio utilizado a partir del espacio asignado y el espacio libre.

Cuando un archivo tiene `AUTOEXTEND` habilitado, el cálculo considera su capacidad máxima configurada.

### Procedimiento

`VERIFICAR_TABLESPACES`

### Archivo

`verificar_tablespaces.sql`

### Permisos necesarios

Conectarse como un usuario administrador autorizado en `XEPDB1` y ejecutar:

```sql
GRANT SELECT ON SYS.DBA_DATA_FILES TO CP_POS;

GRANT SELECT ON SYS.DBA_FREE_SPACE TO CP_POS;
```

Los permisos deben otorgarse directamente al usuario `CP_POS` para que puedan utilizarse desde el procedimiento almacenado.

No es necesario otorgar el rol DBA al usuario del proyecto.

### Ejecución manual

```sql
BEGIN
    verificar_tablespaces;
END;
/
```

### Resultado esperado sin inconsistencias

```text
Verificacion correcta: ningun tablespace permanente alcanza el 85% de ocupacion.
```

### Consultar el espacio asignado

```sql
SELECT
    TABLESPACE_NAME,
    ROUND(SUM(BYTES) / 1024 / 1024, 2) AS ESPACIO_MB
FROM DBA_DATA_FILES
GROUP BY TABLESPACE_NAME
ORDER BY TABLESPACE_NAME;
```

Esta consulta muestra el espacio asignado a los archivos de datos, no el porcentaje utilizado.

### Consultar el porcentaje de ocupación

```sql
WITH archivos AS (
    SELECT
        TABLESPACE_NAME,
        SUM(BYTES) AS BYTES_ASIGNADOS,
        SUM(
            CASE
                WHEN AUTOEXTENSIBLE = 'YES'
                THEN GREATEST(BYTES, MAXBYTES)
                ELSE BYTES
            END
        ) AS BYTES_MAXIMOS
    FROM DBA_DATA_FILES
    GROUP BY TABLESPACE_NAME
),
libres AS (
    SELECT
        TABLESPACE_NAME,
        SUM(BYTES) AS BYTES_LIBRES
    FROM DBA_FREE_SPACE
    GROUP BY TABLESPACE_NAME
)
SELECT
    a.TABLESPACE_NAME,
    ROUND(
        (a.BYTES_ASIGNADOS - NVL(l.BYTES_LIBRES, 0))
        / NULLIF(a.BYTES_MAXIMOS, 0) * 100,
        2
    ) AS PORCENTAJE_USO
FROM archivos a
LEFT JOIN libres l
    ON a.TABLESPACE_NAME = l.TABLESPACE_NAME
ORDER BY PORCENTAJE_USO DESC;
```

### Resultado cuando existen inconsistencias

Si algún tablespace alcanza o supera el 85 %, el procedimiento envía una alerta indicando:

- Nombre del tablespace.
- Porcentaje de ocupación.
- Base de datos y contenedor revisados.

Si varios tablespaces superan el umbral, se agrupan en un único correo.

### Alcance de la verificación

El procedimiento revisa los tablespaces permanentes visibles desde `XEPDB1`.

No incluye los tablespaces temporales.

El porcentaje corresponde a la capacidad máxima configurada para los archivos cuando aplica `AUTOEXTEND`.

---

# PARTE II. ALERTAS DE CRÉDITO Y MORA DE CLIENTES

## 10. Alertas de crédito de clientes

### Objetivo

Detectar clientes cuyo nivel de utilización de crédito alcanza el umbral configurado para generar una alerta.

Estas alertas permiten identificar clientes que están utilizando una proporción elevada del crédito disponible.

### Archivo

`procedimientos_alertas_credito.sql`

### Funcionalidad

El módulo contiene la lógica de alertas de crédito de clientes.

Uno de los procedimientos implementados es:

`PRC_CP_ALERTA_CREDITO_85`

Este procedimiento detecta clientes que alcanzan o superan el 85 % de utilización de su crédito.

### Criterio de detección

Se compara el saldo utilizado por el cliente con el límite de crédito autorizado.

La alerta se genera cuando el porcentaje de utilización alcanza el umbral establecido.

### Ejecución manual

```sql
BEGIN
    PRC_CP_ALERTA_CREDITO_85;
END;
/
```

### Programación automática

La ejecución automática se realiza mediante el job:

`JOB_CP_ALERTA_CREDITO_85`

El job se encuentra documentado en el módulo:

`DataBase_Scripts/jobs/`

La configuración de ejecución establecida para esta alerta es cada 15 minutos.

---

## 11. Alertas de mora de clientes

### Objetivo

Identificar clientes que mantienen cuentas por cobrar vencidas y cumplen el criterio de antigüedad establecido para generar una notificación.

### Archivo

`procedimientos_alertas_mora.sql`

### Procedimiento

`PRC_CP_ALERTA_MORA_CLIENTES`

### Criterios de detección

El procedimiento considera cuentas por cobrar que:

- Se encuentran en estados pendientes, parciales o vencidos.
- Tienen una fecha de vencimiento anterior al día actual.
- Cumplen el criterio de más de 30 días desde el último pago registrado.

Para determinar el último pago se utiliza la fecha del abono más reciente.

Cuando el cliente no registra pagos, se utiliza la fecha de creación más antigua de sus cuentas como referencia.

### Ejecución manual

```sql
BEGIN
    PRC_CP_ALERTA_MORA_CLIENTES;
END;
/
```

### Notificaciones

Cuando se detectan clientes que cumplen las condiciones, se generan las notificaciones correspondientes utilizando el módulo de correo del sistema.

El procedimiento contempla el correo principal del cliente como destinatario de la notificación.

### Programación automática

La ejecución periódica se encuentra asociada al job:

`JOB_CP_ALERTA_MORA_CLIENTES`

La configuración de los jobs se documenta en:

`DataBase_Scripts/jobs/`

---

# PARTE III. ALERTAS DE CRÉDITO DE PROVEEDORES

## 12. Alerta de crédito de proveedores al coordinador

### Objetivo

Detectar proveedores cuyo nivel de utilización de crédito alcanza el umbral establecido para generar una alerta dirigida al coordinador.

### Archivo

`procedimiento_umbral_85.sql`

### Procedimiento

`PRC_CP_ALERTA_CXP_COORDINADOR`

### Parámetro utilizado

`UMBRAL_CXP_COORDINADOR_PCT`

El valor inicial configurado es 85 %.

### Criterio de detección

El procedimiento calcula la utilización del crédito de los proveedores y compara el porcentaje obtenido con el umbral configurado.

Cuando el porcentaje alcanza o supera el umbral, se genera una notificación.

### Ejecución manual

```sql
BEGIN
    PRC_CP_ALERTA_CXP_COORDINADOR;
END;
/
```

### Programación automática

Job:

`JOB_CP_ALERTA_CXP_COORDINADOR`

La ejecución se encuentra configurada de forma periódica cada 15 minutos.

---

## 13. Alerta de crédito de proveedores al gerente

### Objetivo

Detectar proveedores cuyo nivel de utilización de crédito alcanza el umbral establecido para generar una alerta dirigida al gerente.

### Archivo

`procedimiento_umbral_70.sql`

### Procedimiento

`PRC_CP_ALERTA_CXP_GERENTE`

### Parámetro utilizado

`UMBRAL_CXP_GERENTE_PCT`

El valor inicial configurado es 70 %.

### Criterio de detección

El procedimiento calcula la utilización del crédito de los proveedores y compara el porcentaje obtenido con el umbral configurado.

Cuando el porcentaje alcanza o supera el umbral, se genera una notificación.

### Ejecución manual

```sql
BEGIN
    PRC_CP_ALERTA_CXP_GERENTE;
END;
/
```

### Programación automática

Job:

`JOB_CP_ALERTA_CXP_GERENTE`

La ejecución se encuentra configurada de forma periódica cada 15 minutos.

---

# PARTE IV. NOTIFICACIONES AGRUPADAS

## 14. Notificación de mora para gerente y coordinador

### Objetivo

Generar una notificación agrupada con información relacionada con las cuentas en mora, dirigida a los responsables correspondientes.

### Archivo

`procedimiento_notificacion_mora_gerente_coordinador.sql`

### Funcionalidad

Este procedimiento complementa las alertas individuales de mora mediante una notificación destinada a los responsables de supervisión.

La información se presenta de forma agrupada para facilitar el seguimiento de las cuentas pendientes y vencidas.

### Ejecución y programación

La ejecución automática está relacionada con el job:

`JOB_CP_NOTIFICACION_MORA_GERENTE_COORDINADOR`

El script de programación se encuentra en:

`DataBase_Scripts/jobs/`

---

## 15. Notificación de productos vencidos al coordinador

### Objetivo

Detectar productos vencidos que todavía mantienen existencias en los inventarios de los almacenes y notificar al coordinador.

### Archivo

`procedimiento_notificacion_productos_vencidos_coordinador.sql`

### Procedimiento

`PRC_CP_NOTIFICACION_PRODUCTOS_VENCIDOS_COORD`

### Criterios de detección

El procedimiento identifica lotes de productos que cumplen las siguientes condiciones:

- La fecha de vencimiento es anterior al día actual.
- El lote mantiene una cantidad disponible mayor que cero en el inventario del almacén.

### Información incluida en la notificación

El mensaje contiene información como:

- Nombre del producto.
- Código del producto.
- Número de lote.
- Fecha de vencimiento.
- Almacén correspondiente.
- Cantidad disponible.
- Resumen de los productos vencidos detectados.

La notificación presenta la información agrupada en un único mensaje.

### Ejecución manual

```sql
BEGIN
    PRC_CP_NOTIFICACION_PRODUCTOS_VENCIDOS_COORD;
END;
/
```

### Programación automática

Job:

`JOB_CP_NOTIFICACION_PRODUCTOS_VENCIDOS_COORD`

La ejecución se encuentra configurada de forma periódica cada 15 minutos.

---

# PARTE V. CONFIGURACIÓN Y OPERACIÓN

## 16. Configuración de las alertas

Los procedimientos utilizan parámetros centralizados en `CP_PARAMETRO` para obtener los valores de configuración correspondientes.

Para consultar los parámetros:

```sql
SELECT
    CODIGO_PARAMETRO,
    VALOR
FROM CP_PARAMETRO
WHERE CODIGO_PARAMETRO IN (
    'CORREO_ALERTAS_BD',
    'UMBRAL_CXP_COORDINADOR_PCT',
    'UMBRAL_CXP_GERENTE_PCT'
)
ORDER BY CODIGO_PARAMETRO;
```

El uso de parámetros permite modificar determinados valores de configuración sin tener que modificar directamente el código de los procedimientos.

---

## 17. Manejo de notificaciones y destinatarios

El sistema utiliza el módulo centralizado de notificaciones de CP-POS.

Entre sus componentes se encuentran:

- `CP_NOTIFICACION`
- `CP_NOTIFICACION_DESTINATARIO`
- `CP_DESTINATARIO_NOTIFICACION`
- `CP_CONFIGURACION_CORREO`
- `CP_CONTACTO`

El paquete `PKG_CP_NOTIFICACIONES` permite centralizar el procesamiento y envío de los mensajes.

Los procedimientos que generan notificaciones almacenadas utilizan el flujo de notificaciones del proyecto, evitando implementar un mecanismo independiente de correo para cada alerta.

---

## 18. Manejo de excepciones

Los procedimientos utilizan bloques de manejo de excepciones para identificar y propagar errores durante su ejecución.

Un patrón utilizado es:

```sql
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(
            'Error: ' || SQLERRM
        );
        RAISE;
```

Esto permite mostrar información del error y propagarlo al proceso que invocó el procedimiento.

Cuando un job ejecuta un procedimiento y ocurre una excepción no controlada, Oracle Scheduler puede registrar la ejecución como fallida.

---

## 19. Programación automática

Los procedimientos se ejecutan automáticamente mediante jobs de Oracle Scheduler.

La programación de estos trabajos se documenta en:

`DataBase_Scripts/jobs/`

Los intervalos configurados para los módulos son:

| Módulo | Frecuencia |
|---|---|
| Monitoreo de objetos inválidos | Diariamente, a las 2:00 p. m. |
| Monitoreo de índices | Diariamente, a las 2:00 p. m. |
| Monitoreo de tablespaces | Diariamente, a las 2:00 p. m. |
| Alertas de crédito de clientes | Cada 15 minutos. |
| Alertas de mora de clientes | Cada 15 minutos. |
| Alertas de crédito de proveedores | Cada 15 minutos. |
| Notificación de productos vencidos | Cada 15 minutos. |

Los jobs se ejecutan desde Oracle Database. No es necesario mantener PL/SQL Developer abierto, pero la base de datos y el contenedor Docker deben permanecer funcionando.

Para consultar los trabajos del esquema:

```sql
SELECT
    JOB_NAME,
    ENABLED,
    STATE,
    NEXT_RUN_DATE
FROM USER_SCHEDULER_JOBS
ORDER BY JOB_NAME;
```

---

## 20. Solución de problemas

### Procedimiento INVALID

Consultar `USER_ERRORS` para identificar el problema de compilación.

Verificar que existan los paquetes, tablas, vistas y permisos utilizados.

### ORA-00942: table or view does not exist

Verificar que el usuario `CP_POS` tenga los permisos directos necesarios sobre las vistas administrativas y los objetos consultados.

### No se recibe la alerta

Verificar:

1. Que exista una condición que cumpla los criterios del procedimiento.
2. Que los parámetros de configuración estén registrados.
3. Que `PKG_CP_NOTIFICACIONES` esté compilado.
4. Que la configuración SMTP funcione correctamente.
5. Que existan destinatarios activos cuando el procedimiento utilice destinatarios registrados.
6. Que el correo no esté en la carpeta de spam.

### El procedimiento muestra un error de envío

Consultar el mensaje de error de Oracle y revisar la configuración SMTP, Wallet y permisos de red.

### El job no se ejecuta

Verificar:

- Que el job exista.
- Que esté habilitado.
- Que el estado sea correcto.
- Que el contenedor Docker y la base de datos estén funcionando.
- Que el historial de ejecuciones no muestre errores.

---

## 21. Consideraciones de seguridad

- Los procedimientos pertenecen al esquema `CP_POS`.
- Los privilegios administrativos se otorgan de forma controlada.
- No se deben almacenar contraseñas de correo directamente en los procedimientos.
- Los destinatarios y parámetros deben administrarse desde las tablas de configuración correspondientes.
- El servicio de correo utiliza la configuración centralizada del módulo de notificaciones.
- Las pruebas que modifican objetos deben realizarse únicamente en desarrollo.
- No se debe otorgar el rol DBA al usuario del proyecto solo para permitir la ejecución de estas verificaciones.

---

## 22. Resultado esperado

Al finalizar la instalación y configuración:

- Los procedimientos deben estar compilados en estado `VALID`.
- Las verificaciones de base de datos deben poder ejecutarse manualmente.
- Las alertas de crédito deben detectar los niveles de utilización establecidos.
- Las alertas de mora deben identificar las cuentas que cumplen los criterios definidos.
- Las alertas de crédito de proveedores deben respetar los umbrales configurados.
- Las notificaciones de productos vencidos deben identificar los lotes con existencias disponibles.
- Los mensajes deben utilizar el sistema centralizado de notificaciones.
- Los jobs deben poder ejecutar los procedimientos según sus horarios programados.
- Los errores deben quedar disponibles para su diagnóstico mediante Oracle y el historial de Scheduler.

---

**CP-POS Multisucursal — Módulo de procedimientos de monitoreo y notificaciones.**