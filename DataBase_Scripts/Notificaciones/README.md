
# Módulo de notificaciones por correo — CP-POS Multisucursal

## 1. Descripción

Este módulo permite enviar notificaciones automáticas desde Oracle Database 21c XE mediante el protocolo SMTP.

El proyecto utiliza Gmail como servidor SMTP, con conexión cifrada mediante STARTTLS y un Oracle Wallet para validar los certificados de seguridad.

El módulo es reutilizado por diferentes procesos del sistema, entre ellos:

- Alertas de objetos inválidos.
- Alertas de índices inutilizables.
- Alertas por ocupación de tablespaces.
- Notificaciones de clientes y proveedores.
- Otras notificaciones automáticas del sistema.

Las credenciales de correo se almacenan en la base de datos y la contraseña se protege mediante cifrado.

## 2. Tecnologías utilizadas

| Tecnología | Uso |
|---|---|
| Oracle Database 21c XE | Motor de base de datos |
| Docker | Ejecución del servidor Oracle |
| PL/SQL | Implementación de procedimientos y paquetes |
| UTL_SMTP | Envío de correos desde Oracle |
| Oracle Wallet | Gestión de certificados TLS |
| DBMS_CRYPTO | Cifrado de información sensible |
| Gmail SMTP | Servidor de correo |
| DBMS_SCHEDULER | Ejecución automática de procesos |

## 3. Requisitos previos

Antes de configurar el correo, verificar:

1. Oracle Database 21c XE está funcionando en Docker.
2. Existe el usuario `CP_POS` en `XEPDB1`.
3. El contenedor Oracle tiene acceso a Internet.
4. Se dispone de una cuenta Gmail autorizada para enviar correos.
5. Se dispone de una contraseña de aplicación u otro mecanismo SMTP compatible con la cuenta.
6. El administrador puede configurar permisos de red y certificados.
7. Existen las tablas de configuración del módulo.

No almacenar contraseñas reales ni archivos privados del Wallet en GitHub.

## 4. Configuración del servidor SMTP

El servicio de correo utilizado es Gmail.

| Parámetro | Valor |
|---|---|
| Servidor SMTP | smtp.gmail.com |
| Puerto | 587 |
| Seguridad | STARTTLS |
| Autenticación | Cuenta de correo y contraseña de aplicación |
| Wallet | /opt/oracle/wallets/smtp |

El servidor debe permitir conexiones salientes hacia `smtp.gmail.com` por el puerto `587`.

La ruta del Wallet debe existir dentro del contenedor de Oracle, no solamente en Windows.

## 5. Configuración de Oracle Wallet

Oracle Wallet permite validar los certificados utilizados durante la conexión TLS con Gmail.

En la implementación se utiliza la siguiente ubicación dentro del contenedor:

```text
/opt/oracle/wallets/smtp
```

La referencia utilizada desde PL/SQL es:

```text
file:/opt/oracle/wallets/smtp
```

### Procedimiento general

1. Acceder al contenedor donde se ejecuta Oracle.
2. Crear o verificar el directorio del Wallet.
3. Crear el Wallet con las herramientas de Oracle.
4. Importar los certificados de confianza necesarios para validar la conexión SMTP.
5. Verificar que el usuario del proceso Oracle tenga permisos de lectura.
6. Configurar el paquete de envío para utilizar la ruta del Wallet.

Los certificados deben obtenerse de fuentes confiables y comprobarse antes de importarlos.

**Nota:** los comandos exactos de creación e importación deben corresponder al procedimiento utilizado en el contenedor del proyecto. No publicar la contraseña del Wallet.

## 6. Permisos de red de Oracle

Oracle necesita autorización para establecer conexiones de red mediante `UTL_SMTP`.

Un administrador de la base de datos debe configurar una ACL que permita al esquema `CP_POS` conectarse al servidor SMTP.

Ejemplo de configuración, ejecutado por un administrador autorizado en `XEPDB1`:

```sql
BEGIN
    DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
        host       => 'smtp.gmail.com',
        lower_port => 587,
        upper_port => 587,
        ace        => XS$ACE_TYPE(
            privilege_list => XS$NAME_LIST('connect'),
            principal_name => 'CP_POS',
            principal_type => XS_ACL.PTYPE_DB
        )
    );
END;
/
```

Si la implementación necesita permisos adicionales para resolver nombres de host, estos deben configurarse según los requisitos de Oracle.

No otorgar permisos de red globales a todos los usuarios si no son necesarios.

## 7. Tablas utilizadas

El módulo utiliza las siguientes tablas:

| Tabla | Función |
|---|---|
| `CP_CONFIGURACION_CORREO` | Almacena la configuración del servicio SMTP y las credenciales protegidas. |
| `CP_CONTACTO` | Registra las direcciones de contacto. |
| `CP_DESTINATARIO_NOTIFICACION` | Identifica los destinatarios habilitados para recibir notificaciones. |
| `CP_NOTIFICACION` | Registra notificaciones generadas por el sistema. |
| `CP_NOTIFICACION_DESTINATARIO` | Relaciona las notificaciones con sus destinatarios. |
| `CP_PARAMETRO` | Almacena parámetros configurables, como el correo de alertas. |

Las tablas deben estar creadas antes de instalar los paquetes de notificaciones.

## 8. Configuración de credenciales

La configuración SMTP se administra mediante la tabla `CP_CONFIGURACION_CORREO`.

La contraseña del correo no debe almacenarse como texto plano.

El proyecto utiliza el paquete:

```sql
PKG_CP_CRIPTO
```

Este paquete permite proteger información sensible mediante cifrado y recuperar los valores cuando el proceso autorizado necesita utilizarlos.

La contraseña cifrada es utilizada internamente por el servicio de envío.

### Recomendaciones de seguridad

- No incluir contraseñas en archivos SQL del repositorio.
- No publicar valores cifrados junto con sus claves de descifrado.
- No registrar credenciales en mensajes de depuración.
- Mantener las claves de cifrado fuera del código público.
- Limitar los permisos de acceso a la configuración.

La carga inicial de las credenciales debe realizarse mediante un procedimiento administrativo seguro.

## 9. Configuración del destinatario de alertas

El correo destinatario de las alertas de mantenimiento se obtiene desde `CP_PARAMETRO`.

Se utiliza el código:

```text
CORREO_ALERTAS_BD
```

Para comprobar su configuración:

```sql
SELECT
    CODIGO_PARAMETRO,
    MODULO,
    VALOR
FROM CP_PARAMETRO
WHERE CODIGO_PARAMETRO = 'CORREO_ALERTAS_BD';
```

Para instalar el parámetro si todavía no existe, se puede utilizar el siguiente ejemplo. Sustituir el correo por el destinatario autorizado:

```sql
INSERT INTO CP_PARAMETRO (
    CODIGO_PARAMETRO,
    MODULO,
    TIPO_DATO,
    ES_CIFRADO,
    VALOR
)
SELECT
    'CORREO_ALERTAS_BD',
    'NOTIFICACION',
    'TEXTO',
    'N',
    'destinatario@ejemplo.com'
FROM DUAL
WHERE NOT EXISTS (
    SELECT 1
    FROM CP_PARAMETRO
    WHERE CODIGO_PARAMETRO = 'CORREO_ALERTAS_BD'
);

COMMIT;
```

Los procedimientos obtienen el correo mediante:

```sql
PKG_CP_PARAMETRO.obtener_texto('CORREO_ALERTAS_BD')
```

Esto permite cambiar el destinatario sin modificar los procedimientos PL/SQL.

## 10. Paquetes del módulo

### PKG_CP_CRIPTO

Se utiliza para cifrar y descifrar información sensible de forma controlada.

En particular, protege la contraseña utilizada para autenticarse con el servidor SMTP.

### PKG_CP_PARAMETRO

Permite consultar los parámetros configurados en `CP_PARAMETRO`.

Los procedimientos de monitoreo utilizan este paquete para obtener el destinatario de las alertas.

### PKG_CP_NOTIFICACIONES

Es el paquete encargado de realizar el envío de correos electrónicos desde Oracle.

Contiene el procedimiento:

```sql
PKG_CP_NOTIFICACIONES.enviar_correo(
    p_destinatario,
    p_asunto,
    p_mensaje
)
```

También contiene:

```sql
PKG_CP_NOTIFICACIONES.procesar_pendientes
```

Este último permite procesar las notificaciones pendientes y registrar el resultado de los intentos de envío.

## 11. Orden de instalación

Para instalar el módulo en una nueva base de datos:

1. Crear las tablas y estructuras necesarias.
2. Configurar los privilegios de red para `CP_POS`.
3. Preparar el Oracle Wallet y los certificados.
4. Instalar el paquete `PKG_CP_CRIPTO`.
5. Instalar el paquete `PKG_CP_PARAMETRO`.
6. Registrar la configuración SMTP y las credenciales cifradas.
7. Registrar los contactos y destinatarios autorizados.
8. Configurar el parámetro `CORREO_ALERTAS_BD`.
9. Instalar el paquete `PKG_CP_NOTIFICACIONES`.
10. Comprobar que los paquetes estén compilados correctamente.
11. Realizar una prueba de envío.

Este orden presupone que las dependencias de los paquetes y las tablas ya están disponibles.

## 12. Verificar que los paquetes estén compilados

Ejecutar conectado como `CP_POS`:

```sql
SELECT
    OBJECT_NAME,
    OBJECT_TYPE,
    STATUS
FROM USER_OBJECTS
WHERE OBJECT_NAME IN (
    'PKG_CP_CRIPTO',
    'PKG_CP_PARAMETRO',
    'PKG_CP_NOTIFICACIONES'
)
ORDER BY OBJECT_NAME, OBJECT_TYPE;
```

Los paquetes y sus cuerpos deben aparecer en estado `VALID`.

Si aparece `INVALID`, consultar los errores de compilación antes de continuar.

## 13. Realizar una prueba de envío

Ejecutar conectado como `CP_POS`:

```sql
DECLARE
    v_correo VARCHAR2(300);
BEGIN
    v_correo := PKG_CP_PARAMETRO.obtener_texto(
        'CORREO_ALERTAS_BD'
    );

    IF TRIM(v_correo) IS NULL THEN
        RAISE_APPLICATION_ERROR(
            -20054,
            'No existe un destinatario de alertas configurado'
        );
    END IF;

    PKG_CP_NOTIFICACIONES.enviar_correo(
        p_destinatario => v_correo,
        p_asunto       => 'Prueba de correo - CP-POS',
        p_mensaje      => 'Prueba de envio desde Oracle Database 21c XE.'
    );

    DBMS_OUTPUT.PUT_LINE(
        'Solicitud de envio ejecutada correctamente.'
    );
END;
/
```

### Resultado esperado

El destinatario configurado debe recibir un correo con:

**Asunto:**

```text
Prueba de correo - CP-POS
```

**Mensaje:**

```text
Prueba de envio desde Oracle Database 21c XE.
```

La ejecución del bloque sin errores y la recepción del mensaje permiten comprobar el funcionamiento del servicio.

## 14. Procesar notificaciones pendientes

Para ejecutar el procesamiento de notificaciones pendientes:

```sql
BEGIN
    PKG_CP_NOTIFICACIONES.procesar_pendientes;
END;
/
```

El paquete procesa los registros pendientes y actualiza su estado según el resultado del envío.

Para revisar las notificaciones se deben utilizar las consultas correspondientes a la estructura de `CP_NOTIFICACION` y `CP_NOTIFICACION_DESTINATARIO`.

## 15. Solución de problemas

### ORA-24247: network access denied

Oracle no tiene los permisos de red necesarios.

Verificar la configuración de la ACL para `CP_POS` y el servidor `smtp.gmail.com`.

### Error de certificados o Wallet

Comprobar:

- Que la ruta del Wallet sea correcta.
- Que los certificados necesarios estén importados.
- Que Oracle tenga permisos para leer el Wallet.
- Que la conexión STARTTLS pueda validar el certificado del servidor.

### Error de autenticación SMTP

Comprobar:

- Que la cuenta remitente esté configurada correctamente.
- Que las credenciales correspondan al mecanismo SMTP permitido.
- Que la contraseña cifrada pueda recuperarse mediante el paquete autorizado.
- Que la cuenta permita el envío por SMTP.

No imprimir ni compartir las credenciales durante la revisión.

### No llega el correo

1. Confirmar que el procedimiento se ejecutó sin errores.
2. Verificar el destinatario configurado.
3. Revisar el resultado del procesamiento de notificaciones.
4. Comprobar la conectividad del contenedor Oracle.
5. Revisar la carpeta de correo no deseado.
6. Consultar los errores registrados por el módulo.

## 16. Relación con los procedimientos de monitoreo

Los procedimientos de monitoreo utilizan este servicio de correo:

- `VERIFICAR_OBJETOS_INVALIDOS`
- `VERIFICAR_INDICES`
- `VERIFICAR_TABLESPACES`

Cuando detectan una inconsistencia, consultan el parámetro `CORREO_ALERTAS_BD` y llaman al procedimiento `PKG_CP_NOTIFICACIONES.enviar_correo`.

Si no existen inconsistencias, no generan correos de alerta.

La instalación y prueba de esos procedimientos se documenta por separado en:

```text
Notifications/procedures/README.md
```

La programación de los trabajos automáticos se documenta en:

```text
jobs/diarios/README.md
```

## 17. Consideraciones para Docker

- El servicio Oracle debe estar funcionando para enviar correos.
- El contenedor debe tener conectividad con el servidor SMTP.
- La ruta del Wallet debe estar disponible dentro del contenedor.
- Si el contenedor se elimina y se vuelve a crear, los archivos no persistidos pueden perderse.
- Se recomienda utilizar almacenamiento persistente para el Wallet y los datos de Oracle.
- No publicar archivos privados ni contraseñas en el repositorio.

## 18. Resultado esperado

Al finalizar la configuración:

- Oracle podrá conectarse al servidor SMTP de Gmail.
- Las credenciales estarán protegidas mediante cifrado.
- El destinatario de alertas será configurable.
- Los paquetes estarán compilados y disponibles.
- Se podrán enviar correos de prueba desde PL/SQL.
- Los procedimientos automáticos podrán reutilizar el servicio de notificaciones.
