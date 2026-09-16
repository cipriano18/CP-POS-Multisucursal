-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- BASE DE DATOS: Oracle 21c
-- SCRIPT: 04_tablas.sql
-- DESCRIPCION: Creacion de las tablas del sistema
-- USUARIO: CP_POS
-- ============================================================


-- ============================================================
-- 1. CP_TIPO_NEGOCIO
-- ============================================================

CREATE TABLE CP_TIPO_NEGOCIO (
    id_tipo_negocio     NUMBER
        DEFAULT SEQ_CP_TIPO_NEGOCIO.NEXTVAL
        NOT NULL,

    nombre_tipo_negocio VARCHAR2(30)
        NOT NULL,

    descripcion         VARCHAR2(200),

    CONSTRAINT PK_CP_TIPO_NEGOCIO
        PRIMARY KEY (id_tipo_negocio)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;

-- ============================================================
-- 2. CP_ESTADO
-- ============================================================

CREATE TABLE CP_ESTADO (
    id_estado       NUMBER
        DEFAULT SEQ_CP_ESTADO.NEXTVAL
        NOT NULL,

    nombre          VARCHAR2(30)
        NOT NULL,

    descripcion     VARCHAR2(150),

    CONSTRAINT PK_CP_ESTADO
        PRIMARY KEY (id_estado)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;

-- ============================================================
-- 3. CP_TIPO_OPERACION
-- ============================================================

CREATE TABLE CP_TIPO_OPERACION (
    id_tipo_operacion      NUMBER
        DEFAULT SEQ_CP_TIPO_OPERACION.NEXTVAL
        NOT NULL,

    nombre_tipo_operacion  VARCHAR2(50)
        NOT NULL,

    descripcion            VARCHAR2(150),

    CONSTRAINT PK_CP_TIPO_OPERACION
        PRIMARY KEY (id_tipo_operacion)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_TIPO_OPERACION_NOMBRE
        UNIQUE (nombre_tipo_operacion)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 4. CP_PROVINCIA
-- ============================================================

CREATE TABLE CP_PROVINCIA (
    id_provincia    NUMBER
        DEFAULT SEQ_CP_PROVINCIA.NEXTVAL
        NOT NULL,

    nombre          VARCHAR2(100)
        NOT NULL,

    CONSTRAINT PK_CP_PROVINCIA
        PRIMARY KEY (id_provincia)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;

-- ============================================================
-- 5. CP_CANTON
-- ============================================================

CREATE TABLE CP_CANTON (
    id_canton       NUMBER
        DEFAULT SEQ_CP_CANTON.NEXTVAL
        NOT NULL,

    id_provincia    NUMBER
        NOT NULL,

    nombre          VARCHAR2(100)
        NOT NULL,

    CONSTRAINT PK_CP_CANTON
        PRIMARY KEY (id_canton)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 6. CP_DISTRITO
-- ============================================================

CREATE TABLE CP_DISTRITO (
    id_distrito     NUMBER
        DEFAULT SEQ_CP_DISTRITO.NEXTVAL
        NOT NULL,

    id_canton       NUMBER
        NOT NULL,

    nombre          VARCHAR2(100)
        NOT NULL,

    CONSTRAINT PK_CP_DISTRITO
        PRIMARY KEY (id_distrito)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 7. CP_DIRECCION
-- ============================================================

CREATE TABLE CP_DIRECCION (
    id_direccion    NUMBER
        DEFAULT SEQ_CP_DIRECCION.NEXTVAL
        NOT NULL,

    id_distrito     NUMBER
        NOT NULL,

    otras_senas     VARCHAR2(250)
        NOT NULL,

    CONSTRAINT PK_CP_DIRECCION
        PRIMARY KEY (id_direccion)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 8. CP_TIPO_DIRECCION
-- ============================================================

CREATE TABLE CP_TIPO_DIRECCION (
    id_tipo_direccion       NUMBER
        DEFAULT SEQ_CP_TIPO_DIRECCION.NEXTVAL
        NOT NULL,

    nombre_tipo_direccion   VARCHAR2(30)
        NOT NULL,

    descripcion             VARCHAR2(100),

    CONSTRAINT PK_CP_TIPO_DIRECCION
        PRIMARY KEY (id_tipo_direccion)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_TIPO_DIRECCION_NOMBRE
        UNIQUE (nombre_tipo_direccion)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;

-- ============================================================
-- 9. CP_SUCURSAL
-- ============================================================

CREATE TABLE CP_SUCURSAL (
    id_sucursal       NUMBER
        DEFAULT SEQ_CP_SUCURSAL.NEXTVAL
        NOT NULL,

    id_negocio        NUMBER
        NOT NULL,

    id_direccion      NUMBER
        NOT NULL,

    id_estado         NUMBER
        NOT NULL,

    codigo_sucursal   VARCHAR2(20)
        NOT NULL,

    nombre_sucursal   VARCHAR2(100)
        NOT NULL,

    CONSTRAINT PK_CP_SUCURSAL
        PRIMARY KEY (id_sucursal)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_SUCURSAL_CODIGO
        UNIQUE (codigo_sucursal)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 10. CP_NACIONALIDAD
-- ============================================================

CREATE TABLE CP_NACIONALIDAD (
    id_nacionalidad       NUMBER
        DEFAULT SEQ_CP_NACIONALIDAD.NEXTVAL
        NOT NULL,

    nombre_nacionalidad   VARCHAR2(20)
        NOT NULL,

    CONSTRAINT PK_CP_NACIONALIDAD
        PRIMARY KEY (id_nacionalidad)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_NACIONALIDAD_NOMBRE
        UNIQUE (nombre_nacionalidad)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 11. CP_SEXO
-- ============================================================

CREATE TABLE CP_SEXO (
    id_sexo       NUMBER
        DEFAULT SEQ_CP_SEXO.NEXTVAL
        NOT NULL,

    nombre_sexo   VARCHAR2(30)
        NOT NULL,

    CONSTRAINT PK_CP_SEXO
        PRIMARY KEY (id_sexo)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_SEXO_NOMBRE
        UNIQUE (nombre_sexo)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 12. CP_ESTADO_CIVIL
-- ============================================================

CREATE TABLE CP_ESTADO_CIVIL (
    id_estado_civil       NUMBER
        DEFAULT SEQ_CP_ESTADO_CIVIL.NEXTVAL
        NOT NULL,

    nombre_estado_civil   VARCHAR2(30)
        NOT NULL,

    CONSTRAINT PK_CP_ESTADO_CIVIL
        PRIMARY KEY (id_estado_civil)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_ESTADO_CIVIL_NOMBRE
        UNIQUE (nombre_estado_civil)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 13. CP_ESCOLARIDAD
-- ============================================================

CREATE TABLE CP_ESCOLARIDAD (
    id_escolaridad       NUMBER
        DEFAULT SEQ_CP_ESCOLARIDAD.NEXTVAL
        NOT NULL,

    nombre_escolaridad   VARCHAR2(50)
        NOT NULL,

    CONSTRAINT PK_CP_ESCOLARIDAD
        PRIMARY KEY (id_escolaridad)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_ESCOLARIDAD_NOMBRE
        UNIQUE (nombre_escolaridad)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 14. CP_TIPO_RESIDENCIA
-- ============================================================

CREATE TABLE CP_TIPO_RESIDENCIA (
    id_tipo_residencia       NUMBER
        DEFAULT SEQ_CP_TIPO_RESIDENCIA.NEXTVAL
        NOT NULL,

    nombre_tipo_residencia   VARCHAR2(50)
        NOT NULL,

    CONSTRAINT PK_CP_TIPO_RESIDENCIA
        PRIMARY KEY (id_tipo_residencia)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_TIPO_RESIDENCIA_NOMBRE
        UNIQUE (nombre_tipo_residencia)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 15. CP_PERSONA
-- ============================================================

CREATE TABLE CP_PERSONA (
    id_persona           NUMBER
        DEFAULT SEQ_CP_PERSONA.NEXTVAL
        NOT NULL,

    id_nacionalidad      NUMBER
        NOT NULL,

    id_estado_civil      NUMBER
        NOT NULL,

    id_sexo              NUMBER
        NOT NULL,

    id_escolaridad       NUMBER
        NOT NULL,

    id_tipo_residencia   NUMBER
        NOT NULL,

    identificacion       VARCHAR2(30)
        NOT NULL,

    primer_nombre        VARCHAR2(50)
        NOT NULL,

    segundo_nombre       VARCHAR2(50),

    primer_apellido      VARCHAR2(50)
        NOT NULL,

    segundo_apellido     VARCHAR2(50),

    fecha_nacimiento     DATE
        NOT NULL,

    es_asegurado         CHAR(1)
        DEFAULT 'N'
        NOT NULL,

    CONSTRAINT PK_CP_PERSONA
        PRIMARY KEY (id_persona)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_PERSONA_IDENTIFICACION
        UNIQUE (identificacion)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_PERSONA_ES_ASEGURADO
        CHECK (es_asegurado IN ('S', 'N'))

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 16. CP_TIPO_DE_CONTACTO
-- ============================================================

CREATE TABLE CP_TIPO_DE_CONTACTO (
    id_tipo_contacto       NUMBER
        DEFAULT SEQ_CP_TIPO_DE_CONTACTO.NEXTVAL
        NOT NULL,

    nombre_tipo_contacto   VARCHAR2(20)
        NOT NULL,

    descripcion            VARCHAR2(100),

    CONSTRAINT PK_CP_TIPO_DE_CONTACTO
        PRIMARY KEY (id_tipo_contacto)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_TIPO_CONTACTO_NOMBRE
        UNIQUE (nombre_tipo_contacto)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 17. CP_CONTACTO
-- ============================================================

CREATE TABLE CP_CONTACTO (
    id_contacto        NUMBER
        DEFAULT SEQ_CP_CONTACTO.NEXTVAL
        NOT NULL,

    id_tipo_contacto   NUMBER
        NOT NULL,

    valor_contacto     VARCHAR2(100)
        NOT NULL,

    CONSTRAINT PK_CP_CONTACTO
        PRIMARY KEY (id_contacto)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 18. CP_PERSONA_DIRECCION
-- ============================================================

CREATE TABLE CP_PERSONA_DIRECCION (
    id_persona_direccion   NUMBER
        DEFAULT SEQ_CP_PERSONA_DIRECCION.NEXTVAL
        NOT NULL,

    id_persona             NUMBER
        NOT NULL,

    id_direccion           NUMBER
        NOT NULL,

    id_tipo_direccion      NUMBER
        NOT NULL,

    es_principal           CHAR(1)
        DEFAULT 'N'
        NOT NULL,

    CONSTRAINT PK_CP_PERSONA_DIRECCION
        PRIMARY KEY (id_persona_direccion)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_PERSONA_DIRECCION_PRINCIPAL
        CHECK (es_principal IN ('S', 'N'))

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 19. CP_PERSONA_CONTACTO
-- ============================================================

CREATE TABLE CP_PERSONA_CONTACTO (
    id_persona_contacto    NUMBER
        DEFAULT SEQ_CP_PERSONA_CONTACTO.NEXTVAL
        NOT NULL,

    id_persona             NUMBER
        NOT NULL,

    id_contacto            NUMBER
        NOT NULL,

    es_principal           CHAR(1)
        DEFAULT 'N'
        NOT NULL,

    CONSTRAINT PK_CP_PERSONA_CONTACTO
        PRIMARY KEY (id_persona_contacto)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_PERSONA_CONTACTO_PRINCIPAL
        CHECK (es_principal IN ('S', 'N'))

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 20. CP_PUESTO
-- ============================================================

CREATE TABLE CP_PUESTO (
    id_puesto       NUMBER
        DEFAULT SEQ_CP_PUESTO.NEXTVAL
        NOT NULL,

    nombre_puesto   VARCHAR2(100)
        NOT NULL,

    descripcion     VARCHAR2(150),

    CONSTRAINT PK_CP_PUESTO
        PRIMARY KEY (id_puesto)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_PUESTO_NOMBRE
        UNIQUE (nombre_puesto)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 21. CP_EMPRESA_LABORAL
-- ============================================================

CREATE TABLE CP_EMPRESA_LABORAL (
    id_empresa_laboral   NUMBER
        DEFAULT SEQ_CP_EMPRESA_LABORAL.NEXTVAL
        NOT NULL,

    cedula_juridica      VARCHAR2(20)
        NOT NULL,

    razon_social         VARCHAR2(150)
        NOT NULL,

    nombre_comercial     VARCHAR2(150),

    CONSTRAINT PK_CP_EMPRESA_LABORAL
        PRIMARY KEY (id_empresa_laboral)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_EMPRESA_LABORAL_CEDULA
        UNIQUE (cedula_juridica)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;

-- ============================================================
-- 22. CP_PERSONA_EMPLEO
-- ============================================================

CREATE TABLE CP_PERSONA_EMPLEO (
    id_persona_empleo    NUMBER
        DEFAULT SEQ_CP_PERSONA_EMPLEO.NEXTVAL
        NOT NULL,

    id_persona           NUMBER
        NOT NULL,

    id_puesto            NUMBER
        NOT NULL,

    id_empresa_laboral   NUMBER
        NOT NULL,

    fecha_ingreso        DATE
        NOT NULL,

    fecha_salida         DATE,

    CONSTRAINT PK_CP_PERSONA_EMPLEO
        PRIMARY KEY (id_persona_empleo)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_PERSONA_EMPLEO_PERIODO
        CHECK (fecha_salida IS NULL OR fecha_salida >= fecha_ingreso)

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 23. CP_ROL
-- ============================================================

CREATE TABLE CP_ROL (
    id_rol       NUMBER
        DEFAULT SEQ_CP_ROL.NEXTVAL
        NOT NULL,

    id_estado    NUMBER
        NOT NULL,

    nombre_rol   VARCHAR2(50)
        NOT NULL,

    descripcion  VARCHAR2(50),

    CONSTRAINT PK_CP_ROL
        PRIMARY KEY (id_rol)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_ROL_NOMBRE
        UNIQUE (nombre_rol)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 24. CP_PERMISO
-- ============================================================

CREATE TABLE CP_PERMISO (
    id_permiso       NUMBER
        DEFAULT SEQ_CP_PERMISO.NEXTVAL
        NOT NULL,

    id_estado        NUMBER
        NOT NULL,

    nombre_permiso   VARCHAR2(100)
        NOT NULL,

    CONSTRAINT PK_CP_PERMISO
        PRIMARY KEY (id_permiso)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_PERMISO_NOMBRE
        UNIQUE (nombre_permiso)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 25. CP_ROL_PERMISO
-- ============================================================

CREATE TABLE CP_ROL_PERMISO (
    id_rol_permiso   NUMBER
        DEFAULT SEQ_CP_ROL_PERMISO.NEXTVAL
        NOT NULL,

    id_rol           NUMBER
        NOT NULL,

    id_permiso       NUMBER
        NOT NULL,

    CONSTRAINT PK_CP_ROL_PERMISO
        PRIMARY KEY (id_rol_permiso)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;

-- ============================================================
-- 26. CP_USUARIO
-- ============================================================

CREATE TABLE CP_USUARIO (
    id_usuario       NUMBER
        DEFAULT SEQ_CP_USUARIO.NEXTVAL
        NOT NULL,

    id_persona       NUMBER
        NOT NULL,

    id_estado        NUMBER
        NOT NULL,

    id_sucursal      NUMBER
        NOT NULL,

    id_rol           NUMBER
        NOT NULL,

    nombre_usuario   VARCHAR2(50)
        NOT NULL,

    contrasena_hash  VARCHAR2(255)
        NOT NULL,

    fecha_creacion   TIMESTAMP
        DEFAULT SYSTIMESTAMP
        NOT NULL,

    ultimo_acceso    TIMESTAMP,

    CONSTRAINT PK_CP_USUARIO
        PRIMARY KEY (id_usuario)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 27. CP_TIPO_CLIENTE
-- ============================================================

CREATE TABLE CP_TIPO_CLIENTE (
    id_tipo_cliente       NUMBER
        DEFAULT SEQ_CP_TIPO_CLIENTE.NEXTVAL
        NOT NULL,

    nombre_tipo_cliente   VARCHAR2(30)
        NOT NULL,

    descripcion           VARCHAR2(150),

    CONSTRAINT PK_CP_TIPO_CLIENTE
        PRIMARY KEY (id_tipo_cliente)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_TIPO_CLIENTE_NOMBRE
        UNIQUE (nombre_tipo_cliente)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 28. CP_ESTADO_CLIENTE
-- ============================================================

CREATE TABLE CP_ESTADO_CLIENTE (
    id_estado_cliente       NUMBER
        DEFAULT SEQ_CP_ESTADO_CLIENTE.NEXTVAL
        NOT NULL,

    nombre_estado_cliente   VARCHAR2(30)
        NOT NULL,

    descripcion             VARCHAR2(150),

    CONSTRAINT PK_CP_ESTADO_CLIENTE
        PRIMARY KEY (id_estado_cliente)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_ESTADO_CLIENTE_NOMBRE
        UNIQUE (nombre_estado_cliente)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 29. CP_CLIENTE
-- ============================================================

CREATE TABLE CP_CLIENTE (
    id_cliente           NUMBER
        DEFAULT SEQ_CP_CLIENTE.NEXTVAL
        NOT NULL,

    id_tipo_cliente      NUMBER
        NOT NULL,

    id_estado_cliente    NUMBER
        NOT NULL,

    fecha_ingreso        DATE
        NOT NULL,

    es_cliente_defecto   CHAR(1)
        DEFAULT 'N'
        NOT NULL,

    CONSTRAINT PK_CP_CLIENTE
        PRIMARY KEY (id_cliente)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_CLIENTE_ES_DEFECTO
        CHECK (es_cliente_defecto IN ('S', 'N'))

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 30. CP_CLIENTE_PERSONA
-- ============================================================

CREATE TABLE CP_CLIENTE_PERSONA (
    id_cliente_persona   NUMBER
        DEFAULT SEQ_CP_CLIENTE_PERSONA.NEXTVAL
        NOT NULL,

    id_cliente           NUMBER
        NOT NULL,

    id_persona           NUMBER
        NOT NULL,

    CONSTRAINT PK_CP_CLIENTE_PERSONA
        PRIMARY KEY (id_cliente_persona)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_CLIENTE_PERSONA_CLIENTE
        UNIQUE (id_cliente)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 31. CP_CLIENTE_EMPRESA
-- ============================================================

CREATE TABLE CP_CLIENTE_EMPRESA (
    id_cliente_empresa   NUMBER
        DEFAULT SEQ_CP_CLIENTE_EMPRESA.NEXTVAL
        NOT NULL,

    id_cliente           NUMBER
        NOT NULL,

    cedula_juridica      VARCHAR2(20)
        NOT NULL,

    razon_social         VARCHAR2(150)
        NOT NULL,

    nombre_comercial     VARCHAR2(150),

    CONSTRAINT PK_CP_CLIENTE_EMPRESA
        PRIMARY KEY (id_cliente_empresa)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_CLIENTE_EMPRESA_CLIENTE
        UNIQUE (id_cliente)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_CLIENTE_EMPRESA_CEDULA
        UNIQUE (cedula_juridica)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 32. CP_CLIENTE_EMPRESA_DIRECCION
-- ============================================================

CREATE TABLE CP_CLIENTE_EMPRESA_DIRECCION (
    id_cliente_empresa_direccion   NUMBER
        DEFAULT SEQ_CP_CLIENTE_EMPRESA_DIRECCION.NEXTVAL
        NOT NULL,

    id_cliente_empresa             NUMBER
        NOT NULL,

    id_direccion                   NUMBER
        NOT NULL,

    id_tipo_direccion              NUMBER
        NOT NULL,

    es_principal                   CHAR(1)
        DEFAULT 'N'
        NOT NULL,

    CONSTRAINT PK_CP_CLIENTE_EMPRESA_DIRECCION
        PRIMARY KEY (id_cliente_empresa_direccion)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_CLI_EMP_DIR_PRINCIPAL
        CHECK (es_principal IN ('S', 'N'))

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 33. CP_CLIENTE_EMPRESA_CONTACTO
-- ============================================================

CREATE TABLE CP_CLIENTE_EMPRESA_CONTACTO (
    id_cliente_empresa_contacto   NUMBER
        DEFAULT SEQ_CP_CLIENTE_EMPRESA_CONTACTO.NEXTVAL
        NOT NULL,

    id_cliente_empresa            NUMBER
        NOT NULL,

    id_contacto                   NUMBER
        NOT NULL,

    es_principal                  CHAR(1)
        DEFAULT 'N'
        NOT NULL,

    CONSTRAINT PK_CP_CLIENTE_EMPRESA_CONTACTO
        PRIMARY KEY (id_cliente_empresa_contacto)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_CLI_EMP_CONT_PRINCIPAL
        CHECK (es_principal IN ('S', 'N'))

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 34. CP_PROVEEDOR
-- ============================================================

CREATE TABLE CP_PROVEEDOR (
    id_proveedor       NUMBER
        DEFAULT SEQ_CP_PROVEEDOR.NEXTVAL
        NOT NULL,

    id_estado          NUMBER
        NOT NULL,

    cedula_juridica    VARCHAR2(50)
        NOT NULL,

    razon_social       VARCHAR2(150)
        NOT NULL,

    nombre_comercial   VARCHAR2(100),

    fecha_registro     DATE
        DEFAULT SYSDATE
        NOT NULL,

    CONSTRAINT PK_CP_PROVEEDOR
        PRIMARY KEY (id_proveedor)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_PROVEEDOR_CEDULA
        UNIQUE (cedula_juridica)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 35. CP_PROVEEDOR_DIRECCION
-- ============================================================

CREATE TABLE CP_PROVEEDOR_DIRECCION (
    id_proveedor_direccion   NUMBER
        DEFAULT SEQ_CP_PROVEEDOR_DIRECCION.NEXTVAL
        NOT NULL,

    id_proveedor             NUMBER
        NOT NULL,

    id_tipo_direccion        NUMBER
        NOT NULL,

    id_direccion             NUMBER
        NOT NULL,

    es_principal             CHAR(1)
        DEFAULT 'N'
        NOT NULL,

    fecha_asignacion         DATE
        NOT NULL,

    CONSTRAINT PK_CP_PROVEEDOR_DIRECCION
        PRIMARY KEY (id_proveedor_direccion)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_PROV_DIR_PRINCIPAL
        CHECK (es_principal IN ('S', 'N'))

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 36. CP_NEGOCIO
-- ============================================================

CREATE TABLE CP_NEGOCIO (
    id_negocio          NUMBER
        DEFAULT SEQ_CP_NEGOCIO.NEXTVAL
        NOT NULL,

    id_tipo_negocio     NUMBER
        NOT NULL,

    id_estado           NUMBER
        NOT NULL,

    cedula_juridica     VARCHAR2(20)
        NOT NULL,

    nombre_negocio      VARCHAR2(100)
        NOT NULL,

    fecha_registro      DATE
        DEFAULT SYSDATE
        NOT NULL,

    CONSTRAINT PK_CP_NEGOCIO
        PRIMARY KEY (id_negocio)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_NEGOCIO_CEDULA
        UNIQUE (cedula_juridica)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 37. CP_PROVEEDOR_CONTACTO
-- ============================================================

CREATE TABLE CP_PROVEEDOR_CONTACTO (
    id_proveedor_contacto   NUMBER
        DEFAULT SEQ_CP_PROVEEDOR_CONTACTO.NEXTVAL
        NOT NULL,

    id_proveedor            NUMBER
        NOT NULL,

    id_contacto             NUMBER
        NOT NULL,

    es_principal            CHAR(1)
        DEFAULT 'N'
        NOT NULL,

    CONSTRAINT PK_CP_PROVEEDOR_CONTACTO
        PRIMARY KEY (id_proveedor_contacto)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_PROVEEDOR_CONTACTO_PRINCIPAL
        CHECK (es_principal IN ('S', 'N'))

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 38. CP_CREDITO_PROVEEDOR
-- ============================================================

CREATE TABLE CP_CREDITO_PROVEEDOR (
    id_credito_proveedor   NUMBER
        DEFAULT SEQ_CP_CREDITO_PROVEEDOR.NEXTVAL
        NOT NULL,

    id_proveedor           NUMBER
        NOT NULL,

    id_negocio             NUMBER
        NOT NULL,

    id_estado_credito      NUMBER
        NOT NULL,

    limite_credito         NUMBER(14,2)
        NOT NULL,

    fecha_autorizacion     DATE
        NOT NULL,

    fecha_vencimiento      DATE,

    CONSTRAINT PK_CP_CREDITO_PROVEEDOR
        PRIMARY KEY (id_credito_proveedor)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_CREDITO_PROVEEDOR_LIMITE
        CHECK (limite_credito >= 0),

    CONSTRAINT CK_CP_CREDITO_PROVEEDOR_VIGENCIA
        CHECK (
            fecha_vencimiento IS NULL
            OR fecha_vencimiento >= fecha_autorizacion
        )

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 39. CP_FAMILIA_PRODUCTO
-- ============================================================

CREATE TABLE CP_FAMILIA_PRODUCTO (
    id_familia_producto   NUMBER
        DEFAULT SEQ_CP_FAMILIA_PRODUCTO.NEXTVAL
        NOT NULL,

    nombre_familia        VARCHAR2(20)
        NOT NULL,

    descripcion           VARCHAR2(200),

    CONSTRAINT PK_CP_FAMILIA_PRODUCTO
        PRIMARY KEY (id_familia_producto)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_FAMILIA_PRODUCTO_NOMBRE_FAMILIA
        UNIQUE (nombre_familia)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 40. CP_IMPUESTO
-- ============================================================

CREATE TABLE CP_IMPUESTO (
    id_impuesto           NUMBER
        DEFAULT SEQ_CP_IMPUESTO.NEXTVAL
        NOT NULL,

    id_estado             NUMBER
        NOT NULL,

    nombre_impuesto       VARCHAR2(50)
        NOT NULL,

    porcentaje_impuesto   NUMBER(5,2)
        NOT NULL,

    descripcion           VARCHAR2(150),

    CONSTRAINT PK_CP_IMPUESTO
        PRIMARY KEY (id_impuesto)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_IMPUESTO_NOMBRE_IMPUESTO
        UNIQUE (nombre_impuesto)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_IMPUESTO_PORCENTAJE
        CHECK (porcentaje_impuesto BETWEEN 0 AND 100)

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 41. CP_PRODUCTO
-- ============================================================

CREATE TABLE CP_PRODUCTO (
    id_producto           NUMBER
        DEFAULT SEQ_CP_PRODUCTO.NEXTVAL
        NOT NULL,

    id_familia_producto   NUMBER
        NOT NULL,

    id_impuesto           NUMBER
        NOT NULL,

    id_estado             NUMBER
        NOT NULL,

    codigo_producto       VARCHAR2(30)
        NOT NULL,

    nombre_producto       VARCHAR2(150)
        NOT NULL,

    descripcion           VARCHAR2(250),

    CONSTRAINT PK_CP_PRODUCTO
        PRIMARY KEY (id_producto)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_PRODUCTO_CODIGO_PRODUCTO
        UNIQUE (codigo_producto)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 42. CP_CODIGO_BARRA
-- ============================================================

CREATE TABLE CP_CODIGO_BARRA (
    id_codigo_barra   NUMBER
        DEFAULT SEQ_CP_CODIGO_BARRA.NEXTVAL
        NOT NULL,

    id_producto       NUMBER
        NOT NULL,

    codigo_barra      VARCHAR2(50)
        NOT NULL,

    CONSTRAINT PK_CP_CODIGO_BARRA
        PRIMARY KEY (id_codigo_barra)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_CODIGO_BARRA_CODIGO_BARRA
        UNIQUE (codigo_barra)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 43. CP_PRODUCTO_PROVEEDOR
-- ============================================================

CREATE TABLE CP_PRODUCTO_PROVEEDOR (
    id_producto_proveedor   NUMBER
        DEFAULT SEQ_CP_PRODUCTO_PROVEEDOR.NEXTVAL
        NOT NULL,

    id_proveedor            NUMBER
        NOT NULL,

    id_producto             NUMBER
        NOT NULL,

    precio_costo_actual     NUMBER(14,2)
        NOT NULL,

    CONSTRAINT PK_CP_PRODUCTO_PROVEEDOR
        PRIMARY KEY (id_producto_proveedor)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_PRODUCTO_PROVEEDOR_REL
        UNIQUE (id_producto, id_proveedor)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_PRODUCTO_PROVEEDOR_COSTO_ACT
        CHECK (precio_costo_actual >= 0)

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 44. CP_PRODUCTO_NEGOCIO
-- ============================================================

CREATE TABLE CP_PRODUCTO_NEGOCIO (
    id_producto_negocio   NUMBER
        DEFAULT SEQ_CP_PRODUCTO_NEGOCIO.NEXTVAL
        NOT NULL,

    id_producto           NUMBER
        NOT NULL,

    id_negocio            NUMBER
        NOT NULL,

    porcentaje_utilidad   NUMBER(5,2)
        NOT NULL,

    descuento_maximo      NUMBER(5,2)
        NOT NULL,

    precio_venta_actual   NUMBER(14,2)
        NOT NULL,

    CONSTRAINT PK_CP_PRODUCTO_NEGOCIO
        PRIMARY KEY (id_producto_negocio)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_PRODUCTO_NEGOCIO_UTILIDAD
        CHECK (porcentaje_utilidad BETWEEN 0 AND 100),

    CONSTRAINT CK_CP_PRODUCTO_NEGOCIO_DESCUENTO
        CHECK (descuento_maximo BETWEEN 0 AND 100),

    CONSTRAINT CK_CP_PRODUCTO_NEGOCIO_PRECIO_ACT
        CHECK (precio_venta_actual >= 0)

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 45. CP_LOTE_PRODUCTO
-- ============================================================

CREATE TABLE CP_LOTE_PRODUCTO (
    id_lote_producto    NUMBER
        DEFAULT SEQ_CP_LOTE_PRODUCTO.NEXTVAL
        NOT NULL,

    id_detalle_compra   NUMBER
        NOT NULL,

    numero_lote         VARCHAR2(50)
        NOT NULL,

    cantidad_recibida   NUMBER(12,2)
        NOT NULL,

    fecha_ingreso       DATE
        NOT NULL,

    fecha_vencimiento   DATE,

    CONSTRAINT PK_CP_LOTE_PRODUCTO
        PRIMARY KEY (id_lote_producto)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_LOTE_PRODUCTO_CANTIDAD
        CHECK (cantidad_recibida > 0),

    CONSTRAINT CK_CP_LOTE_PRODUCTO_FECHAS
        CHECK (
            fecha_vencimiento IS NULL
            OR fecha_vencimiento >= fecha_ingreso
        )

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 46. CP_TIPO_ALMACEN
-- ============================================================

CREATE TABLE CP_TIPO_ALMACEN (
    id_tipo_almacen       NUMBER
        DEFAULT SEQ_CP_TIPO_ALMACEN.NEXTVAL
        NOT NULL,

    nombre_tipo_almacen   VARCHAR2(50)
        NOT NULL,

    descripcion           VARCHAR2(150),

    CONSTRAINT PK_CP_TIPO_ALMACEN
        PRIMARY KEY (id_tipo_almacen)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 47. CP_ALMACEN
-- ============================================================

CREATE TABLE CP_ALMACEN (
    id_almacen        NUMBER
        DEFAULT SEQ_CP_ALMACEN.NEXTVAL
        NOT NULL,

    id_tipo_almacen   NUMBER
        NOT NULL,

    id_sucursal       NUMBER
        NOT NULL,

    id_estado         NUMBER
        NOT NULL,

    id_direccion      NUMBER
        NOT NULL,

    nombre_almacen    VARCHAR2(100)
        NOT NULL,

    fecha_registro    DATE
        DEFAULT SYSDATE
        NOT NULL,

    CONSTRAINT PK_CP_ALMACEN
        PRIMARY KEY (id_almacen)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 48. CP_INVENTARIO_ALMACEN
-- ============================================================

CREATE TABLE CP_INVENTARIO_ALMACEN (
    id_inventario_almacen   NUMBER
        DEFAULT SEQ_CP_INVENTARIO_ALMACEN.NEXTVAL
        NOT NULL,

    id_almacen              NUMBER
        NOT NULL,

    id_lote_producto        NUMBER
        NOT NULL,

    cantidad_actual         NUMBER(12,2)
        NOT NULL,

    fecha_actualizacion     TIMESTAMP
        NOT NULL,

    CONSTRAINT PK_CP_INVENTARIO_ALMACEN
        PRIMARY KEY (id_inventario_almacen)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_INVENTARIO_ALMACEN_LOTE
        UNIQUE (id_almacen, id_lote_producto)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_INVENTARIO_ALMACEN_CANTIDAD
        CHECK (cantidad_actual >= 0)

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 49. CP_ESTADO_TRASLADO
-- ============================================================

CREATE TABLE CP_ESTADO_TRASLADO (
    id_estado_traslado       NUMBER
        DEFAULT SEQ_CP_ESTADO_TRASLADO.NEXTVAL
        NOT NULL,

    nombre_estado_traslado   VARCHAR2(30)
        NOT NULL,

    descripcion              VARCHAR2(150),

    CONSTRAINT PK_CP_ESTADO_TRASLADO
        PRIMARY KEY (id_estado_traslado)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 50. CP_TRASLADO
-- ============================================================

CREATE TABLE CP_TRASLADO (
    id_traslado           NUMBER
        DEFAULT SEQ_CP_TRASLADO.NEXTVAL
        NOT NULL,

    id_almacen_origen     NUMBER
        NOT NULL,

    id_almacen_destino    NUMBER
        NOT NULL,

    id_usuario_solicita   NUMBER
        NOT NULL,

    id_usuario_recibe     NUMBER,

    id_estado_traslado    NUMBER
        NOT NULL,

    fecha_solicitud       TIMESTAMP
        NOT NULL,

    fecha_recepcion       TIMESTAMP,

    observacion           VARCHAR2(250),

    CONSTRAINT PK_CP_TRASLADO
        PRIMARY KEY (id_traslado)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_TRASLADO_ALMACENES
        CHECK (id_almacen_origen <> id_almacen_destino),

    CONSTRAINT CK_CP_TRASLADO_RECEPCION
        CHECK (
            fecha_recepcion IS NULL
            OR fecha_recepcion >= fecha_solicitud
        )

) TABLESPACE CP_POS_DATOS;

-- ============================================================
-- 51. CP_DETALLE_TRASLADO
-- ============================================================

CREATE TABLE CP_DETALLE_TRASLADO (
    id_detalle_traslado   NUMBER
        DEFAULT SEQ_CP_DETALLE_TRASLADO.NEXTVAL
        NOT NULL,

    id_traslado           NUMBER
        NOT NULL,

    id_lote_producto      NUMBER
        NOT NULL,

    cantidad              NUMBER(12,2)
        NOT NULL,

    CONSTRAINT PK_CP_DETALLE_TRASLADO
        PRIMARY KEY (id_detalle_traslado)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_DETALLE_TRASLADO_CANTIDAD
        CHECK (cantidad > 0)

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 52. CP_FACTURA_COMPRA
-- ============================================================

CREATE TABLE CP_FACTURA_COMPRA (
    id_factura_compra          NUMBER
        DEFAULT SEQ_CP_FACTURA_COMPRA.NEXTVAL
        NOT NULL,

    id_proveedor               NUMBER
        NOT NULL,

    id_negocio                 NUMBER
        NOT NULL,

    id_almacen_recepcion       NUMBER
        NOT NULL,

    id_usuario                 NUMBER
        NOT NULL,

    id_estado_factura_compra   NUMBER
        NOT NULL,

    numero_factura             VARCHAR2(50)
        NOT NULL,

    fecha_emision              DATE
        NOT NULL,

    fecha_recepcion            DATE,

    subtotal                   NUMBER(14,2)
        NOT NULL,

    descuento_total            NUMBER(14,2)
        NOT NULL,

    impuesto_total             NUMBER(14,2)
        NOT NULL,

    total                      NUMBER(14,2)
        NOT NULL,

    CONSTRAINT PK_CP_FACTURA_COMPRA
        PRIMARY KEY (id_factura_compra)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_FACTURA_COMPRA_NUMERO_FACTURA
        UNIQUE (numero_factura)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_FACTURA_COMPRA_SUBTOTAL
        CHECK (subtotal >= 0),

    CONSTRAINT CK_CP_FACTURA_COMPRA_DESCUENTO_TOTAL
        CHECK (descuento_total >= 0),

    CONSTRAINT CK_CP_FACTURA_COMPRA_IMPUESTO_TOTAL
        CHECK (impuesto_total >= 0),

    CONSTRAINT CK_CP_FACTURA_COMPRA_TOTAL
        CHECK (total >= 0)

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 53. CP_ESTADO_FACTURA_COMPRA
-- ============================================================

CREATE TABLE CP_ESTADO_FACTURA_COMPRA (
    id_estado_factura_compra   NUMBER
        DEFAULT SEQ_CP_ESTADO_FACTURA_COMPRA.NEXTVAL
        NOT NULL,

    nombre_estado_factura      VARCHAR2(30)
        NOT NULL,

    descripcion                VARCHAR2(150),

    CONSTRAINT PK_CP_ESTADO_FACTURA_COMPRA
        PRIMARY KEY (id_estado_factura_compra)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_ESTADO_FACTURA_COMPRA_NOMBRE_ESTADO_FACTURA
        UNIQUE (nombre_estado_factura)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 54. CP_DETALLE_COMPRA
-- ============================================================

CREATE TABLE CP_DETALLE_COMPRA (
    id_detalle_compra       NUMBER
        DEFAULT SEQ_CP_DETALLE_COMPRA.NEXTVAL
        NOT NULL,

    id_factura_compra       NUMBER
        NOT NULL,

    id_producto_proveedor   NUMBER
        NOT NULL,

    cantidad                NUMBER(12,2)
        NOT NULL,

    precio_costo_unitario   NUMBER(14,2)
        NOT NULL,

    monto_descuento         NUMBER(14,2)
        NOT NULL,

    porcentaje_impuesto     NUMBER(5,2)
        NOT NULL,

    monto_impuesto          NUMBER(14,2)
        NOT NULL,

    subtotal_linea          NUMBER(14,2)
        NOT NULL,

    total_linea             NUMBER(14,2)
        NOT NULL,

    CONSTRAINT PK_CP_DETALLE_COMPRA
        PRIMARY KEY (id_detalle_compra)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_DETALLE_COMPRA_CANTIDAD
        CHECK (cantidad > 0),

    CONSTRAINT CK_CP_DETALLE_COMPRA_PRECIO_COSTO
        CHECK (precio_costo_unitario >= 0),

    CONSTRAINT CK_CP_DETALLE_COMPRA_MONTO_DESCUENTO
        CHECK (monto_descuento >= 0),

    CONSTRAINT CK_CP_DETALLE_COMPRA_PORCENTAJE_IMPUESTO
        CHECK (porcentaje_impuesto BETWEEN 0 AND 100),

    CONSTRAINT CK_CP_DETALLE_COMPRA_MONTO_IMPUESTO
        CHECK (monto_impuesto >= 0),

    CONSTRAINT CK_CP_DETALLE_COMPRA_SUBTOTAL
        CHECK (subtotal_linea >= 0),

    CONSTRAINT CK_CP_DETALLE_COMPRA_TOTAL
        CHECK (total_linea >= 0)

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 55. CP_CUENTA_PAGAR
-- ============================================================

CREATE TABLE CP_CUENTA_PAGAR (
    id_cuenta_pagar          NUMBER
        DEFAULT SEQ_CP_CUENTA_PAGAR.NEXTVAL
        NOT NULL,

    id_factura_compra        NUMBER
        NOT NULL,

    id_estado_cuenta_pagar   NUMBER
        NOT NULL,

    fecha_creacion           DATE
        DEFAULT SYSDATE
        NOT NULL,

    fecha_vencimiento        DATE
        NOT NULL,

    observacion              VARCHAR2(250),

    CONSTRAINT PK_CP_CUENTA_PAGAR
        PRIMARY KEY (id_cuenta_pagar)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_CUENTA_PAGAR_VENCIMIENTO
        CHECK (fecha_vencimiento >= fecha_creacion)

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 56. CP_ESTADO_CUENTA_PAGAR
-- ============================================================

CREATE TABLE CP_ESTADO_CUENTA_PAGAR (
    id_estado_cuenta_pagar       NUMBER
        DEFAULT SEQ_CP_ESTADO_CUENTA_PAGAR.NEXTVAL
        NOT NULL,

    nombre_estado_cuenta_pagar   VARCHAR2(30)
        NOT NULL,

    descripcion                  VARCHAR2(150),

    CONSTRAINT PK_CP_ESTADO_CUENTA_PAGAR
        PRIMARY KEY (id_estado_cuenta_pagar)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_ESTADO_CUENTA_PAGAR_NOMBRE_ESTADO_CUENTA_PAGAR
        UNIQUE (nombre_estado_cuenta_pagar)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 57. CP_ABONO_CUENTA_PAGAR
-- ============================================================

CREATE TABLE CP_ABONO_CUENTA_PAGAR (
    id_abono_cuenta_pagar   NUMBER
        DEFAULT SEQ_CP_ABONO_CUENTA_PAGAR.NEXTVAL
        NOT NULL,

    id_cuenta_pagar         NUMBER
        NOT NULL,

    id_tipo_pago            NUMBER
        NOT NULL,

    id_usuario              NUMBER
        NOT NULL,

    monto_abono             NUMBER(14,2)
        NOT NULL,

    fecha_abono             TIMESTAMP
        NOT NULL,

    numero_referencia       VARCHAR2(100),

    observacion             VARCHAR2(100),

    CONSTRAINT PK_CP_ABONO_CUENTA_PAGAR
        PRIMARY KEY (id_abono_cuenta_pagar)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_ABONO_CUENTA_PAGAR_MONTO
        CHECK (monto_abono > 0)

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 58. CP_SERVICIO
-- ============================================================

CREATE TABLE CP_SERVICIO (
    id_servicio       NUMBER
        DEFAULT SEQ_CP_SERVICIO.NEXTVAL
        NOT NULL,

    id_negocio        NUMBER
        NOT NULL,

    id_impuesto       NUMBER
        NOT NULL,

    id_estado         NUMBER
        NOT NULL,

    codigo_servicio   VARCHAR2(30)
        NOT NULL,

    nombre_servicio   VARCHAR2(100)
        NOT NULL,

    descripcion       VARCHAR2(150),

    precio_servicio   NUMBER(14,2)
        NOT NULL,

    CONSTRAINT PK_CP_SERVICIO
        PRIMARY KEY (id_servicio)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_SERVICIO_CODIGO_SERVICIO
        UNIQUE (codigo_servicio)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_SERVICIO_PRECIO_SERVICIO
        CHECK (precio_servicio >= 0)

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 59. CP_FACTURA_VENTA
-- ============================================================

CREATE TABLE CP_FACTURA_VENTA (
    id_factura_venta          NUMBER
        DEFAULT SEQ_CP_FACTURA_VENTA.NEXTVAL
        NOT NULL,

    id_cliente                NUMBER
        NOT NULL,

    id_sucursal               NUMBER
        NOT NULL,

    id_usuario                NUMBER
        NOT NULL,

    id_estado_factura_venta   NUMBER
        NOT NULL,

    numero_factura            VARCHAR2(50)
        NOT NULL,

    fecha_emision             DATE
        NOT NULL,

    subtotal                  NUMBER(14,2)
        NOT NULL,

    descuento_total           NUMBER(14,2)
        NOT NULL,

    impuesto_total            NUMBER(14,2)
        NOT NULL,

    total                     NUMBER(14,2)
        NOT NULL,

    CONSTRAINT PK_CP_FACTURA_VENTA
        PRIMARY KEY (id_factura_venta)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_FACTURA_VENTA_NUMERO_FACTURA
        UNIQUE (numero_factura)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_FACTURA_VENTA_SUBTOTAL
        CHECK (subtotal >= 0),

    CONSTRAINT CK_CP_FACTURA_VENTA_DESCUENTO_TOTAL
        CHECK (descuento_total >= 0),

    CONSTRAINT CK_CP_FACTURA_VENTA_IMPUESTO_TOTAL
        CHECK (impuesto_total >= 0),

    CONSTRAINT CK_CP_FACTURA_VENTA_TOTAL
        CHECK (total >= 0)

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 60. CP_ESTADO_FACTURA_VENTA
-- ============================================================

CREATE TABLE CP_ESTADO_FACTURA_VENTA (
    id_estado_factura_venta   NUMBER
        DEFAULT SEQ_CP_ESTADO_FACTURA_VENTA.NEXTVAL
        NOT NULL,

    nombre_estado_factura     VARCHAR2(30)
        NOT NULL,

    descripcion               VARCHAR2(150),

    CONSTRAINT PK_CP_ESTADO_FACTURA_VENTA
        PRIMARY KEY (id_estado_factura_venta)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_ESTADO_FACTURA_VENTA_NOMBRE_ESTADO_FACTURA
        UNIQUE (nombre_estado_factura)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 61. CP_DETALLE_VENTA_PRODUCTO
-- ============================================================

CREATE TABLE CP_DETALLE_VENTA_PRODUCTO (
    id_detalle_venta_producto   NUMBER
        DEFAULT SEQ_CP_DETALLE_VENTA_PRODUCTO.NEXTVAL
        NOT NULL,

    id_factura_venta            NUMBER
        NOT NULL,

    id_producto                 NUMBER
        NOT NULL,

    cantidad                    NUMBER(12,2)
        NOT NULL,

    precio_unitario             NUMBER(14,2)
        NOT NULL,

    porcentaje_descuento        NUMBER(5,2)
        NOT NULL,

    monto_descuento             NUMBER(14,2)
        NOT NULL,

    porcentaje_impuesto         NUMBER(5,2)
        NOT NULL,

    monto_impuesto              NUMBER(14,2)
        NOT NULL,

    subtotal                    NUMBER(14,2)
        NOT NULL,

    total                       NUMBER(14,2)
        NOT NULL,

    CONSTRAINT PK_CP_DETALLE_VENTA_PRODUCTO
        PRIMARY KEY (id_detalle_venta_producto)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_DETALLE_VENTA_PRODUCTO_CANTIDAD
        CHECK (cantidad > 0),

    CONSTRAINT CK_CP_DETALLE_VENTA_PRODUCTO_PRECIO
        CHECK (precio_unitario >= 0),

    CONSTRAINT CK_CP_DETALLE_VENTA_PRODUCTO_DESCUENTO
        CHECK (porcentaje_descuento BETWEEN 0 AND 100),

    CONSTRAINT CK_CP_DETALLE_VENTA_PRODUCTO_MONTO_DESC
        CHECK (monto_descuento >= 0),

    CONSTRAINT CK_CP_DETALLE_VENTA_PRODUCTO_IMPUESTO
        CHECK (porcentaje_impuesto BETWEEN 0 AND 100),

    CONSTRAINT CK_CP_DETALLE_VENTA_PRODUCTO_MONTO_IMP
        CHECK (monto_impuesto >= 0),

    CONSTRAINT CK_CP_DETALLE_VENTA_PRODUCTO_SUBTOTAL
        CHECK (subtotal >= 0),

    CONSTRAINT CK_CP_DETALLE_VENTA_PRODUCTO_TOTAL
        CHECK (total >= 0)

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 62. CP_DETALLE_VENTA_SERVICIO
-- ============================================================

CREATE TABLE CP_DETALLE_VENTA_SERVICIO (
    id_detalle_venta_servicio   NUMBER
        DEFAULT SEQ_CP_DETALLE_VENTA_SERVICIO.NEXTVAL
        NOT NULL,

    id_factura_venta            NUMBER
        NOT NULL,

    id_servicio                 NUMBER
        NOT NULL,

    cantidad                    NUMBER(12,2)
        NOT NULL,

    precio_unitario             NUMBER(14,2)
        NOT NULL,

    porcentaje_descuento        NUMBER(5,2)
        NOT NULL,

    monto_descuento             NUMBER(14,2)
        NOT NULL,

    porcentaje_impuesto         NUMBER(5,2)
        NOT NULL,

    monto_impuesto              NUMBER(14,2)
        NOT NULL,

    subtotal                    NUMBER(14,2)
        NOT NULL,

    total                       NUMBER(14,2)
        NOT NULL,

    CONSTRAINT PK_CP_DETALLE_VENTA_SERVICIO
        PRIMARY KEY (id_detalle_venta_servicio)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_DETALLE_VENTA_SERVICIO_CANTIDAD
        CHECK (cantidad > 0),

    CONSTRAINT CK_CP_DETALLE_VENTA_SERVICIO_PRECIO
        CHECK (precio_unitario >= 0),

    CONSTRAINT CK_CP_DETALLE_VENTA_SERVICIO_DESCUENTO
        CHECK (porcentaje_descuento BETWEEN 0 AND 100),

    CONSTRAINT CK_CP_DETALLE_VENTA_SERVICIO_MONTO_DESC
        CHECK (monto_descuento >= 0),

    CONSTRAINT CK_CP_DETALLE_VENTA_SERVICIO_IMPUESTO
        CHECK (porcentaje_impuesto BETWEEN 0 AND 100),

    CONSTRAINT CK_CP_DETALLE_VENTA_SERVICIO_MONTO_IMP
        CHECK (monto_impuesto >= 0),

    CONSTRAINT CK_CP_DETALLE_VENTA_SERVICIO_SUBTOTAL
        CHECK (subtotal >= 0),

    CONSTRAINT CK_CP_DETALLE_VENTA_SERVICIO_TOTAL
        CHECK (total >= 0)

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 63. CP_DETALLE_VENTA_LOTE
-- ============================================================

CREATE TABLE CP_DETALLE_VENTA_LOTE (
    id_detalle_venta_lote       NUMBER
        DEFAULT SEQ_CP_DETALLE_VENTA_LOTE.NEXTVAL
        NOT NULL,

    id_detalle_venta_producto   NUMBER
        NOT NULL,

    id_lote_producto            NUMBER
        NOT NULL,

    cantidad                    NUMBER(12,2)
        NOT NULL,

    CONSTRAINT PK_CP_DETALLE_VENTA_LOTE
        PRIMARY KEY (id_detalle_venta_lote)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_DETALLE_VENTA_LOTE_CANTIDAD
        CHECK (cantidad > 0)

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 64. CP_TIPO_PAGO
-- ============================================================

CREATE TABLE CP_TIPO_PAGO (
    id_tipo_pago       NUMBER
        DEFAULT SEQ_CP_TIPO_PAGO.NEXTVAL
        NOT NULL,

    id_estado          NUMBER
        NOT NULL,

    nombre_tipo_pago   VARCHAR2(50)
        NOT NULL,

    descripcion        VARCHAR2(150),

    CONSTRAINT PK_CP_TIPO_PAGO
        PRIMARY KEY (id_tipo_pago)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_TIPO_PAGO_NOMBRE_TIPO_PAGO
        UNIQUE (nombre_tipo_pago)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 65. CP_PAGO_FACTURA_VENTA
-- ============================================================

CREATE TABLE CP_PAGO_FACTURA_VENTA (
    id_pago_factura_venta   NUMBER
        DEFAULT SEQ_CP_PAGO_FACTURA_VENTA.NEXTVAL
        NOT NULL,

    id_factura_venta        NUMBER
        NOT NULL,

    id_tipo_pago            NUMBER
        NOT NULL,

    id_usuario              NUMBER
        NOT NULL,

    fecha_pago              TIMESTAMP
        DEFAULT SYSTIMESTAMP
        NOT NULL,

    monto_pago              NUMBER(14,2)
        NOT NULL,

    numero_referencia       VARCHAR2(100),

    observacion             VARCHAR2(250),

    CONSTRAINT PK_CP_PAGO_FACTURA_VENTA
        PRIMARY KEY (id_pago_factura_venta)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_PAGO_FACTURA_VENTA_MONTO_PAGO
        CHECK (monto_pago > 0)

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 66. CP_ESTADO_CREDITO
-- ============================================================

CREATE TABLE CP_ESTADO_CREDITO (
    id_estado_credito       NUMBER
        DEFAULT SEQ_CP_ESTADO_CREDITO.NEXTVAL
        NOT NULL,

    nombre_estado_credito   VARCHAR2(30)
        NOT NULL,

    descripcion             VARCHAR2(150),

    CONSTRAINT PK_CP_ESTADO_CREDITO
        PRIMARY KEY (id_estado_credito)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 67. CP_CREDITO_CLIENTE
-- ============================================================

CREATE TABLE CP_CREDITO_CLIENTE (
    id_credito_cliente    NUMBER
        DEFAULT SEQ_CP_CREDITO_CLIENTE.NEXTVAL
        NOT NULL,

    id_cliente            NUMBER
        NOT NULL,

    id_negocio            NUMBER
        NOT NULL,

    id_estado_credito     NUMBER
        NOT NULL,

    limite_credito        NUMBER(14,2)
        NOT NULL,

    fecha_autorizacion    DATE
        NOT NULL,

    fecha_vencimiento     DATE,

    CONSTRAINT PK_CP_CREDITO_CLIENTE
        PRIMARY KEY (id_credito_cliente)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_CREDITO_CLIENTE_LIMITE_CREDITO
        CHECK (limite_credito >= 0),

    CONSTRAINT CK_CP_CREDITO_CLIENTE_VIGENCIA
        CHECK (
            fecha_vencimiento IS NULL
            OR fecha_vencimiento >= fecha_autorizacion
        )

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 68. CP_CUENTA_COBRAR
-- ============================================================

CREATE TABLE CP_CUENTA_COBRAR (
    id_cuenta_cobrar          NUMBER
        DEFAULT SEQ_CP_CUENTA_COBRAR.NEXTVAL
        NOT NULL,

    id_factura_venta          NUMBER
        NOT NULL,

    id_credito_cliente        NUMBER
        NOT NULL,

    id_estado_cuenta_cobrar   NUMBER
        NOT NULL,

    fecha_creacion            DATE
        DEFAULT SYSDATE
        NOT NULL,

    fecha_vencimiento         DATE
        NOT NULL,

    observacion               VARCHAR2(250),

    CONSTRAINT PK_CP_CUENTA_COBRAR
        PRIMARY KEY (id_cuenta_cobrar)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_CUENTA_COBRAR_VENCIMIENTO
        CHECK (fecha_vencimiento >= fecha_creacion)

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 69. CP_ESTADO_CUENTA_COBRAR
-- ============================================================

CREATE TABLE CP_ESTADO_CUENTA_COBRAR (
    id_estado_cuenta_cobrar       NUMBER
        DEFAULT SEQ_CP_ESTADO_CUENTA_COBRAR.NEXTVAL
        NOT NULL,

    nombre_estado_cuenta_cobrar   VARCHAR2(30)
        NOT NULL,

    descripcion                   VARCHAR2(150),

    CONSTRAINT PK_CP_ESTADO_CUENTA_COBRAR
        PRIMARY KEY (id_estado_cuenta_cobrar)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_ESTADO_CUENTA_COBRAR_NOMBRE_ESTADO
        UNIQUE (nombre_estado_cuenta_cobrar)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 70. CP_ABONO_CUENTA_COBRAR
-- ============================================================

CREATE TABLE CP_ABONO_CUENTA_COBRAR (
    id_abono_cuenta_cobrar   NUMBER
        DEFAULT SEQ_CP_ABONO_CUENTA_COBRAR.NEXTVAL
        NOT NULL,

    id_cuenta_cobrar         NUMBER
        NOT NULL,

    id_tipo_pago             NUMBER
        NOT NULL,

    id_usuario               NUMBER
        NOT NULL,

    monto_abono              NUMBER(14,2)
        NOT NULL,

    fecha_abono              TIMESTAMP
        NOT NULL,

    numero_referencia        VARCHAR2(100),

    observacion              VARCHAR2(100),

    CONSTRAINT PK_CP_ABONO_CUENTA_COBRAR
        PRIMARY KEY (id_abono_cuenta_cobrar)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_ABONO_CUENTA_COBRAR_MONTO_ABONO
        CHECK (monto_abono > 0)

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 71. CP_ESTADO_PROMOCION
-- ============================================================

CREATE TABLE CP_ESTADO_PROMOCION (
    id_estado_promocion       NUMBER
        DEFAULT SEQ_CP_ESTADO_PROMOCION.NEXTVAL
        NOT NULL,

    nombre_estado_promocion   VARCHAR2(30)
        NOT NULL,

    descripcion               VARCHAR2(150),

    CONSTRAINT PK_CP_ESTADO_PROMOCION
        PRIMARY KEY (id_estado_promocion)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_ESTADO_PROMOCION_NOMBRE_ESTADO_PROMOCION
        UNIQUE (nombre_estado_promocion)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 72. CP_PROMOCION
-- ============================================================

CREATE TABLE CP_PROMOCION (
    id_promocion          NUMBER
        DEFAULT SEQ_CP_PROMOCION.NEXTVAL
        NOT NULL,

    id_estado_promocion   NUMBER
        NOT NULL,

    id_negocio            NUMBER
        NOT NULL,

    nombre_promocion      VARCHAR2(100)
        NOT NULL,

    descripcion           VARCHAR2(250),

    fecha_inicio          DATE
        NOT NULL,

    fecha_final           DATE,

    CONSTRAINT PK_CP_PROMOCION
        PRIMARY KEY (id_promocion)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_PROMOCION_NOMBRE_PROMOCION
        UNIQUE (nombre_promocion)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_PROMOCION_VIGENCIA
        CHECK (
            fecha_final IS NULL
            OR fecha_final >= fecha_inicio
        )

) TABLESPACE CP_POS_DATOS;

-- ============================================================
-- 73. CP_ACCION_PROMOCION
-- ============================================================

CREATE TABLE CP_ACCION_PROMOCION (
    id_accion_promocion       NUMBER
        DEFAULT SEQ_CP_ACCION_PROMOCION.NEXTVAL
        NOT NULL,

    nombre_accion_promocion   VARCHAR2(100)
        NOT NULL,

    descripcion               VARCHAR2(150),

    CONSTRAINT PK_CP_ACCION_PROMOCION
        PRIMARY KEY (id_accion_promocion)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_ACCION_PROMOCION_NOMBRE_ACCION_PROMOCION
        UNIQUE (nombre_accion_promocion)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 74. CP_REGLA_PROMOCION
-- ============================================================

CREATE TABLE CP_REGLA_PROMOCION (
    id_regla_promocion    NUMBER
        DEFAULT SEQ_CP_REGLA_PROMOCION.NEXTVAL
        NOT NULL,

    id_promocion          NUMBER
        NOT NULL,

    id_accion_promocion   NUMBER
        NOT NULL,

    cantidad_acciones     NUMBER(12)
        NOT NULL,

    descripcion           VARCHAR2(150),

    CONSTRAINT PK_CP_REGLA_PROMOCION
        PRIMARY KEY (id_regla_promocion)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_REGLA_PROMOCION_CANTIDAD_ACCIONES
        CHECK (cantidad_acciones > 0)

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 75. CP_PROMOCION_PATROCINADOR
-- ============================================================

CREATE TABLE CP_PROMOCION_PATROCINADOR (
    id_promocion_patrocinador   NUMBER
        DEFAULT SEQ_CP_PROMOCION_PATROCINADOR.NEXTVAL
        NOT NULL,

    id_regla_promocion          NUMBER
        NOT NULL,

    id_producto                 NUMBER
        NOT NULL,

    cantidad_requerida          NUMBER(12,2)
        NOT NULL,

    CONSTRAINT PK_CP_PROMOCION_PATROCINADOR
        PRIMARY KEY (id_promocion_patrocinador)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_PROMOCION_PATROCINADOR_CANTIDAD
        CHECK (cantidad_requerida > 0)

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 76. CP_PROMOCION_PREMIO
-- ============================================================

CREATE TABLE CP_PROMOCION_PREMIO (
    id_promocion_premio   NUMBER
        DEFAULT SEQ_CP_PROMOCION_PREMIO.NEXTVAL
        NOT NULL,

    id_regla_promocion    NUMBER
        NOT NULL,

    id_producto_premio    NUMBER
        NOT NULL,

    cantidad_premio       NUMBER(12,2)
        NOT NULL,

    CONSTRAINT PK_CP_PROMOCION_PREMIO
        PRIMARY KEY (id_promocion_premio)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_PROMOCION_PREMIO_CANTIDAD
        CHECK (cantidad_premio > 0)

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 77. CP_ESTADO_DESCUENTO
-- ============================================================

CREATE TABLE CP_ESTADO_DESCUENTO (
    id_estado_descuento       NUMBER
        DEFAULT SEQ_CP_ESTADO_DESCUENTO.NEXTVAL
        NOT NULL,

    nombre_estado_descuento   VARCHAR2(30)
        NOT NULL,

    descripcion               VARCHAR2(250),

    CONSTRAINT PK_CP_ESTADO_DESCUENTO
        PRIMARY KEY (id_estado_descuento)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_ESTADO_DESCUENTO_NOMBRE_ESTADO_DESCUENTO
        UNIQUE (nombre_estado_descuento)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 78. CP_DESCUENTO
-- ============================================================

CREATE TABLE CP_DESCUENTO (
    id_descuento           NUMBER
        DEFAULT SEQ_CP_DESCUENTO.NEXTVAL
        NOT NULL,

    id_negocio             NUMBER
        NOT NULL,

    id_estado_descuento    NUMBER
        NOT NULL,

    nombre_descuento       VARCHAR2(100)
        NOT NULL,

    porcentaje_descuento   NUMBER(5,2)
        NOT NULL,

    fecha_inicio           DATE
        NOT NULL,

    fecha_final            DATE,

    descripcion            VARCHAR2(250),

    CONSTRAINT PK_CP_DESCUENTO
        PRIMARY KEY (id_descuento)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_DESCUENTO_PORCENTAJE
        CHECK (porcentaje_descuento BETWEEN 0 AND 100),

    CONSTRAINT CK_CP_DESCUENTO_VIGENCIA
        CHECK (
            fecha_final IS NULL
            OR fecha_final >= fecha_inicio
        )

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 79. CP_DESCUENTO_FAMILIA
-- ============================================================

CREATE TABLE CP_DESCUENTO_FAMILIA (
    id_descuento_familia   NUMBER
        DEFAULT SEQ_CP_DESCUENTO_FAMILIA.NEXTVAL
        NOT NULL,

    id_descuento           NUMBER
        NOT NULL,

    id_familia_producto    NUMBER
        NOT NULL,

    CONSTRAINT PK_CP_DESCUENTO_FAMILIA
        PRIMARY KEY (id_descuento_familia)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 80. CP_DESCUENTO_PROVEEDOR
-- ============================================================

CREATE TABLE CP_DESCUENTO_PROVEEDOR (
    id_descuento_proveedor   NUMBER
        DEFAULT SEQ_CP_DESCUENTO_PROVEEDOR.NEXTVAL
        NOT NULL,

    id_descuento             NUMBER
        NOT NULL,

    id_proveedor             NUMBER
        NOT NULL,

    CONSTRAINT PK_CP_DESCUENTO_PROVEEDOR
        PRIMARY KEY (id_descuento_proveedor)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 81. CP_DESCUENTO_FECHA_INGRESO
-- ============================================================

CREATE TABLE CP_DESCUENTO_FECHA_INGRESO (
    id_descuento_fecha_ingreso   NUMBER
        DEFAULT SEQ_CP_DESCUENTO_FECHA_INGRESO.NEXTVAL
        NOT NULL,

    id_descuento                 NUMBER
        NOT NULL,

    fecha_ingreso_desde          DATE
        NOT NULL,

    fecha_ingreso_hasta          DATE
        NOT NULL,

    CONSTRAINT PK_CP_DESCUENTO_FECHA_INGRESO
        PRIMARY KEY (id_descuento_fecha_ingreso)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_DESCUENTO_FECHA_INGRESO_RANGO
        CHECK (fecha_ingreso_hasta >= fecha_ingreso_desde)

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 82. CP_DESCUENTO_VENCIMIENTO
-- ============================================================

CREATE TABLE CP_DESCUENTO_VENCIMIENTO (
    id_descuento_vencimiento   NUMBER
        DEFAULT SEQ_CP_DESCUENTO_VENCIMIENTO.NEXTVAL
        NOT NULL,

    id_descuento               NUMBER
        NOT NULL,

    dias_antes_vencimiento     NUMBER
        NOT NULL,

    CONSTRAINT PK_CP_DESCUENTO_VENCIMIENTO
        PRIMARY KEY (id_descuento_vencimiento)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_DESCUENTO_VENCIMIENTO_DIAS
        CHECK (dias_antes_vencimiento >= 0)

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 83. CP_DESCUENTO_APLICADO
-- ============================================================

CREATE TABLE CP_DESCUENTO_APLICADO (
    id_descuento_aplicado       NUMBER
        DEFAULT SEQ_CP_DESCUENTO_APLICADO.NEXTVAL
        NOT NULL,

    id_detalle_venta_producto   NUMBER
        NOT NULL,

    id_descuento                NUMBER
        NOT NULL,

    monto_aplicado              NUMBER(14,2)
        NOT NULL,

    CONSTRAINT PK_CP_DESCUENTO_APLICADO
        PRIMARY KEY (id_descuento_aplicado)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_DESCUENTO_APLICADO_MONTO
        CHECK (monto_aplicado >= 0)

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 84. CP_ESTADO_DEVOLUCION
-- ============================================================

CREATE TABLE CP_ESTADO_DEVOLUCION (
    id_estado_devolucion       NUMBER
        DEFAULT SEQ_CP_ESTADO_DEVOLUCION.NEXTVAL
        NOT NULL,

    nombre_estado_devolucion   VARCHAR2(50)
        NOT NULL,

    descripcion                VARCHAR2(250),

    CONSTRAINT PK_CP_ESTADO_DEVOLUCION
        PRIMARY KEY (id_estado_devolucion)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_ESTADO_DEVOLUCION_NOMBRE_ESTADO_DEVOLUCION
        UNIQUE (nombre_estado_devolucion)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 85. CP_MOTIVO_DEVOLUCION
-- ============================================================

CREATE TABLE CP_MOTIVO_DEVOLUCION (
    id_motivo_devolucion       NUMBER
        DEFAULT SEQ_CP_MOTIVO_DEVOLUCION.NEXTVAL
        NOT NULL,

    nombre_motivo_devolucion   VARCHAR2(100)
        NOT NULL,

    descripcion                VARCHAR2(250),

    CONSTRAINT PK_CP_MOTIVO_DEVOLUCION
        PRIMARY KEY (id_motivo_devolucion)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_MOTIVO_DEVOLUCION_NOMBRE_MOTIVO_DEVOLUCION
        UNIQUE (nombre_motivo_devolucion)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 86. CP_DEVOLUCION_VENTA
-- ============================================================

CREATE TABLE CP_DEVOLUCION_VENTA (
    id_devolucion_venta      NUMBER
        DEFAULT SEQ_CP_DEVOLUCION_VENTA.NEXTVAL
        NOT NULL,

    id_factura_venta         NUMBER
        NOT NULL,

    id_estado_devolucion     NUMBER
        NOT NULL,

    id_usuario               NUMBER
        NOT NULL,

    fecha_devolucion         DATE
        NOT NULL,

    monto_total              NUMBER(14,2)
        NOT NULL,

    observacion              VARCHAR2(150),

    CONSTRAINT PK_CP_DEVOLUCION_VENTA
        PRIMARY KEY (id_devolucion_venta)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_DEVOLUCION_VENTA_MONTO_TOTAL
        CHECK (monto_total >= 0)

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 87. CP_DETALLE_DEVOLUCION_VENTA
-- ============================================================

CREATE TABLE CP_DETALLE_DEVOLUCION_VENTA (
    id_detalle_devolucion_venta   NUMBER
        DEFAULT SEQ_CP_DETALLE_DEVOLUCION_VENTA.NEXTVAL
        NOT NULL,

    id_devolucion_venta           NUMBER
        NOT NULL,

    id_detalle_venta_lote         NUMBER
        NOT NULL,

    id_motivo_devolucion          NUMBER
        NOT NULL,

    cantidad_devuelta             NUMBER(12,2)
        NOT NULL,

    monto_devolucion              NUMBER(14,2)
        NOT NULL,

    CONSTRAINT PK_CP_DETALLE_DEVOLUCION_VENTA
        PRIMARY KEY (id_detalle_devolucion_venta)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_DETALLE_DEVOLUCION_VENTA_CANTIDAD
        CHECK (cantidad_devuelta > 0),

    CONSTRAINT CK_CP_DETALLE_DEVOLUCION_VENTA_MONTO
        CHECK (monto_devolucion >= 0)

) TABLESPACE CP_POS_DATOS;

-- ============================================================
-- 88. CP_NOTA_CREDITO_CLIENTE
-- ============================================================

CREATE TABLE CP_NOTA_CREDITO_CLIENTE (
    id_nota_credito_cliente   NUMBER
        DEFAULT SEQ_CP_NOTA_CREDITO_CLIENTE.NEXTVAL
        NOT NULL,

    id_devolucion_venta       NUMBER
        NOT NULL,

    numero_nota_credito       VARCHAR2(50)
        NOT NULL,

    fecha_emision             DATE
        NOT NULL,

    monto_nota_credito        NUMBER(14,2)
        NOT NULL,

    CONSTRAINT PK_CP_NOTA_CREDITO_CLIENTE
        PRIMARY KEY (id_nota_credito_cliente)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_NOTA_CREDITO_CLIENTE_NUMERO_NOTA_CREDITO
        UNIQUE (numero_nota_credito)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_NOTA_CREDITO_CLIENTE_MONTO_NOTA_CREDITO
        CHECK (monto_nota_credito >= 0)

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 89. CP_DEVOLUCION_COMPRA
-- ============================================================

CREATE TABLE CP_DEVOLUCION_COMPRA (
    id_devolucion_compra    NUMBER
        DEFAULT SEQ_CP_DEVOLUCION_COMPRA.NEXTVAL
        NOT NULL,

    id_factura_compra       NUMBER
        NOT NULL,

    id_estado_devolucion    NUMBER
        NOT NULL,

    id_usuario              NUMBER
        NOT NULL,

    fecha_devolucion        DATE
        NOT NULL,

    observacion             VARCHAR2(150),

    CONSTRAINT PK_CP_DEVOLUCION_COMPRA
        PRIMARY KEY (id_devolucion_compra)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 90. CP_DETALLE_DEVOLUCION_COMPRA
-- ============================================================

CREATE TABLE CP_DETALLE_DEVOLUCION_COMPRA (
    id_detalle_devolucion_compra   NUMBER
        DEFAULT SEQ_CP_DETALLE_DEVOLUCION_COMPRA.NEXTVAL
        NOT NULL,

    id_devolucion_compra           NUMBER
        NOT NULL,

    id_lote_producto               NUMBER
        NOT NULL,

    id_motivo_devolucion           NUMBER
        NOT NULL,

    cantidad                       NUMBER(14,2)
        NOT NULL,

    monto_devolucion               NUMBER(14,2)
        NOT NULL,

    CONSTRAINT PK_CP_DETALLE_DEVOLUCION_COMPRA
        PRIMARY KEY (id_detalle_devolucion_compra)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_DETALLE_DEVOLUCION_COMPRA_CANTIDAD
        CHECK (cantidad > 0),

    CONSTRAINT CK_CP_DETALLE_DEVOLUCION_COMPRA_MONTO_DEVOLUCION
        CHECK (monto_devolucion >= 0)

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 91. CP_NOTA_CREDITO_PROVEEDOR
-- ============================================================

CREATE TABLE CP_NOTA_CREDITO_PROVEEDOR (
    id_nota_credito_proveedor   NUMBER
        DEFAULT SEQ_CP_NOTA_CREDITO_PROVEEDOR.NEXTVAL
        NOT NULL,

    id_devolucion_compra        NUMBER
        NOT NULL,

    numero_nota_credito         VARCHAR2(50)
        NOT NULL,

    fecha_emision               DATE
        NOT NULL,

    monto_nota_credito          NUMBER(14,2)
        NOT NULL,

    CONSTRAINT PK_CP_NOTA_CREDITO_PROVEEDOR
        PRIMARY KEY (id_nota_credito_proveedor)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT UK_CP_NOTA_CREDITO_PROVEEDOR_NUMERO_NOTA_CREDITO
        UNIQUE (numero_nota_credito)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_NOTA_CREDITO_PROVEEDOR_MONTO_NOTA_CREDITO
        CHECK (monto_nota_credito >= 0)

) TABLESPACE CP_POS_DATOS;


-- ============================================================
-- 92. CP_BITACORA_PRECIO
-- ============================================================

CREATE TABLE CP_BITACORA_PRECIO (
    id_bitacora_precio     NUMBER
        DEFAULT SEQ_CP_BITACORA_PRECIO.NEXTVAL
        NOT NULL,

    id_producto_negocio    NUMBER
        NOT NULL,

    id_usuario             NUMBER
        NOT NULL,

    id_tipo_operacion      NUMBER
        NOT NULL,

    precio_anterior        NUMBER(14,2)
        NOT NULL,

    precio_nuevo           NUMBER(14,2)
        NOT NULL,

    fecha_cambio           TIMESTAMP
        DEFAULT SYSTIMESTAMP
        NOT NULL,

    motivo_cambio          VARCHAR2(250),

    CONSTRAINT PK_CP_BITACORA_PRECIO
        PRIMARY KEY (id_bitacora_precio)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_BITACORA_PRECIO_PRECIO_ANTERIOR
        CHECK (precio_anterior >= 0),

    CONSTRAINT CK_CP_BITACORA_PRECIO_PRECIO_NUEVO
        CHECK (precio_nuevo >= 0)

) TABLESPACE CP_POS_AUDITORIA;


-- ============================================================
-- 93. CP_BITACORA_INVENTARIO
-- ============================================================

CREATE TABLE CP_BITACORA_INVENTARIO (
    id_bitacora_inventario   NUMBER
        DEFAULT SEQ_CP_BITACORA_INVENTARIO.NEXTVAL
        NOT NULL,

    id_almacen               NUMBER
        NOT NULL,

    id_lote_producto         NUMBER
        NOT NULL,

    id_usuario               NUMBER
        NOT NULL,

    id_tipo_operacion        NUMBER
        NOT NULL,

    cantidad_anterior        NUMBER(12,2)
        NOT NULL,

    cantidad_nueva           NUMBER(12,2)
        NOT NULL,

    fecha_operacion          TIMESTAMP
        DEFAULT SYSTIMESTAMP
        NOT NULL,

    tabla_referencia         VARCHAR2(150)
        NOT NULL,

    id_referencia            NUMBER
        NOT NULL,

    motivo                   VARCHAR2(250),

    CONSTRAINT PK_CP_BITACORA_INVENTARIO
        PRIMARY KEY (id_bitacora_inventario)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_BITACORA_INVENTARIO_CANTIDAD_ANTERIOR
        CHECK (cantidad_anterior >= 0),

    CONSTRAINT CK_CP_BITACORA_INVENTARIO_CANTIDAD_NUEVA
        CHECK (cantidad_nueva >= 0)

) TABLESPACE CP_POS_AUDITORIA;


-- ============================================================
-- 94. CP_BITACORA_TRASLADO
-- ============================================================

CREATE TABLE CP_BITACORA_TRASLADO (
    id_bitacora_traslado   NUMBER
        DEFAULT SEQ_CP_BITACORA_TRASLADO.NEXTVAL
        NOT NULL,

    id_traslado            NUMBER
        NOT NULL,

    id_usuario             NUMBER
        NOT NULL,

    id_tipo_operacion      NUMBER
        NOT NULL,

    id_estado_anterior     NUMBER
        NOT NULL,

    id_estado_nuevo        NUMBER
        NOT NULL,

    fecha_cambio           TIMESTAMP
        DEFAULT SYSTIMESTAMP
        NOT NULL,

    observacion            VARCHAR2(250),

    CONSTRAINT PK_CP_BITACORA_TRASLADO
        PRIMARY KEY (id_bitacora_traslado)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_AUDITORIA;


-- ============================================================
-- 95. CP_BITACORA_VENTA
-- ============================================================

CREATE TABLE CP_BITACORA_VENTA (
    id_bitacora_venta     NUMBER
        DEFAULT SEQ_CP_BITACORA_VENTA.NEXTVAL
        NOT NULL,

    id_factura_venta      NUMBER
        NOT NULL,

    id_usuario            NUMBER
        NOT NULL,

    id_tipo_operacion     NUMBER
        NOT NULL,

    id_estado_anterior    NUMBER
        NOT NULL,

    id_estado_nuevo       NUMBER
        NOT NULL,

    total_anterior        NUMBER(12,2)
        NOT NULL,

    total_nuevo           NUMBER(12,2)
        NOT NULL,

    fecha_operacion       TIMESTAMP
        DEFAULT SYSTIMESTAMP
        NOT NULL,

    motivo                VARCHAR2(250),

    CONSTRAINT PK_CP_BITACORA_VENTA
        PRIMARY KEY (id_bitacora_venta)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_BITACORA_VENTA_TOTAL_ANTERIOR
        CHECK (total_anterior >= 0),

    CONSTRAINT CK_CP_BITACORA_VENTA_TOTAL_NUEVO
        CHECK (total_nuevo >= 0)

) TABLESPACE CP_POS_AUDITORIA;

-- ============================================================
-- 96. CP_BITACORA_CREDITO_CLIENTE
-- ============================================================

CREATE TABLE CP_BITACORA_CREDITO_CLIENTE (
    id_bitacora_credito_cliente   NUMBER
        DEFAULT SEQ_CP_BITACORA_CREDITO_CLIENTE.NEXTVAL
        NOT NULL,

    id_credito_cliente            NUMBER
        NOT NULL,

    id_usuario                    NUMBER
        NOT NULL,

    id_tipo_operacion             NUMBER
        NOT NULL,

    limite_anterior               NUMBER
        NOT NULL,

    limite_nuevo                  NUMBER
        NOT NULL,

    fecha_operacion               TIMESTAMP
        DEFAULT SYSTIMESTAMP
        NOT NULL,

    motivo                        VARCHAR2(250),

    CONSTRAINT PK_CP_BITACORA_CREDITO_CLIENTE
        PRIMARY KEY (id_bitacora_credito_cliente)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_BITACORA_CREDITO_CLIENTE_LIMITE_ANTERIOR
        CHECK (limite_anterior >= 0),

    CONSTRAINT CK_CP_BITACORA_CREDITO_CLIENTE_LIMITE_NUEVO
        CHECK (limite_nuevo >= 0)

) TABLESPACE CP_POS_AUDITORIA;


-- ============================================================
-- 97. CP_BITACORA_CREDITO_PROVEEDOR
-- ============================================================

CREATE TABLE CP_BITACORA_CREDITO_PROVEEDOR (
    id_bitacora_credito_proveedor   NUMBER
        DEFAULT SEQ_CP_BITACORA_CREDITO_PROVEEDOR.NEXTVAL
        NOT NULL,

    id_credito_proveedor            NUMBER
        NOT NULL,

    id_usuario                      NUMBER
        NOT NULL,

    id_tipo_operacion               NUMBER
        NOT NULL,

    limite_anterior                 NUMBER
        NOT NULL,

    limite_nuevo                    NUMBER
        NOT NULL,

    fecha_operacion                 TIMESTAMP
        DEFAULT SYSTIMESTAMP
        NOT NULL,

    motivo                          VARCHAR2(250),

    CONSTRAINT PK_CP_BITACORA_CREDITO_PROVEEDOR
        PRIMARY KEY (id_bitacora_credito_proveedor)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_BITACORA_CREDITO_PROVEEDOR_LIMITE_ANTERIOR
        CHECK (limite_anterior >= 0),

    CONSTRAINT CK_CP_BITACORA_CREDITO_PROVEEDOR_LIMITE_NUEVO
        CHECK (limite_nuevo >= 0)

) TABLESPACE CP_POS_AUDITORIA;


-- ============================================================
-- 98. CP_BITACORA_DEVOLUCION_VENTA
-- ============================================================

CREATE TABLE CP_BITACORA_DEVOLUCION_VENTA (
    id_bitacora_devolucion_venta   NUMBER
        DEFAULT SEQ_CP_BITACORA_DEVOLUCION_VENTA.NEXTVAL
        NOT NULL,

    id_devolucion_venta            NUMBER
        NOT NULL,

    id_usuario                     NUMBER
        NOT NULL,

    id_tipo_operacion              NUMBER
        NOT NULL,

    id_estado_anterior             NUMBER
        NOT NULL,

    id_estado_nuevo                NUMBER
        NOT NULL,

    fecha_operacion                TIMESTAMP
        DEFAULT SYSTIMESTAMP
        NOT NULL,

    motivo                         VARCHAR2(250),

    CONSTRAINT PK_CP_BITACORA_DEVOLUCION_VENTA
        PRIMARY KEY (id_bitacora_devolucion_venta)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_AUDITORIA;


-- ============================================================
-- 99. CP_BITACORA_DEVOLUCION_COMPRA
-- ============================================================

CREATE TABLE CP_BITACORA_DEVOLUCION_COMPRA (
    id_bitacora_devolucion_compra   NUMBER
        DEFAULT SEQ_CP_BITACORA_DEVOLUCION_COMPRA.NEXTVAL
        NOT NULL,

    id_devolucion_compra            NUMBER
        NOT NULL,

    id_usuario                      NUMBER
        NOT NULL,

    id_tipo_operacion               NUMBER
        NOT NULL,

    id_estado_anterior              NUMBER
        NOT NULL,

    id_estado_nuevo                 NUMBER
        NOT NULL,

    fecha_operacion                 TIMESTAMP
        DEFAULT SYSTIMESTAMP
        NOT NULL,

    motivo                          VARCHAR2(250),

    CONSTRAINT PK_CP_BITACORA_DEVOLUCION_COMPRA
        PRIMARY KEY (id_bitacora_devolucion_compra)
        USING INDEX TABLESPACE CP_POS_INDICES

) TABLESPACE CP_POS_AUDITORIA;


-- ============================================================
-- 100. CP_BITACORA_ACCESO
-- ============================================================

CREATE TABLE CP_BITACORA_ACCESO (
    id_bitacora_acceso       NUMBER
        DEFAULT SEQ_CP_BITACORA_ACCESO.NEXTVAL
        NOT NULL,

    id_usuario               NUMBER,

    nombre_usuario_intento   VARCHAR2(50)
        NOT NULL,

    fecha_hora               TIMESTAMP
        DEFAULT SYSTIMESTAMP
        NOT NULL,

    tipo_acceso              VARCHAR2(20)
        NOT NULL,

    resultado                VARCHAR2(20)
        NOT NULL,

    direccion_ip             VARCHAR2(45)
        NOT NULL,

    observacion              VARCHAR2(250),

    CONSTRAINT PK_CP_BITACORA_ACCESO
        PRIMARY KEY (id_bitacora_acceso)
        USING INDEX TABLESPACE CP_POS_INDICES,

    CONSTRAINT CK_CP_BITACORA_ACCESO_RESULTADO
        CHECK (resultado IN ('EXITOSO', 'FALLIDO')),

    CONSTRAINT CK_CP_BITACORA_ACCESO_TIPO
        CHECK (tipo_acceso IN ('INICIO_SESION', 'CIERRE_SESION'))

) TABLESPACE CP_POS_AUDITORIA;