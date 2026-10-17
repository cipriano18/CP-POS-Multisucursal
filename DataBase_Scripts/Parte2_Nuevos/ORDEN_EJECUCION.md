# Scripts nuevos de la Parte 2 (seguridad y cifrado)

Esta carpeta contiene solo lo agregado en el Entregable #2. Los scripts 01-10 de la Parte 1 (en la carpeta de arriba) no se modifican.

Se ejecutan **después** de instalar la base completa (tablespaces, usuario, secuencias, tablas, constraints, índices, triggers, comentarios, datos de prueba, vistas).

| Orden | Script | Usuario | Qué crea | Re-ejecutable |
|---|---|---|---|---|
| 11 | `CP_seguridad_perfiles.sql` | SYS | Perfiles PRF_CP_USUARIO y PRF_CP_SERVICIO | Sí |
| 12 | `CP_seguridad_roles.sql` | SYS | Roles ROL_CP_CONEXION, GERENTE, JEFE_DEPARTAMENTO, JEFE_PROVEEDURIA, DIGITADOR; los 4 de negocio se conceden a CP_POS con ADMIN OPTION | Sí |
| 13 | `CP_seguridad_privilegios.sql` | SYS | Privilegios de objetos para los 4 roles de negocio | Sí (correr de nuevo al final si se agregan tablas) |
| 14 | `CP_seguridad_cifrado.sql` | CP_POS | Tablas CP_LLAVE_CIFRADO y CP_PARAMETRO con sus parámetros iniciales | No (crea tablas; borrar antes de repetir) |
| 15 | `CP_seguridad_paquetes.sql` | CP_POS | Paquetes PKG_CP_ERROR, PKG_CP_CRIPTO, PKG_CP_PARAMETRO, PKG_CP_SEGURIDAD, PKG_CP_CLAVE_ROL y PKG_CP_SESION; llave inicial, claves de los roles y pruebas | Sí (cambia las claves de roles solo si faltan) |
| 16 | `CP_seguridad_usuarios.sql` | SYS | Usuarios USR_CP_GERENTE, USR_CP_JEFE_DEPTO, USR_CP_JEFE_PROVEEDURIA y USR_CP_DIGITADOR, con ROL_CP_CONEXION como unico rol por defecto; las claves se piden al ejecutar | Sí (vuelve a pedir las claves) |
| 17 | `CP_seguridad_pruebas_usuarios.sql` | USR_CP_* (uno por uno) | Pruebas de seguridad con usuarios reales; no crea objetos | Sí |

Dependencias: el 12 va antes del 15 (el paquete de claves de rol necesita SELECT sobre SYS.DBA_ROLE_PRIVS y ADMIN OPTION sobre los roles); el 14 va antes del 15 (usa CP_PARAMETRO y CP_LLAVE_CIFRADO); el 17 necesita haber corrido el 15 y el 16.

Volver a correr el 13 después del 14 y del 15 es opcional: las tablas de sistema (CP_PARAMETRO, CP_LLAVE_CIFRADO) no se conceden a ningún rol, así que el resultado no cambia.

Si la instalación limpia falla en `CP_tablespaces.sql` (Parte 1) por la ruta de los archivos de datos, ajustar la ruta al entorno donde corre Oracle; los scripts de esta carpeta solo usan los nombres de los tablespaces, no las rutas.

Las claves de USR_CP_* se escriben al ejecutar el 16 y no se guardan en ningún script. Las claves de prueba usadas durante el desarrollo se cambian antes de la entrega final.
