-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- BASE DE DATOS: Oracle 21c
-- SCRIPT: 06_indices.sql
-- DESCRIPCION: Creacion de indices adicionales del sistema
-- USUARIO: CP_POS
-- ============================================================


-- ============================================================
-- 1. CP_TIPO_NEGOCIO
-- ============================================================
-- No requiere indices adicionales.


-- ============================================================
-- 2. CP_ESTADO
-- ============================================================
-- No requiere indices adicionales.


-- ============================================================
-- 3. CP_TIPO_OPERACION
-- ============================================================
-- No requiere indices adicionales.


-- ============================================================
-- 4. CP_PROVINCIA
-- ============================================================
-- No requiere indices adicionales.


-- ============================================================
-- 5. CP_CANTON
-- ============================================================

CREATE INDEX IX_CP_CANTON_PROVINCIA
ON CP_CANTON (id_provincia)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 6. CP_DISTRITO
-- ============================================================

CREATE INDEX IX_CP_DISTRITO_CANTON
ON CP_DISTRITO (id_canton)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 7. CP_DIRECCION
-- ============================================================

CREATE INDEX IX_CP_DIRECCION_DISTRITO
ON CP_DIRECCION (id_distrito)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 8. CP_TIPO_DIRECCION
-- ============================================================
-- No requiere indices adicionales.


-- ============================================================
-- 9. CP_SUCURSAL
-- ============================================================

CREATE INDEX IX_CP_SUCURSAL_NEGOCIO
ON CP_SUCURSAL (id_negocio)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_SUCURSAL_DIRECCION
ON CP_SUCURSAL (id_direccion)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_SUCURSAL_ESTADO
ON CP_SUCURSAL (id_estado)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 10. CP_NACIONALIDAD
-- ============================================================
-- No requiere indices adicionales.


-- ============================================================
-- 11. CP_SEXO
-- ============================================================
-- No requiere indices adicionales.


-- ============================================================
-- 12. CP_ESTADO_CIVIL
-- ============================================================
-- No requiere indices adicionales.


-- ============================================================
-- 13. CP_ESCOLARIDAD
-- ============================================================
-- No requiere indices adicionales.


-- ============================================================
-- 14. CP_TIPO_RESIDENCIA
-- ============================================================
-- No requiere indices adicionales.


-- ============================================================
-- 15. CP_PERSONA
-- ============================================================

CREATE INDEX IX_CP_PERSONA_NACIONALIDAD
ON CP_PERSONA (id_nacionalidad)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_PERSONA_SEXO
ON CP_PERSONA (id_sexo)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_PERSONA_ESTADO_CIVIL
ON CP_PERSONA (id_estado_civil)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_PERSONA_ESCOLARIDAD
ON CP_PERSONA (id_escolaridad)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_PERSONA_TIPO_RESIDENCIA
ON CP_PERSONA (id_tipo_residencia)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 16. CP_TIPO_DE_CONTACTO
-- ============================================================
-- No requiere indices adicionales.


-- ============================================================
-- 17. CP_CONTACTO
-- ============================================================

CREATE INDEX IX_CP_CONTACTO_TIPO
ON CP_CONTACTO (id_tipo_contacto)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 18. CP_PERSONA_DIRECCION
-- ============================================================

CREATE INDEX IX_CP_PERSONA_DIR_PERSONA
ON CP_PERSONA_DIRECCION (id_persona)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_PERSONA_DIR_DIRECCION
ON CP_PERSONA_DIRECCION (id_direccion)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_PERSONA_DIR_TIPO
ON CP_PERSONA_DIRECCION (id_tipo_direccion)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 19. CP_PERSONA_CONTACTO
-- ============================================================

CREATE INDEX IX_CP_PERSONA_CONT_PERSONA
ON CP_PERSONA_CONTACTO (id_persona)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_PERSONA_CONT_CONTACTO
ON CP_PERSONA_CONTACTO (id_contacto)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 20. CP_PUESTO
-- ============================================================
-- No requiere indices adicionales.


-- ============================================================
-- 21. CP_EMPRESA_LABORAL
-- ============================================================
-- No requiere indices adicionales.


-- ============================================================
-- 22. CP_PERSONA_EMPLEO
-- ============================================================

CREATE INDEX IX_CP_PERSONA_EMPLEO_PERSONA
ON CP_PERSONA_EMPLEO (id_persona)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_PERSONA_EMPLEO_PUESTO
ON CP_PERSONA_EMPLEO (id_puesto)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_PERSONA_EMPLEO_EMPRESA
ON CP_PERSONA_EMPLEO (id_empresa_laboral)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 23. CP_ROL
-- ============================================================
-- No requiere indices adicionales.


-- ============================================================
-- 24. CP_PERMISO
-- ============================================================
-- No requiere indices adicionales.


-- ============================================================
-- 25. CP_ROL_PERMISO
-- ============================================================

CREATE INDEX IX_CP_ROL_PERMISO_ROL
ON CP_ROL_PERMISO (id_rol)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_ROL_PERMISO_PERMISO
ON CP_ROL_PERMISO (id_permiso)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 26. CP_USUARIO
-- ============================================================

CREATE INDEX IX_CP_USUARIO_PERSONA
ON CP_USUARIO (id_persona)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_USUARIO_ESTADO
ON CP_USUARIO (id_estado)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_USUARIO_SUCURSAL
ON CP_USUARIO (id_sucursal)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_USUARIO_ROL
ON CP_USUARIO (id_rol)
TABLESPACE CP_POS_INDICES;

-- ============================================================
-- 27. CP_TIPO_CLIENTE
-- ============================================================
-- No requiere indices adicionales.


-- ============================================================
-- 28. CP_ESTADO_CLIENTE
-- ============================================================
-- No requiere indices adicionales.


-- ============================================================
-- 29. CP_CLIENTE
-- ============================================================

CREATE INDEX IX_CP_CLIENTE_TIPO
ON CP_CLIENTE (id_tipo_cliente)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_CLIENTE_ESTADO
ON CP_CLIENTE (id_estado_cliente)
TABLESPACE CP_POS_INDICES;

-- ============================================================
-- 30. CP_CLIENTE_PERSONA
-- ============================================================

-- id_cliente ya posee un indice generado por la restriccion
-- UNIQUE, por lo que no se crea otro indice sobre esa columna.

CREATE INDEX IX_CP_CLI_PERSONA_PERSONA
ON CP_CLIENTE_PERSONA (id_persona)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 31. CP_CLIENTE_EMPRESA
-- ============================================================

-- id_cliente ya posee un indice generado por la restriccion
-- UNIQUE, por lo que no requiere indices adicionales.


-- ============================================================
-- 32. CP_CLIENTE_EMPRESA_DIRECCION
-- ============================================================

CREATE INDEX IX_CP_CLI_EMP_DIR_EMPRESA
ON CP_CLIENTE_EMPRESA_DIRECCION (id_cliente_empresa)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_CLI_EMP_DIR_DIRECCION
ON CP_CLIENTE_EMPRESA_DIRECCION (id_direccion)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_CLI_EMP_DIR_TIPO
ON CP_CLIENTE_EMPRESA_DIRECCION (id_tipo_direccion)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 33. CP_CLIENTE_EMPRESA_CONTACTO
-- ============================================================

CREATE INDEX IX_CP_CLI_EMP_CONT_EMPRESA
ON CP_CLIENTE_EMPRESA_CONTACTO (id_cliente_empresa)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_CLI_EMP_CONT_CONTACTO
ON CP_CLIENTE_EMPRESA_CONTACTO (id_contacto)
TABLESPACE CP_POS_INDICES;
-- ============================================================
-- 34. CP_PROVEEDOR
-- ============================================================

CREATE INDEX IX_CP_PROVEEDOR_ESTADO
ON CP_PROVEEDOR (id_estado)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 35. CP_PROVEEDOR_DIRECCION
-- ============================================================

CREATE INDEX IX_CP_PROV_DIR_PROVEEDOR
ON CP_PROVEEDOR_DIRECCION (id_proveedor)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_PROV_DIR_TIPO
ON CP_PROVEEDOR_DIRECCION (id_tipo_direccion)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_PROV_DIR_DIRECCION
ON CP_PROVEEDOR_DIRECCION (id_direccion)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 36. CP_NEGOCIO
-- ============================================================

CREATE INDEX IX_CP_NEGOCIO_TIPO
ON CP_NEGOCIO (id_tipo_negocio)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_NEGOCIO_ESTADO
ON CP_NEGOCIO (id_estado)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 37. CP_PROVEEDOR_CONTACTO
-- ============================================================

CREATE INDEX IX_CP_PROV_CONT_PROVEEDOR
ON CP_PROVEEDOR_CONTACTO (id_proveedor)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_PROV_CONT_CONTACTO
ON CP_PROVEEDOR_CONTACTO (id_contacto)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 38. CP_CREDITO_PROVEEDOR
-- ============================================================

CREATE INDEX IX_CP_CRED_PROV_PROVEEDOR
ON CP_CREDITO_PROVEEDOR (id_proveedor)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_CRED_PROV_NEGOCIO
ON CP_CREDITO_PROVEEDOR (id_negocio)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_CRED_PROV_ESTADO
ON CP_CREDITO_PROVEEDOR (id_estado_credito)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 39. CP_FAMILIA_PRODUCTO
-- ============================================================
-- No requiere indices adicionales.


-- ============================================================
-- 40. CP_IMPUESTO
-- ============================================================

CREATE INDEX IX_CP_IMPUESTO_ESTADO
ON CP_IMPUESTO (id_estado)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 41. CP_PRODUCTO
-- ============================================================

CREATE INDEX IX_CP_PRODUCTO_FAMILIA
ON CP_PRODUCTO (id_familia_producto)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_PRODUCTO_IMPUESTO
ON CP_PRODUCTO (id_impuesto)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_PRODUCTO_ESTADO
ON CP_PRODUCTO (id_estado)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 42. CP_CODIGO_BARRA
-- ============================================================

CREATE INDEX IX_CP_COD_BARRA_PRODUCTO
ON CP_CODIGO_BARRA (id_producto)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 43. CP_PRODUCTO_PROVEEDOR
-- ============================================================

CREATE INDEX IX_CP_PROD_PROV_PROVEEDOR
ON CP_PRODUCTO_PROVEEDOR (id_proveedor)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_PROD_PROV_PRODUCTO
ON CP_PRODUCTO_PROVEEDOR (id_producto)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 44. CP_PRODUCTO_NEGOCIO
-- ============================================================

CREATE INDEX IX_CP_PROD_NEG_PRODUCTO
ON CP_PRODUCTO_NEGOCIO (id_producto)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_PROD_NEG_NEGOCIO
ON CP_PRODUCTO_NEGOCIO (id_negocio)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 45. CP_LOTE_PRODUCTO
-- ============================================================

CREATE INDEX IX_CP_LOTE_DET_COMPRA
ON CP_LOTE_PRODUCTO (id_detalle_compra)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 46. CP_TIPO_ALMACEN
-- ============================================================
-- No requiere indices adicionales.


-- ============================================================
-- 47. CP_ALMACEN
-- ============================================================

CREATE INDEX IX_CP_ALMACEN_TIPO
ON CP_ALMACEN (id_tipo_almacen)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_ALMACEN_SUCURSAL
ON CP_ALMACEN (id_sucursal)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_ALMACEN_ESTADO
ON CP_ALMACEN (id_estado)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_ALMACEN_DIRECCION
ON CP_ALMACEN (id_direccion)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 48. CP_INVENTARIO_ALMACEN
-- ============================================================

CREATE INDEX IX_CP_INV_ALMACEN_ALMACEN
ON CP_INVENTARIO_ALMACEN (id_almacen)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_INV_ALMACEN_LOTE
ON CP_INVENTARIO_ALMACEN (id_lote_producto)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 49. CP_ESTADO_TRASLADO
-- ============================================================
-- No requiere indices adicionales.


-- ============================================================
-- 50. CP_TRASLADO
-- ============================================================

CREATE INDEX IX_CP_TRASLADO_ORIGEN
ON CP_TRASLADO (id_almacen_origen)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_TRASLADO_DESTINO
ON CP_TRASLADO (id_almacen_destino)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_TRASLADO_USU_SOL
ON CP_TRASLADO (id_usuario_solicita)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_TRASLADO_USU_REC
ON CP_TRASLADO (id_usuario_recibe)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_TRASLADO_ESTADO
ON CP_TRASLADO (id_estado_traslado)
TABLESPACE CP_POS_INDICES;

-- ============================================================
-- 51. CP_DETALLE_TRASLADO
-- ============================================================

CREATE INDEX IX_CP_DET_TRAS_TRASLADO
ON CP_DETALLE_TRASLADO (id_traslado)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_DET_TRAS_LOTE
ON CP_DETALLE_TRASLADO (id_lote_producto)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 52. CP_FACTURA_COMPRA
-- ============================================================

CREATE INDEX IX_CP_FACT_COMP_PROVEEDOR
ON CP_FACTURA_COMPRA (id_proveedor)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_FACT_COMP_NEGOCIO
ON CP_FACTURA_COMPRA (id_negocio)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_FACT_COMP_ALMACEN
ON CP_FACTURA_COMPRA (id_almacen_recepcion)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_FACT_COMP_USUARIO
ON CP_FACTURA_COMPRA (id_usuario)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_FACT_COMP_ESTADO
ON CP_FACTURA_COMPRA (id_estado_factura_compra)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 53. CP_ESTADO_FACTURA_COMPRA
-- ============================================================
-- No requiere indices adicionales.


-- ============================================================
-- 54. CP_DETALLE_COMPRA
-- ============================================================

CREATE INDEX IX_CP_DET_COMP_FACTURA
ON CP_DETALLE_COMPRA (id_factura_compra)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_DET_COMP_PROD_PROV
ON CP_DETALLE_COMPRA (id_producto_proveedor)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 55. CP_CUENTA_PAGAR
-- ============================================================

CREATE INDEX IX_CP_CTA_PAGAR_FACTURA
ON CP_CUENTA_PAGAR (id_factura_compra)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_CTA_PAGAR_ESTADO
ON CP_CUENTA_PAGAR (id_estado_cuenta_pagar)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 56. CP_ESTADO_CUENTA_PAGAR
-- ============================================================
-- No requiere indices adicionales.


-- ============================================================
-- 57. CP_ABONO_CUENTA_PAGAR
-- ============================================================

CREATE INDEX IX_CP_ABONO_PAGAR_CUENTA
ON CP_ABONO_CUENTA_PAGAR (id_cuenta_pagar)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_ABONO_PAGAR_TIPO
ON CP_ABONO_CUENTA_PAGAR (id_tipo_pago)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_ABONO_PAGAR_USUARIO
ON CP_ABONO_CUENTA_PAGAR (id_usuario)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 58. CP_SERVICIO
-- ============================================================

CREATE INDEX IX_CP_SERVICIO_NEGOCIO
ON CP_SERVICIO (id_negocio)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_SERVICIO_IMPUESTO
ON CP_SERVICIO (id_impuesto)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_SERVICIO_ESTADO
ON CP_SERVICIO (id_estado)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 59. CP_FACTURA_VENTA
-- ============================================================

CREATE INDEX IX_CP_FACT_VENTA_CLIENTE
ON CP_FACTURA_VENTA (id_cliente)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_FACT_VENTA_SUCURSAL
ON CP_FACTURA_VENTA (id_sucursal)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_FACT_VENTA_USUARIO
ON CP_FACTURA_VENTA (id_usuario)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_FACT_VENTA_ESTADO
ON CP_FACTURA_VENTA (id_estado_factura_venta)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 60. CP_ESTADO_FACTURA_VENTA
-- ============================================================
-- No requiere indices adicionales.


-- ============================================================
-- 61. CP_DETALLE_VENTA_PRODUCTO
-- ============================================================

CREATE INDEX IX_CP_DET_VENTA_PROD_FACT
ON CP_DETALLE_VENTA_PRODUCTO (id_factura_venta)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_DET_VENTA_PROD_PROD
ON CP_DETALLE_VENTA_PRODUCTO (id_producto)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 62. CP_DETALLE_VENTA_SERVICIO
-- ============================================================

CREATE INDEX IX_CP_DET_VENTA_SERV_FACT
ON CP_DETALLE_VENTA_SERVICIO (id_factura_venta)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_DET_VENTA_SERV_SERV
ON CP_DETALLE_VENTA_SERVICIO (id_servicio)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 63. CP_DETALLE_VENTA_LOTE
-- ============================================================

CREATE INDEX IX_CP_DET_VENTA_LOTE_DET
ON CP_DETALLE_VENTA_LOTE (id_detalle_venta_producto)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_DET_VENTA_LOTE_LOTE
ON CP_DETALLE_VENTA_LOTE (id_lote_producto)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 64. CP_TIPO_PAGO
-- ============================================================

CREATE INDEX IX_CP_TIPO_PAGO_ESTADO
ON CP_TIPO_PAGO (id_estado)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 65. CP_PAGO_FACTURA_VENTA
-- ============================================================

CREATE INDEX IX_CP_PAGO_VENTA_FACTURA
ON CP_PAGO_FACTURA_VENTA (id_factura_venta)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_PAGO_VENTA_TIPO
ON CP_PAGO_FACTURA_VENTA (id_tipo_pago)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_PAGO_VENTA_USUARIO
ON CP_PAGO_FACTURA_VENTA (id_usuario)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 66. CP_ESTADO_CREDITO
-- ============================================================
-- No requiere indices adicionales.


-- ============================================================
-- 67. CP_CREDITO_CLIENTE
-- ============================================================

CREATE INDEX IX_CP_CRED_CLI_CLIENTE
ON CP_CREDITO_CLIENTE (id_cliente)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_CRED_CLI_NEGOCIO
ON CP_CREDITO_CLIENTE (id_negocio)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_CRED_CLI_ESTADO
ON CP_CREDITO_CLIENTE (id_estado_credito)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 68. CP_CUENTA_COBRAR
-- ============================================================

CREATE INDEX IX_CP_CTA_COBRAR_FACTURA
ON CP_CUENTA_COBRAR (id_factura_venta)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_CTA_COBRAR_CREDITO
ON CP_CUENTA_COBRAR (id_credito_cliente)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_CTA_COBRAR_ESTADO
ON CP_CUENTA_COBRAR (id_estado_cuenta_cobrar)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 69. CP_ESTADO_CUENTA_COBRAR
-- ============================================================
-- No requiere indices adicionales.


-- ============================================================
-- 70. CP_ABONO_CUENTA_COBRAR
-- ============================================================

CREATE INDEX IX_CP_ABONO_COBRAR_CUENTA
ON CP_ABONO_CUENTA_COBRAR (id_cuenta_cobrar)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_ABONO_COBRAR_TIPO
ON CP_ABONO_CUENTA_COBRAR (id_tipo_pago)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_ABONO_COBRAR_USUARIO
ON CP_ABONO_CUENTA_COBRAR (id_usuario)
TABLESPACE CP_POS_INDICES;

-- ============================================================
-- 71. CP_ESTADO_PROMOCION
-- ============================================================
-- No requiere indices adicionales.


-- ============================================================
-- 72. CP_PROMOCION
-- ============================================================

CREATE INDEX IX_CP_PROMOCION_ESTADO
ON CP_PROMOCION (id_estado_promocion)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_PROMOCION_NEGOCIO
ON CP_PROMOCION (id_negocio)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 73. CP_ACCION_PROMOCION
-- ============================================================
-- No requiere indices adicionales.


-- ============================================================
-- 74. CP_REGLA_PROMOCION
-- ============================================================

CREATE INDEX IX_CP_REGLA_PROM_PROMOCION
ON CP_REGLA_PROMOCION (id_promocion)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_REGLA_PROM_ACCION
ON CP_REGLA_PROMOCION (id_accion_promocion)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 75. CP_PROMOCION_PATROCINADOR
-- ============================================================

CREATE INDEX IX_CP_PROM_PAT_REGLA
ON CP_PROMOCION_PATROCINADOR (id_regla_promocion)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_PROM_PAT_PRODUCTO
ON CP_PROMOCION_PATROCINADOR (id_producto)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 76. CP_PROMOCION_PREMIO
-- ============================================================

CREATE INDEX IX_CP_PROM_PREMIO_REGLA
ON CP_PROMOCION_PREMIO (id_regla_promocion)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_PROM_PREMIO_PRODUCTO
ON CP_PROMOCION_PREMIO (id_producto_premio)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 77. CP_ESTADO_DESCUENTO
-- ============================================================
-- No requiere indices adicionales.


-- ============================================================
-- 78. CP_DESCUENTO
-- ============================================================

CREATE INDEX IX_CP_DESCUENTO_NEGOCIO
ON CP_DESCUENTO (id_negocio)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_DESCUENTO_ESTADO
ON CP_DESCUENTO (id_estado_descuento)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 79. CP_DESCUENTO_FAMILIA
-- ============================================================

CREATE INDEX IX_CP_DESC_FAMILIA_DESC
ON CP_DESCUENTO_FAMILIA (id_descuento)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_DESC_FAMILIA_FAMILIA
ON CP_DESCUENTO_FAMILIA (id_familia_producto)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 80. CP_DESCUENTO_PROVEEDOR
-- ============================================================

CREATE INDEX IX_CP_DESC_PROV_DESC
ON CP_DESCUENTO_PROVEEDOR (id_descuento)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_DESC_PROV_PROVEEDOR
ON CP_DESCUENTO_PROVEEDOR (id_proveedor)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 81. CP_DESCUENTO_FECHA_INGRESO
-- ============================================================

CREATE INDEX IX_CP_DESC_FECHA_DESC
ON CP_DESCUENTO_FECHA_INGRESO (id_descuento)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 82. CP_DESCUENTO_VENCIMIENTO
-- ============================================================

CREATE INDEX IX_CP_DESC_VENC_DESC
ON CP_DESCUENTO_VENCIMIENTO (id_descuento)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 83. CP_DESCUENTO_APLICADO
-- ============================================================

CREATE INDEX IX_CP_DESC_APLIC_DET_VENTA
ON CP_DESCUENTO_APLICADO (id_detalle_venta_producto)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_DESC_APLIC_DESCUENTO
ON CP_DESCUENTO_APLICADO (id_descuento)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 84. CP_ESTADO_DEVOLUCION
-- ============================================================
-- No requiere indices adicionales.


-- ============================================================
-- 85. CP_MOTIVO_DEVOLUCION
-- ============================================================
-- No requiere indices adicionales.


-- ============================================================
-- 86. CP_DEVOLUCION_VENTA
-- ============================================================

CREATE INDEX IX_CP_DEV_VENTA_FACTURA
ON CP_DEVOLUCION_VENTA (id_factura_venta)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_DEV_VENTA_ESTADO
ON CP_DEVOLUCION_VENTA (id_estado_devolucion)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_DEV_VENTA_USUARIO
ON CP_DEVOLUCION_VENTA (id_usuario)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 87. CP_DETALLE_DEVOLUCION_VENTA
-- ============================================================

CREATE INDEX IX_CP_DET_DEV_VENTA_DEV
ON CP_DETALLE_DEVOLUCION_VENTA (id_devolucion_venta)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_DET_DEV_VENTA_LOTE
ON CP_DETALLE_DEVOLUCION_VENTA (id_detalle_venta_lote)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_DET_DEV_VENTA_MOTIVO
ON CP_DETALLE_DEVOLUCION_VENTA (id_motivo_devolucion)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 88. CP_NOTA_CREDITO_CLIENTE
-- ============================================================

CREATE INDEX IX_CP_NOTA_CRED_CLI_DEV
ON CP_NOTA_CREDITO_CLIENTE (id_devolucion_venta)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 89. CP_DEVOLUCION_COMPRA
-- ============================================================

CREATE INDEX IX_CP_DEV_COMPRA_FACTURA
ON CP_DEVOLUCION_COMPRA (id_factura_compra)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_DEV_COMPRA_ESTADO
ON CP_DEVOLUCION_COMPRA (id_estado_devolucion)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_DEV_COMPRA_USUARIO
ON CP_DEVOLUCION_COMPRA (id_usuario)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 90. CP_DETALLE_DEVOLUCION_COMPRA
-- ============================================================

CREATE INDEX IX_CP_DET_DEV_COMPRA_DEV
ON CP_DETALLE_DEVOLUCION_COMPRA (id_devolucion_compra)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_DET_DEV_COMPRA_LOTE
ON CP_DETALLE_DEVOLUCION_COMPRA (id_lote_producto)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_DET_DEV_COMPRA_MOTIVO
ON CP_DETALLE_DEVOLUCION_COMPRA (id_motivo_devolucion)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 91. CP_NOTA_CREDITO_PROVEEDOR
-- ============================================================

CREATE INDEX IX_CP_NOTA_CRED_PROV_DEV
ON CP_NOTA_CREDITO_PROVEEDOR (id_devolucion_compra)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 92. CP_BITACORA_PRECIO
-- ============================================================

CREATE INDEX IX_CP_BIT_PRECIO_PROD_NEG
ON CP_BITACORA_PRECIO (id_producto_negocio)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_BIT_PRECIO_USUARIO
ON CP_BITACORA_PRECIO (id_usuario)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_BIT_PRECIO_OPERACION
ON CP_BITACORA_PRECIO (id_tipo_operacion)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 93. CP_BITACORA_INVENTARIO
-- ============================================================

CREATE INDEX IX_CP_BIT_INV_ALMACEN
ON CP_BITACORA_INVENTARIO (id_almacen)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_BIT_INV_LOTE
ON CP_BITACORA_INVENTARIO (id_lote_producto)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_BIT_INV_USUARIO
ON CP_BITACORA_INVENTARIO (id_usuario)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_BIT_INV_OPERACION
ON CP_BITACORA_INVENTARIO (id_tipo_operacion)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 94. CP_BITACORA_TRASLADO
-- ============================================================

CREATE INDEX IX_CP_BIT_TRAS_TRASLADO
ON CP_BITACORA_TRASLADO (id_traslado)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_BIT_TRAS_USUARIO
ON CP_BITACORA_TRASLADO (id_usuario)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_BIT_TRAS_OPERACION
ON CP_BITACORA_TRASLADO (id_tipo_operacion)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_BIT_TRAS_EST_ANT
ON CP_BITACORA_TRASLADO (id_estado_anterior)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_BIT_TRAS_EST_NUEVO
ON CP_BITACORA_TRASLADO (id_estado_nuevo)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 95. CP_BITACORA_VENTA
-- ============================================================

CREATE INDEX IX_CP_BIT_VENTA_FACTURA
ON CP_BITACORA_VENTA (id_factura_venta)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_BIT_VENTA_USUARIO
ON CP_BITACORA_VENTA (id_usuario)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_BIT_VENTA_OPERACION
ON CP_BITACORA_VENTA (id_tipo_operacion)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_BIT_VENTA_EST_ANT
ON CP_BITACORA_VENTA (id_estado_anterior)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_BIT_VENTA_EST_NUEVO
ON CP_BITACORA_VENTA (id_estado_nuevo)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 96. CP_BITACORA_CREDITO_CLIENTE
-- ============================================================

CREATE INDEX IX_CP_BIT_CRED_CLI_CREDITO
ON CP_BITACORA_CREDITO_CLIENTE (id_credito_cliente)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_BIT_CRED_CLI_USUARIO
ON CP_BITACORA_CREDITO_CLIENTE (id_usuario)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_BIT_CRED_CLI_OPER
ON CP_BITACORA_CREDITO_CLIENTE (id_tipo_operacion)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 97. CP_BITACORA_CREDITO_PROVEEDOR
-- ============================================================

CREATE INDEX IX_CP_BIT_CRED_PROV_CRED
ON CP_BITACORA_CREDITO_PROVEEDOR (id_credito_proveedor)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_BIT_CRED_PROV_USUARIO
ON CP_BITACORA_CREDITO_PROVEEDOR (id_usuario)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_BIT_CRED_PROV_OPER
ON CP_BITACORA_CREDITO_PROVEEDOR (id_tipo_operacion)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 98. CP_BITACORA_DEVOLUCION_VENTA
-- ============================================================

CREATE INDEX IX_CP_BIT_DEV_VENTA_DEV
ON CP_BITACORA_DEVOLUCION_VENTA (id_devolucion_venta)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_BIT_DEV_VENTA_USUARIO
ON CP_BITACORA_DEVOLUCION_VENTA (id_usuario)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_BIT_DEV_VENTA_OPER
ON CP_BITACORA_DEVOLUCION_VENTA (id_tipo_operacion)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_BIT_DEV_VENTA_EST_ANT
ON CP_BITACORA_DEVOLUCION_VENTA (id_estado_anterior)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_BIT_DEV_VENTA_EST_NUE
ON CP_BITACORA_DEVOLUCION_VENTA (id_estado_nuevo)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 99. CP_BITACORA_DEVOLUCION_COMPRA
-- ============================================================

CREATE INDEX IX_CP_BIT_DEV_COMPRA_DEV
ON CP_BITACORA_DEVOLUCION_COMPRA (id_devolucion_compra)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_BIT_DEV_COMPRA_USUARIO
ON CP_BITACORA_DEVOLUCION_COMPRA (id_usuario)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_BIT_DEV_COMPRA_OPER
ON CP_BITACORA_DEVOLUCION_COMPRA (id_tipo_operacion)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_BIT_DEV_COMPRA_EST_ANT
ON CP_BITACORA_DEVOLUCION_COMPRA (id_estado_anterior)
TABLESPACE CP_POS_INDICES;

CREATE INDEX IX_CP_BIT_DEV_COMPRA_EST_NUE
ON CP_BITACORA_DEVOLUCION_COMPRA (id_estado_nuevo)
TABLESPACE CP_POS_INDICES;


-- ============================================================
-- 100. CP_BITACORA_ACCESO
-- ============================================================

CREATE INDEX IX_CP_BIT_ACCESO_USUARIO
ON CP_BITACORA_ACCESO (id_usuario)
TABLESPACE CP_POS_INDICES;
