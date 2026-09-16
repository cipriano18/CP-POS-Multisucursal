-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- BASE DE DATOS: Oracle 21c
-- SCRIPT: 08_comentarios.sql
-- DESCRIPCION: Comentarios de las 100 tablas y sus columnas
-- USUARIO: CP_POS
-- GENERADO A PARTIR DEL 04_tablas.sql ACTUAL
-- ============================================================

-- ============================================================
-- 1. CP_TIPO_NEGOCIO
-- ============================================================

COMMENT ON TABLE CP_TIPO_NEGOCIO IS
'Registra y administra la información correspondiente a tipo negocio dentro del sistema.';

COMMENT ON COLUMN CP_TIPO_NEGOCIO.id_tipo_negocio IS
'Identificador o referencia correspondiente a tipo negocio.';

COMMENT ON COLUMN CP_TIPO_NEGOCIO.nombre_tipo_negocio IS
'Nombre correspondiente a tipo negocio.';

-- ============================================================
-- 2. CP_ESTADO
-- ============================================================

COMMENT ON TABLE CP_ESTADO IS
'Registra y administra la información correspondiente a estado dentro del sistema.';

COMMENT ON COLUMN CP_ESTADO.id_estado IS
'Identificador o referencia correspondiente a estado.';

COMMENT ON COLUMN CP_ESTADO.nombre IS
'Nombre correspondiente a nombre.';

-- ============================================================
-- 3. CP_TIPO_OPERACION
-- ============================================================

COMMENT ON TABLE CP_TIPO_OPERACION IS
'Registra y administra la información correspondiente a tipo operacion dentro del sistema.';

COMMENT ON COLUMN CP_TIPO_OPERACION.id_tipo_operacion IS
'Identificador o referencia correspondiente a tipo operacion.';

COMMENT ON COLUMN CP_TIPO_OPERACION.nombre_tipo_operacion IS
'Nombre correspondiente a tipo operacion.';

-- ============================================================
-- 4. CP_PROVINCIA
-- ============================================================

COMMENT ON TABLE CP_PROVINCIA IS
'Registra y administra la información correspondiente a provincia dentro del sistema.';

COMMENT ON COLUMN CP_PROVINCIA.id_provincia IS
'Identificador o referencia correspondiente a provincia.';

COMMENT ON COLUMN CP_PROVINCIA.nombre IS
'Nombre correspondiente a nombre.';

-- ============================================================
-- 5. CP_CANTON
-- ============================================================

COMMENT ON TABLE CP_CANTON IS
'Registra y administra la información correspondiente a canton dentro del sistema.';

COMMENT ON COLUMN CP_CANTON.id_canton IS
'Identificador o referencia correspondiente a canton.';

COMMENT ON COLUMN CP_CANTON.id_provincia IS
'Identificador o referencia correspondiente a provincia.';

COMMENT ON COLUMN CP_CANTON.nombre IS
'Nombre correspondiente a nombre.';

-- ============================================================
-- 6. CP_DISTRITO
-- ============================================================

COMMENT ON TABLE CP_DISTRITO IS
'Registra y administra la información correspondiente a distrito dentro del sistema.';

COMMENT ON COLUMN CP_DISTRITO.id_distrito IS
'Identificador o referencia correspondiente a distrito.';

COMMENT ON COLUMN CP_DISTRITO.id_canton IS
'Identificador o referencia correspondiente a canton.';

COMMENT ON COLUMN CP_DISTRITO.nombre IS
'Nombre correspondiente a nombre.';

-- ============================================================
-- 7. CP_DIRECCION
-- ============================================================

COMMENT ON TABLE CP_DIRECCION IS
'Registra y administra la información correspondiente a direccion dentro del sistema.';

COMMENT ON COLUMN CP_DIRECCION.id_direccion IS
'Identificador o referencia correspondiente a direccion.';

COMMENT ON COLUMN CP_DIRECCION.id_distrito IS
'Identificador o referencia correspondiente a distrito.';

COMMENT ON COLUMN CP_DIRECCION.otras_senas IS
'Detalle adicional de la dirección.';

-- ============================================================
-- 8. CP_TIPO_DIRECCION
-- ============================================================

COMMENT ON TABLE CP_TIPO_DIRECCION IS
'Registra y administra la información correspondiente a tipo direccion dentro del sistema.';

COMMENT ON COLUMN CP_TIPO_DIRECCION.id_tipo_direccion IS
'Identificador o referencia correspondiente a tipo direccion.';

COMMENT ON COLUMN CP_TIPO_DIRECCION.nombre_tipo_direccion IS
'Nombre correspondiente a tipo direccion.';

-- ============================================================
-- 9. CP_SUCURSAL
-- ============================================================

COMMENT ON TABLE CP_SUCURSAL IS
'Registra y administra la información correspondiente a sucursal dentro del sistema.';

COMMENT ON COLUMN CP_SUCURSAL.id_sucursal IS
'Identificador o referencia correspondiente a sucursal.';

COMMENT ON COLUMN CP_SUCURSAL.id_negocio IS
'Identificador o referencia correspondiente a negocio.';

COMMENT ON COLUMN CP_SUCURSAL.id_direccion IS
'Identificador o referencia correspondiente a direccion.';

COMMENT ON COLUMN CP_SUCURSAL.id_estado IS
'Identificador o referencia correspondiente a estado.';

COMMENT ON COLUMN CP_SUCURSAL.codigo_sucursal IS
'Valor correspondiente a codigo sucursal.';

COMMENT ON COLUMN CP_SUCURSAL.nombre_sucursal IS
'Nombre correspondiente a sucursal.';

-- ============================================================
-- 10. CP_NACIONALIDAD
-- ============================================================

COMMENT ON TABLE CP_NACIONALIDAD IS
'Registra y administra la información correspondiente a nacionalidad dentro del sistema.';

COMMENT ON COLUMN CP_NACIONALIDAD.id_nacionalidad IS
'Identificador o referencia correspondiente a nacionalidad.';

COMMENT ON COLUMN CP_NACIONALIDAD.nombre_nacionalidad IS
'Nombre correspondiente a nacionalidad.';

-- ============================================================
-- 11. CP_SEXO
-- ============================================================

COMMENT ON TABLE CP_SEXO IS
'Registra y administra la información correspondiente a sexo dentro del sistema.';

COMMENT ON COLUMN CP_SEXO.id_sexo IS
'Identificador o referencia correspondiente a sexo.';

COMMENT ON COLUMN CP_SEXO.nombre_sexo IS
'Nombre correspondiente a sexo.';

-- ============================================================
-- 12. CP_ESTADO_CIVIL
-- ============================================================

COMMENT ON TABLE CP_ESTADO_CIVIL IS
'Registra y administra la información correspondiente a estado civil dentro del sistema.';

COMMENT ON COLUMN CP_ESTADO_CIVIL.id_estado_civil IS
'Identificador o referencia correspondiente a estado civil.';

COMMENT ON COLUMN CP_ESTADO_CIVIL.nombre_estado_civil IS
'Nombre correspondiente a estado civil.';

-- ============================================================
-- 13. CP_ESCOLARIDAD
-- ============================================================

COMMENT ON TABLE CP_ESCOLARIDAD IS
'Registra y administra la información correspondiente a escolaridad dentro del sistema.';

COMMENT ON COLUMN CP_ESCOLARIDAD.id_escolaridad IS
'Identificador o referencia correspondiente a escolaridad.';

COMMENT ON COLUMN CP_ESCOLARIDAD.nombre_escolaridad IS
'Nombre correspondiente a escolaridad.';

-- ============================================================
-- 14. CP_TIPO_RESIDENCIA
-- ============================================================

COMMENT ON TABLE CP_TIPO_RESIDENCIA IS
'Registra y administra la información correspondiente a tipo residencia dentro del sistema.';

COMMENT ON COLUMN CP_TIPO_RESIDENCIA.id_tipo_residencia IS
'Identificador o referencia correspondiente a tipo residencia.';

COMMENT ON COLUMN CP_TIPO_RESIDENCIA.nombre_tipo_residencia IS
'Nombre correspondiente a tipo residencia.';

-- ============================================================
-- 15. CP_PERSONA
-- ============================================================

COMMENT ON TABLE CP_PERSONA IS
'Registra y administra la información correspondiente a persona dentro del sistema.';

COMMENT ON COLUMN CP_PERSONA.id_persona IS
'Identificador o referencia correspondiente a persona.';

COMMENT ON COLUMN CP_PERSONA.id_nacionalidad IS
'Identificador o referencia correspondiente a nacionalidad.';

COMMENT ON COLUMN CP_PERSONA.id_estado_civil IS
'Identificador o referencia correspondiente a estado civil.';

COMMENT ON COLUMN CP_PERSONA.id_sexo IS
'Identificador o referencia correspondiente a sexo.';

COMMENT ON COLUMN CP_PERSONA.id_escolaridad IS
'Identificador o referencia correspondiente a escolaridad.';

COMMENT ON COLUMN CP_PERSONA.id_tipo_residencia IS
'Identificador o referencia correspondiente a tipo residencia.';

COMMENT ON COLUMN CP_PERSONA.identificacion IS
'Número de identificación de la persona.';

COMMENT ON COLUMN CP_PERSONA.primer_nombre IS
'Valor correspondiente a primer nombre.';

COMMENT ON COLUMN CP_PERSONA.primer_apellido IS
'Valor correspondiente a primer apellido.';

COMMENT ON COLUMN CP_PERSONA.fecha_nacimiento IS
'Fecha y/o hora correspondiente a fecha nacimiento.';

COMMENT ON COLUMN CP_PERSONA.es_asegurado IS
'Indica con S o N si la persona se encuentra asegurada.';

-- ============================================================
-- 16. CP_TIPO_DE_CONTACTO
-- ============================================================

COMMENT ON TABLE CP_TIPO_DE_CONTACTO IS
'Registra y administra la información correspondiente a tipo de contacto dentro del sistema.';

COMMENT ON COLUMN CP_TIPO_DE_CONTACTO.id_tipo_contacto IS
'Identificador o referencia correspondiente a tipo contacto.';

COMMENT ON COLUMN CP_TIPO_DE_CONTACTO.nombre_tipo_contacto IS
'Nombre correspondiente a tipo contacto.';

-- ============================================================
-- 17. CP_CONTACTO
-- ============================================================

COMMENT ON TABLE CP_CONTACTO IS
'Registra y administra la información correspondiente a contacto dentro del sistema.';

COMMENT ON COLUMN CP_CONTACTO.id_contacto IS
'Identificador o referencia correspondiente a contacto.';

COMMENT ON COLUMN CP_CONTACTO.id_tipo_contacto IS
'Identificador o referencia correspondiente a tipo contacto.';

COMMENT ON COLUMN CP_CONTACTO.valor_contacto IS
'Valor del medio de contacto, como teléfono o correo electrónico.';

-- ============================================================
-- 18. CP_PERSONA_DIRECCION
-- ============================================================

COMMENT ON TABLE CP_PERSONA_DIRECCION IS
'Registra y administra la información correspondiente a persona direccion dentro del sistema.';

COMMENT ON COLUMN CP_PERSONA_DIRECCION.id_persona_direccion IS
'Identificador o referencia correspondiente a persona direccion.';

COMMENT ON COLUMN CP_PERSONA_DIRECCION.id_persona IS
'Identificador o referencia correspondiente a persona.';

COMMENT ON COLUMN CP_PERSONA_DIRECCION.id_direccion IS
'Identificador o referencia correspondiente a direccion.';

COMMENT ON COLUMN CP_PERSONA_DIRECCION.id_tipo_direccion IS
'Identificador o referencia correspondiente a tipo direccion.';

COMMENT ON COLUMN CP_PERSONA_DIRECCION.es_principal IS
'Indica con S o N si el registro corresponde al principal.';

-- ============================================================
-- 19. CP_PERSONA_CONTACTO
-- ============================================================

COMMENT ON TABLE CP_PERSONA_CONTACTO IS
'Registra y administra la información correspondiente a persona contacto dentro del sistema.';

COMMENT ON COLUMN CP_PERSONA_CONTACTO.id_persona_contacto IS
'Identificador o referencia correspondiente a persona contacto.';

COMMENT ON COLUMN CP_PERSONA_CONTACTO.id_persona IS
'Identificador o referencia correspondiente a persona.';

COMMENT ON COLUMN CP_PERSONA_CONTACTO.id_contacto IS
'Identificador o referencia correspondiente a contacto.';

COMMENT ON COLUMN CP_PERSONA_CONTACTO.es_principal IS
'Indica con S o N si el registro corresponde al principal.';

-- ============================================================
-- 20. CP_PUESTO
-- ============================================================

COMMENT ON TABLE CP_PUESTO IS
'Registra y administra la información correspondiente a puesto dentro del sistema.';

COMMENT ON COLUMN CP_PUESTO.id_puesto IS
'Identificador o referencia correspondiente a puesto.';

COMMENT ON COLUMN CP_PUESTO.nombre_puesto IS
'Nombre correspondiente a puesto.';

-- ============================================================
-- 21. CP_EMPRESA_LABORAL
-- ============================================================

COMMENT ON TABLE CP_EMPRESA_LABORAL IS
'Registra y administra la información correspondiente a empresa laboral dentro del sistema.';

COMMENT ON COLUMN CP_EMPRESA_LABORAL.id_empresa_laboral IS
'Identificador o referencia correspondiente a empresa laboral.';

COMMENT ON COLUMN CP_EMPRESA_LABORAL.cedula_juridica IS
'Número de cédula jurídica correspondiente al registro.';

COMMENT ON COLUMN CP_EMPRESA_LABORAL.razon_social IS
'Razón social registrada legalmente.';

-- ============================================================
-- 22. CP_PERSONA_EMPLEO
-- ============================================================

COMMENT ON TABLE CP_PERSONA_EMPLEO IS
'Registra y administra la información correspondiente a persona empleo dentro del sistema.';

COMMENT ON COLUMN CP_PERSONA_EMPLEO.id_persona_empleo IS
'Identificador o referencia correspondiente a persona empleo.';

COMMENT ON COLUMN CP_PERSONA_EMPLEO.id_persona IS
'Identificador o referencia correspondiente a persona.';

COMMENT ON COLUMN CP_PERSONA_EMPLEO.id_puesto IS
'Identificador o referencia correspondiente a puesto.';

COMMENT ON COLUMN CP_PERSONA_EMPLEO.id_empresa_laboral IS
'Identificador o referencia correspondiente a empresa laboral.';

COMMENT ON COLUMN CP_PERSONA_EMPLEO.fecha_ingreso IS
'Fecha y/o hora correspondiente a fecha ingreso.';

-- ============================================================
-- 23. CP_ROL
-- ============================================================

COMMENT ON TABLE CP_ROL IS
'Registra y administra la información correspondiente a rol dentro del sistema.';

COMMENT ON COLUMN CP_ROL.id_rol IS
'Identificador o referencia correspondiente a rol.';

COMMENT ON COLUMN CP_ROL.id_estado IS
'Identificador o referencia correspondiente a estado.';

COMMENT ON COLUMN CP_ROL.nombre_rol IS
'Nombre correspondiente a rol.';

-- ============================================================
-- 24. CP_PERMISO
-- ============================================================

COMMENT ON TABLE CP_PERMISO IS
'Registra y administra la información correspondiente a permiso dentro del sistema.';

COMMENT ON COLUMN CP_PERMISO.id_permiso IS
'Identificador o referencia correspondiente a permiso.';

COMMENT ON COLUMN CP_PERMISO.id_estado IS
'Identificador o referencia correspondiente a estado.';

COMMENT ON COLUMN CP_PERMISO.nombre_permiso IS
'Nombre correspondiente a permiso.';

-- ============================================================
-- 25. CP_ROL_PERMISO
-- ============================================================

COMMENT ON TABLE CP_ROL_PERMISO IS
'Registra y administra la información correspondiente a rol permiso dentro del sistema.';

COMMENT ON COLUMN CP_ROL_PERMISO.id_rol_permiso IS
'Identificador o referencia correspondiente a rol permiso.';

COMMENT ON COLUMN CP_ROL_PERMISO.id_rol IS
'Identificador o referencia correspondiente a rol.';

COMMENT ON COLUMN CP_ROL_PERMISO.id_permiso IS
'Identificador o referencia correspondiente a permiso.';

-- ============================================================
-- 26. CP_USUARIO
-- ============================================================

COMMENT ON TABLE CP_USUARIO IS
'Registra y administra la información correspondiente a usuario dentro del sistema.';

COMMENT ON COLUMN CP_USUARIO.id_usuario IS
'Identificador o referencia correspondiente a usuario.';

COMMENT ON COLUMN CP_USUARIO.id_persona IS
'Identificador o referencia correspondiente a persona.';

COMMENT ON COLUMN CP_USUARIO.id_estado IS
'Identificador o referencia correspondiente a estado.';

COMMENT ON COLUMN CP_USUARIO.id_sucursal IS
'Identificador o referencia correspondiente a sucursal.';

COMMENT ON COLUMN CP_USUARIO.id_rol IS
'Identificador o referencia correspondiente a rol.';

COMMENT ON COLUMN CP_USUARIO.nombre_usuario IS
'Nombre correspondiente a usuario.';

COMMENT ON COLUMN CP_USUARIO.contrasena_hash IS
'Almacena de forma protegida el valor derivado de la contraseña del usuario.';

COMMENT ON COLUMN CP_USUARIO.fecha_creacion IS
'Fecha y/o hora correspondiente a fecha creacion.';

-- ============================================================
-- 27. CP_TIPO_CLIENTE
-- ============================================================

COMMENT ON TABLE CP_TIPO_CLIENTE IS
'Registra y administra la información correspondiente a tipo cliente dentro del sistema.';

COMMENT ON COLUMN CP_TIPO_CLIENTE.id_tipo_cliente IS
'Identificador o referencia correspondiente a tipo cliente.';

COMMENT ON COLUMN CP_TIPO_CLIENTE.nombre_tipo_cliente IS
'Nombre correspondiente a tipo cliente.';

-- ============================================================
-- 28. CP_ESTADO_CLIENTE
-- ============================================================

COMMENT ON TABLE CP_ESTADO_CLIENTE IS
'Registra y administra la información correspondiente a estado cliente dentro del sistema.';

COMMENT ON COLUMN CP_ESTADO_CLIENTE.id_estado_cliente IS
'Identificador o referencia correspondiente a estado cliente.';

COMMENT ON COLUMN CP_ESTADO_CLIENTE.nombre_estado_cliente IS
'Nombre correspondiente a estado cliente.';

-- ============================================================
-- 29. CP_CLIENTE
-- ============================================================

COMMENT ON TABLE CP_CLIENTE IS
'Registra y administra la información correspondiente a cliente dentro del sistema.';

COMMENT ON COLUMN CP_CLIENTE.id_cliente IS
'Identificador o referencia correspondiente a cliente.';

COMMENT ON COLUMN CP_CLIENTE.id_tipo_cliente IS
'Identificador o referencia correspondiente a tipo cliente.';

COMMENT ON COLUMN CP_CLIENTE.id_estado_cliente IS
'Identificador o referencia correspondiente a estado cliente.';

COMMENT ON COLUMN CP_CLIENTE.fecha_ingreso IS
'Fecha y/o hora correspondiente a fecha ingreso.';

COMMENT ON COLUMN CP_CLIENTE.es_cliente_defecto IS
'Indica con S o N si corresponde al cliente por defecto del sistema.';

-- ============================================================
-- 30. CP_CLIENTE_PERSONA
-- ============================================================

COMMENT ON TABLE CP_CLIENTE_PERSONA IS
'Registra y administra la información correspondiente a cliente persona dentro del sistema.';

COMMENT ON COLUMN CP_CLIENTE_PERSONA.id_cliente_persona IS
'Identificador o referencia correspondiente a cliente persona.';

COMMENT ON COLUMN CP_CLIENTE_PERSONA.id_cliente IS
'Identificador o referencia correspondiente a cliente.';

COMMENT ON COLUMN CP_CLIENTE_PERSONA.id_persona IS
'Identificador o referencia correspondiente a persona.';

-- ============================================================
-- 31. CP_CLIENTE_EMPRESA
-- ============================================================

COMMENT ON TABLE CP_CLIENTE_EMPRESA IS
'Registra y administra la información correspondiente a cliente empresa dentro del sistema.';

COMMENT ON COLUMN CP_CLIENTE_EMPRESA.id_cliente_empresa IS
'Identificador o referencia correspondiente a cliente empresa.';

COMMENT ON COLUMN CP_CLIENTE_EMPRESA.id_cliente IS
'Identificador o referencia correspondiente a cliente.';

COMMENT ON COLUMN CP_CLIENTE_EMPRESA.cedula_juridica IS
'Número de cédula jurídica correspondiente al registro.';

COMMENT ON COLUMN CP_CLIENTE_EMPRESA.razon_social IS
'Razón social registrada legalmente.';

-- ============================================================
-- 32. CP_CLIENTE_EMPRESA_DIRECCION
-- ============================================================

COMMENT ON TABLE CP_CLIENTE_EMPRESA_DIRECCION IS
'Registra y administra la información correspondiente a cliente empresa direccion dentro del sistema.';

COMMENT ON COLUMN CP_CLIENTE_EMPRESA_DIRECCION.id_cliente_empresa_direccion IS
'Identificador o referencia correspondiente a cliente empresa direccion.';

COMMENT ON COLUMN CP_CLIENTE_EMPRESA_DIRECCION.id_cliente_empresa IS
'Identificador o referencia correspondiente a cliente empresa.';

COMMENT ON COLUMN CP_CLIENTE_EMPRESA_DIRECCION.id_direccion IS
'Identificador o referencia correspondiente a direccion.';

COMMENT ON COLUMN CP_CLIENTE_EMPRESA_DIRECCION.id_tipo_direccion IS
'Identificador o referencia correspondiente a tipo direccion.';

COMMENT ON COLUMN CP_CLIENTE_EMPRESA_DIRECCION.es_principal IS
'Indica con S o N si el registro corresponde al principal.';

-- ============================================================
-- 33. CP_CLIENTE_EMPRESA_CONTACTO
-- ============================================================

COMMENT ON TABLE CP_CLIENTE_EMPRESA_CONTACTO IS
'Registra y administra la información correspondiente a cliente empresa contacto dentro del sistema.';

COMMENT ON COLUMN CP_CLIENTE_EMPRESA_CONTACTO.id_cliente_empresa_contacto IS
'Identificador o referencia correspondiente a cliente empresa contacto.';

COMMENT ON COLUMN CP_CLIENTE_EMPRESA_CONTACTO.id_cliente_empresa IS
'Identificador o referencia correspondiente a cliente empresa.';

COMMENT ON COLUMN CP_CLIENTE_EMPRESA_CONTACTO.id_contacto IS
'Identificador o referencia correspondiente a contacto.';

COMMENT ON COLUMN CP_CLIENTE_EMPRESA_CONTACTO.es_principal IS
'Indica con S o N si el registro corresponde al principal.';

-- ============================================================
-- 34. CP_PROVEEDOR
-- ============================================================

COMMENT ON TABLE CP_PROVEEDOR IS
'Registra y administra la información correspondiente a proveedor dentro del sistema.';

COMMENT ON COLUMN CP_PROVEEDOR.id_proveedor IS
'Identificador o referencia correspondiente a proveedor.';

COMMENT ON COLUMN CP_PROVEEDOR.id_estado IS
'Identificador o referencia correspondiente a estado.';

COMMENT ON COLUMN CP_PROVEEDOR.cedula_juridica IS
'Número de cédula jurídica correspondiente al registro.';

COMMENT ON COLUMN CP_PROVEEDOR.razon_social IS
'Razón social registrada legalmente.';

COMMENT ON COLUMN CP_PROVEEDOR.fecha_registro IS
'Fecha y/o hora correspondiente a fecha registro.';

-- ============================================================
-- 35. CP_PROVEEDOR_DIRECCION
-- ============================================================

COMMENT ON TABLE CP_PROVEEDOR_DIRECCION IS
'Registra y administra la información correspondiente a proveedor direccion dentro del sistema.';

COMMENT ON COLUMN CP_PROVEEDOR_DIRECCION.id_proveedor_direccion IS
'Identificador o referencia correspondiente a proveedor direccion.';

COMMENT ON COLUMN CP_PROVEEDOR_DIRECCION.id_proveedor IS
'Identificador o referencia correspondiente a proveedor.';

COMMENT ON COLUMN CP_PROVEEDOR_DIRECCION.id_tipo_direccion IS
'Identificador o referencia correspondiente a tipo direccion.';

COMMENT ON COLUMN CP_PROVEEDOR_DIRECCION.id_direccion IS
'Identificador o referencia correspondiente a direccion.';

COMMENT ON COLUMN CP_PROVEEDOR_DIRECCION.es_principal IS
'Indica con S o N si el registro corresponde al principal.';

COMMENT ON COLUMN CP_PROVEEDOR_DIRECCION.fecha_asignacion IS
'Fecha y/o hora correspondiente a fecha asignacion.';

-- ============================================================
-- 36. CP_NEGOCIO
-- ============================================================

COMMENT ON TABLE CP_NEGOCIO IS
'Registra y administra la información correspondiente a negocio dentro del sistema.';

COMMENT ON COLUMN CP_NEGOCIO.id_negocio IS
'Identificador o referencia correspondiente a negocio.';

COMMENT ON COLUMN CP_NEGOCIO.id_tipo_negocio IS
'Identificador o referencia correspondiente a tipo negocio.';

COMMENT ON COLUMN CP_NEGOCIO.id_estado IS
'Identificador o referencia correspondiente a estado.';

COMMENT ON COLUMN CP_NEGOCIO.cedula_juridica IS
'Número de cédula jurídica correspondiente al registro.';

COMMENT ON COLUMN CP_NEGOCIO.nombre_negocio IS
'Nombre correspondiente a negocio.';

COMMENT ON COLUMN CP_NEGOCIO.fecha_registro IS
'Fecha y/o hora correspondiente a fecha registro.';

-- ============================================================
-- 37. CP_PROVEEDOR_CONTACTO
-- ============================================================

COMMENT ON TABLE CP_PROVEEDOR_CONTACTO IS
'Registra y administra la información correspondiente a proveedor contacto dentro del sistema.';

COMMENT ON COLUMN CP_PROVEEDOR_CONTACTO.id_proveedor_contacto IS
'Identificador o referencia correspondiente a proveedor contacto.';

COMMENT ON COLUMN CP_PROVEEDOR_CONTACTO.id_proveedor IS
'Identificador o referencia correspondiente a proveedor.';

COMMENT ON COLUMN CP_PROVEEDOR_CONTACTO.id_contacto IS
'Identificador o referencia correspondiente a contacto.';

COMMENT ON COLUMN CP_PROVEEDOR_CONTACTO.es_principal IS
'Indica con S o N si el registro corresponde al principal.';

-- ============================================================
-- 38. CP_CREDITO_PROVEEDOR
-- ============================================================

COMMENT ON TABLE CP_CREDITO_PROVEEDOR IS
'Registra y administra la información correspondiente a credito proveedor dentro del sistema.';

COMMENT ON COLUMN CP_CREDITO_PROVEEDOR.id_credito_proveedor IS
'Identificador o referencia correspondiente a credito proveedor.';

COMMENT ON COLUMN CP_CREDITO_PROVEEDOR.id_proveedor IS
'Identificador o referencia correspondiente a proveedor.';

COMMENT ON COLUMN CP_CREDITO_PROVEEDOR.id_negocio IS
'Identificador o referencia correspondiente a negocio.';

COMMENT ON COLUMN CP_CREDITO_PROVEEDOR.id_estado_credito IS
'Identificador o referencia correspondiente a estado credito.';

COMMENT ON COLUMN CP_CREDITO_PROVEEDOR.limite_credito IS
'Valor correspondiente a limite credito.';

COMMENT ON COLUMN CP_CREDITO_PROVEEDOR.fecha_autorizacion IS
'Fecha y/o hora correspondiente a fecha autorizacion.';

-- ============================================================
-- 39. CP_FAMILIA_PRODUCTO
-- ============================================================

COMMENT ON TABLE CP_FAMILIA_PRODUCTO IS
'Registra y administra la información correspondiente a familia producto dentro del sistema.';

COMMENT ON COLUMN CP_FAMILIA_PRODUCTO.id_familia_producto IS
'Identificador o referencia correspondiente a familia producto.';

COMMENT ON COLUMN CP_FAMILIA_PRODUCTO.nombre_familia IS
'Nombre correspondiente a familia.';

-- ============================================================
-- 40. CP_IMPUESTO
-- ============================================================

COMMENT ON TABLE CP_IMPUESTO IS
'Registra y administra la información correspondiente a impuesto dentro del sistema.';

COMMENT ON COLUMN CP_IMPUESTO.id_impuesto IS
'Identificador o referencia correspondiente a impuesto.';

COMMENT ON COLUMN CP_IMPUESTO.id_estado IS
'Identificador o referencia correspondiente a estado.';

COMMENT ON COLUMN CP_IMPUESTO.nombre_impuesto IS
'Nombre correspondiente a impuesto.';

COMMENT ON COLUMN CP_IMPUESTO.porcentaje_impuesto IS
'Porcentaje correspondiente a porcentaje impuesto.';

-- ============================================================
-- 41. CP_PRODUCTO
-- ============================================================

COMMENT ON TABLE CP_PRODUCTO IS
'Registra y administra la información correspondiente a producto dentro del sistema.';

COMMENT ON COLUMN CP_PRODUCTO.id_producto IS
'Identificador o referencia correspondiente a producto.';

COMMENT ON COLUMN CP_PRODUCTO.id_familia_producto IS
'Identificador o referencia correspondiente a familia producto.';

COMMENT ON COLUMN CP_PRODUCTO.id_impuesto IS
'Identificador o referencia correspondiente a impuesto.';

COMMENT ON COLUMN CP_PRODUCTO.id_estado IS
'Identificador o referencia correspondiente a estado.';

COMMENT ON COLUMN CP_PRODUCTO.codigo_producto IS
'Valor correspondiente a codigo producto.';

COMMENT ON COLUMN CP_PRODUCTO.nombre_producto IS
'Nombre correspondiente a producto.';

-- ============================================================
-- 42. CP_CODIGO_BARRA
-- ============================================================

COMMENT ON TABLE CP_CODIGO_BARRA IS
'Registra y administra la información correspondiente a codigo barra dentro del sistema.';

COMMENT ON COLUMN CP_CODIGO_BARRA.id_codigo_barra IS
'Identificador o referencia correspondiente a codigo barra.';

COMMENT ON COLUMN CP_CODIGO_BARRA.id_producto IS
'Identificador o referencia correspondiente a producto.';

COMMENT ON COLUMN CP_CODIGO_BARRA.codigo_barra IS
'Valor correspondiente a codigo barra.';

-- ============================================================
-- 43. CP_PRODUCTO_PROVEEDOR
-- ============================================================

COMMENT ON TABLE CP_PRODUCTO_PROVEEDOR IS
'Registra y administra la información correspondiente a producto proveedor dentro del sistema.';

COMMENT ON COLUMN CP_PRODUCTO_PROVEEDOR.id_producto_proveedor IS
'Identificador o referencia correspondiente a producto proveedor.';

COMMENT ON COLUMN CP_PRODUCTO_PROVEEDOR.id_proveedor IS
'Identificador o referencia correspondiente a proveedor.';

COMMENT ON COLUMN CP_PRODUCTO_PROVEEDOR.id_producto IS
'Identificador o referencia correspondiente a producto.';

COMMENT ON COLUMN CP_PRODUCTO_PROVEEDOR.precio_costo_actual IS
'Valor monetario correspondiente a precio costo actual.';

-- ============================================================
-- 44. CP_PRODUCTO_NEGOCIO
-- ============================================================

COMMENT ON TABLE CP_PRODUCTO_NEGOCIO IS
'Registra y administra la información correspondiente a producto negocio dentro del sistema.';

COMMENT ON COLUMN CP_PRODUCTO_NEGOCIO.id_producto_negocio IS
'Identificador o referencia correspondiente a producto negocio.';

COMMENT ON COLUMN CP_PRODUCTO_NEGOCIO.id_producto IS
'Identificador o referencia correspondiente a producto.';

COMMENT ON COLUMN CP_PRODUCTO_NEGOCIO.id_negocio IS
'Identificador o referencia correspondiente a negocio.';

COMMENT ON COLUMN CP_PRODUCTO_NEGOCIO.porcentaje_utilidad IS
'Porcentaje correspondiente a porcentaje utilidad.';

COMMENT ON COLUMN CP_PRODUCTO_NEGOCIO.descuento_maximo IS
'Valor correspondiente a descuento maximo.';

COMMENT ON COLUMN CP_PRODUCTO_NEGOCIO.precio_venta_actual IS
'Valor monetario correspondiente a precio venta actual.';

-- ============================================================
-- 45. CP_LOTE_PRODUCTO
-- ============================================================

COMMENT ON TABLE CP_LOTE_PRODUCTO IS
'Registra y administra la información correspondiente a lote producto dentro del sistema.';

COMMENT ON COLUMN CP_LOTE_PRODUCTO.id_lote_producto IS
'Identificador o referencia correspondiente a lote producto.';

COMMENT ON COLUMN CP_LOTE_PRODUCTO.id_detalle_compra IS
'Identificador o referencia correspondiente a detalle compra.';

COMMENT ON COLUMN CP_LOTE_PRODUCTO.numero_lote IS
'Valor correspondiente a numero lote.';

COMMENT ON COLUMN CP_LOTE_PRODUCTO.cantidad_recibida IS
'Cantidad correspondiente a cantidad recibida.';

COMMENT ON COLUMN CP_LOTE_PRODUCTO.fecha_ingreso IS
'Fecha y/o hora correspondiente a fecha ingreso.';

-- ============================================================
-- 46. CP_TIPO_ALMACEN
-- ============================================================

COMMENT ON TABLE CP_TIPO_ALMACEN IS
'Registra y administra la información correspondiente a tipo almacen dentro del sistema.';

COMMENT ON COLUMN CP_TIPO_ALMACEN.id_tipo_almacen IS
'Identificador o referencia correspondiente a tipo almacen.';

COMMENT ON COLUMN CP_TIPO_ALMACEN.nombre_tipo_almacen IS
'Nombre correspondiente a tipo almacen.';

-- ============================================================
-- 47. CP_ALMACEN
-- ============================================================

COMMENT ON TABLE CP_ALMACEN IS
'Registra y administra la información correspondiente a almacen dentro del sistema.';

COMMENT ON COLUMN CP_ALMACEN.id_almacen IS
'Identificador o referencia correspondiente a almacen.';

COMMENT ON COLUMN CP_ALMACEN.id_tipo_almacen IS
'Identificador o referencia correspondiente a tipo almacen.';

COMMENT ON COLUMN CP_ALMACEN.id_sucursal IS
'Identificador o referencia correspondiente a sucursal.';

COMMENT ON COLUMN CP_ALMACEN.id_estado IS
'Identificador o referencia correspondiente a estado.';

COMMENT ON COLUMN CP_ALMACEN.id_direccion IS
'Identificador o referencia correspondiente a direccion.';

COMMENT ON COLUMN CP_ALMACEN.nombre_almacen IS
'Nombre correspondiente a almacen.';

COMMENT ON COLUMN CP_ALMACEN.fecha_registro IS
'Fecha y/o hora correspondiente a fecha registro.';

-- ============================================================
-- 48. CP_INVENTARIO_ALMACEN
-- ============================================================

COMMENT ON TABLE CP_INVENTARIO_ALMACEN IS
'Registra y administra la información correspondiente a inventario almacen dentro del sistema.';

COMMENT ON COLUMN CP_INVENTARIO_ALMACEN.id_inventario_almacen IS
'Identificador o referencia correspondiente a inventario almacen.';

COMMENT ON COLUMN CP_INVENTARIO_ALMACEN.id_almacen IS
'Identificador o referencia correspondiente a almacen.';

COMMENT ON COLUMN CP_INVENTARIO_ALMACEN.id_lote_producto IS
'Identificador o referencia correspondiente a lote producto.';

COMMENT ON COLUMN CP_INVENTARIO_ALMACEN.cantidad_actual IS
'Cantidad correspondiente a cantidad actual.';

COMMENT ON COLUMN CP_INVENTARIO_ALMACEN.fecha_actualizacion IS
'Fecha y/o hora correspondiente a fecha actualizacion.';

-- ============================================================
-- 49. CP_ESTADO_TRASLADO
-- ============================================================

COMMENT ON TABLE CP_ESTADO_TRASLADO IS
'Registra y administra la información correspondiente a estado traslado dentro del sistema.';

COMMENT ON COLUMN CP_ESTADO_TRASLADO.id_estado_traslado IS
'Identificador o referencia correspondiente a estado traslado.';

COMMENT ON COLUMN CP_ESTADO_TRASLADO.nombre_estado_traslado IS
'Nombre correspondiente a estado traslado.';

-- ============================================================
-- 50. CP_TRASLADO
-- ============================================================

COMMENT ON TABLE CP_TRASLADO IS
'Registra y administra la información correspondiente a traslado dentro del sistema.';

COMMENT ON COLUMN CP_TRASLADO.id_traslado IS
'Identificador o referencia correspondiente a traslado.';

COMMENT ON COLUMN CP_TRASLADO.id_almacen_origen IS
'Identificador o referencia correspondiente a almacen origen.';

COMMENT ON COLUMN CP_TRASLADO.id_almacen_destino IS
'Identificador o referencia correspondiente a almacen destino.';

COMMENT ON COLUMN CP_TRASLADO.id_usuario_solicita IS
'Identificador o referencia correspondiente a usuario solicita.';

COMMENT ON COLUMN CP_TRASLADO.id_estado_traslado IS
'Identificador o referencia correspondiente a estado traslado.';

COMMENT ON COLUMN CP_TRASLADO.fecha_solicitud IS
'Fecha y/o hora correspondiente a fecha solicitud.';

-- ============================================================
-- 51. CP_DETALLE_TRASLADO
-- ============================================================

COMMENT ON TABLE CP_DETALLE_TRASLADO IS
'Registra y administra la información correspondiente a detalle traslado dentro del sistema.';

COMMENT ON COLUMN CP_DETALLE_TRASLADO.id_detalle_traslado IS
'Identificador o referencia correspondiente a detalle traslado.';

COMMENT ON COLUMN CP_DETALLE_TRASLADO.id_traslado IS
'Identificador o referencia correspondiente a traslado.';

COMMENT ON COLUMN CP_DETALLE_TRASLADO.id_lote_producto IS
'Identificador o referencia correspondiente a lote producto.';

COMMENT ON COLUMN CP_DETALLE_TRASLADO.cantidad IS
'Cantidad correspondiente a cantidad.';

-- ============================================================
-- 52. CP_FACTURA_COMPRA
-- ============================================================

COMMENT ON TABLE CP_FACTURA_COMPRA IS
'Registra y administra la información correspondiente a factura compra dentro del sistema.';

COMMENT ON COLUMN CP_FACTURA_COMPRA.id_factura_compra IS
'Identificador o referencia correspondiente a factura compra.';

COMMENT ON COLUMN CP_FACTURA_COMPRA.id_proveedor IS
'Identificador o referencia correspondiente a proveedor.';

COMMENT ON COLUMN CP_FACTURA_COMPRA.id_negocio IS
'Identificador o referencia correspondiente a negocio.';

COMMENT ON COLUMN CP_FACTURA_COMPRA.id_almacen_recepcion IS
'Identificador o referencia correspondiente a almacen recepcion.';

COMMENT ON COLUMN CP_FACTURA_COMPRA.id_usuario IS
'Identificador o referencia correspondiente a usuario.';

COMMENT ON COLUMN CP_FACTURA_COMPRA.id_estado_factura_compra IS
'Identificador o referencia correspondiente a estado factura compra.';

COMMENT ON COLUMN CP_FACTURA_COMPRA.numero_factura IS
'Valor correspondiente a numero factura.';

COMMENT ON COLUMN CP_FACTURA_COMPRA.fecha_emision IS
'Fecha y/o hora correspondiente a fecha emision.';

COMMENT ON COLUMN CP_FACTURA_COMPRA.subtotal IS
'Valor correspondiente a subtotal.';

COMMENT ON COLUMN CP_FACTURA_COMPRA.descuento_total IS
'Valor correspondiente a descuento total.';

COMMENT ON COLUMN CP_FACTURA_COMPRA.impuesto_total IS
'Valor correspondiente a impuesto total.';

COMMENT ON COLUMN CP_FACTURA_COMPRA.total IS
'Valor correspondiente a total.';

-- ============================================================
-- 53. CP_ESTADO_FACTURA_COMPRA
-- ============================================================

COMMENT ON TABLE CP_ESTADO_FACTURA_COMPRA IS
'Registra y administra la información correspondiente a estado factura compra dentro del sistema.';

COMMENT ON COLUMN CP_ESTADO_FACTURA_COMPRA.id_estado_factura_compra IS
'Identificador o referencia correspondiente a estado factura compra.';

COMMENT ON COLUMN CP_ESTADO_FACTURA_COMPRA.nombre_estado_factura IS
'Nombre correspondiente a estado factura.';

-- ============================================================
-- 54. CP_DETALLE_COMPRA
-- ============================================================

COMMENT ON TABLE CP_DETALLE_COMPRA IS
'Registra y administra la información correspondiente a detalle compra dentro del sistema.';

COMMENT ON COLUMN CP_DETALLE_COMPRA.id_detalle_compra IS
'Identificador o referencia correspondiente a detalle compra.';

COMMENT ON COLUMN CP_DETALLE_COMPRA.id_factura_compra IS
'Identificador o referencia correspondiente a factura compra.';

COMMENT ON COLUMN CP_DETALLE_COMPRA.id_producto_proveedor IS
'Identificador o referencia correspondiente a producto proveedor.';

COMMENT ON COLUMN CP_DETALLE_COMPRA.cantidad IS
'Cantidad correspondiente a cantidad.';

COMMENT ON COLUMN CP_DETALLE_COMPRA.precio_costo_unitario IS
'Valor monetario correspondiente a precio costo unitario.';

COMMENT ON COLUMN CP_DETALLE_COMPRA.monto_descuento IS
'Monto correspondiente a monto descuento.';

COMMENT ON COLUMN CP_DETALLE_COMPRA.porcentaje_impuesto IS
'Porcentaje correspondiente a porcentaje impuesto.';

COMMENT ON COLUMN CP_DETALLE_COMPRA.monto_impuesto IS
'Monto correspondiente a monto impuesto.';

COMMENT ON COLUMN CP_DETALLE_COMPRA.subtotal_linea IS
'Valor correspondiente a subtotal linea.';

COMMENT ON COLUMN CP_DETALLE_COMPRA.total_linea IS
'Valor correspondiente a total linea.';

-- ============================================================
-- 55. CP_CUENTA_PAGAR
-- ============================================================

COMMENT ON TABLE CP_CUENTA_PAGAR IS
'Registra y administra la información correspondiente a cuenta pagar dentro del sistema.';

COMMENT ON COLUMN CP_CUENTA_PAGAR.id_cuenta_pagar IS
'Identificador o referencia correspondiente a cuenta pagar.';

COMMENT ON COLUMN CP_CUENTA_PAGAR.id_factura_compra IS
'Identificador o referencia correspondiente a factura compra.';

COMMENT ON COLUMN CP_CUENTA_PAGAR.id_estado_cuenta_pagar IS
'Identificador o referencia correspondiente a estado cuenta pagar.';

COMMENT ON COLUMN CP_CUENTA_PAGAR.fecha_creacion IS
'Fecha y/o hora correspondiente a fecha creacion.';

COMMENT ON COLUMN CP_CUENTA_PAGAR.fecha_vencimiento IS
'Fecha y/o hora correspondiente a fecha vencimiento.';

-- ============================================================
-- 56. CP_ESTADO_CUENTA_PAGAR
-- ============================================================

COMMENT ON TABLE CP_ESTADO_CUENTA_PAGAR IS
'Registra y administra la información correspondiente a estado cuenta pagar dentro del sistema.';

COMMENT ON COLUMN CP_ESTADO_CUENTA_PAGAR.id_estado_cuenta_pagar IS
'Identificador o referencia correspondiente a estado cuenta pagar.';

COMMENT ON COLUMN CP_ESTADO_CUENTA_PAGAR.nombre_estado_cuenta_pagar IS
'Nombre correspondiente a estado cuenta pagar.';

-- ============================================================
-- 57. CP_ABONO_CUENTA_PAGAR
-- ============================================================

COMMENT ON TABLE CP_ABONO_CUENTA_PAGAR IS
'Registra y administra la información correspondiente a abono cuenta pagar dentro del sistema.';

COMMENT ON COLUMN CP_ABONO_CUENTA_PAGAR.id_abono_cuenta_pagar IS
'Identificador o referencia correspondiente a abono cuenta pagar.';

COMMENT ON COLUMN CP_ABONO_CUENTA_PAGAR.id_cuenta_pagar IS
'Identificador o referencia correspondiente a cuenta pagar.';

COMMENT ON COLUMN CP_ABONO_CUENTA_PAGAR.id_tipo_pago IS
'Identificador o referencia correspondiente a tipo pago.';

COMMENT ON COLUMN CP_ABONO_CUENTA_PAGAR.id_usuario IS
'Identificador o referencia correspondiente a usuario.';

COMMENT ON COLUMN CP_ABONO_CUENTA_PAGAR.monto_abono IS
'Monto correspondiente a monto abono.';

COMMENT ON COLUMN CP_ABONO_CUENTA_PAGAR.fecha_abono IS
'Fecha y/o hora correspondiente a fecha abono.';

-- ============================================================
-- 58. CP_SERVICIO
-- ============================================================

COMMENT ON TABLE CP_SERVICIO IS
'Registra y administra la información correspondiente a servicio dentro del sistema.';

COMMENT ON COLUMN CP_SERVICIO.id_servicio IS
'Identificador o referencia correspondiente a servicio.';

COMMENT ON COLUMN CP_SERVICIO.id_negocio IS
'Identificador o referencia correspondiente a negocio.';

COMMENT ON COLUMN CP_SERVICIO.id_impuesto IS
'Identificador o referencia correspondiente a impuesto.';

COMMENT ON COLUMN CP_SERVICIO.id_estado IS
'Identificador o referencia correspondiente a estado.';

COMMENT ON COLUMN CP_SERVICIO.codigo_servicio IS
'Valor correspondiente a codigo servicio.';

COMMENT ON COLUMN CP_SERVICIO.nombre_servicio IS
'Nombre correspondiente a servicio.';

COMMENT ON COLUMN CP_SERVICIO.precio_servicio IS
'Valor monetario correspondiente a precio servicio.';

-- ============================================================
-- 59. CP_FACTURA_VENTA
-- ============================================================

COMMENT ON TABLE CP_FACTURA_VENTA IS
'Registra y administra la información correspondiente a factura venta dentro del sistema.';

COMMENT ON COLUMN CP_FACTURA_VENTA.id_factura_venta IS
'Identificador o referencia correspondiente a factura venta.';

COMMENT ON COLUMN CP_FACTURA_VENTA.id_cliente IS
'Identificador o referencia correspondiente a cliente.';

COMMENT ON COLUMN CP_FACTURA_VENTA.id_sucursal IS
'Identificador o referencia correspondiente a sucursal.';

COMMENT ON COLUMN CP_FACTURA_VENTA.id_usuario IS
'Identificador o referencia correspondiente a usuario.';

COMMENT ON COLUMN CP_FACTURA_VENTA.id_estado_factura_venta IS
'Identificador o referencia correspondiente a estado factura venta.';

COMMENT ON COLUMN CP_FACTURA_VENTA.numero_factura IS
'Valor correspondiente a numero factura.';

COMMENT ON COLUMN CP_FACTURA_VENTA.fecha_emision IS
'Fecha y/o hora correspondiente a fecha emision.';

COMMENT ON COLUMN CP_FACTURA_VENTA.subtotal IS
'Valor correspondiente a subtotal.';

COMMENT ON COLUMN CP_FACTURA_VENTA.descuento_total IS
'Valor correspondiente a descuento total.';

COMMENT ON COLUMN CP_FACTURA_VENTA.impuesto_total IS
'Valor correspondiente a impuesto total.';

COMMENT ON COLUMN CP_FACTURA_VENTA.total IS
'Valor correspondiente a total.';

-- ============================================================
-- 60. CP_ESTADO_FACTURA_VENTA
-- ============================================================

COMMENT ON TABLE CP_ESTADO_FACTURA_VENTA IS
'Registra y administra la información correspondiente a estado factura venta dentro del sistema.';

COMMENT ON COLUMN CP_ESTADO_FACTURA_VENTA.id_estado_factura_venta IS
'Identificador o referencia correspondiente a estado factura venta.';

COMMENT ON COLUMN CP_ESTADO_FACTURA_VENTA.nombre_estado_factura IS
'Nombre correspondiente a estado factura.';

-- ============================================================
-- 61. CP_DETALLE_VENTA_PRODUCTO
-- ============================================================

COMMENT ON TABLE CP_DETALLE_VENTA_PRODUCTO IS
'Registra y administra la información correspondiente a detalle venta producto dentro del sistema.';

COMMENT ON COLUMN CP_DETALLE_VENTA_PRODUCTO.id_detalle_venta_producto IS
'Identificador o referencia correspondiente a detalle venta producto.';

COMMENT ON COLUMN CP_DETALLE_VENTA_PRODUCTO.id_factura_venta IS
'Identificador o referencia correspondiente a factura venta.';

COMMENT ON COLUMN CP_DETALLE_VENTA_PRODUCTO.id_producto IS
'Identificador o referencia correspondiente a producto.';

COMMENT ON COLUMN CP_DETALLE_VENTA_PRODUCTO.cantidad IS
'Cantidad correspondiente a cantidad.';

COMMENT ON COLUMN CP_DETALLE_VENTA_PRODUCTO.precio_unitario IS
'Valor monetario correspondiente a precio unitario.';

COMMENT ON COLUMN CP_DETALLE_VENTA_PRODUCTO.porcentaje_descuento IS
'Porcentaje correspondiente a porcentaje descuento.';

COMMENT ON COLUMN CP_DETALLE_VENTA_PRODUCTO.monto_descuento IS
'Monto correspondiente a monto descuento.';

COMMENT ON COLUMN CP_DETALLE_VENTA_PRODUCTO.porcentaje_impuesto IS
'Porcentaje correspondiente a porcentaje impuesto.';

COMMENT ON COLUMN CP_DETALLE_VENTA_PRODUCTO.monto_impuesto IS
'Monto correspondiente a monto impuesto.';

COMMENT ON COLUMN CP_DETALLE_VENTA_PRODUCTO.subtotal IS
'Valor correspondiente a subtotal.';

COMMENT ON COLUMN CP_DETALLE_VENTA_PRODUCTO.total IS
'Valor correspondiente a total.';

-- ============================================================
-- 62. CP_DETALLE_VENTA_SERVICIO
-- ============================================================

COMMENT ON TABLE CP_DETALLE_VENTA_SERVICIO IS
'Registra y administra la información correspondiente a detalle venta servicio dentro del sistema.';

COMMENT ON COLUMN CP_DETALLE_VENTA_SERVICIO.id_detalle_venta_servicio IS
'Identificador o referencia correspondiente a detalle venta servicio.';

COMMENT ON COLUMN CP_DETALLE_VENTA_SERVICIO.id_factura_venta IS
'Identificador o referencia correspondiente a factura venta.';

COMMENT ON COLUMN CP_DETALLE_VENTA_SERVICIO.id_servicio IS
'Identificador o referencia correspondiente a servicio.';

COMMENT ON COLUMN CP_DETALLE_VENTA_SERVICIO.cantidad IS
'Cantidad correspondiente a cantidad.';

COMMENT ON COLUMN CP_DETALLE_VENTA_SERVICIO.precio_unitario IS
'Valor monetario correspondiente a precio unitario.';

COMMENT ON COLUMN CP_DETALLE_VENTA_SERVICIO.porcentaje_descuento IS
'Porcentaje correspondiente a porcentaje descuento.';

COMMENT ON COLUMN CP_DETALLE_VENTA_SERVICIO.monto_descuento IS
'Monto correspondiente a monto descuento.';

COMMENT ON COLUMN CP_DETALLE_VENTA_SERVICIO.porcentaje_impuesto IS
'Porcentaje correspondiente a porcentaje impuesto.';

COMMENT ON COLUMN CP_DETALLE_VENTA_SERVICIO.monto_impuesto IS
'Monto correspondiente a monto impuesto.';

COMMENT ON COLUMN CP_DETALLE_VENTA_SERVICIO.subtotal IS
'Valor correspondiente a subtotal.';

COMMENT ON COLUMN CP_DETALLE_VENTA_SERVICIO.total IS
'Valor correspondiente a total.';

-- ============================================================
-- 63. CP_DETALLE_VENTA_LOTE
-- ============================================================

COMMENT ON TABLE CP_DETALLE_VENTA_LOTE IS
'Registra y administra la información correspondiente a detalle venta lote dentro del sistema.';

COMMENT ON COLUMN CP_DETALLE_VENTA_LOTE.id_detalle_venta_lote IS
'Identificador o referencia correspondiente a detalle venta lote.';

COMMENT ON COLUMN CP_DETALLE_VENTA_LOTE.id_detalle_venta_producto IS
'Identificador o referencia correspondiente a detalle venta producto.';

COMMENT ON COLUMN CP_DETALLE_VENTA_LOTE.id_lote_producto IS
'Identificador o referencia correspondiente a lote producto.';

COMMENT ON COLUMN CP_DETALLE_VENTA_LOTE.cantidad IS
'Cantidad correspondiente a cantidad.';

-- ============================================================
-- 64. CP_TIPO_PAGO
-- ============================================================

COMMENT ON TABLE CP_TIPO_PAGO IS
'Registra y administra la información correspondiente a tipo pago dentro del sistema.';

COMMENT ON COLUMN CP_TIPO_PAGO.id_tipo_pago IS
'Identificador o referencia correspondiente a tipo pago.';

COMMENT ON COLUMN CP_TIPO_PAGO.id_estado IS
'Identificador o referencia correspondiente a estado.';

COMMENT ON COLUMN CP_TIPO_PAGO.nombre_tipo_pago IS
'Nombre correspondiente a tipo pago.';

-- ============================================================
-- 65. CP_PAGO_FACTURA_VENTA
-- ============================================================

COMMENT ON TABLE CP_PAGO_FACTURA_VENTA IS
'Registra y administra la información correspondiente a pago factura venta dentro del sistema.';

COMMENT ON COLUMN CP_PAGO_FACTURA_VENTA.id_pago_factura_venta IS
'Identificador o referencia correspondiente a pago factura venta.';

COMMENT ON COLUMN CP_PAGO_FACTURA_VENTA.id_factura_venta IS
'Identificador o referencia correspondiente a factura venta.';

COMMENT ON COLUMN CP_PAGO_FACTURA_VENTA.id_tipo_pago IS
'Identificador o referencia correspondiente a tipo pago.';

COMMENT ON COLUMN CP_PAGO_FACTURA_VENTA.id_usuario IS
'Identificador o referencia correspondiente a usuario.';

COMMENT ON COLUMN CP_PAGO_FACTURA_VENTA.fecha_pago IS
'Fecha y/o hora correspondiente a fecha pago.';

COMMENT ON COLUMN CP_PAGO_FACTURA_VENTA.monto_pago IS
'Monto correspondiente a monto pago.';

-- ============================================================
-- 66. CP_ESTADO_CREDITO
-- ============================================================

COMMENT ON TABLE CP_ESTADO_CREDITO IS
'Registra y administra la información correspondiente a estado credito dentro del sistema.';

COMMENT ON COLUMN CP_ESTADO_CREDITO.id_estado_credito IS
'Identificador o referencia correspondiente a estado credito.';

COMMENT ON COLUMN CP_ESTADO_CREDITO.nombre_estado_credito IS
'Nombre correspondiente a estado credito.';

-- ============================================================
-- 67. CP_CREDITO_CLIENTE
-- ============================================================

COMMENT ON TABLE CP_CREDITO_CLIENTE IS
'Registra y administra la información correspondiente a credito cliente dentro del sistema.';

COMMENT ON COLUMN CP_CREDITO_CLIENTE.id_credito_cliente IS
'Identificador o referencia correspondiente a credito cliente.';

COMMENT ON COLUMN CP_CREDITO_CLIENTE.id_cliente IS
'Identificador o referencia correspondiente a cliente.';

COMMENT ON COLUMN CP_CREDITO_CLIENTE.id_negocio IS
'Identificador o referencia correspondiente a negocio.';

COMMENT ON COLUMN CP_CREDITO_CLIENTE.id_estado_credito IS
'Identificador o referencia correspondiente a estado credito.';

COMMENT ON COLUMN CP_CREDITO_CLIENTE.limite_credito IS
'Valor correspondiente a limite credito.';

COMMENT ON COLUMN CP_CREDITO_CLIENTE.fecha_autorizacion IS
'Fecha y/o hora correspondiente a fecha autorizacion.';

-- ============================================================
-- 68. CP_CUENTA_COBRAR
-- ============================================================

COMMENT ON TABLE CP_CUENTA_COBRAR IS
'Registra y administra la información correspondiente a cuenta cobrar dentro del sistema.';

COMMENT ON COLUMN CP_CUENTA_COBRAR.id_cuenta_cobrar IS
'Identificador o referencia correspondiente a cuenta cobrar.';

COMMENT ON COLUMN CP_CUENTA_COBRAR.id_factura_venta IS
'Identificador o referencia correspondiente a factura venta.';

COMMENT ON COLUMN CP_CUENTA_COBRAR.id_credito_cliente IS
'Identificador o referencia correspondiente a credito cliente.';

COMMENT ON COLUMN CP_CUENTA_COBRAR.id_estado_cuenta_cobrar IS
'Identificador o referencia correspondiente a estado cuenta cobrar.';

COMMENT ON COLUMN CP_CUENTA_COBRAR.fecha_creacion IS
'Fecha y/o hora correspondiente a fecha creacion.';

COMMENT ON COLUMN CP_CUENTA_COBRAR.fecha_vencimiento IS
'Fecha y/o hora correspondiente a fecha vencimiento.';

-- ============================================================
-- 69. CP_ESTADO_CUENTA_COBRAR
-- ============================================================

COMMENT ON TABLE CP_ESTADO_CUENTA_COBRAR IS
'Registra y administra la información correspondiente a estado cuenta cobrar dentro del sistema.';

COMMENT ON COLUMN CP_ESTADO_CUENTA_COBRAR.id_estado_cuenta_cobrar IS
'Identificador o referencia correspondiente a estado cuenta cobrar.';

COMMENT ON COLUMN CP_ESTADO_CUENTA_COBRAR.nombre_estado_cuenta_cobrar IS
'Nombre correspondiente a estado cuenta cobrar.';

-- ============================================================
-- 70. CP_ABONO_CUENTA_COBRAR
-- ============================================================

COMMENT ON TABLE CP_ABONO_CUENTA_COBRAR IS
'Registra y administra la información correspondiente a abono cuenta cobrar dentro del sistema.';

COMMENT ON COLUMN CP_ABONO_CUENTA_COBRAR.id_abono_cuenta_cobrar IS
'Identificador o referencia correspondiente a abono cuenta cobrar.';

COMMENT ON COLUMN CP_ABONO_CUENTA_COBRAR.id_cuenta_cobrar IS
'Identificador o referencia correspondiente a cuenta cobrar.';

COMMENT ON COLUMN CP_ABONO_CUENTA_COBRAR.id_tipo_pago IS
'Identificador o referencia correspondiente a tipo pago.';

COMMENT ON COLUMN CP_ABONO_CUENTA_COBRAR.id_usuario IS
'Identificador o referencia correspondiente a usuario.';

COMMENT ON COLUMN CP_ABONO_CUENTA_COBRAR.monto_abono IS
'Monto correspondiente a monto abono.';

COMMENT ON COLUMN CP_ABONO_CUENTA_COBRAR.fecha_abono IS
'Fecha y/o hora correspondiente a fecha abono.';

-- ============================================================
-- 71. CP_ESTADO_PROMOCION
-- ============================================================

COMMENT ON TABLE CP_ESTADO_PROMOCION IS
'Registra y administra la información correspondiente a estado promocion dentro del sistema.';

COMMENT ON COLUMN CP_ESTADO_PROMOCION.id_estado_promocion IS
'Identificador o referencia correspondiente a estado promocion.';

COMMENT ON COLUMN CP_ESTADO_PROMOCION.nombre_estado_promocion IS
'Nombre correspondiente a estado promocion.';

-- ============================================================
-- 72. CP_PROMOCION
-- ============================================================

COMMENT ON TABLE CP_PROMOCION IS
'Registra y administra la información correspondiente a promocion dentro del sistema.';

COMMENT ON COLUMN CP_PROMOCION.id_promocion IS
'Identificador o referencia correspondiente a promocion.';

COMMENT ON COLUMN CP_PROMOCION.id_estado_promocion IS
'Identificador o referencia correspondiente a estado promocion.';

COMMENT ON COLUMN CP_PROMOCION.id_negocio IS
'Identificador o referencia correspondiente a negocio.';

COMMENT ON COLUMN CP_PROMOCION.nombre_promocion IS
'Nombre correspondiente a promocion.';

COMMENT ON COLUMN CP_PROMOCION.fecha_inicio IS
'Fecha y/o hora correspondiente a fecha inicio.';

-- ============================================================
-- 73. CP_ACCION_PROMOCION
-- ============================================================

COMMENT ON TABLE CP_ACCION_PROMOCION IS
'Registra y administra la información correspondiente a accion promocion dentro del sistema.';

COMMENT ON COLUMN CP_ACCION_PROMOCION.id_accion_promocion IS
'Identificador o referencia correspondiente a accion promocion.';

COMMENT ON COLUMN CP_ACCION_PROMOCION.nombre_accion_promocion IS
'Nombre correspondiente a accion promocion.';

-- ============================================================
-- 74. CP_REGLA_PROMOCION
-- ============================================================

COMMENT ON TABLE CP_REGLA_PROMOCION IS
'Registra y administra la información correspondiente a regla promocion dentro del sistema.';

COMMENT ON COLUMN CP_REGLA_PROMOCION.id_regla_promocion IS
'Identificador o referencia correspondiente a regla promocion.';

COMMENT ON COLUMN CP_REGLA_PROMOCION.id_promocion IS
'Identificador o referencia correspondiente a promocion.';

COMMENT ON COLUMN CP_REGLA_PROMOCION.id_accion_promocion IS
'Identificador o referencia correspondiente a accion promocion.';

COMMENT ON COLUMN CP_REGLA_PROMOCION.cantidad_acciones IS
'Cantidad correspondiente a cantidad acciones.';

-- ============================================================
-- 75. CP_PROMOCION_PATROCINADOR
-- ============================================================

COMMENT ON TABLE CP_PROMOCION_PATROCINADOR IS
'Registra y administra la información correspondiente a promocion patrocinador dentro del sistema.';

COMMENT ON COLUMN CP_PROMOCION_PATROCINADOR.id_promocion_patrocinador IS
'Identificador o referencia correspondiente a promocion patrocinador.';

COMMENT ON COLUMN CP_PROMOCION_PATROCINADOR.id_regla_promocion IS
'Identificador o referencia correspondiente a regla promocion.';

COMMENT ON COLUMN CP_PROMOCION_PATROCINADOR.id_producto IS
'Identificador o referencia correspondiente a producto.';

COMMENT ON COLUMN CP_PROMOCION_PATROCINADOR.cantidad_requerida IS
'Cantidad correspondiente a cantidad requerida.';

-- ============================================================
-- 76. CP_PROMOCION_PREMIO
-- ============================================================

COMMENT ON TABLE CP_PROMOCION_PREMIO IS
'Registra y administra la información correspondiente a promocion premio dentro del sistema.';

COMMENT ON COLUMN CP_PROMOCION_PREMIO.id_promocion_premio IS
'Identificador o referencia correspondiente a promocion premio.';

COMMENT ON COLUMN CP_PROMOCION_PREMIO.id_regla_promocion IS
'Identificador o referencia correspondiente a regla promocion.';

COMMENT ON COLUMN CP_PROMOCION_PREMIO.id_producto_premio IS
'Identificador o referencia correspondiente a producto premio.';

COMMENT ON COLUMN CP_PROMOCION_PREMIO.cantidad_premio IS
'Cantidad correspondiente a cantidad premio.';

-- ============================================================
-- 77. CP_ESTADO_DESCUENTO
-- ============================================================

COMMENT ON TABLE CP_ESTADO_DESCUENTO IS
'Registra y administra la información correspondiente a estado descuento dentro del sistema.';

COMMENT ON COLUMN CP_ESTADO_DESCUENTO.id_estado_descuento IS
'Identificador o referencia correspondiente a estado descuento.';

COMMENT ON COLUMN CP_ESTADO_DESCUENTO.nombre_estado_descuento IS
'Nombre correspondiente a estado descuento.';

-- ============================================================
-- 78. CP_DESCUENTO
-- ============================================================

COMMENT ON TABLE CP_DESCUENTO IS
'Registra y administra la información correspondiente a descuento dentro del sistema.';

COMMENT ON COLUMN CP_DESCUENTO.id_descuento IS
'Identificador o referencia correspondiente a descuento.';

COMMENT ON COLUMN CP_DESCUENTO.id_negocio IS
'Identificador o referencia correspondiente a negocio.';

COMMENT ON COLUMN CP_DESCUENTO.id_estado_descuento IS
'Identificador o referencia correspondiente a estado descuento.';

COMMENT ON COLUMN CP_DESCUENTO.nombre_descuento IS
'Nombre correspondiente a descuento.';

COMMENT ON COLUMN CP_DESCUENTO.porcentaje_descuento IS
'Porcentaje correspondiente a porcentaje descuento.';

COMMENT ON COLUMN CP_DESCUENTO.fecha_inicio IS
'Fecha y/o hora correspondiente a fecha inicio.';

-- ============================================================
-- 79. CP_DESCUENTO_FAMILIA
-- ============================================================

COMMENT ON TABLE CP_DESCUENTO_FAMILIA IS
'Registra y administra la información correspondiente a descuento familia dentro del sistema.';

COMMENT ON COLUMN CP_DESCUENTO_FAMILIA.id_descuento_familia IS
'Identificador o referencia correspondiente a descuento familia.';

COMMENT ON COLUMN CP_DESCUENTO_FAMILIA.id_descuento IS
'Identificador o referencia correspondiente a descuento.';

COMMENT ON COLUMN CP_DESCUENTO_FAMILIA.id_familia_producto IS
'Identificador o referencia correspondiente a familia producto.';

-- ============================================================
-- 80. CP_DESCUENTO_PROVEEDOR
-- ============================================================

COMMENT ON TABLE CP_DESCUENTO_PROVEEDOR IS
'Registra y administra la información correspondiente a descuento proveedor dentro del sistema.';

COMMENT ON COLUMN CP_DESCUENTO_PROVEEDOR.id_descuento_proveedor IS
'Identificador o referencia correspondiente a descuento proveedor.';

COMMENT ON COLUMN CP_DESCUENTO_PROVEEDOR.id_descuento IS
'Identificador o referencia correspondiente a descuento.';

COMMENT ON COLUMN CP_DESCUENTO_PROVEEDOR.id_proveedor IS
'Identificador o referencia correspondiente a proveedor.';

-- ============================================================
-- 81. CP_DESCUENTO_FECHA_INGRESO
-- ============================================================

COMMENT ON TABLE CP_DESCUENTO_FECHA_INGRESO IS
'Registra y administra la información correspondiente a descuento fecha ingreso dentro del sistema.';

COMMENT ON COLUMN CP_DESCUENTO_FECHA_INGRESO.id_descuento_fecha_ingreso IS
'Identificador o referencia correspondiente a descuento fecha ingreso.';

COMMENT ON COLUMN CP_DESCUENTO_FECHA_INGRESO.id_descuento IS
'Identificador o referencia correspondiente a descuento.';

COMMENT ON COLUMN CP_DESCUENTO_FECHA_INGRESO.fecha_ingreso_desde IS
'Fecha y/o hora correspondiente a fecha ingreso desde.';

COMMENT ON COLUMN CP_DESCUENTO_FECHA_INGRESO.fecha_ingreso_hasta IS
'Fecha y/o hora correspondiente a fecha ingreso hasta.';

-- ============================================================
-- 82. CP_DESCUENTO_VENCIMIENTO
-- ============================================================

COMMENT ON TABLE CP_DESCUENTO_VENCIMIENTO IS
'Registra y administra la información correspondiente a descuento vencimiento dentro del sistema.';

COMMENT ON COLUMN CP_DESCUENTO_VENCIMIENTO.id_descuento_vencimiento IS
'Identificador o referencia correspondiente a descuento vencimiento.';

COMMENT ON COLUMN CP_DESCUENTO_VENCIMIENTO.id_descuento IS
'Identificador o referencia correspondiente a descuento.';

COMMENT ON COLUMN CP_DESCUENTO_VENCIMIENTO.dias_antes_vencimiento IS
'Valor correspondiente a dias antes vencimiento.';

-- ============================================================
-- 83. CP_DESCUENTO_APLICADO
-- ============================================================

COMMENT ON TABLE CP_DESCUENTO_APLICADO IS
'Registra y administra la información correspondiente a descuento aplicado dentro del sistema.';

COMMENT ON COLUMN CP_DESCUENTO_APLICADO.id_descuento_aplicado IS
'Identificador o referencia correspondiente a descuento aplicado.';

COMMENT ON COLUMN CP_DESCUENTO_APLICADO.id_detalle_venta_producto IS
'Identificador o referencia correspondiente a detalle venta producto.';

COMMENT ON COLUMN CP_DESCUENTO_APLICADO.id_descuento IS
'Identificador o referencia correspondiente a descuento.';

COMMENT ON COLUMN CP_DESCUENTO_APLICADO.monto_aplicado IS
'Monto correspondiente a monto aplicado.';

-- ============================================================
-- 84. CP_ESTADO_DEVOLUCION
-- ============================================================

COMMENT ON TABLE CP_ESTADO_DEVOLUCION IS
'Registra y administra la información correspondiente a estado devolucion dentro del sistema.';

COMMENT ON COLUMN CP_ESTADO_DEVOLUCION.id_estado_devolucion IS
'Identificador o referencia correspondiente a estado devolucion.';

COMMENT ON COLUMN CP_ESTADO_DEVOLUCION.nombre_estado_devolucion IS
'Nombre correspondiente a estado devolucion.';

-- ============================================================
-- 85. CP_MOTIVO_DEVOLUCION
-- ============================================================

COMMENT ON TABLE CP_MOTIVO_DEVOLUCION IS
'Registra y administra la información correspondiente a motivo devolucion dentro del sistema.';

COMMENT ON COLUMN CP_MOTIVO_DEVOLUCION.id_motivo_devolucion IS
'Identificador o referencia correspondiente a motivo devolucion.';

COMMENT ON COLUMN CP_MOTIVO_DEVOLUCION.nombre_motivo_devolucion IS
'Nombre correspondiente a motivo devolucion.';

-- ============================================================
-- 86. CP_DEVOLUCION_VENTA
-- ============================================================

COMMENT ON TABLE CP_DEVOLUCION_VENTA IS
'Registra y administra la información correspondiente a devolucion venta dentro del sistema.';

COMMENT ON COLUMN CP_DEVOLUCION_VENTA.id_devolucion_venta IS
'Identificador o referencia correspondiente a devolucion venta.';

COMMENT ON COLUMN CP_DEVOLUCION_VENTA.id_factura_venta IS
'Identificador o referencia correspondiente a factura venta.';

COMMENT ON COLUMN CP_DEVOLUCION_VENTA.id_estado_devolucion IS
'Identificador o referencia correspondiente a estado devolucion.';

COMMENT ON COLUMN CP_DEVOLUCION_VENTA.id_usuario IS
'Identificador o referencia correspondiente a usuario.';

COMMENT ON COLUMN CP_DEVOLUCION_VENTA.fecha_devolucion IS
'Fecha y/o hora correspondiente a fecha devolucion.';

COMMENT ON COLUMN CP_DEVOLUCION_VENTA.monto_total IS
'Monto correspondiente a monto total.';

-- ============================================================
-- 87. CP_DETALLE_DEVOLUCION_VENTA
-- ============================================================

COMMENT ON TABLE CP_DETALLE_DEVOLUCION_VENTA IS
'Registra y administra la información correspondiente a detalle devolucion venta dentro del sistema.';

COMMENT ON COLUMN CP_DETALLE_DEVOLUCION_VENTA.id_detalle_devolucion_venta IS
'Identificador o referencia correspondiente a detalle devolucion venta.';

COMMENT ON COLUMN CP_DETALLE_DEVOLUCION_VENTA.id_devolucion_venta IS
'Identificador o referencia correspondiente a devolucion venta.';

COMMENT ON COLUMN CP_DETALLE_DEVOLUCION_VENTA.id_detalle_venta_lote IS
'Identificador o referencia correspondiente a detalle venta lote.';

COMMENT ON COLUMN CP_DETALLE_DEVOLUCION_VENTA.id_motivo_devolucion IS
'Identificador o referencia correspondiente a motivo devolucion.';

COMMENT ON COLUMN CP_DETALLE_DEVOLUCION_VENTA.cantidad_devuelta IS
'Cantidad correspondiente a cantidad devuelta.';

COMMENT ON COLUMN CP_DETALLE_DEVOLUCION_VENTA.monto_devolucion IS
'Monto correspondiente a monto devolucion.';

-- ============================================================
-- 88. CP_NOTA_CREDITO_CLIENTE
-- ============================================================

COMMENT ON TABLE CP_NOTA_CREDITO_CLIENTE IS
'Registra y administra la información correspondiente a nota credito cliente dentro del sistema.';

COMMENT ON COLUMN CP_NOTA_CREDITO_CLIENTE.id_nota_credito_cliente IS
'Identificador o referencia correspondiente a nota credito cliente.';

COMMENT ON COLUMN CP_NOTA_CREDITO_CLIENTE.id_devolucion_venta IS
'Identificador o referencia correspondiente a devolucion venta.';

COMMENT ON COLUMN CP_NOTA_CREDITO_CLIENTE.numero_nota_credito IS
'Valor correspondiente a numero nota credito.';

COMMENT ON COLUMN CP_NOTA_CREDITO_CLIENTE.fecha_emision IS
'Fecha y/o hora correspondiente a fecha emision.';

COMMENT ON COLUMN CP_NOTA_CREDITO_CLIENTE.monto_nota_credito IS
'Monto correspondiente a monto nota credito.';

-- ============================================================
-- 89. CP_DEVOLUCION_COMPRA
-- ============================================================

COMMENT ON TABLE CP_DEVOLUCION_COMPRA IS
'Registra y administra la información correspondiente a devolucion compra dentro del sistema.';

COMMENT ON COLUMN CP_DEVOLUCION_COMPRA.id_devolucion_compra IS
'Identificador o referencia correspondiente a devolucion compra.';

COMMENT ON COLUMN CP_DEVOLUCION_COMPRA.id_factura_compra IS
'Identificador o referencia correspondiente a factura compra.';

COMMENT ON COLUMN CP_DEVOLUCION_COMPRA.id_estado_devolucion IS
'Identificador o referencia correspondiente a estado devolucion.';

COMMENT ON COLUMN CP_DEVOLUCION_COMPRA.id_usuario IS
'Identificador o referencia correspondiente a usuario.';

COMMENT ON COLUMN CP_DEVOLUCION_COMPRA.fecha_devolucion IS
'Fecha y/o hora correspondiente a fecha devolucion.';

-- ============================================================
-- 90. CP_DETALLE_DEVOLUCION_COMPRA
-- ============================================================

COMMENT ON TABLE CP_DETALLE_DEVOLUCION_COMPRA IS
'Registra y administra la información correspondiente a detalle devolucion compra dentro del sistema.';

COMMENT ON COLUMN CP_DETALLE_DEVOLUCION_COMPRA.id_detalle_devolucion_compra IS
'Identificador o referencia correspondiente a detalle devolucion compra.';

COMMENT ON COLUMN CP_DETALLE_DEVOLUCION_COMPRA.id_devolucion_compra IS
'Identificador o referencia correspondiente a devolucion compra.';

COMMENT ON COLUMN CP_DETALLE_DEVOLUCION_COMPRA.id_lote_producto IS
'Identificador o referencia correspondiente a lote producto.';

COMMENT ON COLUMN CP_DETALLE_DEVOLUCION_COMPRA.id_motivo_devolucion IS
'Identificador o referencia correspondiente a motivo devolucion.';

COMMENT ON COLUMN CP_DETALLE_DEVOLUCION_COMPRA.cantidad IS
'Cantidad correspondiente a cantidad.';

COMMENT ON COLUMN CP_DETALLE_DEVOLUCION_COMPRA.monto_devolucion IS
'Monto correspondiente a monto devolucion.';

-- ============================================================
-- 91. CP_NOTA_CREDITO_PROVEEDOR
-- ============================================================

COMMENT ON TABLE CP_NOTA_CREDITO_PROVEEDOR IS
'Registra y administra la información correspondiente a nota credito proveedor dentro del sistema.';

COMMENT ON COLUMN CP_NOTA_CREDITO_PROVEEDOR.id_nota_credito_proveedor IS
'Identificador o referencia correspondiente a nota credito proveedor.';

COMMENT ON COLUMN CP_NOTA_CREDITO_PROVEEDOR.id_devolucion_compra IS
'Identificador o referencia correspondiente a devolucion compra.';

COMMENT ON COLUMN CP_NOTA_CREDITO_PROVEEDOR.numero_nota_credito IS
'Valor correspondiente a numero nota credito.';

COMMENT ON COLUMN CP_NOTA_CREDITO_PROVEEDOR.fecha_emision IS
'Fecha y/o hora correspondiente a fecha emision.';

COMMENT ON COLUMN CP_NOTA_CREDITO_PROVEEDOR.monto_nota_credito IS
'Monto correspondiente a monto nota credito.';

-- ============================================================
-- 92. CP_BITACORA_PRECIO
-- ============================================================

COMMENT ON TABLE CP_BITACORA_PRECIO IS
'Registra y administra la información correspondiente a bitacora precio dentro del sistema.';

COMMENT ON COLUMN CP_BITACORA_PRECIO.id_bitacora_precio IS
'Identificador único del registro de bitacora precio.';

COMMENT ON COLUMN CP_BITACORA_PRECIO.id_producto_negocio IS
'Identificador o referencia correspondiente a producto negocio.';

COMMENT ON COLUMN CP_BITACORA_PRECIO.id_usuario IS
'Identificador o referencia correspondiente a usuario.';

COMMENT ON COLUMN CP_BITACORA_PRECIO.id_tipo_operacion IS
'Identificador o referencia correspondiente a tipo operacion.';

COMMENT ON COLUMN CP_BITACORA_PRECIO.precio_anterior IS
'Valor monetario correspondiente a precio anterior.';

COMMENT ON COLUMN CP_BITACORA_PRECIO.precio_nuevo IS
'Valor monetario correspondiente a precio nuevo.';

COMMENT ON COLUMN CP_BITACORA_PRECIO.fecha_cambio IS
'Fecha y/o hora correspondiente a fecha cambio.';

-- ============================================================
-- 93. CP_BITACORA_INVENTARIO
-- ============================================================

COMMENT ON TABLE CP_BITACORA_INVENTARIO IS
'Registra y administra la información correspondiente a bitacora inventario dentro del sistema.';

COMMENT ON COLUMN CP_BITACORA_INVENTARIO.id_bitacora_inventario IS
'Identificador único del registro de bitacora inventario.';

COMMENT ON COLUMN CP_BITACORA_INVENTARIO.id_almacen IS
'Identificador o referencia correspondiente a almacen.';

COMMENT ON COLUMN CP_BITACORA_INVENTARIO.id_lote_producto IS
'Identificador o referencia correspondiente a lote producto.';

COMMENT ON COLUMN CP_BITACORA_INVENTARIO.id_usuario IS
'Identificador o referencia correspondiente a usuario.';

COMMENT ON COLUMN CP_BITACORA_INVENTARIO.id_tipo_operacion IS
'Identificador o referencia correspondiente a tipo operacion.';

COMMENT ON COLUMN CP_BITACORA_INVENTARIO.cantidad_anterior IS
'Cantidad correspondiente a cantidad anterior.';

COMMENT ON COLUMN CP_BITACORA_INVENTARIO.cantidad_nueva IS
'Cantidad correspondiente a cantidad nueva.';

COMMENT ON COLUMN CP_BITACORA_INVENTARIO.fecha_operacion IS
'Fecha y/o hora correspondiente a fecha operacion.';

COMMENT ON COLUMN CP_BITACORA_INVENTARIO.tabla_referencia IS
'Valor correspondiente a tabla referencia.';

COMMENT ON COLUMN CP_BITACORA_INVENTARIO.id_referencia IS
'Identificador o referencia correspondiente a referencia.';

-- ============================================================
-- 94. CP_BITACORA_TRASLADO
-- ============================================================

COMMENT ON TABLE CP_BITACORA_TRASLADO IS
'Registra y administra la información correspondiente a bitacora traslado dentro del sistema.';

COMMENT ON COLUMN CP_BITACORA_TRASLADO.id_bitacora_traslado IS
'Identificador único del registro de bitacora traslado.';

COMMENT ON COLUMN CP_BITACORA_TRASLADO.id_traslado IS
'Identificador o referencia correspondiente a traslado.';

COMMENT ON COLUMN CP_BITACORA_TRASLADO.id_usuario IS
'Identificador o referencia correspondiente a usuario.';

COMMENT ON COLUMN CP_BITACORA_TRASLADO.id_tipo_operacion IS
'Identificador o referencia correspondiente a tipo operacion.';

COMMENT ON COLUMN CP_BITACORA_TRASLADO.id_estado_anterior IS
'Identificador o referencia correspondiente a estado anterior.';

COMMENT ON COLUMN CP_BITACORA_TRASLADO.id_estado_nuevo IS
'Identificador o referencia correspondiente a estado nuevo.';

COMMENT ON COLUMN CP_BITACORA_TRASLADO.fecha_cambio IS
'Fecha y/o hora correspondiente a fecha cambio.';

-- ============================================================
-- 95. CP_BITACORA_VENTA
-- ============================================================

COMMENT ON TABLE CP_BITACORA_VENTA IS
'Registra y administra la información correspondiente a bitacora venta dentro del sistema.';

COMMENT ON COLUMN CP_BITACORA_VENTA.id_bitacora_venta IS
'Identificador único del registro de bitacora venta.';

COMMENT ON COLUMN CP_BITACORA_VENTA.id_factura_venta IS
'Identificador o referencia correspondiente a factura venta.';

COMMENT ON COLUMN CP_BITACORA_VENTA.id_usuario IS
'Identificador o referencia correspondiente a usuario.';

COMMENT ON COLUMN CP_BITACORA_VENTA.id_tipo_operacion IS
'Identificador o referencia correspondiente a tipo operacion.';

COMMENT ON COLUMN CP_BITACORA_VENTA.id_estado_anterior IS
'Identificador o referencia correspondiente a estado anterior.';

COMMENT ON COLUMN CP_BITACORA_VENTA.id_estado_nuevo IS
'Identificador o referencia correspondiente a estado nuevo.';

COMMENT ON COLUMN CP_BITACORA_VENTA.total_anterior IS
'Valor correspondiente a total anterior.';

COMMENT ON COLUMN CP_BITACORA_VENTA.total_nuevo IS
'Valor correspondiente a total nuevo.';

COMMENT ON COLUMN CP_BITACORA_VENTA.fecha_operacion IS
'Fecha y/o hora correspondiente a fecha operacion.';

-- ============================================================
-- 96. CP_BITACORA_CREDITO_CLIENTE
-- ============================================================

COMMENT ON TABLE CP_BITACORA_CREDITO_CLIENTE IS
'Registra y administra la información correspondiente a bitacora credito cliente dentro del sistema.';

COMMENT ON COLUMN CP_BITACORA_CREDITO_CLIENTE.id_bitacora_credito_cliente IS
'Identificador único del registro de bitacora credito cliente.';

COMMENT ON COLUMN CP_BITACORA_CREDITO_CLIENTE.id_credito_cliente IS
'Identificador o referencia correspondiente a credito cliente.';

COMMENT ON COLUMN CP_BITACORA_CREDITO_CLIENTE.id_usuario IS
'Identificador o referencia correspondiente a usuario.';

COMMENT ON COLUMN CP_BITACORA_CREDITO_CLIENTE.id_tipo_operacion IS
'Identificador o referencia correspondiente a tipo operacion.';

COMMENT ON COLUMN CP_BITACORA_CREDITO_CLIENTE.limite_anterior IS
'Valor correspondiente a limite anterior.';

COMMENT ON COLUMN CP_BITACORA_CREDITO_CLIENTE.limite_nuevo IS
'Valor correspondiente a limite nuevo.';

COMMENT ON COLUMN CP_BITACORA_CREDITO_CLIENTE.fecha_operacion IS
'Fecha y/o hora correspondiente a fecha operacion.';

-- ============================================================
-- 97. CP_BITACORA_CREDITO_PROVEEDOR
-- ============================================================

COMMENT ON TABLE CP_BITACORA_CREDITO_PROVEEDOR IS
'Registra y administra la información correspondiente a bitacora credito proveedor dentro del sistema.';

COMMENT ON COLUMN CP_BITACORA_CREDITO_PROVEEDOR.id_bitacora_credito_proveedor IS
'Identificador único del registro de bitacora credito proveedor.';

COMMENT ON COLUMN CP_BITACORA_CREDITO_PROVEEDOR.id_credito_proveedor IS
'Identificador o referencia correspondiente a credito proveedor.';

COMMENT ON COLUMN CP_BITACORA_CREDITO_PROVEEDOR.id_usuario IS
'Identificador o referencia correspondiente a usuario.';

COMMENT ON COLUMN CP_BITACORA_CREDITO_PROVEEDOR.id_tipo_operacion IS
'Identificador o referencia correspondiente a tipo operacion.';

COMMENT ON COLUMN CP_BITACORA_CREDITO_PROVEEDOR.limite_anterior IS
'Valor correspondiente a limite anterior.';

COMMENT ON COLUMN CP_BITACORA_CREDITO_PROVEEDOR.limite_nuevo IS
'Valor correspondiente a limite nuevo.';

COMMENT ON COLUMN CP_BITACORA_CREDITO_PROVEEDOR.fecha_operacion IS
'Fecha y/o hora correspondiente a fecha operacion.';

-- ============================================================
-- 98. CP_BITACORA_DEVOLUCION_VENTA
-- ============================================================

COMMENT ON TABLE CP_BITACORA_DEVOLUCION_VENTA IS
'Registra y administra la información correspondiente a bitacora devolucion venta dentro del sistema.';

COMMENT ON COLUMN CP_BITACORA_DEVOLUCION_VENTA.id_bitacora_devolucion_venta IS
'Identificador único del registro de bitacora devolucion venta.';

COMMENT ON COLUMN CP_BITACORA_DEVOLUCION_VENTA.id_devolucion_venta IS
'Identificador o referencia correspondiente a devolucion venta.';

COMMENT ON COLUMN CP_BITACORA_DEVOLUCION_VENTA.id_usuario IS
'Identificador o referencia correspondiente a usuario.';

COMMENT ON COLUMN CP_BITACORA_DEVOLUCION_VENTA.id_tipo_operacion IS
'Identificador o referencia correspondiente a tipo operacion.';

COMMENT ON COLUMN CP_BITACORA_DEVOLUCION_VENTA.id_estado_anterior IS
'Identificador o referencia correspondiente a estado anterior.';

COMMENT ON COLUMN CP_BITACORA_DEVOLUCION_VENTA.id_estado_nuevo IS
'Identificador o referencia correspondiente a estado nuevo.';

COMMENT ON COLUMN CP_BITACORA_DEVOLUCION_VENTA.fecha_operacion IS
'Fecha y/o hora correspondiente a fecha operacion.';

-- ============================================================
-- 99. CP_BITACORA_DEVOLUCION_COMPRA
-- ============================================================

COMMENT ON TABLE CP_BITACORA_DEVOLUCION_COMPRA IS
'Registra y administra la información correspondiente a bitacora devolucion compra dentro del sistema.';

COMMENT ON COLUMN CP_BITACORA_DEVOLUCION_COMPRA.id_bitacora_devolucion_compra IS
'Identificador único del registro de bitacora devolucion compra.';

COMMENT ON COLUMN CP_BITACORA_DEVOLUCION_COMPRA.id_devolucion_compra IS
'Identificador o referencia correspondiente a devolucion compra.';

COMMENT ON COLUMN CP_BITACORA_DEVOLUCION_COMPRA.id_usuario IS
'Identificador o referencia correspondiente a usuario.';

COMMENT ON COLUMN CP_BITACORA_DEVOLUCION_COMPRA.id_tipo_operacion IS
'Identificador o referencia correspondiente a tipo operacion.';

COMMENT ON COLUMN CP_BITACORA_DEVOLUCION_COMPRA.id_estado_anterior IS
'Identificador o referencia correspondiente a estado anterior.';

COMMENT ON COLUMN CP_BITACORA_DEVOLUCION_COMPRA.id_estado_nuevo IS
'Identificador o referencia correspondiente a estado nuevo.';

COMMENT ON COLUMN CP_BITACORA_DEVOLUCION_COMPRA.fecha_operacion IS
'Fecha y/o hora correspondiente a fecha operacion.';

-- ============================================================
-- 100. CP_BITACORA_ACCESO
-- ============================================================

COMMENT ON TABLE CP_BITACORA_ACCESO IS
'Registra y administra la información correspondiente a bitacora acceso dentro del sistema.';

COMMENT ON COLUMN CP_BITACORA_ACCESO.id_bitacora_acceso IS
'Identificador único del registro de bitacora acceso.';

COMMENT ON COLUMN CP_BITACORA_ACCESO.nombre_usuario_intento IS
'Nombre correspondiente a usuario intento.';

COMMENT ON COLUMN CP_BITACORA_ACCESO.fecha_hora IS
'Fecha y/o hora correspondiente a fecha hora.';

COMMENT ON COLUMN CP_BITACORA_ACCESO.tipo_acceso IS
'Valor correspondiente a tipo acceso.';

COMMENT ON COLUMN CP_BITACORA_ACCESO.resultado IS
'Valor correspondiente a resultado.';

COMMENT ON COLUMN CP_BITACORA_ACCESO.direccion_ip IS
'Dirección IP desde la cual se realizó el acceso.';
