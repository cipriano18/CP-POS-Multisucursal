-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- BASE DE DATOS: Oracle 21c
-- SCRIPT: 14_seguridad_cifrado.sql
-- DESCRIPCION: Tablas del cifrado y de los parametros del
--              sistema: CP_LLAVE_CIFRADO (llave AES) y
--              CP_PARAMETRO (valores parametrizados y valores
--              cifrados), con sus secuencias, restricciones,
--              comentarios y parametros iniciales.
--
-- EJECUTAR COMO: CP_POS en XEPDB1 (despues de CP_secuencias.sql y
--                CP_tablas.sql; el script 13 se vuelve a ejecutar
--                como SYS al final para clasificar estas tablas)
-- ============================================================

-- ============================================================
-- 1. SECUENCIAS
-- ============================================================

CREATE SEQUENCE SEQ_CP_LLAVE_CIFRADO
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;

CREATE SEQUENCE SEQ_CP_PARAMETRO
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;

-- ============================================================
-- 2. TABLA CP_LLAVE_CIFRADO
-- ============================================================

CREATE TABLE CP_LLAVE_CIFRADO (

    id_llave_cifrado NUMBER
        DEFAULT SEQ_CP_LLAVE_CIFRADO.NEXTVAL
        NOT NULL,

    llave RAW(32) NOT NULL,

    activa CHAR(1) DEFAULT 'S' NOT NULL,

    fecha_creacion TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,

    CONSTRAINT PK_CP_LLAVE_CIFRADO
        PRIMARY KEY (id_llave_cifrado)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;

-- ============================================================
-- 3. TABLA CP_PARAMETRO
-- ============================================================

CREATE TABLE CP_PARAMETRO (

    id_parametro NUMBER
        DEFAULT SEQ_CP_PARAMETRO.NEXTVAL
        NOT NULL,

    codigo_parametro VARCHAR2(60) NOT NULL,

    modulo VARCHAR2(30) NOT NULL,

    tipo_dato VARCHAR2(10) NOT NULL,

    unidad VARCHAR2(20),

    es_cifrado CHAR(1) DEFAULT 'N' NOT NULL,

    valor VARCHAR2(500),

    valor_cifrado RAW(2000),

    descripcion VARCHAR2(300),

    fecha_modificacion TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,

    CONSTRAINT PK_CP_PARAMETRO
        PRIMARY KEY (id_parametro)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;

-- ============================================================
-- 4. RESTRICCIONES
-- ============================================================

ALTER TABLE CP_LLAVE_CIFRADO
ADD CONSTRAINT CK_CP_LLAVE_ACTIVA
CHECK (activa IN ('S', 'N'));

ALTER TABLE CP_PARAMETRO
ADD CONSTRAINT UK_CP_PARAM_CODIGO
UNIQUE (codigo_parametro) USING INDEX TABLESPACE CP_POS_INDICES;

ALTER TABLE CP_PARAMETRO
ADD CONSTRAINT CK_CP_PARAM_TIPO
CHECK (tipo_dato IN ('NUMERO', 'TEXTO'));

ALTER TABLE CP_PARAMETRO
ADD CONSTRAINT CK_CP_PARAM_CIFRADO
CHECK (es_cifrado IN ('S', 'N'));

ALTER TABLE CP_PARAMETRO
ADD CONSTRAINT CK_CP_PARAM_VALOR
CHECK (
    (es_cifrado = 'N' AND valor IS NOT NULL AND valor_cifrado IS NULL)
    OR
    (es_cifrado = 'S' AND valor_cifrado IS NOT NULL AND valor IS NULL)
);

-- ============================================================
-- 5. INDICE UNICO: UNA SOLA LLAVE ACTIVA
-- ============================================================

CREATE UNIQUE INDEX IX_CP_LLAVE_ACTIVA
ON CP_LLAVE_CIFRADO (CASE WHEN activa = 'S' THEN 1 END)
TABLESPACE CP_POS_INDICES;

-- ============================================================
-- 6. COMENTARIOS
-- ============================================================

COMMENT ON TABLE CP_LLAVE_CIFRADO IS
'Almacena las llaves AES-256 usadas por PKG_CP_CRIPTO. Ningun rol de negocio tiene acceso.';

COMMENT ON COLUMN CP_LLAVE_CIFRADO.id_llave_cifrado IS
'Identificador unico de la llave.';

COMMENT ON COLUMN CP_LLAVE_CIFRADO.llave IS
'Llave AES de 256 bits (32 bytes) generada de forma aleatoria.';

COMMENT ON COLUMN CP_LLAVE_CIFRADO.activa IS
'Indica si la llave es la vigente para cifrar (S/N). Solo puede haber una activa.';

COMMENT ON COLUMN CP_LLAVE_CIFRADO.fecha_creacion IS
'Fecha y hora en que se genero la llave.';

COMMENT ON TABLE CP_PARAMETRO IS
'Almacena los parametros configurables del sistema y los valores sensibles cifrados.';

COMMENT ON COLUMN CP_PARAMETRO.id_parametro IS
'Identificador unico del parametro.';

COMMENT ON COLUMN CP_PARAMETRO.codigo_parametro IS
'Nombre estable con el que el codigo consulta el parametro.';

COMMENT ON COLUMN CP_PARAMETRO.modulo IS
'Area del sistema a la que pertenece el parametro.';

COMMENT ON COLUMN CP_PARAMETRO.tipo_dato IS
'Tipo logico del valor: NUMERO o TEXTO.';

COMMENT ON COLUMN CP_PARAMETRO.unidad IS
'Unidad en que se expresa el valor (MINUTOS, DIAS, PORCENTAJE, COLONES, MB, etc.).';

COMMENT ON COLUMN CP_PARAMETRO.es_cifrado IS
'Indica si el valor esta cifrado (S/N).';

COMMENT ON COLUMN CP_PARAMETRO.valor IS
'Valor en claro. Solo se usa cuando es_cifrado = N.';

COMMENT ON COLUMN CP_PARAMETRO.valor_cifrado IS
'Valor cifrado (id de llave + IV + texto cifrado). Solo se usa cuando es_cifrado = S.';

COMMENT ON COLUMN CP_PARAMETRO.descripcion IS
'Explicacion de para que se usa el parametro.';

COMMENT ON COLUMN CP_PARAMETRO.fecha_modificacion IS
'Fecha y hora de la ultima modificacion del parametro.';

-- ============================================================
-- 7. PARAMETROS INICIALES
-- ============================================================

INSERT INTO CP_PARAMETRO (codigo_parametro, modulo, tipo_dato, unidad, valor, descripcion)
VALUES ('ARCHIVELOG_INTERVALO_MINUTOS', 'STANDBY', 'NUMERO', 'MINUTOS', '5',
        'Cada cuantos minutos se genera un archivo de actualizacion (archivelog).');

INSERT INTO CP_PARAMETRO (codigo_parametro, modulo, tipo_dato, unidad, valor, descripcion)
VALUES ('ARCHIVELOG_TAMANO_MB', 'STANDBY', 'NUMERO', 'MB', '50',
        'Tamano maximo en MB que dispara la generacion de un archivelog.');

INSERT INTO CP_PARAMETRO (codigo_parametro, modulo, tipo_dato, unidad, valor, descripcion)
VALUES ('TRASLADO_STANDBY_MINUTOS', 'STANDBY', 'NUMERO', 'MINUTOS', '10',
        'Cada cuantos minutos se trasladan los archivos al servidor standby.');

INSERT INTO CP_PARAMETRO (codigo_parametro, modulo, tipo_dato, unidad, valor, descripcion)
VALUES ('RETENCION_ARCHIVOS_DIAS', 'STANDBY', 'NUMERO', 'DIAS', '3',
        'Dias que se conservan los archivos ya aplicados antes de eliminarlos.');

INSERT INTO CP_PARAMETRO (codigo_parametro, modulo, tipo_dato, unidad, valor, descripcion)
VALUES ('UMBRAL_CXC_CLIENTE_PCT', 'NOTIFICACION', 'NUMERO', 'PORCENTAJE', '85',
        'Porcentaje del limite de credito en cuentas por cobrar que dispara el aviso al cliente.');

INSERT INTO CP_PARAMETRO (codigo_parametro, modulo, tipo_dato, unidad, valor, descripcion)
VALUES ('UMBRAL_CXP_COORDINADOR_PCT', 'NOTIFICACION', 'NUMERO', 'PORCENTAJE', '85',
        'Porcentaje en cuentas por pagar que dispara el aviso al coordinador.');

INSERT INTO CP_PARAMETRO (codigo_parametro, modulo, tipo_dato, unidad, valor, descripcion)
VALUES ('UMBRAL_CXP_GERENTE_PCT', 'NOTIFICACION', 'NUMERO', 'PORCENTAJE', '70',
        'Porcentaje en cuentas por pagar de proveedores que dispara el aviso al gerente.');

INSERT INTO CP_PARAMETRO (codigo_parametro, modulo, tipo_dato, unidad, valor, descripcion)
VALUES ('MOROSIDAD_DIAS_SIN_PAGO', 'NOTIFICACION', 'NUMERO', 'DIAS', '30',
        'Dias desde el ultimo pago a partir de los cuales un cliente se considera moroso.');

INSERT INTO CP_PARAMETRO (codigo_parametro, modulo, tipo_dato, unidad, valor, descripcion)
VALUES ('PREMIO_CANTIDAD_CLIENTES', 'PREMIACION', 'NUMERO', 'CLIENTES', '10',
        'Cantidad de mejores clientes que reciben orden de compra.');

INSERT INTO CP_PARAMETRO (codigo_parametro, modulo, tipo_dato, unidad, valor, descripcion)
VALUES ('PREMIO_PERIODO_MESES', 'PREMIACION', 'NUMERO', 'MESES', '6',
        'Periodo en meses de cada premiacion de mejores clientes.');

INSERT INTO CP_PARAMETRO (codigo_parametro, modulo, tipo_dato, unidad, valor, descripcion)
VALUES ('PREMIO_MONTO_ORDEN', 'PREMIACION', 'NUMERO', 'COLONES', '100000',
        'Monto de la orden de compra que se entrega a cada cliente premiado.');

INSERT INTO CP_PARAMETRO (codigo_parametro, modulo, tipo_dato, unidad, valor, descripcion)
VALUES ('VENCIMIENTO_VENTANA_DIAS', 'VENCIMIENTO', 'NUMERO', 'DIAS', '7',
        'Dias de anticipacion para considerar un producto por vencer.');

INSERT INTO CP_PARAMETRO (codigo_parametro, modulo, tipo_dato, unidad, valor, descripcion)
VALUES ('ANTIGUEDAD_BODEGA_MESES', 'VENCIMIENTO', 'NUMERO', 'MESES', '6',
        'Meses en bodega a partir de los cuales un producto se considera con mucha antiguedad.');

INSERT INTO CP_PARAMETRO (codigo_parametro, modulo, tipo_dato, unidad, valor, descripcion)
VALUES ('TABLESPACE_UMBRAL_PCT', 'MONITOREO', 'NUMERO', 'PORCENTAJE', '85',
        'Porcentaje de uso de un tablespace que dispara la alerta.');

COMMIT;

-- ============================================================
-- 8. VERIFICACION
-- ============================================================

SELECT constraint_name, constraint_type, table_name
FROM user_constraints
WHERE table_name IN ('CP_LLAVE_CIFRADO', 'CP_PARAMETRO')
ORDER BY table_name, constraint_type, constraint_name;

SELECT index_name, uniqueness, table_name, tablespace_name
FROM user_indexes
WHERE table_name IN ('CP_LLAVE_CIFRADO', 'CP_PARAMETRO')
ORDER BY table_name, index_name;

SELECT modulo, COUNT(*) AS total
FROM CP_PARAMETRO
GROUP BY modulo
ORDER BY modulo;
