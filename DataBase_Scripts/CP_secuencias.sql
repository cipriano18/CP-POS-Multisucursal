-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- BASE DE DATOS: Oracle 21c
-- SCRIPT: 03_secuencias.sql
-- DESCRIPCION: Creacion de las secuencias del sistema
-- USUARIO: CP_POS
-- ============================================================


-- ============================================================
-- 1. CP_TIPO_NEGOCIO
-- ============================================================

CREATE SEQUENCE SEQ_CP_TIPO_NEGOCIO
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 2. CP_NEGOCIO
-- ============================================================

CREATE SEQUENCE SEQ_CP_NEGOCIO
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 3. CP_ESTADO
-- ============================================================

CREATE SEQUENCE SEQ_CP_ESTADO
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 4. CP_TIPO_OPERACION
-- ============================================================

CREATE SEQUENCE SEQ_CP_TIPO_OPERACION
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 5. CP_PROVINCIA
-- ============================================================

CREATE SEQUENCE SEQ_CP_PROVINCIA
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 6. CP_CANTON
-- ============================================================

CREATE SEQUENCE SEQ_CP_CANTON
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 7. CP_DISTRITO
-- ============================================================

CREATE SEQUENCE SEQ_CP_DISTRITO
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 8. CP_DIRECCION
-- ============================================================

CREATE SEQUENCE SEQ_CP_DIRECCION
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 9. CP_TIPO_DIRECCION
-- ============================================================

CREATE SEQUENCE SEQ_CP_TIPO_DIRECCION
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 10. CP_SUCURSAL
-- ============================================================

CREATE SEQUENCE SEQ_CP_SUCURSAL
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 11. CP_NACIONALIDAD
-- ============================================================

CREATE SEQUENCE SEQ_CP_NACIONALIDAD
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 12. CP_SEXO
-- ============================================================

CREATE SEQUENCE SEQ_CP_SEXO
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 13. CP_ESTADO_CIVIL
-- ============================================================

CREATE SEQUENCE SEQ_CP_ESTADO_CIVIL
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 14. CP_ESCOLARIDAD
-- ============================================================

CREATE SEQUENCE SEQ_CP_ESCOLARIDAD
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 15. CP_TIPO_RESIDENCIA
-- ============================================================

CREATE SEQUENCE SEQ_CP_TIPO_RESIDENCIA
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 16. CP_PERSONA
-- ============================================================

CREATE SEQUENCE SEQ_CP_PERSONA
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 17. CP_TIPO_DE_CONTACTO
-- ============================================================

CREATE SEQUENCE SEQ_CP_TIPO_DE_CONTACTO
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 18. CP_CONTACTO
-- ============================================================

CREATE SEQUENCE SEQ_CP_CONTACTO
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 19. CP_PERSONA_CONTACTO
-- ============================================================

CREATE SEQUENCE SEQ_CP_PERSONA_CONTACTO
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 20. CP_PERSONA_DIRECCION
-- ============================================================

CREATE SEQUENCE SEQ_CP_PERSONA_DIRECCION
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 21. CP_PUESTO
-- ============================================================

CREATE SEQUENCE SEQ_CP_PUESTO
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 22. CP_EMPRESA_LABORAL
-- ============================================================

CREATE SEQUENCE SEQ_CP_EMPRESA_LABORAL
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 23. CP_PERSONA_EMPLEO
-- ============================================================

CREATE SEQUENCE SEQ_CP_PERSONA_EMPLEO
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 24. CP_ROL
-- ============================================================

CREATE SEQUENCE SEQ_CP_ROL
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 25. CP_PERMISO
-- ============================================================

CREATE SEQUENCE SEQ_CP_PERMISO
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 26. CP_ROL_PERMISO
-- ============================================================

CREATE SEQUENCE SEQ_CP_ROL_PERMISO
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 27. CP_USUARIO
-- ============================================================

CREATE SEQUENCE SEQ_CP_USUARIO
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 28. CP_TIPO_ALMACEN
-- ============================================================

CREATE SEQUENCE SEQ_CP_TIPO_ALMACEN
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 29. CP_ALMACEN
-- ============================================================

CREATE SEQUENCE SEQ_CP_ALMACEN
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 30. CP_ESTADO_TRASLADO
-- ============================================================

CREATE SEQUENCE SEQ_CP_ESTADO_TRASLADO
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 31. CP_TRASLADO
-- ============================================================

CREATE SEQUENCE SEQ_CP_TRASLADO
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 32. CP_DETALLE_TRASLADO
-- ============================================================

CREATE SEQUENCE SEQ_CP_DETALLE_TRASLADO
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 33. CP_PROVEEDOR
-- ============================================================

CREATE SEQUENCE SEQ_CP_PROVEEDOR
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 34. CP_PROVEEDOR_DIRECCION
-- ============================================================

CREATE SEQUENCE SEQ_CP_PROVEEDOR_DIRECCION
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 35. CP_PROVEEDOR_CONTACTO
-- ============================================================

CREATE SEQUENCE SEQ_CP_PROVEEDOR_CONTACTO
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 36. CP_FAMILIA_PRODUCTO
-- ============================================================

CREATE SEQUENCE SEQ_CP_FAMILIA_PRODUCTO
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 37. CP_IMPUESTO
-- ============================================================

CREATE SEQUENCE SEQ_CP_IMPUESTO
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 38. CP_PRODUCTO
-- ============================================================

CREATE SEQUENCE SEQ_CP_PRODUCTO
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 39. CP_PRODUCTO_PROVEEDOR
-- ============================================================

CREATE SEQUENCE SEQ_CP_PRODUCTO_PROVEEDOR
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 40. CP_CODIGO_BARRA
-- ============================================================

CREATE SEQUENCE SEQ_CP_CODIGO_BARRA
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 41. CP_PRODUCTO_NEGOCIO
-- ============================================================

CREATE SEQUENCE SEQ_CP_PRODUCTO_NEGOCIO
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 42. CP_ESTADO_FACTURA_COMPRA
-- ============================================================

CREATE SEQUENCE SEQ_CP_ESTADO_FACTURA_COMPRA
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 43. CP_FACTURA_COMPRA
-- ============================================================

CREATE SEQUENCE SEQ_CP_FACTURA_COMPRA
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 44. CP_DETALLE_COMPRA
-- ============================================================

CREATE SEQUENCE SEQ_CP_DETALLE_COMPRA
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 45. CP_LOTE_PRODUCTO
-- ============================================================

CREATE SEQUENCE SEQ_CP_LOTE_PRODUCTO
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 46. CP_INVENTARIO_ALMACEN
-- ============================================================

CREATE SEQUENCE SEQ_CP_INVENTARIO_ALMACEN
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 47. CP_ESTADO_CUENTA_PAGAR
-- ============================================================

CREATE SEQUENCE SEQ_CP_ESTADO_CUENTA_PAGAR
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 48. CP_CUENTA_PAGAR
-- ============================================================

CREATE SEQUENCE SEQ_CP_CUENTA_PAGAR
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 49. CP_TIPO_PAGO
-- ============================================================

CREATE SEQUENCE SEQ_CP_TIPO_PAGO
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 50. CP_ABONO_CUENTA_PAGAR
-- ============================================================

CREATE SEQUENCE SEQ_CP_ABONO_CUENTA_PAGAR
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 51. CP_TIPO_CLIENTE
-- ============================================================

CREATE SEQUENCE SEQ_CP_TIPO_CLIENTE
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 52. CP_ESTADO_CLIENTE
-- ============================================================

CREATE SEQUENCE SEQ_CP_ESTADO_CLIENTE
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 53. CP_CLIENTE
-- ============================================================

CREATE SEQUENCE SEQ_CP_CLIENTE
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 54. CP_CLIENTE_PERSONA
-- ============================================================

CREATE SEQUENCE SEQ_CP_CLIENTE_PERSONA
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 55. CP_CLIENTE_EMPRESA
-- ============================================================

CREATE SEQUENCE SEQ_CP_CLIENTE_EMPRESA
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 56. CP_CLIENTE_EMPRESA_DIRECCION
-- ============================================================

CREATE SEQUENCE SEQ_CP_CLIENTE_EMPRESA_DIRECCION
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 57. CP_CLIENTE_EMPRESA_CONTACTO
-- ============================================================

CREATE SEQUENCE SEQ_CP_CLIENTE_EMPRESA_CONTACTO
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 58. CP_ESTADO_CREDITO
-- ============================================================

CREATE SEQUENCE SEQ_CP_ESTADO_CREDITO
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 59. CP_CREDITO_CLIENTE
-- ============================================================

CREATE SEQUENCE SEQ_CP_CREDITO_CLIENTE
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 60. CP_CREDITO_PROVEEDOR
-- ============================================================

CREATE SEQUENCE SEQ_CP_CREDITO_PROVEEDOR
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 61. CP_ESTADO_CUENTA_COBRAR
-- ============================================================

CREATE SEQUENCE SEQ_CP_ESTADO_CUENTA_COBRAR
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 62. CP_ESTADO_FACTURA_VENTA
-- ============================================================

CREATE SEQUENCE SEQ_CP_ESTADO_FACTURA_VENTA
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 63. CP_FACTURA_VENTA
-- ============================================================

CREATE SEQUENCE SEQ_CP_FACTURA_VENTA
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 64. CP_CUENTA_COBRAR
-- ============================================================

CREATE SEQUENCE SEQ_CP_CUENTA_COBRAR
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 65. CP_ABONO_CUENTA_COBRAR
-- ============================================================

CREATE SEQUENCE SEQ_CP_ABONO_CUENTA_COBRAR
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 66. CP_SERVICIO
-- ============================================================

CREATE SEQUENCE SEQ_CP_SERVICIO
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 67. CP_DETALLE_VENTA_PRODUCTO
-- ============================================================

CREATE SEQUENCE SEQ_CP_DETALLE_VENTA_PRODUCTO
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 68. CP_DETALLE_VENTA_SERVICIO
-- ============================================================

CREATE SEQUENCE SEQ_CP_DETALLE_VENTA_SERVICIO
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 69. CP_DETALLE_VENTA_LOTE
-- ============================================================

CREATE SEQUENCE SEQ_CP_DETALLE_VENTA_LOTE
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 70. CP_PAGO_FACTURA_VENTA
-- ============================================================

CREATE SEQUENCE SEQ_CP_PAGO_FACTURA_VENTA
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 71. CP_ESTADO_PROMOCION
-- ============================================================

CREATE SEQUENCE SEQ_CP_ESTADO_PROMOCION
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 72. CP_PROMOCION
-- ============================================================

CREATE SEQUENCE SEQ_CP_PROMOCION
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 73. CP_ACCION_PROMOCION
-- ============================================================

CREATE SEQUENCE SEQ_CP_ACCION_PROMOCION
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 74. CP_REGLA_PROMOCION
-- ============================================================

CREATE SEQUENCE SEQ_CP_REGLA_PROMOCION
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 75. CP_PROMOCION_PATROCINADOR
-- ============================================================

CREATE SEQUENCE SEQ_CP_PROMOCION_PATROCINADOR
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 76. CP_PROMOCION_PREMIO
-- ============================================================

CREATE SEQUENCE SEQ_CP_PROMOCION_PREMIO
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 77. CP_ESTADO_DESCUENTO
-- ============================================================

CREATE SEQUENCE SEQ_CP_ESTADO_DESCUENTO
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 78. CP_DESCUENTO
-- ============================================================

CREATE SEQUENCE SEQ_CP_DESCUENTO
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 79. CP_DESCUENTO_FAMILIA
-- ============================================================

CREATE SEQUENCE SEQ_CP_DESCUENTO_FAMILIA
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 80. CP_DESCUENTO_PROVEEDOR
-- ============================================================

CREATE SEQUENCE SEQ_CP_DESCUENTO_PROVEEDOR
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;



-- ============================================================
-- 81. CP_DESCUENTO_VENCIMIENTO
-- ============================================================

CREATE SEQUENCE SEQ_CP_DESCUENTO_VENCIMIENTO
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 82. CP_DESCUENTO_FECHA_INGRESO
-- ============================================================

CREATE SEQUENCE SEQ_CP_DESCUENTO_FECHA_INGRESO
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 83. CP_DESCUENTO_APLICADO
-- ============================================================

CREATE SEQUENCE SEQ_CP_DESCUENTO_APLICADO
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 84. CP_ESTADO_DEVOLUCION
-- ============================================================

CREATE SEQUENCE SEQ_CP_ESTADO_DEVOLUCION
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 85. CP_MOTIVO_DEVOLUCION
-- ============================================================

CREATE SEQUENCE SEQ_CP_MOTIVO_DEVOLUCION
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 86. CP_DEVOLUCION_VENTA
-- ============================================================

CREATE SEQUENCE SEQ_CP_DEVOLUCION_VENTA
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 87. CP_DETALLE_DEVOLUCION_VENTA
-- ============================================================

CREATE SEQUENCE SEQ_CP_DETALLE_DEVOLUCION_VENTA
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 88. CP_NOTA_CREDITO_CLIENTE
-- ============================================================

CREATE SEQUENCE SEQ_CP_NOTA_CREDITO_CLIENTE
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 89. CP_DEVOLUCION_COMPRA
-- ============================================================

CREATE SEQUENCE SEQ_CP_DEVOLUCION_COMPRA
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 90. CP_DETALLE_DEVOLUCION_COMPRA
-- ============================================================

CREATE SEQUENCE SEQ_CP_DETALLE_DEVOLUCION_COMPRA
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 91. CP_NOTA_CREDITO_PROVEEDOR
-- ============================================================

CREATE SEQUENCE SEQ_CP_NOTA_CREDITO_PROVEEDOR
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 92. CP_BITACORA_PRECIO
-- ============================================================

CREATE SEQUENCE SEQ_CP_BITACORA_PRECIO
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 93. CP_BITACORA_TRASLADO
-- ============================================================

CREATE SEQUENCE SEQ_CP_BITACORA_TRASLADO
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 94. CP_BITACORA_INVENTARIO
-- ============================================================

CREATE SEQUENCE SEQ_CP_BITACORA_INVENTARIO
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 95. CP_BITACORA_VENTA
-- ============================================================

CREATE SEQUENCE SEQ_CP_BITACORA_VENTA
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 96. CP_BITACORA_CREDITO_CLIENTE
-- ============================================================

CREATE SEQUENCE SEQ_CP_BITACORA_CREDITO_CLIENTE
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 97. CP_BITACORA_CREDITO_PROVEEDOR
-- ============================================================

CREATE SEQUENCE SEQ_CP_BITACORA_CREDITO_PROVEEDOR
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 98. CP_BITACORA_DEVOLUCION_VENTA
-- ============================================================

CREATE SEQUENCE SEQ_CP_BITACORA_DEVOLUCION_VENTA
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 99. CP_BITACORA_DEVOLUCION_COMPRA
-- ============================================================

CREATE SEQUENCE SEQ_CP_BITACORA_DEVOLUCION_COMPRA
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- ============================================================
-- 100. CP_BITACORA_ACCESO
-- ============================================================

CREATE SEQUENCE SEQ_CP_BITACORA_ACCESO
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;
