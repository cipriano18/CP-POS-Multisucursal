# Scripts nuevos de la Parte 2 (seguridad, cifrado, facturacion y negocio)

Este documento ordena solo lo agregado en el Entregable #2. Los scripts 01-10 de la Parte 1 (en `DataBase_Scripts/`) no se modifican.

Los scripts de seguridad (11 al 17) estan en `DataBase_Scripts/Seguridad/`, los de facturacion e inventario (18 al 25) en `DataBase_Scripts/facturacion/` y los de reglas de negocio (26 al 34) en `DataBase_Scripts/negocio/`; las dos ultimas carpetas tienen ademas su propio `ORDEN_EJECUCION.md` con el detalle. Las rutas de la tabla son relativas a `DataBase_Scripts/`. El orden de ejecucion es el numero de la primera columna, sin importar la carpeta; recuerda que el 25 se ejecuta antes que el 23.

Se ejecutan **después** de instalar la base completa (tablespaces, usuario, secuencias, tablas, constraints, índices, triggers, comentarios, datos de prueba, vistas).

| Orden | Script | Usuario | Qué crea | Re-ejecutable |
|---|---|---|---|---|
| 11 | `Seguridad/CP_seguridad_perfiles.sql` | SYS | Perfiles PRF_CP_USUARIO y PRF_CP_SERVICIO | Sí |
| 12 | `Seguridad/CP_seguridad_roles.sql` | SYS | Roles ROL_CP_CONEXION, GERENTE, JEFE_DEPARTAMENTO, JEFE_PROVEEDURIA, DIGITADOR; los 4 de negocio se conceden a CP_POS con ADMIN OPTION | Sí |
| 13 | `Seguridad/CP_seguridad_privilegios.sql` | SYS | Privilegios de objetos para los 4 roles de negocio, y `EXECUTE`/`SELECT` de los paquetes, las vistas y las vistas materializadas de los scripts 25 al 34 (si ya existen) | Sí (correr de nuevo al final, despues del 35) |
| 14 | `Seguridad/CP_seguridad_cifrado.sql` | CP_POS | Tablas CP_LLAVE_CIFRADO y CP_PARAMETRO con sus parámetros iniciales | No (crea tablas; borrar antes de repetir) |
| 15 | `Seguridad/CP_seguridad_paquetes.sql` | CP_POS | Paquetes PKG_CP_ERROR, PKG_CP_CRIPTO, PKG_CP_PARAMETRO, PKG_CP_SEGURIDAD, PKG_CP_CLAVE_ROL y PKG_CP_SESION; llave inicial, claves de los roles y pruebas | Sí (cambia las claves de roles solo si faltan) |
| 16 | `Seguridad/CP_seguridad_usuarios.sql` | SYS | Usuarios USR_CP_GERENTE, USR_CP_JEFE_DEPTO, USR_CP_JEFE_PROVEEDURIA y USR_CP_DIGITADOR, con ROL_CP_CONEXION como unico rol por defecto; las claves se piden al ejecutar | Sí (vuelve a pedir las claves) |
| 17 | `Seguridad/CP_seguridad_pruebas_usuarios.sql` | USR_CP_* (uno por uno) | Pruebas de seguridad con usuarios reales; no crea objetos | Sí |
| 18 | `facturacion/CP_facturacion_cuentas.sql` | CP_POS | Columnas `monto_total` y `saldo_pendiente` en CP_CUENTA_COBRAR y CP_CUENTA_PAGAR, con restricciones y comentarios; retira TRG_CP_ABONO_COBRAR_LIMITE y TRG_CP_ABONO_PAGAR_LIMITE | No (cambia tablas; ejecutar una sola vez) |
| 19 | `facturacion/CP_facturacion_credito_pagar.sql` | CP_POS | Columna `id_credito_proveedor` en CP_CUENTA_PAGAR (llave foranea, indice y comentario): cada cuenta por pagar queda ligada a la linea de credito del proveedor | No (cambia tablas; ejecutar una sola vez) |
| 20 | `facturacion/CP_facturacion_paquetes.sql` | CP_POS | Estados de factura PENDIENTE y CANCELADA, parametros de plazo (30 dias), paquetes PKG_CP_CREDITO (limites de credito) y PKG_CP_CUENTA (crea y anula la cuenta segun el estado de la factura y aplica los abonos), triggers de facturas (TRG_CP_FACTURA_VENTA_CUENTA, TRG_CP_FACTURA_COMPRA_CUENTA) y de abonos (TRG_CP_ABONO_COBRAR_SALDO, TRG_CP_ABONO_PAGAR_SALDO); pruebas | Si |
| 21 | `facturacion/CP_facturacion_inventario.sql` | CP_POS | Columna `reingresa_inventario` en CP_MOTIVO_DEVOLUCION (N para danado, vencido y calidad); paquete PKG_CP_INVENTARIO (salida FEFO en ventas, entrada por cada lote de compra, reintegro y retiro al anular facturas, movimiento al procesar devoluciones) y 9 triggers (TRG_CP_VENTA_LINEA_INVENTARIO, TRG_CP_VENTA_LOTE_PROTEGIDO, TRG_CP_VENTA_INVENTARIO_ESTADO, TRG_CP_LOTE_INVENTARIO, TRG_CP_COMPRA_INVENTARIO_ESTADO, TRG_CP_DEV_VENTA_INVENTARIO, TRG_CP_DEV_COMPRA_INVENTARIO, TRG_CP_DEV_VENTA_DET_EDITABLE, TRG_CP_DEV_COMPRA_DET_EDITABLE); errores -20270 a -20283; pruebas | Si |
| 22 | `facturacion/CP_facturacion_costos.sql` | CP_POS | Paquete PKG_CP_COSTO y trigger TRG_CP_COMPRA_COSTO_LINEA: cada linea de compra con un costo distinto al actual del producto con ese proveedor actualiza `CP_PRODUCTO_PROVEEDOR.precio_costo_actual`, y el cambio queda en `CP_BITACORA_COSTO_PRODUCTO` (lo escribe TRG_CP_AUD_COSTO_PRODUCTO de la Parte 1); error -20290; pruebas | Si |
| 23 | `facturacion/CP_facturacion_pruebas_usuarios.sql` | USR_CP_* (uno por uno) | Pruebas de facturacion e inventario con usuarios reales: cada rol vende, compra o devuelve solo lo que su rol permite, con INSERT/UPDATE directos y a traves de PKG_CP_FACTURACION; el inventario y el costo cambian por los triggers y lo demas es negado; no crea objetos | Si |
| 24 | `facturacion/CP_facturacion_concurrencia_A.sql` y `facturacion/CP_facturacion_concurrencia_B.sql` | CP_POS (dos conexiones) | Prueba manual de concurrencia: la sesion A vende 1 unidad sin confirmar y deja bloqueado el inventario; la sesion B intenta vender lo mismo, espera 5 segundos y recibe -20282; despues de ROLLBACK en A, la sesion B vende sin esperar; no crea objetos | Si |
| 25 | `facturacion/CP_facturacion_transacciones.sql` | CP_POS | Paquete PKG_CP_FACTURACION (AUTHID CURRENT_USER): registrar venta y compra, anular, abonar y devolver como operaciones completas con SAVEPOINT, ROLLBACK TO SAVEPOINT y COMMIT (parametro `p_commit`), FOR UPDATE NOWAIT sobre el documento (error -20291) y errores -20291 a -20294; GRANT EXECUTE a DIGITADOR, JEFE_DEPARTAMENTO y JEFE_PROVEEDURIA; 40 pruebas | Si |
| 26 | `negocio/CP_negocio_modelo.sql` | CP_POS | Cambios de modelo de la Fase 4: cantidades en el cierre diario (seccion 1), tipo de promocion (seccion 2) e indices de fecha para las consultas de la fase (seccion 3) | Si |
| 26A | `negocio/CP_negocio_avisos.sql` | CP_POS | PKG_CP_AVISO: los avisos de cierre, inventario y premiacion pasan a la cola del modulo de notificaciones (correo de `CORREO_ALERTAS_BD`) sin detener el proceso si fallan | Si |
| 27 | `negocio/CP_negocio_cierre.sql` | CP_POS | PKG_CP_CIERRE y JOB_CP_CIERRE_DIARIO | Si |
| 28 | `negocio/CP_negocio_vencimiento.sql` | CP_POS | PKG_CP_VENCIMIENTO y JOB_CP_REPORTE_INVENTARIO_SEMANAL | Si |
| 29 | `negocio/CP_negocio_descuento.sql` | CP_POS | PKG_CP_DESCUENTO, TRG_CP_AUD_DESCUENTO_PRODUCTO y JOB_CP_REVISION_DESCUENTOS | Si |
| 30 | `negocio/CP_negocio_promocion.sql` | CP_POS | VW_CP_ACCIONES_PROMOCION, PKG_CP_PROMOCION y TRG_CP_AUD_PROMOCION_TIPO | Si |
| 31 | `negocio/CP_negocio_premiacion.sql` | CP_POS | VW_CP_VENTA_NETA_FACTURA, PKG_CP_PREMIACION y JOB_CP_PREMIACION_CLIENTES | Si |
| 32 | `negocio/CP_negocio_explain.sql` | CP_POS | EXPLAIN PLAN de 20 consultas de los requerimientos funcionales (Fase 4, padron, credito y salida FEFO de la facturacion, alertas y cada vista materializada frente a su calculo en vivo), con resumen de costos e indices; no modifica datos. Se corre al final, despues del 34 y del modulo de notificaciones | Si |
| 33 | `negocio/CP_negocio_pruebas_usuarios.sql` | USR_CP_* (uno por uno) | Pruebas de acceso por rol a los paquetes y vistas de la Fase 4 y del padron; no crea objetos | Si |
| 34 | `negocio/CP_negocio_vistas_materializadas.sql` | CP_POS | Vistas materializadas del requisito 9: MV_CP_VENTAS_MENSUALES (mes y sucursal) y MV_CP_INVENTARIO_CONSOLIDADO (sucursal y producto), con REFRESH COMPLETE ON DEMAND sobre las vistas de calculo VW_CP_VENTAS_MENSUALES y VW_CP_INVENTARIO_CONSOLIDADO; PKG_CP_REPORTE, JOB_CP_REFRESCO_VENTAS_MENSUALES (diario 00:45) y JOB_CP_REFRESCO_INVENTARIO (cada hora); errores -20370 y -20371 | Si (borra y crea las vistas materializadas; despues correr el 13) |
| 35 | `negocio/CP_negocio_bitacoras.sql` | CP_POS | Bitacora de facturacion completa: tabla `CP_BITACORA_COMPRA` (creacion y cambios de las facturas de compra, `TRG_CP_BIT_COMPRA`), `TRG_CP_BIT_VENTA_CREACION` (la creacion de cada venta en `CP_BITACORA_VENTA`) y `TRG_CP_FACTURA_VENTA_SIN_BORRADO` / `TRG_CP_FACTURA_COMPRA_SIN_BORRADO` (las facturas no se borran, se anulan; -20240); 10 pruebas | Si (la tabla solo se crea si falta; despues correr el 13) |
| 36 | `Seguridad/CP_seguridad_auditoria.sql` | SYS | Auditoria unificada de operaciones criticas: politicas `POL_CP_DATOS_CRITICOS` (DML sobre facturas, cuentas, abonos, creditos, precios, costos, inventario, parametros, llaves, correo y cambios o borrados en las bitacoras; lectura de `CP_LLAVE_CIFRADO`), `POL_CP_SEGURIDAD` (usuarios, roles, perfiles, GRANT/REVOKE y SET ROLE) y `POL_CP_ACCESO_FALLIDO` (inicios de sesion fallidos); 4 pruebas y consultas para la defensa | Si (borra y crea las politicas) |

Dependencias: el 12 va antes del 15 (el paquete de claves de rol necesita SELECT sobre SYS.DBA_ROLE_PRIVS y ADMIN OPTION sobre los roles); el 14 va antes del 15 (usa CP_PARAMETRO y CP_LLAVE_CIFRADO); el 17 necesita haber corrido el 15 y el 16.
El 18 va despues de CP_datos_prueba.sql: una vez aplicado, CP_CUENTA_COBRAR y CP_CUENTA_PAGAR exigen monto_total y saldo_pendiente, por lo que los INSERT de cuentas de CP_datos_prueba.sql ya no sirven y no deben volver a ejecutarse sobre esa base. El 19 va despues del 18 (agrega una columna a CP_CUENTA_PAGAR) y el 20 despues del 19 y del 15 (usa PKG_CP_ERROR y CP_PARAMETRO). Una vez instalado el 20, cada factura de venta o compra que se inserte o cambie a PENDIENTE valida el credito y crea su cuenta; por eso CP_datos_prueba.sql no debe volver a ejecutarse sobre esa base.

El 21 va despues del 20 y del 15 (usa PKG_CP_ERROR y PKG_CP_CONTEXTO). Una vez instalado, cada linea de venta descuenta el inventario del almacen activo de la sucursal por FEFO y cada lote de compra lo aumenta, por lo que CP_datos_prueba.sql no debe volver a ejecutarse sobre esa base. Las 5 ventas de prueba originales (VENT-001 a VENT-005) tienen lotes asignados pero nunca descontaron inventario; no conviene anularlas ni devolverlas.

El 22 va despues del 21 y del 15 (usa PKG_CP_ERROR y PKG_CP_CONTEXTO). Una vez instalado, cada linea de compra nueva compara su costo con el costo actual del producto con ese proveedor: si es distinto lo actualiza y queda en el historial con el usuario de la factura. Gana el ultimo costo registrado, aunque la factura tenga una fecha de emision anterior; una factura anulada no cambia el costo y anular una factura tampoco lo revierte.

El 23 necesita haber corrido el 16, el 21, el 22 y el 25. Se ejecuta una vez por usuario (USR_CP_GERENTE, USR_CP_JEFE_DEPTO, USR_CP_JEFE_PROVEEDURIA y USR_CP_DIGITADOR), cada uno en su conexion. Todo lo que crea se deshace con ROLLBACK; solo quedan en CP_BITACORA_ERROR las filas de los errores provocados a proposito (-20273 y -20275), que el propietario puede borrar.

El 25 va despues del 22. La logica de los triggers (descontar inventario, crear cuentas, registrar costos) no puede llevar COMMIT, ROLLBACK ni SAVEPOINT (ORA-04092), por eso el control de la transaccion esta en este paquete: cada operacion abre un SAVEPOINT, y si falla deshace solo lo suyo con ROLLBACK TO SAVEPOINT sin tocar lo que la sesion tuviera pendiente. Con `p_commit => TRUE` (valor por defecto) confirma al terminar; con FALSE deja la transaccion abierta para agrupar varias operaciones. El bloqueo FOR UPDATE NOWAIT se usa sobre el documento (dos personas no operan la misma factura a la vez); el inventario conserva FOR UPDATE WAIT 5, porque ahi si conviene esperar un instante. Las pruebas de CP_POS confirman de verdad una sola venta (para probar el COMMIT) y la compensan con anular_venta: quedan dos facturas ANULADAS (T25-C-... para el COMMIT y T25-N-... para la prueba de NOWAIT, que necesita una factura confirmada) y el inventario igual. Volver a correr el 13 vuelve a otorgar el EXECUTE de este paquete.

Los scripts 26 al 31 (con el 26A entre el 26 y el 27) van despues del 25 (usan PKG_CP_FACTURACION en sus pruebas) y del 15 con el rango de errores -20200 a -20399. El detalle esta en `negocio/ORDEN_EJECUCION.md`. Al terminar el 31 se vuelve a correr el 13 como SYS.

## Modulo de notificaciones (correo)

Lo crean los scripts de la carpeta `Notificaciones/` y el job de envio de `jobs/diarios/`. Sin este modulo los avisos de los scripts 26A al 31 no se pierden ni detienen nada: quedan registrados en `CP_BITACORA_ERROR` como no enviados. Orden de instalacion:

| Paso | Script o accion | Ejecutar como | Que hace |
|---|---|---|---|
| 1 | `CP_usuario_esquema.sql`, secciones 15 y 16, y los cuatro GRANT finales de la seccion 10 | SYS | `SELECT` sobre `DBA_DATA_FILES`, `DBA_FREE_SPACE`, `V_$PARAMETER` y `V_$PROCESS` (los usa `PKG_CP_MONITOREO`), `EXECUTE` sobre `DBMS_LOCK` (lo usa `procesar_pendientes` para que dos corridas no envien la misma cola) y ACL de red: `connect` a `smtp.gmail.com:587` y `resolve` del nombre, solo para CP_POS. En una base que ya existe se ejecutan solo esas dos secciones (la seccion 1 crea el usuario) |
| 2 | Wallet de Gmail en `/opt/oracle/wallets/smtp` dentro del contenedor | Sistema operativo del contenedor | Certificados para la conexion TLS (ver `Notificaciones/README.md`, seccion 5) |
| 3 | `Notificaciones/CP_notificaciones_configuracion.sql` | CP_POS (F5) | Pide el correo de avisos, el correo remitente y la contrasena de aplicacion de Gmail; carga `CORREO_ALERTAS_BD`, deja una sola configuracion SMTP activa con la clave cifrada por `PKG_CP_CRIPTO` y registra el destinatario. Va despues del 15. Re-ejecutable (sirve para cambiar correo o clave) |
| 4 | `Notificaciones/packages/PKG_CP_NOTIFICACIONES.sql` y `..._BODY.sql` | CP_POS | Envio por UTL_SMTP con STARTTLS, cola de notificaciones (`encolar`) y procesamiento de pendientes |
| 5 | `jobs/diarios/JOB_CP_PROCESAR_NOTIFICACIONES.sql` | CP_POS | Job que envia la cola de notificaciones cada 15 minutos (`PKG_CP_NOTIFICACIONES.procesar_pendientes`) |
| 6 | `Notificaciones/CP_notificaciones_paquetes.sql` | CP_POS | Va despues del 26A. Paquetes `PKG_CP_ALERTA` (clientes con el 85 % de su credito, proveedores con el 85 % al coordinador y el 70 % al gerente en un solo correo, clientes en mora al gerente y coordinador y a cada cliente, productos vencidos con su total) y `PKG_CP_MONITOREO` (tablespaces, objetos invalidos, indices, sesiones y bloqueos, errores de la bitacora y crecimiento en la tabla nueva `CP_MONITOREO_TABLESPACE`); vistas `VW_CP_CLIENTE_CORREO`, `VW_CP_CREDITO_CLIENTE_USO`, `VW_CP_CREDITO_PROVEEDOR_USO`, `VW_CP_CLIENTE_MORA`, `VW_CP_USO_TABLESPACE` y `VW_CP_CRECIMIENTO_TABLESPACE`; parametros `SESIONES_UMBRAL_PCT` y `SESION_BLOQUEO_SEGUNDOS`; errores -20380, -20381 y -20390; 34 pruebas; jobs `JOB_CP_ALERTAS_NEGOCIO` (07:00), `JOB_CP_MONITOREO_DIARIO` (06:30) y `JOB_CP_MONITOREO_SESIONES` (cada 15 minutos). Retira los nueve procedimientos sueltos y sus jobs. Re-ejecutable; despues correr el 13 |

Los archivos de `Notificaciones/procedures/` y los demas de `jobs/diarios/` quedan solo como antecedente: sus nueve procedimientos sueltos pasaron a `PKG_CP_ALERTA` y `PKG_CP_MONITOREO` (requisitos 1 y 13) y ya no se ejecutan. Si estan instalados, el paso 6 los retira junto con sus jobs.

## Modulo del padron nacional

Lo crea `Padron/CP_padron_nacional.sql`; el detalle de instalacion, uso y decisiones esta en `Padron/README.md`. Va despues del 15 (usa PKG_CP_ERROR y PKG_CP_PARAMETRO) y se puede instalar antes o despues de los scripts 18 al 31.

| Paso | Script o accion | Ejecutar como | Que hace |
|---|---|---|---|
| 1 | Copiar `PADRON_COMPLETO.txt` a `/tmp/padron` en el contenedor y dar la carpeta al usuario `oracle` | Sistema operativo del contenedor | Deja el archivo del TSE donde Oracle lo puede leer y donde puede escribir el registro de la carga (README, seccion 6) |
| 2 | `CREATE OR REPLACE DIRECTORY DIR_PADRON AS '/tmp/padron'` y `GRANT READ, WRITE ON DIRECTORY DIR_PADRON TO CP_POS` | SYS | Directorio de Oracle del padron (README, seccion 7) |
| 3 | `Padron/CP_padron_nacional.sql` | CP_POS | Columna `CP_PERSONA.id_padron` (FK opcional al padron), parametros `PADRON_ARCHIVO` y `PADRON_CHARSET`, tabla externa `CP_PADRON_EXTERNO`, paquete PKG_CP_PADRON (carga con un solo MERGE, enlace y datos basicos), trigger TRG_CP_PERSONA_PADRON, vista VW_CP_CLIENTE_PADRON, 18 pruebas y job mensual JOB_CP_CARGA_PADRON; errores -20360 a -20364. Re-ejecutable |
| 4 | `Seguridad/CP_seguridad_privilegios.sql` (13) | SYS | Lectura de VW_CP_CLIENTE_PADRON para DIGITADOR, JEFE_DEPARTAMENTO y GERENTE; CP_PADRON_EXTERNO queda como tabla de sistema |
| 5 | `EXEC PKG_CP_PADRON.load_file;` | CP_POS | Carga real del padron (tarda unos minutos) |

## Nota sobre el modelo

Los scripts 11 a 25 no cambian la estructura de las tablas de la Parte 1 mas alla de lo que sigue, pero **el diagrama relacional (`modelo/Diagrama_Proyecto_db.pdf`, Lucid) y el diccionario de datos (`documentacion/Diccionario_Datos_CP_POS.pdf`) todavia no reflejan estos cambios y hay que actualizarlos antes de la entrega**, porque el enunciado vuelve a calificar el modelo relacional:

- `CP_CUENTA_COBRAR` y `CP_CUENTA_PAGAR`: columnas `monto_total` y `saldo_pendiente`.
- `CP_CUENTA_PAGAR`: columna `id_credito_proveedor`.
- `CP_MOTIVO_DEVOLUCION`: columna `reingresa_inventario` (S o N, con su restriccion).
- Estados renombrados: en `CP_ESTADO_FACTURA_VENTA`, CREDITO pasa a PENDIENTE y PAGADA a CANCELADA; en `CP_ESTADO_FACTURA_COMPRA`, PAGADA pasa a CANCELADA (PENDIENTE ya existía).
- Triggers de la Parte 1 eliminados por el script 18: `TRG_CP_ABONO_COBRAR_LIMITE` y `TRG_CP_ABONO_PAGAR_LIMITE`, reemplazados por `TRG_CP_ABONO_COBRAR_SALDO` y `TRG_CP_ABONO_PAGAR_SALDO`.
- Objetos nuevos que van en el diccionario: paquetes PKG_CP_CREDITO, PKG_CP_CUENTA, PKG_CP_INVENTARIO, PKG_CP_COSTO y PKG_CP_FACTURACION y sus triggers.
- Fase 4 (scripts 26 al 31): columnas de cantidades en `CP_CIERRE_DIARIO` y `CP_DETALLE_CIERRE_DIARIO`; `CP_PROMOCION.id_tipo_promocion` con FK a `CP_TIPO_PROMOCION`; vistas `VW_CP_ACCIONES_PROMOCION` y `VW_CP_VENTA_NETA_FACTURA`; paquetes PKG_CP_AVISO, PKG_CP_CIERRE, PKG_CP_VENCIMIENTO, PKG_CP_DESCUENTO, PKG_CP_PROMOCION y PKG_CP_PREMIACION, triggers TRG_CP_AUD_DESCUENTO_PRODUCTO y TRG_CP_AUD_PROMOCION_TIPO, y cuatro jobs; cinco indices de fecha (`IX_CP_LOTE_PROD_VENCE`, `IX_CP_LOTE_PROD_INGRESO`, `IX_CP_FACT_VENTA_SUC_FECHA`, `IX_CP_FACT_VENTA_FECHA`, `IX_CP_DEV_VENTA_FECHA`).
- Padron nacional: columna `CP_PERSONA.id_padron` con `FK_CP_PERSONA_PADRON` hacia `CP_PADRON_NACIONAL` (relacion opcional, ON DELETE SET NULL) e indice `IX_CP_PERSONA_PADRON`; tabla externa `CP_PADRON_EXTERNO`; vista `VW_CP_CLIENTE_PADRON`; paquete PKG_CP_PADRON, trigger TRG_CP_PERSONA_PADRON y job JOB_CP_CARGA_PADRON.

Volver a correr el 13 después del 14 y del 15 es opcional: las tablas de sistema (CP_PARAMETRO, CP_LLAVE_CIFRADO) no se conceden a ningún rol, así que el resultado no cambia.

Si la instalación limpia falla en `CP_tablespaces.sql` (Parte 1) por la ruta de los archivos de datos, ajustar la ruta al entorno donde corre Oracle; los scripts 11 al 25 solo usan los nombres de los tablespaces, no las rutas.

Las claves de USR_CP_* se escriben al ejecutar el 16 y no se guardan en ningún script. Las claves de prueba usadas durante el desarrollo se cambian antes de la entrega final.
