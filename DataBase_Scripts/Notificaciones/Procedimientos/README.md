
# Procedimientos de monitoreo — CP-POS Multisucursal

## 1. Descripción

Este módulo contiene los procedimientos almacenados encargados
de verificar el estado de diferentes componentes de Oracle
Database 21c XE.

Su objetivo es detectar inconsistencias y enviar alertas al
administrador de la base de datos cuando sea necesario.

Se implementan tres verificaciones:

1. Objetos inválidos.
2. Índices inutilizables.
3. Tablespaces con ocupación igual o superior al 85 %.

Los procedimientos pertenecen al esquema `CP_POS` y utilizan
el servicio de notificaciones del proyecto.

Las verificaciones se ejecutan diariamente mediante
Oracle `DBMS_SCHEDULER`, a las 2:00 p. m., hora de Costa Rica.

Los procedimientos también pueden ejecutarse manualmente
sin esperar el horario programado.

## 2. Archivos del módulo

| Archivo | Procedimiento | Función |
|---|---|---|
| `verificar_objetos_invalidos.sql` | `VERIFICAR_OBJETOS_INVALIDOS` | Detecta objetos inválidos del esquema CP_POS. |
| `verificar_indices.sql` | `VERIFICAR_INDICES` | Detecta índices o particiones de índices en estado UNUSABLE. |
| `verificar_tablespaces.sql` | `VERIFICAR_TABLESPACES` | Detecta tablespaces permanentes con ocupación igual o superior al 85 %. |

## 3. Requisitos previos

Antes de instalar los procedimientos, se requiere:

1. Tener Oracle Database 21c XE funcionando.
2. Tener creado el esquema `CP_POS`.
3. Conectarse a la base de datos `XEPDB1`.
4. Tener configurado el envío de correos.
5. Tener compilado el paquete `PKG_CP_NOTIFICACIONES`.
6. Tener compilado el paquete `PKG_CP_PARAMETRO`.
7. Tener registrado el parámetro `CORREO_ALERTAS_BD`.
8. Tener los permisos necesarios para consultar las
   vistas administrativas de Oracle.

La configuración del correo se documenta en:

`DataBase_Scripts/Notifications/README.md`

## 4. Permisos necesarios

Los procedimientos de objetos inválidos e índices utilizan
vistas del diccionario correspondientes al propio esquema.

El procedimiento de tablespaces necesita consultar:

- `DBA_DATA_FILES`
- `DBA_FREE_SPACE`

Para otorgar estos permisos, conectarse como un usuario
administrador autorizado en `XEPDB1` y ejecutar:

```sql
GRANT SELECT ON SYS.DBA_DATA_FILES TO CP_POS;

GRANT SELECT ON SYS.DBA_FREE_SPACE TO CP_POS;
```

Los permisos deben otorgarse directamente al usuario `CP_POS`
para que puedan utilizarse desde el procedimiento almacenado.

No es necesario otorgar el rol DBA al usuario del proyecto.

## 5. Instalación de los procedimientos

Desde PL/SQL Developer:

1. Conectarse como `CP_POS` a `XEPDB1`.
2. Abrir el archivo `verificar_objetos_invalidos.sql`.
3. Ejecutar el script para crear el procedimiento.
4. Abrir el archivo `verificar_indices.sql`.
5. Ejecutar el script.
6. Abrir el archivo `verificar_tablespaces.sql`.
7. Ejecutar el script.
8. Comprobar que los tres procedimientos estén compilados.

Los archivos utilizan `CREATE OR REPLACE PROCEDURE`, por lo
que pueden ejecutarse nuevamente para actualizar su código.

## 6. Verificar que los procedimientos estén compilados

Ejecutar:

```sql
SELECT
    OBJECT_NAME,
    OBJECT_TYPE,
    STATUS
FROM USER_OBJECTS
WHERE OBJECT_NAME IN (
    'VERIFICAR_OBJETOS_INVALIDOS',
    'VERIFICAR_INDICES',
    'VERIFICAR_TABLESPACES'
)
ORDER BY OBJECT_NAME;
```

### Resultado esperado

Los tres procedimientos deben aparecer con:

`STATUS = VALID`

Si alguno aparece como `INVALID`, consultar sus errores:

```sql
SELECT
    NAME,
    TYPE,
    LINE,
    POSITION,
    TEXT
FROM USER_ERRORS
WHERE NAME IN (
    'VERIFICAR_OBJETOS_INVALIDOS',
    'VERIFICAR_INDICES',
    'VERIFICAR_TABLESPACES'
)
ORDER BY NAME, SEQUENCE;
```

Los errores deben corregirse antes de continuar.

---

## 7. Verificación de objetos inválidos

### Objetivo

Detectar objetos inválidos pertenecientes al esquema `CP_POS`.

El procedimiento utiliza la vista `USER_OBJECTS` y revisa
los objetos cuyo estado sea `INVALID`.

Se excluye el propio procedimiento
`VERIFICAR_OBJETOS_INVALIDOS` del conteo.

### Procedimiento

`VERIFICAR_OBJETOS_INVALIDOS`

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

Posteriormente envía una alerta utilizando:

```sql
PKG_CP_NOTIFICACIONES.enviar_correo(...)
```

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

Para comprobar la detección, puede crearse un procedimiento
de prueba que haga referencia a un objeto inexistente.

Esta prueba debe realizarse únicamente en un ambiente
de desarrollo.

```sql
CREATE OR REPLACE PROCEDURE PRUEBA_OBJETO_INVALIDO
AS
BEGIN
    TABLA_QUE_NO_EXISTE;
END;
/
```

Oracle puede crear el procedimiento con errores de compilación,
dejándolo en estado `INVALID`.

Ejecutar:

```sql
BEGIN
    verificar_objetos_invalidos;
END;
/
```

Se espera recibir un correo de alerta.

### Limpieza de la prueba

Eliminar el objeto de prueba:

```sql
DROP PROCEDURE PRUEBA_OBJETO_INVALIDO;
```

Comprobar nuevamente que no existan objetos inválidos.

**Importante:** no dejar objetos de prueba inválidos en
la base de datos, ya que provocarían alertas diarias.

---

## 8. Verificación de índices

### Objetivo

Detectar índices inutilizables en las tablas del esquema
`CP_POS`.

El procedimiento utiliza:

- `USER_INDEXES`
- `USER_IND_PARTITIONS`
- `USER_IND_SUBPARTITIONS`

Se comprueba si existen índices o particiones con estado
`UNUSABLE`.

### Procedimiento

`VERIFICAR_INDICES`

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

El procedimiento revisa los índices del esquema `CP_POS`,
no los de otros usuarios de Oracle.

La detección del estado `UNUSABLE` no equivale a una
verificación física completa de corrupción de índices.

---

## 9. Verificación de tablespaces

### Objetivo

Detectar tablespaces permanentes cuya ocupación alcance
o supere el 85 % de la capacidad considerada.

El procedimiento utiliza:

- `DBA_DATA_FILES`
- `DBA_FREE_SPACE`

Calcula el espacio utilizado a partir del espacio asignado
y el espacio libre.

Cuando un archivo tiene `AUTOEXTEND` habilitado, el cálculo
considera su capacidad máxima configurada.

### Procedimiento

`VERIFICAR_TABLESPACES`

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

Esta consulta muestra el espacio asignado a los archivos
de datos, no el porcentaje utilizado.

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

Si algún tablespace alcanza o supera el 85 %, el
procedimiento envía una alerta indicando:

- Nombre del tablespace.
- Porcentaje de ocupación.
- Base de datos y contenedor revisados.

Si varios tablespaces superan el umbral, se agrupan
en un único correo.

### Alcance de la verificación

El procedimiento revisa los tablespaces permanentes
visibles desde `XEPDB1`.

No incluye los tablespaces temporales.

El porcentaje corresponde a la capacidad máxima
configurada para los archivos, cuando aplica AUTOEXTEND.

---

## 10. Configuración de las alertas

Los tres procedimientos utilizan el mismo parámetro
para obtener el destinatario:

`CORREO_ALERTAS_BD`

Para verificar su valor:

```sql
SELECT
    CODIGO_PARAMETRO,
    VALOR
FROM CP_PARAMETRO
WHERE CODIGO_PARAMETRO = 'CORREO_ALERTAS_BD';
```

El envío se realiza mediante:

`PKG_CP_NOTIFICACIONES.enviar_correo`

Esto permite reutilizar el sistema de notificaciones
sin almacenar direcciones de correo directamente
dentro de los procedimientos.

## 11. Manejo de excepciones

Los procedimientos implementan un bloque:

```sql
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(
            'Error: ' || SQLERRM
        );
        RAISE;
```

Esto permite mostrar información del error y propagarlo
al proceso que invocó el procedimiento.

Cuando un job ejecuta el procedimiento y ocurre una
excepción no controlada, Oracle Scheduler puede
registrar la ejecución como fallida.

## 12. Programación automática

Los procedimientos son ejecutados mediante tres jobs:

| Procedimiento | Job |
|---|---|
| `VERIFICAR_OBJETOS_INVALIDOS` | `JOB_CP_VERIFICAR_OBJETOS_INVALIDOS` |
| `VERIFICAR_INDICES` | `JOB_CP_VERIFICAR_INDICES` |
| `VERIFICAR_TABLESPACES` | `JOB_CP_VERIFICAR_TABLESPACES` |

Los trabajos se programan diariamente a las
2:00 p. m., hora de Costa Rica.

La creación, ejecución manual y consulta del historial
de estos jobs se documenta en:

`DataBase_Scripts/jobs/diarios/README.md`

## 13. Solución de problemas

### Procedimiento INVALID

Consultar `USER_ERRORS` para identificar el problema
de compilación.

Verificar que existan los paquetes y tablas utilizados.

### ORA-00942: table or view does not exist

Verificar que el usuario `CP_POS` tenga los permisos
directos necesarios sobre las vistas administrativas.

### No se recibe la alerta

Verificar:

1. Que exista una inconsistencia real.
2. Que el parámetro `CORREO_ALERTAS_BD` esté configurado.
3. Que `PKG_CP_NOTIFICACIONES` esté compilado.
4. Que el servicio SMTP funcione correctamente.
5. Que el correo no esté en la carpeta de spam.

### El procedimiento muestra un error de envío

Consultar el mensaje de error de Oracle y revisar
la configuración de SMTP, Wallet y permisos de red.

## 14. Consideraciones de seguridad

- Los procedimientos pertenecen al esquema `CP_POS`.
- Los privilegios administrativos se otorgan de forma controlada.
- No se almacenan contraseñas de correo en los procedimientos.
- El destinatario se obtiene desde `CP_PARAMETRO`.
- El servicio de correo utiliza la configuración cifrada
  del módulo de notificaciones.
- Las pruebas que modifican objetos deben realizarse
  únicamente en desarrollo.

## 15. Resultado esperado

Al finalizar la instalación y las pruebas:

- Los tres procedimientos deben estar en estado `VALID`.
- Deben poder ejecutarse manualmente desde PL/SQL Developer.
- Deben detectar las inconsistencias contempladas.
- Deben enviar correos únicamente cuando corresponda.
- Deben poder ser invocados por Oracle Scheduler.
- La configuración del destinatario debe permanecer
  centralizada en `CP_PARAMETRO`.
