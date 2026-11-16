-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- SCRIPT: CP_datos_defensa.sql  (reemplaza a CP_datos_prueba.sql)
-- USUARIO: CP_POS (PDB ORCLPDB1, primaria)
-- ============================================================
-- Carga de datos realistas para la defensa del Entregable #2.
-- * Negocio: Supermercado Brunca (zona sur: Ciudad Neily,
--   Paso Canoas y San Vito de Coto Brus).
-- * Todos los contactos son CORREOS. Los tres correos reales se
--   asignan a clientes que reciben alertas; el resto usa variantes
--   con "+etiqueta" (llegan al mismo buzon).
-- * Los vencimientos de los lotes son RELATIVOS a SYSDATE, de modo
--   que siempre haya productos por vencer (7 dias), vencidos y con
--   mas de 6 meses en bodega.
-- * Los limites de credito se calculan para que haya clientes en
--   85 % o mas, proveedores en 70 % y en 85 % o mas, y morosos.
--
-- EJECUTAR UNA SOLA VEZ, en una base con las tablas vacias, y
-- ANTES del script 18 (CP_facturacion_cuentas.sql).
-- En Command Window: SET SQLBLANKLINES ON y luego @ruta\script.
-- Requiere el esquema completo de 117 tablas CP_*, secuencias, restricciones
-- y triggers instalados; ejecutar una sola vez despues de crear esos objetos.
-- CP_PADRON_NACIONAL queda vacia por decision del proyecto.
SET SQLBLANKLINES ON
SET SERVEROUTPUT ON
-- ============================================================


-- ============================================================
-- 1. CATALOGOS
-- ============================================================

INSERT INTO CP_TIPO_NEGOCIO (nombre_tipo_negocio, descripcion) VALUES ('SUPERMERCADO', 'Venta de productos de consumo general');

INSERT INTO CP_ESTADO (nombre, descripcion) VALUES ('ACTIVO', 'Registro activo en el sistema');
INSERT INTO CP_ESTADO (nombre, descripcion) VALUES ('INACTIVO', 'Registro inactivo en el sistema');
INSERT INTO CP_ESTADO (nombre, descripcion) VALUES ('SUSPENDIDO', 'Registro suspendido temporalmente');
INSERT INTO CP_ESTADO (nombre, descripcion) VALUES ('BLOQUEADO', 'Registro bloqueado en el sistema');
INSERT INTO CP_ESTADO (nombre, descripcion) VALUES ('PENDIENTE', 'Registro pendiente de activacion');

INSERT INTO CP_TIPO_OPERACION (nombre_tipo_operacion, descripcion) VALUES ('CREACION', 'Creacion de un registro');
INSERT INTO CP_TIPO_OPERACION (nombre_tipo_operacion, descripcion) VALUES ('MODIFICACION', 'Modificacion de un registro');
INSERT INTO CP_TIPO_OPERACION (nombre_tipo_operacion, descripcion) VALUES ('ELIMINACION', 'Eliminacion de un registro');
INSERT INTO CP_TIPO_OPERACION (nombre_tipo_operacion, descripcion) VALUES ('ENTRADA', 'Entrada de inventario');
INSERT INTO CP_TIPO_OPERACION (nombre_tipo_operacion, descripcion) VALUES ('SALIDA', 'Salida de inventario');

INSERT INTO CP_PROVINCIA (nombre) VALUES ('San Jose');
INSERT INTO CP_PROVINCIA (nombre) VALUES ('Alajuela');
INSERT INTO CP_PROVINCIA (nombre) VALUES ('Cartago');
INSERT INTO CP_PROVINCIA (nombre) VALUES ('Heredia');
INSERT INTO CP_PROVINCIA (nombre) VALUES ('Guanacaste');
INSERT INTO CP_PROVINCIA (nombre) VALUES ('Puntarenas');
INSERT INTO CP_PROVINCIA (nombre) VALUES ('Limon');

INSERT INTO CP_CANTON (id_provincia, nombre) SELECT id_provincia, 'Corredores' FROM CP_PROVINCIA WHERE nombre = 'Puntarenas';
INSERT INTO CP_CANTON (id_provincia, nombre) SELECT id_provincia, 'Coto Brus' FROM CP_PROVINCIA WHERE nombre = 'Puntarenas';
INSERT INTO CP_CANTON (id_provincia, nombre) SELECT id_provincia, 'Golfito' FROM CP_PROVINCIA WHERE nombre = 'Puntarenas';
INSERT INTO CP_CANTON (id_provincia, nombre) SELECT id_provincia, 'San Jose' FROM CP_PROVINCIA WHERE nombre = 'San Jose';

INSERT INTO CP_DISTRITO (id_canton, nombre) SELECT id_canton, 'Corredor' FROM CP_CANTON WHERE nombre = 'Corredores';
INSERT INTO CP_DISTRITO (id_canton, nombre) SELECT id_canton, 'Canoas' FROM CP_CANTON WHERE nombre = 'Corredores';
INSERT INTO CP_DISTRITO (id_canton, nombre) SELECT id_canton, 'La Cuesta' FROM CP_CANTON WHERE nombre = 'Corredores';
INSERT INTO CP_DISTRITO (id_canton, nombre) SELECT id_canton, 'San Vito' FROM CP_CANTON WHERE nombre = 'Coto Brus';
INSERT INTO CP_DISTRITO (id_canton, nombre) SELECT id_canton, 'Sabalito' FROM CP_CANTON WHERE nombre = 'Coto Brus';
INSERT INTO CP_DISTRITO (id_canton, nombre) SELECT id_canton, 'Golfito' FROM CP_CANTON WHERE nombre = 'Golfito';
INSERT INTO CP_DISTRITO (id_canton, nombre) SELECT id_canton, 'Carmen' FROM CP_CANTON WHERE nombre = 'San Jose';

INSERT INTO CP_TIPO_DIRECCION (nombre_tipo_direccion, descripcion) VALUES ('RESIDENCIA', 'Direccion de residencia');
INSERT INTO CP_TIPO_DIRECCION (nombre_tipo_direccion, descripcion) VALUES ('TRABAJO', 'Direccion del lugar de trabajo');
INSERT INTO CP_TIPO_DIRECCION (nombre_tipo_direccion, descripcion) VALUES ('COMERCIAL', 'Direccion comercial');
INSERT INTO CP_TIPO_DIRECCION (nombre_tipo_direccion, descripcion) VALUES ('FACTURACION', 'Direccion utilizada para facturacion');
INSERT INTO CP_TIPO_DIRECCION (nombre_tipo_direccion, descripcion) VALUES ('ENTREGA', 'Direccion utilizada para entregas');

INSERT INTO CP_NACIONALIDAD (nombre_nacionalidad) VALUES ('Costarricense');
INSERT INTO CP_NACIONALIDAD (nombre_nacionalidad) VALUES ('Panamena');
INSERT INTO CP_NACIONALIDAD (nombre_nacionalidad) VALUES ('Nicaraguense');
INSERT INTO CP_NACIONALIDAD (nombre_nacionalidad) VALUES ('Colombiana');
INSERT INTO CP_NACIONALIDAD (nombre_nacionalidad) VALUES ('Mexicana');

INSERT INTO CP_SEXO (nombre_sexo) VALUES ('MASCULINO');
INSERT INTO CP_SEXO (nombre_sexo) VALUES ('FEMENINO');
INSERT INTO CP_SEXO (nombre_sexo) VALUES ('NO INDICA');

INSERT INTO CP_ESTADO_CIVIL (nombre_estado_civil) VALUES ('SOLTERO');
INSERT INTO CP_ESTADO_CIVIL (nombre_estado_civil) VALUES ('CASADO');
INSERT INTO CP_ESTADO_CIVIL (nombre_estado_civil) VALUES ('DIVORCIADO');
INSERT INTO CP_ESTADO_CIVIL (nombre_estado_civil) VALUES ('VIUDO');
INSERT INTO CP_ESTADO_CIVIL (nombre_estado_civil) VALUES ('UNION LIBRE');

INSERT INTO CP_ESCOLARIDAD (nombre_escolaridad) VALUES ('PRIMARIA');
INSERT INTO CP_ESCOLARIDAD (nombre_escolaridad) VALUES ('SECUNDARIA');
INSERT INTO CP_ESCOLARIDAD (nombre_escolaridad) VALUES ('TECNICO');
INSERT INTO CP_ESCOLARIDAD (nombre_escolaridad) VALUES ('UNIVERSITARIA');
INSERT INTO CP_ESCOLARIDAD (nombre_escolaridad) VALUES ('POSGRADO');

INSERT INTO CP_TIPO_RESIDENCIA (nombre_tipo_residencia) VALUES ('PROPIA');
INSERT INTO CP_TIPO_RESIDENCIA (nombre_tipo_residencia) VALUES ('ALQUILADA');
INSERT INTO CP_TIPO_RESIDENCIA (nombre_tipo_residencia) VALUES ('FAMILIAR');
INSERT INTO CP_TIPO_RESIDENCIA (nombre_tipo_residencia) VALUES ('PRESTADA');
INSERT INTO CP_TIPO_RESIDENCIA (nombre_tipo_residencia) VALUES ('OTRA');

INSERT INTO CP_TIPO_DE_CONTACTO (nombre_tipo_contacto, descripcion) VALUES ('TELEFONO', 'Numero telefonico');
INSERT INTO CP_TIPO_DE_CONTACTO (nombre_tipo_contacto, descripcion) VALUES ('CELULAR', 'Numero de telefono celular');
INSERT INTO CP_TIPO_DE_CONTACTO (nombre_tipo_contacto, descripcion) VALUES ('CORREO', 'Direccion de correo electronico');
INSERT INTO CP_TIPO_DE_CONTACTO (nombre_tipo_contacto, descripcion) VALUES ('FAX', 'Numero de fax');

INSERT INTO CP_PUESTO (nombre_puesto, descripcion) VALUES ('ADMINISTRADOR', 'Administrador del sistema y gerente general');
INSERT INTO CP_PUESTO (nombre_puesto, descripcion) VALUES ('CAJERO', 'Encargado de realizar ventas');
INSERT INTO CP_PUESTO (nombre_puesto, descripcion) VALUES ('BODEGUERO', 'Encargado del inventario');
INSERT INTO CP_PUESTO (nombre_puesto, descripcion) VALUES ('SUPERVISOR', 'Coordinador de operaciones');
INSERT INTO CP_PUESTO (nombre_puesto, descripcion) VALUES ('CONTADOR', 'Encargado de procesos contables y proveeduria');

INSERT INTO CP_ROL (id_estado, nombre_rol, descripcion) SELECT id_estado, 'ADMINISTRADOR', 'Control total' FROM CP_ESTADO WHERE nombre = 'ACTIVO';
INSERT INTO CP_ROL (id_estado, nombre_rol, descripcion) SELECT id_estado, 'CAJERO', 'Gestion de ventas' FROM CP_ESTADO WHERE nombre = 'ACTIVO';
INSERT INTO CP_ROL (id_estado, nombre_rol, descripcion) SELECT id_estado, 'BODEGUERO', 'Gestion inventario' FROM CP_ESTADO WHERE nombre = 'ACTIVO';
INSERT INTO CP_ROL (id_estado, nombre_rol, descripcion) SELECT id_estado, 'SUPERVISOR', 'Supervisa procesos' FROM CP_ESTADO WHERE nombre = 'ACTIVO';
INSERT INTO CP_ROL (id_estado, nombre_rol, descripcion) SELECT id_estado, 'CONTADOR', 'Gestion contable' FROM CP_ESTADO WHERE nombre = 'ACTIVO';

INSERT INTO CP_PERMISO (id_estado, nombre_permiso) SELECT id_estado, 'GESTIONAR_USUARIOS' FROM CP_ESTADO WHERE nombre = 'ACTIVO';
INSERT INTO CP_PERMISO (id_estado, nombre_permiso) SELECT id_estado, 'REALIZAR_VENTAS' FROM CP_ESTADO WHERE nombre = 'ACTIVO';
INSERT INTO CP_PERMISO (id_estado, nombre_permiso) SELECT id_estado, 'GESTIONAR_INVENTARIO' FROM CP_ESTADO WHERE nombre = 'ACTIVO';
INSERT INTO CP_PERMISO (id_estado, nombre_permiso) SELECT id_estado, 'AUTORIZAR_DESCUENTOS' FROM CP_ESTADO WHERE nombre = 'ACTIVO';
INSERT INTO CP_PERMISO (id_estado, nombre_permiso) SELECT id_estado, 'GESTIONAR_CREDITOS' FROM CP_ESTADO WHERE nombre = 'ACTIVO';

INSERT INTO CP_ROL_PERMISO (id_rol, id_permiso) SELECT r.id_rol, p.id_permiso FROM CP_ROL r CROSS JOIN CP_PERMISO p WHERE r.nombre_rol = 'ADMINISTRADOR' AND p.nombre_permiso = 'GESTIONAR_USUARIOS';
INSERT INTO CP_ROL_PERMISO (id_rol, id_permiso) SELECT r.id_rol, p.id_permiso FROM CP_ROL r CROSS JOIN CP_PERMISO p WHERE r.nombre_rol = 'CAJERO' AND p.nombre_permiso = 'REALIZAR_VENTAS';
INSERT INTO CP_ROL_PERMISO (id_rol, id_permiso) SELECT r.id_rol, p.id_permiso FROM CP_ROL r CROSS JOIN CP_PERMISO p WHERE r.nombre_rol = 'BODEGUERO' AND p.nombre_permiso = 'GESTIONAR_INVENTARIO';
INSERT INTO CP_ROL_PERMISO (id_rol, id_permiso) SELECT r.id_rol, p.id_permiso FROM CP_ROL r CROSS JOIN CP_PERMISO p WHERE r.nombre_rol = 'SUPERVISOR' AND p.nombre_permiso = 'AUTORIZAR_DESCUENTOS';
INSERT INTO CP_ROL_PERMISO (id_rol, id_permiso) SELECT r.id_rol, p.id_permiso FROM CP_ROL r CROSS JOIN CP_PERMISO p WHERE r.nombre_rol = 'CONTADOR' AND p.nombre_permiso = 'GESTIONAR_CREDITOS';

INSERT INTO CP_TIPO_CLIENTE (nombre_tipo_cliente, descripcion) VALUES ('PERSONA', 'Cliente que corresponde a una persona');
INSERT INTO CP_TIPO_CLIENTE (nombre_tipo_cliente, descripcion) VALUES ('EMPRESA', 'Cliente que corresponde a una empresa');

INSERT INTO CP_ESTADO_CLIENTE (nombre_estado_cliente, descripcion) VALUES ('ACTIVO', 'Cliente activo');
INSERT INTO CP_ESTADO_CLIENTE (nombre_estado_cliente, descripcion) VALUES ('INACTIVO', 'Cliente inactivo');
INSERT INTO CP_ESTADO_CLIENTE (nombre_estado_cliente, descripcion) VALUES ('SUSPENDIDO', 'Cliente suspendido');
INSERT INTO CP_ESTADO_CLIENTE (nombre_estado_cliente, descripcion) VALUES ('BLOQUEADO', 'Cliente bloqueado');
INSERT INTO CP_ESTADO_CLIENTE (nombre_estado_cliente, descripcion) VALUES ('PENDIENTE', 'Cliente pendiente');

INSERT INTO CP_FAMILIA_PRODUCTO (nombre_familia, descripcion) VALUES ('ABARROTES', 'Productos de consumo basico');
INSERT INTO CP_FAMILIA_PRODUCTO (nombre_familia, descripcion) VALUES ('LACTEOS', 'Leche, quesos y derivados');
INSERT INTO CP_FAMILIA_PRODUCTO (nombre_familia, descripcion) VALUES ('CARNES', 'Carnes y embutidos');
INSERT INTO CP_FAMILIA_PRODUCTO (nombre_familia, descripcion) VALUES ('VERDURAS', 'Verduras y productos frescos');
INSERT INTO CP_FAMILIA_PRODUCTO (nombre_familia, descripcion) VALUES ('BEBIDAS', 'Bebidas y refrescos');
INSERT INTO CP_FAMILIA_PRODUCTO (nombre_familia, descripcion) VALUES ('LIMPIEZA', 'Productos para limpieza del hogar');

INSERT INTO CP_IMPUESTO (id_estado, nombre_impuesto, porcentaje_impuesto, descripcion) SELECT id_estado, 'EXENTO', 0, 'Producto exento de impuesto' FROM CP_ESTADO WHERE nombre = 'ACTIVO';
INSERT INTO CP_IMPUESTO (id_estado, nombre_impuesto, porcentaje_impuesto, descripcion) SELECT id_estado, 'IVA 1%', 1, 'IVA de la canasta basica (1 por ciento)' FROM CP_ESTADO WHERE nombre = 'ACTIVO';
INSERT INTO CP_IMPUESTO (id_estado, nombre_impuesto, porcentaje_impuesto, descripcion) SELECT id_estado, 'IVA 2%', 2, 'IVA reducido (2 por ciento)' FROM CP_ESTADO WHERE nombre = 'ACTIVO';
INSERT INTO CP_IMPUESTO (id_estado, nombre_impuesto, porcentaje_impuesto, descripcion) SELECT id_estado, 'IVA 4%', 4, 'IVA reducido (4 por ciento)' FROM CP_ESTADO WHERE nombre = 'ACTIVO';
INSERT INTO CP_IMPUESTO (id_estado, nombre_impuesto, porcentaje_impuesto, descripcion) SELECT id_estado, 'IVA 13%', 13, 'IVA general (13 por ciento)' FROM CP_ESTADO WHERE nombre = 'ACTIVO';

INSERT INTO CP_TIPO_ALMACEN (nombre_tipo_almacen, descripcion) VALUES ('CENTRAL', 'Almacen central de inventario');
INSERT INTO CP_TIPO_ALMACEN (nombre_tipo_almacen, descripcion) VALUES ('SUCURSAL', 'Almacen asociado a una sucursal');

INSERT INTO CP_ESTADO_TRASLADO (nombre_estado_traslado, descripcion) VALUES ('SOLICITADO', 'Traslado solicitado');
INSERT INTO CP_ESTADO_TRASLADO (nombre_estado_traslado, descripcion) VALUES ('EN PROCESO', 'Traslado en proceso');
INSERT INTO CP_ESTADO_TRASLADO (nombre_estado_traslado, descripcion) VALUES ('RECIBIDO', 'Traslado recibido');
INSERT INTO CP_ESTADO_TRASLADO (nombre_estado_traslado, descripcion) VALUES ('CANCELADO', 'Traslado cancelado');
INSERT INTO CP_ESTADO_TRASLADO (nombre_estado_traslado, descripcion) VALUES ('RECHAZADO', 'Traslado rechazado');

INSERT INTO CP_ESTADO_FACTURA_COMPRA (nombre_estado_factura, descripcion) VALUES ('REGISTRADA', 'Factura registrada');
INSERT INTO CP_ESTADO_FACTURA_COMPRA (nombre_estado_factura, descripcion) VALUES ('PENDIENTE', 'Factura pendiente');
INSERT INTO CP_ESTADO_FACTURA_COMPRA (nombre_estado_factura, descripcion) VALUES ('PAGADA', 'Factura pagada');
INSERT INTO CP_ESTADO_FACTURA_COMPRA (nombre_estado_factura, descripcion) VALUES ('ANULADA', 'Factura anulada');
INSERT INTO CP_ESTADO_FACTURA_COMPRA (nombre_estado_factura, descripcion) VALUES ('PARCIAL', 'Factura con pago parcial');

INSERT INTO CP_ESTADO_CUENTA_PAGAR (nombre_estado_cuenta_pagar, descripcion) VALUES ('PENDIENTE', 'Cuenta pendiente de pago');
INSERT INTO CP_ESTADO_CUENTA_PAGAR (nombre_estado_cuenta_pagar, descripcion) VALUES ('PARCIAL', 'Cuenta pagada parcialmente');
INSERT INTO CP_ESTADO_CUENTA_PAGAR (nombre_estado_cuenta_pagar, descripcion) VALUES ('PAGADA', 'Cuenta completamente pagada');
INSERT INTO CP_ESTADO_CUENTA_PAGAR (nombre_estado_cuenta_pagar, descripcion) VALUES ('VENCIDA', 'Cuenta vencida');
INSERT INTO CP_ESTADO_CUENTA_PAGAR (nombre_estado_cuenta_pagar, descripcion) VALUES ('ANULADA', 'Cuenta anulada');

INSERT INTO CP_ESTADO_FACTURA_VENTA (nombre_estado_factura, descripcion) VALUES ('EMITIDA', 'Factura emitida');
INSERT INTO CP_ESTADO_FACTURA_VENTA (nombre_estado_factura, descripcion) VALUES ('PAGADA', 'Factura pagada');
INSERT INTO CP_ESTADO_FACTURA_VENTA (nombre_estado_factura, descripcion) VALUES ('CREDITO', 'Factura realizada a credito');
INSERT INTO CP_ESTADO_FACTURA_VENTA (nombre_estado_factura, descripcion) VALUES ('ANULADA', 'Factura anulada');
INSERT INTO CP_ESTADO_FACTURA_VENTA (nombre_estado_factura, descripcion) VALUES ('DEVUELTA', 'Factura con devolucion');

INSERT INTO CP_TIPO_PAGO (id_estado, nombre_tipo_pago, descripcion) SELECT id_estado, 'EFECTIVO', 'Pago realizado en efectivo' FROM CP_ESTADO WHERE nombre = 'ACTIVO';
INSERT INTO CP_TIPO_PAGO (id_estado, nombre_tipo_pago, descripcion) SELECT id_estado, 'TARJETA DEBITO', 'Pago con tarjeta de debito' FROM CP_ESTADO WHERE nombre = 'ACTIVO';
INSERT INTO CP_TIPO_PAGO (id_estado, nombre_tipo_pago, descripcion) SELECT id_estado, 'TARJETA CREDITO', 'Pago con tarjeta de credito' FROM CP_ESTADO WHERE nombre = 'ACTIVO';
INSERT INTO CP_TIPO_PAGO (id_estado, nombre_tipo_pago, descripcion) SELECT id_estado, 'SINPE', 'Pago mediante SINPE Movil' FROM CP_ESTADO WHERE nombre = 'ACTIVO';
INSERT INTO CP_TIPO_PAGO (id_estado, nombre_tipo_pago, descripcion) SELECT id_estado, 'TRANSFERENCIA', 'Pago mediante transferencia bancaria' FROM CP_ESTADO WHERE nombre = 'ACTIVO';

INSERT INTO CP_ESTADO_CREDITO (nombre_estado_credito, descripcion) VALUES ('ACTIVO', 'Credito autorizado y disponible');
INSERT INTO CP_ESTADO_CREDITO (nombre_estado_credito, descripcion) VALUES ('SUSPENDIDO', 'Credito suspendido temporalmente');
INSERT INTO CP_ESTADO_CREDITO (nombre_estado_credito, descripcion) VALUES ('VENCIDO', 'Credito fuera de su periodo de vigencia');
INSERT INTO CP_ESTADO_CREDITO (nombre_estado_credito, descripcion) VALUES ('CANCELADO', 'Credito cancelado');
INSERT INTO CP_ESTADO_CREDITO (nombre_estado_credito, descripcion) VALUES ('BLOQUEADO', 'Credito bloqueado para nuevas operaciones');

INSERT INTO CP_ESTADO_CUENTA_COBRAR (nombre_estado_cuenta_cobrar, descripcion) VALUES ('PENDIENTE', 'Cuenta pendiente de cobro');
INSERT INTO CP_ESTADO_CUENTA_COBRAR (nombre_estado_cuenta_cobrar, descripcion) VALUES ('PARCIAL', 'Cuenta cobrada parcialmente');
INSERT INTO CP_ESTADO_CUENTA_COBRAR (nombre_estado_cuenta_cobrar, descripcion) VALUES ('PAGADA', 'Cuenta completamente pagada');
INSERT INTO CP_ESTADO_CUENTA_COBRAR (nombre_estado_cuenta_cobrar, descripcion) VALUES ('VENCIDA', 'Cuenta vencida');
INSERT INTO CP_ESTADO_CUENTA_COBRAR (nombre_estado_cuenta_cobrar, descripcion) VALUES ('ANULADA', 'Cuenta anulada');

INSERT INTO CP_ESTADO_PROMOCION (nombre_estado_promocion, descripcion) VALUES ('ACTIVA', 'Promocion actualmente activa');
INSERT INTO CP_ESTADO_PROMOCION (nombre_estado_promocion, descripcion) VALUES ('PROGRAMADA', 'Promocion programada');
INSERT INTO CP_ESTADO_PROMOCION (nombre_estado_promocion, descripcion) VALUES ('FINALIZADA', 'Promocion finalizada');
INSERT INTO CP_ESTADO_PROMOCION (nombre_estado_promocion, descripcion) VALUES ('SUSPENDIDA', 'Promocion suspendida');
INSERT INTO CP_ESTADO_PROMOCION (nombre_estado_promocion, descripcion) VALUES ('CANCELADA', 'Promocion cancelada');

INSERT INTO CP_ACCION_PROMOCION (nombre_accion_promocion, descripcion) VALUES ('ENTREGAR PRODUCTO', 'Entrega un producto como premio');
INSERT INTO CP_ACCION_PROMOCION (nombre_accion_promocion, descripcion) VALUES ('APLICAR DESCUENTO', 'Aplica un descuento promocional');
INSERT INTO CP_ACCION_PROMOCION (nombre_accion_promocion, descripcion) VALUES ('ENTREGAR CUPON', 'Entrega un cupon al cliente');
INSERT INTO CP_ACCION_PROMOCION (nombre_accion_promocion, descripcion) VALUES ('ACUMULAR PUNTOS', 'Entrega puntos promocionales');
INSERT INTO CP_ACCION_PROMOCION (nombre_accion_promocion, descripcion) VALUES ('PRECIO ESPECIAL', 'Aplica un precio promocional');

INSERT INTO CP_ESTADO_DESCUENTO (nombre_estado_descuento, descripcion) VALUES ('ACTIVO', 'Descuento activo');
INSERT INTO CP_ESTADO_DESCUENTO (nombre_estado_descuento, descripcion) VALUES ('PROGRAMADO', 'Descuento programado');
INSERT INTO CP_ESTADO_DESCUENTO (nombre_estado_descuento, descripcion) VALUES ('FINALIZADO', 'Descuento finalizado');
INSERT INTO CP_ESTADO_DESCUENTO (nombre_estado_descuento, descripcion) VALUES ('SUSPENDIDO', 'Descuento suspendido');
INSERT INTO CP_ESTADO_DESCUENTO (nombre_estado_descuento, descripcion) VALUES ('CANCELADO', 'Descuento cancelado');

INSERT INTO CP_ESTADO_DEVOLUCION (nombre_estado_devolucion, descripcion) VALUES ('SOLICITADA', 'Devolucion registrada y pendiente de revision');
INSERT INTO CP_ESTADO_DEVOLUCION (nombre_estado_devolucion, descripcion) VALUES ('APROBADA', 'Devolucion aprobada');
INSERT INTO CP_ESTADO_DEVOLUCION (nombre_estado_devolucion, descripcion) VALUES ('RECHAZADA', 'Devolucion rechazada');
INSERT INTO CP_ESTADO_DEVOLUCION (nombre_estado_devolucion, descripcion) VALUES ('PROCESADA', 'Devolucion procesada');
INSERT INTO CP_ESTADO_DEVOLUCION (nombre_estado_devolucion, descripcion) VALUES ('ANULADA', 'Devolucion anulada');

INSERT INTO CP_MOTIVO_DEVOLUCION (nombre_motivo_devolucion, descripcion) VALUES ('PRODUCTO DANADO', 'El producto presenta danos');
INSERT INTO CP_MOTIVO_DEVOLUCION (nombre_motivo_devolucion, descripcion) VALUES ('PRODUCTO VENCIDO', 'El producto se encuentra vencido');
INSERT INTO CP_MOTIVO_DEVOLUCION (nombre_motivo_devolucion, descripcion) VALUES ('PRODUCTO INCORRECTO', 'Se entrego un producto incorrecto');
INSERT INTO CP_MOTIVO_DEVOLUCION (nombre_motivo_devolucion, descripcion) VALUES ('ERROR DE FACTURACION', 'Se produjo un error durante la facturacion');
INSERT INTO CP_MOTIVO_DEVOLUCION (nombre_motivo_devolucion, descripcion) VALUES ('CALIDAD DEL PRODUCTO', 'El producto no cumple con la calidad esperada');

COMMIT;

-- ============================================================
-- 2. NEGOCIO, PERSONAL, CLIENTES, PROVEEDORES, PRODUCTOS,
--    COMPRAS, INVENTARIO, VENTAS, CREDITOS, PROMOCIONES,
--    DESCUENTOS Y BITACORAS (un solo bloque PL/SQL)
-- ============================================================

DECLARE
    TYPE t_num  IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    TYPE t_numk IS TABLE OF NUMBER INDEX BY VARCHAR2(40);
    TYPE t_str  IS TABLE OF VARCHAR2(40) INDEX BY PLS_INTEGER;
    TYPE t_date IS TABLE OF DATE INDEX BY PLS_INTEGER;
    v_dir     t_num;
    v_disp    t_num;
    v_almL    t_num;
    v_suc     t_numk;
    v_alm     t_numk;
    v_cajero  t_numk;
    v_cliente t_numk;
    v_deuda   t_numk;
    v_target  t_numk;
    v_cred    t_numk;
    v_deudaP  t_numk;
    v_targetP t_numk;
    v_credP   t_numk;
    cr_fact   t_num;
    cr_total  t_num;
    cr_abono  t_num;
    cr_key    t_str;
    cr_fecha  t_date;
    cr_fabono t_date;
    cr_n      PLS_INTEGER := 0;
    v_negocio NUMBER;
    v_admin   NUMBER;
    v_conta   NUMBER;
    v_empresa NUMBER;
    v_p       NUMBER;
    v_u       NUMBER;
    v_nlote   PLS_INTEGER := 0;
    v_npago   PLS_INTEGER := 0;
    v_id      NUMBER;
    v_ratio   NUMBER;
    v_lim     NUMBER;
    v_est     NUMBER;
    v_est2    NUMBER;
    v_l1      NUMBER;
    v_tr      NUMBER;
    v_lote_id NUMBER;
    v_prom    NUMBER;
    v_regla   NUMBER;
    v_desc    NUMBER;
    k         VARCHAR2(40);

    ----------------------------------------------------------
    FUNCTION dir(p_distrito VARCHAR2, p_senas VARCHAR2) RETURN NUMBER IS
        v_d NUMBER;
        v_r NUMBER;
    BEGIN
        SELECT id_distrito INTO v_d FROM CP_DISTRITO WHERE nombre = p_distrito;
        INSERT INTO CP_DIRECCION (id_distrito, otras_senas) VALUES (v_d, p_senas) RETURNING id_direccion INTO v_r;
        RETURN v_r;
    END dir;

    FUNCTION correo(p_valor VARCHAR2) RETURN NUMBER IS
        v_t NUMBER;
        v_r NUMBER;
    BEGIN
        SELECT id_tipo_contacto INTO v_t FROM CP_TIPO_DE_CONTACTO WHERE nombre_tipo_contacto = 'CORREO';
        INSERT INTO CP_CONTACTO (id_tipo_contacto, valor_contacto) VALUES (v_t, p_valor) RETURNING id_contacto INTO v_r;
        RETURN v_r;
    END correo;

    FUNCTION persona(p_ident VARCHAR2, p_n1 VARCHAR2, p_n2 VARCHAR2, p_a1 VARCHAR2, p_a2 VARCHAR2,
                     p_nac DATE, p_sexo VARCHAR2, p_civil VARCHAR2, p_esc VARCHAR2, p_res VARCHAR2,
                     p_aseg VARCHAR2, p_correo VARCHAR2, p_dir NUMBER) RETURN NUMBER IS
        v_nac NUMBER; v_civ NUMBER; v_sex NUMBER; v_esc NUMBER; v_res NUMBER;
        v_td NUMBER; v_c NUMBER; v_r NUMBER;
    BEGIN
        SELECT id_nacionalidad INTO v_nac FROM CP_NACIONALIDAD WHERE nombre_nacionalidad = 'Costarricense';
        SELECT id_estado_civil INTO v_civ FROM CP_ESTADO_CIVIL WHERE nombre_estado_civil = p_civil;
        SELECT id_sexo INTO v_sex FROM CP_SEXO WHERE nombre_sexo = p_sexo;
        SELECT id_escolaridad INTO v_esc FROM CP_ESCOLARIDAD WHERE nombre_escolaridad = p_esc;
        SELECT id_tipo_residencia INTO v_res FROM CP_TIPO_RESIDENCIA WHERE nombre_tipo_residencia = p_res;
        INSERT INTO CP_PERSONA (id_nacionalidad, id_estado_civil, id_sexo, id_escolaridad, id_tipo_residencia,
                                identificacion, primer_nombre, segundo_nombre, primer_apellido, segundo_apellido,
                                fecha_nacimiento, es_asegurado)
        VALUES (v_nac, v_civ, v_sex, v_esc, v_res, p_ident, p_n1, p_n2, p_a1, p_a2, p_nac, p_aseg)
        RETURNING id_persona INTO v_r;
        SELECT id_tipo_direccion INTO v_td FROM CP_TIPO_DIRECCION WHERE nombre_tipo_direccion = 'RESIDENCIA';
        INSERT INTO CP_PERSONA_DIRECCION (id_persona, id_direccion, id_tipo_direccion, es_principal) VALUES (v_r, p_dir, v_td, 'S');
        v_c := correo(p_correo);
        INSERT INTO CP_PERSONA_CONTACTO (id_persona, id_contacto, es_principal) VALUES (v_r, v_c, 'S');
        RETURN v_r;
    END persona;

    FUNCTION usuario(p_persona NUMBER, p_user VARCHAR2, p_suc VARCHAR2, p_rol VARCHAR2, p_puesto VARCHAR2, p_ingreso DATE) RETURN NUMBER IS
        v_e NUMBER; v_r NUMBER; v_pu NUMBER; v_res NUMBER;
    BEGIN
        SELECT id_estado INTO v_e FROM CP_ESTADO WHERE nombre = 'ACTIVO';
        SELECT id_rol INTO v_r FROM CP_ROL WHERE nombre_rol = p_rol;
        INSERT INTO CP_USUARIO (id_persona, id_estado, id_sucursal, id_rol, nombre_usuario, contrasena_hash)
        VALUES (p_persona, v_e, v_suc(p_suc), v_r, p_user, 'HASH_PRUEBA_' || UPPER(p_user))
        RETURNING id_usuario INTO v_res;
        SELECT id_puesto INTO v_pu FROM CP_PUESTO WHERE nombre_puesto = p_puesto;
        INSERT INTO CP_PERSONA_EMPLEO (id_persona, id_puesto, id_empresa_laboral, fecha_ingreso, fecha_salida)
        VALUES (p_persona, v_pu, v_empresa, p_ingreso, NULL);
        RETURN v_res;
    END usuario;

    PROCEDURE cli_persona(p_persona NUMBER, p_key VARCHAR2, p_ingreso DATE) IS
        v_t NUMBER; v_e NUMBER; v_c NUMBER;
    BEGIN
        SELECT id_tipo_cliente INTO v_t FROM CP_TIPO_CLIENTE WHERE nombre_tipo_cliente = 'PERSONA';
        SELECT id_estado_cliente INTO v_e FROM CP_ESTADO_CLIENTE WHERE nombre_estado_cliente = 'ACTIVO';
        INSERT INTO CP_CLIENTE (id_tipo_cliente, id_estado_cliente, fecha_ingreso, es_cliente_defecto)
        VALUES (v_t, v_e, p_ingreso, 'N') RETURNING id_cliente INTO v_c;
        INSERT INTO CP_CLIENTE_PERSONA (id_cliente, id_persona) VALUES (v_c, p_persona);
        v_cliente(p_key) := v_c;
    END cli_persona;

    PROCEDURE cli_empresa(p_ced VARCHAR2, p_razon VARCHAR2, p_comercial VARCHAR2, p_correo VARCHAR2, p_dir NUMBER, p_ingreso DATE) IS
        v_t NUMBER; v_e NUMBER; v_c NUMBER; v_ce NUMBER; v_td NUMBER; v_co NUMBER;
    BEGIN
        SELECT id_tipo_cliente INTO v_t FROM CP_TIPO_CLIENTE WHERE nombre_tipo_cliente = 'EMPRESA';
        SELECT id_estado_cliente INTO v_e FROM CP_ESTADO_CLIENTE WHERE nombre_estado_cliente = 'ACTIVO';
        INSERT INTO CP_CLIENTE (id_tipo_cliente, id_estado_cliente, fecha_ingreso, es_cliente_defecto)
        VALUES (v_t, v_e, p_ingreso, 'N') RETURNING id_cliente INTO v_c;
        INSERT INTO CP_CLIENTE_EMPRESA (id_cliente, cedula_juridica, razon_social, nombre_comercial)
        VALUES (v_c, p_ced, p_razon, p_comercial) RETURNING id_cliente_empresa INTO v_ce;
        SELECT id_tipo_direccion INTO v_td FROM CP_TIPO_DIRECCION WHERE nombre_tipo_direccion = 'COMERCIAL';
        INSERT INTO CP_CLIENTE_EMPRESA_DIRECCION (id_cliente_empresa, id_direccion, id_tipo_direccion, es_principal)
        VALUES (v_ce, p_dir, v_td, 'S');
        v_co := correo(p_correo);
        INSERT INTO CP_CLIENTE_EMPRESA_CONTACTO (id_cliente_empresa, id_contacto, es_principal) VALUES (v_ce, v_co, 'S');
        v_cliente(p_ced) := v_c;
    END cli_empresa;

    PROCEDURE proveedor(p_ced VARCHAR2, p_razon VARCHAR2, p_comercial VARCHAR2, p_correo VARCHAR2, p_dir NUMBER, p_fecha DATE) IS
        v_e NUMBER; v_pr NUMBER; v_td NUMBER; v_co NUMBER;
    BEGIN
        SELECT id_estado INTO v_e FROM CP_ESTADO WHERE nombre = 'ACTIVO';
        INSERT INTO CP_PROVEEDOR (id_estado, cedula_juridica, razon_social, nombre_comercial)
        VALUES (v_e, p_ced, p_razon, p_comercial) RETURNING id_proveedor INTO v_pr;
        SELECT id_tipo_direccion INTO v_td FROM CP_TIPO_DIRECCION WHERE nombre_tipo_direccion = 'COMERCIAL';
        INSERT INTO CP_PROVEEDOR_DIRECCION (id_proveedor, id_tipo_direccion, id_direccion, es_principal, fecha_asignacion)
        VALUES (v_pr, v_td, p_dir, 'S', p_fecha);
        v_co := correo(p_correo);
        INSERT INTO CP_PROVEEDOR_CONTACTO (id_proveedor, id_contacto, es_principal) VALUES (v_pr, v_co, 'S');
    END proveedor;

    PROCEDURE producto(p_cod VARCHAR2, p_nombre VARCHAR2, p_desc VARCHAR2, p_familia VARCHAR2, p_imp VARCHAR2,
                       p_prov VARCHAR2, p_costo NUMBER, p_precio NUMBER, p_descmax NUMBER) IS
        v_f NUMBER; v_i NUMBER; v_e NUMBER; v_pr NUMBER; v_prov NUMBER;
    BEGIN
        SELECT id_familia_producto INTO v_f FROM CP_FAMILIA_PRODUCTO WHERE nombre_familia = p_familia;
        SELECT id_impuesto INTO v_i FROM CP_IMPUESTO WHERE nombre_impuesto = p_imp;
        SELECT id_estado INTO v_e FROM CP_ESTADO WHERE nombre = 'ACTIVO';
        SELECT id_proveedor INTO v_prov FROM CP_PROVEEDOR WHERE cedula_juridica = p_prov;
        INSERT INTO CP_PRODUCTO (id_familia_producto, id_impuesto, id_estado, codigo_producto, nombre_producto, descripcion)
        VALUES (v_f, v_i, v_e, p_cod, p_nombre, p_desc) RETURNING id_producto INTO v_pr;
        INSERT INTO CP_CODIGO_BARRA (id_producto, codigo_barra)
        VALUES (v_pr, '7441' || LPAD(TO_NUMBER(SUBSTR(p_cod, 5)) * 137, 9, '0'));
        INSERT INTO CP_PRODUCTO_PROVEEDOR (id_proveedor, id_producto, precio_costo_actual) VALUES (v_prov, v_pr, p_costo);
        INSERT INTO CP_PRODUCTO_NEGOCIO (id_producto, id_negocio, porcentaje_utilidad, descuento_maximo, precio_venta_actual)
        VALUES (v_pr, v_negocio, 25, p_descmax, p_precio);
    END producto;

    FUNCTION lote_de(p_compra VARCHAR2, p_cod VARCHAR2) RETURN NUMBER IS
        v_r NUMBER;
    BEGIN
        SELECT lp.id_lote_producto INTO v_r
        FROM CP_LOTE_PRODUCTO lp
        JOIN CP_DETALLE_COMPRA dc ON dc.id_detalle_compra = lp.id_detalle_compra
        JOIN CP_FACTURA_COMPRA fc ON fc.id_factura_compra = dc.id_factura_compra
        JOIN CP_PRODUCTO_PROVEEDOR pp ON pp.id_producto_proveedor = dc.id_producto_proveedor
        JOIN CP_PRODUCTO p ON p.id_producto = pp.id_producto
        WHERE fc.numero_factura = p_compra AND p.codigo_producto = p_cod;
        RETURN v_r;
    END lote_de;

    ----------------------------------------------------------
    -- Compra a proveedor. Lineas: 'CODIGO,CANTIDAD,DIAS_PARA_VENCER;...'
    ----------------------------------------------------------
    PROCEDURE compra(p_num VARCHAR2, p_prov VARCHAR2, p_suc VARCHAR2, p_fecha DATE, p_estado VARCHAR2,
                     p_lineas VARCHAR2, p_abono NUMBER DEFAULT 0, p_fabono DATE DEFAULT NULL) IS
        TYPE t_l IS RECORD (pp NUMBER, cant NUMBER, costo NUMBER, pct NUMBER, vence DATE);
        TYPE t_la IS TABLE OF t_l INDEX BY PLS_INTEGER;
        l t_la;
        i PLS_INTEGER := 0;
        tok VARCHAR2(100);
        cod VARCHAR2(20);
        v_sub NUMBER := 0; v_imp NUMBER := 0; v_tot NUMBER; v_ls NUMBER; v_li NUMBER;
        v_prov NUMBER; v_est NUMBER; v_fc NUMBER; v_det NUMBER; v_lote NUMBER;
        v_cta NUMBER; v_ec NUMBER; v_tp NUMBER;
    BEGIN
        SELECT id_proveedor INTO v_prov FROM CP_PROVEEDOR WHERE cedula_juridica = p_prov;
        SELECT id_estado_factura_compra INTO v_est FROM CP_ESTADO_FACTURA_COMPRA WHERE nombre_estado_factura = p_estado;
        LOOP
            i := i + 1;
            tok := REGEXP_SUBSTR(p_lineas, '[^;]+', 1, i);
            EXIT WHEN tok IS NULL;
            cod := REGEXP_SUBSTR(tok, '[^,]+', 1, 1);
            l(i).cant  := TO_NUMBER(REGEXP_SUBSTR(tok, '[^,]+', 1, 2));
            l(i).vence := TRUNC(SYSDATE) + TO_NUMBER(REGEXP_SUBSTR(tok, '[^,]+', 1, 3));
            SELECT pp.id_producto_proveedor, pp.precio_costo_actual, im.porcentaje_impuesto
              INTO l(i).pp, l(i).costo, l(i).pct
            FROM CP_PRODUCTO p
            JOIN CP_PRODUCTO_PROVEEDOR pp ON pp.id_producto = p.id_producto AND pp.id_proveedor = v_prov
            JOIN CP_IMPUESTO im ON im.id_impuesto = p.id_impuesto
            WHERE p.codigo_producto = cod;
            v_ls := l(i).cant * l(i).costo;
            v_sub := v_sub + v_ls;
            v_imp := v_imp + ROUND(v_ls * l(i).pct / 100, 2);
        END LOOP;
        v_tot := v_sub + v_imp;
        INSERT INTO CP_FACTURA_COMPRA (id_proveedor, id_negocio, id_almacen_recepcion, id_usuario, id_estado_factura_compra,
                                       numero_factura, fecha_emision, fecha_recepcion, subtotal, descuento_total, impuesto_total, total)
        VALUES (v_prov, v_negocio, v_alm(p_suc), v_conta, v_est, p_num, p_fecha, p_fecha, v_sub, 0, v_imp, v_tot)
        RETURNING id_factura_compra INTO v_fc;
        FOR j IN 1 .. l.COUNT LOOP
            v_ls := l(j).cant * l(j).costo;
            v_li := ROUND(v_ls * l(j).pct / 100, 2);
            INSERT INTO CP_DETALLE_COMPRA (id_factura_compra, id_producto_proveedor, cantidad, precio_costo_unitario, monto_descuento,
                                           porcentaje_impuesto, monto_impuesto, subtotal_linea, total_linea)
            VALUES (v_fc, l(j).pp, l(j).cant, l(j).costo, 0, l(j).pct, v_li, v_ls, v_ls + v_li)
            RETURNING id_detalle_compra INTO v_det;
            v_nlote := v_nlote + 1;
            INSERT INTO CP_LOTE_PRODUCTO (id_detalle_compra, numero_lote, cantidad_recibida, fecha_ingreso, fecha_vencimiento)
            VALUES (v_det, 'LT-' || TO_CHAR(p_fecha, 'YYMM') || '-' || LPAD(v_nlote, 4, '0'), l(j).cant, p_fecha, l(j).vence)
            RETURNING id_lote_producto INTO v_lote;
            v_disp(v_lote) := l(j).cant;
            v_almL(v_lote) := v_alm(p_suc);
        END LOOP;
        IF p_estado = 'PENDIENTE' THEN
            SELECT id_estado_cuenta_pagar INTO v_ec FROM CP_ESTADO_CUENTA_PAGAR WHERE nombre_estado_cuenta_pagar = 'PENDIENTE';
            INSERT INTO CP_CUENTA_PAGAR (id_factura_compra, id_estado_cuenta_pagar, fecha_creacion, fecha_vencimiento, observacion)
            VALUES (v_fc, v_ec, p_fecha, p_fecha + 30, 'Cuenta por pagar factura ' || p_num) RETURNING id_cuenta_pagar INTO v_cta;
            IF p_abono > 0 THEN
                SELECT id_tipo_pago INTO v_tp FROM CP_TIPO_PAGO WHERE nombre_tipo_pago = 'TRANSFERENCIA';
                INSERT INTO CP_ABONO_CUENTA_PAGAR (id_cuenta_pagar, id_tipo_pago, id_usuario, monto_abono, fecha_abono, numero_referencia, observacion)
                VALUES (v_cta, v_tp, v_conta, p_abono, p_fabono + 9/24, 'TRF-' || p_num, 'Abono a factura ' || p_num);
            END IF;
            IF v_deudaP.EXISTS(p_prov) THEN
                v_deudaP(p_prov) := v_deudaP(p_prov) + v_tot - p_abono;
            ELSE
                v_deudaP(p_prov) := v_tot - p_abono;
            END IF;
        END IF;
    END compra;

    ----------------------------------------------------------
    -- Venta a cliente. Forma: C contado, R credito, E emitida sin pago.
    -- Lineas: 'CODIGO,CANTIDAD;...'  (salida de lotes por FEFO)
    ----------------------------------------------------------
    PROCEDURE venta(p_num VARCHAR2, p_fecha DATE, p_suc VARCHAR2, p_cli VARCHAR2, p_forma VARCHAR2,
                    p_lineas VARCHAR2, p_abono NUMBER DEFAULT 0, p_fabono DATE DEFAULT NULL) IS
        TYPE t_l IS RECORD (prod NUMBER, cod VARCHAR2(20), cant NUMBER, precio NUMBER, pct NUMBER);
        TYPE t_la IS TABLE OF t_l INDEX BY PLS_INTEGER;
        l t_la;
        i PLS_INTEGER := 0;
        tok VARCHAR2(100);
        v_sub NUMBER := 0; v_imp NUMBER := 0; v_tot NUMBER; v_ls NUMBER; v_li NUMBER;
        v_est NUMBER; v_fv NUMBER; v_dp NUMBER; v_falta NUMBER; v_toma NUMBER; v_tp NUMBER;
        v_tpn VARCHAR2(30);
    BEGIN
        LOOP
            i := i + 1;
            tok := REGEXP_SUBSTR(p_lineas, '[^;]+', 1, i);
            EXIT WHEN tok IS NULL;
            l(i).cod  := REGEXP_SUBSTR(tok, '[^,]+', 1, 1);
            l(i).cant := TO_NUMBER(REGEXP_SUBSTR(tok, '[^,]+', 1, 2));
            SELECT p.id_producto, pn.precio_venta_actual, im.porcentaje_impuesto
              INTO l(i).prod, l(i).precio, l(i).pct
            FROM CP_PRODUCTO p
            JOIN CP_PRODUCTO_NEGOCIO pn ON pn.id_producto = p.id_producto AND pn.id_negocio = v_negocio
            JOIN CP_IMPUESTO im ON im.id_impuesto = p.id_impuesto
            WHERE p.codigo_producto = l(i).cod;
            v_ls := l(i).cant * l(i).precio;
            v_sub := v_sub + v_ls;
            v_imp := v_imp + ROUND(v_ls * l(i).pct / 100, 2);
        END LOOP;
        v_tot := v_sub + v_imp;
        SELECT id_estado_factura_venta INTO v_est FROM CP_ESTADO_FACTURA_VENTA
        WHERE nombre_estado_factura = CASE p_forma WHEN 'C' THEN 'PAGADA' WHEN 'R' THEN 'CREDITO' ELSE 'EMITIDA' END;
        INSERT INTO CP_FACTURA_VENTA (id_cliente, id_sucursal, id_usuario, id_estado_factura_venta, numero_factura,
                                      fecha_emision, subtotal, descuento_total, impuesto_total, total)
        VALUES (v_cliente(p_cli), v_suc(p_suc), v_cajero(p_suc), v_est, p_num, p_fecha, v_sub, 0, v_imp, v_tot)
        RETURNING id_factura_venta INTO v_fv;
        FOR j IN 1 .. l.COUNT LOOP
            v_ls := l(j).cant * l(j).precio;
            v_li := ROUND(v_ls * l(j).pct / 100, 2);
            INSERT INTO CP_DETALLE_VENTA_PRODUCTO (id_factura_venta, id_producto, cantidad, precio_unitario, porcentaje_descuento,
                                                   monto_descuento, porcentaje_impuesto, monto_impuesto, subtotal, total)
            VALUES (v_fv, l(j).prod, l(j).cant, l(j).precio, 0, 0, l(j).pct, v_li, v_ls, v_ls + v_li)
            RETURNING id_detalle_venta_producto INTO v_dp;
            v_falta := l(j).cant;
            FOR r IN (SELECT lp.id_lote_producto
                      FROM CP_LOTE_PRODUCTO lp
                      JOIN CP_DETALLE_COMPRA dc ON dc.id_detalle_compra = lp.id_detalle_compra
                      JOIN CP_PRODUCTO_PROVEEDOR pp ON pp.id_producto_proveedor = dc.id_producto_proveedor
                      JOIN CP_FACTURA_COMPRA fc ON fc.id_factura_compra = dc.id_factura_compra
                      WHERE pp.id_producto = l(j).prod
                        AND fc.id_almacen_recepcion = v_alm(p_suc)
                        AND lp.fecha_ingreso <= p_fecha
                        AND lp.fecha_vencimiento > p_fecha
                      ORDER BY lp.fecha_vencimiento, lp.id_lote_producto) LOOP
                EXIT WHEN v_falta <= 0;
                IF v_disp.EXISTS(r.id_lote_producto) AND v_disp(r.id_lote_producto) > 0 THEN
                    v_toma := LEAST(v_falta, v_disp(r.id_lote_producto));
                    INSERT INTO CP_DETALLE_VENTA_LOTE (id_detalle_venta_producto, id_lote_producto, cantidad)
                    VALUES (v_dp, r.id_lote_producto, v_toma);
                    v_disp(r.id_lote_producto) := v_disp(r.id_lote_producto) - v_toma;
                    v_falta := v_falta - v_toma;
                END IF;
            END LOOP;
            IF v_falta > 0 THEN
                RAISE_APPLICATION_ERROR(-20999, 'Existencias insuficientes en ' || p_num || ' para ' || l(j).cod);
            END IF;
        END LOOP;
        IF p_forma = 'C' THEN
            v_npago := v_npago + 1;
            v_tpn := CASE MOD(v_npago, 4) WHEN 0 THEN 'EFECTIVO' WHEN 1 THEN 'SINPE' WHEN 2 THEN 'TARJETA DEBITO' ELSE 'TARJETA CREDITO' END;
            SELECT id_tipo_pago INTO v_tp FROM CP_TIPO_PAGO WHERE nombre_tipo_pago = v_tpn;
            INSERT INTO CP_PAGO_FACTURA_VENTA (id_factura_venta, id_tipo_pago, id_usuario, fecha_pago, monto_pago, numero_referencia, observacion)
            VALUES (v_fv, v_tp, v_cajero(p_suc), p_fecha + 10/24, v_tot,
                    CASE WHEN v_tpn = 'EFECTIVO' THEN NULL ELSE 'REF-' || p_num END, 'Pago factura ' || p_num);
        ELSIF p_forma = 'R' THEN
            cr_n := cr_n + 1;
            cr_fact(cr_n) := v_fv;
            cr_key(cr_n) := p_cli;
            cr_fecha(cr_n) := p_fecha;
            cr_total(cr_n) := v_tot;
            cr_abono(cr_n) := p_abono;
            cr_fabono(cr_n) := p_fabono;
            IF v_deuda.EXISTS(p_cli) THEN
                v_deuda(p_cli) := v_deuda(p_cli) + v_tot - p_abono;
            ELSE
                v_deuda(p_cli) := v_tot - p_abono;
            END IF;
        END IF;
    END venta;

    PROCEDURE dev_venta(p_fact VARCHAR2, p_cod VARCHAR2, p_motivo VARCHAR2, p_fecha DATE, p_nc VARCHAR2) IS
        v_dvl NUMBER; v_monto NUMBER; v_fv NUMBER; v_m NUMBER; v_e NUMBER; v_dv NUMBER;
    BEGIN
        SELECT dvl.id_detalle_venta_lote, ROUND(dvp.precio_unitario + dvp.monto_impuesto / dvp.cantidad, 2), fv.id_factura_venta
          INTO v_dvl, v_monto, v_fv
        FROM CP_DETALLE_VENTA_LOTE dvl
        JOIN CP_DETALLE_VENTA_PRODUCTO dvp ON dvp.id_detalle_venta_producto = dvl.id_detalle_venta_producto
        JOIN CP_FACTURA_VENTA fv ON fv.id_factura_venta = dvp.id_factura_venta
        JOIN CP_PRODUCTO p ON p.id_producto = dvp.id_producto
        WHERE fv.numero_factura = p_fact AND p.codigo_producto = p_cod AND ROWNUM = 1;
        SELECT id_motivo_devolucion INTO v_m FROM CP_MOTIVO_DEVOLUCION WHERE nombre_motivo_devolucion = p_motivo;
        SELECT id_estado_devolucion INTO v_e FROM CP_ESTADO_DEVOLUCION WHERE nombre_estado_devolucion = 'SOLICITADA';
        INSERT INTO CP_DEVOLUCION_VENTA (id_factura_venta, id_estado_devolucion, id_usuario, fecha_devolucion, monto_total, observacion)
        VALUES (v_fv, v_e, v_admin, p_fecha, v_monto, 'Devolucion ' || p_fact) RETURNING id_devolucion_venta INTO v_dv;
        INSERT INTO CP_DETALLE_DEVOLUCION_VENTA (id_devolucion_venta, id_detalle_venta_lote, id_motivo_devolucion, cantidad_devuelta, monto_devolucion)
        VALUES (v_dv, v_dvl, v_m, 1, v_monto);
        INSERT INTO CP_NOTA_CREDITO_CLIENTE (id_devolucion_venta, numero_nota_credito, fecha_emision, monto_nota_credito)
        VALUES (v_dv, p_nc, p_fecha, v_monto);
    END dev_venta;

    PROCEDURE dev_compra(p_compra VARCHAR2, p_cod VARCHAR2, p_motivo VARCHAR2, p_cant NUMBER, p_fecha DATE, p_nc VARCHAR2) IS
        v_fc NUMBER; v_lote NUMBER; v_m NUMBER; v_e NUMBER; v_dc NUMBER; v_costo NUMBER; v_monto NUMBER;
    BEGIN
        SELECT id_factura_compra INTO v_fc FROM CP_FACTURA_COMPRA WHERE numero_factura = p_compra;
        v_lote := lote_de(p_compra, p_cod);
        SELECT dc.precio_costo_unitario INTO v_costo
        FROM CP_DETALLE_COMPRA dc
        JOIN CP_PRODUCTO_PROVEEDOR pp ON pp.id_producto_proveedor = dc.id_producto_proveedor
        JOIN CP_PRODUCTO p ON p.id_producto = pp.id_producto
        WHERE dc.id_factura_compra = v_fc AND p.codigo_producto = p_cod;
        v_monto := p_cant * v_costo;
        SELECT id_motivo_devolucion INTO v_m FROM CP_MOTIVO_DEVOLUCION WHERE nombre_motivo_devolucion = p_motivo;
        SELECT id_estado_devolucion INTO v_e FROM CP_ESTADO_DEVOLUCION WHERE nombre_estado_devolucion = 'SOLICITADA';
        INSERT INTO CP_DEVOLUCION_COMPRA (id_factura_compra, id_estado_devolucion, id_usuario, fecha_devolucion, observacion)
        VALUES (v_fc, v_e, v_conta, p_fecha, 'Devolucion ' || p_compra) RETURNING id_devolucion_compra INTO v_dc;
        INSERT INTO CP_DETALLE_DEVOLUCION_COMPRA (id_devolucion_compra, id_lote_producto, id_motivo_devolucion, cantidad, monto_devolucion)
        VALUES (v_dc, v_lote, v_m, p_cant, v_monto);
        INSERT INTO CP_NOTA_CREDITO_PROVEEDOR (id_devolucion_compra, numero_nota_credito, fecha_emision, monto_nota_credito)
        VALUES (v_dc, p_nc, p_fecha, v_monto);
    END dev_compra;

BEGIN
    ----------------------------------------------------------
    -- Negocio, direcciones, sucursales y almacenes
    ----------------------------------------------------------
    SELECT id_tipo_negocio INTO v_id FROM CP_TIPO_NEGOCIO WHERE nombre_tipo_negocio = 'SUPERMERCADO';
    SELECT id_estado INTO v_est FROM CP_ESTADO WHERE nombre = 'ACTIVO';
    INSERT INTO CP_NEGOCIO (id_tipo_negocio, id_estado, cedula_juridica, nombre_negocio)
    VALUES (v_id, v_est, '3-101-745210', 'Supermercado Brunca') RETURNING id_negocio INTO v_negocio;

    v_dir(1)  := dir('Corredor',  'Barrio San Rafael, 200 metros sur de la Escuela Central de Ciudad Neily');
    v_dir(2)  := dir('Corredor',  'Urbanizacion Los Almendros, casa 14, Ciudad Neily');
    v_dir(3)  := dir('Corredor',  'Frente al Banco Nacional, Ciudad Neily centro');
    v_dir(4)  := dir('Canoas',    'Paso Canoas, 100 metros este de la Aduana Fronteriza');
    v_dir(5)  := dir('Canoas',    'Barrio Santa Marta, 150 metros norte de la plaza de Paso Canoas');
    v_dir(6)  := dir('San Vito',  'Contiguo al Parque Central de San Vito de Coto Brus');
    v_dir(7)  := dir('San Vito',  'Barrio Los Angeles, 300 metros oeste del Liceo de San Vito');
    v_dir(8)  := dir('La Cuesta', 'Centro de La Cuesta, 50 metros sur del Colegio');
    v_dir(9)  := dir('Sabalito',  'Sabalito, 400 metros sur del Salon Comunal');
    v_dir(10) := dir('Golfito',   'Barrio El Muelle, 100 metros oeste de la Terminal de Golfito');
    v_dir(11) := dir('Corredor',  'Calle Cementerio, 250 metros este de la Cruz Roja, Ciudad Neily');

    INSERT INTO CP_SUCURSAL (id_negocio, id_direccion, id_estado, codigo_sucursal, nombre_sucursal)
    VALUES (v_negocio, v_dir(3), v_est, 'SUC001', 'Sucursal Ciudad Neily') RETURNING id_sucursal INTO v_id;
    v_suc('SUC001') := v_id;
    INSERT INTO CP_SUCURSAL (id_negocio, id_direccion, id_estado, codigo_sucursal, nombre_sucursal)
    VALUES (v_negocio, v_dir(4), v_est, 'SUC002', 'Sucursal Paso Canoas') RETURNING id_sucursal INTO v_id;
    v_suc('SUC002') := v_id;
    INSERT INTO CP_SUCURSAL (id_negocio, id_direccion, id_estado, codigo_sucursal, nombre_sucursal)
    VALUES (v_negocio, v_dir(6), v_est, 'SUC003', 'Sucursal San Vito') RETURNING id_sucursal INTO v_id;
    v_suc('SUC003') := v_id;

    SELECT id_tipo_almacen INTO v_est2 FROM CP_TIPO_ALMACEN WHERE nombre_tipo_almacen = 'CENTRAL';
    INSERT INTO CP_ALMACEN (id_tipo_almacen, id_sucursal, id_estado, id_direccion, nombre_almacen)
    VALUES (v_est2, v_suc('SUC001'), v_est, v_dir(11), 'Almacen Central Ciudad Neily') RETURNING id_almacen INTO v_id;
    v_alm('SUC001') := v_id;
    SELECT id_tipo_almacen INTO v_est2 FROM CP_TIPO_ALMACEN WHERE nombre_tipo_almacen = 'SUCURSAL';
    INSERT INTO CP_ALMACEN (id_tipo_almacen, id_sucursal, id_estado, id_direccion, nombre_almacen)
    VALUES (v_est2, v_suc('SUC002'), v_est, v_dir(4), 'Almacen Paso Canoas') RETURNING id_almacen INTO v_id;
    v_alm('SUC002') := v_id;
    INSERT INTO CP_ALMACEN (id_tipo_almacen, id_sucursal, id_estado, id_direccion, nombre_almacen)
    VALUES (v_est2, v_suc('SUC003'), v_est, v_dir(7), 'Almacen San Vito') RETURNING id_almacen INTO v_id;
    v_alm('SUC003') := v_id;

    ----------------------------------------------------------
    -- Personal y usuarios
    ----------------------------------------------------------
    INSERT INTO CP_EMPRESA_LABORAL (cedula_juridica, razon_social, nombre_comercial)
    VALUES ('3-101-745210', 'Supermercado Brunca Sociedad Anonima', 'Supermercado Brunca') RETURNING id_empresa_laboral INTO v_empresa;

    v_p := persona('604230915','Cipriano','Antonio','Rivera','Escobar',DATE '1999-03-14','MASCULINO','SOLTERO','UNIVERSITARIA','FAMILIAR','S','ciprianoantonioriveraescobar+gerente@gmail.com',v_dir(2));
    v_admin := usuario(v_p, 'cipriano.rivera', 'SUC001', 'ADMINISTRADOR', 'ADMINISTRADOR', DATE '2026-01-05');
    v_p := persona('603980274','Marvin',NULL,'Torres','Sequeira',DATE '1998-07-22','MASCULINO','SOLTERO','UNIVERSITARIA','FAMILIAR','S','marvin.torres.sequeira+coordinador@est.una.ac.cr',v_dir(1));
    v_u := usuario(v_p, 'marvin.torres', 'SUC001', 'SUPERVISOR', 'SUPERVISOR', DATE '2026-01-05');
    v_p := persona('604120563','Daniela','Fernanda','Porras','Villalobos',DATE '1996-11-05','FEMENINO','SOLTERO','TECNICO','ALQUILADA','S','cipriano.rivera.escobar+dporras@est.una.ac.cr',v_dir(3));
    v_cajero('SUC001') := usuario(v_p, 'dporras', 'SUC001', 'CAJERO', 'CAJERO', DATE '2026-02-01');
    v_p := persona('603670821','Kevin','Alberto','Jimenez','Solis',DATE '1992-02-18','MASCULINO','CASADO','SECUNDARIA','PROPIA','S','cipriano.rivera.escobar+kjimenez@est.una.ac.cr',v_dir(11));
    v_u := usuario(v_p, 'kjimenez', 'SUC001', 'BODEGUERO', 'BODEGUERO', DATE '2026-02-01');
    v_p := persona('602890456','Priscilla','Maria','Montero','Acuna',DATE '1990-09-30','FEMENINO','CASADO','UNIVERSITARIA','PROPIA','S','cipriano.rivera.escobar+pmontero@est.una.ac.cr',v_dir(1));
    v_conta := usuario(v_p, 'pmontero', 'SUC001', 'CONTADOR', 'CONTADOR', DATE '2026-01-15');
    v_p := persona('604560178','Esteban','Jose','Calderon','Vega',DATE '1997-05-09','MASCULINO','SOLTERO','SECUNDARIA','FAMILIAR','S','cipriano.rivera.escobar+ecalderon@est.una.ac.cr',v_dir(5));
    v_cajero('SUC002') := usuario(v_p, 'ecalderon', 'SUC002', 'CAJERO', 'CAJERO', DATE '2026-02-10');
    v_p := persona('603340912','Melissa','Andrea','Brenes','Fallas',DATE '1995-12-01','FEMENINO','UNION LIBRE','TECNICO','ALQUILADA','S','cipriano.rivera.escobar+mbrenes@est.una.ac.cr',v_dir(7));
    v_cajero('SUC003') := usuario(v_p, 'mbrenes', 'SUC003', 'CAJERO', 'CAJERO', DATE '2026-02-15');

    PKG_CP_CONTEXTO.establecer_usuario(v_admin);

    ----------------------------------------------------------
    -- Clientes (personas, empresas y cliente de contado)
    ----------------------------------------------------------
    SELECT id_tipo_cliente INTO v_id FROM CP_TIPO_CLIENTE WHERE nombre_tipo_cliente = 'PERSONA';
    SELECT id_estado_cliente INTO v_est FROM CP_ESTADO_CLIENTE WHERE nombre_estado_cliente = 'ACTIVO';
    INSERT INTO CP_CLIENTE (id_tipo_cliente, id_estado_cliente, fecha_ingreso, es_cliente_defecto)
    VALUES (v_id, v_est, DATE '2026-01-05', 'S') RETURNING id_cliente INTO v_id;
    v_cliente('DEFECTO') := v_id;

    v_p := persona('601560234','Rosa','Elena','Mora','Quesada',DATE '1985-04-12','FEMENINO','CASADO','UNIVERSITARIA','PROPIA','S','ciprianoantonioriveraescobar@gmail.com',v_dir(1));
    cli_persona(v_p, '601560234', DATE '2026-02-03');
    v_p := persona('602340871','Jorge','Luis','Salazar','Barrantes',DATE '1979-10-03','MASCULINO','CASADO','SECUNDARIA','PROPIA','S','cipriano.rivera.escobar@est.una.ac.cr',v_dir(2));
    cli_persona(v_p, '602340871', DATE '2026-02-10');
    v_p := persona('603120945','Marta','Patricia','Vargas','Hidalgo',DATE '1988-06-27','FEMENINO','DIVORCIADO','TECNICO','ALQUILADA','S','marvin.torres.sequeira@est.una.ac.cr',v_dir(3));
    cli_persona(v_p, '603120945', DATE '2026-02-17');
    v_p := persona('701870312','Luis','Diego','Araya','Cordero',DATE '1993-01-19','MASCULINO','SOLTERO','UNIVERSITARIA','FAMILIAR','S','ciprianoantonioriveraescobar+ldaraya@gmail.com',v_dir(5));
    cli_persona(v_p, '701870312', DATE '2026-03-02');
    v_p := persona('604510277','Yendry','Carolina','Obando','Jimenez',DATE '1991-08-08','FEMENINO','UNION LIBRE','SECUNDARIA','ALQUILADA','S','ciprianoantonioriveraescobar+yobando@gmail.com',v_dir(7));
    cli_persona(v_p, '604510277', DATE '2026-03-09');
    v_p := persona('603890154','Ricardo','Jose','Mena','Zuniga',DATE '1982-12-15','MASCULINO','CASADO','PRIMARIA','PROPIA','N','marvin.torres.sequeira+rmena@est.una.ac.cr',v_dir(8));
    cli_persona(v_p, '603890154', DATE '2026-03-16');
    v_p := persona('105670321','Karla','Vanessa','Castro','Porras',DATE '1994-05-21','FEMENINO','SOLTERO','UNIVERSITARIA','ALQUILADA','S','cipriano.rivera.escobar+kcastro@est.una.ac.cr',v_dir(6));
    cli_persona(v_p, '105670321', DATE '2026-04-06');
    v_p := persona('603450618','Andres','Felipe','Rojas','Navarro',DATE '1989-09-09','MASCULINO','CASADO','TECNICO','PROPIA','S','ciprianoantonioriveraescobar+arojas@gmail.com',v_dir(9));
    cli_persona(v_p, '603450618', DATE '2026-04-13');
    v_p := persona('601980432','Silvia','Maria','Gamboa','Leiva',DATE '1976-02-02','FEMENINO','VIUDO','PRIMARIA','PROPIA','S','marvin.torres.sequeira+sgamboa@est.una.ac.cr',v_dir(10));
    cli_persona(v_p, '601980432', DATE '2026-05-04');
    v_p := persona('702150689','Fabian','Alonso','Chacon','Rodriguez',DATE '1997-07-30','MASCULINO','SOLTERO','UNIVERSITARIA','FAMILIAR','S','cipriano.rivera.escobar+fchacon@est.una.ac.cr',v_dir(4));
    cli_persona(v_p, '702150689', DATE '2026-05-11');

    cli_empresa('3-101-684127','Soda y Restaurante El Fogon del Sur Sociedad Anonima','Soda El Fogon del Sur','ciprianoantonioriveraescobar+sodaelfogon@gmail.com',v_dir(1),DATE '2026-02-20');
    cli_empresa('3-101-702356','Hotel Pacifico Sur Sociedad Anonima','Hotel Pacifico Sur','marvin.torres.sequeira+hotelpacifico@est.una.ac.cr',v_dir(4),DATE '2026-03-05');
    cli_empresa('3-101-659843','Panaderia La Espiga Dorada Sociedad Anonima','Panaderia La Espiga Dorada','cipriano.rivera.escobar+laespiga@est.una.ac.cr',v_dir(5),DATE '2026-03-23');
    cli_empresa('3-101-721504','Abastecedora de Comedores Coto Brus Sociedad Anonima','Comedores Coto Brus','ciprianoantonioriveraescobar+comedores@gmail.com',v_dir(7),DATE '2026-04-20');

    ----------------------------------------------------------
    -- Proveedores y productos
    ----------------------------------------------------------
    proveedor('3-101-598231','Comercial de Abarrotes Hermanos Quiros Sociedad Anonima','Abarrotes Hermanos Quiros','ciprianoantonioriveraescobar+prov1@gmail.com',v_dir(8),DATE '2026-01-10');
    proveedor('3-101-612904','Lacteos Coto Brus Sociedad Anonima','Lacteos Coto Brus','ciprianoantonioriveraescobar+prov2@gmail.com',v_dir(9),DATE '2026-01-10');
    proveedor('3-101-577316','Carnes y Embutidos Zona Sur Sociedad Anonima','Carnes Zona Sur','ciprianoantonioriveraescobar+prov3@gmail.com',v_dir(10),DATE '2026-01-12');
    proveedor('3-101-634478','Bebidas Tropicales de Costa Rica Sociedad Anonima','Bebidas Tropicales','ciprianoantonioriveraescobar+prov4@gmail.com',v_dir(2),DATE '2026-01-12');
    proveedor('3-101-589012','Distribuidora Agricola del Pacifico Sur Sociedad Anonima','Agricola Pacifico Sur','ciprianoantonioriveraescobar+prov5@gmail.com',v_dir(6),DATE '2026-01-15');
    proveedor('3-101-646750','Quimicos y Limpieza Centroamericana Sociedad Anonima','Limpieza Centroamericana','ciprianoantonioriveraescobar+prov6@gmail.com',v_dir(3),DATE '2026-01-15');

    producto('PROD001','Arroz blanco 99% grano entero 1 kg','Arroz blanco de grano entero, bolsa de 1 kilogramo','ABARROTES','IVA 1%','3-101-598231',850,1065,5);
    producto('PROD002','Frijoles negros 800 g','Frijoles negros seleccionados, bolsa de 800 gramos','ABARROTES','IVA 1%','3-101-598231',1250,1565,5);
    producto('PROD003','Azucar blanca 2 kg','Azucar blanca refinada, bolsa de 2 kilogramos','ABARROTES','IVA 1%','3-101-598231',1800,2250,5);
    producto('PROD004','Aceite vegetal 900 ml','Aceite vegetal comestible, botella de 900 ml','ABARROTES','IVA 1%','3-101-598231',2300,2875,5);
    producto('PROD005','Cafe molido 500 g','Cafe molido tostado, bolsa de 500 gramos','ABARROTES','IVA 13%','3-101-598231',3100,3875,10);
    producto('PROD006','Atun en agua 140 g','Atun en agua, lata de 140 gramos','ABARROTES','IVA 13%','3-101-598231',1050,1315,10);
    producto('PROD007','Pasta espagueti 400 g','Pasta espagueti, paquete de 400 gramos','ABARROTES','IVA 1%','3-101-598231',620,775,10);
    producto('PROD008','Leche entera 1 L','Leche entera pasteurizada, envase de 1 litro','LACTEOS','IVA 1%','3-101-612904',790,990,5);
    producto('PROD009','Queso tierno 500 g','Queso tierno fresco, paquete de 500 gramos','LACTEOS','IVA 1%','3-101-612904',2600,3250,10);
    producto('PROD010','Yogur natural 1 L','Yogur natural sin azucar, envase de 1 litro','LACTEOS','IVA 13%','3-101-612904',1450,1815,10);
    producto('PROD011','Pollo entero por kg','Pollo entero fresco, precio por kilogramo','CARNES','IVA 1%','3-101-577316',2400,3000,5);
    producto('PROD012','Carne molida de res por kg','Carne molida de res, precio por kilogramo','CARNES','IVA 1%','3-101-577316',4300,5375,5);
    producto('PROD013','Salchichon 500 g','Salchichon de cerdo y res, paquete de 500 gramos','CARNES','IVA 13%','3-101-577316',2100,2625,10);
    producto('PROD014','Tomate por kg','Tomate fresco, precio por kilogramo','VERDURAS','EXENTO','3-101-589012',900,1125,10);
    producto('PROD015','Papa por kg','Papa fresca, precio por kilogramo','VERDURAS','EXENTO','3-101-589012',750,940,10);
    producto('PROD016','Cebolla por kg','Cebolla amarilla, precio por kilogramo','VERDURAS','EXENTO','3-101-589012',800,1000,10);
    producto('PROD017','Gaseosa cola 2.5 L','Bebida gaseosa sabor cola, botella de 2.5 litros','BEBIDAS','IVA 13%','3-101-634478',1650,2065,10);
    producto('PROD018','Jugo de naranja 1 L','Jugo de naranja, envase de 1 litro','BEBIDAS','IVA 13%','3-101-634478',1100,1375,10);
    producto('PROD019','Agua purificada 600 ml','Agua purificada, botella de 600 ml','BEBIDAS','IVA 13%','3-101-634478',380,475,10);
    producto('PROD020','Detergente en polvo 1 kg','Detergente en polvo para ropa, bolsa de 1 kg','LIMPIEZA','IVA 13%','3-101-646750',2150,2690,10);
    producto('PROD021','Lavaplatos liquido 750 ml','Jabon liquido lavaplatos, botella de 750 ml','LIMPIEZA','IVA 13%','3-101-646750',1300,1625,10);
    producto('PROD022','Papel higienico 12 rollos','Papel higienico doble hoja, paquete de 12 rollos','LIMPIEZA','IVA 13%','3-101-646750',3400,4250,10);

    ----------------------------------------------------------
    -- Compras a proveedores (generan lotes con vencimiento
    -- relativo a SYSDATE). Las PENDIENTE crean cuenta por pagar.
    ----------------------------------------------------------
    compra('COMP-0001','3-101-598231','SUC001',DATE '2026-04-18','PAGADA',    'PROD003,80,420;PROD004,60,210;PROD005,40,260');
    compra('COMP-0002','3-101-598231','SUC001',DATE '2026-08-12','PENDIENTE', 'PROD001,300,330;PROD002,200,300;PROD003,150,400;PROD006,240,500;PROD007,200,360', 300000, DATE '2026-09-10');
    compra('COMP-0003','3-101-612904','SUC001',DATE '2026-08-14','PENDIENTE', 'PROD008,400,40;PROD009,80,5;PROD010,120,-6', 150000, DATE '2026-09-12');
    compra('COMP-0004','3-101-577316','SUC001',DATE '2026-09-02','PENDIENTE', 'PROD011,150,30;PROD012,120,25;PROD013,60,6', 100000, DATE '2026-10-05');
    compra('COMP-0005','3-101-634478','SUC001',DATE '2026-09-20','PENDIENTE', 'PROD017,200,180;PROD018,160,70;PROD019,600,300');
    compra('COMP-0006','3-101-589012','SUC001',DATE '2026-10-25','PENDIENTE', 'PROD014,120,7;PROD015,150,14;PROD016,100,12');
    compra('COMP-0007','3-101-646750','SUC001',DATE '2026-10-05','PENDIENTE', 'PROD020,100,700;PROD021,90,500;PROD022,80,800', 50000, DATE '2026-10-20');
    compra('COMP-0008','3-101-598231','SUC002',DATE '2026-09-05','PAGADA',    'PROD001,150,320;PROD002,100,290;PROD003,60,380;PROD006,120,480');
    compra('COMP-0009','3-101-612904','SUC002',DATE '2026-10-28','PAGADA',    'PROD008,150,25;PROD010,40,3');
    compra('COMP-0010','3-101-634478','SUC002',DATE '2026-10-10','PAGADA',    'PROD017,80,170;PROD019,300,290');
    compra('COMP-0011','3-101-598231','SUC003',DATE '2026-09-08','PAGADA',    'PROD001,120,310;PROD002,80,280;PROD003,50,370;PROD004,40,200;PROD007,90,340');
    compra('COMP-0012','3-101-589012','SUC003',DATE '2026-11-02','PAGADA',    'PROD014,60,9;PROD015,80,15;PROD016,50,13');
    compra('COMP-0013','3-101-612904','SUC003',DATE '2026-11-03','PAGADA',    'PROD008,100,28;PROD009,30,16');
    compra('COMP-0014','3-101-577316','SUC002',DATE '2026-10-20','PAGADA',    'PROD011,60,20;PROD012,40,18');

    ----------------------------------------------------------
    -- Ventas (contado C, credito R, emitida sin pago E)
    ----------------------------------------------------------
    venta('VENT-0001',DATE '2026-09-03','SUC001','DEFECTO','C','PROD001,3;PROD002,2;PROD008,4;PROD006,2');
    venta('VENT-0002',DATE '2026-09-05','SUC001','603120945','C','PROD011,2;PROD001,2;PROD008,3;PROD009,1');
    venta('VENT-0003',DATE '2026-09-09','SUC002','DEFECTO','C','PROD001,5;PROD003,2;PROD006,4');
    venta('VENT-0004',DATE '2026-09-12','SUC003','602340871','C','PROD001,4;PROD002,3;PROD007,6');
    venta('VENT-0005',DATE '2026-09-15','SUC001','601560234','C','PROD012,3;PROD013,2;PROD009,2;PROD002,2');
    venta('VENT-0007',DATE '2026-09-24','SUC001','DEFECTO','C','PROD017,3;PROD019,24;PROD018,4');
    venta('VENT-0008',DATE '2026-10-02','SUC001','701870312','C','PROD001,5;PROD002,4;PROD003,3;PROD011,3;PROD008,6');
    venta('VENT-0009',DATE '2026-10-08','SUC001','604510277','C','PROD020,2;PROD021,3;PROD022,2');
    venta('VENT-0020',DATE '2026-10-16','SUC001','105670321','C','PROD001,3;PROD017,2;PROD018,3;PROD013,1');
    venta('VENT-0021',DATE '2026-10-27','SUC001','603450618','C','PROD014,4;PROD015,5;PROD016,3;PROD011,2;PROD001,2');
    venta('VENT-0022',DATE '2026-11-02','SUC001','702150689','C','PROD012,2;PROD015,4;PROD008,4;PROD019,12');
    venta('VENT-0023',DATE '2026-11-07','SUC001','DEFECTO','C','PROD001,2;PROD007,3;PROD014,2;PROD008,2');
    venta('VENT-0025',DATE '2026-10-30','SUC002','701870312','C','PROD008,6;PROD011,3;PROD019,12');
    venta('VENT-0026',DATE '2026-11-09','SUC002','DEFECTO','C','PROD010,3;PROD008,4;PROD017,2;PROD012,2');
    venta('VENT-0027',DATE '2026-11-11','SUC003','604510277','C','PROD004,2;PROD007,5;PROD008,6;PROD015,3');
    venta('VENT-0028',DATE '2026-11-12','SUC001','DEFECTO','E','PROD001,2;PROD008,2;PROD019,6');

    venta('VENT-0010',DATE '2026-09-18','SUC001','3-101-684127','R','PROD011,30;PROD012,20;PROD001,25;PROD002,20;PROD004,10', 40000, DATE '2026-10-20');
    venta('VENT-0011',DATE '2026-09-22','SUC001','3-101-702356','R','PROD008,60;PROD009,10;PROD018,30;PROD004,8;PROD005,6', 20000, DATE '2026-09-28');
    venta('VENT-0012',DATE '2026-09-25','SUC002','603890154','R','PROD001,8;PROD003,4;PROD006,10');
    venta('VENT-0013',DATE '2026-10-06','SUC001','601560234','R','PROD001,10;PROD002,8;PROD003,6;PROD011,4;PROD008,10;PROD020,2', 5000, DATE '2026-11-05');
    venta('VENT-0014',DATE '2026-10-12','SUC003','602340871','R','PROD001,12;PROD002,10;PROD007,12;PROD003,5', 3000, DATE '2026-11-08');
    venta('VENT-0015',DATE '2026-10-20','SUC001','603120945','R','PROD012,6;PROD011,5;PROD017,6;PROD021,3;PROD022,2');
    venta('VENT-0016',DATE '2026-10-14','SUC001','3-101-684127','R','PROD011,25;PROD012,15;PROD017,12;PROD019,48');
    venta('VENT-0017',DATE '2026-10-22','SUC002','3-101-659843','R','PROD003,40;PROD001,30;PROD006,20;PROD017,12', 30000, DATE '2026-11-10');
    venta('VENT-0018',DATE '2026-11-04','SUC003','601980432','R','PROD014,5;PROD015,6;PROD008,3');
    venta('VENT-0019',DATE '2026-11-06','SUC003','3-101-721504','R','PROD001,40;PROD002,30;PROD016,20;PROD015,40;PROD014,25', 25000, DATE '2026-11-12');

    ----------------------------------------------------------
    -- Creditos de clientes (limite calculado segun el uso objetivo)
    ----------------------------------------------------------
    v_target('601560234') := 0.90;
    v_target('602340871') := 0.86;
    v_target('603120945') := 0.87;
    v_target('3-101-684127') := 0.88;
    v_target('3-101-702356') := 0.55;
    v_target('603890154') := 0.40;
    v_target('3-101-659843') := 0.30;
    v_target('601980432') := 0.25;
    v_target('3-101-721504') := 0.50;

    SELECT id_estado_credito INTO v_est FROM CP_ESTADO_CREDITO WHERE nombre_estado_credito = 'ACTIVO';
    k := v_deuda.FIRST;
    WHILE k IS NOT NULL LOOP
        v_ratio := CASE WHEN v_target.EXISTS(k) THEN v_target(k) ELSE 0.30 END;
        v_lim := FLOOR(v_deuda(k) / v_ratio / 1000) * 1000;
        INSERT INTO CP_CREDITO_CLIENTE (id_cliente, id_negocio, id_estado_credito, limite_credito, fecha_autorizacion, fecha_vencimiento)
        VALUES (v_cliente(k), v_negocio, v_est, v_lim, DATE '2026-08-15', DATE '2027-08-15') RETURNING id_credito_cliente INTO v_cred(k);
        k := v_deuda.NEXT(k);
    END LOOP;
    INSERT INTO CP_CREDITO_CLIENTE (id_cliente, id_negocio, id_estado_credito, limite_credito, fecha_autorizacion, fecha_vencimiento)
    VALUES (v_cliente('105670321'), v_negocio, v_est, 150000, DATE '2026-08-15', DATE '2027-08-15');
    INSERT INTO CP_CREDITO_CLIENTE (id_cliente, id_negocio, id_estado_credito, limite_credito, fecha_autorizacion, fecha_vencimiento)
    VALUES (v_cliente('603450618'), v_negocio, v_est, 200000, DATE '2026-08-15', DATE '2027-08-15');

    SELECT id_estado_cuenta_cobrar INTO v_est2 FROM CP_ESTADO_CUENTA_COBRAR WHERE nombre_estado_cuenta_cobrar = 'PENDIENTE';
    FOR n IN 1 .. cr_n LOOP
        INSERT INTO CP_CUENTA_COBRAR (id_factura_venta, id_credito_cliente, id_estado_cuenta_cobrar, fecha_creacion, fecha_vencimiento, observacion)
        VALUES (cr_fact(n), v_cred(cr_key(n)), v_est2, cr_fecha(n), cr_fecha(n) + 30, 'Cuenta por cobrar de la venta a credito ' || n)
        RETURNING id_cuenta_cobrar INTO v_id;
        IF cr_abono(n) > 0 THEN
            SELECT id_tipo_pago INTO v_l1 FROM CP_TIPO_PAGO WHERE nombre_tipo_pago = 'SINPE';
            INSERT INTO CP_ABONO_CUENTA_COBRAR (id_cuenta_cobrar, id_tipo_pago, id_usuario, monto_abono, fecha_abono, numero_referencia, observacion)
            VALUES (v_id, v_l1, v_cajero('SUC001'), cr_abono(n), cr_fabono(n) + 10/24, 'SINPE-AB-' || LPAD(n, 3, '0'), 'Abono del cliente');
        END IF;
    END LOOP;

    ----------------------------------------------------------
    -- Creditos de proveedores (limite segun el uso objetivo)
    ----------------------------------------------------------
    v_targetP('3-101-598231') := 0.88;
    v_targetP('3-101-612904') := 0.72;
    v_targetP('3-101-577316') := 0.76;
    v_targetP('3-101-634478') := 0.45;
    v_targetP('3-101-589012') := 0.86;
    v_targetP('3-101-646750') := 0.35;
    k := v_deudaP.FIRST;
    WHILE k IS NOT NULL LOOP
        v_lim := FLOOR(v_deudaP(k) / v_targetP(k) / 1000) * 1000;
        SELECT id_proveedor INTO v_id FROM CP_PROVEEDOR WHERE cedula_juridica = k;
        INSERT INTO CP_CREDITO_PROVEEDOR (id_proveedor, id_negocio, id_estado_credito, limite_credito, fecha_autorizacion, fecha_vencimiento)
        VALUES (v_id, v_negocio, v_est, v_lim, DATE '2026-08-01', DATE '2027-08-01') RETURNING id_credito_proveedor INTO v_credP(k);
        k := v_deudaP.NEXT(k);
    END LOOP;

    ----------------------------------------------------------
    -- Inventario por almacen (existencias = recibido - vendido)
    ----------------------------------------------------------
    v_id := v_disp.FIRST;
    WHILE v_id IS NOT NULL LOOP
        INSERT INTO CP_INVENTARIO_ALMACEN (id_almacen, id_lote_producto, cantidad_actual, fecha_actualizacion)
        VALUES (v_almL(v_id), v_id, v_disp(v_id), SYSTIMESTAMP);
        v_id := v_disp.NEXT(v_id);
    END LOOP;

    ----------------------------------------------------------
    -- Traslados entre almacenes (en proceso)
    ----------------------------------------------------------
    SELECT id_estado_traslado INTO v_est FROM CP_ESTADO_TRASLADO WHERE nombre_estado_traslado = 'EN PROCESO';
    INSERT INTO CP_TRASLADO (id_almacen_origen, id_almacen_destino, id_usuario_solicita, id_estado_traslado, fecha_solicitud, observacion)
    VALUES (v_alm('SUC001'), v_alm('SUC002'), v_cajero('SUC002'), v_est, TIMESTAMP '2026-11-10 08:00:00', 'Reposicion de frijoles para Paso Canoas')
    RETURNING id_traslado INTO v_tr;
    v_lote_id := lote_de('COMP-0002','PROD002');
    INSERT INTO CP_DETALLE_TRASLADO (id_traslado, id_lote_producto, cantidad) VALUES (v_tr, v_lote_id, 20);
    INSERT INTO CP_TRASLADO (id_almacen_origen, id_almacen_destino, id_usuario_solicita, id_estado_traslado, fecha_solicitud, observacion)
    VALUES (v_alm('SUC001'), v_alm('SUC003'), v_cajero('SUC003'), v_est, TIMESTAMP '2026-11-12 08:30:00', 'Reposicion de leche para San Vito')
    RETURNING id_traslado INTO v_tr;
    v_lote_id := lote_de('COMP-0003','PROD008');
    INSERT INTO CP_DETALLE_TRASLADO (id_traslado, id_lote_producto, cantidad) VALUES (v_tr, v_lote_id, 30);

    ----------------------------------------------------------
    -- Devoluciones y notas de credito
    ----------------------------------------------------------
    dev_venta('VENT-0005','PROD012','PRODUCTO DANADO',DATE '2026-09-16','NC-C-0001');
    dev_venta('VENT-0008','PROD011','CALIDAD DEL PRODUCTO',DATE '2026-10-03','NC-C-0002');
    dev_venta('VENT-0022','PROD019','PRODUCTO INCORRECTO',DATE '2026-11-04','NC-C-0003');
    dev_compra('COMP-0003','PROD010','PRODUCTO VENCIDO',10,DATE '2026-11-10','NC-P-0001');
    dev_compra('COMP-0004','PROD013','CALIDAD DEL PRODUCTO',2,DATE '2026-09-10','NC-P-0002');

    ----------------------------------------------------------
    -- Promociones (cantidad de patrocinadores por accion)
    ----------------------------------------------------------
    SELECT id_estado_promocion INTO v_est FROM CP_ESTADO_PROMOCION WHERE nombre_estado_promocion = 'ACTIVA';
    SELECT id_estado_promocion INTO v_est2 FROM CP_ESTADO_PROMOCION WHERE nombre_estado_promocion = 'PROGRAMADA';

    INSERT INTO CP_PROMOCION (id_estado_promocion, id_negocio, nombre_promocion, descripcion, fecha_inicio, fecha_final)
    VALUES (v_est, v_negocio, 'Lleve 2 Arroz y reciba 1 Frijoles', 'Por cada 2 arroz de 1 kg se regala 1 bolsa de frijoles de 800 g', DATE '2026-11-01', DATE '2026-12-31')
    RETURNING id_promocion INTO v_prom;
    SELECT id_accion_promocion INTO v_id FROM CP_ACCION_PROMOCION WHERE nombre_accion_promocion = 'ENTREGAR PRODUCTO';
    INSERT INTO CP_REGLA_PROMOCION (id_promocion, id_accion_promocion, cantidad_acciones, descripcion)
    VALUES (v_prom, v_id, 1, 'Entrega 1 frijoles por cada grupo de arroz') RETURNING id_regla_promocion INTO v_regla;
    INSERT INTO CP_PROMOCION_PATROCINADOR (id_regla_promocion, id_producto, cantidad_requerida)
    SELECT v_regla, id_producto, 2 FROM CP_PRODUCTO WHERE codigo_producto = 'PROD001';
    INSERT INTO CP_PROMOCION_PREMIO (id_regla_promocion, id_producto_premio, cantidad_premio)
    SELECT v_regla, id_producto, 1 FROM CP_PRODUCTO WHERE codigo_producto = 'PROD002';

    INSERT INTO CP_PROMOCION (id_estado_promocion, id_negocio, nombre_promocion, descripcion, fecha_inicio, fecha_final)
    VALUES (v_est, v_negocio, 'Compre 3 Gaseosas y lleve 2 Aguas', 'Por cada 3 gaseosas de 2.5 L se regalan 2 aguas de 600 ml', DATE '2026-11-01', DATE '2026-12-31')
    RETURNING id_promocion INTO v_prom;
    INSERT INTO CP_REGLA_PROMOCION (id_promocion, id_accion_promocion, cantidad_acciones, descripcion)
    VALUES (v_prom, v_id, 1, 'Entrega aguas por cada grupo de gaseosas') RETURNING id_regla_promocion INTO v_regla;
    INSERT INTO CP_PROMOCION_PATROCINADOR (id_regla_promocion, id_producto, cantidad_requerida)
    SELECT v_regla, id_producto, 3 FROM CP_PRODUCTO WHERE codigo_producto = 'PROD017';
    INSERT INTO CP_PROMOCION_PREMIO (id_regla_promocion, id_producto_premio, cantidad_premio)
    SELECT v_regla, id_producto, 2 FROM CP_PRODUCTO WHERE codigo_producto = 'PROD019';

    INSERT INTO CP_PROMOCION (id_estado_promocion, id_negocio, nombre_promocion, descripcion, fecha_inicio, fecha_final)
    VALUES (v_est, v_negocio, 'Cafe y azucar', 'Por cada 2 cafes de 500 g se regala 1 azucar de 2 kg', DATE '2026-11-01', DATE '2026-12-31')
    RETURNING id_promocion INTO v_prom;
    INSERT INTO CP_REGLA_PROMOCION (id_promocion, id_accion_promocion, cantidad_acciones, descripcion)
    VALUES (v_prom, v_id, 1, 'Entrega azucar por cada grupo de cafe') RETURNING id_regla_promocion INTO v_regla;
    INSERT INTO CP_PROMOCION_PATROCINADOR (id_regla_promocion, id_producto, cantidad_requerida)
    SELECT v_regla, id_producto, 2 FROM CP_PRODUCTO WHERE codigo_producto = 'PROD005';
    INSERT INTO CP_PROMOCION_PREMIO (id_regla_promocion, id_producto_premio, cantidad_premio)
    SELECT v_regla, id_producto, 1 FROM CP_PRODUCTO WHERE codigo_producto = 'PROD003';

    INSERT INTO CP_PROMOCION (id_estado_promocion, id_negocio, nombre_promocion, descripcion, fecha_inicio, fecha_final)
    VALUES (v_est, v_negocio, 'Puntos por limpieza del hogar', 'Se acumulan 5 puntos por cada detergente en polvo comprado', DATE '2026-11-01', DATE '2026-12-31')
    RETURNING id_promocion INTO v_prom;
    SELECT id_accion_promocion INTO v_id FROM CP_ACCION_PROMOCION WHERE nombre_accion_promocion = 'ACUMULAR PUNTOS';
    INSERT INTO CP_REGLA_PROMOCION (id_promocion, id_accion_promocion, cantidad_acciones, descripcion)
    VALUES (v_prom, v_id, 5, 'Acumula 5 puntos por cada detergente') RETURNING id_regla_promocion INTO v_regla;
    INSERT INTO CP_PROMOCION_PATROCINADOR (id_regla_promocion, id_producto, cantidad_requerida)
    SELECT v_regla, id_producto, 1 FROM CP_PRODUCTO WHERE codigo_producto = 'PROD020';

    INSERT INTO CP_PROMOCION (id_estado_promocion, id_negocio, nombre_promocion, descripcion, fecha_inicio, fecha_final)
    VALUES (v_est2, v_negocio, 'Navidad: queso con descuento', 'Descuento al comprar 2 quesos tiernos, programada para diciembre', DATE '2026-12-01', DATE '2026-12-24')
    RETURNING id_promocion INTO v_prom;
    SELECT id_accion_promocion INTO v_id FROM CP_ACCION_PROMOCION WHERE nombre_accion_promocion = 'APLICAR DESCUENTO';
    INSERT INTO CP_REGLA_PROMOCION (id_promocion, id_accion_promocion, cantidad_acciones, descripcion)
    VALUES (v_prom, v_id, 1, 'Aplica descuento por cada par de quesos') RETURNING id_regla_promocion INTO v_regla;
    INSERT INTO CP_PROMOCION_PATROCINADOR (id_regla_promocion, id_producto, cantidad_requerida)
    SELECT v_regla, id_producto, 2 FROM CP_PRODUCTO WHERE codigo_producto = 'PROD009';

    ----------------------------------------------------------
    -- Descuentos programados
    ----------------------------------------------------------
    SELECT id_estado_descuento INTO v_est FROM CP_ESTADO_DESCUENTO WHERE nombre_estado_descuento = 'ACTIVO';

    INSERT INTO CP_DESCUENTO (id_negocio, id_estado_descuento, nombre_descuento, porcentaje_descuento, fecha_inicio, fecha_final, descripcion)
    VALUES (v_negocio, v_est, 'Liquidacion de lacteos proximos a vencer', 20, DATE '2026-11-01', DATE '2026-12-31', 'Descuento a lacteos que vencen en los proximos 10 dias')
    RETURNING id_descuento INTO v_desc;
    INSERT INTO CP_DESCUENTO_FAMILIA (id_descuento, id_familia_producto) SELECT v_desc, id_familia_producto FROM CP_FAMILIA_PRODUCTO WHERE nombre_familia = 'LACTEOS';
    INSERT INTO CP_DESCUENTO_VENCIMIENTO (id_descuento, dias_antes_vencimiento) VALUES (v_desc, 10);

    INSERT INTO CP_DESCUENTO (id_negocio, id_estado_descuento, nombre_descuento, porcentaje_descuento, fecha_inicio, fecha_final, descripcion)
    VALUES (v_negocio, v_est, 'Rebaja por antiguedad en bodega', 15, DATE '2026-11-01', DATE '2026-12-31', 'Descuento a abarrotes con mas de 6 meses en bodega')
    RETURNING id_descuento INTO v_desc;
    INSERT INTO CP_DESCUENTO_FAMILIA (id_descuento, id_familia_producto) SELECT v_desc, id_familia_producto FROM CP_FAMILIA_PRODUCTO WHERE nombre_familia = 'ABARROTES';
    INSERT INTO CP_DESCUENTO_FECHA_INGRESO (id_descuento, fecha_ingreso_desde, fecha_ingreso_hasta) VALUES (v_desc, DATE '2026-01-01', DATE '2026-05-14');

    INSERT INTO CP_DESCUENTO (id_negocio, id_estado_descuento, nombre_descuento, porcentaje_descuento, fecha_inicio, fecha_final, descripcion)
    VALUES (v_negocio, v_est, 'Verduras de temporada', 10, DATE '2026-11-01', DATE '2026-12-31', 'Descuento a verduras que vencen en los proximos 7 dias')
    RETURNING id_descuento INTO v_desc;
    INSERT INTO CP_DESCUENTO_FAMILIA (id_descuento, id_familia_producto) SELECT v_desc, id_familia_producto FROM CP_FAMILIA_PRODUCTO WHERE nombre_familia = 'VERDURAS';
    INSERT INTO CP_DESCUENTO_VENCIMIENTO (id_descuento, dias_antes_vencimiento) VALUES (v_desc, 7);

    INSERT INTO CP_DESCUENTO (id_negocio, id_estado_descuento, nombre_descuento, porcentaje_descuento, fecha_inicio, fecha_final, descripcion)
    VALUES (v_negocio, v_est, 'Promocion del proveedor de bebidas', 8, DATE '2026-11-01', DATE '2026-12-31', 'Descuento a productos del proveedor Bebidas Tropicales')
    RETURNING id_descuento INTO v_desc;
    INSERT INTO CP_DESCUENTO_PROVEEDOR (id_descuento, id_proveedor) SELECT v_desc, id_proveedor FROM CP_PROVEEDOR WHERE cedula_juridica = '3-101-634478';
    INSERT INTO CP_DESCUENTO_VENCIMIENTO (id_descuento, dias_antes_vencimiento) VALUES (v_desc, 30);

    INSERT INTO CP_DESCUENTO (id_negocio, id_estado_descuento, nombre_descuento, porcentaje_descuento, fecha_inicio, fecha_final, descripcion)
    VALUES (v_negocio, v_est, 'Limpieza del hogar', 12, DATE '2026-11-01', DATE '2026-12-31', 'Descuento a productos de limpieza ingresados antes de junio')
    RETURNING id_descuento INTO v_desc;
    INSERT INTO CP_DESCUENTO_FAMILIA (id_descuento, id_familia_producto) SELECT v_desc, id_familia_producto FROM CP_FAMILIA_PRODUCTO WHERE nombre_familia = 'LIMPIEZA';
    INSERT INTO CP_DESCUENTO_FECHA_INGRESO (id_descuento, fecha_ingreso_desde, fecha_ingreso_hasta) VALUES (v_desc, DATE '2026-01-01', DATE '2026-05-31');

    ----------------------------------------------------------
    -- Bitacoras (se llenan con los triggers al modificar datos)
    ----------------------------------------------------------
    UPDATE CP_PRODUCTO_NEGOCIO SET precio_venta_actual = precio_venta_actual + 75
    WHERE id_negocio = v_negocio AND id_producto = (SELECT id_producto FROM CP_PRODUCTO WHERE codigo_producto = 'PROD012');
    UPDATE CP_PRODUCTO_NEGOCIO SET precio_venta_actual = precio_venta_actual + 25
    WHERE id_negocio = v_negocio AND id_producto = (SELECT id_producto FROM CP_PRODUCTO WHERE codigo_producto = 'PROD004');
    UPDATE CP_PRODUCTO_NEGOCIO SET precio_venta_actual = precio_venta_actual + 35
    WHERE id_negocio = v_negocio AND id_producto = (SELECT id_producto FROM CP_PRODUCTO WHERE codigo_producto = 'PROD017');

    v_lote_id := lote_de('COMP-0004','PROD013');
    UPDATE CP_INVENTARIO_ALMACEN SET cantidad_actual = cantidad_actual - 1
    WHERE id_lote_producto = v_lote_id AND cantidad_actual > 1;
    v_lote_id := lote_de('COMP-0005','PROD019');
    UPDATE CP_INVENTARIO_ALMACEN SET cantidad_actual = cantidad_actual + 2
    WHERE id_lote_producto = v_lote_id;

    UPDATE CP_CREDITO_CLIENTE SET limite_credito = limite_credito + 10000 WHERE id_credito_cliente = v_cred('3-101-702356');
    UPDATE CP_CREDITO_CLIENTE SET limite_credito = limite_credito + 10000 WHERE id_credito_cliente = v_cred('3-101-659843');
    UPDATE CP_CREDITO_PROVEEDOR SET limite_credito = limite_credito + 20000 WHERE id_credito_proveedor = v_credP('3-101-646750');

    UPDATE CP_FACTURA_VENTA
    SET id_estado_factura_venta = (SELECT id_estado_factura_venta FROM CP_ESTADO_FACTURA_VENTA WHERE nombre_estado_factura = 'PAGADA')
    WHERE numero_factura = 'VENT-0028';
    SELECT id_tipo_pago INTO v_l1 FROM CP_TIPO_PAGO WHERE nombre_tipo_pago = 'EFECTIVO';
    INSERT INTO CP_PAGO_FACTURA_VENTA (id_factura_venta, id_tipo_pago, id_usuario, fecha_pago, monto_pago, numero_referencia, observacion)
    SELECT id_factura_venta, v_l1, v_cajero('SUC001'), TIMESTAMP '2026-11-12 16:30:00', total, NULL, 'Pago factura VENT-0028'
    FROM CP_FACTURA_VENTA WHERE numero_factura = 'VENT-0028';

    SELECT id_estado_devolucion INTO v_est FROM CP_ESTADO_DEVOLUCION WHERE nombre_estado_devolucion = 'APROBADA';
    UPDATE CP_DEVOLUCION_VENTA SET id_estado_devolucion = v_est WHERE observacion = 'Devolucion VENT-0005';
    UPDATE CP_DEVOLUCION_VENTA SET id_estado_devolucion = v_est WHERE observacion = 'Devolucion VENT-0008';
    UPDATE CP_DEVOLUCION_COMPRA SET id_estado_devolucion = v_est WHERE observacion = 'Devolucion COMP-0004';

    INSERT INTO CP_BITACORA_ACCESO (id_usuario, nombre_usuario_intento, tipo_acceso, resultado, direccion_ip, observacion)
    VALUES (v_admin, 'cipriano.rivera', 'INICIO_SESION', 'EXITOSO', '192.168.1.10', 'Inicio de sesion correcto');
    INSERT INTO CP_BITACORA_ACCESO (id_usuario, nombre_usuario_intento, tipo_acceso, resultado, direccion_ip, observacion)
    VALUES (v_admin, 'cipriano.rivera', 'CIERRE_SESION', 'EXITOSO', '192.168.1.10', 'Cierre de sesion correcto');
    INSERT INTO CP_BITACORA_ACCESO (id_usuario, nombre_usuario_intento, tipo_acceso, resultado, direccion_ip, observacion)
    VALUES (v_cajero('SUC002'), 'ecalderon', 'INICIO_SESION', 'EXITOSO', '192.168.1.21', 'Inicio de sesion correcto');
    INSERT INTO CP_BITACORA_ACCESO (id_usuario, nombre_usuario_intento, tipo_acceso, resultado, direccion_ip, observacion)
    VALUES (NULL, 'usuario_inexistente', 'INICIO_SESION', 'FALLIDO', '192.168.1.50', 'Usuario no registrado');
    INSERT INTO CP_BITACORA_ACCESO (id_usuario, nombre_usuario_intento, tipo_acceso, resultado, direccion_ip, observacion)
    VALUES (NULL, 'mbrenes', 'INICIO_SESION', 'FALLIDO', '192.168.1.51', 'Clave incorrecta');

    PKG_CP_CONTEXTO.limpiar_usuario;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Datos de la defensa cargados correctamente.');
END;
/


-- ============================================================
-- 3. DATOS COMPLEMENTARIOS PARA COBERTURA DE TODAS LAS TABLAS
-- Completa las tablas que no recibian filas en la carga original.
-- CP_PADRON_NACIONAL se deja intencionalmente vacia.
-- ============================================================

DECLARE
    v_negocio       NUMBER;
    v_estado        NUMBER;
    v_impuesto      NUMBER;
    v_servicio      NUMBER;
    v_cliente       NUMBER;
    v_sucursal      NUMBER;
    v_usuario       NUMBER;
    v_estado_fact   NUMBER;
    v_factura       NUMBER;
    v_descuento     NUMBER;
    v_detalle       NUMBER;
    v_contacto      NUMBER;
    v_destinatario  NUMBER := 0;
    v_cantidad      NUMBER;
    v_total         NUMBER(14,2);
    v_pp            NUMBER;
    v_costo         NUMBER(14,2);
BEGIN
    SELECT id_negocio INTO v_negocio FROM CP_NEGOCIO WHERE nombre_negocio = 'Supermercado Brunca';
    SELECT id_estado INTO v_estado FROM CP_ESTADO WHERE nombre = 'ACTIVO';
    SELECT id_impuesto INTO v_impuesto FROM CP_IMPUESTO WHERE nombre_impuesto = 'IVA 13%';

    -- Servicio de entrega y factura de muestra con su detalle asociado.
    INSERT INTO CP_SERVICIO (
        id_negocio, id_impuesto, id_estado, codigo_servicio,
        nombre_servicio, descripcion, precio_servicio
    ) VALUES (
        v_negocio, v_impuesto, v_estado, 'SRV-ENTREGA-001',
        'Entrega local', 'Entrega de compras dentro de la zona de cobertura', 2000
    ) RETURNING id_servicio INTO v_servicio;

    SELECT id_cliente INTO v_cliente FROM CP_CLIENTE WHERE es_cliente_defecto = 'S';
    SELECT id_sucursal INTO v_sucursal FROM CP_SUCURSAL WHERE codigo_sucursal = 'SUC001';
    SELECT id_usuario INTO v_usuario FROM CP_USUARIO WHERE nombre_usuario = 'dporras';
    SELECT id_estado_factura_venta INTO v_estado_fact
      FROM CP_ESTADO_FACTURA_VENTA WHERE nombre_estado_factura = 'EMITIDA';

    INSERT INTO CP_FACTURA_VENTA (
        id_cliente, id_sucursal, id_usuario, id_estado_factura_venta,
        numero_factura, fecha_emision, subtotal, descuento_total,
        impuesto_total, total
    ) VALUES (
        v_cliente, v_sucursal, v_usuario, v_estado_fact,
        'VENT-SRV-0001', DATE '2026-11-13', 2000, 0, 260, 2260
    ) RETURNING id_factura_venta INTO v_factura;

    INSERT INTO CP_DETALLE_VENTA_SERVICIO (
        id_factura_venta, id_servicio, cantidad, precio_unitario,
        porcentaje_descuento, monto_descuento, porcentaje_impuesto,
        monto_impuesto, subtotal, total
    ) VALUES (v_factura, v_servicio, 1, 2000, 0, 0, 13, 260, 2000, 2260);

    -- Asociar el descuento de verduras a producto vendido durante su vigencia.
    SELECT id_descuento INTO v_descuento
      FROM CP_DESCUENTO WHERE nombre_descuento = 'Verduras de temporada';

    SELECT dv.id_detalle_venta_producto INTO v_detalle
    FROM CP_DETALLE_VENTA_PRODUCTO dv
    JOIN CP_FACTURA_VENTA fv ON fv.id_factura_venta = dv.id_factura_venta
    JOIN CP_PRODUCTO p ON p.id_producto = dv.id_producto
    WHERE fv.numero_factura = 'VENT-0022' AND p.codigo_producto = 'PROD015';

    INSERT INTO CP_DESCUENTO_APLICADO (
        id_detalle_venta_producto, id_descuento, monto_aplicado
    ) VALUES (v_detalle, v_descuento, 376);

    INSERT INTO CP_DESCUENTO_PRODUCTO (
        id_descuento_producto, id_descuento, id_producto,
        fecha_inicio, fecha_fin, activo
    )
    SELECT 1, v_descuento, id_producto, DATE '2026-11-01', DATE '2026-12-31', 'S'
    FROM CP_PRODUCTO WHERE codigo_producto = 'PROD015';

    -- Tipos para campañas de temporada, volumen y fidelidad.
    INSERT INTO CP_TIPO_PROMOCION VALUES (1, 'TEMPORADA', 'Promocion asociada a fechas comerciales');
    INSERT INTO CP_TIPO_PROMOCION VALUES (2, 'VOLUMEN', 'Beneficio por compra de varias unidades');
    INSERT INTO CP_TIPO_PROMOCION VALUES (3, 'LEALTAD', 'Beneficio para clientes frecuentes');

    -- Cierre diario de SUC001 a partir de las ventas ya cargadas.
    SELECT COUNT(*), NVL(SUM(total), 0) INTO v_cantidad, v_total
    FROM CP_FACTURA_VENTA
    WHERE id_sucursal = v_sucursal AND TRUNC(fecha_emision) = DATE '2026-11-12';

    INSERT INTO CP_CIERRE_DIARIO (
        id_cierre_diario, id_sucursal, fecha_cierre, total_ventas, total_devoluciones
    ) VALUES (1, v_sucursal, DATE '2026-11-12', v_total, 0);

    INSERT INTO CP_DETALLE_CIERRE_DIARIO (
        id_detalle_cierre_diario, id_cierre_diario, id_usuario,
        cantidad_ventas, cantidad_devoluciones, total_ventas, total_devoluciones
    ) VALUES (1, 1, v_usuario, v_cantidad, 0, v_total, 0);

    -- Los siguientes datos de correo son demostrativos: no se envia email.
    -- clave_cifrada contiene bytes ficticios, NO una credencial cifrada real.
    SELECT id_contacto INTO v_contacto
    FROM CP_CONTACTO
    WHERE valor_contacto = 'ciprianoantonioriveraescobar@gmail.com' AND ROWNUM = 1;

    INSERT INTO CP_CONFIGURACION_CORREO (
        id_configuracion_correo, id_contacto_remitente, servidor_smtp,
        puerto_smtp, usuario_smtp, clave_cifrada, requiere_tls, activo
    ) VALUES (
        1, v_contacto, 'smtp.example.com', 587,
        'notificaciones@supermercadobrunca.example',
        HEXTORAW('DEADBEEFCAFEBABEDEADBEEFCAFEBABEDEADBEEFCAFEBABEDEADBEEFCAFEBABE'), 'S', 'S'
    );

    FOR r IN (
        SELECT MIN(c.id_contacto) AS id_contacto, c.valor_contacto
        FROM CP_CONTACTO c
        JOIN CP_TIPO_DE_CONTACTO tc ON tc.id_tipo_contacto = c.id_tipo_contacto
        WHERE tc.nombre_tipo_contacto = 'CORREO'
          AND c.valor_contacto IN (
              'ciprianoantonioriveraescobar@gmail.com',
              'cipriano.rivera.escobar@est.una.ac.cr',
              'marvin.torres.sequeira@est.una.ac.cr'
          )
        GROUP BY c.valor_contacto
        ORDER BY c.valor_contacto
    ) LOOP
        v_destinatario := v_destinatario + 1;
        INSERT INTO CP_DESTINATARIO_NOTIFICACION (id_destinatario, id_contacto, activo)
        VALUES (v_destinatario, r.id_contacto, 'S');
    END LOOP;

    IF v_destinatario = 0 THEN
        RAISE_APPLICATION_ERROR(-20031, 'No se encontraron correos para destinatarios de muestra.');
    END IF;

    INSERT INTO CP_NOTIFICACION (
        id_notificacion, id_configuracion_correo, asunto, mensaje, tipo_notificacion
    ) VALUES (
        1, 1, 'Resumen de promociones - Supermercado Brunca',
        'Registro de demostracion; esta fila no envia correo automaticamente.', 'DEFENSA'
    );

    FOR r IN (SELECT id_destinatario FROM CP_DESTINATARIO_NOTIFICACION ORDER BY id_destinatario) LOOP
        INSERT INTO CP_NOTIFICACION_DESTINATARIO (
            id_notificacion_destinatario, id_notificacion, id_destinatario, estado_envio
        ) VALUES (r.id_destinatario, 1, r.id_destinatario, 'PENDIENTE');
    END LOOP;

    -- Premiacion de muestra: tres clientes existentes, sin datos de padron.
    INSERT INTO CP_EJECUCION_PREMIACION (
        id_ejecucion_premiacion, fecha_ejecucion, fecha_inicio_periodo,
        fecha_fin_periodo, monto_premio, cantidad_premiados
    ) VALUES (
        1, TIMESTAMP '2026-05-01 01:15:00', DATE '2025-11-01',
        DATE '2026-04-30', 100000, 3
    );

    INSERT INTO CP_ORDEN_PREMIO_CLIENTE (
        id_orden_premio_cliente, id_ejecucion_premiacion, id_cliente, posicion,
        monto_premio, fecha_emision
    )
    SELECT 1, 1, c.id_cliente, 1, 100000, TIMESTAMP '2026-05-01 01:15:00'
    FROM CP_CLIENTE c JOIN CP_CLIENTE_PERSONA cp ON cp.id_cliente = c.id_cliente
    JOIN CP_PERSONA p ON p.id_persona = cp.id_persona
    WHERE p.identificacion = '601560234';

    INSERT INTO CP_ORDEN_PREMIO_CLIENTE (
        id_orden_premio_cliente, id_ejecucion_premiacion, id_cliente, posicion,
        monto_premio, fecha_emision
    )
    SELECT 2, 1, c.id_cliente, 2, 100000, TIMESTAMP '2026-05-01 01:15:00'
    FROM CP_CLIENTE c JOIN CP_CLIENTE_PERSONA cp ON cp.id_cliente = c.id_cliente
    JOIN CP_PERSONA p ON p.id_persona = cp.id_persona
    WHERE p.identificacion = '602340871';

    INSERT INTO CP_ORDEN_PREMIO_CLIENTE (
        id_orden_premio_cliente, id_ejecucion_premiacion, id_cliente, posicion,
        monto_premio, fecha_emision
    )
    SELECT 3, 1, c.id_cliente, 3, 100000, TIMESTAMP '2026-05-01 01:15:00'
    FROM CP_CLIENTE c JOIN CP_CLIENTE_PERSONA cp ON cp.id_cliente = c.id_cliente
    JOIN CP_PERSONA p ON p.id_persona = cp.id_persona
    WHERE p.identificacion = '603120945';

    -- Bitacoras adicionales para los modulos nuevos de la defensa.
    SELECT c.id_cliente INTO v_cliente
    FROM CP_CLIENTE_PERSONA cp JOIN CP_PERSONA p ON p.id_persona = cp.id_persona
    JOIN CP_CLIENTE c ON c.id_cliente = cp.id_cliente
    WHERE p.identificacion = '601560234';

    INSERT INTO CP_BITACORA_CLIENTE (
        id_cliente, id_usuario, operacion, valor_anterior, valor_nuevo
    ) VALUES (v_cliente, v_usuario, 'CREACION', NULL, 'Alta inicial del cliente de muestra');

    SELECT pp.id_producto_proveedor, pp.precio_costo_actual INTO v_pp, v_costo
    FROM CP_PRODUCTO_PROVEEDOR pp JOIN CP_PRODUCTO p ON p.id_producto = pp.id_producto
    WHERE p.codigo_producto = 'PROD001' AND ROWNUM = 1;

    UPDATE CP_PRODUCTO_PROVEEDOR
    SET precio_costo_actual = v_costo + 25
    WHERE id_producto_proveedor = v_pp;

    INSERT INTO CP_BITACORA_COSTO_PRODUCTO (
        id_producto_proveedor, id_usuario, costo_anterior, costo_nuevo
    ) VALUES (v_pp, v_usuario, v_costo, v_costo + 25);

    INSERT INTO CP_BITACORA_DESCUENTO (
        id_descuento, id_usuario, operacion, valor_anterior, valor_nuevo
    ) VALUES (v_descuento, v_usuario, 'CREACION', NULL,
              'Descuento de temporada para verduras: 10 por ciento');

    INSERT INTO CP_BITACORA_ERROR (
        modulo, codigo_error, mensaje_error, detalle_error
    ) VALUES ('CARGA_DEFENSA', -20001,
              'Evento sintetico de demostracion de bitacora',
              'No representa un error real ni una falla de carga.');

    INSERT INTO CP_BITACORA_PROMOCION (
        id_promocion, id_usuario, operacion, valor_anterior, valor_nuevo
    )
    SELECT id_promocion, v_usuario, 'CREACION', NULL,
           'Promocion activa cargada para la defensa'
    FROM CP_PROMOCION
    WHERE nombre_promocion = 'Lleve 2 Arroz y reciba 1 Frijoles';

    INSERT INTO CP_BITACORA_PROVEEDOR (
        id_proveedor, id_usuario, operacion, valor_anterior, valor_nuevo
    )
    SELECT id_proveedor, v_usuario, 'CREACION', NULL,
           'Proveedor de abarrotes cargado para la defensa'
    FROM CP_PROVEEDOR
    WHERE cedula_juridica = '3-101-598231';

    -- Un traslado se marca recibido para que el trigger genere su bitacora.
    UPDATE CP_TRASLADO
    SET id_estado_traslado = (
        SELECT id_estado_traslado FROM CP_ESTADO_TRASLADO
        WHERE nombre_estado_traslado = 'RECIBIDO'
    )
    WHERE observacion = 'Reposicion de leche para San Vito'
      AND id_estado_traslado = (
        SELECT id_estado_traslado FROM CP_ESTADO_TRASLADO
        WHERE nombre_estado_traslado = 'EN PROCESO'
    );

    COMMIT;
END;
/
-- ============================================================
-- 4. VERIFICACION DE COBERTURA
-- En el esquema completo hay 116 tablas CP_* con datos y una tabla de padron vacia.
-- ============================================================

DECLARE
    v_count NUMBER;
    v_tables NUMBER := 0;
    v_padron NUMBER;
BEGIN
    FOR r IN (
        SELECT table_name FROM user_tables
        WHERE table_name LIKE 'CP\_%' ESCAPE '\'
          AND table_name <> 'CP_PADRON_NACIONAL'
        ORDER BY table_name
    ) LOOP
        EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM ' || r.table_name INTO v_count;
        v_tables := v_tables + 1;
        DBMS_OUTPUT.PUT_LINE(RPAD(r.table_name, 42) || TO_CHAR(v_count));
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20041, 'La tabla ' || r.table_name || ' quedo sin datos.');
        END IF;
    END LOOP;

    IF v_tables <> 116 THEN
        RAISE_APPLICATION_ERROR(-20042, 'Se esperaban 116 tablas CP_* distintas del padron; se encontraron ' || v_tables || '.');
    END IF;

    SELECT COUNT(*) INTO v_padron FROM CP_PADRON_NACIONAL;
    DBMS_OUTPUT.PUT_LINE(RPAD('CP_PADRON_NACIONAL', 42) || TO_CHAR(v_padron) || ' (debe ser cero)');
    IF v_padron <> 0 THEN
        RAISE_APPLICATION_ERROR(-20043, 'CP_PADRON_NACIONAL debe permanecer vacia.');
    END IF;
END;
/

COMMIT;


-- ============================================================
-- 5. AJUSTE DE SECUENCIAS
-- ============================================================

DECLARE
    v_default   VARCHAR2(4000);
    v_sequence  VARCHAR2(128);
    v_max_id    NUMBER;
    v_next      NUMBER;
    v_adjusted  PLS_INTEGER := 0;
BEGIN
    FOR r IN (
        SELECT c.table_name, c.column_name, c.data_default
        FROM user_tab_columns c
        JOIN user_cons_columns cc
          ON cc.table_name = c.table_name
         AND cc.column_name = c.column_name
        JOIN user_constraints k
          ON k.constraint_name = cc.constraint_name
         AND k.constraint_type = 'P'
        WHERE c.table_name LIKE 'CP\_%' ESCAPE '\'
    ) LOOP
        v_default  := UPPER(r.data_default);
        v_sequence := REGEXP_SUBSTR(v_default, '"?([A-Z0-9_$#]+)"?\."?NEXTVAL', 1, 1, NULL, 1);

        IF v_sequence IS NOT NULL THEN
            EXECUTE IMMEDIATE
                'SELECT NVL(MAX(' || r.column_name || '), 0) FROM ' || r.table_name
                INTO v_max_id;

            SELECT last_number INTO v_next
            FROM user_sequences
            WHERE sequence_name = v_sequence;

            IF v_next <= v_max_id THEN
                EXECUTE IMMEDIATE
                    'ALTER SEQUENCE ' || v_sequence || ' RESTART START WITH ' || TO_CHAR(v_max_id + 1);
                v_adjusted := v_adjusted + 1;
                DBMS_OUTPUT.PUT_LINE(RPAD(v_sequence, 42) || TO_CHAR(v_next) || ' -> ' || TO_CHAR(v_max_id + 1));
            END IF;
        END IF;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('Secuencias ajustadas: ' || v_adjusted);
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20044, 'No se pudieron ajustar las secuencias: ' || SQLERRM);
END;
/
