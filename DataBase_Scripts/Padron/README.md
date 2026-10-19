# Carga del Padrón Nacional Electoral
## CP-POS Multisucursal

Este documento explica cómo descargar el Padrón Nacional Electoral del Tribunal Supremo de Elecciones (TSE), copiarlo al contenedor Docker e importar sus registros a Oracle Database 21c XE mediante un paquete PL/SQL.

La información se almacena en la tabla `CP_PADRON_NACIONAL`.

## 1. Requisitos

- Docker Desktop con Oracle Database 21c XE.
- PL/SQL Developer.
- Conexión a `XEPDB1`.
- Usuario de base de datos `CP_POS`.
- Tabla `CP_PADRON_NACIONAL`.
- Secuencia `SEQ_CP_PADRON_NACIONAL`.
- Script SQL del paquete `PKG_CP_PADRON`.

## 2. Descargar y preparar el padrón

**Paso 1.** Ingresar a la página oficial del TSE:

https://www.tse.go.cr/descarga_padron.html

**Paso 2.** Descargar el archivo ZIP del Padrón Nacional completo.

**Paso 3.** Extraer el contenido del archivo descargado.

**Paso 4.** Abrir el Explorador de archivos de Windows, ingresar al disco `C:` y crear manualmente una carpeta llamada `padron`.

**Paso 5.** Copiar el TXT que contiene los datos del padrón completo a esa carpeta y asignarle el nombre `PADRON_COMPLETO.txt`.

La ubicación final debe ser:

`C:\padron\PADRON_COMPLETO.txt`

## 3. Copiar el archivo al contenedor Docker

Abrir PowerShell y ejecutar los siguientes comandos en orden.

**Paso 1. Verificar que el contenedor esté funcionando.**

```powershell
docker ps
```

El contenedor utilizado en este proyecto es `eif402-oracle21c-oficial`.

**Paso 2. Crear el directorio de destino dentro de Docker.**

```powershell
docker exec -u 0 eif402-oracle21c-oficial mkdir -p /tmp/padron
```

**Paso 3. Copiar el archivo desde Windows.**

```powershell
docker cp "C:\padron\PADRON_COMPLETO.txt" eif402-oracle21c-oficial:/tmp/padron/PADRON_COMPLETO.txt
```

**Paso 4. Asignar permisos de lectura.**

```powershell
docker exec -u 0 eif402-oracle21c-oficial chmod 755 /tmp/padron
docker exec -u 0 eif402-oracle21c-oficial chmod 644 /tmp/padron/PADRON_COMPLETO.txt
```

**Paso 5. Verificar que el archivo esté en Docker.**

```powershell
docker exec eif402-oracle21c-oficial ls -lh /tmp/padron/
```

Debe aparecer `PADRON_COMPLETO.txt` con su tamaño correspondiente.

## 4. Configurar Oracle

**Paso 1.** Abrir PL/SQL Developer y conectarse como `SYSTEM` a `XEPDB1`.

**Paso 2.** Crear el directorio Oracle:

```sql
CREATE OR REPLACE DIRECTORY DIR_PADRON AS '/tmp/padron';
```

**Paso 3.** Otorgar permisos de lectura al usuario del proyecto:

```sql
GRANT READ ON DIRECTORY DIR_PADRON TO CP_POS;
```

**Paso 4.** Conectarse nuevamente como `CP_POS`.

## 5. Verificar la lectura del archivo

Antes de importar los registros, ejecutar este bloque en una ventana PL/SQL:

```sql
DECLARE
    v_archivo UTL_FILE.FILE_TYPE;
    v_linea   VARCHAR2(32767);
BEGIN
    v_archivo := UTL_FILE.FOPEN(
        'DIR_PADRON',
        'PADRON_COMPLETO.txt',
        'R',
        32767
    );

    UTL_FILE.GET_LINE(v_archivo, v_linea);

    DBMS_OUTPUT.PUT_LINE('Archivo abierto correctamente');
    DBMS_OUTPUT.PUT_LINE('Primera linea: ' || v_linea);

    UTL_FILE.FCLOSE(v_archivo);

EXCEPTION
    WHEN OTHERS THEN
        IF UTL_FILE.IS_OPEN(v_archivo) THEN
            UTL_FILE.FCLOSE(v_archivo);
        END IF;

        RAISE;
END;
```

Activar **DBMS Output** para visualizar el resultado.

Esta prueba comprueba que Oracle puede leer el archivo sin modificar la tabla.

## 6. Instalar el paquete PL/SQL

**Paso 1.** Conectarse como `CP_POS`.

**Paso 2.** Abrir el script `CP_padron_nacional.sql` del módulo del padrón.

**Paso 3.** Ejecutar el script para crear el paquete `PKG_CP_PADRON` y su cuerpo.

**Paso 4.** Verificar la compilación:

```sql
SELECT OBJECT_NAME, OBJECT_TYPE, STATUS
FROM USER_OBJECTS
WHERE OBJECT_NAME = 'PKG_CP_PADRON';
```

Deben aparecer `PACKAGE` y `PACKAGE BODY` con estado `VALID`.

## 7. Ejecutar la carga del padrón

Desde una ventana PL/SQL, ejecutar:

```sql
BEGIN
    PKG_CP_PADRON.CARGAR_ARCHIVO('PADRON_COMPLETO.txt');
END;
```

El procedimiento está diseñado para:

- Leer y separar los campos del TXT.
- Validar las cédulas y los datos obligatorios.
- Evitar la inserción de cédulas duplicadas.
- Generar los identificadores con `SEQ_CP_PADRON_NACIONAL`.
- Controlar las transacciones mediante `SAVEPOINT`, `COMMIT` y `ROLLBACK`.
- Mostrar los registros leídos, insertados, duplicados y con errores.

El tiempo de ejecución depende del tamaño del archivo y de los recursos de Oracle.

## 8. Verificar los datos cargados

**Paso 1. Consultar la cantidad de registros.**

```sql
SELECT COUNT(*) AS TOTAL_REGISTROS
FROM CP_PADRON_NACIONAL;
```

**Paso 2. Consultar una muestra de los datos.**

```sql
SELECT
    ID_PADRON,
    CEDULA,
    NOMBRE,
    PRIMER_APELLIDO,
    SEGUNDO_APELLIDO,
    CODIGO_ELECTORAL
FROM CP_PADRON_NACIONAL
ORDER BY ID_PADRON
FETCH FIRST 20 ROWS ONLY;
```

**Paso 3. Comprobar que no existan cédulas duplicadas.**

```sql
SELECT CEDULA, COUNT(*) AS CANTIDAD
FROM CP_PADRON_NACIONAL
GROUP BY CEDULA
HAVING COUNT(*) > 1;
```

La última consulta no debe devolver registros.

## 9. Integración con clientes

La tabla `CP_PADRON_NACIONAL` permite consultar los datos básicos de las personas registradas en el padrón electoral.

Su integración con los clientes del sistema debe respetar las relaciones y claves definidas en el modelo relacional, utilizando las tablas correspondientes a personas y clientes.

## 10. Solución de problemas

**ORA-29283: archivo o ruta no válida**

Comprobar que `PADRON_COMPLETO.txt` exista en `/tmp/padron`, que `DIR_PADRON` apunte a esa ruta y que el usuario tenga permisos de lectura.

**ORA-00001: restricción única violada**

Comprobar que el paquete controle las cédulas duplicadas y utilice correctamente la secuencia.

**Errores de compilación del paquete**

Ejecutar:

```sql
SELECT LINE, POSITION, TEXT
FROM USER_ERRORS
WHERE NAME = 'PKG_CP_PADRON'
ORDER BY SEQUENCE;
```

Corregir los errores indicados y volver a compilar.

## 11. Consideraciones

- Utilizar el padrón completo descargado desde el sitio oficial del TSE.
- Mantener el nombre `PADRON_COMPLETO.txt` en Windows, Docker y la ejecución PL/SQL.
- No es necesario borrar registros ni reiniciar la secuencia para realizar una nueva carga.

## 12. Archivos del módulo

```text
padron/
├── CP_padron_nacional.sql
└── README.md
```

- **CP_padron_nacional.sql:** paquete PL/SQL encargado de importar los registros.
- **README.md:** documentación de instalación, configuración y ejecución.

**Fuente oficial:** [Tribunal Supremo de Elecciones — Descarga del Padrón Nacional](https://www.tse.go.cr/descarga_padron.html)