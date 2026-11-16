# CP-POS Multisucursal

Sistema de punto de venta multisucursal desarrollado para el curso **Administración de Bases de Datos II** de la Universidad Nacional. El proyecto modela y administra ventas, compras, inventario, clientes, proveedores, créditos, promociones, descuentos, devoluciones y operaciones relacionadas.

## Tecnologías y entorno

- Oracle Database 21c Enterprise Edition.
- SQL y PL/SQL.
- Docker Desktop en Windows.
- PL/SQL Developer y Oracle SQL Developer para ejecutar y administrar scripts.
- Configuración Data Guard con una base primaria y una física standby.

La instalación principal del proyecto utiliza el servicio `ORCLPDB1` y el esquema propietario `CP_POS`. Los archivos SQL deben ejecutarse en el contenedor y servicio configurados para la instalación de cada persona; consulte los manuales para ajustar nombres, puertos y rutas del entorno.

## Funcionalidad

El sistema incluye:

- Gestión multisucursal, usuarios, clientes personales y empresariales, contactos, proveedores, productos y servicios.
- Inventario por sucursal, almacén y lote; traslados entre almacenes y salida de productos con criterio FEFO.
- Facturación de ventas y compras, cuentas por cobrar y pagar, créditos, abonos y devoluciones.
- Validaciones de límites de crédito, estados de facturas y consistencia de saldos.
- Actualización automática de inventario y del costo de compra, con bitácoras de cambios.
- Seguridad basada en perfiles, roles de negocio, usuarios y activación de roles mediante claves cifradas.
- Cifrado de parámetros sensibles y configuración de correo para notificaciones generadas desde Oracle.
- Padrón Nacional Electoral, carga desde archivo, enlace opcional con personas y consulta de datos básicos.
- Reglas de cierre diario, vencimiento y antigüedad de inventario, descuentos, promociones y premiación de clientes.
- Auditoría de operaciones críticas y monitoreo de objetos, índices, sesiones, bloqueos y tablespaces.
- Oracle Scheduler para tareas periódicas, y Data Guard/RMAN para continuidad y respaldos.

### Módulos del proyecto

| Módulo | Alcance |
|---|---|
| Esquema base | Tablas, secuencias, restricciones, índices, triggers, comentarios, datos de prueba y vistas del punto de venta. |
| Seguridad | Perfiles, roles, usuarios de aplicación, permisos por rol, claves de roles cifradas y activación controlada de privilegios. |
| Facturación y crédito | Registro transaccional de ventas y compras, cuentas por cobrar y pagar, límites de crédito, abonos, cancelación de facturas y devoluciones. |
| Inventario y costos | Movimientos automáticos por factura/devolución, asignación FEFO por lote, validación de existencias, protección de detalles y bitácora de cambios de costo. |
| Reglas de negocio | Cierre diario, alertas de vencimiento y antigüedad, descuentos planificados, acciones de promociones y premiación periódica de clientes. |
| Padrón nacional | Carga de archivo del TSE, conciliación de registros y consulta de datos básicos enlazados opcionalmente con personas/clientes. |
| Notificaciones | Configuración de remitente y destinatarios, secreto SMTP cifrado, cola de mensajes y envío desde Oracle mediante SMTP/TLS. |
| Monitoreo y auditoría | Seguimiento de objetos inválidos, índices, tablespaces, sesiones, bloqueos y errores; auditoría de operaciones críticas y de seguridad. |
| Continuidad y respaldos | Oracle Data Guard Broker con una base primaria y una standby física; respaldos y gestión de archivelogs con RMAN. |
| Reportes | Vistas de negocio, vistas materializadas de ventas e inventario y análisis de planes de ejecución. |

## Esquema y almacenamiento

Los objetos de aplicación utilizan el prefijo `CP_`. El diseño base contiene 100 tablas; los módulos posteriores agregan objetos de soporte como vistas, paquetes, jobs y objetos para la carga del padrón.

Los tablespaces del proyecto son:

| Tablespace | Uso |
|---|---|
| `CP_POS_DATOS` | Tablas principales y datos de la aplicación. |
| `CP_POS_INDICES` | Índices y restricciones basadas en índices. |
| `CP_POS_AUDITORIA` | Tablas de bitácora y auditoría. |

## Estructura del repositorio

```text
DataBase_Scripts/
  CP_*.sql                 Scripts de instalación base (Parte 1)
  Seguridad/               Perfiles, roles, cifrado, usuarios y auditoría
  facturacion/              Cuentas, crédito, inventario, costos y transacciones
  negocio/                  Cierre, vencimientos, descuentos, promociones y reportes
  Notificaciones/           Configuración SMTP, cola, paquetes y pruebas
  Padron/                   Modelo, carga e instrucciones del padrón
  jobs/diarios/              Definiciones individuales de los 11 jobs vigentes
  standby/                   Guía de operación de Data Guard y RMAN
  ORDEN_EJECUCION.md         Secuencia general y dependencias de instalación
MANUALES/                    Manuales PDF de instalación, administración y operación
modelo/                      Diagrama y artefactos del modelo
documentacion/               Documentación complementaria del proyecto
```

## Instalación

La instalación completa se realiza sobre una base preparada para el proyecto. **No ejecute los scripts de creación inicial sobre una base que ya contiene datos sin revisar antes sus efectos**: varios scripts alteran tablas y el script de datos de prueba no debe repetirse después de instalar el módulo de facturación.

### Parte 1: esquema base

Ejecute en este orden:

| Orden | Archivo | Usuario |
|---:|---|---|
| 1 | `CP_tablespaces.sql` | SYS / administrador |
| 2 | `CP_usuario_esquema.sql` | SYS / administrador |
| 3 | `CP_secuencias.sql` | `CP_POS` |
| 4 | `CP_tablas.sql` | `CP_POS` |
| 5 | `CP_constraints.sql` | `CP_POS` |
| 6 | `CP_indices.sql` | `CP_POS` |
| 7 | `CP_triggers_reglas.sql` | `CP_POS` |
| 8 | `CP_comentarios.sql` | `CP_POS` |
| 9 | `CP_datos_prueba.sql` | `CP_POS` |
| 10 | `CP_vistas.sql` | `CP_POS` |
| 11 | `CP_pruebas.sql` | `CP_POS` |

### Parte 2: seguridad, facturación y negocio

Después de la Parte 1, siga `DataBase_Scripts/ORDEN_EJECUCION.md` y las guías específicas de `Seguridad/`, `facturacion/` y `negocio/`. La secuencia abarca los scripts numerados del 11 al 36, con dependencias y usuarios de ejecución indicados allí. Algunos pasos son de una sola ejecución porque agregan columnas o restricciones.

### Notificaciones y padrón

La instalación del correo requiere configuración administrativa previa (privilegios y ACL de red ejecutados por SYS), certificados TLS disponibles para Oracle, configuración SMTP bajo `CP_POS` y los paquetes y jobs del módulo. Siga `DataBase_Scripts/Notificaciones/README.md` y el orden general.

El padrón requiere obtener el archivo oficial del TSE, copiarlo al contenedor Oracle, crear como SYS el objeto `DIR_PADRON` con sus privilegios y ejecutar los scripts como `CP_POS`. Los pasos portables están en `DataBase_Scripts/Padron/README.md`; el archivo fuente no está incluido en el repositorio.

## Roles de aplicación

La seguridad define los roles `ROL_CP_GERENTE`, `ROL_CP_JEFE_DEPARTAMENTO`, `ROL_CP_JEFE_PROVEEDURIA` y `ROL_CP_DIGITADOR`, además del rol de conexión `ROL_CP_CONEXION`. Los usuarios de aplicación se crean mediante los scripts de seguridad y los privilegios se asignan según las responsabilidades de cada rol. Consulte `DataBase_Scripts/Seguridad/` para conocer qué se ejecuta como SYS y qué se ejecuta como `CP_POS`.

Las claves para activar los roles se almacenan cifradas en la base de datos. Las cuentas creadas para la aplicación reciben `ROL_CP_CONEXION` como rol inicial; el usuario activa su rol de negocio mediante los paquetes de sesión y seguridad del esquema `CP_POS`.

## Jobs programados

Los 11 jobs vigentes tienen un SQL individual en `DataBase_Scripts/jobs/diarios/`. Los módulos de notificaciones, negocio y padrón también crean los jobs correspondientes como parte de su instalación. Para evitar definiciones duplicadas, instale cada job desde el script del módulo o desde su archivo individual, no desde ambos.

La lista, frecuencia, origen de cada definición y consultas para revisar el estado de Oracle Scheduler están en [`DataBase_Scripts/jobs/diarios/README.md`](DataBase_Scripts/jobs/diarios/README.md). Los jobs se ejecutan mientras la instancia Oracle y Scheduler están activos.

## Data Guard y respaldos RMAN

El entorno del proyecto contempla una base primaria y una standby física administradas por Data Guard Broker. El transporte y la aplicación de redo se realizan de forma continua según el modo configurado en Broker. RMAN administra respaldos de la base y archivelogs. La carpeta `DataBase_Scripts/standby/` contiene la guía de pasos y el manual de administración describe las comprobaciones, respaldos y operaciones controladas. Consulte [`DataBase_Scripts/standby/standby_pasos.txt`](DataBase_Scripts/standby/standby_pasos.txt) y [`MANUALES/Manual_Administracion_Standby_CP_POS.pdf`](MANUALES/Manual_Administracion_Standby_CP_POS.pdf) antes de ejecutar mantenimiento o cambios de rol.

## Pruebas

El repositorio incluye scripts de pruebas para la instalación base, permisos de usuarios, facturación, inventario, costos, transacciones, reglas de negocio, padrón, notificaciones y auditoría. Algunos guiones de concurrencia requieren dos conexiones simultáneas. Consulte el encabezado y la guía de cada script antes de ejecutarlo: ciertas pruebas crean datos temporales, realizan `COMMIT` o requieren `ROLLBACK` manual.

## Verificación y documentación

- `DataBase_Scripts/ORDEN_EJECUCION.md`: dependencias y orden general.
- `DataBase_Scripts/facturacion/ORDEN_EJECUCION.md`: facturación, crédito, inventario, costos y transacciones.
- `DataBase_Scripts/negocio/ORDEN_EJECUCION.md`: módulos de negocio y reportes.
- `DataBase_Scripts/Notificaciones/README.md`: correo, wallet y trabajos de notificación.
- `DataBase_Scripts/Padron/README.md`: preparación y carga del padrón.
- `MANUALES/Manual_de_instalacion_CP_POS.pdf`: instalación del sistema.
- `MANUALES/Manual_Tecnico_CP_POS.pdf`: administración y mantenimiento técnico.
- `MANUALES/Manual_Administracion_Standby_CP_POS.pdf`: operación de Data Guard y RMAN.
- `modelo/Diagrama_Proyecto_db.pdf`: diagrama del modelo relacional.
- `documentacion/Diccionario_Datos_CP_POS.pdf`: diccionario de datos.

Los scripts de pruebas funcionales están distribuidos en las carpetas de cada módulo. Ejecútelos únicamente con el usuario y en el entorno indicados por su documentación, y revise la salida y el historial de Oracle Scheduler antes de considerar una tarea periódica validada.

## Autoría

**Estudiantes:**

- Cipriano Rivera Escobar
- Marvin Torres Sequeira

**Profesor:** Ing. Jeremy Elizondo Castro

Universidad Nacional de Costa Rica · Sede Regional Brunca

Curso: Administración de Bases de Datos II · II Ciclo 2026
