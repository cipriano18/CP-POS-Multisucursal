
-- ============================================================
-- 09_datos_prueba_FINAL_CORREGIDO.sql
-- Revisado contra el 04_tablas.sql actual del proyecto.
-- Correcciones principales:
--   * CP_NEGOCIO usa nombre_negocio.
--   * llamada a PKG_CP_CONTEXTO corregida para PL/SQL.
--   * CP_ESTADO_FACTURA_VENTA usa nombre_estado_factura.
-- ============================================================

-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- SCRIPT: 09_datos_prueba.sql
-- BLOQUE: TABLAS 1 A 20
-- USUARIO: CP_POS
-- ============================================================


-- ============================================================
-- 1. CP_TIPO_NEGOCIO
-- Un solo tipo de negocio para toda la instancia
-- ============================================================

INSERT INTO CP_TIPO_NEGOCIO
(nombre_tipo_negocio, descripcion)
VALUES
('SUPERMERCADO', 'Venta de productos de consumo general');


-- ============================================================
-- 3. CP_ESTADO
-- Se inserta antes de CP_NEGOCIO por dependencia FK
-- ============================================================

INSERT INTO CP_ESTADO (nombre, descripcion)
VALUES ('ACTIVO', 'Registro activo en el sistema');

INSERT INTO CP_ESTADO (nombre, descripcion)
VALUES ('INACTIVO', 'Registro inactivo en el sistema');

INSERT INTO CP_ESTADO (nombre, descripcion)
VALUES ('SUSPENDIDO', 'Registro suspendido temporalmente');

INSERT INTO CP_ESTADO (nombre, descripcion)
VALUES ('BLOQUEADO', 'Registro bloqueado en el sistema');

INSERT INTO CP_ESTADO (nombre, descripcion)
VALUES ('PENDIENTE', 'Registro pendiente de activacion');


-- ============================================================
-- 2. CP_NEGOCIO
-- Se pueden tener varios negocios, pero todos deben utilizar
-- el mismo tipo de negocio: SUPERMERCADO
-- ============================================================

INSERT INTO CP_NEGOCIO
(id_tipo_negocio, id_estado, cedula_juridica, nombre_negocio)
SELECT
    tn.id_tipo_negocio,
    e.id_estado,
    '3-101-100001',
    'Super Rivera'
FROM CP_TIPO_NEGOCIO tn
CROSS JOIN CP_ESTADO e
WHERE tn.nombre_tipo_negocio = 'SUPERMERCADO'
AND e.nombre = 'ACTIVO';

INSERT INTO CP_NEGOCIO
(id_tipo_negocio, id_estado, cedula_juridica, nombre_negocio)
SELECT
    tn.id_tipo_negocio,
    e.id_estado,
    '3-101-100002',
    'Super del Sur'
FROM CP_TIPO_NEGOCIO tn
CROSS JOIN CP_ESTADO e
WHERE tn.nombre_tipo_negocio = 'SUPERMERCADO'
AND e.nombre = 'ACTIVO';

INSERT INTO CP_NEGOCIO
(id_tipo_negocio, id_estado, cedula_juridica, nombre_negocio)
SELECT
    tn.id_tipo_negocio,
    e.id_estado,
    '3-101-100003',
    'Mercado Brunca'
FROM CP_TIPO_NEGOCIO tn
CROSS JOIN CP_ESTADO e
WHERE tn.nombre_tipo_negocio = 'SUPERMERCADO'
AND e.nombre = 'ACTIVO';

INSERT INTO CP_NEGOCIO
(id_tipo_negocio, id_estado, cedula_juridica, nombre_negocio)
SELECT
    tn.id_tipo_negocio,
    e.id_estado,
    '3-101-100004',
    'Super Pacifico'
FROM CP_TIPO_NEGOCIO tn
CROSS JOIN CP_ESTADO e
WHERE tn.nombre_tipo_negocio = 'SUPERMERCADO'
AND e.nombre = 'ACTIVO';

INSERT INTO CP_NEGOCIO
(id_tipo_negocio, id_estado, cedula_juridica, nombre_negocio)
SELECT
    tn.id_tipo_negocio,
    e.id_estado,
    '3-101-100005',
    'Super Valle'
FROM CP_TIPO_NEGOCIO tn
CROSS JOIN CP_ESTADO e
WHERE tn.nombre_tipo_negocio = 'SUPERMERCADO'
AND e.nombre = 'ACTIVO';


-- ============================================================
-- 4. CP_TIPO_OPERACION
-- MODIFICACION es requerido por los triggers del script 07
-- ============================================================

INSERT INTO CP_TIPO_OPERACION
(nombre_tipo_operacion, descripcion)
VALUES ('CREACION', 'Creacion de un registro');

INSERT INTO CP_TIPO_OPERACION
(nombre_tipo_operacion, descripcion)
VALUES ('MODIFICACION', 'Modificacion de un registro');

INSERT INTO CP_TIPO_OPERACION
(nombre_tipo_operacion, descripcion)
VALUES ('ELIMINACION', 'Eliminacion de un registro');

INSERT INTO CP_TIPO_OPERACION
(nombre_tipo_operacion, descripcion)
VALUES ('ENTRADA', 'Entrada de inventario');

INSERT INTO CP_TIPO_OPERACION
(nombre_tipo_operacion, descripcion)
VALUES ('SALIDA', 'Salida de inventario');


-- ============================================================
-- 5. CP_PROVINCIA
-- ============================================================

INSERT INTO CP_PROVINCIA (nombre)
VALUES ('San Jose');

INSERT INTO CP_PROVINCIA (nombre)
VALUES ('Alajuela');

INSERT INTO CP_PROVINCIA (nombre)
VALUES ('Cartago');

INSERT INTO CP_PROVINCIA (nombre)
VALUES ('Heredia');

INSERT INTO CP_PROVINCIA (nombre)
VALUES ('Puntarenas');


-- ============================================================
-- 6. CP_CANTON
-- ============================================================

INSERT INTO CP_CANTON (id_provincia, nombre)
SELECT id_provincia, 'San Jose'
FROM CP_PROVINCIA
WHERE nombre = 'San Jose';

INSERT INTO CP_CANTON (id_provincia, nombre)
SELECT id_provincia, 'Alajuela'
FROM CP_PROVINCIA
WHERE nombre = 'Alajuela';

INSERT INTO CP_CANTON (id_provincia, nombre)
SELECT id_provincia, 'Cartago'
FROM CP_PROVINCIA
WHERE nombre = 'Cartago';

INSERT INTO CP_CANTON (id_provincia, nombre)
SELECT id_provincia, 'Heredia'
FROM CP_PROVINCIA
WHERE nombre = 'Heredia';

INSERT INTO CP_CANTON (id_provincia, nombre)
SELECT id_provincia, 'Corredores'
FROM CP_PROVINCIA
WHERE nombre = 'Puntarenas';


-- ============================================================
-- 7. CP_DISTRITO
-- ============================================================

INSERT INTO CP_DISTRITO (id_canton, nombre)
SELECT id_canton, 'Carmen'
FROM CP_CANTON
WHERE nombre = 'San Jose';

INSERT INTO CP_DISTRITO (id_canton, nombre)
SELECT id_canton, 'Alajuela'
FROM CP_CANTON
WHERE nombre = 'Alajuela';

INSERT INTO CP_DISTRITO (id_canton, nombre)
SELECT id_canton, 'Oriental'
FROM CP_CANTON
WHERE nombre = 'Cartago';

INSERT INTO CP_DISTRITO (id_canton, nombre)
SELECT id_canton, 'Heredia'
FROM CP_CANTON
WHERE nombre = 'Heredia';

INSERT INTO CP_DISTRITO (id_canton, nombre)
SELECT id_canton, 'Canoas'
FROM CP_CANTON
WHERE nombre = 'Corredores';


-- ============================================================
-- 8. CP_DIRECCION
-- ============================================================

INSERT INTO CP_DIRECCION
(id_distrito, otras_senas)
SELECT id_distrito,
       '100 metros norte del parque central'
FROM CP_DISTRITO
WHERE nombre = 'Carmen';

INSERT INTO CP_DIRECCION
(id_distrito, otras_senas)
SELECT id_distrito,
       '200 metros este de la iglesia'
FROM CP_DISTRITO
WHERE nombre = 'Alajuela';

INSERT INTO CP_DIRECCION
(id_distrito, otras_senas)
SELECT id_distrito,
       'Frente al parque principal'
FROM CP_DISTRITO
WHERE nombre = 'Oriental';

INSERT INTO CP_DIRECCION
(id_distrito, otras_senas)
SELECT id_distrito,
       '150 metros oeste del centro'
FROM CP_DISTRITO
WHERE nombre = 'Heredia';

INSERT INTO CP_DIRECCION
(id_distrito, otras_senas)
SELECT id_distrito,
       'Costado norte de la carretera principal'
FROM CP_DISTRITO
WHERE nombre = 'Canoas';


-- ============================================================
-- 9. CP_TIPO_DIRECCION
-- ============================================================

INSERT INTO CP_TIPO_DIRECCION
(nombre_tipo_direccion, descripcion)
VALUES ('RESIDENCIA', 'Direccion de residencia');

INSERT INTO CP_TIPO_DIRECCION
(nombre_tipo_direccion, descripcion)
VALUES ('TRABAJO', 'Direccion del lugar de trabajo');

INSERT INTO CP_TIPO_DIRECCION
(nombre_tipo_direccion, descripcion)
VALUES ('COMERCIAL', 'Direccion comercial');

INSERT INTO CP_TIPO_DIRECCION
(nombre_tipo_direccion, descripcion)
VALUES ('FACTURACION', 'Direccion utilizada para facturacion');

INSERT INTO CP_TIPO_DIRECCION
(nombre_tipo_direccion, descripcion)
VALUES ('ENTREGA', 'Direccion utilizada para entregas');


-- ============================================================
-- 10. CP_SUCURSAL
-- ============================================================

INSERT INTO CP_SUCURSAL
(id_negocio, id_direccion, id_estado,
 codigo_sucursal, nombre_sucursal)
SELECT
    n.id_negocio,
    d.id_direccion,
    e.id_estado,
    'SUC001',
    'Sucursal San Jose'
FROM CP_NEGOCIO n
CROSS JOIN CP_DIRECCION d
CROSS JOIN CP_ESTADO e
WHERE n.cedula_juridica = '3-101-100001'
AND d.otras_senas = '100 metros norte del parque central'
AND e.nombre = 'ACTIVO';

INSERT INTO CP_SUCURSAL
(id_negocio, id_direccion, id_estado,
 codigo_sucursal, nombre_sucursal)
SELECT
    n.id_negocio,
    d.id_direccion,
    e.id_estado,
    'SUC002',
    'Sucursal Alajuela'
FROM CP_NEGOCIO n
CROSS JOIN CP_DIRECCION d
CROSS JOIN CP_ESTADO e
WHERE n.cedula_juridica = '3-101-100002'
AND d.otras_senas = '200 metros este de la iglesia'
AND e.nombre = 'ACTIVO';

INSERT INTO CP_SUCURSAL
(id_negocio, id_direccion, id_estado,
 codigo_sucursal, nombre_sucursal)
SELECT
    n.id_negocio,
    d.id_direccion,
    e.id_estado,
    'SUC003',
    'Sucursal Cartago'
FROM CP_NEGOCIO n
CROSS JOIN CP_DIRECCION d
CROSS JOIN CP_ESTADO e
WHERE n.cedula_juridica = '3-101-100003'
AND d.otras_senas = 'Frente al parque principal'
AND e.nombre = 'ACTIVO';

INSERT INTO CP_SUCURSAL
(id_negocio, id_direccion, id_estado,
 codigo_sucursal, nombre_sucursal)
SELECT
    n.id_negocio,
    d.id_direccion,
    e.id_estado,
    'SUC004',
    'Sucursal Heredia'
FROM CP_NEGOCIO n
CROSS JOIN CP_DIRECCION d
CROSS JOIN CP_ESTADO e
WHERE n.cedula_juridica = '3-101-100004'
AND d.otras_senas = '150 metros oeste del centro'
AND e.nombre = 'ACTIVO';

INSERT INTO CP_SUCURSAL
(id_negocio, id_direccion, id_estado,
 codigo_sucursal, nombre_sucursal)
SELECT
    n.id_negocio,
    d.id_direccion,
    e.id_estado,
    'SUC005',
    'Sucursal Canoas'
FROM CP_NEGOCIO n
CROSS JOIN CP_DIRECCION d
CROSS JOIN CP_ESTADO e
WHERE n.cedula_juridica = '3-101-100005'
AND d.otras_senas = 'Costado norte de la carretera principal'
AND e.nombre = 'ACTIVO';


-- ============================================================
-- 11. CP_NACIONALIDAD
-- ============================================================

INSERT INTO CP_NACIONALIDAD (nombre_nacionalidad)
VALUES ('Costarricense');

INSERT INTO CP_NACIONALIDAD (nombre_nacionalidad)
VALUES ('Panamena');

INSERT INTO CP_NACIONALIDAD (nombre_nacionalidad)
VALUES ('Nicaraguense');

INSERT INTO CP_NACIONALIDAD (nombre_nacionalidad)
VALUES ('Colombiana');

INSERT INTO CP_NACIONALIDAD (nombre_nacionalidad)
VALUES ('Mexicana');


-- ============================================================
-- 12. CP_SEXO
-- Catalogo de dominio: no se inventan valores solo para llegar a 5
-- ============================================================

INSERT INTO CP_SEXO (nombre_sexo)
VALUES ('MASCULINO');

INSERT INTO CP_SEXO (nombre_sexo)
VALUES ('FEMENINO');

INSERT INTO CP_SEXO (nombre_sexo)
VALUES ('NO INDICA');


-- ============================================================
-- 13. CP_ESTADO_CIVIL
-- ============================================================

INSERT INTO CP_ESTADO_CIVIL (nombre_estado_civil)
VALUES ('SOLTERO');

INSERT INTO CP_ESTADO_CIVIL (nombre_estado_civil)
VALUES ('CASADO');

INSERT INTO CP_ESTADO_CIVIL (nombre_estado_civil)
VALUES ('DIVORCIADO');

INSERT INTO CP_ESTADO_CIVIL (nombre_estado_civil)
VALUES ('VIUDO');

INSERT INTO CP_ESTADO_CIVIL (nombre_estado_civil)
VALUES ('UNION LIBRE');


-- ============================================================
-- 14. CP_ESCOLARIDAD
-- ============================================================

INSERT INTO CP_ESCOLARIDAD (nombre_escolaridad)
VALUES ('PRIMARIA');

INSERT INTO CP_ESCOLARIDAD (nombre_escolaridad)
VALUES ('SECUNDARIA');

INSERT INTO CP_ESCOLARIDAD (nombre_escolaridad)
VALUES ('TECNICO');

INSERT INTO CP_ESCOLARIDAD (nombre_escolaridad)
VALUES ('UNIVERSITARIA');

INSERT INTO CP_ESCOLARIDAD (nombre_escolaridad)
VALUES ('POSGRADO');


-- ============================================================
-- 15. CP_TIPO_RESIDENCIA
-- ============================================================

INSERT INTO CP_TIPO_RESIDENCIA (nombre_tipo_residencia)
VALUES ('PROPIA');

INSERT INTO CP_TIPO_RESIDENCIA (nombre_tipo_residencia)
VALUES ('ALQUILADA');

INSERT INTO CP_TIPO_RESIDENCIA (nombre_tipo_residencia)
VALUES ('FAMILIAR');

INSERT INTO CP_TIPO_RESIDENCIA (nombre_tipo_residencia)
VALUES ('PRESTADA');

INSERT INTO CP_TIPO_RESIDENCIA (nombre_tipo_residencia)
VALUES ('OTRA');


-- ============================================================
-- 16. CP_PERSONA
-- ============================================================

INSERT INTO CP_PERSONA
(id_nacionalidad, id_estado_civil, id_sexo,
 id_escolaridad, id_tipo_residencia,
 identificacion, primer_nombre, segundo_nombre,
 primer_apellido, segundo_apellido,
 fecha_nacimiento, es_asegurado)
SELECT
    n.id_nacionalidad,
    ec.id_estado_civil,
    s.id_sexo,
    es.id_escolaridad,
    tr.id_tipo_residencia,
    '101110111',
    'Carlos',
    NULL,
    'Mora',
    'Rojas',
    DATE '1990-05-10',
    'S'
FROM CP_NACIONALIDAD n
CROSS JOIN CP_ESTADO_CIVIL ec
CROSS JOIN CP_SEXO s
CROSS JOIN CP_ESCOLARIDAD es
CROSS JOIN CP_TIPO_RESIDENCIA tr
WHERE n.nombre_nacionalidad = 'Costarricense'
AND ec.nombre_estado_civil = 'SOLTERO'
AND s.nombre_sexo = 'MASCULINO'
AND es.nombre_escolaridad = 'UNIVERSITARIA'
AND tr.nombre_tipo_residencia = 'PROPIA';


INSERT INTO CP_PERSONA
(id_nacionalidad, id_estado_civil, id_sexo,
 id_escolaridad, id_tipo_residencia,
 identificacion, primer_nombre, segundo_nombre,
 primer_apellido, segundo_apellido,
 fecha_nacimiento, es_asegurado)
SELECT
    n.id_nacionalidad,
    ec.id_estado_civil,
    s.id_sexo,
    es.id_escolaridad,
    tr.id_tipo_residencia,
    '202220222',
    'Maria',
    'Fernanda',
    'Jimenez',
    'Soto',
    DATE '1995-08-20',
    'S'
FROM CP_NACIONALIDAD n
CROSS JOIN CP_ESTADO_CIVIL ec
CROSS JOIN CP_SEXO s
CROSS JOIN CP_ESCOLARIDAD es
CROSS JOIN CP_TIPO_RESIDENCIA tr
WHERE n.nombre_nacionalidad = 'Costarricense'
AND ec.nombre_estado_civil = 'CASADO'
AND s.nombre_sexo = 'FEMENINO'
AND es.nombre_escolaridad = 'UNIVERSITARIA'
AND tr.nombre_tipo_residencia = 'ALQUILADA';


INSERT INTO CP_PERSONA
(id_nacionalidad, id_estado_civil, id_sexo,
 id_escolaridad, id_tipo_residencia,
 identificacion, primer_nombre, segundo_nombre,
 primer_apellido, segundo_apellido,
 fecha_nacimiento, es_asegurado)
SELECT
    n.id_nacionalidad,
    ec.id_estado_civil,
    s.id_sexo,
    es.id_escolaridad,
    tr.id_tipo_residencia,
    '303330333',
    'Luis',
    'Alberto',
    'Vargas',
    'Solano',
    DATE '1988-03-15',
    'S'
FROM CP_NACIONALIDAD n
CROSS JOIN CP_ESTADO_CIVIL ec
CROSS JOIN CP_SEXO s
CROSS JOIN CP_ESCOLARIDAD es
CROSS JOIN CP_TIPO_RESIDENCIA tr
WHERE n.nombre_nacionalidad = 'Costarricense'
AND ec.nombre_estado_civil = 'CASADO'
AND s.nombre_sexo = 'MASCULINO'
AND es.nombre_escolaridad = 'SECUNDARIA'
AND tr.nombre_tipo_residencia = 'PROPIA';


INSERT INTO CP_PERSONA
(id_nacionalidad, id_estado_civil, id_sexo,
 id_escolaridad, id_tipo_residencia,
 identificacion, primer_nombre, segundo_nombre,
 primer_apellido, segundo_apellido,
 fecha_nacimiento, es_asegurado)
SELECT
    n.id_nacionalidad,
    ec.id_estado_civil,
    s.id_sexo,
    es.id_escolaridad,
    tr.id_tipo_residencia,
    '404440444',
    'Ana',
    'Maria',
    'Rodriguez',
    'Castro',
    DATE '1998-11-25',
    'S'
FROM CP_NACIONALIDAD n
CROSS JOIN CP_ESTADO_CIVIL ec
CROSS JOIN CP_SEXO s
CROSS JOIN CP_ESCOLARIDAD es
CROSS JOIN CP_TIPO_RESIDENCIA tr
WHERE n.nombre_nacionalidad = 'Costarricense'
AND ec.nombre_estado_civil = 'SOLTERO'
AND s.nombre_sexo = 'FEMENINO'
AND es.nombre_escolaridad = 'TECNICO'
AND tr.nombre_tipo_residencia = 'FAMILIAR';


INSERT INTO CP_PERSONA
(id_nacionalidad, id_estado_civil, id_sexo,
 id_escolaridad, id_tipo_residencia,
 identificacion, primer_nombre, segundo_nombre,
 primer_apellido, segundo_apellido,
 fecha_nacimiento, es_asegurado)
SELECT
    n.id_nacionalidad,
    ec.id_estado_civil,
    s.id_sexo,
    es.id_escolaridad,
    tr.id_tipo_residencia,
    '505550555',
    'Jose',
    NULL,
    'Quesada',
    'Perez',
    DATE '1985-07-01',
    'N'
FROM CP_NACIONALIDAD n
CROSS JOIN CP_ESTADO_CIVIL ec
CROSS JOIN CP_SEXO s
CROSS JOIN CP_ESCOLARIDAD es
CROSS JOIN CP_TIPO_RESIDENCIA tr
WHERE n.nombre_nacionalidad = 'Costarricense'
AND ec.nombre_estado_civil = 'DIVORCIADO'
AND s.nombre_sexo = 'MASCULINO'
AND es.nombre_escolaridad = 'SECUNDARIA'
AND tr.nombre_tipo_residencia = 'ALQUILADA';


-- ============================================================
-- 17. CP_TIPO_DE_CONTACTO
-- Catalogo de dominio
-- ============================================================

INSERT INTO CP_TIPO_DE_CONTACTO
(nombre_tipo_contacto, descripcion)
VALUES ('TELEFONO', 'Numero telefonico');

INSERT INTO CP_TIPO_DE_CONTACTO
(nombre_tipo_contacto, descripcion)
VALUES ('CELULAR', 'Numero de telefono celular');

INSERT INTO CP_TIPO_DE_CONTACTO
(nombre_tipo_contacto, descripcion)
VALUES ('CORREO', 'Direccion de correo electronico');

INSERT INTO CP_TIPO_DE_CONTACTO
(nombre_tipo_contacto, descripcion)
VALUES ('FAX', 'Numero de fax');


-- ============================================================
-- 18. CP_CONTACTO
-- ============================================================

INSERT INTO CP_CONTACTO
(id_tipo_contacto, valor_contacto)
SELECT id_tipo_contacto, '8888-1001'
FROM CP_TIPO_DE_CONTACTO
WHERE nombre_tipo_contacto = 'CELULAR';

INSERT INTO CP_CONTACTO
(id_tipo_contacto, valor_contacto)
SELECT id_tipo_contacto, '8888-1002'
FROM CP_TIPO_DE_CONTACTO
WHERE nombre_tipo_contacto = 'CELULAR';

INSERT INTO CP_CONTACTO
(id_tipo_contacto, valor_contacto)
SELECT id_tipo_contacto, '8888-1003'
FROM CP_TIPO_DE_CONTACTO
WHERE nombre_tipo_contacto = 'CELULAR';

INSERT INTO CP_CONTACTO
(id_tipo_contacto, valor_contacto)
SELECT id_tipo_contacto, '8888-1004'
FROM CP_TIPO_DE_CONTACTO
WHERE nombre_tipo_contacto = 'CELULAR';

INSERT INTO CP_CONTACTO
(id_tipo_contacto, valor_contacto)
SELECT id_tipo_contacto, '8888-1005'
FROM CP_TIPO_DE_CONTACTO
WHERE nombre_tipo_contacto = 'CELULAR';


-- ============================================================
-- 19. CP_PERSONA_DIRECCION
-- ============================================================

INSERT INTO CP_PERSONA_DIRECCION
(id_persona, id_direccion, id_tipo_direccion, es_principal)
SELECT
    p.id_persona,
    d.id_direccion,
    td.id_tipo_direccion,
    'S'
FROM CP_PERSONA p
CROSS JOIN CP_DIRECCION d
CROSS JOIN CP_TIPO_DIRECCION td
WHERE p.identificacion = '101110111'
AND d.otras_senas = '100 metros norte del parque central'
AND td.nombre_tipo_direccion = 'RESIDENCIA';

INSERT INTO CP_PERSONA_DIRECCION
(id_persona, id_direccion, id_tipo_direccion, es_principal)
SELECT
    p.id_persona,
    d.id_direccion,
    td.id_tipo_direccion,
    'S'
FROM CP_PERSONA p
CROSS JOIN CP_DIRECCION d
CROSS JOIN CP_TIPO_DIRECCION td
WHERE p.identificacion = '202220222'
AND d.otras_senas = '200 metros este de la iglesia'
AND td.nombre_tipo_direccion = 'RESIDENCIA';

INSERT INTO CP_PERSONA_DIRECCION
(id_persona, id_direccion, id_tipo_direccion, es_principal)
SELECT
    p.id_persona,
    d.id_direccion,
    td.id_tipo_direccion,
    'S'
FROM CP_PERSONA p
CROSS JOIN CP_DIRECCION d
CROSS JOIN CP_TIPO_DIRECCION td
WHERE p.identificacion = '303330333'
AND d.otras_senas = 'Frente al parque principal'
AND td.nombre_tipo_direccion = 'RESIDENCIA';

INSERT INTO CP_PERSONA_DIRECCION
(id_persona, id_direccion, id_tipo_direccion, es_principal)
SELECT
    p.id_persona,
    d.id_direccion,
    td.id_tipo_direccion,
    'S'
FROM CP_PERSONA p
CROSS JOIN CP_DIRECCION d
CROSS JOIN CP_TIPO_DIRECCION td
WHERE p.identificacion = '404440444'
AND d.otras_senas = '150 metros oeste del centro'
AND td.nombre_tipo_direccion = 'RESIDENCIA';

INSERT INTO CP_PERSONA_DIRECCION
(id_persona, id_direccion, id_tipo_direccion, es_principal)
SELECT
    p.id_persona,
    d.id_direccion,
    td.id_tipo_direccion,
    'S'
FROM CP_PERSONA p
CROSS JOIN CP_DIRECCION d
CROSS JOIN CP_TIPO_DIRECCION td
WHERE p.identificacion = '505550555'
AND d.otras_senas = 'Costado norte de la carretera principal'
AND td.nombre_tipo_direccion = 'RESIDENCIA';


-- ============================================================
-- 20. CP_PERSONA_CONTACTO
-- ============================================================

INSERT INTO CP_PERSONA_CONTACTO
(id_persona, id_contacto, es_principal)
SELECT p.id_persona, c.id_contacto, 'S'
FROM CP_PERSONA p
CROSS JOIN CP_CONTACTO c
WHERE p.identificacion = '101110111'
AND c.valor_contacto = '8888-1001';

INSERT INTO CP_PERSONA_CONTACTO
(id_persona, id_contacto, es_principal)
SELECT p.id_persona, c.id_contacto, 'S'
FROM CP_PERSONA p
CROSS JOIN CP_CONTACTO c
WHERE p.identificacion = '202220222'
AND c.valor_contacto = '8888-1002';

INSERT INTO CP_PERSONA_CONTACTO
(id_persona, id_contacto, es_principal)
SELECT p.id_persona, c.id_contacto, 'S'
FROM CP_PERSONA p
CROSS JOIN CP_CONTACTO c
WHERE p.identificacion = '303330333'
AND c.valor_contacto = '8888-1003';

INSERT INTO CP_PERSONA_CONTACTO
(id_persona, id_contacto, es_principal)
SELECT p.id_persona, c.id_contacto, 'S'
FROM CP_PERSONA p
CROSS JOIN CP_CONTACTO c
WHERE p.identificacion = '404440444'
AND c.valor_contacto = '8888-1004';

INSERT INTO CP_PERSONA_CONTACTO
(id_persona, id_contacto, es_principal)
SELECT p.id_persona, c.id_contacto, 'S'
FROM CP_PERSONA p
CROSS JOIN CP_CONTACTO c
WHERE p.identificacion = '505550555'
AND c.valor_contacto = '8888-1005';


COMMIT;



-- ============================================================
-- 21. CP_PUESTO
-- ============================================================

INSERT INTO CP_PUESTO (nombre_puesto, descripcion)
VALUES ('ADMINISTRADOR', 'Administrador del sistema');

INSERT INTO CP_PUESTO (nombre_puesto, descripcion)
VALUES ('CAJERO', 'Encargado de realizar ventas');

INSERT INTO CP_PUESTO (nombre_puesto, descripcion)
VALUES ('BODEGUERO', 'Encargado del inventario');

INSERT INTO CP_PUESTO (nombre_puesto, descripcion)
VALUES ('SUPERVISOR', 'Encargado de supervisar operaciones');

INSERT INTO CP_PUESTO (nombre_puesto, descripcion)
VALUES ('CONTADOR', 'Encargado de procesos contables');


-- ============================================================
-- 22. CP_EMPRESA_LABORAL
-- ============================================================

INSERT INTO CP_EMPRESA_LABORAL
(cedula_juridica, razon_social, nombre_comercial)
VALUES
('3-101-200001', 'Servicios del Sur Sociedad Anonima', 'Servicios del Sur');

INSERT INTO CP_EMPRESA_LABORAL
(cedula_juridica, razon_social, nombre_comercial)
VALUES
('3-101-200002', 'Comercial Brunca Sociedad Anonima', 'Comercial Brunca');

INSERT INTO CP_EMPRESA_LABORAL
(cedula_juridica, razon_social, nombre_comercial)
VALUES
('3-101-200003', 'Distribuidora Pacifico Sociedad Anonima', 'Distribuidora Pacifico');

INSERT INTO CP_EMPRESA_LABORAL
(cedula_juridica, razon_social, nombre_comercial)
VALUES
('3-101-200004', 'Servicios Canoas Sociedad Anonima', 'Servicios Canoas');

INSERT INTO CP_EMPRESA_LABORAL
(cedula_juridica, razon_social, nombre_comercial)
VALUES
('3-101-200005', 'Empresa del Valle Sociedad Anonima', 'Empresa del Valle');


-- ============================================================
-- 23. CP_PERSONA_EMPLEO
-- ============================================================

INSERT INTO CP_PERSONA_EMPLEO
(id_persona, id_puesto, id_empresa_laboral, fecha_ingreso, fecha_salida)
SELECT
    p.id_persona,
    pu.id_puesto,
    e.id_empresa_laboral,
    DATE '2024-01-15',
    NULL
FROM CP_PERSONA p
CROSS JOIN CP_PUESTO pu
CROSS JOIN CP_EMPRESA_LABORAL e
WHERE p.identificacion = '101110111'
AND pu.nombre_puesto = 'ADMINISTRADOR'
AND e.cedula_juridica = '3-101-200001';

INSERT INTO CP_PERSONA_EMPLEO
(id_persona, id_puesto, id_empresa_laboral, fecha_ingreso, fecha_salida)
SELECT
    p.id_persona,
    pu.id_puesto,
    e.id_empresa_laboral,
    DATE '2024-02-01',
    NULL
FROM CP_PERSONA p
CROSS JOIN CP_PUESTO pu
CROSS JOIN CP_EMPRESA_LABORAL e
WHERE p.identificacion = '202220222'
AND pu.nombre_puesto = 'CAJERO'
AND e.cedula_juridica = '3-101-200002';

INSERT INTO CP_PERSONA_EMPLEO
(id_persona, id_puesto, id_empresa_laboral, fecha_ingreso, fecha_salida)
SELECT
    p.id_persona,
    pu.id_puesto,
    e.id_empresa_laboral,
    DATE '2024-03-10',
    NULL
FROM CP_PERSONA p
CROSS JOIN CP_PUESTO pu
CROSS JOIN CP_EMPRESA_LABORAL e
WHERE p.identificacion = '303330333'
AND pu.nombre_puesto = 'BODEGUERO'
AND e.cedula_juridica = '3-101-200003';

INSERT INTO CP_PERSONA_EMPLEO
(id_persona, id_puesto, id_empresa_laboral, fecha_ingreso, fecha_salida)
SELECT
    p.id_persona,
    pu.id_puesto,
    e.id_empresa_laboral,
    DATE '2024-04-05',
    NULL
FROM CP_PERSONA p
CROSS JOIN CP_PUESTO pu
CROSS JOIN CP_EMPRESA_LABORAL e
WHERE p.identificacion = '404440444'
AND pu.nombre_puesto = 'SUPERVISOR'
AND e.cedula_juridica = '3-101-200004';

INSERT INTO CP_PERSONA_EMPLEO
(id_persona, id_puesto, id_empresa_laboral, fecha_ingreso, fecha_salida)
SELECT
    p.id_persona,
    pu.id_puesto,
    e.id_empresa_laboral,
    DATE '2024-05-20',
    NULL
FROM CP_PERSONA p
CROSS JOIN CP_PUESTO pu
CROSS JOIN CP_EMPRESA_LABORAL e
WHERE p.identificacion = '505550555'
AND pu.nombre_puesto = 'CONTADOR'
AND e.cedula_juridica = '3-101-200005';


-- ============================================================
-- 24. CP_ROL
-- ============================================================

INSERT INTO CP_ROL (id_estado, nombre_rol, descripcion)
SELECT id_estado, 'ADMINISTRADOR', 'Control total'
FROM CP_ESTADO
WHERE nombre = 'ACTIVO';

INSERT INTO CP_ROL (id_estado, nombre_rol, descripcion)
SELECT id_estado, 'CAJERO', 'Gestion de ventas'
FROM CP_ESTADO
WHERE nombre = 'ACTIVO';

INSERT INTO CP_ROL (id_estado, nombre_rol, descripcion)
SELECT id_estado, 'BODEGUERO', 'Gestion inventario'
FROM CP_ESTADO
WHERE nombre = 'ACTIVO';

INSERT INTO CP_ROL (id_estado, nombre_rol, descripcion)
SELECT id_estado, 'SUPERVISOR', 'Supervisa procesos'
FROM CP_ESTADO
WHERE nombre = 'ACTIVO';

INSERT INTO CP_ROL (id_estado, nombre_rol, descripcion)
SELECT id_estado, 'CONTADOR', 'Gestion contable'
FROM CP_ESTADO
WHERE nombre = 'ACTIVO';


-- ============================================================
-- 25. CP_PERMISO
-- ============================================================

INSERT INTO CP_PERMISO (id_estado, nombre_permiso)
SELECT id_estado, 'GESTIONAR_USUARIOS'
FROM CP_ESTADO
WHERE nombre = 'ACTIVO';

INSERT INTO CP_PERMISO (id_estado, nombre_permiso)
SELECT id_estado, 'REALIZAR_VENTAS'
FROM CP_ESTADO
WHERE nombre = 'ACTIVO';

INSERT INTO CP_PERMISO (id_estado, nombre_permiso)
SELECT id_estado, 'GESTIONAR_INVENTARIO'
FROM CP_ESTADO
WHERE nombre = 'ACTIVO';

INSERT INTO CP_PERMISO (id_estado, nombre_permiso)
SELECT id_estado, 'AUTORIZAR_DESCUENTOS'
FROM CP_ESTADO
WHERE nombre = 'ACTIVO';

INSERT INTO CP_PERMISO (id_estado, nombre_permiso)
SELECT id_estado, 'GESTIONAR_CREDITOS'
FROM CP_ESTADO
WHERE nombre = 'ACTIVO';


-- ============================================================
-- 26. CP_ROL_PERMISO
-- ============================================================

INSERT INTO CP_ROL_PERMISO (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso
FROM CP_ROL r
CROSS JOIN CP_PERMISO p
WHERE r.nombre_rol = 'ADMINISTRADOR'
AND p.nombre_permiso = 'GESTIONAR_USUARIOS';

INSERT INTO CP_ROL_PERMISO (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso
FROM CP_ROL r
CROSS JOIN CP_PERMISO p
WHERE r.nombre_rol = 'CAJERO'
AND p.nombre_permiso = 'REALIZAR_VENTAS';

INSERT INTO CP_ROL_PERMISO (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso
FROM CP_ROL r
CROSS JOIN CP_PERMISO p
WHERE r.nombre_rol = 'BODEGUERO'
AND p.nombre_permiso = 'GESTIONAR_INVENTARIO';

INSERT INTO CP_ROL_PERMISO (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso
FROM CP_ROL r
CROSS JOIN CP_PERMISO p
WHERE r.nombre_rol = 'SUPERVISOR'
AND p.nombre_permiso = 'AUTORIZAR_DESCUENTOS';

INSERT INTO CP_ROL_PERMISO (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso
FROM CP_ROL r
CROSS JOIN CP_PERMISO p
WHERE r.nombre_rol = 'CONTADOR'
AND p.nombre_permiso = 'GESTIONAR_CREDITOS';


-- ============================================================
-- 27. CP_USUARIO
-- Los valores son cadenas simuladas que representan hashes.
-- No se guardan contrasenas en texto plano.
-- ============================================================

INSERT INTO CP_USUARIO
(id_persona, id_estado, id_sucursal, id_rol,
 nombre_usuario, contrasena_hash)
SELECT
    p.id_persona, e.id_estado, s.id_sucursal, r.id_rol,
    'cmora', 'HASH_PRUEBA_CMORA_2026'
FROM CP_PERSONA p
CROSS JOIN CP_ESTADO e
CROSS JOIN CP_SUCURSAL s
CROSS JOIN CP_ROL r
WHERE p.identificacion = '101110111'
AND e.nombre = 'ACTIVO'
AND s.codigo_sucursal = 'SUC001'
AND r.nombre_rol = 'ADMINISTRADOR';

INSERT INTO CP_USUARIO
(id_persona, id_estado, id_sucursal, id_rol,
 nombre_usuario, contrasena_hash)
SELECT
    p.id_persona, e.id_estado, s.id_sucursal, r.id_rol,
    'mjimenez', 'HASH_PRUEBA_MJIMENEZ_2026'
FROM CP_PERSONA p
CROSS JOIN CP_ESTADO e
CROSS JOIN CP_SUCURSAL s
CROSS JOIN CP_ROL r
WHERE p.identificacion = '202220222'
AND e.nombre = 'ACTIVO'
AND s.codigo_sucursal = 'SUC002'
AND r.nombre_rol = 'CAJERO';

INSERT INTO CP_USUARIO
(id_persona, id_estado, id_sucursal, id_rol,
 nombre_usuario, contrasena_hash)
SELECT
    p.id_persona, e.id_estado, s.id_sucursal, r.id_rol,
    'lvargas', 'HASH_PRUEBA_LVARGAS_2026'
FROM CP_PERSONA p
CROSS JOIN CP_ESTADO e
CROSS JOIN CP_SUCURSAL s
CROSS JOIN CP_ROL r
WHERE p.identificacion = '303330333'
AND e.nombre = 'ACTIVO'
AND s.codigo_sucursal = 'SUC003'
AND r.nombre_rol = 'BODEGUERO';

INSERT INTO CP_USUARIO
(id_persona, id_estado, id_sucursal, id_rol,
 nombre_usuario, contrasena_hash)
SELECT
    p.id_persona, e.id_estado, s.id_sucursal, r.id_rol,
    'arodriguez', 'HASH_PRUEBA_ARODRIGUEZ_2026'
FROM CP_PERSONA p
CROSS JOIN CP_ESTADO e
CROSS JOIN CP_SUCURSAL s
CROSS JOIN CP_ROL r
WHERE p.identificacion = '404440444'
AND e.nombre = 'ACTIVO'
AND s.codigo_sucursal = 'SUC004'
AND r.nombre_rol = 'SUPERVISOR';

INSERT INTO CP_USUARIO
(id_persona, id_estado, id_sucursal, id_rol,
 nombre_usuario, contrasena_hash)
SELECT
    p.id_persona, e.id_estado, s.id_sucursal, r.id_rol,
    'jquesada', 'HASH_PRUEBA_JQUESADA_2026'
FROM CP_PERSONA p
CROSS JOIN CP_ESTADO e
CROSS JOIN CP_SUCURSAL s
CROSS JOIN CP_ROL r
WHERE p.identificacion = '505550555'
AND e.nombre = 'ACTIVO'
AND s.codigo_sucursal = 'SUC005'
AND r.nombre_rol = 'CONTADOR';


-- ============================================================
-- 28. CP_TIPO_CLIENTE
-- Solo existen los tipos necesarios para el modelo.
-- ============================================================

INSERT INTO CP_TIPO_CLIENTE
(nombre_tipo_cliente, descripcion)
VALUES ('PERSONA', 'Cliente que corresponde a una persona');

INSERT INTO CP_TIPO_CLIENTE
(nombre_tipo_cliente, descripcion)
VALUES ('EMPRESA', 'Cliente que corresponde a una empresa');


-- ============================================================
-- 29. CP_ESTADO_CLIENTE
-- ============================================================

INSERT INTO CP_ESTADO_CLIENTE
(nombre_estado_cliente, descripcion)
VALUES ('ACTIVO', 'Cliente activo');

INSERT INTO CP_ESTADO_CLIENTE
(nombre_estado_cliente, descripcion)
VALUES ('INACTIVO', 'Cliente inactivo');

INSERT INTO CP_ESTADO_CLIENTE
(nombre_estado_cliente, descripcion)
VALUES ('SUSPENDIDO', 'Cliente suspendido');

INSERT INTO CP_ESTADO_CLIENTE
(nombre_estado_cliente, descripcion)
VALUES ('BLOQUEADO', 'Cliente bloqueado');

INSERT INTO CP_ESTADO_CLIENTE
(nombre_estado_cliente, descripcion)
VALUES ('PENDIENTE', 'Cliente pendiente');



-- ---------- Clientes PERSONA ----------

INSERT INTO CP_CLIENTE
(id_tipo_cliente, id_estado_cliente, fecha_ingreso, es_cliente_defecto)
SELECT tc.id_tipo_cliente, ec.id_estado_cliente,
       DATE '2026-01-10', 'S'
FROM CP_TIPO_CLIENTE tc
CROSS JOIN CP_ESTADO_CLIENTE ec
WHERE tc.nombre_tipo_cliente = 'PERSONA'
AND ec.nombre_estado_cliente = 'ACTIVO';

INSERT INTO CP_CLIENTE
(id_tipo_cliente, id_estado_cliente, fecha_ingreso, es_cliente_defecto)
SELECT tc.id_tipo_cliente, ec.id_estado_cliente,
       DATE '2026-02-10', 'N'
FROM CP_TIPO_CLIENTE tc
CROSS JOIN CP_ESTADO_CLIENTE ec
WHERE tc.nombre_tipo_cliente = 'PERSONA'
AND ec.nombre_estado_cliente = 'ACTIVO';

INSERT INTO CP_CLIENTE
(id_tipo_cliente, id_estado_cliente, fecha_ingreso, es_cliente_defecto)
SELECT tc.id_tipo_cliente, ec.id_estado_cliente,
       DATE '2026-03-10', 'N'
FROM CP_TIPO_CLIENTE tc
CROSS JOIN CP_ESTADO_CLIENTE ec
WHERE tc.nombre_tipo_cliente = 'PERSONA'
AND ec.nombre_estado_cliente = 'ACTIVO';

INSERT INTO CP_CLIENTE
(id_tipo_cliente, id_estado_cliente, fecha_ingreso, es_cliente_defecto)
SELECT tc.id_tipo_cliente, ec.id_estado_cliente,
       DATE '2026-04-10', 'N'
FROM CP_TIPO_CLIENTE tc
CROSS JOIN CP_ESTADO_CLIENTE ec
WHERE tc.nombre_tipo_cliente = 'PERSONA'
AND ec.nombre_estado_cliente = 'ACTIVO';

INSERT INTO CP_CLIENTE
(id_tipo_cliente, id_estado_cliente, fecha_ingreso, es_cliente_defecto)
SELECT tc.id_tipo_cliente, ec.id_estado_cliente,
       DATE '2026-05-10', 'N'
FROM CP_TIPO_CLIENTE tc
CROSS JOIN CP_ESTADO_CLIENTE ec
WHERE tc.nombre_tipo_cliente = 'PERSONA'
AND ec.nombre_estado_cliente = 'ACTIVO';


-- ---------- Clientes EMPRESA ----------

INSERT INTO CP_CLIENTE
(id_tipo_cliente, id_estado_cliente, fecha_ingreso, es_cliente_defecto)
SELECT tc.id_tipo_cliente, ec.id_estado_cliente,
       DATE '2026-01-15', 'N'
FROM CP_TIPO_CLIENTE tc
CROSS JOIN CP_ESTADO_CLIENTE ec
WHERE tc.nombre_tipo_cliente = 'EMPRESA'
AND ec.nombre_estado_cliente = 'ACTIVO';

INSERT INTO CP_CLIENTE
(id_tipo_cliente, id_estado_cliente, fecha_ingreso, es_cliente_defecto)
SELECT tc.id_tipo_cliente, ec.id_estado_cliente,
       DATE '2026-02-15', 'N'
FROM CP_TIPO_CLIENTE tc
CROSS JOIN CP_ESTADO_CLIENTE ec
WHERE tc.nombre_tipo_cliente = 'EMPRESA'
AND ec.nombre_estado_cliente = 'ACTIVO';

INSERT INTO CP_CLIENTE
(id_tipo_cliente, id_estado_cliente, fecha_ingreso, es_cliente_defecto)
SELECT tc.id_tipo_cliente, ec.id_estado_cliente,
       DATE '2026-03-15', 'N'
FROM CP_TIPO_CLIENTE tc
CROSS JOIN CP_ESTADO_CLIENTE ec
WHERE tc.nombre_tipo_cliente = 'EMPRESA'
AND ec.nombre_estado_cliente = 'ACTIVO';

INSERT INTO CP_CLIENTE
(id_tipo_cliente, id_estado_cliente, fecha_ingreso, es_cliente_defecto)
SELECT tc.id_tipo_cliente, ec.id_estado_cliente,
       DATE '2026-04-15', 'N'
FROM CP_TIPO_CLIENTE tc
CROSS JOIN CP_ESTADO_CLIENTE ec
WHERE tc.nombre_tipo_cliente = 'EMPRESA'
AND ec.nombre_estado_cliente = 'ACTIVO';

INSERT INTO CP_CLIENTE
(id_tipo_cliente, id_estado_cliente, fecha_ingreso, es_cliente_defecto)
SELECT tc.id_tipo_cliente, ec.id_estado_cliente,
       DATE '2026-05-15', 'N'
FROM CP_TIPO_CLIENTE tc
CROSS JOIN CP_ESTADO_CLIENTE ec
WHERE tc.nombre_tipo_cliente = 'EMPRESA'
AND ec.nombre_estado_cliente = 'ACTIVO';


-- ============================================================
-- 31. CP_CLIENTE_PERSONA
-- Se utilizan los primeros 5 clientes de tipo PERSONA
-- ============================================================

INSERT INTO CP_CLIENTE_PERSONA (id_cliente, id_persona)
SELECT c.id_cliente, p.id_persona
FROM (
    SELECT id_cliente,
           ROW_NUMBER() OVER (ORDER BY id_cliente) AS rn
    FROM CP_CLIENTE
    WHERE id_tipo_cliente = (
        SELECT id_tipo_cliente
        FROM CP_TIPO_CLIENTE
        WHERE nombre_tipo_cliente = 'PERSONA'
    )
) c
CROSS JOIN CP_PERSONA p
WHERE c.rn = 1
AND p.identificacion = '101110111';

INSERT INTO CP_CLIENTE_PERSONA (id_cliente, id_persona)
SELECT c.id_cliente, p.id_persona
FROM (
    SELECT id_cliente,
           ROW_NUMBER() OVER (ORDER BY id_cliente) AS rn
    FROM CP_CLIENTE
    WHERE id_tipo_cliente = (
        SELECT id_tipo_cliente
        FROM CP_TIPO_CLIENTE
        WHERE nombre_tipo_cliente = 'PERSONA'
    )
) c
CROSS JOIN CP_PERSONA p
WHERE c.rn = 2
AND p.identificacion = '202220222';

INSERT INTO CP_CLIENTE_PERSONA (id_cliente, id_persona)
SELECT c.id_cliente, p.id_persona
FROM (
    SELECT id_cliente,
           ROW_NUMBER() OVER (ORDER BY id_cliente) AS rn
    FROM CP_CLIENTE
    WHERE id_tipo_cliente = (
        SELECT id_tipo_cliente
        FROM CP_TIPO_CLIENTE
        WHERE nombre_tipo_cliente = 'PERSONA'
    )
) c
CROSS JOIN CP_PERSONA p
WHERE c.rn = 3
AND p.identificacion = '303330333';

INSERT INTO CP_CLIENTE_PERSONA (id_cliente, id_persona)
SELECT c.id_cliente, p.id_persona
FROM (
    SELECT id_cliente,
           ROW_NUMBER() OVER (ORDER BY id_cliente) AS rn
    FROM CP_CLIENTE
    WHERE id_tipo_cliente = (
        SELECT id_tipo_cliente
        FROM CP_TIPO_CLIENTE
        WHERE nombre_tipo_cliente = 'PERSONA'
    )
) c
CROSS JOIN CP_PERSONA p
WHERE c.rn = 4
AND p.identificacion = '404440444';

INSERT INTO CP_CLIENTE_PERSONA (id_cliente, id_persona)
SELECT c.id_cliente, p.id_persona
FROM (
    SELECT id_cliente,
           ROW_NUMBER() OVER (ORDER BY id_cliente) AS rn
    FROM CP_CLIENTE
    WHERE id_tipo_cliente = (
        SELECT id_tipo_cliente
        FROM CP_TIPO_CLIENTE
        WHERE nombre_tipo_cliente = 'PERSONA'
    )
) c
CROSS JOIN CP_PERSONA p
WHERE c.rn = 5
AND p.identificacion = '505550555';


-- ============================================================
-- 32. CP_CLIENTE_EMPRESA
-- Los otros 5 clientes son de tipo EMPRESA.
-- ============================================================

INSERT INTO CP_CLIENTE_EMPRESA
(id_cliente, cedula_juridica, razon_social, nombre_comercial)
SELECT id_cliente,
       '3-101-300001',
       'Restaurante del Sur Sociedad Anonima',
       'Restaurante del Sur'
FROM (
    SELECT id_cliente,
           ROW_NUMBER() OVER (ORDER BY id_cliente) rn
    FROM CP_CLIENTE
    WHERE id_tipo_cliente = (
        SELECT id_tipo_cliente
        FROM CP_TIPO_CLIENTE
        WHERE nombre_tipo_cliente = 'EMPRESA'
    )
)
WHERE rn = 1;

INSERT INTO CP_CLIENTE_EMPRESA
(id_cliente, cedula_juridica, razon_social, nombre_comercial)
SELECT id_cliente,
       '3-101-300002',
       'Hotel Brunca Sociedad Anonima',
       'Hotel Brunca'
FROM (
    SELECT id_cliente,
           ROW_NUMBER() OVER (ORDER BY id_cliente) rn
    FROM CP_CLIENTE
    WHERE id_tipo_cliente = (
        SELECT id_tipo_cliente
        FROM CP_TIPO_CLIENTE
        WHERE nombre_tipo_cliente = 'EMPRESA'
    )
)
WHERE rn = 2;

INSERT INTO CP_CLIENTE_EMPRESA
(id_cliente, cedula_juridica, razon_social, nombre_comercial)
SELECT id_cliente,
       '3-101-300003',
       'Panaderia Pacifico Sociedad Anonima',
       'Panaderia Pacifico'
FROM (
    SELECT id_cliente,
           ROW_NUMBER() OVER (ORDER BY id_cliente) rn
    FROM CP_CLIENTE
    WHERE id_tipo_cliente = (
        SELECT id_tipo_cliente
        FROM CP_TIPO_CLIENTE
        WHERE nombre_tipo_cliente = 'EMPRESA'
    )
)
WHERE rn = 3;

INSERT INTO CP_CLIENTE_EMPRESA
(id_cliente, cedula_juridica, razon_social, nombre_comercial)
SELECT id_cliente,
       '3-101-300004',
       'Cafeteria Canoas Sociedad Anonima',
       'Cafeteria Canoas'
FROM (
    SELECT id_cliente,
           ROW_NUMBER() OVER (ORDER BY id_cliente) rn
    FROM CP_CLIENTE
    WHERE id_tipo_cliente = (
        SELECT id_tipo_cliente
        FROM CP_TIPO_CLIENTE
        WHERE nombre_tipo_cliente = 'EMPRESA'
    )
)
WHERE rn = 4;

INSERT INTO CP_CLIENTE_EMPRESA
(id_cliente, cedula_juridica, razon_social, nombre_comercial)
SELECT id_cliente,
       '3-101-300005',
       'Distribuidora Valle Sociedad Anonima',
       'Distribuidora Valle'
FROM (
    SELECT id_cliente,
           ROW_NUMBER() OVER (ORDER BY id_cliente) rn
    FROM CP_CLIENTE
    WHERE id_tipo_cliente = (
        SELECT id_tipo_cliente
        FROM CP_TIPO_CLIENTE
        WHERE nombre_tipo_cliente = 'EMPRESA'
    )
)
WHERE rn = 5;


-- ============================================================
-- 33. CP_CLIENTE_EMPRESA_DIRECCION
-- ============================================================

INSERT INTO CP_CLIENTE_EMPRESA_DIRECCION
(id_cliente_empresa, id_direccion, id_tipo_direccion, es_principal)
SELECT ce.id_cliente_empresa, d.id_direccion,
       td.id_tipo_direccion, 'S'
FROM CP_CLIENTE_EMPRESA ce
CROSS JOIN CP_DIRECCION d
CROSS JOIN CP_TIPO_DIRECCION td
WHERE ce.cedula_juridica = '3-101-300001'
AND d.otras_senas = '100 metros norte del parque central'
AND td.nombre_tipo_direccion = 'COMERCIAL';

INSERT INTO CP_CLIENTE_EMPRESA_DIRECCION
(id_cliente_empresa, id_direccion, id_tipo_direccion, es_principal)
SELECT ce.id_cliente_empresa, d.id_direccion,
       td.id_tipo_direccion, 'S'
FROM CP_CLIENTE_EMPRESA ce
CROSS JOIN CP_DIRECCION d
CROSS JOIN CP_TIPO_DIRECCION td
WHERE ce.cedula_juridica = '3-101-300002'
AND d.otras_senas = '200 metros este de la iglesia'
AND td.nombre_tipo_direccion = 'COMERCIAL';

INSERT INTO CP_CLIENTE_EMPRESA_DIRECCION
(id_cliente_empresa, id_direccion, id_tipo_direccion, es_principal)
SELECT ce.id_cliente_empresa, d.id_direccion,
       td.id_tipo_direccion, 'S'
FROM CP_CLIENTE_EMPRESA ce
CROSS JOIN CP_DIRECCION d
CROSS JOIN CP_TIPO_DIRECCION td
WHERE ce.cedula_juridica = '3-101-300003'
AND d.otras_senas = 'Frente al parque principal'
AND td.nombre_tipo_direccion = 'COMERCIAL';

INSERT INTO CP_CLIENTE_EMPRESA_DIRECCION
(id_cliente_empresa, id_direccion, id_tipo_direccion, es_principal)
SELECT ce.id_cliente_empresa, d.id_direccion,
       td.id_tipo_direccion, 'S'
FROM CP_CLIENTE_EMPRESA ce
CROSS JOIN CP_DIRECCION d
CROSS JOIN CP_TIPO_DIRECCION td
WHERE ce.cedula_juridica = '3-101-300004'
AND d.otras_senas = '150 metros oeste del centro'
AND td.nombre_tipo_direccion = 'COMERCIAL';

INSERT INTO CP_CLIENTE_EMPRESA_DIRECCION
(id_cliente_empresa, id_direccion, id_tipo_direccion, es_principal)
SELECT ce.id_cliente_empresa, d.id_direccion,
       td.id_tipo_direccion, 'S'
FROM CP_CLIENTE_EMPRESA ce
CROSS JOIN CP_DIRECCION d
CROSS JOIN CP_TIPO_DIRECCION td
WHERE ce.cedula_juridica = '3-101-300005'
AND d.otras_senas = 'Costado norte de la carretera principal'
AND td.nombre_tipo_direccion = 'COMERCIAL';


-- ============================================================
-- DATOS AUXILIARES DE CONTACTO
-- Necesitamos contactos adicionales para las empresas y proveedores.
-- Siguen siendo registros validos de CP_CONTACTO (tabla 18).
-- ============================================================

INSERT INTO CP_CONTACTO (id_tipo_contacto, valor_contacto)
SELECT id_tipo_contacto, 'empresa1@correo.com'
FROM CP_TIPO_DE_CONTACTO
WHERE nombre_tipo_contacto = 'CORREO';

INSERT INTO CP_CONTACTO (id_tipo_contacto, valor_contacto)
SELECT id_tipo_contacto, 'empresa2@correo.com'
FROM CP_TIPO_DE_CONTACTO
WHERE nombre_tipo_contacto = 'CORREO';

INSERT INTO CP_CONTACTO (id_tipo_contacto, valor_contacto)
SELECT id_tipo_contacto, 'empresa3@correo.com'
FROM CP_TIPO_DE_CONTACTO
WHERE nombre_tipo_contacto = 'CORREO';

INSERT INTO CP_CONTACTO (id_tipo_contacto, valor_contacto)
SELECT id_tipo_contacto, 'empresa4@correo.com'
FROM CP_TIPO_DE_CONTACTO
WHERE nombre_tipo_contacto = 'CORREO';

INSERT INTO CP_CONTACTO (id_tipo_contacto, valor_contacto)
SELECT id_tipo_contacto, 'empresa5@correo.com'
FROM CP_TIPO_DE_CONTACTO
WHERE nombre_tipo_contacto = 'CORREO';


-- ============================================================
-- 34. CP_CLIENTE_EMPRESA_CONTACTO
-- ============================================================

INSERT INTO CP_CLIENTE_EMPRESA_CONTACTO
(id_cliente_empresa, id_contacto, es_principal)
SELECT ce.id_cliente_empresa, c.id_contacto, 'S'
FROM CP_CLIENTE_EMPRESA ce
CROSS JOIN CP_CONTACTO c
WHERE ce.cedula_juridica = '3-101-300001'
AND c.valor_contacto = 'empresa1@correo.com';

INSERT INTO CP_CLIENTE_EMPRESA_CONTACTO
(id_cliente_empresa, id_contacto, es_principal)
SELECT ce.id_cliente_empresa, c.id_contacto, 'S'
FROM CP_CLIENTE_EMPRESA ce
CROSS JOIN CP_CONTACTO c
WHERE ce.cedula_juridica = '3-101-300002'
AND c.valor_contacto = 'empresa2@correo.com';

INSERT INTO CP_CLIENTE_EMPRESA_CONTACTO
(id_cliente_empresa, id_contacto, es_principal)
SELECT ce.id_cliente_empresa, c.id_contacto, 'S'
FROM CP_CLIENTE_EMPRESA ce
CROSS JOIN CP_CONTACTO c
WHERE ce.cedula_juridica = '3-101-300003'
AND c.valor_contacto = 'empresa3@correo.com';

INSERT INTO CP_CLIENTE_EMPRESA_CONTACTO
(id_cliente_empresa, id_contacto, es_principal)
SELECT ce.id_cliente_empresa, c.id_contacto, 'S'
FROM CP_CLIENTE_EMPRESA ce
CROSS JOIN CP_CONTACTO c
WHERE ce.cedula_juridica = '3-101-300004'
AND c.valor_contacto = 'empresa4@correo.com';

INSERT INTO CP_CLIENTE_EMPRESA_CONTACTO
(id_cliente_empresa, id_contacto, es_principal)
SELECT ce.id_cliente_empresa, c.id_contacto, 'S'
FROM CP_CLIENTE_EMPRESA ce
CROSS JOIN CP_CONTACTO c
WHERE ce.cedula_juridica = '3-101-300005'
AND c.valor_contacto = 'empresa5@correo.com';


-- ============================================================
-- 35. CP_PROVEEDOR
-- Los proveedores son EMPRESAS.
-- ============================================================

INSERT INTO CP_PROVEEDOR
(id_estado, cedula_juridica, razon_social, nombre_comercial)
SELECT id_estado, '3-101-400001',
       'Distribuidora Nacional Sociedad Anonima',
       'Distribuidora Nacional'
FROM CP_ESTADO
WHERE nombre = 'ACTIVO';

INSERT INTO CP_PROVEEDOR
(id_estado, cedula_juridica, razon_social, nombre_comercial)
SELECT id_estado, '3-101-400002',
       'Alimentos del Sur Sociedad Anonima',
       'Alimentos del Sur'
FROM CP_ESTADO
WHERE nombre = 'ACTIVO';

INSERT INTO CP_PROVEEDOR
(id_estado, cedula_juridica, razon_social, nombre_comercial)
SELECT id_estado, '3-101-400003',
       'Productos Brunca Sociedad Anonima',
       'Productos Brunca'
FROM CP_ESTADO
WHERE nombre = 'ACTIVO';

INSERT INTO CP_PROVEEDOR
(id_estado, cedula_juridica, razon_social, nombre_comercial)
SELECT id_estado, '3-101-400004',
       'Comercial Pacifico Sociedad Anonima',
       'Comercial Pacifico'
FROM CP_ESTADO
WHERE nombre = 'ACTIVO';

INSERT INTO CP_PROVEEDOR
(id_estado, cedula_juridica, razon_social, nombre_comercial)
SELECT id_estado, '3-101-400005',
       'Abastecedora del Valle Sociedad Anonima',
       'Abastecedora del Valle'
FROM CP_ESTADO
WHERE nombre = 'ACTIVO';


-- ============================================================
-- 36. CP_PROVEEDOR_DIRECCION
-- ============================================================

INSERT INTO CP_PROVEEDOR_DIRECCION
(id_proveedor, id_tipo_direccion, id_direccion,
 es_principal, fecha_asignacion)
SELECT p.id_proveedor, td.id_tipo_direccion,
       d.id_direccion, 'S', DATE '2026-01-01'
FROM CP_PROVEEDOR p
CROSS JOIN CP_TIPO_DIRECCION td
CROSS JOIN CP_DIRECCION d
WHERE p.cedula_juridica = '3-101-400001'
AND td.nombre_tipo_direccion = 'COMERCIAL'
AND d.otras_senas = '100 metros norte del parque central';

INSERT INTO CP_PROVEEDOR_DIRECCION
(id_proveedor, id_tipo_direccion, id_direccion,
 es_principal, fecha_asignacion)
SELECT p.id_proveedor, td.id_tipo_direccion,
       d.id_direccion, 'S', DATE '2026-01-02'
FROM CP_PROVEEDOR p
CROSS JOIN CP_TIPO_DIRECCION td
CROSS JOIN CP_DIRECCION d
WHERE p.cedula_juridica = '3-101-400002'
AND td.nombre_tipo_direccion = 'COMERCIAL'
AND d.otras_senas = '200 metros este de la iglesia';

INSERT INTO CP_PROVEEDOR_DIRECCION
(id_proveedor, id_tipo_direccion, id_direccion,
 es_principal, fecha_asignacion)
SELECT p.id_proveedor, td.id_tipo_direccion,
       d.id_direccion, 'S', DATE '2026-01-03'
FROM CP_PROVEEDOR p
CROSS JOIN CP_TIPO_DIRECCION td
CROSS JOIN CP_DIRECCION d
WHERE p.cedula_juridica = '3-101-400003'
AND td.nombre_tipo_direccion = 'COMERCIAL'
AND d.otras_senas = 'Frente al parque principal';

INSERT INTO CP_PROVEEDOR_DIRECCION
(id_proveedor, id_tipo_direccion, id_direccion,
 es_principal, fecha_asignacion)
SELECT p.id_proveedor, td.id_tipo_direccion,
       d.id_direccion, 'S', DATE '2026-01-04'
FROM CP_PROVEEDOR p
CROSS JOIN CP_TIPO_DIRECCION td
CROSS JOIN CP_DIRECCION d
WHERE p.cedula_juridica = '3-101-400004'
AND td.nombre_tipo_direccion = 'COMERCIAL'
AND d.otras_senas = '150 metros oeste del centro';

INSERT INTO CP_PROVEEDOR_DIRECCION
(id_proveedor, id_tipo_direccion, id_direccion,
 es_principal, fecha_asignacion)
SELECT p.id_proveedor, td.id_tipo_direccion,
       d.id_direccion, 'S', DATE '2026-01-05'
FROM CP_PROVEEDOR p
CROSS JOIN CP_TIPO_DIRECCION td
CROSS JOIN CP_DIRECCION d
WHERE p.cedula_juridica = '3-101-400005'
AND td.nombre_tipo_direccion = 'COMERCIAL'
AND d.otras_senas = 'Costado norte de la carretera principal';


-- ============================================================
-- CONTACTOS AUXILIARES PARA PROVEEDORES
-- ============================================================

INSERT INTO CP_CONTACTO (id_tipo_contacto, valor_contacto)
SELECT id_tipo_contacto, 'proveedor1@correo.com'
FROM CP_TIPO_DE_CONTACTO
WHERE nombre_tipo_contacto = 'CORREO';

INSERT INTO CP_CONTACTO (id_tipo_contacto, valor_contacto)
SELECT id_tipo_contacto, 'proveedor2@correo.com'
FROM CP_TIPO_DE_CONTACTO
WHERE nombre_tipo_contacto = 'CORREO';

INSERT INTO CP_CONTACTO (id_tipo_contacto, valor_contacto)
SELECT id_tipo_contacto, 'proveedor3@correo.com'
FROM CP_TIPO_DE_CONTACTO
WHERE nombre_tipo_contacto = 'CORREO';

INSERT INTO CP_CONTACTO (id_tipo_contacto, valor_contacto)
SELECT id_tipo_contacto, 'proveedor4@correo.com'
FROM CP_TIPO_DE_CONTACTO
WHERE nombre_tipo_contacto = 'CORREO';

INSERT INTO CP_CONTACTO (id_tipo_contacto, valor_contacto)
SELECT id_tipo_contacto, 'proveedor5@correo.com'
FROM CP_TIPO_DE_CONTACTO
WHERE nombre_tipo_contacto = 'CORREO';


-- ============================================================
-- 37. CP_PROVEEDOR_CONTACTO
-- ============================================================

INSERT INTO CP_PROVEEDOR_CONTACTO
(id_proveedor, id_contacto, es_principal)
SELECT p.id_proveedor, c.id_contacto, 'S'
FROM CP_PROVEEDOR p
CROSS JOIN CP_CONTACTO c
WHERE p.cedula_juridica = '3-101-400001'
AND c.valor_contacto = 'proveedor1@correo.com';

INSERT INTO CP_PROVEEDOR_CONTACTO
(id_proveedor, id_contacto, es_principal)
SELECT p.id_proveedor, c.id_contacto, 'S'
FROM CP_PROVEEDOR p
CROSS JOIN CP_CONTACTO c
WHERE p.cedula_juridica = '3-101-400002'
AND c.valor_contacto = 'proveedor2@correo.com';

INSERT INTO CP_PROVEEDOR_CONTACTO
(id_proveedor, id_contacto, es_principal)
SELECT p.id_proveedor, c.id_contacto, 'S'
FROM CP_PROVEEDOR p
CROSS JOIN CP_CONTACTO c
WHERE p.cedula_juridica = '3-101-400003'
AND c.valor_contacto = 'proveedor3@correo.com';

INSERT INTO CP_PROVEEDOR_CONTACTO
(id_proveedor, id_contacto, es_principal)
SELECT p.id_proveedor, c.id_contacto, 'S'
FROM CP_PROVEEDOR p
CROSS JOIN CP_CONTACTO c
WHERE p.cedula_juridica = '3-101-400004'
AND c.valor_contacto = 'proveedor4@correo.com';

INSERT INTO CP_PROVEEDOR_CONTACTO
(id_proveedor, id_contacto, es_principal)
SELECT p.id_proveedor, c.id_contacto, 'S'
FROM CP_PROVEEDOR p
CROSS JOIN CP_CONTACTO c
WHERE p.cedula_juridica = '3-101-400005'
AND c.valor_contacto = 'proveedor5@correo.com';



-- ============================================================
-- 39. CP_FAMILIA_PRODUCTO
-- ============================================================

INSERT INTO CP_FAMILIA_PRODUCTO
(nombre_familia, descripcion)
VALUES ('BEBIDAS', 'Bebidas y refrescos');

INSERT INTO CP_FAMILIA_PRODUCTO
(nombre_familia, descripcion)
VALUES ('CARNES', 'Carnes y productos relacionados');

INSERT INTO CP_FAMILIA_PRODUCTO
(nombre_familia, descripcion)
VALUES ('VERDURAS', 'Verduras y productos frescos');

INSERT INTO CP_FAMILIA_PRODUCTO
(nombre_familia, descripcion)
VALUES ('ABARROTES', 'Productos de consumo basico');

INSERT INTO CP_FAMILIA_PRODUCTO
(nombre_familia, descripcion)
VALUES ('LIMPIEZA', 'Productos para limpieza');


-- ============================================================
-- 40. CP_IMPUESTO
-- Incluimos EXENTO con 0%, como establece el diccionario.
-- ============================================================

INSERT INTO CP_IMPUESTO
(id_estado, nombre_impuesto, porcentaje_impuesto, descripcion)
SELECT id_estado, 'EXENTO', 0,
       'Producto exento de impuesto'
FROM CP_ESTADO
WHERE nombre = 'ACTIVO';

INSERT INTO CP_IMPUESTO
(id_estado, nombre_impuesto, porcentaje_impuesto, descripcion)
SELECT id_estado, 'IVA 1%', 1,
       'Impuesto al valor agregado del 1 por ciento'
FROM CP_ESTADO
WHERE nombre = 'ACTIVO';

INSERT INTO CP_IMPUESTO
(id_estado, nombre_impuesto, porcentaje_impuesto, descripcion)
SELECT id_estado, 'IVA 2%', 2,
       'Impuesto al valor agregado del 2 por ciento'
FROM CP_ESTADO
WHERE nombre = 'ACTIVO';

INSERT INTO CP_IMPUESTO
(id_estado, nombre_impuesto, porcentaje_impuesto, descripcion)
SELECT id_estado, 'IVA 4%', 4,
       'Impuesto al valor agregado del 4 por ciento'
FROM CP_ESTADO
WHERE nombre = 'ACTIVO';

INSERT INTO CP_IMPUESTO
(id_estado, nombre_impuesto, porcentaje_impuesto, descripcion)
SELECT id_estado, 'IVA 13%', 13,
       'Impuesto al valor agregado del 13 por ciento'
FROM CP_ESTADO
WHERE nombre = 'ACTIVO';


COMMIT;


-- ============================================================
-- 41. CP_PRODUCTO
-- ============================================================

INSERT INTO CP_PRODUCTO
(id_familia_producto, id_impuesto, id_estado,
 codigo_producto, nombre_producto, descripcion)
SELECT f.id_familia_producto, i.id_impuesto, e.id_estado,
       'PROD001', 'Arroz 1 kg', 'Arroz blanco de 1 kilogramo'
FROM CP_FAMILIA_PRODUCTO f
CROSS JOIN CP_IMPUESTO i
CROSS JOIN CP_ESTADO e
WHERE f.nombre_familia = 'ABARROTES'
AND i.nombre_impuesto = 'IVA 1%'
AND e.nombre = 'ACTIVO';

INSERT INTO CP_PRODUCTO
(id_familia_producto, id_impuesto, id_estado,
 codigo_producto, nombre_producto, descripcion)
SELECT f.id_familia_producto, i.id_impuesto, e.id_estado,
       'PROD002', 'Refresco 2 litros', 'Refresco gaseoso'
FROM CP_FAMILIA_PRODUCTO f
CROSS JOIN CP_IMPUESTO i
CROSS JOIN CP_ESTADO e
WHERE f.nombre_familia = 'BEBIDAS'
AND i.nombre_impuesto = 'IVA 13%'
AND e.nombre = 'ACTIVO';

INSERT INTO CP_PRODUCTO
(id_familia_producto, id_impuesto, id_estado,
 codigo_producto, nombre_producto, descripcion)
SELECT f.id_familia_producto, i.id_impuesto, e.id_estado,
       'PROD003', 'Carne de res', 'Carne de res por kilogramo'
FROM CP_FAMILIA_PRODUCTO f
CROSS JOIN CP_IMPUESTO i
CROSS JOIN CP_ESTADO e
WHERE f.nombre_familia = 'CARNES'
AND i.nombre_impuesto = 'IVA 1%'
AND e.nombre = 'ACTIVO';

INSERT INTO CP_PRODUCTO
(id_familia_producto, id_impuesto, id_estado,
 codigo_producto, nombre_producto, descripcion)
SELECT f.id_familia_producto, i.id_impuesto, e.id_estado,
       'PROD004', 'Tomate', 'Tomate fresco por kilogramo'
FROM CP_FAMILIA_PRODUCTO f
CROSS JOIN CP_IMPUESTO i
CROSS JOIN CP_ESTADO e
WHERE f.nombre_familia = 'VERDURAS'
AND i.nombre_impuesto = 'EXENTO'
AND e.nombre = 'ACTIVO';

INSERT INTO CP_PRODUCTO
(id_familia_producto, id_impuesto, id_estado,
 codigo_producto, nombre_producto, descripcion)
SELECT f.id_familia_producto, i.id_impuesto, e.id_estado,
       'PROD005', 'Detergente', 'Detergente para limpieza'
FROM CP_FAMILIA_PRODUCTO f
CROSS JOIN CP_IMPUESTO i
CROSS JOIN CP_ESTADO e
WHERE f.nombre_familia = 'LIMPIEZA'
AND i.nombre_impuesto = 'IVA 13%'
AND e.nombre = 'ACTIVO';


-- ============================================================
-- 42. CP_CODIGO_BARRA
-- Un producto puede tener varios codigos de barras.
-- ============================================================

INSERT INTO CP_CODIGO_BARRA (id_producto, codigo_barra)
SELECT id_producto, '7441000000011'
FROM CP_PRODUCTO
WHERE codigo_producto = 'PROD001';

INSERT INTO CP_CODIGO_BARRA (id_producto, codigo_barra)
SELECT id_producto, '7441000000028'
FROM CP_PRODUCTO
WHERE codigo_producto = 'PROD002';

INSERT INTO CP_CODIGO_BARRA (id_producto, codigo_barra)
SELECT id_producto, '7441000000035'
FROM CP_PRODUCTO
WHERE codigo_producto = 'PROD003';

INSERT INTO CP_CODIGO_BARRA (id_producto, codigo_barra)
SELECT id_producto, '7441000000042'
FROM CP_PRODUCTO
WHERE codigo_producto = 'PROD004';

INSERT INTO CP_CODIGO_BARRA (id_producto, codigo_barra)
SELECT id_producto, '7441000000059'
FROM CP_PRODUCTO
WHERE codigo_producto = 'PROD005';

-- Segundo codigo para PROD001, demostrando multiples codigos
INSERT INTO CP_CODIGO_BARRA (id_producto, codigo_barra)
SELECT id_producto, '7441000001018'
FROM CP_PRODUCTO
WHERE codigo_producto = 'PROD001';


-- ============================================================
-- 43. CP_PRODUCTO_PROVEEDOR
-- ============================================================

INSERT INTO CP_PRODUCTO_PROVEEDOR
(id_proveedor, id_producto, precio_costo_actual)
SELECT pr.id_proveedor, p.id_producto, 800
FROM CP_PROVEEDOR pr CROSS JOIN CP_PRODUCTO p
WHERE pr.cedula_juridica = '3-101-400001'
AND p.codigo_producto = 'PROD001';

INSERT INTO CP_PRODUCTO_PROVEEDOR
(id_proveedor, id_producto, precio_costo_actual)
SELECT pr.id_proveedor, p.id_producto, 1200
FROM CP_PROVEEDOR pr CROSS JOIN CP_PRODUCTO p
WHERE pr.cedula_juridica = '3-101-400002'
AND p.codigo_producto = 'PROD002';

INSERT INTO CP_PRODUCTO_PROVEEDOR
(id_proveedor, id_producto, precio_costo_actual)
SELECT pr.id_proveedor, p.id_producto, 3500
FROM CP_PROVEEDOR pr CROSS JOIN CP_PRODUCTO p
WHERE pr.cedula_juridica = '3-101-400003'
AND p.codigo_producto = 'PROD003';

INSERT INTO CP_PRODUCTO_PROVEEDOR
(id_proveedor, id_producto, precio_costo_actual)
SELECT pr.id_proveedor, p.id_producto, 700
FROM CP_PROVEEDOR pr CROSS JOIN CP_PRODUCTO p
WHERE pr.cedula_juridica = '3-101-400004'
AND p.codigo_producto = 'PROD004';

INSERT INTO CP_PRODUCTO_PROVEEDOR
(id_proveedor, id_producto, precio_costo_actual)
SELECT pr.id_proveedor, p.id_producto, 1800
FROM CP_PROVEEDOR pr CROSS JOIN CP_PRODUCTO p
WHERE pr.cedula_juridica = '3-101-400005'
AND p.codigo_producto = 'PROD005';


-- ============================================================
-- 44. CP_PRODUCTO_NEGOCIO
-- ============================================================

INSERT INTO CP_PRODUCTO_NEGOCIO
(id_producto, id_negocio, porcentaje_utilidad,
 descuento_maximo, precio_venta_actual)
SELECT p.id_producto, n.id_negocio, 25, 10, 1000
FROM CP_PRODUCTO p CROSS JOIN CP_NEGOCIO n
WHERE p.codigo_producto = 'PROD001'
AND n.cedula_juridica = '3-101-100001';

INSERT INTO CP_PRODUCTO_NEGOCIO
(id_producto, id_negocio, porcentaje_utilidad,
 descuento_maximo, precio_venta_actual)
SELECT p.id_producto, n.id_negocio, 25, 10, 1500
FROM CP_PRODUCTO p CROSS JOIN CP_NEGOCIO n
WHERE p.codigo_producto = 'PROD002'
AND n.cedula_juridica = '3-101-100002';

INSERT INTO CP_PRODUCTO_NEGOCIO
(id_producto, id_negocio, porcentaje_utilidad,
 descuento_maximo, precio_venta_actual)
SELECT p.id_producto, n.id_negocio, 20, 5, 4200
FROM CP_PRODUCTO p CROSS JOIN CP_NEGOCIO n
WHERE p.codigo_producto = 'PROD003'
AND n.cedula_juridica = '3-101-100003';

INSERT INTO CP_PRODUCTO_NEGOCIO
(id_producto, id_negocio, porcentaje_utilidad,
 descuento_maximo, precio_venta_actual)
SELECT p.id_producto, n.id_negocio, 20, 10, 850
FROM CP_PRODUCTO p CROSS JOIN CP_NEGOCIO n
WHERE p.codigo_producto = 'PROD004'
AND n.cedula_juridica = '3-101-100004';

INSERT INTO CP_PRODUCTO_NEGOCIO
(id_producto, id_negocio, porcentaje_utilidad,
 descuento_maximo, precio_venta_actual)
SELECT p.id_producto, n.id_negocio, 25, 10, 2250
FROM CP_PRODUCTO p CROSS JOIN CP_NEGOCIO n
WHERE p.codigo_producto = 'PROD005'
AND n.cedula_juridica = '3-101-100005';


-- ============================================================
-- 46. CP_TIPO_ALMACEN
-- Solo necesitamos los tipos reales del sistema.
-- ============================================================

INSERT INTO CP_TIPO_ALMACEN
(nombre_tipo_almacen, descripcion)
VALUES ('CENTRAL', 'Almacen central de inventario');

INSERT INTO CP_TIPO_ALMACEN
(nombre_tipo_almacen, descripcion)
VALUES ('SUCURSAL', 'Almacen asociado a una sucursal');


-- ============================================================
-- 47. CP_ALMACEN
-- IMPORTANTE: SOLO UNO ES CENTRAL
-- ============================================================

INSERT INTO CP_ALMACEN
(id_tipo_almacen, id_sucursal, id_estado,
 id_direccion, nombre_almacen)
SELECT ta.id_tipo_almacen, s.id_sucursal, e.id_estado,
       d.id_direccion, 'Almacen Central'
FROM CP_TIPO_ALMACEN ta
CROSS JOIN CP_SUCURSAL s
CROSS JOIN CP_ESTADO e
CROSS JOIN CP_DIRECCION d
WHERE ta.nombre_tipo_almacen = 'CENTRAL'
AND s.codigo_sucursal = 'SUC001'
AND e.nombre = 'ACTIVO'
AND d.otras_senas = '100 metros norte del parque central';

INSERT INTO CP_ALMACEN
(id_tipo_almacen, id_sucursal, id_estado,
 id_direccion, nombre_almacen)
SELECT ta.id_tipo_almacen, s.id_sucursal, e.id_estado,
       d.id_direccion, 'Almacen Alajuela'
FROM CP_TIPO_ALMACEN ta
CROSS JOIN CP_SUCURSAL s
CROSS JOIN CP_ESTADO e
CROSS JOIN CP_DIRECCION d
WHERE ta.nombre_tipo_almacen = 'SUCURSAL'
AND s.codigo_sucursal = 'SUC002'
AND e.nombre = 'ACTIVO'
AND d.otras_senas = '200 metros este de la iglesia';

INSERT INTO CP_ALMACEN
(id_tipo_almacen, id_sucursal, id_estado,
 id_direccion, nombre_almacen)
SELECT ta.id_tipo_almacen, s.id_sucursal, e.id_estado,
       d.id_direccion, 'Almacen Cartago'
FROM CP_TIPO_ALMACEN ta
CROSS JOIN CP_SUCURSAL s
CROSS JOIN CP_ESTADO e
CROSS JOIN CP_DIRECCION d
WHERE ta.nombre_tipo_almacen = 'SUCURSAL'
AND s.codigo_sucursal = 'SUC003'
AND e.nombre = 'ACTIVO'
AND d.otras_senas = 'Frente al parque principal';

INSERT INTO CP_ALMACEN
(id_tipo_almacen, id_sucursal, id_estado,
 id_direccion, nombre_almacen)
SELECT ta.id_tipo_almacen, s.id_sucursal, e.id_estado,
       d.id_direccion, 'Almacen Heredia'
FROM CP_TIPO_ALMACEN ta
CROSS JOIN CP_SUCURSAL s
CROSS JOIN CP_ESTADO e
CROSS JOIN CP_DIRECCION d
WHERE ta.nombre_tipo_almacen = 'SUCURSAL'
AND s.codigo_sucursal = 'SUC004'
AND e.nombre = 'ACTIVO'
AND d.otras_senas = '150 metros oeste del centro';

INSERT INTO CP_ALMACEN
(id_tipo_almacen, id_sucursal, id_estado,
 id_direccion, nombre_almacen)
SELECT ta.id_tipo_almacen, s.id_sucursal, e.id_estado,
       d.id_direccion, 'Almacen Canoas'
FROM CP_TIPO_ALMACEN ta
CROSS JOIN CP_SUCURSAL s
CROSS JOIN CP_ESTADO e
CROSS JOIN CP_DIRECCION d
WHERE ta.nombre_tipo_almacen = 'SUCURSAL'
AND s.codigo_sucursal = 'SUC005'
AND e.nombre = 'ACTIVO'
AND d.otras_senas = 'Costado norte de la carretera principal';


-- ============================================================
-- 49. CP_ESTADO_TRASLADO
-- Se carga antes de CP_TRASLADO
-- ============================================================

INSERT INTO CP_ESTADO_TRASLADO
(nombre_estado_traslado, descripcion)
VALUES ('SOLICITADO', 'Traslado solicitado');

INSERT INTO CP_ESTADO_TRASLADO
(nombre_estado_traslado, descripcion)
VALUES ('EN PROCESO', 'Traslado en proceso');

INSERT INTO CP_ESTADO_TRASLADO
(nombre_estado_traslado, descripcion)
VALUES ('RECIBIDO', 'Traslado recibido');

INSERT INTO CP_ESTADO_TRASLADO
(nombre_estado_traslado, descripcion)
VALUES ('CANCELADO', 'Traslado cancelado');

INSERT INTO CP_ESTADO_TRASLADO
(nombre_estado_traslado, descripcion)
VALUES ('RECHAZADO', 'Traslado rechazado');


-- ============================================================
-- 53. CP_ESTADO_FACTURA_COMPRA
-- Se carga antes de CP_FACTURA_COMPRA
-- ============================================================

INSERT INTO CP_ESTADO_FACTURA_COMPRA
(nombre_estado_factura, descripcion)
VALUES ('REGISTRADA', 'Factura registrada');

INSERT INTO CP_ESTADO_FACTURA_COMPRA
(nombre_estado_factura, descripcion)
VALUES ('PENDIENTE', 'Factura pendiente');

INSERT INTO CP_ESTADO_FACTURA_COMPRA
(nombre_estado_factura, descripcion)
VALUES ('PAGADA', 'Factura pagada');

INSERT INTO CP_ESTADO_FACTURA_COMPRA
(nombre_estado_factura, descripcion)
VALUES ('ANULADA', 'Factura anulada');

INSERT INTO CP_ESTADO_FACTURA_COMPRA
(nombre_estado_factura, descripcion)
VALUES ('PARCIAL', 'Factura con pago parcial');


-- ============================================================
-- 56. CP_ESTADO_CUENTA_PAGAR
-- Se carga antes de CP_CUENTA_PAGAR
-- ============================================================

INSERT INTO CP_ESTADO_CUENTA_PAGAR
(nombre_estado_cuenta_pagar, descripcion)
VALUES ('PENDIENTE', 'Cuenta pendiente de pago');

INSERT INTO CP_ESTADO_CUENTA_PAGAR
(nombre_estado_cuenta_pagar, descripcion)
VALUES ('PARCIAL', 'Cuenta pagada parcialmente');

INSERT INTO CP_ESTADO_CUENTA_PAGAR
(nombre_estado_cuenta_pagar, descripcion)
VALUES ('PAGADA', 'Cuenta completamente pagada');

INSERT INTO CP_ESTADO_CUENTA_PAGAR
(nombre_estado_cuenta_pagar, descripcion)
VALUES ('VENCIDA', 'Cuenta vencida');

INSERT INTO CP_ESTADO_CUENTA_PAGAR
(nombre_estado_cuenta_pagar, descripcion)
VALUES ('ANULADA', 'Cuenta anulada');


-- ============================================================
-- 60. CP_ESTADO_FACTURA_VENTA
-- Se carga antes de CP_FACTURA_VENTA
-- ============================================================

INSERT INTO CP_ESTADO_FACTURA_VENTA
(nombre_estado_factura, descripcion)
VALUES ('EMITIDA', 'Factura emitida');

INSERT INTO CP_ESTADO_FACTURA_VENTA
(nombre_estado_factura, descripcion)
VALUES ('PAGADA', 'Factura pagada');

INSERT INTO CP_ESTADO_FACTURA_VENTA
(nombre_estado_factura, descripcion)
VALUES ('CREDITO', 'Factura realizada a credito');

INSERT INTO CP_ESTADO_FACTURA_VENTA
(nombre_estado_factura, descripcion)
VALUES ('ANULADA', 'Factura anulada');

INSERT INTO CP_ESTADO_FACTURA_VENTA
(nombre_estado_factura, descripcion)
VALUES ('DEVUELTA', 'Factura con devolucion');


-- ============================================================
-- 52. CP_FACTURA_COMPRA
-- Ahora sí, porque ya existe CP_ESTADO_FACTURA_COMPRA
-- ============================================================

INSERT INTO CP_FACTURA_COMPRA
(id_proveedor, id_negocio, id_almacen_recepcion, id_usuario,
 id_estado_factura_compra, numero_factura,
 fecha_emision, fecha_recepcion,
 subtotal, descuento_total, impuesto_total, total)
SELECT pr.id_proveedor, n.id_negocio, a.id_almacen, u.id_usuario,
       ef.id_estado_factura_compra,
       'COMP-001', DATE '2026-08-01', DATE '2026-08-01',
       80000, 0, 800, 80800
FROM CP_PROVEEDOR pr
CROSS JOIN CP_NEGOCIO n
CROSS JOIN CP_ALMACEN a
CROSS JOIN CP_USUARIO u
CROSS JOIN CP_ESTADO_FACTURA_COMPRA ef
WHERE pr.cedula_juridica = '3-101-400001'
AND n.cedula_juridica = '3-101-100001'
AND a.nombre_almacen = 'Almacen Central'
AND u.nombre_usuario = 'cmora'
AND ef.nombre_estado_factura = 'REGISTRADA';

INSERT INTO CP_FACTURA_COMPRA
(id_proveedor, id_negocio, id_almacen_recepcion, id_usuario,
 id_estado_factura_compra, numero_factura,
 fecha_emision, fecha_recepcion,
 subtotal, descuento_total, impuesto_total, total)
SELECT pr.id_proveedor, n.id_negocio, a.id_almacen, u.id_usuario,
       ef.id_estado_factura_compra,
       'COMP-002', DATE '2026-08-02', DATE '2026-08-02',
       120000, 0, 15600, 135600
FROM CP_PROVEEDOR pr
CROSS JOIN CP_NEGOCIO n
CROSS JOIN CP_ALMACEN a
CROSS JOIN CP_USUARIO u
CROSS JOIN CP_ESTADO_FACTURA_COMPRA ef
WHERE pr.cedula_juridica = '3-101-400002'
AND n.cedula_juridica = '3-101-100002'
AND a.nombre_almacen = 'Almacen Alajuela'
AND u.nombre_usuario = 'mjimenez'
AND ef.nombre_estado_factura = 'REGISTRADA';

INSERT INTO CP_FACTURA_COMPRA
(id_proveedor, id_negocio, id_almacen_recepcion, id_usuario,
 id_estado_factura_compra, numero_factura,
 fecha_emision, fecha_recepcion,
 subtotal, descuento_total, impuesto_total, total)
SELECT pr.id_proveedor, n.id_negocio, a.id_almacen, u.id_usuario,
       ef.id_estado_factura_compra,
       'COMP-003', DATE '2026-08-03', DATE '2026-08-03',
       175000, 0, 1750, 176750
FROM CP_PROVEEDOR pr
CROSS JOIN CP_NEGOCIO n
CROSS JOIN CP_ALMACEN a
CROSS JOIN CP_USUARIO u
CROSS JOIN CP_ESTADO_FACTURA_COMPRA ef
WHERE pr.cedula_juridica = '3-101-400003'
AND n.cedula_juridica = '3-101-100003'
AND a.nombre_almacen = 'Almacen Cartago'
AND u.nombre_usuario = 'lvargas'
AND ef.nombre_estado_factura = 'REGISTRADA';

INSERT INTO CP_FACTURA_COMPRA
(id_proveedor, id_negocio, id_almacen_recepcion, id_usuario,
 id_estado_factura_compra, numero_factura,
 fecha_emision, fecha_recepcion,
 subtotal, descuento_total, impuesto_total, total)
SELECT pr.id_proveedor, n.id_negocio, a.id_almacen, u.id_usuario,
       ef.id_estado_factura_compra,
       'COMP-004', DATE '2026-08-04', DATE '2026-08-04',
       35000, 0, 0, 35000
FROM CP_PROVEEDOR pr
CROSS JOIN CP_NEGOCIO n
CROSS JOIN CP_ALMACEN a
CROSS JOIN CP_USUARIO u
CROSS JOIN CP_ESTADO_FACTURA_COMPRA ef
WHERE pr.cedula_juridica = '3-101-400004'
AND n.cedula_juridica = '3-101-100004'
AND a.nombre_almacen = 'Almacen Heredia'
AND u.nombre_usuario = 'arodriguez'
AND ef.nombre_estado_factura = 'REGISTRADA';

INSERT INTO CP_FACTURA_COMPRA
(id_proveedor, id_negocio, id_almacen_recepcion, id_usuario,
 id_estado_factura_compra, numero_factura,
 fecha_emision, fecha_recepcion,
 subtotal, descuento_total, impuesto_total, total)
SELECT pr.id_proveedor, n.id_negocio, a.id_almacen, u.id_usuario,
       ef.id_estado_factura_compra,
       'COMP-005', DATE '2026-08-05', DATE '2026-08-05',
       90000, 0, 11700, 101700
FROM CP_PROVEEDOR pr
CROSS JOIN CP_NEGOCIO n
CROSS JOIN CP_ALMACEN a
CROSS JOIN CP_USUARIO u
CROSS JOIN CP_ESTADO_FACTURA_COMPRA ef
WHERE pr.cedula_juridica = '3-101-400005'
AND n.cedula_juridica = '3-101-100005'
AND a.nombre_almacen = 'Almacen Canoas'
AND u.nombre_usuario = 'jquesada'
AND ef.nombre_estado_factura = 'REGISTRADA';


-- ============================================================
-- 54. CP_DETALLE_COMPRA
-- ============================================================

INSERT INTO CP_DETALLE_COMPRA
(id_factura_compra, id_producto_proveedor, cantidad,
 precio_costo_unitario, monto_descuento,
 porcentaje_impuesto, monto_impuesto,
 subtotal_linea, total_linea)
SELECT fc.id_factura_compra, pp.id_producto_proveedor,
       100, 800, 0, 1, 800, 80000, 80800
FROM CP_FACTURA_COMPRA fc
CROSS JOIN CP_PRODUCTO_PROVEEDOR pp
JOIN CP_PRODUCTO p ON p.id_producto = pp.id_producto
WHERE fc.numero_factura = 'COMP-001'
AND p.codigo_producto = 'PROD001';

INSERT INTO CP_DETALLE_COMPRA
(id_factura_compra, id_producto_proveedor, cantidad,
 precio_costo_unitario, monto_descuento,
 porcentaje_impuesto, monto_impuesto,
 subtotal_linea, total_linea)
SELECT fc.id_factura_compra, pp.id_producto_proveedor,
       100, 1200, 0, 13, 15600, 120000, 135600
FROM CP_FACTURA_COMPRA fc
CROSS JOIN CP_PRODUCTO_PROVEEDOR pp
JOIN CP_PRODUCTO p ON p.id_producto = pp.id_producto
WHERE fc.numero_factura = 'COMP-002'
AND p.codigo_producto = 'PROD002';

INSERT INTO CP_DETALLE_COMPRA
(id_factura_compra, id_producto_proveedor, cantidad,
 precio_costo_unitario, monto_descuento,
 porcentaje_impuesto, monto_impuesto,
 subtotal_linea, total_linea)
SELECT fc.id_factura_compra, pp.id_producto_proveedor,
       50, 3500, 0, 1, 1750, 175000, 176750
FROM CP_FACTURA_COMPRA fc
CROSS JOIN CP_PRODUCTO_PROVEEDOR pp
JOIN CP_PRODUCTO p ON p.id_producto = pp.id_producto
WHERE fc.numero_factura = 'COMP-003'
AND p.codigo_producto = 'PROD003';

INSERT INTO CP_DETALLE_COMPRA
(id_factura_compra, id_producto_proveedor, cantidad,
 precio_costo_unitario, monto_descuento,
 porcentaje_impuesto, monto_impuesto,
 subtotal_linea, total_linea)
SELECT fc.id_factura_compra, pp.id_producto_proveedor,
       50, 700, 0, 0, 0, 35000, 35000
FROM CP_FACTURA_COMPRA fc
CROSS JOIN CP_PRODUCTO_PROVEEDOR pp
JOIN CP_PRODUCTO p ON p.id_producto = pp.id_producto
WHERE fc.numero_factura = 'COMP-004'
AND p.codigo_producto = 'PROD004';

INSERT INTO CP_DETALLE_COMPRA
(id_factura_compra, id_producto_proveedor, cantidad,
 precio_costo_unitario, monto_descuento,
 porcentaje_impuesto, monto_impuesto,
 subtotal_linea, total_linea)
SELECT fc.id_factura_compra, pp.id_producto_proveedor,
       50, 1800, 0, 13, 11700, 90000, 101700
FROM CP_FACTURA_COMPRA fc
CROSS JOIN CP_PRODUCTO_PROVEEDOR pp
JOIN CP_PRODUCTO p ON p.id_producto = pp.id_producto
WHERE fc.numero_factura = 'COMP-005'
AND p.codigo_producto = 'PROD005';


-- ============================================================
-- 45. CP_LOTE_PRODUCTO
-- IMPORTANTE: depende de CP_DETALLE_COMPRA
-- ============================================================

INSERT INTO CP_LOTE_PRODUCTO
(id_detalle_compra, numero_lote, cantidad_recibida,
 fecha_ingreso, fecha_vencimiento)
SELECT id_detalle_compra, 'LOTE-001', 100,
       DATE '2026-08-01', DATE '2027-08-01'
FROM CP_DETALLE_COMPRA dc
JOIN CP_FACTURA_COMPRA fc
ON fc.id_factura_compra = dc.id_factura_compra
WHERE fc.numero_factura = 'COMP-001';

INSERT INTO CP_LOTE_PRODUCTO
(id_detalle_compra, numero_lote, cantidad_recibida,
 fecha_ingreso, fecha_vencimiento)
SELECT id_detalle_compra, 'LOTE-002', 100,
       DATE '2026-08-02', DATE '2027-02-02'
FROM CP_DETALLE_COMPRA dc
JOIN CP_FACTURA_COMPRA fc
ON fc.id_factura_compra = dc.id_factura_compra
WHERE fc.numero_factura = 'COMP-002';

INSERT INTO CP_LOTE_PRODUCTO
(id_detalle_compra, numero_lote, cantidad_recibida,
 fecha_ingreso, fecha_vencimiento)
SELECT id_detalle_compra, 'LOTE-003', 50,
       DATE '2026-08-03', DATE '2026-09-30'
FROM CP_DETALLE_COMPRA dc
JOIN CP_FACTURA_COMPRA fc
ON fc.id_factura_compra = dc.id_factura_compra
WHERE fc.numero_factura = 'COMP-003';

INSERT INTO CP_LOTE_PRODUCTO
(id_detalle_compra, numero_lote, cantidad_recibida,
 fecha_ingreso, fecha_vencimiento)
SELECT id_detalle_compra, 'LOTE-004', 50,
       DATE '2026-08-04', DATE '2026-09-20'
FROM CP_DETALLE_COMPRA dc
JOIN CP_FACTURA_COMPRA fc
ON fc.id_factura_compra = dc.id_factura_compra
WHERE fc.numero_factura = 'COMP-004';

INSERT INTO CP_LOTE_PRODUCTO
(id_detalle_compra, numero_lote, cantidad_recibida,
 fecha_ingreso, fecha_vencimiento)
SELECT id_detalle_compra, 'LOTE-005', 50,
       DATE '2026-08-05', DATE '2028-08-05'
FROM CP_DETALLE_COMPRA dc
JOIN CP_FACTURA_COMPRA fc
ON fc.id_factura_compra = dc.id_factura_compra
WHERE fc.numero_factura = 'COMP-005';


-- ============================================================
-- 48. CP_INVENTARIO_ALMACEN
-- ============================================================

INSERT INTO CP_INVENTARIO_ALMACEN
(id_almacen, id_lote_producto, cantidad_actual, fecha_actualizacion)
SELECT a.id_almacen, l.id_lote_producto,
       100, TIMESTAMP '2026-08-01 10:00:00'
FROM CP_ALMACEN a CROSS JOIN CP_LOTE_PRODUCTO l
WHERE a.nombre_almacen = 'Almacen Central'
AND l.numero_lote = 'LOTE-001';

INSERT INTO CP_INVENTARIO_ALMACEN
(id_almacen, id_lote_producto, cantidad_actual, fecha_actualizacion)
SELECT a.id_almacen, l.id_lote_producto,
       100, TIMESTAMP '2026-08-02 10:00:00'
FROM CP_ALMACEN a CROSS JOIN CP_LOTE_PRODUCTO l
WHERE a.nombre_almacen = 'Almacen Alajuela'
AND l.numero_lote = 'LOTE-002';

INSERT INTO CP_INVENTARIO_ALMACEN
(id_almacen, id_lote_producto, cantidad_actual, fecha_actualizacion)
SELECT a.id_almacen, l.id_lote_producto,
       50, TIMESTAMP '2026-08-03 10:00:00'
FROM CP_ALMACEN a CROSS JOIN CP_LOTE_PRODUCTO l
WHERE a.nombre_almacen = 'Almacen Cartago'
AND l.numero_lote = 'LOTE-003';

INSERT INTO CP_INVENTARIO_ALMACEN
(id_almacen, id_lote_producto, cantidad_actual, fecha_actualizacion)
SELECT a.id_almacen, l.id_lote_producto,
       50, TIMESTAMP '2026-08-04 10:00:00'
FROM CP_ALMACEN a CROSS JOIN CP_LOTE_PRODUCTO l
WHERE a.nombre_almacen = 'Almacen Heredia'
AND l.numero_lote = 'LOTE-004';

INSERT INTO CP_INVENTARIO_ALMACEN
(id_almacen, id_lote_producto, cantidad_actual, fecha_actualizacion)
SELECT a.id_almacen, l.id_lote_producto,
       50, TIMESTAMP '2026-08-05 10:00:00'
FROM CP_ALMACEN a CROSS JOIN CP_LOTE_PRODUCTO l
WHERE a.nombre_almacen = 'Almacen Canoas'
AND l.numero_lote = 'LOTE-005';


-- ============================================================
-- 50. CP_TRASLADO
-- Origen y destino siempre son diferentes.
-- ============================================================

INSERT INTO CP_TRASLADO
(id_almacen_origen, id_almacen_destino,
 id_usuario_solicita, id_estado_traslado,
 fecha_solicitud, observacion)
SELECT ao.id_almacen, ad.id_almacen, u.id_usuario,
       et.id_estado_traslado,
       TIMESTAMP '2026-08-10 08:00:00',
       'Traslado de prueba 1'
FROM CP_ALMACEN ao
CROSS JOIN CP_ALMACEN ad
CROSS JOIN CP_USUARIO u
CROSS JOIN CP_ESTADO_TRASLADO et
WHERE ao.nombre_almacen = 'Almacen Central'
AND ad.nombre_almacen = 'Almacen Alajuela'
AND u.nombre_usuario = 'cmora'
AND et.nombre_estado_traslado = 'EN PROCESO';

INSERT INTO CP_TRASLADO
(id_almacen_origen, id_almacen_destino,
 id_usuario_solicita, id_estado_traslado,
 fecha_solicitud, observacion)
SELECT ao.id_almacen, ad.id_almacen, u.id_usuario,
       et.id_estado_traslado,
       TIMESTAMP '2026-08-11 08:00:00',
       'Traslado de prueba 2'
FROM CP_ALMACEN ao
CROSS JOIN CP_ALMACEN ad
CROSS JOIN CP_USUARIO u
CROSS JOIN CP_ESTADO_TRASLADO et
WHERE ao.nombre_almacen = 'Almacen Alajuela'
AND ad.nombre_almacen = 'Almacen Central'
AND u.nombre_usuario = 'mjimenez'
AND et.nombre_estado_traslado = 'EN PROCESO';

INSERT INTO CP_TRASLADO
(id_almacen_origen, id_almacen_destino,
 id_usuario_solicita, id_estado_traslado,
 fecha_solicitud, observacion)
SELECT ao.id_almacen, ad.id_almacen, u.id_usuario,
       et.id_estado_traslado,
       TIMESTAMP '2026-08-12 08:00:00',
       'Traslado de prueba 3'
FROM CP_ALMACEN ao
CROSS JOIN CP_ALMACEN ad
CROSS JOIN CP_USUARIO u
CROSS JOIN CP_ESTADO_TRASLADO et
WHERE ao.nombre_almacen = 'Almacen Cartago'
AND ad.nombre_almacen = 'Almacen Central'
AND u.nombre_usuario = 'lvargas'
AND et.nombre_estado_traslado = 'EN PROCESO';

INSERT INTO CP_TRASLADO
(id_almacen_origen, id_almacen_destino,
 id_usuario_solicita, id_estado_traslado,
 fecha_solicitud, observacion)
SELECT ao.id_almacen, ad.id_almacen, u.id_usuario,
       et.id_estado_traslado,
       TIMESTAMP '2026-08-13 08:00:00',
       'Traslado de prueba 4'
FROM CP_ALMACEN ao
CROSS JOIN CP_ALMACEN ad
CROSS JOIN CP_USUARIO u
CROSS JOIN CP_ESTADO_TRASLADO et
WHERE ao.nombre_almacen = 'Almacen Heredia'
AND ad.nombre_almacen = 'Almacen Central'
AND u.nombre_usuario = 'arodriguez'
AND et.nombre_estado_traslado = 'EN PROCESO';

INSERT INTO CP_TRASLADO
(id_almacen_origen, id_almacen_destino,
 id_usuario_solicita, id_estado_traslado,
 fecha_solicitud, observacion)
SELECT ao.id_almacen, ad.id_almacen, u.id_usuario,
       et.id_estado_traslado,
       TIMESTAMP '2026-08-14 08:00:00',
       'Traslado de prueba 5'
FROM CP_ALMACEN ao
CROSS JOIN CP_ALMACEN ad
CROSS JOIN CP_USUARIO u
CROSS JOIN CP_ESTADO_TRASLADO et
WHERE ao.nombre_almacen = 'Almacen Canoas'
AND ad.nombre_almacen = 'Almacen Central'
AND u.nombre_usuario = 'jquesada'
AND et.nombre_estado_traslado = 'EN PROCESO';


-- ============================================================
-- 51. CP_DETALLE_TRASLADO
-- Cantidades menores que la existencia del almacen origen.
-- ============================================================

INSERT INTO CP_DETALLE_TRASLADO
(id_traslado, id_lote_producto, cantidad)
SELECT t.id_traslado, l.id_lote_producto, 10
FROM CP_TRASLADO t CROSS JOIN CP_LOTE_PRODUCTO l
WHERE t.observacion = 'Traslado de prueba 1'
AND l.numero_lote = 'LOTE-001';

INSERT INTO CP_DETALLE_TRASLADO
(id_traslado, id_lote_producto, cantidad)
SELECT t.id_traslado, l.id_lote_producto, 10
FROM CP_TRASLADO t CROSS JOIN CP_LOTE_PRODUCTO l
WHERE t.observacion = 'Traslado de prueba 2'
AND l.numero_lote = 'LOTE-002';

INSERT INTO CP_DETALLE_TRASLADO
(id_traslado, id_lote_producto, cantidad)
SELECT t.id_traslado, l.id_lote_producto, 5
FROM CP_TRASLADO t CROSS JOIN CP_LOTE_PRODUCTO l
WHERE t.observacion = 'Traslado de prueba 3'
AND l.numero_lote = 'LOTE-003';

INSERT INTO CP_DETALLE_TRASLADO
(id_traslado, id_lote_producto, cantidad)
SELECT t.id_traslado, l.id_lote_producto, 5
FROM CP_TRASLADO t CROSS JOIN CP_LOTE_PRODUCTO l
WHERE t.observacion = 'Traslado de prueba 4'
AND l.numero_lote = 'LOTE-004';

INSERT INTO CP_DETALLE_TRASLADO
(id_traslado, id_lote_producto, cantidad)
SELECT t.id_traslado, l.id_lote_producto, 5
FROM CP_TRASLADO t CROSS JOIN CP_LOTE_PRODUCTO l
WHERE t.observacion = 'Traslado de prueba 5'
AND l.numero_lote = 'LOTE-005';


-- ============================================================
-- 55. CP_CUENTA_PAGAR
-- ============================================================

INSERT INTO CP_CUENTA_PAGAR
(id_factura_compra, id_estado_cuenta_pagar,
 fecha_vencimiento, observacion)
SELECT fc.id_factura_compra, e.id_estado_cuenta_pagar,
       DATE '2026-10-01', 'Cuenta por pagar compra 1'
FROM CP_FACTURA_COMPRA fc
CROSS JOIN CP_ESTADO_CUENTA_PAGAR e
WHERE fc.numero_factura = 'COMP-001'
AND e.nombre_estado_cuenta_pagar = 'PENDIENTE';

INSERT INTO CP_CUENTA_PAGAR
(id_factura_compra, id_estado_cuenta_pagar,
 fecha_vencimiento, observacion)
SELECT fc.id_factura_compra, e.id_estado_cuenta_pagar,
       DATE '2026-10-02', 'Cuenta por pagar compra 2'
FROM CP_FACTURA_COMPRA fc
CROSS JOIN CP_ESTADO_CUENTA_PAGAR e
WHERE fc.numero_factura = 'COMP-002'
AND e.nombre_estado_cuenta_pagar = 'PENDIENTE';

INSERT INTO CP_CUENTA_PAGAR
(id_factura_compra, id_estado_cuenta_pagar,
 fecha_vencimiento, observacion)
SELECT fc.id_factura_compra, e.id_estado_cuenta_pagar,
       DATE '2026-10-03', 'Cuenta por pagar compra 3'
FROM CP_FACTURA_COMPRA fc
CROSS JOIN CP_ESTADO_CUENTA_PAGAR e
WHERE fc.numero_factura = 'COMP-003'
AND e.nombre_estado_cuenta_pagar = 'PENDIENTE';

INSERT INTO CP_CUENTA_PAGAR
(id_factura_compra, id_estado_cuenta_pagar,
 fecha_vencimiento, observacion)
SELECT fc.id_factura_compra, e.id_estado_cuenta_pagar,
       DATE '2026-10-04', 'Cuenta por pagar compra 4'
FROM CP_FACTURA_COMPRA fc
CROSS JOIN CP_ESTADO_CUENTA_PAGAR e
WHERE fc.numero_factura = 'COMP-004'
AND e.nombre_estado_cuenta_pagar = 'PENDIENTE';

INSERT INTO CP_CUENTA_PAGAR
(id_factura_compra, id_estado_cuenta_pagar,
 fecha_vencimiento, observacion)
SELECT fc.id_factura_compra, e.id_estado_cuenta_pagar,
       DATE '2026-10-05', 'Cuenta por pagar compra 5'
FROM CP_FACTURA_COMPRA fc
CROSS JOIN CP_ESTADO_CUENTA_PAGAR e
WHERE fc.numero_factura = 'COMP-005'
AND e.nombre_estado_cuenta_pagar = 'PENDIENTE';


-- ============================================================
-- 58. CP_SERVICIO
-- ============================================================

INSERT INTO CP_SERVICIO
(id_negocio, id_impuesto, id_estado,
 codigo_servicio, nombre_servicio, descripcion, precio_servicio)
SELECT n.id_negocio, i.id_impuesto, e.id_estado,
       'SERV001', 'Entrega a domicilio',
       'Servicio de entrega', 2500
FROM CP_NEGOCIO n
CROSS JOIN CP_IMPUESTO i
CROSS JOIN CP_ESTADO e
WHERE n.cedula_juridica = '3-101-100001'
AND i.nombre_impuesto = 'IVA 13%'
AND e.nombre = 'ACTIVO';

INSERT INTO CP_SERVICIO
(id_negocio, id_impuesto, id_estado,
 codigo_servicio, nombre_servicio, descripcion, precio_servicio)
SELECT n.id_negocio, i.id_impuesto, e.id_estado,
       'SERV002', 'Empaque especial',
       'Servicio de empaque', 1000
FROM CP_NEGOCIO n
CROSS JOIN CP_IMPUESTO i
CROSS JOIN CP_ESTADO e
WHERE n.cedula_juridica = '3-101-100002'
AND i.nombre_impuesto = 'IVA 13%'
AND e.nombre = 'ACTIVO';

INSERT INTO CP_SERVICIO
(id_negocio, id_impuesto, id_estado,
 codigo_servicio, nombre_servicio, descripcion, precio_servicio)
SELECT n.id_negocio, i.id_impuesto, e.id_estado,
       'SERV003', 'Transporte local',
       'Servicio de transporte', 3000
FROM CP_NEGOCIO n
CROSS JOIN CP_IMPUESTO i
CROSS JOIN CP_ESTADO e
WHERE n.cedula_juridica = '3-101-100003'
AND i.nombre_impuesto = 'IVA 13%'
AND e.nombre = 'ACTIVO';

INSERT INTO CP_SERVICIO
(id_negocio, id_impuesto, id_estado,
 codigo_servicio, nombre_servicio, descripcion, precio_servicio)
SELECT n.id_negocio, i.id_impuesto, e.id_estado,
       'SERV004', 'Preparacion de pedido',
       'Preparacion especial de mercaderia', 1500
FROM CP_NEGOCIO n
CROSS JOIN CP_IMPUESTO i
CROSS JOIN CP_ESTADO e
WHERE n.cedula_juridica = '3-101-100004'
AND i.nombre_impuesto = 'IVA 13%'
AND e.nombre = 'ACTIVO';

INSERT INTO CP_SERVICIO
(id_negocio, id_impuesto, id_estado,
 codigo_servicio, nombre_servicio, descripcion, precio_servicio)
SELECT n.id_negocio, i.id_impuesto, e.id_estado,
       'SERV005', 'Entrega programada',
       'Entrega en horario programado', 2000
FROM CP_NEGOCIO n
CROSS JOIN CP_IMPUESTO i
CROSS JOIN CP_ESTADO e
WHERE n.cedula_juridica = '3-101-100005'
AND i.nombre_impuesto = 'IVA 13%'
AND e.nombre = 'ACTIVO';


-- ============================================================
-- 59. CP_FACTURA_VENTA
-- Ya existe CP_ESTADO_FACTURA_VENTA (tabla 60)
-- ============================================================

INSERT INTO CP_FACTURA_VENTA
(id_cliente, id_sucursal, id_usuario, id_estado_factura_venta,
 numero_factura, fecha_emision,
 subtotal, descuento_total, impuesto_total, total)
SELECT c.id_cliente, s.id_sucursal, u.id_usuario,
       ev.id_estado_factura_venta,
       'VENT-001', DATE '2026-09-01',
       10000, 0, 100, 10100
FROM CP_CLIENTE c
CROSS JOIN CP_SUCURSAL s
CROSS JOIN CP_USUARIO u
CROSS JOIN CP_ESTADO_FACTURA_VENTA ev
WHERE c.es_cliente_defecto = 'S'
AND s.codigo_sucursal = 'SUC001'
AND u.nombre_usuario = 'cmora'
AND ev.nombre_estado_factura = 'EMITIDA';

INSERT INTO CP_FACTURA_VENTA
(id_cliente, id_sucursal, id_usuario, id_estado_factura_venta,
 numero_factura, fecha_emision,
 subtotal, descuento_total, impuesto_total, total)
SELECT cp.id_cliente, s.id_sucursal, u.id_usuario,
       ev.id_estado_factura_venta,
       'VENT-002', DATE '2026-09-02',
       15000, 0, 1950, 16950
FROM CP_CLIENTE_PERSONA cp
JOIN CP_PERSONA p ON p.id_persona = cp.id_persona
CROSS JOIN CP_SUCURSAL s
CROSS JOIN CP_USUARIO u
CROSS JOIN CP_ESTADO_FACTURA_VENTA ev
WHERE p.identificacion = '202220222'
AND s.codigo_sucursal = 'SUC002'
AND u.nombre_usuario = 'mjimenez'
AND ev.nombre_estado_factura = 'EMITIDA';

INSERT INTO CP_FACTURA_VENTA
(id_cliente, id_sucursal, id_usuario, id_estado_factura_venta,
 numero_factura, fecha_emision,
 subtotal, descuento_total, impuesto_total, total)
SELECT cp.id_cliente, s.id_sucursal, u.id_usuario,
       ev.id_estado_factura_venta,
       'VENT-003', DATE '2026-09-03',
       21000, 0, 210, 21210
FROM CP_CLIENTE_PERSONA cp
JOIN CP_PERSONA p ON p.id_persona = cp.id_persona
CROSS JOIN CP_SUCURSAL s
CROSS JOIN CP_USUARIO u
CROSS JOIN CP_ESTADO_FACTURA_VENTA ev
WHERE p.identificacion = '303330333'
AND s.codigo_sucursal = 'SUC003'
AND u.nombre_usuario = 'lvargas'
AND ev.nombre_estado_factura = 'EMITIDA';

INSERT INTO CP_FACTURA_VENTA
(id_cliente, id_sucursal, id_usuario, id_estado_factura_venta,
 numero_factura, fecha_emision,
 subtotal, descuento_total, impuesto_total, total)
SELECT cp.id_cliente, s.id_sucursal, u.id_usuario,
       ev.id_estado_factura_venta,
       'VENT-004', DATE '2026-09-04',
       8500, 0, 0, 8500
FROM CP_CLIENTE_PERSONA cp
JOIN CP_PERSONA p ON p.id_persona = cp.id_persona
CROSS JOIN CP_SUCURSAL s
CROSS JOIN CP_USUARIO u
CROSS JOIN CP_ESTADO_FACTURA_VENTA ev
WHERE p.identificacion = '404440444'
AND s.codigo_sucursal = 'SUC004'
AND u.nombre_usuario = 'arodriguez'
AND ev.nombre_estado_factura = 'EMITIDA';

INSERT INTO CP_FACTURA_VENTA
(id_cliente, id_sucursal, id_usuario, id_estado_factura_venta,
 numero_factura, fecha_emision,
 subtotal, descuento_total, impuesto_total, total)
SELECT cp.id_cliente, s.id_sucursal, u.id_usuario,
       ev.id_estado_factura_venta,
       'VENT-005', DATE '2026-09-05',
       11250, 0, 1462.50, 12712.50
FROM CP_CLIENTE_PERSONA cp
JOIN CP_PERSONA p ON p.id_persona = cp.id_persona
CROSS JOIN CP_SUCURSAL s
CROSS JOIN CP_USUARIO u
CROSS JOIN CP_ESTADO_FACTURA_VENTA ev
WHERE p.identificacion = '505550555'
AND s.codigo_sucursal = 'SUC005'
AND u.nombre_usuario = 'jquesada'
AND ev.nombre_estado_factura = 'EMITIDA';


COMMIT;


-- ============================================================
-- 64. CP_TIPO_PAGO
-- Se crea primero porque lo necesitan otras tablas.
-- ============================================================

INSERT INTO CP_TIPO_PAGO
(id_estado, nombre_tipo_pago, descripcion)
SELECT e.id_estado, 'EFECTIVO', 'Pago realizado en efectivo'
FROM CP_ESTADO e
WHERE e.nombre = 'ACTIVO';

INSERT INTO CP_TIPO_PAGO
(id_estado, nombre_tipo_pago, descripcion)
SELECT e.id_estado, 'TARJETA DEBITO', 'Pago con tarjeta de debito'
FROM CP_ESTADO e
WHERE e.nombre = 'ACTIVO';

INSERT INTO CP_TIPO_PAGO
(id_estado, nombre_tipo_pago, descripcion)
SELECT e.id_estado, 'TARJETA CREDITO', 'Pago con tarjeta de credito'
FROM CP_ESTADO e
WHERE e.nombre = 'ACTIVO';

INSERT INTO CP_TIPO_PAGO
(id_estado, nombre_tipo_pago, descripcion)
SELECT e.id_estado, 'SINPE', 'Pago mediante SINPE Movil'
FROM CP_ESTADO e
WHERE e.nombre = 'ACTIVO';

INSERT INTO CP_TIPO_PAGO
(id_estado, nombre_tipo_pago, descripcion)
SELECT e.id_estado, 'TRANSFERENCIA', 'Pago mediante transferencia bancaria'
FROM CP_ESTADO e
WHERE e.nombre = 'ACTIVO';


-- ============================================================
-- 66. CP_ESTADO_CREDITO
-- Se crea antes de los creditos.
-- ============================================================

INSERT INTO CP_ESTADO_CREDITO
(nombre_estado_credito, descripcion)
VALUES ('ACTIVO', 'Credito autorizado y disponible');

INSERT INTO CP_ESTADO_CREDITO
(nombre_estado_credito, descripcion)
VALUES ('SUSPENDIDO', 'Credito suspendido temporalmente');

INSERT INTO CP_ESTADO_CREDITO
(nombre_estado_credito, descripcion)
VALUES ('VENCIDO', 'Credito fuera de su periodo de vigencia');

INSERT INTO CP_ESTADO_CREDITO
(nombre_estado_credito, descripcion)
VALUES ('CANCELADO', 'Credito cancelado');

INSERT INTO CP_ESTADO_CREDITO
(nombre_estado_credito, descripcion)
VALUES ('BLOQUEADO', 'Credito bloqueado para nuevas operaciones');


-- ============================================================
-- 38. CP_CREDITO_PROVEEDOR
-- PENDIENTE DEL BLOQUE ANTERIOR
-- ============================================================

INSERT INTO CP_CREDITO_PROVEEDOR
(id_proveedor, id_negocio, id_estado_credito,
 limite_credito, fecha_autorizacion, fecha_vencimiento)
SELECT p.id_proveedor, n.id_negocio, e.id_estado_credito,
       500000, DATE '2026-08-01', DATE '2027-08-01'
FROM CP_PROVEEDOR p
CROSS JOIN CP_NEGOCIO n
CROSS JOIN CP_ESTADO_CREDITO e
WHERE p.cedula_juridica = '3-101-400001'
AND n.cedula_juridica = '3-101-100001'
AND e.nombre_estado_credito = 'ACTIVO';

INSERT INTO CP_CREDITO_PROVEEDOR
(id_proveedor, id_negocio, id_estado_credito,
 limite_credito, fecha_autorizacion, fecha_vencimiento)
SELECT p.id_proveedor, n.id_negocio, e.id_estado_credito,
       750000, DATE '2026-08-02', DATE '2027-08-02'
FROM CP_PROVEEDOR p
CROSS JOIN CP_NEGOCIO n
CROSS JOIN CP_ESTADO_CREDITO e
WHERE p.cedula_juridica = '3-101-400002'
AND n.cedula_juridica = '3-101-100002'
AND e.nombre_estado_credito = 'ACTIVO';

INSERT INTO CP_CREDITO_PROVEEDOR
(id_proveedor, id_negocio, id_estado_credito,
 limite_credito, fecha_autorizacion, fecha_vencimiento)
SELECT p.id_proveedor, n.id_negocio, e.id_estado_credito,
       600000, DATE '2026-08-03', DATE '2027-08-03'
FROM CP_PROVEEDOR p
CROSS JOIN CP_NEGOCIO n
CROSS JOIN CP_ESTADO_CREDITO e
WHERE p.cedula_juridica = '3-101-400003'
AND n.cedula_juridica = '3-101-100003'
AND e.nombre_estado_credito = 'ACTIVO';

INSERT INTO CP_CREDITO_PROVEEDOR
(id_proveedor, id_negocio, id_estado_credito,
 limite_credito, fecha_autorizacion, fecha_vencimiento)
SELECT p.id_proveedor, n.id_negocio, e.id_estado_credito,
       400000, DATE '2026-08-04', DATE '2027-08-04'
FROM CP_PROVEEDOR p
CROSS JOIN CP_NEGOCIO n
CROSS JOIN CP_ESTADO_CREDITO e
WHERE p.cedula_juridica = '3-101-400004'
AND n.cedula_juridica = '3-101-100004'
AND e.nombre_estado_credito = 'ACTIVO';

INSERT INTO CP_CREDITO_PROVEEDOR
(id_proveedor, id_negocio, id_estado_credito,
 limite_credito, fecha_autorizacion, fecha_vencimiento)
SELECT p.id_proveedor, n.id_negocio, e.id_estado_credito,
       550000, DATE '2026-08-05', DATE '2027-08-05'
FROM CP_PROVEEDOR p
CROSS JOIN CP_NEGOCIO n
CROSS JOIN CP_ESTADO_CREDITO e
WHERE p.cedula_juridica = '3-101-400005'
AND n.cedula_juridica = '3-101-100005'
AND e.nombre_estado_credito = 'ACTIVO';


-- ============================================================
-- 57. CP_ABONO_CUENTA_PAGAR
-- PENDIENTE DEL BLOQUE ANTERIOR
-- Los abonos son menores al total de cada factura.
-- ============================================================

INSERT INTO CP_ABONO_CUENTA_PAGAR
(id_cuenta_pagar, id_tipo_pago, id_usuario,
 monto_abono, fecha_abono, numero_referencia, observacion)
SELECT cp.id_cuenta_pagar, tp.id_tipo_pago, u.id_usuario,
       10000, TIMESTAMP '2026-09-01 09:00:00',
       'REF-PAG-001', 'Primer abono proveedor'
FROM CP_CUENTA_PAGAR cp
JOIN CP_FACTURA_COMPRA fc
  ON fc.id_factura_compra = cp.id_factura_compra
CROSS JOIN CP_TIPO_PAGO tp
CROSS JOIN CP_USUARIO u
WHERE fc.numero_factura = 'COMP-001'
AND tp.nombre_tipo_pago = 'TRANSFERENCIA'
AND u.nombre_usuario = 'cmora';

INSERT INTO CP_ABONO_CUENTA_PAGAR
(id_cuenta_pagar, id_tipo_pago, id_usuario,
 monto_abono, fecha_abono, numero_referencia, observacion)
SELECT cp.id_cuenta_pagar, tp.id_tipo_pago, u.id_usuario,
       20000, TIMESTAMP '2026-09-02 09:00:00',
       'REF-PAG-002', 'Primer abono proveedor'
FROM CP_CUENTA_PAGAR cp
JOIN CP_FACTURA_COMPRA fc
  ON fc.id_factura_compra = cp.id_factura_compra
CROSS JOIN CP_TIPO_PAGO tp
CROSS JOIN CP_USUARIO u
WHERE fc.numero_factura = 'COMP-002'
AND tp.nombre_tipo_pago = 'TRANSFERENCIA'
AND u.nombre_usuario = 'mjimenez';

INSERT INTO CP_ABONO_CUENTA_PAGAR
(id_cuenta_pagar, id_tipo_pago, id_usuario,
 monto_abono, fecha_abono, numero_referencia, observacion)
SELECT cp.id_cuenta_pagar, tp.id_tipo_pago, u.id_usuario,
       25000, TIMESTAMP '2026-09-03 09:00:00',
       'REF-PAG-003', 'Primer abono proveedor'
FROM CP_CUENTA_PAGAR cp
JOIN CP_FACTURA_COMPRA fc
  ON fc.id_factura_compra = cp.id_factura_compra
CROSS JOIN CP_TIPO_PAGO tp
CROSS JOIN CP_USUARIO u
WHERE fc.numero_factura = 'COMP-003'
AND tp.nombre_tipo_pago = 'TRANSFERENCIA'
AND u.nombre_usuario = 'lvargas';

INSERT INTO CP_ABONO_CUENTA_PAGAR
(id_cuenta_pagar, id_tipo_pago, id_usuario,
 monto_abono, fecha_abono, numero_referencia, observacion)
SELECT cp.id_cuenta_pagar, tp.id_tipo_pago, u.id_usuario,
       5000, TIMESTAMP '2026-09-04 09:00:00',
       'REF-PAG-004', 'Primer abono proveedor'
FROM CP_CUENTA_PAGAR cp
JOIN CP_FACTURA_COMPRA fc
  ON fc.id_factura_compra = cp.id_factura_compra
CROSS JOIN CP_TIPO_PAGO tp
CROSS JOIN CP_USUARIO u
WHERE fc.numero_factura = 'COMP-004'
AND tp.nombre_tipo_pago = 'TRANSFERENCIA'
AND u.nombre_usuario = 'arodriguez';

INSERT INTO CP_ABONO_CUENTA_PAGAR
(id_cuenta_pagar, id_tipo_pago, id_usuario,
 monto_abono, fecha_abono, numero_referencia, observacion)
SELECT cp.id_cuenta_pagar, tp.id_tipo_pago, u.id_usuario,
       15000, TIMESTAMP '2026-09-05 09:00:00',
       'REF-PAG-005', 'Primer abono proveedor'
FROM CP_CUENTA_PAGAR cp
JOIN CP_FACTURA_COMPRA fc
  ON fc.id_factura_compra = cp.id_factura_compra
CROSS JOIN CP_TIPO_PAGO tp
CROSS JOIN CP_USUARIO u
WHERE fc.numero_factura = 'COMP-005'
AND tp.nombre_tipo_pago = 'TRANSFERENCIA'
AND u.nombre_usuario = 'jquesada';


-- ============================================================
-- 61. CP_DETALLE_VENTA_PRODUCTO
-- ============================================================

INSERT INTO CP_DETALLE_VENTA_PRODUCTO
(id_factura_venta, id_producto, cantidad, precio_unitario,
 porcentaje_descuento, monto_descuento,
 porcentaje_impuesto, monto_impuesto, subtotal, total)
SELECT fv.id_factura_venta, p.id_producto,
       10, 1000, 0, 0, 1, 100, 10000, 10100
FROM CP_FACTURA_VENTA fv
CROSS JOIN CP_PRODUCTO p
WHERE fv.numero_factura = 'VENT-001'
AND p.codigo_producto = 'PROD001';

INSERT INTO CP_DETALLE_VENTA_PRODUCTO
(id_factura_venta, id_producto, cantidad, precio_unitario,
 porcentaje_descuento, monto_descuento,
 porcentaje_impuesto, monto_impuesto, subtotal, total)
SELECT fv.id_factura_venta, p.id_producto,
       10, 1500, 0, 0, 13, 1950, 15000, 16950
FROM CP_FACTURA_VENTA fv
CROSS JOIN CP_PRODUCTO p
WHERE fv.numero_factura = 'VENT-002'
AND p.codigo_producto = 'PROD002';

INSERT INTO CP_DETALLE_VENTA_PRODUCTO
(id_factura_venta, id_producto, cantidad, precio_unitario,
 porcentaje_descuento, monto_descuento,
 porcentaje_impuesto, monto_impuesto, subtotal, total)
SELECT fv.id_factura_venta, p.id_producto,
       5, 4200, 0, 0, 1, 210, 21000, 21210
FROM CP_FACTURA_VENTA fv
CROSS JOIN CP_PRODUCTO p
WHERE fv.numero_factura = 'VENT-003'
AND p.codigo_producto = 'PROD003';

INSERT INTO CP_DETALLE_VENTA_PRODUCTO
(id_factura_venta, id_producto, cantidad, precio_unitario,
 porcentaje_descuento, monto_descuento,
 porcentaje_impuesto, monto_impuesto, subtotal, total)
SELECT fv.id_factura_venta, p.id_producto,
       10, 850, 0, 0, 0, 0, 8500, 8500
FROM CP_FACTURA_VENTA fv
CROSS JOIN CP_PRODUCTO p
WHERE fv.numero_factura = 'VENT-004'
AND p.codigo_producto = 'PROD004';

INSERT INTO CP_DETALLE_VENTA_PRODUCTO
(id_factura_venta, id_producto, cantidad, precio_unitario,
 porcentaje_descuento, monto_descuento,
 porcentaje_impuesto, monto_impuesto, subtotal, total)
SELECT fv.id_factura_venta, p.id_producto,
       5, 2250, 0, 0, 13, 1462.50, 11250, 12712.50
FROM CP_FACTURA_VENTA fv
CROSS JOIN CP_PRODUCTO p
WHERE fv.numero_factura = 'VENT-005'
AND p.codigo_producto = 'PROD005';


-- ============================================================
-- 62. CP_DETALLE_VENTA_SERVICIO
-- ============================================================

INSERT INTO CP_DETALLE_VENTA_SERVICIO
(id_factura_venta, id_servicio, cantidad, precio_unitario,
 porcentaje_descuento, monto_descuento,
 porcentaje_impuesto, monto_impuesto, subtotal, total)
SELECT fv.id_factura_venta, s.id_servicio,
       1, 2500, 0, 0, 13, 325, 2500, 2825
FROM CP_FACTURA_VENTA fv CROSS JOIN CP_SERVICIO s
WHERE fv.numero_factura = 'VENT-001'
AND s.codigo_servicio = 'SERV001';

INSERT INTO CP_DETALLE_VENTA_SERVICIO
(id_factura_venta, id_servicio, cantidad, precio_unitario,
 porcentaje_descuento, monto_descuento,
 porcentaje_impuesto, monto_impuesto, subtotal, total)
SELECT fv.id_factura_venta, s.id_servicio,
       1, 1000, 0, 0, 13, 130, 1000, 1130
FROM CP_FACTURA_VENTA fv CROSS JOIN CP_SERVICIO s
WHERE fv.numero_factura = 'VENT-002'
AND s.codigo_servicio = 'SERV002';

INSERT INTO CP_DETALLE_VENTA_SERVICIO
(id_factura_venta, id_servicio, cantidad, precio_unitario,
 porcentaje_descuento, monto_descuento,
 porcentaje_impuesto, monto_impuesto, subtotal, total)
SELECT fv.id_factura_venta, s.id_servicio,
       1, 3000, 0, 0, 13, 390, 3000, 3390
FROM CP_FACTURA_VENTA fv CROSS JOIN CP_SERVICIO s
WHERE fv.numero_factura = 'VENT-003'
AND s.codigo_servicio = 'SERV003';

INSERT INTO CP_DETALLE_VENTA_SERVICIO
(id_factura_venta, id_servicio, cantidad, precio_unitario,
 porcentaje_descuento, monto_descuento,
 porcentaje_impuesto, monto_impuesto, subtotal, total)
SELECT fv.id_factura_venta, s.id_servicio,
       1, 1500, 0, 0, 13, 195, 1500, 1695
FROM CP_FACTURA_VENTA fv CROSS JOIN CP_SERVICIO s
WHERE fv.numero_factura = 'VENT-004'
AND s.codigo_servicio = 'SERV004';

INSERT INTO CP_DETALLE_VENTA_SERVICIO
(id_factura_venta, id_servicio, cantidad, precio_unitario,
 porcentaje_descuento, monto_descuento,
 porcentaje_impuesto, monto_impuesto, subtotal, total)
SELECT fv.id_factura_venta, s.id_servicio,
       1, 2000, 0, 0, 13, 260, 2000, 2260
FROM CP_FACTURA_VENTA fv CROSS JOIN CP_SERVICIO s
WHERE fv.numero_factura = 'VENT-005'
AND s.codigo_servicio = 'SERV005';


-- ============================================================
-- 63. CP_DETALLE_VENTA_LOTE
-- Relaciona cada venta de producto con el lote utilizado.
-- ============================================================

INSERT INTO CP_DETALLE_VENTA_LOTE
(id_detalle_venta_producto, id_lote_producto, cantidad)
SELECT dv.id_detalle_venta_producto, l.id_lote_producto, 10
FROM CP_DETALLE_VENTA_PRODUCTO dv
JOIN CP_FACTURA_VENTA fv
  ON fv.id_factura_venta = dv.id_factura_venta
CROSS JOIN CP_LOTE_PRODUCTO l
WHERE fv.numero_factura = 'VENT-001'
AND l.numero_lote = 'LOTE-001';

INSERT INTO CP_DETALLE_VENTA_LOTE
(id_detalle_venta_producto, id_lote_producto, cantidad)
SELECT dv.id_detalle_venta_producto, l.id_lote_producto, 10
FROM CP_DETALLE_VENTA_PRODUCTO dv
JOIN CP_FACTURA_VENTA fv
  ON fv.id_factura_venta = dv.id_factura_venta
CROSS JOIN CP_LOTE_PRODUCTO l
WHERE fv.numero_factura = 'VENT-002'
AND l.numero_lote = 'LOTE-002';

INSERT INTO CP_DETALLE_VENTA_LOTE
(id_detalle_venta_producto, id_lote_producto, cantidad)
SELECT dv.id_detalle_venta_producto, l.id_lote_producto, 5
FROM CP_DETALLE_VENTA_PRODUCTO dv
JOIN CP_FACTURA_VENTA fv
  ON fv.id_factura_venta = dv.id_factura_venta
CROSS JOIN CP_LOTE_PRODUCTO l
WHERE fv.numero_factura = 'VENT-003'
AND l.numero_lote = 'LOTE-003';

INSERT INTO CP_DETALLE_VENTA_LOTE
(id_detalle_venta_producto, id_lote_producto, cantidad)
SELECT dv.id_detalle_venta_producto, l.id_lote_producto, 10
FROM CP_DETALLE_VENTA_PRODUCTO dv
JOIN CP_FACTURA_VENTA fv
  ON fv.id_factura_venta = dv.id_factura_venta
CROSS JOIN CP_LOTE_PRODUCTO l
WHERE fv.numero_factura = 'VENT-004'
AND l.numero_lote = 'LOTE-004';

INSERT INTO CP_DETALLE_VENTA_LOTE
(id_detalle_venta_producto, id_lote_producto, cantidad)
SELECT dv.id_detalle_venta_producto, l.id_lote_producto, 5
FROM CP_DETALLE_VENTA_PRODUCTO dv
JOIN CP_FACTURA_VENTA fv
  ON fv.id_factura_venta = dv.id_factura_venta
CROSS JOIN CP_LOTE_PRODUCTO l
WHERE fv.numero_factura = 'VENT-005'
AND l.numero_lote = 'LOTE-005';


-- ============================================================
-- 65. CP_PAGO_FACTURA_VENTA
-- ============================================================

INSERT INTO CP_PAGO_FACTURA_VENTA
(id_factura_venta, id_tipo_pago, id_usuario,
 fecha_pago, monto_pago, numero_referencia, observacion)
SELECT fv.id_factura_venta, tp.id_tipo_pago, u.id_usuario,
       TIMESTAMP '2026-09-01 10:00:00',
       10100, NULL, 'Pago factura VENT-001'
FROM CP_FACTURA_VENTA fv
CROSS JOIN CP_TIPO_PAGO tp
CROSS JOIN CP_USUARIO u
WHERE fv.numero_factura = 'VENT-001'
AND tp.nombre_tipo_pago = 'EFECTIVO'
AND u.nombre_usuario = 'cmora';

INSERT INTO CP_PAGO_FACTURA_VENTA
(id_factura_venta, id_tipo_pago, id_usuario,
 fecha_pago, monto_pago, numero_referencia, observacion)
SELECT fv.id_factura_venta, tp.id_tipo_pago, u.id_usuario,
       TIMESTAMP '2026-09-02 10:00:00',
       16950, 'TAR-002', 'Pago factura VENT-002'
FROM CP_FACTURA_VENTA fv
CROSS JOIN CP_TIPO_PAGO tp
CROSS JOIN CP_USUARIO u
WHERE fv.numero_factura = 'VENT-002'
AND tp.nombre_tipo_pago = 'TARJETA DEBITO'
AND u.nombre_usuario = 'mjimenez';

INSERT INTO CP_PAGO_FACTURA_VENTA
(id_factura_venta, id_tipo_pago, id_usuario,
 fecha_pago, monto_pago, numero_referencia, observacion)
SELECT fv.id_factura_venta, tp.id_tipo_pago, u.id_usuario,
       TIMESTAMP '2026-09-03 10:00:00',
       21210, 'SINPE-003', 'Pago factura VENT-003'
FROM CP_FACTURA_VENTA fv
CROSS JOIN CP_TIPO_PAGO tp
CROSS JOIN CP_USUARIO u
WHERE fv.numero_factura = 'VENT-003'
AND tp.nombre_tipo_pago = 'SINPE'
AND u.nombre_usuario = 'lvargas';

INSERT INTO CP_PAGO_FACTURA_VENTA
(id_factura_venta, id_tipo_pago, id_usuario,
 fecha_pago, monto_pago, numero_referencia, observacion)
SELECT fv.id_factura_venta, tp.id_tipo_pago, u.id_usuario,
       TIMESTAMP '2026-09-04 10:00:00',
       8500, NULL, 'Pago factura VENT-004'
FROM CP_FACTURA_VENTA fv
CROSS JOIN CP_TIPO_PAGO tp
CROSS JOIN CP_USUARIO u
WHERE fv.numero_factura = 'VENT-004'
AND tp.nombre_tipo_pago = 'EFECTIVO'
AND u.nombre_usuario = 'arodriguez';

INSERT INTO CP_PAGO_FACTURA_VENTA
(id_factura_venta, id_tipo_pago, id_usuario,
 fecha_pago, monto_pago, numero_referencia, observacion)
SELECT fv.id_factura_venta, tp.id_tipo_pago, u.id_usuario,
       TIMESTAMP '2026-09-05 10:00:00',
       12712.50, 'TAR-005', 'Pago factura VENT-005'
FROM CP_FACTURA_VENTA fv
CROSS JOIN CP_TIPO_PAGO tp
CROSS JOIN CP_USUARIO u
WHERE fv.numero_factura = 'VENT-005'
AND tp.nombre_tipo_pago = 'TARJETA CREDITO'
AND u.nombre_usuario = 'jquesada';


-- ============================================================
-- 67. CP_CREDITO_CLIENTE
-- ============================================================

INSERT INTO CP_CREDITO_CLIENTE
(id_cliente, id_negocio, id_estado_credito,
 limite_credito, fecha_autorizacion, fecha_vencimiento)
SELECT cp.id_cliente, n.id_negocio, e.id_estado_credito,
       100000, DATE '2026-08-01', DATE '2027-08-01'
FROM CP_CLIENTE_PERSONA cp
JOIN CP_PERSONA p ON p.id_persona = cp.id_persona
CROSS JOIN CP_NEGOCIO n
CROSS JOIN CP_ESTADO_CREDITO e
WHERE p.identificacion = '202220222'
AND n.cedula_juridica = '3-101-100001'
AND e.nombre_estado_credito = 'ACTIVO';

INSERT INTO CP_CREDITO_CLIENTE
(id_cliente, id_negocio, id_estado_credito,
 limite_credito, fecha_autorizacion, fecha_vencimiento)
SELECT cp.id_cliente, n.id_negocio, e.id_estado_credito,
       150000, DATE '2026-08-02', DATE '2027-08-02'
FROM CP_CLIENTE_PERSONA cp
JOIN CP_PERSONA p ON p.id_persona = cp.id_persona
CROSS JOIN CP_NEGOCIO n
CROSS JOIN CP_ESTADO_CREDITO e
WHERE p.identificacion = '303330333'
AND n.cedula_juridica = '3-101-100002'
AND e.nombre_estado_credito = 'ACTIVO';

INSERT INTO CP_CREDITO_CLIENTE
(id_cliente, id_negocio, id_estado_credito,
 limite_credito, fecha_autorizacion, fecha_vencimiento)
SELECT cp.id_cliente, n.id_negocio, e.id_estado_credito,
       200000, DATE '2026-08-03', DATE '2027-08-03'
FROM CP_CLIENTE_PERSONA cp
JOIN CP_PERSONA p ON p.id_persona = cp.id_persona
CROSS JOIN CP_NEGOCIO n
CROSS JOIN CP_ESTADO_CREDITO e
WHERE p.identificacion = '404440444'
AND n.cedula_juridica = '3-101-100003'
AND e.nombre_estado_credito = 'ACTIVO';

INSERT INTO CP_CREDITO_CLIENTE
(id_cliente, id_negocio, id_estado_credito,
 limite_credito, fecha_autorizacion, fecha_vencimiento)
SELECT cp.id_cliente, n.id_negocio, e.id_estado_credito,
       125000, DATE '2026-08-04', DATE '2027-08-04'
FROM CP_CLIENTE_PERSONA cp
JOIN CP_PERSONA p ON p.id_persona = cp.id_persona
CROSS JOIN CP_NEGOCIO n
CROSS JOIN CP_ESTADO_CREDITO e
WHERE p.identificacion = '505550555'
AND n.cedula_juridica = '3-101-100004'
AND e.nombre_estado_credito = 'ACTIVO';

INSERT INTO CP_CREDITO_CLIENTE
(id_cliente, id_negocio, id_estado_credito,
 limite_credito, fecha_autorizacion, fecha_vencimiento)
SELECT ce.id_cliente, n.id_negocio, e.id_estado_credito,
       300000, DATE '2026-08-05', DATE '2027-08-05'
FROM CP_CLIENTE_EMPRESA ce
CROSS JOIN CP_NEGOCIO n
CROSS JOIN CP_ESTADO_CREDITO e
WHERE n.cedula_juridica = '3-101-100005'
AND e.nombre_estado_credito = 'ACTIVO'
AND ce.id_cliente = (
    SELECT MIN(id_cliente)
    FROM CP_CLIENTE_EMPRESA
);


-- ============================================================
-- 69. CP_ESTADO_CUENTA_COBRAR
-- Debe existir antes de CP_CUENTA_COBRAR.
-- ============================================================

INSERT INTO CP_ESTADO_CUENTA_COBRAR
(nombre_estado_cuenta_cobrar, descripcion)
VALUES ('PENDIENTE', 'Cuenta pendiente de cobro');

INSERT INTO CP_ESTADO_CUENTA_COBRAR
(nombre_estado_cuenta_cobrar, descripcion)
VALUES ('PARCIAL', 'Cuenta cobrada parcialmente');

INSERT INTO CP_ESTADO_CUENTA_COBRAR
(nombre_estado_cuenta_cobrar, descripcion)
VALUES ('PAGADA', 'Cuenta completamente pagada');

INSERT INTO CP_ESTADO_CUENTA_COBRAR
(nombre_estado_cuenta_cobrar, descripcion)
VALUES ('VENCIDA', 'Cuenta vencida');

INSERT INTO CP_ESTADO_CUENTA_COBRAR
(nombre_estado_cuenta_cobrar, descripcion)
VALUES ('ANULADA', 'Cuenta anulada');


-- ============================================================
-- 68. CP_CUENTA_COBRAR
-- ============================================================

INSERT INTO CP_CUENTA_COBRAR
(id_factura_venta, id_credito_cliente,
 id_estado_cuenta_cobrar, fecha_vencimiento, observacion)
SELECT fv.id_factura_venta, cc.id_credito_cliente,
       ec.id_estado_cuenta_cobrar,
       DATE '2026-10-02', 'Cuenta por cobrar 1'
FROM CP_FACTURA_VENTA fv
CROSS JOIN CP_CREDITO_CLIENTE cc
CROSS JOIN CP_ESTADO_CUENTA_COBRAR ec
WHERE fv.numero_factura = 'VENT-002'
AND ec.nombre_estado_cuenta_cobrar = 'PENDIENTE'
AND cc.id_credito_cliente =
    (SELECT MIN(id_credito_cliente) FROM CP_CREDITO_CLIENTE);

INSERT INTO CP_CUENTA_COBRAR
(id_factura_venta, id_credito_cliente,
 id_estado_cuenta_cobrar, fecha_vencimiento, observacion)
SELECT fv.id_factura_venta, cc.id_credito_cliente,
       ec.id_estado_cuenta_cobrar,
       DATE '2026-10-03', 'Cuenta por cobrar 2'
FROM CP_FACTURA_VENTA fv
CROSS JOIN CP_CREDITO_CLIENTE cc
CROSS JOIN CP_ESTADO_CUENTA_COBRAR ec
WHERE fv.numero_factura = 'VENT-003'
AND ec.nombre_estado_cuenta_cobrar = 'PENDIENTE'
AND cc.id_credito_cliente =
    (SELECT MIN(id_credito_cliente) + 1 FROM CP_CREDITO_CLIENTE);

INSERT INTO CP_CUENTA_COBRAR
(id_factura_venta, id_credito_cliente,
 id_estado_cuenta_cobrar, fecha_vencimiento, observacion)
SELECT fv.id_factura_venta, cc.id_credito_cliente,
       ec.id_estado_cuenta_cobrar,
       DATE '2026-10-04', 'Cuenta por cobrar 3'
FROM CP_FACTURA_VENTA fv
CROSS JOIN CP_CREDITO_CLIENTE cc
CROSS JOIN CP_ESTADO_CUENTA_COBRAR ec
WHERE fv.numero_factura = 'VENT-004'
AND ec.nombre_estado_cuenta_cobrar = 'PENDIENTE'
AND cc.id_credito_cliente =
    (SELECT MIN(id_credito_cliente) + 2 FROM CP_CREDITO_CLIENTE);

INSERT INTO CP_CUENTA_COBRAR
(id_factura_venta, id_credito_cliente,
 id_estado_cuenta_cobrar, fecha_vencimiento, observacion)
SELECT fv.id_factura_venta, cc.id_credito_cliente,
       ec.id_estado_cuenta_cobrar,
       DATE '2026-10-05', 'Cuenta por cobrar 4'
FROM CP_FACTURA_VENTA fv
CROSS JOIN CP_CREDITO_CLIENTE cc
CROSS JOIN CP_ESTADO_CUENTA_COBRAR ec
WHERE fv.numero_factura = 'VENT-005'
AND ec.nombre_estado_cuenta_cobrar = 'PENDIENTE'
AND cc.id_credito_cliente =
    (SELECT MIN(id_credito_cliente) + 3 FROM CP_CREDITO_CLIENTE);

INSERT INTO CP_CUENTA_COBRAR
(id_factura_venta, id_credito_cliente,
 id_estado_cuenta_cobrar, fecha_vencimiento, observacion)
SELECT fv.id_factura_venta, cc.id_credito_cliente,
       ec.id_estado_cuenta_cobrar,
       DATE '2026-10-01', 'Cuenta por cobrar 5'
FROM CP_FACTURA_VENTA fv
CROSS JOIN CP_CREDITO_CLIENTE cc
CROSS JOIN CP_ESTADO_CUENTA_COBRAR ec
WHERE fv.numero_factura = 'VENT-001'
AND ec.nombre_estado_cuenta_cobrar = 'PENDIENTE'
AND cc.id_credito_cliente =
    (SELECT MAX(id_credito_cliente) FROM CP_CREDITO_CLIENTE);


-- ============================================================
-- 70. CP_ABONO_CUENTA_COBRAR
-- Los montos no superan el total de las facturas.
-- ============================================================

INSERT INTO CP_ABONO_CUENTA_COBRAR
(id_cuenta_cobrar, id_tipo_pago, id_usuario,
 monto_abono, fecha_abono, numero_referencia, observacion)
SELECT c.id_cuenta_cobrar, tp.id_tipo_pago, u.id_usuario,
       2000, TIMESTAMP '2026-09-10 10:00:00',
       'AB-001', 'Abono de cliente'
FROM CP_CUENTA_COBRAR c
CROSS JOIN CP_TIPO_PAGO tp
CROSS JOIN CP_USUARIO u
WHERE c.observacion = 'Cuenta por cobrar 1'
AND tp.nombre_tipo_pago = 'EFECTIVO'
AND u.nombre_usuario = 'cmora';

INSERT INTO CP_ABONO_CUENTA_COBRAR
(id_cuenta_cobrar, id_tipo_pago, id_usuario,
 monto_abono, fecha_abono, numero_referencia, observacion)
SELECT c.id_cuenta_cobrar, tp.id_tipo_pago, u.id_usuario,
       3000, TIMESTAMP '2026-09-11 10:00:00',
       'AB-002', 'Abono de cliente'
FROM CP_CUENTA_COBRAR c
CROSS JOIN CP_TIPO_PAGO tp
CROSS JOIN CP_USUARIO u
WHERE c.observacion = 'Cuenta por cobrar 2'
AND tp.nombre_tipo_pago = 'SINPE'
AND u.nombre_usuario = 'mjimenez';

INSERT INTO CP_ABONO_CUENTA_COBRAR
(id_cuenta_cobrar, id_tipo_pago, id_usuario,
 monto_abono, fecha_abono, numero_referencia, observacion)
SELECT c.id_cuenta_cobrar, tp.id_tipo_pago, u.id_usuario,
       1500, TIMESTAMP '2026-09-12 10:00:00',
       'AB-003', 'Abono de cliente'
FROM CP_CUENTA_COBRAR c
CROSS JOIN CP_TIPO_PAGO tp
CROSS JOIN CP_USUARIO u
WHERE c.observacion = 'Cuenta por cobrar 3'
AND tp.nombre_tipo_pago = 'EFECTIVO'
AND u.nombre_usuario = 'lvargas';

INSERT INTO CP_ABONO_CUENTA_COBRAR
(id_cuenta_cobrar, id_tipo_pago, id_usuario,
 monto_abono, fecha_abono, numero_referencia, observacion)
SELECT c.id_cuenta_cobrar, tp.id_tipo_pago, u.id_usuario,
       2500, TIMESTAMP '2026-09-13 10:00:00',
       'AB-004', 'Abono de cliente'
FROM CP_CUENTA_COBRAR c
CROSS JOIN CP_TIPO_PAGO tp
CROSS JOIN CP_USUARIO u
WHERE c.observacion = 'Cuenta por cobrar 4'
AND tp.nombre_tipo_pago = 'TARJETA DEBITO'
AND u.nombre_usuario = 'arodriguez';

INSERT INTO CP_ABONO_CUENTA_COBRAR
(id_cuenta_cobrar, id_tipo_pago, id_usuario,
 monto_abono, fecha_abono, numero_referencia, observacion)
SELECT c.id_cuenta_cobrar, tp.id_tipo_pago, u.id_usuario,
       1000, TIMESTAMP '2026-09-14 10:00:00',
       'AB-005', 'Abono de cliente'
FROM CP_CUENTA_COBRAR c
CROSS JOIN CP_TIPO_PAGO tp
CROSS JOIN CP_USUARIO u
WHERE c.observacion = 'Cuenta por cobrar 5'
AND tp.nombre_tipo_pago = 'EFECTIVO'
AND u.nombre_usuario = 'jquesada';


-- ============================================================
-- 71. CP_ESTADO_PROMOCION
-- ============================================================

INSERT INTO CP_ESTADO_PROMOCION
(nombre_estado_promocion, descripcion)
VALUES ('ACTIVA', 'Promocion actualmente activa');

INSERT INTO CP_ESTADO_PROMOCION
(nombre_estado_promocion, descripcion)
VALUES ('PROGRAMADA', 'Promocion programada');

INSERT INTO CP_ESTADO_PROMOCION
(nombre_estado_promocion, descripcion)
VALUES ('FINALIZADA', 'Promocion finalizada');

INSERT INTO CP_ESTADO_PROMOCION
(nombre_estado_promocion, descripcion)
VALUES ('SUSPENDIDA', 'Promocion suspendida');

INSERT INTO CP_ESTADO_PROMOCION
(nombre_estado_promocion, descripcion)
VALUES ('CANCELADA', 'Promocion cancelada');


-- ============================================================
-- 72. CP_PROMOCION
-- ============================================================

INSERT INTO CP_PROMOCION
(id_estado_promocion, id_negocio, nombre_promocion,
 descripcion, fecha_inicio, fecha_final)
SELECT e.id_estado_promocion, n.id_negocio,
       'Promo Arroz y Refresco',
       'Promocion de productos seleccionados',
       DATE '2026-09-01', DATE '2026-12-31'
FROM CP_ESTADO_PROMOCION e CROSS JOIN CP_NEGOCIO n
WHERE e.nombre_estado_promocion = 'ACTIVA'
AND n.cedula_juridica = '3-101-100001';

INSERT INTO CP_PROMOCION
(id_estado_promocion, id_negocio, nombre_promocion,
 descripcion, fecha_inicio, fecha_final)
SELECT e.id_estado_promocion, n.id_negocio,
       'Promo Bebidas',
       'Promocion especial en bebidas',
       DATE '2026-09-01', DATE '2026-12-31'
FROM CP_ESTADO_PROMOCION e CROSS JOIN CP_NEGOCIO n
WHERE e.nombre_estado_promocion = 'ACTIVA'
AND n.cedula_juridica = '3-101-100002';

INSERT INTO CP_PROMOCION
(id_estado_promocion, id_negocio, nombre_promocion,
 descripcion, fecha_inicio, fecha_final)
SELECT e.id_estado_promocion, n.id_negocio,
       'Promo Carnes',
       'Promocion especial en carnes',
       DATE '2026-09-01', DATE '2026-12-31'
FROM CP_ESTADO_PROMOCION e CROSS JOIN CP_NEGOCIO n
WHERE e.nombre_estado_promocion = 'ACTIVA'
AND n.cedula_juridica = '3-101-100003';

INSERT INTO CP_PROMOCION
(id_estado_promocion, id_negocio, nombre_promocion,
 descripcion, fecha_inicio, fecha_final)
SELECT e.id_estado_promocion, n.id_negocio,
       'Promo Verduras',
       'Promocion especial en verduras',
       DATE '2026-09-01', DATE '2026-12-31'
FROM CP_ESTADO_PROMOCION e CROSS JOIN CP_NEGOCIO n
WHERE e.nombre_estado_promocion = 'ACTIVA'
AND n.cedula_juridica = '3-101-100004';

INSERT INTO CP_PROMOCION
(id_estado_promocion, id_negocio, nombre_promocion,
 descripcion, fecha_inicio, fecha_final)
SELECT e.id_estado_promocion, n.id_negocio,
       'Promo Limpieza',
       'Promocion especial en limpieza',
       DATE '2026-09-01', DATE '2026-12-31'
FROM CP_ESTADO_PROMOCION e CROSS JOIN CP_NEGOCIO n
WHERE e.nombre_estado_promocion = 'ACTIVA'
AND n.cedula_juridica = '3-101-100005';


-- ============================================================
-- 73. CP_ACCION_PROMOCION
-- ============================================================

INSERT INTO CP_ACCION_PROMOCION
(nombre_accion_promocion, descripcion)
VALUES ('ENTREGAR PRODUCTO', 'Entrega un producto como premio');

INSERT INTO CP_ACCION_PROMOCION
(nombre_accion_promocion, descripcion)
VALUES ('APLICAR DESCUENTO', 'Aplica un descuento promocional');

INSERT INTO CP_ACCION_PROMOCION
(nombre_accion_promocion, descripcion)
VALUES ('ENTREGAR CUPON', 'Entrega un cupon al cliente');

INSERT INTO CP_ACCION_PROMOCION
(nombre_accion_promocion, descripcion)
VALUES ('ACUMULAR PUNTOS', 'Entrega puntos promocionales');

INSERT INTO CP_ACCION_PROMOCION
(nombre_accion_promocion, descripcion)
VALUES ('PRECIO ESPECIAL', 'Aplica un precio promocional');


-- ============================================================
-- 74. CP_REGLA_PROMOCION
-- ============================================================

INSERT INTO CP_REGLA_PROMOCION
(id_promocion, id_accion_promocion,
 cantidad_acciones, descripcion)
SELECT p.id_promocion, a.id_accion_promocion,
       1, 'Entrega un premio'
FROM CP_PROMOCION p CROSS JOIN CP_ACCION_PROMOCION a
WHERE p.nombre_promocion = 'Promo Arroz y Refresco'
AND a.nombre_accion_promocion = 'ENTREGAR PRODUCTO';

INSERT INTO CP_REGLA_PROMOCION
(id_promocion, id_accion_promocion,
 cantidad_acciones, descripcion)
SELECT p.id_promocion, a.id_accion_promocion,
       1, 'Aplica descuento'
FROM CP_PROMOCION p CROSS JOIN CP_ACCION_PROMOCION a
WHERE p.nombre_promocion = 'Promo Bebidas'
AND a.nombre_accion_promocion = 'APLICAR DESCUENTO';

INSERT INTO CP_REGLA_PROMOCION
(id_promocion, id_accion_promocion,
 cantidad_acciones, descripcion)
SELECT p.id_promocion, a.id_accion_promocion,
       1, 'Entrega cupon'
FROM CP_PROMOCION p CROSS JOIN CP_ACCION_PROMOCION a
WHERE p.nombre_promocion = 'Promo Carnes'
AND a.nombre_accion_promocion = 'ENTREGAR CUPON';

INSERT INTO CP_REGLA_PROMOCION
(id_promocion, id_accion_promocion,
 cantidad_acciones, descripcion)
SELECT p.id_promocion, a.id_accion_promocion,
       5, 'Entrega puntos'
FROM CP_PROMOCION p CROSS JOIN CP_ACCION_PROMOCION a
WHERE p.nombre_promocion = 'Promo Verduras'
AND a.nombre_accion_promocion = 'ACUMULAR PUNTOS';

INSERT INTO CP_REGLA_PROMOCION
(id_promocion, id_accion_promocion,
 cantidad_acciones, descripcion)
SELECT p.id_promocion, a.id_accion_promocion,
       1, 'Aplica precio especial'
FROM CP_PROMOCION p CROSS JOIN CP_ACCION_PROMOCION a
WHERE p.nombre_promocion = 'Promo Limpieza'
AND a.nombre_accion_promocion = 'PRECIO ESPECIAL';


-- ============================================================
-- 75. CP_PROMOCION_PATROCINADOR
-- ============================================================

INSERT INTO CP_PROMOCION_PATROCINADOR
(id_regla_promocion, id_producto, cantidad_requerida)
SELECT r.id_regla_promocion, p.id_producto, 2
FROM CP_REGLA_PROMOCION r
JOIN CP_PROMOCION pr ON pr.id_promocion = r.id_promocion
CROSS JOIN CP_PRODUCTO p
WHERE pr.nombre_promocion = 'Promo Arroz y Refresco'
AND p.codigo_producto = 'PROD001';

INSERT INTO CP_PROMOCION_PATROCINADOR
(id_regla_promocion, id_producto, cantidad_requerida)
SELECT r.id_regla_promocion, p.id_producto, 2
FROM CP_REGLA_PROMOCION r
JOIN CP_PROMOCION pr ON pr.id_promocion = r.id_promocion
CROSS JOIN CP_PRODUCTO p
WHERE pr.nombre_promocion = 'Promo Bebidas'
AND p.codigo_producto = 'PROD002';

INSERT INTO CP_PROMOCION_PATROCINADOR
(id_regla_promocion, id_producto, cantidad_requerida)
SELECT r.id_regla_promocion, p.id_producto, 2
FROM CP_REGLA_PROMOCION r
JOIN CP_PROMOCION pr ON pr.id_promocion = r.id_promocion
CROSS JOIN CP_PRODUCTO p
WHERE pr.nombre_promocion = 'Promo Carnes'
AND p.codigo_producto = 'PROD003';

INSERT INTO CP_PROMOCION_PATROCINADOR
(id_regla_promocion, id_producto, cantidad_requerida)
SELECT r.id_regla_promocion, p.id_producto, 3
FROM CP_REGLA_PROMOCION r
JOIN CP_PROMOCION pr ON pr.id_promocion = r.id_promocion
CROSS JOIN CP_PRODUCTO p
WHERE pr.nombre_promocion = 'Promo Verduras'
AND p.codigo_producto = 'PROD004';

INSERT INTO CP_PROMOCION_PATROCINADOR
(id_regla_promocion, id_producto, cantidad_requerida)
SELECT r.id_regla_promocion, p.id_producto, 2
FROM CP_REGLA_PROMOCION r
JOIN CP_PROMOCION pr ON pr.id_promocion = r.id_promocion
CROSS JOIN CP_PRODUCTO p
WHERE pr.nombre_promocion = 'Promo Limpieza'
AND p.codigo_producto = 'PROD005';


-- ============================================================
-- 76. CP_PROMOCION_PREMIO
-- ============================================================

INSERT INTO CP_PROMOCION_PREMIO
(id_regla_promocion, id_producto_premio, cantidad_premio)
SELECT r.id_regla_promocion, p.id_producto, 1
FROM CP_REGLA_PROMOCION r
JOIN CP_PROMOCION pr ON pr.id_promocion = r.id_promocion
CROSS JOIN CP_PRODUCTO p
WHERE pr.nombre_promocion = 'Promo Arroz y Refresco'
AND p.codigo_producto = 'PROD002';

INSERT INTO CP_PROMOCION_PREMIO
(id_regla_promocion, id_producto_premio, cantidad_premio)
SELECT r.id_regla_promocion, p.id_producto, 1
FROM CP_REGLA_PROMOCION r
JOIN CP_PROMOCION pr ON pr.id_promocion = r.id_promocion
CROSS JOIN CP_PRODUCTO p
WHERE pr.nombre_promocion = 'Promo Bebidas'
AND p.codigo_producto = 'PROD001';

INSERT INTO CP_PROMOCION_PREMIO
(id_regla_promocion, id_producto_premio, cantidad_premio)
SELECT r.id_regla_promocion, p.id_producto, 1
FROM CP_REGLA_PROMOCION r
JOIN CP_PROMOCION pr ON pr.id_promocion = r.id_promocion
CROSS JOIN CP_PRODUCTO p
WHERE pr.nombre_promocion = 'Promo Carnes'
AND p.codigo_producto = 'PROD004';

INSERT INTO CP_PROMOCION_PREMIO
(id_regla_promocion, id_producto_premio, cantidad_premio)
SELECT r.id_regla_promocion, p.id_producto, 1
FROM CP_REGLA_PROMOCION r
JOIN CP_PROMOCION pr ON pr.id_promocion = r.id_promocion
CROSS JOIN CP_PRODUCTO p
WHERE pr.nombre_promocion = 'Promo Verduras'
AND p.codigo_producto = 'PROD004';

INSERT INTO CP_PROMOCION_PREMIO
(id_regla_promocion, id_producto_premio, cantidad_premio)
SELECT r.id_regla_promocion, p.id_producto, 1
FROM CP_REGLA_PROMOCION r
JOIN CP_PROMOCION pr ON pr.id_promocion = r.id_promocion
CROSS JOIN CP_PRODUCTO p
WHERE pr.nombre_promocion = 'Promo Limpieza'
AND p.codigo_producto = 'PROD005';


-- ============================================================
-- 77. CP_ESTADO_DESCUENTO
-- ============================================================

INSERT INTO CP_ESTADO_DESCUENTO
(nombre_estado_descuento, descripcion)
VALUES ('ACTIVO', 'Descuento activo');

INSERT INTO CP_ESTADO_DESCUENTO
(nombre_estado_descuento, descripcion)
VALUES ('PROGRAMADO', 'Descuento programado');

INSERT INTO CP_ESTADO_DESCUENTO
(nombre_estado_descuento, descripcion)
VALUES ('FINALIZADO', 'Descuento finalizado');

INSERT INTO CP_ESTADO_DESCUENTO
(nombre_estado_descuento, descripcion)
VALUES ('SUSPENDIDO', 'Descuento suspendido');

INSERT INTO CP_ESTADO_DESCUENTO
(nombre_estado_descuento, descripcion)
VALUES ('CANCELADO', 'Descuento cancelado');


-- ============================================================
-- 78. CP_DESCUENTO
-- ============================================================

INSERT INTO CP_DESCUENTO
(id_negocio, id_estado_descuento, nombre_descuento,
 porcentaje_descuento, fecha_inicio, fecha_final, descripcion)
SELECT n.id_negocio, e.id_estado_descuento,
       'Descuento Abarrotes', 5,
       DATE '2026-09-01', DATE '2026-12-31',
       'Descuento en productos de abarrotes'
FROM CP_NEGOCIO n CROSS JOIN CP_ESTADO_DESCUENTO e
WHERE n.cedula_juridica = '3-101-100001'
AND e.nombre_estado_descuento = 'ACTIVO';

INSERT INTO CP_DESCUENTO
(id_negocio, id_estado_descuento, nombre_descuento,
 porcentaje_descuento, fecha_inicio, fecha_final, descripcion)
SELECT n.id_negocio, e.id_estado_descuento,
       'Descuento Bebidas', 10,
       DATE '2026-09-01', DATE '2026-12-31',
       'Descuento en bebidas'
FROM CP_NEGOCIO n CROSS JOIN CP_ESTADO_DESCUENTO e
WHERE n.cedula_juridica = '3-101-100002'
AND e.nombre_estado_descuento = 'ACTIVO';

INSERT INTO CP_DESCUENTO
(id_negocio, id_estado_descuento, nombre_descuento,
 porcentaje_descuento, fecha_inicio, fecha_final, descripcion)
SELECT n.id_negocio, e.id_estado_descuento,
       'Descuento Carnes', 8,
       DATE '2026-09-01', DATE '2026-12-31',
       'Descuento en carnes'
FROM CP_NEGOCIO n CROSS JOIN CP_ESTADO_DESCUENTO e
WHERE n.cedula_juridica = '3-101-100003'
AND e.nombre_estado_descuento = 'ACTIVO';

INSERT INTO CP_DESCUENTO
(id_negocio, id_estado_descuento, nombre_descuento,
 porcentaje_descuento, fecha_inicio, fecha_final, descripcion)
SELECT n.id_negocio, e.id_estado_descuento,
       'Descuento Verduras', 15,
       DATE '2026-09-01', DATE '2026-12-31',
       'Descuento en verduras'
FROM CP_NEGOCIO n CROSS JOIN CP_ESTADO_DESCUENTO e
WHERE n.cedula_juridica = '3-101-100004'
AND e.nombre_estado_descuento = 'ACTIVO';

INSERT INTO CP_DESCUENTO
(id_negocio, id_estado_descuento, nombre_descuento,
 porcentaje_descuento, fecha_inicio, fecha_final, descripcion)
SELECT n.id_negocio, e.id_estado_descuento,
       'Descuento Limpieza', 7,
       DATE '2026-09-01', DATE '2026-12-31',
       'Descuento en productos de limpieza'
FROM CP_NEGOCIO n CROSS JOIN CP_ESTADO_DESCUENTO e
WHERE n.cedula_juridica = '3-101-100005'
AND e.nombre_estado_descuento = 'ACTIVO';


-- ============================================================
-- 79. CP_DESCUENTO_FAMILIA
-- ============================================================

INSERT INTO CP_DESCUENTO_FAMILIA
(id_descuento, id_familia_producto)
SELECT d.id_descuento, f.id_familia_producto
FROM CP_DESCUENTO d CROSS JOIN CP_FAMILIA_PRODUCTO f
WHERE d.nombre_descuento = 'Descuento Abarrotes'
AND f.nombre_familia = 'ABARROTES';

INSERT INTO CP_DESCUENTO_FAMILIA
(id_descuento, id_familia_producto)
SELECT d.id_descuento, f.id_familia_producto
FROM CP_DESCUENTO d CROSS JOIN CP_FAMILIA_PRODUCTO f
WHERE d.nombre_descuento = 'Descuento Bebidas'
AND f.nombre_familia = 'BEBIDAS';

INSERT INTO CP_DESCUENTO_FAMILIA
(id_descuento, id_familia_producto)
SELECT d.id_descuento, f.id_familia_producto
FROM CP_DESCUENTO d CROSS JOIN CP_FAMILIA_PRODUCTO f
WHERE d.nombre_descuento = 'Descuento Carnes'
AND f.nombre_familia = 'CARNES';

INSERT INTO CP_DESCUENTO_FAMILIA
(id_descuento, id_familia_producto)
SELECT d.id_descuento, f.id_familia_producto
FROM CP_DESCUENTO d CROSS JOIN CP_FAMILIA_PRODUCTO f
WHERE d.nombre_descuento = 'Descuento Verduras'
AND f.nombre_familia = 'VERDURAS';

INSERT INTO CP_DESCUENTO_FAMILIA
(id_descuento, id_familia_producto)
SELECT d.id_descuento, f.id_familia_producto
FROM CP_DESCUENTO d CROSS JOIN CP_FAMILIA_PRODUCTO f
WHERE d.nombre_descuento = 'Descuento Limpieza'
AND f.nombre_familia = 'LIMPIEZA';


-- ============================================================
-- 80. CP_DESCUENTO_PROVEEDOR
-- ============================================================

INSERT INTO CP_DESCUENTO_PROVEEDOR
(id_descuento, id_proveedor)
SELECT d.id_descuento, p.id_proveedor
FROM CP_DESCUENTO d CROSS JOIN CP_PROVEEDOR p
WHERE d.nombre_descuento = 'Descuento Abarrotes'
AND p.cedula_juridica = '3-101-400001';

INSERT INTO CP_DESCUENTO_PROVEEDOR
(id_descuento, id_proveedor)
SELECT d.id_descuento, p.id_proveedor
FROM CP_DESCUENTO d CROSS JOIN CP_PROVEEDOR p
WHERE d.nombre_descuento = 'Descuento Bebidas'
AND p.cedula_juridica = '3-101-400002';

INSERT INTO CP_DESCUENTO_PROVEEDOR
(id_descuento, id_proveedor)
SELECT d.id_descuento, p.id_proveedor
FROM CP_DESCUENTO d CROSS JOIN CP_PROVEEDOR p
WHERE d.nombre_descuento = 'Descuento Carnes'
AND p.cedula_juridica = '3-101-400003';

INSERT INTO CP_DESCUENTO_PROVEEDOR
(id_descuento, id_proveedor)
SELECT d.id_descuento, p.id_proveedor
FROM CP_DESCUENTO d CROSS JOIN CP_PROVEEDOR p
WHERE d.nombre_descuento = 'Descuento Verduras'
AND p.cedula_juridica = '3-101-400004';

INSERT INTO CP_DESCUENTO_PROVEEDOR
(id_descuento, id_proveedor)
SELECT d.id_descuento, p.id_proveedor
FROM CP_DESCUENTO d CROSS JOIN CP_PROVEEDOR p
WHERE d.nombre_descuento = 'Descuento Limpieza'
AND p.cedula_juridica = '3-101-400005';


COMMIT;

-- ============================================================
-- 81. CP_DESCUENTO_FECHA_INGRESO
-- ============================================================

INSERT INTO CP_DESCUENTO_FECHA_INGRESO
(id_descuento, fecha_ingreso_desde, fecha_ingreso_hasta)
SELECT id_descuento, DATE '2026-08-01', DATE '2026-08-31'
FROM CP_DESCUENTO
WHERE nombre_descuento = 'Descuento Abarrotes';

INSERT INTO CP_DESCUENTO_FECHA_INGRESO
(id_descuento, fecha_ingreso_desde, fecha_ingreso_hasta)
SELECT id_descuento, DATE '2026-08-01', DATE '2026-08-31'
FROM CP_DESCUENTO
WHERE nombre_descuento = 'Descuento Bebidas';

INSERT INTO CP_DESCUENTO_FECHA_INGRESO
(id_descuento, fecha_ingreso_desde, fecha_ingreso_hasta)
SELECT id_descuento, DATE '2026-08-01', DATE '2026-08-31'
FROM CP_DESCUENTO
WHERE nombre_descuento = 'Descuento Carnes';

INSERT INTO CP_DESCUENTO_FECHA_INGRESO
(id_descuento, fecha_ingreso_desde, fecha_ingreso_hasta)
SELECT id_descuento, DATE '2026-08-01', DATE '2026-08-31'
FROM CP_DESCUENTO
WHERE nombre_descuento = 'Descuento Verduras';

INSERT INTO CP_DESCUENTO_FECHA_INGRESO
(id_descuento, fecha_ingreso_desde, fecha_ingreso_hasta)
SELECT id_descuento, DATE '2026-08-01', DATE '2026-08-31'
FROM CP_DESCUENTO
WHERE nombre_descuento = 'Descuento Limpieza';


-- ============================================================
-- 82. CP_DESCUENTO_VENCIMIENTO
-- ============================================================

INSERT INTO CP_DESCUENTO_VENCIMIENTO
(id_descuento, dias_antes_vencimiento)
SELECT id_descuento, 30
FROM CP_DESCUENTO
WHERE nombre_descuento = 'Descuento Abarrotes';

INSERT INTO CP_DESCUENTO_VENCIMIENTO
(id_descuento, dias_antes_vencimiento)
SELECT id_descuento, 20
FROM CP_DESCUENTO
WHERE nombre_descuento = 'Descuento Bebidas';

INSERT INTO CP_DESCUENTO_VENCIMIENTO
(id_descuento, dias_antes_vencimiento)
SELECT id_descuento, 10
FROM CP_DESCUENTO
WHERE nombre_descuento = 'Descuento Carnes';

INSERT INTO CP_DESCUENTO_VENCIMIENTO
(id_descuento, dias_antes_vencimiento)
SELECT id_descuento, 7
FROM CP_DESCUENTO
WHERE nombre_descuento = 'Descuento Verduras';

INSERT INTO CP_DESCUENTO_VENCIMIENTO
(id_descuento, dias_antes_vencimiento)
SELECT id_descuento, 15
FROM CP_DESCUENTO
WHERE nombre_descuento = 'Descuento Limpieza';


-- ============================================================
-- 83. CP_DESCUENTO_APLICADO
-- ============================================================

INSERT INTO CP_DESCUENTO_APLICADO
(id_detalle_venta_producto, id_descuento, monto_aplicado)
SELECT dv.id_detalle_venta_producto, d.id_descuento, 500
FROM CP_DETALLE_VENTA_PRODUCTO dv
JOIN CP_FACTURA_VENTA fv
    ON fv.id_factura_venta = dv.id_factura_venta
CROSS JOIN CP_DESCUENTO d
WHERE fv.numero_factura = 'VENT-001'
AND d.nombre_descuento = 'Descuento Abarrotes';

INSERT INTO CP_DESCUENTO_APLICADO
(id_detalle_venta_producto, id_descuento, monto_aplicado)
SELECT dv.id_detalle_venta_producto, d.id_descuento, 1000
FROM CP_DETALLE_VENTA_PRODUCTO dv
JOIN CP_FACTURA_VENTA fv
    ON fv.id_factura_venta = dv.id_factura_venta
CROSS JOIN CP_DESCUENTO d
WHERE fv.numero_factura = 'VENT-002'
AND d.nombre_descuento = 'Descuento Bebidas';

INSERT INTO CP_DESCUENTO_APLICADO
(id_detalle_venta_producto, id_descuento, monto_aplicado)
SELECT dv.id_detalle_venta_producto, d.id_descuento, 800
FROM CP_DETALLE_VENTA_PRODUCTO dv
JOIN CP_FACTURA_VENTA fv
    ON fv.id_factura_venta = dv.id_factura_venta
CROSS JOIN CP_DESCUENTO d
WHERE fv.numero_factura = 'VENT-003'
AND d.nombre_descuento = 'Descuento Carnes';

INSERT INTO CP_DESCUENTO_APLICADO
(id_detalle_venta_producto, id_descuento, monto_aplicado)
SELECT dv.id_detalle_venta_producto, d.id_descuento, 600
FROM CP_DETALLE_VENTA_PRODUCTO dv
JOIN CP_FACTURA_VENTA fv
    ON fv.id_factura_venta = dv.id_factura_venta
CROSS JOIN CP_DESCUENTO d
WHERE fv.numero_factura = 'VENT-004'
AND d.nombre_descuento = 'Descuento Verduras';

INSERT INTO CP_DESCUENTO_APLICADO
(id_detalle_venta_producto, id_descuento, monto_aplicado)
SELECT dv.id_detalle_venta_producto, d.id_descuento, 700
FROM CP_DETALLE_VENTA_PRODUCTO dv
JOIN CP_FACTURA_VENTA fv
    ON fv.id_factura_venta = dv.id_factura_venta
CROSS JOIN CP_DESCUENTO d
WHERE fv.numero_factura = 'VENT-005'
AND d.nombre_descuento = 'Descuento Limpieza';


-- ============================================================
-- 84. CP_ESTADO_DEVOLUCION
-- ============================================================

INSERT INTO CP_ESTADO_DEVOLUCION
(nombre_estado_devolucion, descripcion)
VALUES ('SOLICITADA', 'Devolucion registrada y pendiente de revision');

INSERT INTO CP_ESTADO_DEVOLUCION
(nombre_estado_devolucion, descripcion)
VALUES ('APROBADA', 'Devolucion aprobada');

INSERT INTO CP_ESTADO_DEVOLUCION
(nombre_estado_devolucion, descripcion)
VALUES ('RECHAZADA', 'Devolucion rechazada');

INSERT INTO CP_ESTADO_DEVOLUCION
(nombre_estado_devolucion, descripcion)
VALUES ('PROCESADA', 'Devolucion procesada');

INSERT INTO CP_ESTADO_DEVOLUCION
(nombre_estado_devolucion, descripcion)
VALUES ('ANULADA', 'Devolucion anulada');


-- ============================================================
-- 85. CP_MOTIVO_DEVOLUCION
-- ============================================================

INSERT INTO CP_MOTIVO_DEVOLUCION
(nombre_motivo_devolucion, descripcion)
VALUES ('PRODUCTO DANADO', 'El producto presenta danos');

INSERT INTO CP_MOTIVO_DEVOLUCION
(nombre_motivo_devolucion, descripcion)
VALUES ('PRODUCTO VENCIDO', 'El producto se encuentra vencido');

INSERT INTO CP_MOTIVO_DEVOLUCION
(nombre_motivo_devolucion, descripcion)
VALUES ('PRODUCTO INCORRECTO', 'Se entrego un producto incorrecto');

INSERT INTO CP_MOTIVO_DEVOLUCION
(nombre_motivo_devolucion, descripcion)
VALUES ('ERROR DE FACTURACION', 'Se produjo un error durante la facturacion');

INSERT INTO CP_MOTIVO_DEVOLUCION
(nombre_motivo_devolucion, descripcion)
VALUES ('CALIDAD DEL PRODUCTO', 'El producto no cumple con la calidad esperada');


-- ============================================================
-- 86. CP_DEVOLUCION_VENTA
-- ============================================================

INSERT INTO CP_DEVOLUCION_VENTA
(id_factura_venta, id_estado_devolucion, id_usuario,
 fecha_devolucion, monto_total, observacion)
SELECT fv.id_factura_venta, ed.id_estado_devolucion, u.id_usuario,
       DATE '2026-09-06', 1000, 'Devolucion venta 1'
FROM CP_FACTURA_VENTA fv
CROSS JOIN CP_ESTADO_DEVOLUCION ed
CROSS JOIN CP_USUARIO u
WHERE fv.numero_factura = 'VENT-001'
AND ed.nombre_estado_devolucion = 'SOLICITADA'
AND u.nombre_usuario = 'cmora';

INSERT INTO CP_DEVOLUCION_VENTA
(id_factura_venta, id_estado_devolucion, id_usuario,
 fecha_devolucion, monto_total, observacion)
SELECT fv.id_factura_venta, ed.id_estado_devolucion, u.id_usuario,
       DATE '2026-09-07', 1500, 'Devolucion venta 2'
FROM CP_FACTURA_VENTA fv
CROSS JOIN CP_ESTADO_DEVOLUCION ed
CROSS JOIN CP_USUARIO u
WHERE fv.numero_factura = 'VENT-002'
AND ed.nombre_estado_devolucion = 'SOLICITADA'
AND u.nombre_usuario = 'mjimenez';

INSERT INTO CP_DEVOLUCION_VENTA
(id_factura_venta, id_estado_devolucion, id_usuario,
 fecha_devolucion, monto_total, observacion)
SELECT fv.id_factura_venta, ed.id_estado_devolucion, u.id_usuario,
       DATE '2026-09-08', 4200, 'Devolucion venta 3'
FROM CP_FACTURA_VENTA fv
CROSS JOIN CP_ESTADO_DEVOLUCION ed
CROSS JOIN CP_USUARIO u
WHERE fv.numero_factura = 'VENT-003'
AND ed.nombre_estado_devolucion = 'SOLICITADA'
AND u.nombre_usuario = 'lvargas';

INSERT INTO CP_DEVOLUCION_VENTA
(id_factura_venta, id_estado_devolucion, id_usuario,
 fecha_devolucion, monto_total, observacion)
SELECT fv.id_factura_venta, ed.id_estado_devolucion, u.id_usuario,
       DATE '2026-09-09', 850, 'Devolucion venta 4'
FROM CP_FACTURA_VENTA fv
CROSS JOIN CP_ESTADO_DEVOLUCION ed
CROSS JOIN CP_USUARIO u
WHERE fv.numero_factura = 'VENT-004'
AND ed.nombre_estado_devolucion = 'SOLICITADA'
AND u.nombre_usuario = 'arodriguez';

INSERT INTO CP_DEVOLUCION_VENTA
(id_factura_venta, id_estado_devolucion, id_usuario,
 fecha_devolucion, monto_total, observacion)
SELECT fv.id_factura_venta, ed.id_estado_devolucion, u.id_usuario,
       DATE '2026-09-10', 2250, 'Devolucion venta 5'
FROM CP_FACTURA_VENTA fv
CROSS JOIN CP_ESTADO_DEVOLUCION ed
CROSS JOIN CP_USUARIO u
WHERE fv.numero_factura = 'VENT-005'
AND ed.nombre_estado_devolucion = 'SOLICITADA'
AND u.nombre_usuario = 'jquesada';


-- ============================================================
-- 87. CP_DETALLE_DEVOLUCION_VENTA
-- Solo devolvemos 1 unidad de cada venta.
-- ============================================================

INSERT INTO CP_DETALLE_DEVOLUCION_VENTA
(id_devolucion_venta, id_detalle_venta_lote,
 id_motivo_devolucion, cantidad_devuelta, monto_devolucion)
SELECT d.id_devolucion_venta, vl.id_detalle_venta_lote,
       m.id_motivo_devolucion, 1, 1000
FROM CP_DEVOLUCION_VENTA d
JOIN CP_FACTURA_VENTA fv
    ON fv.id_factura_venta = d.id_factura_venta
JOIN CP_DETALLE_VENTA_PRODUCTO vp
    ON vp.id_factura_venta = fv.id_factura_venta
JOIN CP_DETALLE_VENTA_LOTE vl
    ON vl.id_detalle_venta_producto = vp.id_detalle_venta_producto
CROSS JOIN CP_MOTIVO_DEVOLUCION m
WHERE d.observacion = 'Devolucion venta 1'
AND m.nombre_motivo_devolucion = 'PRODUCTO DANADO';

INSERT INTO CP_DETALLE_DEVOLUCION_VENTA
(id_devolucion_venta, id_detalle_venta_lote,
 id_motivo_devolucion, cantidad_devuelta, monto_devolucion)
SELECT d.id_devolucion_venta, vl.id_detalle_venta_lote,
       m.id_motivo_devolucion, 1, 1500
FROM CP_DEVOLUCION_VENTA d
JOIN CP_FACTURA_VENTA fv
    ON fv.id_factura_venta = d.id_factura_venta
JOIN CP_DETALLE_VENTA_PRODUCTO vp
    ON vp.id_factura_venta = fv.id_factura_venta
JOIN CP_DETALLE_VENTA_LOTE vl
    ON vl.id_detalle_venta_producto = vp.id_detalle_venta_producto
CROSS JOIN CP_MOTIVO_DEVOLUCION m
WHERE d.observacion = 'Devolucion venta 2'
AND m.nombre_motivo_devolucion = 'PRODUCTO VENCIDO';

INSERT INTO CP_DETALLE_DEVOLUCION_VENTA
(id_devolucion_venta, id_detalle_venta_lote,
 id_motivo_devolucion, cantidad_devuelta, monto_devolucion)
SELECT d.id_devolucion_venta, vl.id_detalle_venta_lote,
       m.id_motivo_devolucion, 1, 4200
FROM CP_DEVOLUCION_VENTA d
JOIN CP_FACTURA_VENTA fv
    ON fv.id_factura_venta = d.id_factura_venta
JOIN CP_DETALLE_VENTA_PRODUCTO vp
    ON vp.id_factura_venta = fv.id_factura_venta
JOIN CP_DETALLE_VENTA_LOTE vl
    ON vl.id_detalle_venta_producto = vp.id_detalle_venta_producto
CROSS JOIN CP_MOTIVO_DEVOLUCION m
WHERE d.observacion = 'Devolucion venta 3'
AND m.nombre_motivo_devolucion = 'PRODUCTO INCORRECTO';

INSERT INTO CP_DETALLE_DEVOLUCION_VENTA
(id_devolucion_venta, id_detalle_venta_lote,
 id_motivo_devolucion, cantidad_devuelta, monto_devolucion)
SELECT d.id_devolucion_venta, vl.id_detalle_venta_lote,
       m.id_motivo_devolucion, 1, 850
FROM CP_DEVOLUCION_VENTA d
JOIN CP_FACTURA_VENTA fv
    ON fv.id_factura_venta = d.id_factura_venta
JOIN CP_DETALLE_VENTA_PRODUCTO vp
    ON vp.id_factura_venta = fv.id_factura_venta
JOIN CP_DETALLE_VENTA_LOTE vl
    ON vl.id_detalle_venta_producto = vp.id_detalle_venta_producto
CROSS JOIN CP_MOTIVO_DEVOLUCION m
WHERE d.observacion = 'Devolucion venta 4'
AND m.nombre_motivo_devolucion = 'ERROR DE FACTURACION';

INSERT INTO CP_DETALLE_DEVOLUCION_VENTA
(id_devolucion_venta, id_detalle_venta_lote,
 id_motivo_devolucion, cantidad_devuelta, monto_devolucion)
SELECT d.id_devolucion_venta, vl.id_detalle_venta_lote,
       m.id_motivo_devolucion, 1, 2250
FROM CP_DEVOLUCION_VENTA d
JOIN CP_FACTURA_VENTA fv
    ON fv.id_factura_venta = d.id_factura_venta
JOIN CP_DETALLE_VENTA_PRODUCTO vp
    ON vp.id_factura_venta = fv.id_factura_venta
JOIN CP_DETALLE_VENTA_LOTE vl
    ON vl.id_detalle_venta_producto = vp.id_detalle_venta_producto
CROSS JOIN CP_MOTIVO_DEVOLUCION m
WHERE d.observacion = 'Devolucion venta 5'
AND m.nombre_motivo_devolucion = 'CALIDAD DEL PRODUCTO';


-- ============================================================
-- 88. CP_NOTA_CREDITO_CLIENTE
-- ============================================================

INSERT INTO CP_NOTA_CREDITO_CLIENTE
(id_devolucion_venta, numero_nota_credito,
 fecha_emision, monto_nota_credito)
SELECT id_devolucion_venta, 'NC-C-001',
       DATE '2026-09-06', 1000
FROM CP_DEVOLUCION_VENTA
WHERE observacion = 'Devolucion venta 1';

INSERT INTO CP_NOTA_CREDITO_CLIENTE
(id_devolucion_venta, numero_nota_credito,
 fecha_emision, monto_nota_credito)
SELECT id_devolucion_venta, 'NC-C-002',
       DATE '2026-09-07', 1500
FROM CP_DEVOLUCION_VENTA
WHERE observacion = 'Devolucion venta 2';

INSERT INTO CP_NOTA_CREDITO_CLIENTE
(id_devolucion_venta, numero_nota_credito,
 fecha_emision, monto_nota_credito)
SELECT id_devolucion_venta, 'NC-C-003',
       DATE '2026-09-08', 4200
FROM CP_DEVOLUCION_VENTA
WHERE observacion = 'Devolucion venta 3';

INSERT INTO CP_NOTA_CREDITO_CLIENTE
(id_devolucion_venta, numero_nota_credito,
 fecha_emision, monto_nota_credito)
SELECT id_devolucion_venta, 'NC-C-004',
       DATE '2026-09-09', 850
FROM CP_DEVOLUCION_VENTA
WHERE observacion = 'Devolucion venta 4';

INSERT INTO CP_NOTA_CREDITO_CLIENTE
(id_devolucion_venta, numero_nota_credito,
 fecha_emision, monto_nota_credito)
SELECT id_devolucion_venta, 'NC-C-005',
       DATE '2026-09-10', 2250
FROM CP_DEVOLUCION_VENTA
WHERE observacion = 'Devolucion venta 5';


-- ============================================================
-- 89. CP_DEVOLUCION_COMPRA
-- ============================================================

INSERT INTO CP_DEVOLUCION_COMPRA
(id_factura_compra, id_estado_devolucion, id_usuario,
 fecha_devolucion, observacion)
SELECT fc.id_factura_compra, e.id_estado_devolucion, u.id_usuario,
       DATE '2026-09-11', 'Devolucion compra 1'
FROM CP_FACTURA_COMPRA fc
CROSS JOIN CP_ESTADO_DEVOLUCION e
CROSS JOIN CP_USUARIO u
WHERE fc.numero_factura = 'COMP-001'
AND e.nombre_estado_devolucion = 'SOLICITADA'
AND u.nombre_usuario = 'cmora';

INSERT INTO CP_DEVOLUCION_COMPRA
(id_factura_compra, id_estado_devolucion, id_usuario,
 fecha_devolucion, observacion)
SELECT fc.id_factura_compra, e.id_estado_devolucion, u.id_usuario,
       DATE '2026-09-12', 'Devolucion compra 2'
FROM CP_FACTURA_COMPRA fc
CROSS JOIN CP_ESTADO_DEVOLUCION e
CROSS JOIN CP_USUARIO u
WHERE fc.numero_factura = 'COMP-002'
AND e.nombre_estado_devolucion = 'SOLICITADA'
AND u.nombre_usuario = 'mjimenez';

INSERT INTO CP_DEVOLUCION_COMPRA
(id_factura_compra, id_estado_devolucion, id_usuario,
 fecha_devolucion, observacion)
SELECT fc.id_factura_compra, e.id_estado_devolucion, u.id_usuario,
       DATE '2026-09-13', 'Devolucion compra 3'
FROM CP_FACTURA_COMPRA fc
CROSS JOIN CP_ESTADO_DEVOLUCION e
CROSS JOIN CP_USUARIO u
WHERE fc.numero_factura = 'COMP-003'
AND e.nombre_estado_devolucion = 'SOLICITADA'
AND u.nombre_usuario = 'lvargas';

INSERT INTO CP_DEVOLUCION_COMPRA
(id_factura_compra, id_estado_devolucion, id_usuario,
 fecha_devolucion, observacion)
SELECT fc.id_factura_compra, e.id_estado_devolucion, u.id_usuario,
       DATE '2026-09-14', 'Devolucion compra 4'
FROM CP_FACTURA_COMPRA fc
CROSS JOIN CP_ESTADO_DEVOLUCION e
CROSS JOIN CP_USUARIO u
WHERE fc.numero_factura = 'COMP-004'
AND e.nombre_estado_devolucion = 'SOLICITADA'
AND u.nombre_usuario = 'arodriguez';

INSERT INTO CP_DEVOLUCION_COMPRA
(id_factura_compra, id_estado_devolucion, id_usuario,
 fecha_devolucion, observacion)
SELECT fc.id_factura_compra, e.id_estado_devolucion, u.id_usuario,
       DATE '2026-09-15', 'Devolucion compra 5'
FROM CP_FACTURA_COMPRA fc
CROSS JOIN CP_ESTADO_DEVOLUCION e
CROSS JOIN CP_USUARIO u
WHERE fc.numero_factura = 'COMP-005'
AND e.nombre_estado_devolucion = 'SOLICITADA'
AND u.nombre_usuario = 'jquesada';


-- ============================================================
-- 90. CP_DETALLE_DEVOLUCION_COMPRA
-- ============================================================

INSERT INTO CP_DETALLE_DEVOLUCION_COMPRA
(id_devolucion_compra, id_lote_producto,
 id_motivo_devolucion, cantidad, monto_devolucion)
SELECT dc.id_devolucion_compra, l.id_lote_producto,
       m.id_motivo_devolucion, 1, 800
FROM CP_DEVOLUCION_COMPRA dc
CROSS JOIN CP_LOTE_PRODUCTO l
CROSS JOIN CP_MOTIVO_DEVOLUCION m
WHERE dc.observacion = 'Devolucion compra 1'
AND l.numero_lote = 'LOTE-001'
AND m.nombre_motivo_devolucion = 'PRODUCTO DANADO';

INSERT INTO CP_DETALLE_DEVOLUCION_COMPRA
(id_devolucion_compra, id_lote_producto,
 id_motivo_devolucion, cantidad, monto_devolucion)
SELECT dc.id_devolucion_compra, l.id_lote_producto,
       m.id_motivo_devolucion, 1, 1200
FROM CP_DEVOLUCION_COMPRA dc
CROSS JOIN CP_LOTE_PRODUCTO l
CROSS JOIN CP_MOTIVO_DEVOLUCION m
WHERE dc.observacion = 'Devolucion compra 2'
AND l.numero_lote = 'LOTE-002'
AND m.nombre_motivo_devolucion = 'PRODUCTO VENCIDO';

INSERT INTO CP_DETALLE_DEVOLUCION_COMPRA
(id_devolucion_compra, id_lote_producto,
 id_motivo_devolucion, cantidad, monto_devolucion)
SELECT dc.id_devolucion_compra, l.id_lote_producto,
       m.id_motivo_devolucion, 1, 3500
FROM CP_DEVOLUCION_COMPRA dc
CROSS JOIN CP_LOTE_PRODUCTO l
CROSS JOIN CP_MOTIVO_DEVOLUCION m
WHERE dc.observacion = 'Devolucion compra 3'
AND l.numero_lote = 'LOTE-003'
AND m.nombre_motivo_devolucion = 'PRODUCTO INCORRECTO';

INSERT INTO CP_DETALLE_DEVOLUCION_COMPRA
(id_devolucion_compra, id_lote_producto,
 id_motivo_devolucion, cantidad, monto_devolucion)
SELECT dc.id_devolucion_compra, l.id_lote_producto,
       m.id_motivo_devolucion, 1, 650
FROM CP_DEVOLUCION_COMPRA dc
CROSS JOIN CP_LOTE_PRODUCTO l
CROSS JOIN CP_MOTIVO_DEVOLUCION m
WHERE dc.observacion = 'Devolucion compra 4'
AND l.numero_lote = 'LOTE-004'
AND m.nombre_motivo_devolucion = 'ERROR DE FACTURACION';

INSERT INTO CP_DETALLE_DEVOLUCION_COMPRA
(id_devolucion_compra, id_lote_producto,
 id_motivo_devolucion, cantidad, monto_devolucion)
SELECT dc.id_devolucion_compra, l.id_lote_producto,
       m.id_motivo_devolucion, 1, 1800
FROM CP_DEVOLUCION_COMPRA dc
CROSS JOIN CP_LOTE_PRODUCTO l
CROSS JOIN CP_MOTIVO_DEVOLUCION m
WHERE dc.observacion = 'Devolucion compra 5'
AND l.numero_lote = 'LOTE-005'
AND m.nombre_motivo_devolucion = 'CALIDAD DEL PRODUCTO';


-- ============================================================
-- 91. CP_NOTA_CREDITO_PROVEEDOR
-- ============================================================

INSERT INTO CP_NOTA_CREDITO_PROVEEDOR
(id_devolucion_compra, numero_nota_credito,
 fecha_emision, monto_nota_credito)
SELECT id_devolucion_compra, 'NC-P-001',
       DATE '2026-09-11', 800
FROM CP_DEVOLUCION_COMPRA
WHERE observacion = 'Devolucion compra 1';

INSERT INTO CP_NOTA_CREDITO_PROVEEDOR
(id_devolucion_compra, numero_nota_credito,
 fecha_emision, monto_nota_credito)
SELECT id_devolucion_compra, 'NC-P-002',
       DATE '2026-09-12', 1200
FROM CP_DEVOLUCION_COMPRA
WHERE observacion = 'Devolucion compra 2';

INSERT INTO CP_NOTA_CREDITO_PROVEEDOR
(id_devolucion_compra, numero_nota_credito,
 fecha_emision, monto_nota_credito)
SELECT id_devolucion_compra, 'NC-P-003',
       DATE '2026-09-13', 3500
FROM CP_DEVOLUCION_COMPRA
WHERE observacion = 'Devolucion compra 3';

INSERT INTO CP_NOTA_CREDITO_PROVEEDOR
(id_devolucion_compra, numero_nota_credito,
 fecha_emision, monto_nota_credito)
SELECT id_devolucion_compra, 'NC-P-004',
       DATE '2026-09-14', 650
FROM CP_DEVOLUCION_COMPRA
WHERE observacion = 'Devolucion compra 4';

INSERT INTO CP_NOTA_CREDITO_PROVEEDOR
(id_devolucion_compra, numero_nota_credito,
 fecha_emision, monto_nota_credito)
SELECT id_devolucion_compra, 'NC-P-005',
       DATE '2026-09-15', 1800
FROM CP_DEVOLUCION_COMPRA
WHERE observacion = 'Devolucion compra 5';


-- ============================================================
-- 92. CP_BITACORA_PRECIO
-- ============================================================
-- Esta tabla se llena mediante el trigger de cambio de precio.
-- Hacemos 5 cambios controlados.

DECLARE
    v_id_usuario CP_USUARIO.id_usuario%TYPE;
BEGIN
    SELECT MIN(id_usuario)
    INTO v_id_usuario
    FROM CP_USUARIO;

    PKG_CP_CONTEXTO.establecer_usuario(v_id_usuario);
END;
/

UPDATE CP_PRODUCTO_NEGOCIO
SET precio_venta_actual = precio_venta_actual + 10
WHERE id_producto_negocio =
      (SELECT MIN(id_producto_negocio) FROM CP_PRODUCTO_NEGOCIO);

UPDATE CP_PRODUCTO_NEGOCIO
SET precio_venta_actual = precio_venta_actual + 20
WHERE id_producto_negocio =
      (SELECT MIN(id_producto_negocio) + 1 FROM CP_PRODUCTO_NEGOCIO);

UPDATE CP_PRODUCTO_NEGOCIO
SET precio_venta_actual = precio_venta_actual + 30
WHERE id_producto_negocio =
      (SELECT MIN(id_producto_negocio) + 2 FROM CP_PRODUCTO_NEGOCIO);

UPDATE CP_PRODUCTO_NEGOCIO
SET precio_venta_actual = precio_venta_actual + 40
WHERE id_producto_negocio =
      (SELECT MIN(id_producto_negocio) + 3 FROM CP_PRODUCTO_NEGOCIO);

UPDATE CP_PRODUCTO_NEGOCIO
SET precio_venta_actual = precio_venta_actual + 50
WHERE id_producto_negocio =
      (SELECT MIN(id_producto_negocio) + 4 FROM CP_PRODUCTO_NEGOCIO);


-- ============================================================
-- 93. CP_BITACORA_INVENTARIO
-- ============================================================
-- Se generan 5 registros mediante cambios controlados
-- en el inventario.

UPDATE CP_INVENTARIO_ALMACEN
SET cantidad_actual = cantidad_actual + 1
WHERE id_inventario_almacen =
      (SELECT MIN(id_inventario_almacen)
       FROM CP_INVENTARIO_ALMACEN);

UPDATE CP_INVENTARIO_ALMACEN
SET cantidad_actual = cantidad_actual + 1
WHERE id_inventario_almacen =
      (SELECT MIN(id_inventario_almacen) + 1
       FROM CP_INVENTARIO_ALMACEN);

UPDATE CP_INVENTARIO_ALMACEN
SET cantidad_actual = cantidad_actual + 1
WHERE id_inventario_almacen =
      (SELECT MIN(id_inventario_almacen) + 2
       FROM CP_INVENTARIO_ALMACEN);

UPDATE CP_INVENTARIO_ALMACEN
SET cantidad_actual = cantidad_actual + 1
WHERE id_inventario_almacen =
      (SELECT MIN(id_inventario_almacen) + 3
       FROM CP_INVENTARIO_ALMACEN);

UPDATE CP_INVENTARIO_ALMACEN
SET cantidad_actual = cantidad_actual + 1
WHERE id_inventario_almacen =
      (SELECT MIN(id_inventario_almacen) + 4
       FROM CP_INVENTARIO_ALMACEN);


-- ============================================================
-- 94. CP_BITACORA_TRASLADO
-- ============================================================
-- No se realizan UPDATE de CP_TRASLADO en la carga inicial.
-- Los 5 traslados ya se insertan directamente con estado EN PROCESO.
-- La bitácora de traslado se probará posteriormente en 11_pruebas.sql.

-- ============================================================
-- 95. CP_BITACORA_VENTA
-- ============================================================
-- Se generan mediante cambios de estado en las ventas.

UPDATE CP_FACTURA_VENTA
SET id_estado_factura_venta =
    (SELECT id_estado_factura_venta
     FROM CP_ESTADO_FACTURA_VENTA
     WHERE nombre_estado_factura = 'PAGADA')
WHERE numero_factura = 'VENT-001';

UPDATE CP_FACTURA_VENTA
SET id_estado_factura_venta =
    (SELECT id_estado_factura_venta
     FROM CP_ESTADO_FACTURA_VENTA
     WHERE nombre_estado_factura = 'PAGADA')
WHERE numero_factura = 'VENT-002';

UPDATE CP_FACTURA_VENTA
SET id_estado_factura_venta =
    (SELECT id_estado_factura_venta
     FROM CP_ESTADO_FACTURA_VENTA
     WHERE nombre_estado_factura = 'PAGADA')
WHERE numero_factura = 'VENT-003';

UPDATE CP_FACTURA_VENTA
SET id_estado_factura_venta =
    (SELECT id_estado_factura_venta
     FROM CP_ESTADO_FACTURA_VENTA
     WHERE nombre_estado_factura = 'PAGADA')
WHERE numero_factura = 'VENT-004';

UPDATE CP_FACTURA_VENTA
SET id_estado_factura_venta =
    (SELECT id_estado_factura_venta
     FROM CP_ESTADO_FACTURA_VENTA
     WHERE nombre_estado_factura = 'PAGADA')
WHERE numero_factura = 'VENT-005';


-- ============================================================
-- 96. CP_BITACORA_CREDITO_CLIENTE
-- ============================================================
-- Se generan modificando los 5 limites de credito.

UPDATE CP_CREDITO_CLIENTE
SET limite_credito = limite_credito + 1000
WHERE id_credito_cliente =
      (SELECT MIN(id_credito_cliente) FROM CP_CREDITO_CLIENTE);

UPDATE CP_CREDITO_CLIENTE
SET limite_credito = limite_credito + 1000
WHERE id_credito_cliente =
      (SELECT MIN(id_credito_cliente) + 1 FROM CP_CREDITO_CLIENTE);

UPDATE CP_CREDITO_CLIENTE
SET limite_credito = limite_credito + 1000
WHERE id_credito_cliente =
      (SELECT MIN(id_credito_cliente) + 2 FROM CP_CREDITO_CLIENTE);

UPDATE CP_CREDITO_CLIENTE
SET limite_credito = limite_credito + 1000
WHERE id_credito_cliente =
      (SELECT MIN(id_credito_cliente) + 3 FROM CP_CREDITO_CLIENTE);

UPDATE CP_CREDITO_CLIENTE
SET limite_credito = limite_credito + 1000
WHERE id_credito_cliente =
      (SELECT MIN(id_credito_cliente) + 4 FROM CP_CREDITO_CLIENTE);


-- ============================================================
-- 97. CP_BITACORA_CREDITO_PROVEEDOR
-- ============================================================

UPDATE CP_CREDITO_PROVEEDOR
SET limite_credito = limite_credito + 5000
WHERE id_credito_proveedor =
      (SELECT MIN(id_credito_proveedor) FROM CP_CREDITO_PROVEEDOR);

UPDATE CP_CREDITO_PROVEEDOR
SET limite_credito = limite_credito + 5000
WHERE id_credito_proveedor =
      (SELECT MIN(id_credito_proveedor) + 1 FROM CP_CREDITO_PROVEEDOR);

UPDATE CP_CREDITO_PROVEEDOR
SET limite_credito = limite_credito + 5000
WHERE id_credito_proveedor =
      (SELECT MIN(id_credito_proveedor) + 2 FROM CP_CREDITO_PROVEEDOR);

UPDATE CP_CREDITO_PROVEEDOR
SET limite_credito = limite_credito + 5000
WHERE id_credito_proveedor =
      (SELECT MIN(id_credito_proveedor) + 3 FROM CP_CREDITO_PROVEEDOR);

UPDATE CP_CREDITO_PROVEEDOR
SET limite_credito = limite_credito + 5000
WHERE id_credito_proveedor =
      (SELECT MIN(id_credito_proveedor) + 4 FROM CP_CREDITO_PROVEEDOR);


-- ============================================================
-- 98. CP_BITACORA_DEVOLUCION_VENTA
-- ============================================================
-- Cambiamos las devoluciones de SOLICITADA a APROBADA.

UPDATE CP_DEVOLUCION_VENTA
SET id_estado_devolucion =
    (SELECT id_estado_devolucion
     FROM CP_ESTADO_DEVOLUCION
     WHERE nombre_estado_devolucion = 'APROBADA')
WHERE observacion = 'Devolucion venta 1';

UPDATE CP_DEVOLUCION_VENTA
SET id_estado_devolucion =
    (SELECT id_estado_devolucion
     FROM CP_ESTADO_DEVOLUCION
     WHERE nombre_estado_devolucion = 'APROBADA')
WHERE observacion = 'Devolucion venta 2';

UPDATE CP_DEVOLUCION_VENTA
SET id_estado_devolucion =
    (SELECT id_estado_devolucion
     FROM CP_ESTADO_DEVOLUCION
     WHERE nombre_estado_devolucion = 'APROBADA')
WHERE observacion = 'Devolucion venta 3';

UPDATE CP_DEVOLUCION_VENTA
SET id_estado_devolucion =
    (SELECT id_estado_devolucion
     FROM CP_ESTADO_DEVOLUCION
     WHERE nombre_estado_devolucion = 'APROBADA')
WHERE observacion = 'Devolucion venta 4';

UPDATE CP_DEVOLUCION_VENTA
SET id_estado_devolucion =
    (SELECT id_estado_devolucion
     FROM CP_ESTADO_DEVOLUCION
     WHERE nombre_estado_devolucion = 'APROBADA')
WHERE observacion = 'Devolucion venta 5';


-- ============================================================
-- 99. CP_BITACORA_DEVOLUCION_COMPRA
-- ============================================================

UPDATE CP_DEVOLUCION_COMPRA
SET id_estado_devolucion =
    (SELECT id_estado_devolucion
     FROM CP_ESTADO_DEVOLUCION
     WHERE nombre_estado_devolucion = 'APROBADA')
WHERE observacion = 'Devolucion compra 1';

UPDATE CP_DEVOLUCION_COMPRA
SET id_estado_devolucion =
    (SELECT id_estado_devolucion
     FROM CP_ESTADO_DEVOLUCION
     WHERE nombre_estado_devolucion = 'APROBADA')
WHERE observacion = 'Devolucion compra 2';

UPDATE CP_DEVOLUCION_COMPRA
SET id_estado_devolucion =
    (SELECT id_estado_devolucion
     FROM CP_ESTADO_DEVOLUCION
     WHERE nombre_estado_devolucion = 'APROBADA')
WHERE observacion = 'Devolucion compra 3';

UPDATE CP_DEVOLUCION_COMPRA
SET id_estado_devolucion =
    (SELECT id_estado_devolucion
     FROM CP_ESTADO_DEVOLUCION
     WHERE nombre_estado_devolucion = 'APROBADA')
WHERE observacion = 'Devolucion compra 4';

UPDATE CP_DEVOLUCION_COMPRA
SET id_estado_devolucion =
    (SELECT id_estado_devolucion
     FROM CP_ESTADO_DEVOLUCION
     WHERE nombre_estado_devolucion = 'APROBADA')
WHERE observacion = 'Devolucion compra 5';


-- ============================================================
-- 100. CP_BITACORA_ACCESO
-- ============================================================
-- Esta bitacora se carga directamente porque también debe
-- registrar intentos de usuarios que no existen.

INSERT INTO CP_BITACORA_ACCESO
(id_usuario, nombre_usuario_intento, tipo_acceso,
 resultado, direccion_ip, observacion)
SELECT id_usuario, nombre_usuario,
       'INICIO_SESION', 'EXITOSO',
       '192.168.1.10', 'Inicio de sesion correcto'
FROM CP_USUARIO
WHERE nombre_usuario = 'cmora';

INSERT INTO CP_BITACORA_ACCESO
(id_usuario, nombre_usuario_intento, tipo_acceso,
 resultado, direccion_ip, observacion)
SELECT id_usuario, nombre_usuario,
       'CIERRE_SESION', 'EXITOSO',
       '192.168.1.10', 'Cierre de sesion correcto'
FROM CP_USUARIO
WHERE nombre_usuario = 'cmora';

INSERT INTO CP_BITACORA_ACCESO
(id_usuario, nombre_usuario_intento, tipo_acceso,
 resultado, direccion_ip, observacion)
SELECT id_usuario, nombre_usuario,
       'INICIO_SESION', 'EXITOSO',
       '192.168.1.11', 'Inicio de sesion correcto'
FROM CP_USUARIO
WHERE nombre_usuario = 'mjimenez';

INSERT INTO CP_BITACORA_ACCESO
(id_usuario, nombre_usuario_intento, tipo_acceso,
 resultado, direccion_ip, observacion)
VALUES
(NULL, 'usuario_inexistente',
 'INICIO_SESION', 'FALLIDO',
 '192.168.1.50', 'Usuario no registrado');

INSERT INTO CP_BITACORA_ACCESO
(id_usuario, nombre_usuario_intento, tipo_acceso,
 resultado, direccion_ip, observacion)
VALUES
(NULL, 'usuario_prueba',
 'INICIO_SESION', 'FALLIDO',
 '192.168.1.51', 'Intento de acceso fallido');


-- ============================================================
-- LIMPIAR CONTEXTO DE USUARIO
-- ============================================================

BEGIN
    PKG_CP_CONTEXTO.limpiar_usuario;
END;
/


COMMIT;
