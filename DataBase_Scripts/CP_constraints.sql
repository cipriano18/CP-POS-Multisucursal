-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- BASE DE DATOS: Oracle 21c
-- SCRIPT: 05_constraints.sql
-- DESCRIPCION: Creacion de llaves foraneas del sistema
-- USUARIO: CP_POS
-- ============================================================


-- ============================================================
-- 5. CP_CANTON
-- ============================================================

ALTER TABLE CP_CANTON
ADD CONSTRAINT FK_CP_CANTON_PROVINCIA
FOREIGN KEY (id_provincia)
REFERENCES CP_PROVINCIA (id_provincia);


-- ============================================================
-- 6. CP_DISTRITO
-- ============================================================

ALTER TABLE CP_DISTRITO
ADD CONSTRAINT FK_CP_DISTRITO_CANTON
FOREIGN KEY (id_canton)
REFERENCES CP_CANTON (id_canton);


-- ============================================================
-- 7. CP_DIRECCION
-- ============================================================

ALTER TABLE CP_DIRECCION
ADD CONSTRAINT FK_CP_DIRECCION_DISTRITO
FOREIGN KEY (id_distrito)
REFERENCES CP_DISTRITO (id_distrito);


-- ============================================================
-- 9. CP_SUCURSAL
-- ============================================================

ALTER TABLE CP_SUCURSAL
ADD CONSTRAINT FK_CP_SUCURSAL_NEGOCIO
FOREIGN KEY (id_negocio)
REFERENCES CP_NEGOCIO (id_negocio);

ALTER TABLE CP_SUCURSAL
ADD CONSTRAINT FK_CP_SUCURSAL_DIRECCION
FOREIGN KEY (id_direccion)
REFERENCES CP_DIRECCION (id_direccion);

ALTER TABLE CP_SUCURSAL
ADD CONSTRAINT FK_CP_SUCURSAL_ESTADO
FOREIGN KEY (id_estado)
REFERENCES CP_ESTADO (id_estado);


-- ============================================================
-- 15. CP_PERSONA
-- ============================================================

ALTER TABLE CP_PERSONA
ADD CONSTRAINT FK_CP_PERSONA_NACIONALIDAD
FOREIGN KEY (id_nacionalidad)
REFERENCES CP_NACIONALIDAD (id_nacionalidad);

ALTER TABLE CP_PERSONA
ADD CONSTRAINT FK_CP_PERSONA_SEXO
FOREIGN KEY (id_sexo)
REFERENCES CP_SEXO (id_sexo);

ALTER TABLE CP_PERSONA
ADD CONSTRAINT FK_CP_PERSONA_ESTADO_CIVIL
FOREIGN KEY (id_estado_civil)
REFERENCES CP_ESTADO_CIVIL (id_estado_civil);

ALTER TABLE CP_PERSONA
ADD CONSTRAINT FK_CP_PERSONA_ESCOLARIDAD
FOREIGN KEY (id_escolaridad)
REFERENCES CP_ESCOLARIDAD (id_escolaridad);

ALTER TABLE CP_PERSONA
ADD CONSTRAINT FK_CP_PERSONA_TIPO_RESIDENCIA
FOREIGN KEY (id_tipo_residencia)
REFERENCES CP_TIPO_RESIDENCIA (id_tipo_residencia);


-- ============================================================
-- 17. CP_CONTACTO
-- ============================================================

ALTER TABLE CP_CONTACTO
ADD CONSTRAINT FK_CP_CONTACTO_TIPO
FOREIGN KEY (id_tipo_contacto)
REFERENCES CP_TIPO_DE_CONTACTO (id_tipo_contacto);


-- ============================================================
-- 18. CP_PERSONA_DIRECCION
-- ============================================================

ALTER TABLE CP_PERSONA_DIRECCION
ADD CONSTRAINT FK_CP_PERSONA_DIRECCION_PERSONA
FOREIGN KEY (id_persona)
REFERENCES CP_PERSONA (id_persona);

ALTER TABLE CP_PERSONA_DIRECCION
ADD CONSTRAINT FK_CP_PERSONA_DIRECCION_DIRECCION
FOREIGN KEY (id_direccion)
REFERENCES CP_DIRECCION (id_direccion);

ALTER TABLE CP_PERSONA_DIRECCION
ADD CONSTRAINT FK_CP_PERSONA_DIRECCION_TIPO
FOREIGN KEY (id_tipo_direccion)
REFERENCES CP_TIPO_DIRECCION (id_tipo_direccion);


-- ============================================================
-- 19. CP_PERSONA_CONTACTO
-- ============================================================

ALTER TABLE CP_PERSONA_CONTACTO
ADD CONSTRAINT FK_CP_PERSONA_CONTACTO_PERSONA
FOREIGN KEY (id_persona)
REFERENCES CP_PERSONA (id_persona);

ALTER TABLE CP_PERSONA_CONTACTO
ADD CONSTRAINT FK_CP_PERSONA_CONTACTO_CONTACTO
FOREIGN KEY (id_contacto)
REFERENCES CP_CONTACTO (id_contacto);


-- ============================================================
-- 22. CP_PERSONA_EMPLEO
-- ============================================================

ALTER TABLE CP_PERSONA_EMPLEO
ADD CONSTRAINT FK_CP_PERSONA_EMPLEO_PERSONA
FOREIGN KEY (id_persona)
REFERENCES CP_PERSONA (id_persona);

ALTER TABLE CP_PERSONA_EMPLEO
ADD CONSTRAINT FK_CP_PERSONA_EMPLEO_PUESTO
FOREIGN KEY (id_puesto)
REFERENCES CP_PUESTO (id_puesto);

ALTER TABLE CP_PERSONA_EMPLEO
ADD CONSTRAINT FK_CP_PERSONA_EMPLEO_EMPRESA
FOREIGN KEY (id_empresa_laboral)
REFERENCES CP_EMPRESA_LABORAL (id_empresa_laboral);


-- ============================================================
-- 25. CP_ROL_PERMISO
-- ============================================================

ALTER TABLE CP_ROL_PERMISO
ADD CONSTRAINT FK_CP_ROL_PERMISO_ROL
FOREIGN KEY (id_rol)
REFERENCES CP_ROL (id_rol);

ALTER TABLE CP_ROL_PERMISO
ADD CONSTRAINT FK_CP_ROL_PERMISO_PERMISO
FOREIGN KEY (id_permiso)
REFERENCES CP_PERMISO (id_permiso);


-- ============================================================
-- 26. CP_USUARIO
-- ============================================================

ALTER TABLE CP_USUARIO
ADD CONSTRAINT FK_CP_USUARIO_PERSONA
FOREIGN KEY (id_persona)
REFERENCES CP_PERSONA (id_persona);

ALTER TABLE CP_USUARIO
ADD CONSTRAINT FK_CP_USUARIO_ESTADO
FOREIGN KEY (id_estado)
REFERENCES CP_ESTADO (id_estado);

ALTER TABLE CP_USUARIO
ADD CONSTRAINT FK_CP_USUARIO_SUCURSAL
FOREIGN KEY (id_sucursal)
REFERENCES CP_SUCURSAL (id_sucursal);

ALTER TABLE CP_USUARIO
ADD CONSTRAINT FK_CP_USUARIO_ROL
FOREIGN KEY (id_rol)
REFERENCES CP_ROL (id_rol);


-- ============================================================
-- 29. CP_CLIENTE
-- ============================================================

ALTER TABLE CP_CLIENTE
ADD CONSTRAINT FK_CP_CLIENTE_TIPO_CLIENTE
FOREIGN KEY (id_tipo_cliente)
REFERENCES CP_TIPO_CLIENTE (id_tipo_cliente);

ALTER TABLE CP_CLIENTE
ADD CONSTRAINT FK_CP_CLIENTE_ESTADO_CLIENTE
FOREIGN KEY (id_estado_cliente)
REFERENCES CP_ESTADO_CLIENTE (id_estado_cliente);


-- ============================================================
-- 30. CP_CLIENTE_PERSONA
-- ============================================================

ALTER TABLE CP_CLIENTE_PERSONA
ADD CONSTRAINT FK_CP_CLIENTE_PERSONA_CLIENTE
FOREIGN KEY (id_cliente)
REFERENCES CP_CLIENTE (id_cliente);

ALTER TABLE CP_CLIENTE_PERSONA
ADD CONSTRAINT FK_CP_CLIENTE_PERSONA_PERSONA
FOREIGN KEY (id_persona)
REFERENCES CP_PERSONA (id_persona);


-- ============================================================
-- 31. CP_CLIENTE_EMPRESA
-- ============================================================

ALTER TABLE CP_CLIENTE_EMPRESA
ADD CONSTRAINT FK_CP_CLIENTE_EMPRESA_CLIENTE
FOREIGN KEY (id_cliente)
REFERENCES CP_CLIENTE (id_cliente);


-- ============================================================
-- 32. CP_CLIENTE_EMPRESA_DIRECCION
-- ============================================================

ALTER TABLE CP_CLIENTE_EMPRESA_DIRECCION
ADD CONSTRAINT FK_CP_CLI_EMP_DIR_EMPRESA
FOREIGN KEY (id_cliente_empresa)
REFERENCES CP_CLIENTE_EMPRESA (id_cliente_empresa);

ALTER TABLE CP_CLIENTE_EMPRESA_DIRECCION
ADD CONSTRAINT FK_CP_CLI_EMP_DIR_DIRECCION
FOREIGN KEY (id_direccion)
REFERENCES CP_DIRECCION (id_direccion);

ALTER TABLE CP_CLIENTE_EMPRESA_DIRECCION
ADD CONSTRAINT FK_CP_CLI_EMP_DIR_TIPO
FOREIGN KEY (id_tipo_direccion)
REFERENCES CP_TIPO_DIRECCION (id_tipo_direccion);


-- ============================================================
-- 33. CP_CLIENTE_EMPRESA_CONTACTO
-- ============================================================

ALTER TABLE CP_CLIENTE_EMPRESA_CONTACTO
ADD CONSTRAINT FK_CP_CLI_EMP_CONT_EMPRESA
FOREIGN KEY (id_cliente_empresa)
REFERENCES CP_CLIENTE_EMPRESA (id_cliente_empresa);

ALTER TABLE CP_CLIENTE_EMPRESA_CONTACTO
ADD CONSTRAINT FK_CP_CLI_EMP_CONT_CONTACTO
FOREIGN KEY (id_contacto)
REFERENCES CP_CONTACTO (id_contacto);


-- ============================================================
-- 34. CP_PROVEEDOR
-- ============================================================

ALTER TABLE CP_PROVEEDOR
ADD CONSTRAINT FK_CP_PROVEEDOR_ESTADO
FOREIGN KEY (id_estado)
REFERENCES CP_ESTADO (id_estado);


-- ============================================================
-- 35. CP_PROVEEDOR_DIRECCION
-- ============================================================

ALTER TABLE CP_PROVEEDOR_DIRECCION
ADD CONSTRAINT FK_CP_PROV_DIR_PROVEEDOR
FOREIGN KEY (id_proveedor)
REFERENCES CP_PROVEEDOR (id_proveedor);

ALTER TABLE CP_PROVEEDOR_DIRECCION
ADD CONSTRAINT FK_CP_PROV_DIR_TIPO_DIRECCION
FOREIGN KEY (id_tipo_direccion)
REFERENCES CP_TIPO_DIRECCION (id_tipo_direccion);

ALTER TABLE CP_PROVEEDOR_DIRECCION
ADD CONSTRAINT FK_CP_PROV_DIR_DIRECCION
FOREIGN KEY (id_direccion)
REFERENCES CP_DIRECCION (id_direccion);


-- ============================================================
-- 36. CP_NEGOCIO
-- ============================================================

ALTER TABLE CP_NEGOCIO
ADD CONSTRAINT FK_CP_NEGOCIO_TIPO_NEGOCIO
FOREIGN KEY (id_tipo_negocio)
REFERENCES CP_TIPO_NEGOCIO (id_tipo_negocio);

ALTER TABLE CP_NEGOCIO
ADD CONSTRAINT FK_CP_NEGOCIO_ESTADO
FOREIGN KEY (id_estado)
REFERENCES CP_ESTADO (id_estado);


-- ============================================================
-- 37. CP_PROVEEDOR_CONTACTO
-- ============================================================

ALTER TABLE CP_PROVEEDOR_CONTACTO
ADD CONSTRAINT FK_CP_PROV_CONT_PROVEEDOR
FOREIGN KEY (id_proveedor)
REFERENCES CP_PROVEEDOR (id_proveedor);

ALTER TABLE CP_PROVEEDOR_CONTACTO
ADD CONSTRAINT FK_CP_PROV_CONT_CONTACTO
FOREIGN KEY (id_contacto)
REFERENCES CP_CONTACTO (id_contacto);


-- ============================================================
-- 38. CP_CREDITO_PROVEEDOR
-- ============================================================

ALTER TABLE CP_CREDITO_PROVEEDOR
ADD CONSTRAINT FK_CP_CRED_PROV_PROVEEDOR
FOREIGN KEY (id_proveedor)
REFERENCES CP_PROVEEDOR (id_proveedor);

ALTER TABLE CP_CREDITO_PROVEEDOR
ADD CONSTRAINT FK_CP_CRED_PROV_NEGOCIO
FOREIGN KEY (id_negocio)
REFERENCES CP_NEGOCIO (id_negocio);

ALTER TABLE CP_CREDITO_PROVEEDOR
ADD CONSTRAINT FK_CP_CRED_PROV_ESTADO
FOREIGN KEY (id_estado_credito)
REFERENCES CP_ESTADO_CREDITO (id_estado_credito);


-- ============================================================
-- 39. CP_FAMILIA_PRODUCTO
-- ============================================================
-- No posee llaves foraneas.


-- ============================================================
-- 40. CP_IMPUESTO
-- ============================================================

ALTER TABLE CP_IMPUESTO
ADD CONSTRAINT FK_CP_IMPUESTO_ESTADO
FOREIGN KEY (id_estado)
REFERENCES CP_ESTADO (id_estado);


-- ============================================================
-- 41. CP_PRODUCTO
-- ============================================================

ALTER TABLE CP_PRODUCTO
ADD CONSTRAINT FK_CP_PRODUCTO_FAMILIA
FOREIGN KEY (id_familia_producto)
REFERENCES CP_FAMILIA_PRODUCTO (id_familia_producto);

ALTER TABLE CP_PRODUCTO
ADD CONSTRAINT FK_CP_PRODUCTO_IMPUESTO
FOREIGN KEY (id_impuesto)
REFERENCES CP_IMPUESTO (id_impuesto);

ALTER TABLE CP_PRODUCTO
ADD CONSTRAINT FK_CP_PRODUCTO_ESTADO
FOREIGN KEY (id_estado)
REFERENCES CP_ESTADO (id_estado);


-- ============================================================
-- 42. CP_CODIGO_BARRA
-- ============================================================

ALTER TABLE CP_CODIGO_BARRA
ADD CONSTRAINT FK_CP_CODIGO_BARRA_PRODUCTO
FOREIGN KEY (id_producto)
REFERENCES CP_PRODUCTO (id_producto);


-- ============================================================
-- 43. CP_PRODUCTO_PROVEEDOR
-- ============================================================

ALTER TABLE CP_PRODUCTO_PROVEEDOR
ADD CONSTRAINT FK_CP_PROD_PROV_PROVEEDOR
FOREIGN KEY (id_proveedor)
REFERENCES CP_PROVEEDOR (id_proveedor);

ALTER TABLE CP_PRODUCTO_PROVEEDOR
ADD CONSTRAINT FK_CP_PROD_PROV_PRODUCTO
FOREIGN KEY (id_producto)
REFERENCES CP_PRODUCTO (id_producto);


-- ============================================================
-- 44. CP_PRODUCTO_NEGOCIO
-- ============================================================

ALTER TABLE CP_PRODUCTO_NEGOCIO
ADD CONSTRAINT FK_CP_PROD_NEG_PRODUCTO
FOREIGN KEY (id_producto)
REFERENCES CP_PRODUCTO (id_producto);

ALTER TABLE CP_PRODUCTO_NEGOCIO
ADD CONSTRAINT FK_CP_PROD_NEG_NEGOCIO
FOREIGN KEY (id_negocio)
REFERENCES CP_NEGOCIO (id_negocio);


-- ============================================================
-- 45. CP_LOTE_PRODUCTO
-- ============================================================

ALTER TABLE CP_LOTE_PRODUCTO
ADD CONSTRAINT FK_CP_LOTE_PRODUCTO_DET_COMPRA
FOREIGN KEY (id_detalle_compra)
REFERENCES CP_DETALLE_COMPRA (id_detalle_compra);


-- ============================================================
-- 46. CP_TIPO_ALMACEN
-- ============================================================
-- No posee llaves foraneas.


-- ============================================================
-- 47. CP_ALMACEN
-- ============================================================

ALTER TABLE CP_ALMACEN
ADD CONSTRAINT FK_CP_ALMACEN_TIPO
FOREIGN KEY (id_tipo_almacen)
REFERENCES CP_TIPO_ALMACEN (id_tipo_almacen);

ALTER TABLE CP_ALMACEN
ADD CONSTRAINT FK_CP_ALMACEN_SUCURSAL
FOREIGN KEY (id_sucursal)
REFERENCES CP_SUCURSAL (id_sucursal);

ALTER TABLE CP_ALMACEN
ADD CONSTRAINT FK_CP_ALMACEN_ESTADO
FOREIGN KEY (id_estado)
REFERENCES CP_ESTADO (id_estado);

ALTER TABLE CP_ALMACEN
ADD CONSTRAINT FK_CP_ALMACEN_DIRECCION
FOREIGN KEY (id_direccion)
REFERENCES CP_DIRECCION (id_direccion);


-- ============================================================
-- 48. CP_INVENTARIO_ALMACEN
-- ============================================================

ALTER TABLE CP_INVENTARIO_ALMACEN
ADD CONSTRAINT FK_CP_INV_ALMACEN_ALMACEN
FOREIGN KEY (id_almacen)
REFERENCES CP_ALMACEN (id_almacen);

ALTER TABLE CP_INVENTARIO_ALMACEN
ADD CONSTRAINT FK_CP_INV_ALMACEN_LOTE
FOREIGN KEY (id_lote_producto)
REFERENCES CP_LOTE_PRODUCTO (id_lote_producto);


-- ============================================================
-- 49. CP_ESTADO_TRASLADO
-- ============================================================
-- No posee llaves foraneas.


-- ============================================================
-- 50. CP_TRASLADO
-- ============================================================

ALTER TABLE CP_TRASLADO
ADD CONSTRAINT FK_CP_TRASLADO_ALMACEN_ORIGEN
FOREIGN KEY (id_almacen_origen)
REFERENCES CP_ALMACEN (id_almacen);

ALTER TABLE CP_TRASLADO
ADD CONSTRAINT FK_CP_TRASLADO_ALMACEN_DESTINO
FOREIGN KEY (id_almacen_destino)
REFERENCES CP_ALMACEN (id_almacen);

ALTER TABLE CP_TRASLADO
ADD CONSTRAINT FK_CP_TRASLADO_USUARIO_SOLICITA
FOREIGN KEY (id_usuario_solicita)
REFERENCES CP_USUARIO (id_usuario);

ALTER TABLE CP_TRASLADO
ADD CONSTRAINT FK_CP_TRASLADO_USUARIO_RECIBE
FOREIGN KEY (id_usuario_recibe)
REFERENCES CP_USUARIO (id_usuario);

ALTER TABLE CP_TRASLADO
ADD CONSTRAINT FK_CP_TRASLADO_ESTADO
FOREIGN KEY (id_estado_traslado)
REFERENCES CP_ESTADO_TRASLADO (id_estado_traslado);


-- ============================================================
-- 51. CP_DETALLE_TRASLADO
-- ============================================================

ALTER TABLE CP_DETALLE_TRASLADO
ADD CONSTRAINT FK_CP_DET_TRASLADO_TRASLADO
FOREIGN KEY (id_traslado)
REFERENCES CP_TRASLADO (id_traslado);

ALTER TABLE CP_DETALLE_TRASLADO
ADD CONSTRAINT FK_CP_DET_TRASLADO_LOTE
FOREIGN KEY (id_lote_producto)
REFERENCES CP_LOTE_PRODUCTO (id_lote_producto);

-- ============================================================
-- 52. CP_FACTURA_COMPRA
-- ============================================================

ALTER TABLE CP_FACTURA_COMPRA
ADD CONSTRAINT FK_CP_FACT_COMPRA_PROVEEDOR
FOREIGN KEY (id_proveedor)
REFERENCES CP_PROVEEDOR (id_proveedor);

ALTER TABLE CP_FACTURA_COMPRA
ADD CONSTRAINT FK_CP_FACT_COMPRA_NEGOCIO
FOREIGN KEY (id_negocio)
REFERENCES CP_NEGOCIO (id_negocio);

ALTER TABLE CP_FACTURA_COMPRA
ADD CONSTRAINT FK_CP_FACT_COMPRA_ALMACEN
FOREIGN KEY (id_almacen_recepcion)
REFERENCES CP_ALMACEN (id_almacen);

ALTER TABLE CP_FACTURA_COMPRA
ADD CONSTRAINT FK_CP_FACT_COMPRA_USUARIO
FOREIGN KEY (id_usuario)
REFERENCES CP_USUARIO (id_usuario);

ALTER TABLE CP_FACTURA_COMPRA
ADD CONSTRAINT FK_CP_FACT_COMPRA_ESTADO
FOREIGN KEY (id_estado_factura_compra)
REFERENCES CP_ESTADO_FACTURA_COMPRA (id_estado_factura_compra);


-- ============================================================
-- 53. CP_ESTADO_FACTURA_COMPRA
-- ============================================================
-- No posee llaves foraneas.


-- ============================================================
-- 54. CP_DETALLE_COMPRA
-- ============================================================

ALTER TABLE CP_DETALLE_COMPRA
ADD CONSTRAINT FK_CP_DET_COMPRA_FACTURA
FOREIGN KEY (id_factura_compra)
REFERENCES CP_FACTURA_COMPRA (id_factura_compra);

ALTER TABLE CP_DETALLE_COMPRA
ADD CONSTRAINT FK_CP_DET_COMPRA_PROD_PROV
FOREIGN KEY (id_producto_proveedor)
REFERENCES CP_PRODUCTO_PROVEEDOR (id_producto_proveedor);


-- ============================================================
-- 55. CP_CUENTA_PAGAR
-- ============================================================

ALTER TABLE CP_CUENTA_PAGAR
ADD CONSTRAINT FK_CP_CUENTA_PAGAR_FACTURA
FOREIGN KEY (id_factura_compra)
REFERENCES CP_FACTURA_COMPRA (id_factura_compra);

ALTER TABLE CP_CUENTA_PAGAR
ADD CONSTRAINT FK_CP_CUENTA_PAGAR_ESTADO
FOREIGN KEY (id_estado_cuenta_pagar)
REFERENCES CP_ESTADO_CUENTA_PAGAR (id_estado_cuenta_pagar);


-- ============================================================
-- 56. CP_ESTADO_CUENTA_PAGAR
-- ============================================================
-- No posee llaves foraneas.


-- ============================================================
-- 57. CP_ABONO_CUENTA_PAGAR
-- ============================================================

ALTER TABLE CP_ABONO_CUENTA_PAGAR
ADD CONSTRAINT FK_CP_ABONO_PAGAR_CUENTA
FOREIGN KEY (id_cuenta_pagar)
REFERENCES CP_CUENTA_PAGAR (id_cuenta_pagar);

ALTER TABLE CP_ABONO_CUENTA_PAGAR
ADD CONSTRAINT FK_CP_ABONO_PAGAR_TIPO_PAGO
FOREIGN KEY (id_tipo_pago)
REFERENCES CP_TIPO_PAGO (id_tipo_pago);

ALTER TABLE CP_ABONO_CUENTA_PAGAR
ADD CONSTRAINT FK_CP_ABONO_PAGAR_USUARIO
FOREIGN KEY (id_usuario)
REFERENCES CP_USUARIO (id_usuario);


-- ============================================================
-- 58. CP_SERVICIO
-- ============================================================

ALTER TABLE CP_SERVICIO
ADD CONSTRAINT FK_CP_SERVICIO_NEGOCIO
FOREIGN KEY (id_negocio)
REFERENCES CP_NEGOCIO (id_negocio);

ALTER TABLE CP_SERVICIO
ADD CONSTRAINT FK_CP_SERVICIO_IMPUESTO
FOREIGN KEY (id_impuesto)
REFERENCES CP_IMPUESTO (id_impuesto);

ALTER TABLE CP_SERVICIO
ADD CONSTRAINT FK_CP_SERVICIO_ESTADO
FOREIGN KEY (id_estado)
REFERENCES CP_ESTADO (id_estado);


-- ============================================================
-- 59. CP_FACTURA_VENTA
-- ============================================================

ALTER TABLE CP_FACTURA_VENTA
ADD CONSTRAINT FK_CP_FACT_VENTA_CLIENTE
FOREIGN KEY (id_cliente)
REFERENCES CP_CLIENTE (id_cliente);

ALTER TABLE CP_FACTURA_VENTA
ADD CONSTRAINT FK_CP_FACT_VENTA_SUCURSAL
FOREIGN KEY (id_sucursal)
REFERENCES CP_SUCURSAL (id_sucursal);

ALTER TABLE CP_FACTURA_VENTA
ADD CONSTRAINT FK_CP_FACT_VENTA_USUARIO
FOREIGN KEY (id_usuario)
REFERENCES CP_USUARIO (id_usuario);

ALTER TABLE CP_FACTURA_VENTA
ADD CONSTRAINT FK_CP_FACT_VENTA_ESTADO
FOREIGN KEY (id_estado_factura_venta)
REFERENCES CP_ESTADO_FACTURA_VENTA (id_estado_factura_venta);


-- ============================================================
-- 60. CP_ESTADO_FACTURA_VENTA
-- ============================================================
-- No posee llaves foraneas.


-- ============================================================
-- 61. CP_DETALLE_VENTA_PRODUCTO
-- ============================================================

ALTER TABLE CP_DETALLE_VENTA_PRODUCTO
ADD CONSTRAINT FK_CP_DET_VENTA_PROD_FACTURA
FOREIGN KEY (id_factura_venta)
REFERENCES CP_FACTURA_VENTA (id_factura_venta);

ALTER TABLE CP_DETALLE_VENTA_PRODUCTO
ADD CONSTRAINT FK_CP_DET_VENTA_PROD_PRODUCTO
FOREIGN KEY (id_producto)
REFERENCES CP_PRODUCTO (id_producto);

-- ============================================================
-- 62. CP_DETALLE_VENTA_SERVICIO
-- ============================================================

ALTER TABLE CP_DETALLE_VENTA_SERVICIO
ADD CONSTRAINT FK_CP_DET_VENTA_SERV_FACTURA
FOREIGN KEY (id_factura_venta)
REFERENCES CP_FACTURA_VENTA (id_factura_venta);

ALTER TABLE CP_DETALLE_VENTA_SERVICIO
ADD CONSTRAINT FK_CP_DET_VENTA_SERV_SERVICIO
FOREIGN KEY (id_servicio)
REFERENCES CP_SERVICIO (id_servicio);


-- ============================================================
-- 63. CP_DETALLE_VENTA_LOTE
-- ============================================================

ALTER TABLE CP_DETALLE_VENTA_LOTE
ADD CONSTRAINT FK_CP_DET_VENTA_LOTE_DET_PROD
FOREIGN KEY (id_detalle_venta_producto)
REFERENCES CP_DETALLE_VENTA_PRODUCTO (id_detalle_venta_producto);

ALTER TABLE CP_DETALLE_VENTA_LOTE
ADD CONSTRAINT FK_CP_DET_VENTA_LOTE_LOTE
FOREIGN KEY (id_lote_producto)
REFERENCES CP_LOTE_PRODUCTO (id_lote_producto);


-- ============================================================
-- 64. CP_TIPO_PAGO
-- ============================================================

ALTER TABLE CP_TIPO_PAGO
ADD CONSTRAINT FK_CP_TIPO_PAGO_ESTADO
FOREIGN KEY (id_estado)
REFERENCES CP_ESTADO (id_estado);


-- ============================================================
-- 65. CP_PAGO_FACTURA_VENTA
-- ============================================================

ALTER TABLE CP_PAGO_FACTURA_VENTA
ADD CONSTRAINT FK_CP_PAGO_VENTA_FACTURA
FOREIGN KEY (id_factura_venta)
REFERENCES CP_FACTURA_VENTA (id_factura_venta);

ALTER TABLE CP_PAGO_FACTURA_VENTA
ADD CONSTRAINT FK_CP_PAGO_VENTA_TIPO_PAGO
FOREIGN KEY (id_tipo_pago)
REFERENCES CP_TIPO_PAGO (id_tipo_pago);

ALTER TABLE CP_PAGO_FACTURA_VENTA
ADD CONSTRAINT FK_CP_PAGO_VENTA_USUARIO
FOREIGN KEY (id_usuario)
REFERENCES CP_USUARIO (id_usuario);


-- ============================================================
-- 66. CP_ESTADO_CREDITO
-- ============================================================
-- No posee llaves foraneas.


-- ============================================================
-- 67. CP_CREDITO_CLIENTE
-- ============================================================

ALTER TABLE CP_CREDITO_CLIENTE
ADD CONSTRAINT FK_CP_CRED_CLIENTE_CLIENTE
FOREIGN KEY (id_cliente)
REFERENCES CP_CLIENTE (id_cliente);

ALTER TABLE CP_CREDITO_CLIENTE
ADD CONSTRAINT FK_CP_CRED_CLIENTE_NEGOCIO
FOREIGN KEY (id_negocio)
REFERENCES CP_NEGOCIO (id_negocio);

ALTER TABLE CP_CREDITO_CLIENTE
ADD CONSTRAINT FK_CP_CRED_CLIENTE_ESTADO
FOREIGN KEY (id_estado_credito)
REFERENCES CP_ESTADO_CREDITO (id_estado_credito);


-- ============================================================
-- 68. CP_CUENTA_COBRAR
-- ============================================================

ALTER TABLE CP_CUENTA_COBRAR
ADD CONSTRAINT FK_CP_CUENTA_COBRAR_FACTURA
FOREIGN KEY (id_factura_venta)
REFERENCES CP_FACTURA_VENTA (id_factura_venta);

ALTER TABLE CP_CUENTA_COBRAR
ADD CONSTRAINT FK_CP_CUENTA_COBRAR_CREDITO
FOREIGN KEY (id_credito_cliente)
REFERENCES CP_CREDITO_CLIENTE (id_credito_cliente);

ALTER TABLE CP_CUENTA_COBRAR
ADD CONSTRAINT FK_CP_CUENTA_COBRAR_ESTADO
FOREIGN KEY (id_estado_cuenta_cobrar)
REFERENCES CP_ESTADO_CUENTA_COBRAR (id_estado_cuenta_cobrar);


-- ============================================================
-- 69. CP_ESTADO_CUENTA_COBRAR
-- ============================================================
-- No posee llaves foraneas.


-- ============================================================
-- 70. CP_ABONO_CUENTA_COBRAR
-- ============================================================

ALTER TABLE CP_ABONO_CUENTA_COBRAR
ADD CONSTRAINT FK_CP_ABONO_COBRAR_CUENTA
FOREIGN KEY (id_cuenta_cobrar)
REFERENCES CP_CUENTA_COBRAR (id_cuenta_cobrar);

ALTER TABLE CP_ABONO_CUENTA_COBRAR
ADD CONSTRAINT FK_CP_ABONO_COBRAR_TIPO_PAGO
FOREIGN KEY (id_tipo_pago)
REFERENCES CP_TIPO_PAGO (id_tipo_pago);

ALTER TABLE CP_ABONO_CUENTA_COBRAR
ADD CONSTRAINT FK_CP_ABONO_COBRAR_USUARIO
FOREIGN KEY (id_usuario)
REFERENCES CP_USUARIO (id_usuario);

-- ============================================================
-- 71. CP_ESTADO_PROMOCION
-- ============================================================
-- No posee llaves foraneas.


-- ============================================================
-- 72. CP_PROMOCION
-- ============================================================

ALTER TABLE CP_PROMOCION
ADD CONSTRAINT FK_CP_PROMOCION_ESTADO
FOREIGN KEY (id_estado_promocion)
REFERENCES CP_ESTADO_PROMOCION (id_estado_promocion);

ALTER TABLE CP_PROMOCION
ADD CONSTRAINT FK_CP_PROMOCION_NEGOCIO
FOREIGN KEY (id_negocio)
REFERENCES CP_NEGOCIO (id_negocio);


-- ============================================================
-- 73. CP_ACCION_PROMOCION
-- ============================================================
-- No posee llaves foraneas.


-- ============================================================
-- 74. CP_REGLA_PROMOCION
-- ============================================================

ALTER TABLE CP_REGLA_PROMOCION
ADD CONSTRAINT FK_CP_REGLA_PROM_PROMOCION
FOREIGN KEY (id_promocion)
REFERENCES CP_PROMOCION (id_promocion);

ALTER TABLE CP_REGLA_PROMOCION
ADD CONSTRAINT FK_CP_REGLA_PROM_ACCION
FOREIGN KEY (id_accion_promocion)
REFERENCES CP_ACCION_PROMOCION (id_accion_promocion);


-- ============================================================
-- 75. CP_PROMOCION_PATROCINADOR
-- ============================================================

ALTER TABLE CP_PROMOCION_PATROCINADOR
ADD CONSTRAINT FK_CP_PROM_PAT_REGLA
FOREIGN KEY (id_regla_promocion)
REFERENCES CP_REGLA_PROMOCION (id_regla_promocion);

ALTER TABLE CP_PROMOCION_PATROCINADOR
ADD CONSTRAINT FK_CP_PROM_PAT_PRODUCTO
FOREIGN KEY (id_producto)
REFERENCES CP_PRODUCTO (id_producto);


-- ============================================================
-- 76. CP_PROMOCION_PREMIO
-- ============================================================

ALTER TABLE CP_PROMOCION_PREMIO
ADD CONSTRAINT FK_CP_PROM_PREMIO_REGLA
FOREIGN KEY (id_regla_promocion)
REFERENCES CP_REGLA_PROMOCION (id_regla_promocion);

ALTER TABLE CP_PROMOCION_PREMIO
ADD CONSTRAINT FK_CP_PROM_PREMIO_PRODUCTO
FOREIGN KEY (id_producto_premio)
REFERENCES CP_PRODUCTO (id_producto);


-- ============================================================
-- 77. CP_ESTADO_DESCUENTO
-- ============================================================
-- No posee llaves foraneas.


-- ============================================================
-- 78. CP_DESCUENTO
-- ============================================================

ALTER TABLE CP_DESCUENTO
ADD CONSTRAINT FK_CP_DESCUENTO_NEGOCIO
FOREIGN KEY (id_negocio)
REFERENCES CP_NEGOCIO (id_negocio);

ALTER TABLE CP_DESCUENTO
ADD CONSTRAINT FK_CP_DESCUENTO_ESTADO
FOREIGN KEY (id_estado_descuento)
REFERENCES CP_ESTADO_DESCUENTO (id_estado_descuento);


-- ============================================================
-- 79. CP_DESCUENTO_FAMILIA
-- ============================================================

ALTER TABLE CP_DESCUENTO_FAMILIA
ADD CONSTRAINT FK_CP_DESC_FAMILIA_DESCUENTO
FOREIGN KEY (id_descuento)
REFERENCES CP_DESCUENTO (id_descuento);

ALTER TABLE CP_DESCUENTO_FAMILIA
ADD CONSTRAINT FK_CP_DESC_FAMILIA_FAMILIA
FOREIGN KEY (id_familia_producto)
REFERENCES CP_FAMILIA_PRODUCTO (id_familia_producto);


-- ============================================================
-- 80. CP_DESCUENTO_PROVEEDOR
-- ============================================================

ALTER TABLE CP_DESCUENTO_PROVEEDOR
ADD CONSTRAINT FK_CP_DESC_PROV_DESCUENTO
FOREIGN KEY (id_descuento)
REFERENCES CP_DESCUENTO (id_descuento);

ALTER TABLE CP_DESCUENTO_PROVEEDOR
ADD CONSTRAINT FK_CP_DESC_PROV_PROVEEDOR
FOREIGN KEY (id_proveedor)
REFERENCES CP_PROVEEDOR (id_proveedor);

-- ============================================================
-- 81. CP_DESCUENTO_FECHA_INGRESO
-- ============================================================

ALTER TABLE CP_DESCUENTO_FECHA_INGRESO
ADD CONSTRAINT FK_CP_DESC_FECHA_DESCUENTO
FOREIGN KEY (id_descuento)
REFERENCES CP_DESCUENTO (id_descuento);


-- ============================================================
-- 82. CP_DESCUENTO_VENCIMIENTO
-- ============================================================

ALTER TABLE CP_DESCUENTO_VENCIMIENTO
ADD CONSTRAINT FK_CP_DESC_VENC_DESCUENTO
FOREIGN KEY (id_descuento)
REFERENCES CP_DESCUENTO (id_descuento);


-- ============================================================
-- 83. CP_DESCUENTO_APLICADO
-- ============================================================

ALTER TABLE CP_DESCUENTO_APLICADO
ADD CONSTRAINT FK_CP_DESC_APLICADO_DET_VENTA
FOREIGN KEY (id_detalle_venta_producto)
REFERENCES CP_DETALLE_VENTA_PRODUCTO (id_detalle_venta_producto);

ALTER TABLE CP_DESCUENTO_APLICADO
ADD CONSTRAINT FK_CP_DESC_APLICADO_DESCUENTO
FOREIGN KEY (id_descuento)
REFERENCES CP_DESCUENTO (id_descuento);


-- ============================================================
-- 84. CP_ESTADO_DEVOLUCION
-- ============================================================
-- No posee llaves foraneas.


-- ============================================================
-- 85. CP_MOTIVO_DEVOLUCION
-- ============================================================
-- No posee llaves foraneas.


-- ============================================================
-- 86. CP_DEVOLUCION_VENTA
-- ============================================================

ALTER TABLE CP_DEVOLUCION_VENTA
ADD CONSTRAINT FK_CP_DEV_VENTA_FACTURA
FOREIGN KEY (id_factura_venta)
REFERENCES CP_FACTURA_VENTA (id_factura_venta);

ALTER TABLE CP_DEVOLUCION_VENTA
ADD CONSTRAINT FK_CP_DEV_VENTA_ESTADO
FOREIGN KEY (id_estado_devolucion)
REFERENCES CP_ESTADO_DEVOLUCION (id_estado_devolucion);

ALTER TABLE CP_DEVOLUCION_VENTA
ADD CONSTRAINT FK_CP_DEV_VENTA_USUARIO
FOREIGN KEY (id_usuario)
REFERENCES CP_USUARIO (id_usuario);


-- ============================================================
-- 87. CP_DETALLE_DEVOLUCION_VENTA
-- ============================================================

ALTER TABLE CP_DETALLE_DEVOLUCION_VENTA
ADD CONSTRAINT FK_CP_DET_DEV_VENTA_DEVOLUCION
FOREIGN KEY (id_devolucion_venta)
REFERENCES CP_DEVOLUCION_VENTA (id_devolucion_venta);

ALTER TABLE CP_DETALLE_DEVOLUCION_VENTA
ADD CONSTRAINT FK_CP_DET_DEV_VENTA_LOTE
FOREIGN KEY (id_detalle_venta_lote)
REFERENCES CP_DETALLE_VENTA_LOTE (id_detalle_venta_lote);

ALTER TABLE CP_DETALLE_DEVOLUCION_VENTA
ADD CONSTRAINT FK_CP_DET_DEV_VENTA_MOTIVO
FOREIGN KEY (id_motivo_devolucion)
REFERENCES CP_MOTIVO_DEVOLUCION (id_motivo_devolucion);


-- ============================================================
-- 88. CP_NOTA_CREDITO_CLIENTE
-- ============================================================

ALTER TABLE CP_NOTA_CREDITO_CLIENTE
ADD CONSTRAINT FK_CP_NOTA_CRED_CLIENTE_DEV
FOREIGN KEY (id_devolucion_venta)
REFERENCES CP_DEVOLUCION_VENTA (id_devolucion_venta);


-- ============================================================
-- 89. CP_DEVOLUCION_COMPRA
-- ============================================================

ALTER TABLE CP_DEVOLUCION_COMPRA
ADD CONSTRAINT FK_CP_DEV_COMPRA_FACTURA
FOREIGN KEY (id_factura_compra)
REFERENCES CP_FACTURA_COMPRA (id_factura_compra);

ALTER TABLE CP_DEVOLUCION_COMPRA
ADD CONSTRAINT FK_CP_DEV_COMPRA_ESTADO
FOREIGN KEY (id_estado_devolucion)
REFERENCES CP_ESTADO_DEVOLUCION (id_estado_devolucion);

ALTER TABLE CP_DEVOLUCION_COMPRA
ADD CONSTRAINT FK_CP_DEV_COMPRA_USUARIO
FOREIGN KEY (id_usuario)
REFERENCES CP_USUARIO (id_usuario);


-- ============================================================
-- 90. CP_DETALLE_DEVOLUCION_COMPRA
-- ============================================================

ALTER TABLE CP_DETALLE_DEVOLUCION_COMPRA
ADD CONSTRAINT FK_CP_DET_DEV_COMPRA_DEV
FOREIGN KEY (id_devolucion_compra)
REFERENCES CP_DEVOLUCION_COMPRA (id_devolucion_compra);

ALTER TABLE CP_DETALLE_DEVOLUCION_COMPRA
ADD CONSTRAINT FK_CP_DET_DEV_COMPRA_LOTE
FOREIGN KEY (id_lote_producto)
REFERENCES CP_LOTE_PRODUCTO (id_lote_producto);

ALTER TABLE CP_DETALLE_DEVOLUCION_COMPRA
ADD CONSTRAINT FK_CP_DET_DEV_COMPRA_MOTIVO
FOREIGN KEY (id_motivo_devolucion)
REFERENCES CP_MOTIVO_DEVOLUCION (id_motivo_devolucion);


-- ============================================================
-- 91. CP_NOTA_CREDITO_PROVEEDOR
-- ============================================================

ALTER TABLE CP_NOTA_CREDITO_PROVEEDOR
ADD CONSTRAINT FK_CP_NOTA_CRED_PROV_DEV
FOREIGN KEY (id_devolucion_compra)
REFERENCES CP_DEVOLUCION_COMPRA (id_devolucion_compra);

-- ============================================================
-- 92. CP_BITACORA_PRECIO
-- ============================================================

ALTER TABLE CP_BITACORA_PRECIO
ADD CONSTRAINT FK_CP_BIT_PRECIO_PROD_NEG
FOREIGN KEY (id_producto_negocio)
REFERENCES CP_PRODUCTO_NEGOCIO (id_producto_negocio);

ALTER TABLE CP_BITACORA_PRECIO
ADD CONSTRAINT FK_CP_BIT_PRECIO_USUARIO
FOREIGN KEY (id_usuario)
REFERENCES CP_USUARIO (id_usuario);

ALTER TABLE CP_BITACORA_PRECIO
ADD CONSTRAINT FK_CP_BIT_PRECIO_OPERACION
FOREIGN KEY (id_tipo_operacion)
REFERENCES CP_TIPO_OPERACION (id_tipo_operacion);


-- ============================================================
-- 93. CP_BITACORA_INVENTARIO
-- ============================================================

ALTER TABLE CP_BITACORA_INVENTARIO
ADD CONSTRAINT FK_CP_BIT_INV_ALMACEN
FOREIGN KEY (id_almacen)
REFERENCES CP_ALMACEN (id_almacen);

ALTER TABLE CP_BITACORA_INVENTARIO
ADD CONSTRAINT FK_CP_BIT_INV_LOTE
FOREIGN KEY (id_lote_producto)
REFERENCES CP_LOTE_PRODUCTO (id_lote_producto);

ALTER TABLE CP_BITACORA_INVENTARIO
ADD CONSTRAINT FK_CP_BIT_INV_USUARIO
FOREIGN KEY (id_usuario)
REFERENCES CP_USUARIO (id_usuario);

ALTER TABLE CP_BITACORA_INVENTARIO
ADD CONSTRAINT FK_CP_BIT_INV_OPERACION
FOREIGN KEY (id_tipo_operacion)
REFERENCES CP_TIPO_OPERACION (id_tipo_operacion);


-- ============================================================
-- 94. CP_BITACORA_TRASLADO
-- ============================================================

ALTER TABLE CP_BITACORA_TRASLADO
ADD CONSTRAINT FK_CP_BIT_TRAS_TRASLADO
FOREIGN KEY (id_traslado)
REFERENCES CP_TRASLADO (id_traslado);

ALTER TABLE CP_BITACORA_TRASLADO
ADD CONSTRAINT FK_CP_BIT_TRAS_USUARIO
FOREIGN KEY (id_usuario)
REFERENCES CP_USUARIO (id_usuario);

ALTER TABLE CP_BITACORA_TRASLADO
ADD CONSTRAINT FK_CP_BIT_TRAS_OPERACION
FOREIGN KEY (id_tipo_operacion)
REFERENCES CP_TIPO_OPERACION (id_tipo_operacion);

ALTER TABLE CP_BITACORA_TRASLADO
ADD CONSTRAINT FK_CP_BIT_TRAS_EST_ANT
FOREIGN KEY (id_estado_anterior)
REFERENCES CP_ESTADO_TRASLADO (id_estado_traslado);

ALTER TABLE CP_BITACORA_TRASLADO
ADD CONSTRAINT FK_CP_BIT_TRAS_EST_NUEVO
FOREIGN KEY (id_estado_nuevo)
REFERENCES CP_ESTADO_TRASLADO (id_estado_traslado);


-- ============================================================
-- 95. CP_BITACORA_VENTA
-- ============================================================

ALTER TABLE CP_BITACORA_VENTA
ADD CONSTRAINT FK_CP_BIT_VENTA_FACTURA
FOREIGN KEY (id_factura_venta)
REFERENCES CP_FACTURA_VENTA (id_factura_venta);

ALTER TABLE CP_BITACORA_VENTA
ADD CONSTRAINT FK_CP_BIT_VENTA_USUARIO
FOREIGN KEY (id_usuario)
REFERENCES CP_USUARIO (id_usuario);

ALTER TABLE CP_BITACORA_VENTA
ADD CONSTRAINT FK_CP_BIT_VENTA_OPERACION
FOREIGN KEY (id_tipo_operacion)
REFERENCES CP_TIPO_OPERACION (id_tipo_operacion);

ALTER TABLE CP_BITACORA_VENTA
ADD CONSTRAINT FK_CP_BIT_VENTA_EST_ANT
FOREIGN KEY (id_estado_anterior)
REFERENCES CP_ESTADO_FACTURA_VENTA (id_estado_factura_venta);

ALTER TABLE CP_BITACORA_VENTA
ADD CONSTRAINT FK_CP_BIT_VENTA_EST_NUEVO
FOREIGN KEY (id_estado_nuevo)
REFERENCES CP_ESTADO_FACTURA_VENTA (id_estado_factura_venta);


-- ============================================================
-- 96. CP_BITACORA_CREDITO_CLIENTE
-- ============================================================

ALTER TABLE CP_BITACORA_CREDITO_CLIENTE
ADD CONSTRAINT FK_CP_BIT_CRED_CLI_CREDITO
FOREIGN KEY (id_credito_cliente)
REFERENCES CP_CREDITO_CLIENTE (id_credito_cliente);

ALTER TABLE CP_BITACORA_CREDITO_CLIENTE
ADD CONSTRAINT FK_CP_BIT_CRED_CLI_USUARIO
FOREIGN KEY (id_usuario)
REFERENCES CP_USUARIO (id_usuario);

ALTER TABLE CP_BITACORA_CREDITO_CLIENTE
ADD CONSTRAINT FK_CP_BIT_CRED_CLI_OPERACION
FOREIGN KEY (id_tipo_operacion)
REFERENCES CP_TIPO_OPERACION (id_tipo_operacion);


-- ============================================================
-- 97. CP_BITACORA_CREDITO_PROVEEDOR
-- ============================================================

ALTER TABLE CP_BITACORA_CREDITO_PROVEEDOR
ADD CONSTRAINT FK_CP_BIT_CRED_PROV_CREDITO
FOREIGN KEY (id_credito_proveedor)
REFERENCES CP_CREDITO_PROVEEDOR (id_credito_proveedor);

ALTER TABLE CP_BITACORA_CREDITO_PROVEEDOR
ADD CONSTRAINT FK_CP_BIT_CRED_PROV_USUARIO
FOREIGN KEY (id_usuario)
REFERENCES CP_USUARIO (id_usuario);

ALTER TABLE CP_BITACORA_CREDITO_PROVEEDOR
ADD CONSTRAINT FK_CP_BIT_CRED_PROV_OPERACION
FOREIGN KEY (id_tipo_operacion)
REFERENCES CP_TIPO_OPERACION (id_tipo_operacion);


-- ============================================================
-- 98. CP_BITACORA_DEVOLUCION_VENTA
-- ============================================================

ALTER TABLE CP_BITACORA_DEVOLUCION_VENTA
ADD CONSTRAINT FK_CP_BIT_DEV_VENTA_DEV
FOREIGN KEY (id_devolucion_venta)
REFERENCES CP_DEVOLUCION_VENTA (id_devolucion_venta);

ALTER TABLE CP_BITACORA_DEVOLUCION_VENTA
ADD CONSTRAINT FK_CP_BIT_DEV_VENTA_USUARIO
FOREIGN KEY (id_usuario)
REFERENCES CP_USUARIO (id_usuario);

ALTER TABLE CP_BITACORA_DEVOLUCION_VENTA
ADD CONSTRAINT FK_CP_BIT_DEV_VENTA_OPERACION
FOREIGN KEY (id_tipo_operacion)
REFERENCES CP_TIPO_OPERACION (id_tipo_operacion);

ALTER TABLE CP_BITACORA_DEVOLUCION_VENTA
ADD CONSTRAINT FK_CP_BIT_DEV_VENTA_EST_ANT
FOREIGN KEY (id_estado_anterior)
REFERENCES CP_ESTADO_DEVOLUCION (id_estado_devolucion);

ALTER TABLE CP_BITACORA_DEVOLUCION_VENTA
ADD CONSTRAINT FK_CP_BIT_DEV_VENTA_EST_NUEVO
FOREIGN KEY (id_estado_nuevo)
REFERENCES CP_ESTADO_DEVOLUCION (id_estado_devolucion);


-- ============================================================
-- 99. CP_BITACORA_DEVOLUCION_COMPRA
-- ============================================================

ALTER TABLE CP_BITACORA_DEVOLUCION_COMPRA
ADD CONSTRAINT FK_CP_BIT_DEV_COMPRA_DEV
FOREIGN KEY (id_devolucion_compra)
REFERENCES CP_DEVOLUCION_COMPRA (id_devolucion_compra);

ALTER TABLE CP_BITACORA_DEVOLUCION_COMPRA
ADD CONSTRAINT FK_CP_BIT_DEV_COMPRA_USUARIO
FOREIGN KEY (id_usuario)
REFERENCES CP_USUARIO (id_usuario);

ALTER TABLE CP_BITACORA_DEVOLUCION_COMPRA
ADD CONSTRAINT FK_CP_BIT_DEV_COMPRA_OPERACION
FOREIGN KEY (id_tipo_operacion)
REFERENCES CP_TIPO_OPERACION (id_tipo_operacion);

ALTER TABLE CP_BITACORA_DEVOLUCION_COMPRA
ADD CONSTRAINT FK_CP_BIT_DEV_COMPRA_EST_ANT
FOREIGN KEY (id_estado_anterior)
REFERENCES CP_ESTADO_DEVOLUCION (id_estado_devolucion);

ALTER TABLE CP_BITACORA_DEVOLUCION_COMPRA
ADD CONSTRAINT FK_CP_BIT_DEV_COMPRA_EST_NUEVO
FOREIGN KEY (id_estado_nuevo)
REFERENCES CP_ESTADO_DEVOLUCION (id_estado_devolucion);


-- ============================================================
-- 100. CP_BITACORA_ACCESO
-- ============================================================

ALTER TABLE CP_BITACORA_ACCESO
ADD CONSTRAINT FK_CP_BIT_ACCESO_USUARIO
FOREIGN KEY (id_usuario)
REFERENCES CP_USUARIO (id_usuario);