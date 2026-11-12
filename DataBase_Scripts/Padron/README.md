# Padrón Nacional Electoral — CP-POS Multisucursal

## 1. Qué hace este módulo

El enunciado pide cargar el padrón nacional en la base de datos, adaptar el modelo y enlazar el padrón con los clientes para obtener los datos básicos de las personas, con un procedimiento que haga la carga automáticamente (6 % de la nota).

El script `CP_padron_nacional.sql` cubre las tres partes:

1. **Modelo:** agrega a `CP_PERSONA` la columna `id_padron`, con llave foránea hacia `CP_PADRON_NACIONAL`.
2. **Carga:** el paquete `PKG_CP_PADRON` lee el archivo del TSE y lo pasa a `CP_PADRON_NACIONAL`. Inserta las cédulas nuevas y actualiza solo las que cambiaron.
3. **Enlace y datos básicos:** el trigger `TRG_CP_PERSONA_PADRON` enlaza cada persona con su registro del padrón y completa el nombre y los apellidos cuando vienen vacíos. La vista `VW_CP_CLIENTE_PADRON` muestra cada cliente persona con sus datos del padrón.

Además, el job `JOB_CP_CARGA_PADRON` repite la carga el día 1 de cada mes.

## 2. Diseño y decisiones

### 2.1 El enlace va en `CP_PERSONA`

`CP_CLIENTE` no guarda datos de la persona; solo tipo, estado y fecha de ingreso. La cédula está en `CP_PERSONA.identificacion`, y un cliente persona llega a ella por `CP_CLIENTE_PERSONA`. Por eso el padrón se enlaza con la persona, que es la entidad que describe, y a través de ella con el cliente:

```text
CP_CLIENTE ── CP_CLIENTE_PERSONA ── CP_PERSONA ──(id_padron)──> CP_PADRON_NACIONAL
```

Si la misma persona fuera además empleado o contacto, el enlace se registra una sola vez.

### 2.2 Llave foránea opcional, mantenida por un trigger

| Opción | Por qué no / por qué sí |
|---|---|
| FK de `identificacion` a `CP_PADRON_NACIONAL.cedula` | Se descartó. El padrón electoral solo trae costarricenses mayores de edad, así que un cliente extranjero (DIMEX, pasaporte) no podría registrarse. Además, `identificacion` guarda otros documentos (`VARCHAR2(30)`). |
| Unir por cédula solo en las consultas, sin FK | Se descartó. El modelo no mostraría la relación, y el enunciado vuelve a calificar el modelo relacional. |
| **`CP_PERSONA.id_padron`, opcional, con FK** | **Elegida.** La relación se ve en el diagrama y está protegida por la FK. Quien no está en el padrón queda en `NULL`. |

La FK usa `ON DELETE SET NULL`: si un registro sale del padrón, la persona sigue existiendo, solo sin enlace.

El valor de `id_padron` no lo escribe nadie a mano. El trigger lo calcula siempre a partir de la identificación, así que el enlace no puede quedar distinto de la cédula de la persona. Es una regla que una restricción SQL no puede expresar, por eso va en un trigger (requisito 12 del enunciado).

### 2.3 Carga con tabla externa y un solo `MERGE`

La versión anterior leía el archivo línea por línea con `UTL_FILE` y hacía un `INSERT` por cada línea. Con un archivo de varios millones de líneas eso es lento, y nunca actualizaba a quien ya estaba cargado.

Ahora el archivo se lee como una **tabla externa** (`CP_PADRON_EXTERNO`) y se pasa a `CP_PADRON_NACIONAL` con un solo `MERGE`. Oracle procesa el archivo como un conjunto, que es la forma recomendada de hacer cargas masivas:

- Las cédulas nuevas se insertan.
- Las que ya existen se actualizan **solo si cambió algún dato**. Repetir la carga no reescribe millones de filas iguales, y eso importa porque cada fila escrita genera redo que viaja a la standby.
- Si una cédula se repite en el archivo, gana la última línea.
- Las líneas con datos inválidos (cédula que no tiene 9 dígitos, código electoral que no tiene 6, nombre o primer apellido vacío, textos demasiado largos) se cuentan y no se cargan.

La carga completa es una sola transacción: o entra todo o no entra nada. Mientras corre, la tabla queda bloqueada con `LOCK TABLE ... NOWAIT`, así que una segunda carga simultánea se rechaza al instante con `-20362`, en lugar de quedarse esperando.

El nombre del archivo se cambia en cada carga con `EXTERNAL MODIFY`. Esa cláusula cambia la tabla externa solo para esa consulta, sin DDL, así que la carga no hace ningún `COMMIT` implícito.

### 2.4 Codificación del archivo

El TXT del TSE normalmente viene en Windows-1252 (se comprueba en la sección 9), y la base está en AL32UTF8. Si se lee sin declarar la codificación, los nombres con tilde o con Ñ llegan rotos. La tabla externa declara la codificación del archivo, y Oracle convierte los textos al leerlos. La codificación sale del parámetro `PADRON_CHARSET` (por defecto `WE8MSWIN1252`), y `PKG_CP_PADRON.apply_charset` la aplica a la tabla con un `ALTER TABLE`. El script lo ejecuta al instalar, y hay que volver a ejecutarlo cada vez que cambie el parámetro. Como es DDL, confirma la transacción de la sesión; por eso va en un procedimiento aparte y no dentro de la carga. La prueba 5 del script comprueba la conversión con un apellido con Ñ.

### 2.5 Datos básicos al registrar una persona

Al insertar en `CP_PERSONA`, el trigger busca la identificación en el padrón. Acepta la cédula con o sin guiones (`1-1111-1111` o `111111111`):

- **Si está en el padrón:** guarda `id_padron` y completa `primer_nombre`, `segundo_nombre`, `primer_apellido` y `segundo_apellido` cuando vienen vacíos. El padrón trae los nombres juntos («MARIA JOSE»): la primera palabra va al primer nombre y el resto al segundo. Lo que el usuario escribió no se cambia.
- **Si no está:** `id_padron` queda en `NULL`. Si además faltan el nombre o el primer apellido, el registro se rechaza con `-20361`.

El padrón no trae la fecha de nacimiento ni la nacionalidad. Esos campos, obligatorios en `CP_PERSONA`, los sigue escribiendo el usuario.

## 3. Objetos que crea

| Objeto | Tipo | Qué hace |
|---|---|---|
| `CP_PERSONA.id_padron` | Columna | Enlace opcional con el padrón, con `FK_CP_PERSONA_PADRON` e índice `IX_CP_PERSONA_PADRON` |
| `PADRON_ARCHIVO`, `PADRON_CHARSET` | Parámetros en `CP_PARAMETRO` | Archivo a cargar y su codificación |
| `CP_PADRON_EXTERNO` | Tabla externa | Lee el TXT directamente desde `DIR_PADRON` |
| `PKG_CP_PADRON` | Paquete | `load_file`, `link_persons`, `apply_charset`, `complete_person`, `find_padron_id`, `normalize_id`, `last_result` |
| `TRG_CP_PERSONA_PADRON` | Trigger | Enlaza a la persona y completa sus datos básicos |
| `VW_CP_CLIENTE_PADRON` | Vista | Clientes persona con sus datos del padrón |
| `JOB_CP_CARGA_PADRON` | Job | Carga mensual, el día 1 a las 02:00 |

La tabla `CP_PADRON_NACIONAL` y su secuencia ya existen desde los scripts de la Parte 1 (`CP_tablas.sql` y `CP_secuencias.sql`).

## 4. Requisitos

- Base instalada con los scripts de la Parte 1 y el script 15 (`PKG_CP_ERROR` y `PKG_CP_PARAMETRO`).
- Contenedor de Oracle en ejecución: `eif402-oracle21c-oficial` (XE, PDB `XEPDB1`) o `dg-primaria` (Enterprise, PDB `ORCLPDB1`).
- Archivo del padrón completo descargado del TSE.

## 5. Descargar y preparar el padrón

1. Entrar a la página oficial del TSE: https://www.tse.go.cr/descarga_padron.html
2. Descargar el ZIP del padrón nacional completo y extraerlo.
3. Crear la carpeta `C:\padron` y copiar ahí el TXT del padrón completo con el nombre `PADRON_COMPLETO.txt`.

Cada línea del archivo tiene 8 campos separados por coma, rellenos con espacios:

```text
cedula,codigo_electoral,sexo,fecha_caducidad,junta,nombre,primer_apellido,segundo_apellido
```

Se usan la cédula, el código electoral, el nombre y los dos apellidos; los otros tres campos se leen y se ignoran.

## 6. Copiar el archivo al contenedor

En PowerShell. Para la instalación Enterprise, cambie `eif402-oracle21c-oficial` por `dg-primaria`.

**Paso 1. Crear la carpeta dentro del contenedor.**

```powershell
docker exec -u 0 eif402-oracle21c-oficial mkdir -p /tmp/padron
```

**Paso 2. Copiar el archivo.**

```powershell
docker cp "C:\padron\PADRON_COMPLETO.txt" eif402-oracle21c-oficial:/tmp/padron/PADRON_COMPLETO.txt
```

**Paso 3. Dar la carpeta al usuario `oracle`.** Oracle no solo lee el archivo: también escribe ahí el registro de la carga (`padron_carga.log`) y las líneas rechazadas (`padron_rechazos.bad`), y las pruebas crean y borran un archivo pequeño. Por eso la carpeta debe pertenecer al usuario `oracle`.

```powershell
docker exec -u 0 eif402-oracle21c-oficial chown -R oracle /tmp/padron
docker exec eif402-oracle21c-oficial ls -lh /tmp/padron/
```

Debe aparecer `PADRON_COMPLETO.txt` con su tamaño y con `oracle` como dueño.

## 7. Configurar Oracle (como SYS)

Conectado como `SYS` (o `SYSTEM`) a la PDB (`XEPDB1` o `ORCLPDB1`):

```sql
CREATE OR REPLACE DIRECTORY DIR_PADRON AS '/tmp/padron';
GRANT READ, WRITE ON DIRECTORY DIR_PADRON TO CP_POS;
```

`READ` permite leer el padrón y `WRITE` permite escribir los archivos de registro de la carga. Sin `WRITE`, la consulta sobre la tabla externa falla.

## 8. Instalar el módulo

**Paso 1.** Conectado como `CP_POS`, ejecutar el script completo (F5 en SQL Developer o `@CP_padron_nacional.sql` en SQL*Plus). Se puede volver a ejecutar las veces que haga falta.

**Paso 2.** Revisar la salida:

- Sección 1: `OK` u `OMITIDO` (si ya existían) para la columna, la FK y el índice.
- `SHOW ERRORS` del paquete y del trigger: «No errors».
- Sección 8: «CP_PADRON_EXTERNO lee el archivo en WE8MSWIN1252» y «Personas con enlace actualizado: n».
- Sección 9: las 18 pruebas en `OK` y al final `Resultado: 18 OK, 0 FALLA`.
- Sección 10: `JOB_CP_CARGA_PADRON` en estado `SCHEDULED`.
- Sección 11: `OBJETOS_INVALIDOS = 0`. Agregar la columna a `CP_PERSONA` puede dejar en `INVALID` las rutinas que usan esa tabla; el script las recompila para que el control diario de objetos inválidos no mande una alerta falsa.

Las pruebas no necesitan el padrón real. Escriben su propio archivo pequeño en `DIR_PADRON`, con cédulas falsas (`99999000x`), en la codificación de `PADRON_CHARSET` y con fin de línea CRLF como el del TSE. Todo se deshace con `ROLLBACK`, y el archivo se borra al terminar.

**Paso 3.** Conectado como `SYS`, volver a ejecutar `Seguridad/CP_seguridad_privilegios.sql` (script 13). Así se da lectura de `VW_CP_CLIENTE_PADRON` a los roles Digitador, Jefe de Departamento y Gerente, y `CP_PADRON_EXTERNO` queda clasificada como tabla de sistema, sin permisos para los roles.

| Prueba | Qué comprueba |
|---|---|
| 1-2 | Las cédulas de prueba no existen; una persona fuera del padrón queda sin enlace |
| 3-4 | Conteo de la carga: leídas, válidas, inválidas, repetidas, insertadas y actualizadas |
| 5 | La Ñ llega bien con la codificación del archivo |
| 6 | Se quitan los espacios de relleno y el fin de línea; un apellido vacío queda `NULL` |
| 7 | La carga enlaza a una persona que ya existía con la cédula escrita con guiones |
| 8 | Repetir la misma carga no inserta ni actualiza nada |
| 9 | Un nombre que cambió en el archivo se actualiza |
| 10 | Una persona registrada solo con la cédula recibe nombre y apellidos del padrón |
| 11 | Una cédula con guiones se enlaza y se respeta el nombre escrito |
| 12-13 | Un pasaporte con nombre se registra sin enlace; sin nombre se rechaza con `-20361` |
| 14 | Cambiar la identificación recalcula el enlace; escribir `id_padron` a mano no tiene efecto |
| 15 | La vista muestra al cliente con sus datos del padrón |
| 16-17 | Un nombre de archivo con ruta da `-20360`; un archivo inexistente da `-20363` |
| 18 | El `ROLLBACK` deja la base como estaba |

## 9. Revisar el archivo antes de cargarlo

Esta consulta lee el archivo sin cargarlo. Sirve para confirmar el formato y la codificación:

```sql
SELECT cedula, nombre, primer_apellido, segundo_apellido
FROM   CP_PADRON_EXTERNO
WHERE  primer_apellido LIKE '%' || UNISTR('\00D1') || '%'
FETCH FIRST 5 ROWS ONLY;
```

Deben salir apellidos con Ñ escritos correctamente (por ejemplo, MUÑOZ o NUÑEZ).

- Si salen con caracteres raros, el archivo no está en Windows-1252. Cambie el parámetro y aplíquelo; por ejemplo, para UTF-8:

  ```sql
  EXEC PKG_CP_PARAMETRO.guardar('PADRON_CHARSET', 'AL32UTF8');
  COMMIT;
  EXEC PKG_CP_PADRON.apply_charset;
  ```

  Después repita la consulta.
- La consulta lee `PADRON_COMPLETO.txt`, el archivo con que se creó la tabla. La carga, en cambio, usa el archivo del parámetro `PADRON_ARCHIVO`.

## 10. Cargar el padrón

```sql
SET SERVEROUTPUT ON
EXEC PKG_CP_PADRON.load_file;
```

Sin argumentos usa el archivo del parámetro `PADRON_ARCHIVO`. Para cargar otro archivo de la misma carpeta: `EXEC PKG_CP_PADRON.load_file('otro_archivo.txt');`

Resultado esperado:

```text
Carga del padron: PADRON_COMPLETO.txt (WE8MSWIN1252)
  Lineas leidas      : (total de lineas del archivo)
  Validas            : ...
  Invalidas          : ...
  Repetidas          : ...
  Insertadas         : (la primera vez, casi todas las validas)
  Actualizadas       : (la primera vez, 0)
  Personas enlazadas : ...
```

La carga completa tarda unos minutos, según el equipo. Una segunda carga del mismo archivo debe dar `Insertadas: 0` y `Actualizadas: 0`.

**Automatización.** Oracle no puede descargar ni descomprimir el ZIP del TSE por sí solo; ese paso lo hace una persona cuando el TSE publica un padrón nuevo. Lo demás sí es automático: el job `JOB_CP_CARGA_PADRON` carga el archivo de la carpeta el día 1 de cada mes y enlaza a las personas. Para ejecutarlo en el momento (por ejemplo, en la defensa):

```sql
EXEC DBMS_SCHEDULER.RUN_JOB('JOB_CP_CARGA_PADRON', FALSE);
```

## 11. Enlace con las personas y los clientes

**Registrar una persona solo con la cédula.** El trigger completa los nombres desde el padrón. Use una cédula que esté en el padrón cargado:

```sql
INSERT INTO CP_PERSONA (id_nacionalidad, id_estado_civil, id_sexo, id_escolaridad,
                        id_tipo_residencia, identificacion, fecha_nacimiento)
VALUES (1, 1, 1, 1, 1, '1-1111-1111', DATE '1990-01-01');

SELECT identificacion, primer_nombre, segundo_nombre, primer_apellido,
       segundo_apellido, id_padron
FROM   CP_PERSONA
WHERE  identificacion = '1-1111-1111';

ROLLBACK;
```

**Recalcular el enlace de todas las personas**, por ejemplo después de corregir identificaciones. La carga ya lo hace al final, así que normalmente no hace falta:

```sql
EXEC PKG_CP_PADRON.link_persons;
```

**Ver los clientes con sus datos del padrón:**

```sql
SELECT id_cliente, identificacion, primer_nombre, primer_apellido,
       en_padron, nombre_padron, primer_apellido_padron, codigo_electoral
FROM   VW_CP_CLIENTE_PADRON;
```

Las personas de los datos de prueba de la Parte 1 tienen cédulas inventadas. Después de cargar el padrón real es normal que pocas o ninguna queden enlazadas; para la demostración, use el `INSERT` de arriba con una cédula real.

## 12. Verificar los datos cargados

```sql
-- Registros cargados y personas enlazadas
SELECT (SELECT COUNT(*) FROM CP_PADRON_NACIONAL)                    AS registros_padron,
       (SELECT COUNT(*) FROM CP_PERSONA WHERE id_padron IS NOT NULL) AS personas_enlazadas
FROM   dual;

-- Muestra del padron
SELECT cedula, nombre, primer_apellido, segundo_apellido, codigo_electoral
FROM   CP_PADRON_NACIONAL
FETCH FIRST 20 ROWS ONLY;

-- Lineas que Oracle no pudo leer (si las hubo) y detalle de la carga
-- quedan en /tmp/padron/padron_rechazos.bad y /tmp/padron/padron_carga.log
```

No hace falta revisar si hay cédulas duplicadas: la restricción `UK_CP_PADRON_NACIONAL_CEDULA` lo impide.

## 13. Parámetros

| Código | Valor inicial | Uso |
|---|---|---|
| `PADRON_ARCHIVO` | `PADRON_COMPLETO.txt` | Archivo que carga `load_file` sin argumentos y el job |
| `PADRON_CHARSET` | `WE8MSWIN1252` | Codificación del archivo (nombre de juego de caracteres de Oracle) |

Se cambian sin tocar el código: `EXEC PKG_CP_PARAMETRO.guardar('PADRON_ARCHIVO', 'nuevo.txt'); COMMIT;`. Después de cambiar `PADRON_CHARSET`, ejecute además `EXEC PKG_CP_PADRON.apply_charset;`.

## 14. Errores propios y solución de problemas

| Código | Significado | Qué hacer |
|---|---|---|
| `-20360` | El nombre del archivo no es válido | Use solo el nombre, sin ruta: letras, números, punto, guion y guion bajo |
| `-20361` | La persona no tiene nombre y su identificación no está en el padrón | Escriba el nombre y el primer apellido, o revise la cédula |
| `-20362` | Hay otra carga del padrón en curso | Espere a que termine |
| `-20363` | No se pudo leer el archivo en `DIR_PADRON` | Revise que el archivo exista en `/tmp/padron`, que `DIR_PADRON` apunte ahí, que `CP_POS` tenga `READ` y `WRITE` y que la carpeta pertenezca a `oracle` (sección 6, paso 3) |
| `-20364` | `PADRON_CHARSET` no es un juego de caracteres de Oracle (lo revisa `apply_charset`) | Use, por ejemplo, `WE8MSWIN1252` o `AL32UTF8` |

Todos se registran en `CP_BITACORA_ERROR` con el módulo `PADRON`, junto con cualquier error inesperado.

**ORA-30657 en un `COMMENT ON TABLE`:** Oracle no admite comentarios en tablas externas. Por eso la descripción de `CP_PADRON_EXTERNO` está como comentario dentro del script y no en el diccionario de datos de Oracle.

**El script falla en la sección 3 con ORA-06564** (el objeto `DIR_PADRON` no existe): falta la sección 7 de este README.

**Errores de compilación:**

```sql
SELECT name, line, position, text
FROM   user_errors
WHERE  name IN ('PKG_CP_PADRON', 'TRG_CP_PERSONA_PADRON')
ORDER  BY name, sequence;
```

## 15. Standby y entorno Enterprise

- **La carga se replica sola.** Las filas cargadas viajan a la standby por el redo, como cualquier otro cambio. Para eso la primaria debe estar en `FORCE LOGGING` (guía de FSFO, paso 3): si una carga masiva no generara redo, la standby quedaría incompleta.
- **El archivo no se replica.** `/tmp/padron` está en el sistema de archivos del contenedor, no en la base. Si hay un failover y hay que volver a cargar desde la nueva primaria, el archivo tiene que copiarse a ese contenedor (sección 6). El objeto `DIR_PADRON` sí llega con la base, porque está en el diccionario.
- **En `dg-primaria`** se siguen los mismos pasos, cambiando el contenedor por `dg-primaria` y la PDB por `ORCLPDB1`.

## 16. Archivos del módulo

```text
Padron/
├── CP_padron_nacional.sql
└── README.md
```

- **CP_padron_nacional.sql:** cambio de modelo, parámetros, tabla externa, paquete, trigger, vista, pruebas, job y consultas para la defensa.
- **README.md:** este documento.
