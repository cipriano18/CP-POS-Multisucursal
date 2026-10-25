# Scripts de facturación e inventario (18 a 25)

Esta carpeta contiene los scripts de facturación, inventario, costos y transacciones del Entregable #2. Hacen que la facturación del CP-POS sea automática: las cuentas por cobrar y por pagar, el inventario y el historial de costo se actualizan solos, y una API transaccional agrupa cada operación para que se confirme o se deshaga completa.

Los scripts de seguridad (11 a 17) están en `../Seguridad/` y el orden completo de todos los scripts de la Parte 2 (11 a 25) está en `../Parte2_Nuevos/ORDEN_EJECUCION.md`. Los scripts 01 a 10 de la Parte 1 no se modifican.

## Requisitos previos

1. La base completa de la Parte 1 instalada (tablespaces, usuario, secuencias, tablas, constraints, índices, triggers, comentarios, datos de prueba y vistas).
2. Los scripts de seguridad ya ejecutados:
   - 12 (roles) y 13 (privilegios), como SYS.
   - 14 y 15 (tablas de parámetros y cifrado, `PKG_CP_ERROR`), como CP_POS. `PKG_CP_CONTEXTO` ya viene de la Parte 1.
   - 16 (usuarios `USR_CP_*`), como SYS. Lo necesita el script 23.

## Orden de ejecución

El orden es el de la primera columna. **Un solo caso rompe el orden numérico: el 25 se ejecuta antes que el 23**, porque las pruebas del 23 llaman a la API del 25.

| Paso | Script | Usuario | Qué crea o cambia | Re-ejecutable |
|---|---|---|---|---|
| 1 | `CP_facturacion_cuentas.sql` (18) | CP_POS | Columnas `monto_total` y `saldo_pendiente` en `CP_CUENTA_COBRAR` y `CP_CUENTA_PAGAR`, con restricciones y comentarios. Elimina los triggers de la Parte 1 `TRG_CP_ABONO_COBRAR_LIMITE` y `TRG_CP_ABONO_PAGAR_LIMITE`. | No (cambia tablas; una sola vez) |
| 2 | `CP_facturacion_credito_pagar.sql` (19) | CP_POS | Columna `id_credito_proveedor` en `CP_CUENTA_PAGAR` (llave foránea, índice y comentario). | No (cambia tablas; una sola vez) |
| 3 | `CP_facturacion_paquetes.sql` (20) | CP_POS | Estados de factura renombrados, parámetros de plazo de crédito (30 días), paquetes `PKG_CP_CREDITO` y `PKG_CP_CUENTA`, triggers `TRG_CP_FACTURA_VENTA_CUENTA`, `TRG_CP_FACTURA_COMPRA_CUENTA`, `TRG_CP_ABONO_COBRAR_SALDO` y `TRG_CP_ABONO_PAGAR_SALDO`; pruebas. Errores -20250 a -20256 y -20260 a -20265. | Sí |
| 4 | `CP_facturacion_inventario.sql` (21) | CP_POS | Columna `reingresa_inventario` en `CP_MOTIVO_DEVOLUCION`, paquete `PKG_CP_INVENTARIO` y 9 triggers (`TRG_CP_VENTA_LINEA_INVENTARIO`, `TRG_CP_VENTA_LOTE_PROTEGIDO`, `TRG_CP_VENTA_INVENTARIO_ESTADO`, `TRG_CP_LOTE_INVENTARIO`, `TRG_CP_COMPRA_INVENTARIO_ESTADO`, `TRG_CP_DEV_VENTA_INVENTARIO`, `TRG_CP_DEV_COMPRA_INVENTARIO`, `TRG_CP_DEV_VENTA_DET_EDITABLE`, `TRG_CP_DEV_COMPRA_DET_EDITABLE`); pruebas. Errores -20270 a -20283. | Sí |
| 5 | `CP_facturacion_costos.sql` (22) | CP_POS | Paquete `PKG_CP_COSTO` y trigger `TRG_CP_COMPRA_COSTO_LINEA`: actualiza `CP_PRODUCTO_PROVEEDOR.precio_costo_actual` y el cambio queda en `CP_BITACORA_COSTO_PRODUCTO`; pruebas. Error -20290. | Sí |
| 6 | `CP_facturacion_transacciones.sql` (25) | CP_POS | Paquete `PKG_CP_FACTURACION` (`AUTHID CURRENT_USER`): registrar venta y compra, anular, abonar y devolver, con `SAVEPOINT`, `ROLLBACK TO SAVEPOINT` y `COMMIT` (parámetro `p_commit`) y `FOR UPDATE NOWAIT` sobre el documento. `GRANT EXECUTE` a DIGITADOR, JEFE_DEPARTAMENTO y JEFE_PROVEEDURIA; 40 pruebas. Errores -20291 a -20294. | Sí |
| 7 | `CP_facturacion_pruebas_usuarios.sql` (23) | `USR_CP_*` (uno por uno) | Pruebas de facturación e inventario con usuarios reales, con `INSERT` y `UPDATE` directos y por la API. No crea objetos; todo se deshace con `ROLLBACK`. | Sí |
| 8 | `CP_facturacion_concurrencia_A.sql` y `CP_facturacion_concurrencia_B.sql` (24) | CP_POS (dos conexiones) | Prueba manual de concurrencia. No crea objetos. | Sí |

## Dependencias

- El 18 va después de `CP_datos_prueba.sql`. Una vez aplicado, las cuentas exigen `monto_total` y `saldo_pendiente`, por lo que los `INSERT` de cuentas de `CP_datos_prueba.sql` ya no sirven y **no debe volver a ejecutarse** sobre esa base.
- El 19 va después del 18 (agrega una columna a `CP_CUENTA_PAGAR`).
- El 20 va después del 19 y del 15 (usa `PKG_CP_ERROR` y `CP_PARAMETRO`). Una vez instalado, cada factura que se inserte o cambie a `PENDIENTE` valida el crédito y crea su cuenta.
- El 21 va después del 20 y del 15 (usa `PKG_CP_ERROR` y `PKG_CP_CONTEXTO`). Una vez instalado, cada línea de venta descuenta el inventario del almacén activo de la sucursal por FEFO y cada lote de compra lo aumenta.
- El 22 va después del 21 y del 15.
- El 25 va después del 22. Su sección de permisos otorga sola el `EXECUTE` del paquete; volver a correr el 13 como SYS también lo otorga, pero no es necesario.
- El 23 necesita haber corrido el 16, el 21, el 22 y el 25. Se ejecuta una vez por usuario (`USR_CP_GERENTE`, `USR_CP_JEFE_DEPTO`, `USR_CP_JEFE_PROVEEDURIA` y `USR_CP_DIGITADOR`), cada uno en su conexión de XEPDB1.
- El 24 necesita el 21. La sesión A vende 1 unidad sin confirmar y deja bloqueado el inventario; la sesión B intenta vender lo mismo, espera 5 segundos y recibe -20282; tras un `ROLLBACK` en A, B vende sin esperar.

## Resultados esperados

| Script | Resultado |
|---|---|
| 20 | 25 pruebas de cobrar y 17 de pagar en `OK` |
| 21 | 30 pruebas en `OK` |
| 22 | 13 pruebas en `OK` |
| 25 | `Pruebas OK: 40 \| FALLA: 0` |
| 23 | Una línea por prueba para cada usuario: `OK`, `OK (-codigo)` cuando lo correcto es que el rol sea negado, o `no aplica a este rol`. Ninguna `FALLA`. |
| 24 | La sesión B recibe -20282 tras esperar 5 segundos |

## Qué cambia de la Parte 1

Ningún archivo de la Parte 1 se modifica, pero la base cambia así:

- **Estructura:** `CP_CUENTA_COBRAR` y `CP_CUENTA_PAGAR` (columnas `monto_total` y `saldo_pendiente`), `CP_CUENTA_PAGAR` (columna `id_credito_proveedor`) y `CP_MOTIVO_DEVOLUCION` (columna `reingresa_inventario`, en `N` para dañado, vencido y calidad).
- **Estados de factura:** en `CP_ESTADO_FACTURA_VENTA`, `CREDITO` pasa a `PENDIENTE` y `PAGADA` a `CANCELADA` (`EMITIDA` queda para la venta de contado). En `CP_ESTADO_FACTURA_COMPRA`, `PAGADA` pasa a `CANCELADA`; `PENDIENTE` ya existía.
- **Parámetros:** `PLAZO_CREDITO_CLIENTE_DIAS` y `PLAZO_CREDITO_PROVEEDOR_DIAS` (30 días) en `CP_PARAMETRO`.
- **Triggers eliminados:** `TRG_CP_ABONO_COBRAR_LIMITE` y `TRG_CP_ABONO_PAGAR_LIMITE` (definidos en `CP_triggers_reglas.sql`); los reemplazan `TRG_CP_ABONO_COBRAR_SALDO` y `TRG_CP_ABONO_PAGAR_SALDO`.
- **Tablas que ganan triggers:** `CP_FACTURA_VENTA`, `CP_FACTURA_COMPRA`, `CP_ABONO_CUENTA_COBRAR`, `CP_ABONO_CUENTA_PAGAR`, `CP_DETALLE_VENTA_PRODUCTO`, `CP_DETALLE_VENTA_LOTE`, `CP_LOTE_PRODUCTO`, `CP_DEVOLUCION_VENTA`, `CP_DEVOLUCION_COMPRA`, `CP_DETALLE_DEVOLUCION_VENTA`, `CP_DETALLE_DEVOLUCION_COMPRA` y `CP_DETALLE_COMPRA`.
- **Tablas que escribe la lógica automática:** cuentas por cobrar y por pagar (`PKG_CP_CUENTA`), `CP_INVENTARIO_ALMACEN` (`PKG_CP_INVENTARIO`) y `CP_PRODUCTO_PROVEEDOR` (`PKG_CP_COSTO`).

## Notas

- Los paquetes internos (`PKG_CP_CREDITO`, `PKG_CP_CUENTA`, `PKG_CP_INVENTARIO` y `PKG_CP_COSTO`) usan `ACCESSIBLE BY`: solo el trigger o paquete indicado puede llamarlos. La única puerta pública es `PKG_CP_FACTURACION`.
- Los triggers no pueden llevar `COMMIT`, `ROLLBACK` ni `SAVEPOINT` (ORA-04092), por eso el control de la transacción está en `PKG_CP_FACTURACION`. Un `INSERT` directo dispara los mismos triggers, pero sin ese control.
- Las 5 ventas de prueba originales (VENT-001 a VENT-005) tienen lotes asignados pero nunca descontaron inventario; no conviene anularlas ni devolverlas.
- El script 25 deja una factura de venta `ANULADA` con número `T25-C-...` (la que prueba el `COMMIT`) y, si la base no tiene una factura `EMITIDA` ajena a las pruebas, otra `T25-N-...` (la que prueba `NOWAIT`). El inventario queda igual.
- El script 23 deja en `CP_BITACORA_ERROR` las filas de los errores provocados a propósito (-20273 y -20275); el propietario puede borrarlas.
- El costo de un producto con un proveedor lo fija el último costo registrado, aunque la factura tenga una fecha de emisión anterior. Anular una factura no revierte el costo.
- Los códigos de error de esta carpeta (-20250 a -20294) están dentro del bloque -20200 a -20299 reservado para la Parte 2.

## Pendiente

El diagrama relacional (`modelo/Diagrama_Proyecto_db.pdf`, Lucid) y el diccionario de datos (`documentacion/Diccionario_Datos_CP_POS.pdf`) todavía no reflejan estos cambios y hay que actualizarlos antes de la entrega, porque el enunciado vuelve a calificar el modelo relacional.
