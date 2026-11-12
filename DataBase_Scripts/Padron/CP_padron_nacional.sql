-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- BASE DE DATOS: Oracle 21c
-- SCRIPT: CP_padron_nacional.sql
-- DESCRIPCION: Integracion del Padron Nacional Electoral del TSE.
--              Adapta el modelo, carga el padron y lo enlaza con las
--              personas, y por ellas con los clientes.
--
--              1. Modelo: CP_PERSONA.id_padron, enlace opcional (FK)
--                 hacia CP_PADRON_NACIONAL. Es opcional porque el
--                 padron electoral solo trae costarricenses mayores de
--                 edad: un extranjero o un menor queda con NULL.
--              2. Parametros del archivo y de su codificacion.
--              3. Tabla externa CP_PADRON_EXTERNO: Oracle lee el TXT
--                 del TSE como si fuera una tabla.
--              4-5. Paquete PKG_CP_PADRON: carga con un solo MERGE
--                 (inserta las cedulas nuevas y actualiza solo las que
--                 cambiaron), enlaza a las personas y completa sus
--                 datos basicos.
--              6. Trigger TRG_CP_PERSONA_PADRON: al registrar una
--                 persona busca su cedula en el padron, guarda el
--                 enlace y completa nombre y apellidos si vienen vacios.
--              7. Vista VW_CP_CLIENTE_PADRON: cada cliente persona con
--                 sus datos del padron.
--              8. Codificacion de la tabla externa y enlace de las
--                 personas que ya existian.
--              9. Pruebas.
--              10. Job mensual de carga.
--              11. Recompilacion de lo que invalide el cambio de
--                  modelo.
--              12. Consultas para la defensa.
--
-- PARAMETROS (CP_PARAMETRO):
--   PADRON_ARCHIVO  (PADRON_COMPLETO.txt)  archivo dentro de DIR_PADRON
--   PADRON_CHARSET  (WE8MSWIN1252)         codificacion del archivo
--
-- EJECUTAR COMO: CP_POS en XEPDB1, despues del script 15 (usa
--                PKG_CP_ERROR y PKG_CP_PARAMETRO) y despues de crear el
--                directorio DIR_PADRON como SYS (README, seccion 6).
--                Se puede volver a ejecutar completo las veces que
--                haga falta. Al terminar, volver a correr el script 13
--                como SYS (da lectura de la vista nueva).
--
-- ERRORES PROPIOS (tramo -20360 a -20369):
--   -20360 el nombre del archivo no es valido
--   -20361 la persona no tiene nombre y su cedula no esta en el padron
--   -20362 hay otra carga del padron en curso
--   -20363 no se pudo leer el archivo en DIR_PADRON
--   -20364 la codificacion del parametro PADRON_CHARSET no es valida
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET SQLBLANKLINES ON

-- ============================================================
-- 1. MODELO: ENLACE DE CP_PERSONA CON EL PADRON
-- ============================================================

DECLARE
    PROCEDURE run_ddl(p_sql IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE p_sql;
        DBMS_OUTPUT.PUT_LINE('OK      : ' || SUBSTR(p_sql, 1, 90));
    EXCEPTION
        WHEN OTHERS THEN
            -- -1430 columna ya existe, -955 nombre en uso, -1408 ya hay
            -- un indice con esas columnas, -2275 llave foranea ya existe
            IF SQLCODE IN (-1430, -955, -1408, -2275) THEN
                DBMS_OUTPUT.PUT_LINE('OMITIDO : ' || SUBSTR(p_sql, 1, 90));
            ELSE
                RAISE;
            END IF;
    END run_ddl;
BEGIN
    run_ddl('ALTER TABLE CP_PERSONA ADD (id_padron NUMBER)');
    run_ddl('ALTER TABLE CP_PERSONA ADD CONSTRAINT FK_CP_PERSONA_PADRON '
            || 'FOREIGN KEY (id_padron) '
            || 'REFERENCES CP_PADRON_NACIONAL (id_padron) ON DELETE SET NULL');
    run_ddl('CREATE INDEX IX_CP_PERSONA_PADRON ON CP_PERSONA (id_padron) '
            || 'TABLESPACE CP_POS_INDICES');
END;
/

COMMENT ON COLUMN CP_PERSONA.id_padron IS
'Registro del padron nacional que corresponde a la identificacion de la persona. Lo mantiene TRG_CP_PERSONA_PADRON; NULL si la persona no esta en el padron.';

-- ============================================================
-- 2. PARAMETROS DEL PADRON
-- ============================================================

MERGE INTO CP_PARAMETRO p
USING (
    SELECT 'PADRON_ARCHIVO' AS codigo_parametro,
           'PADRON_COMPLETO.txt' AS valor,
           'Nombre del archivo del padron del TSE dentro del directorio DIR_PADRON.' AS descripcion
    FROM DUAL
    UNION ALL
    SELECT 'PADRON_CHARSET',
           'WE8MSWIN1252',
           'Codificacion del archivo del padron (nombre de juego de caracteres de Oracle).'
    FROM DUAL
) n
ON (p.codigo_parametro = n.codigo_parametro)
WHEN NOT MATCHED THEN
    INSERT (codigo_parametro, modulo, tipo_dato, valor, descripcion)
    VALUES (n.codigo_parametro, 'PADRON', 'TEXTO', n.valor, n.descripcion);

COMMIT;

-- ============================================================
-- 3. TABLA EXTERNA CP_PADRON_EXTERNO
-- ============================================================
-- No guarda datos: cada consulta lee el archivo. Se vuelve a crear en
-- cada ejecucion. En cada carga el paquete cambia el archivo con
-- EXTERNAL MODIFY (solo para esa consulta, sin DDL ni COMMIT implicito).
-- La codificacion la aplica PKG_CP_PADRON.apply_charset (seccion 8)
-- desde el parametro PADRON_CHARSET.

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE CP_PADRON_EXTERNO';
EXCEPTION
    WHEN OTHERS THEN
        -- ORA-00942: la tabla no existe todavia, no es un error
        IF SQLCODE != -942 THEN
            RAISE;
        END IF;
END;
/

CREATE TABLE CP_PADRON_EXTERNO (
    cedula            VARCHAR2(30),
    codigo_electoral  VARCHAR2(30),
    sexo              VARCHAR2(10),
    fecha_caducidad   VARCHAR2(20),
    junta             VARCHAR2(20),
    nombre            VARCHAR2(200),
    primer_apellido   VARCHAR2(100),
    segundo_apellido  VARCHAR2(100)
)
ORGANIZATION EXTERNAL (
    TYPE ORACLE_LOADER
    DEFAULT DIRECTORY DIR_PADRON
    ACCESS PARAMETERS (
        RECORDS DELIMITED BY DETECTED NEWLINE
        CHARACTERSET WE8MSWIN1252
        BADFILE DIR_PADRON:'padron_rechazos.bad'
        LOGFILE DIR_PADRON:'padron_carga.log'
        FIELDS TERMINATED BY ',' LRTRIM
        MISSING FIELD VALUES ARE NULL
        REJECT ROWS WITH ALL NULL FIELDS
        (
            cedula            CHAR(30),
            codigo_electoral  CHAR(30),
            sexo              CHAR(10),
            fecha_caducidad   CHAR(20),
            junta             CHAR(20),
            nombre            CHAR(200),
            primer_apellido   CHAR(100),
            segundo_apellido  CHAR(100)
        )
    )
    LOCATION ('PADRON_COMPLETO.txt')
)
REJECT LIMIT UNLIMITED;

-- Oracle no admite COMMENT ON TABLE en una tabla externa (ORA-30657),
-- por eso su descripcion queda aqui: lectura directa del archivo del
-- TSE con 8 campos (cedula, codigo electoral, sexo, fecha de
-- caducidad, junta, nombre, primer apellido y segundo apellido).

-- ============================================================
-- 4. PAQUETE PKG_CP_PADRON (ESPECIFICACION)
-- ============================================================

CREATE OR REPLACE PACKAGE PKG_CP_PADRON AUTHID DEFINER AS

    -- Resultado de la ultima carga o enlace de la sesion (last_result)
    TYPE t_load_result IS RECORD (
        file_name      VARCHAR2(100),
        lines_read     NUMBER,
        valid_rows     NUMBER,
        invalid_rows   NUMBER,
        repeated_rows  NUMBER,
        inserted_rows  NUMBER,
        updated_rows   NUMBER,
        linked_persons NUMBER
    );

    -- Deja una cedula nacional en 9 digitos: '1-1111-1111' y
    -- '111111111' dan '111111111'. Devuelve NULL si el texto no tiene
    -- forma de cedula nacional (pasaporte, DIMEX, cedula juridica).
    FUNCTION normalize_id(
        p_identification IN VARCHAR2
    ) RETURN VARCHAR2 DETERMINISTIC;

    -- id_padron de una identificacion; NULL si no esta en el padron.
    FUNCTION find_padron_id(
        p_identification IN VARCHAR2
    ) RETURN NUMBER;

    -- Busca la identificacion en el padron, devuelve el enlace y
    -- completa los nombres que vengan vacios (lo usa el trigger). Si
    -- al final falta el primer nombre o el primer apellido lanza -20361.
    PROCEDURE complete_person(
        p_identification   IN     VARCHAR2,
        p_padron_id           OUT NUMBER,
        p_first_name       IN OUT VARCHAR2,
        p_second_name      IN OUT VARCHAR2,
        p_last_name        IN OUT VARCHAR2,
        p_second_last_name IN OUT VARCHAR2
    );

    -- Carga el archivo del padron (por defecto el de PADRON_ARCHIVO):
    -- inserta las cedulas nuevas, actualiza solo las que cambiaron y
    -- despues enlaza a las personas. Todo en una sola transaccion: con
    -- p_commit FALSE la deja abierta para quien llama.
    PROCEDURE load_file(
        p_file   IN VARCHAR2 DEFAULT NULL,
        p_commit IN BOOLEAN  DEFAULT TRUE
    );

    -- Recalcula el enlace de todas las personas con el padron actual.
    PROCEDURE link_persons(
        p_commit IN BOOLEAN DEFAULT TRUE
    );

    -- Aplica a la tabla externa la codificacion del parametro
    -- PADRON_CHARSET. Es DDL (ALTER TABLE): confirma la transaccion de
    -- la sesion. Se ejecuta al instalar y despues de cambiar el parametro.
    PROCEDURE apply_charset;

    FUNCTION last_result RETURN t_load_result;

END PKG_CP_PADRON;
/

-- ============================================================
-- 5. PAQUETE PKG_CP_PADRON (CUERPO)
-- ============================================================

CREATE OR REPLACE PACKAGE BODY PKG_CP_PADRON AS

    c_modulo         CONSTANT VARCHAR2(20) := 'PADRON';
    c_param_file     CONSTANT VARCHAR2(30) := 'PADRON_ARCHIVO';
    c_param_charset  CONSTANT VARCHAR2(30) := 'PADRON_CHARSET';

    c_err_file       CONSTANT PLS_INTEGER := -20360;
    c_err_no_name    CONSTANT PLS_INTEGER := -20361;
    c_err_busy       CONSTANT PLS_INTEGER := -20362;
    c_err_read       CONSTANT PLS_INTEGER := -20363;
    c_err_charset    CONSTANT PLS_INTEGER := -20364;

    -- Largo maximo en bytes de las columnas de CP_PERSONA
    c_person_name_bytes CONSTANT PLS_INTEGER := 50;

    -- Una fila del archivo es valida si cumple esta condicion (alias c)
    c_valid_row CONSTANT VARCHAR2(600) :=
           'REGEXP_LIKE(c.cedula, ''^[0-9]{9}$'')'
        || ' AND REGEXP_LIKE(c.codigo_electoral, ''^[0-9]{6}$'')'
        || ' AND c.nombre IS NOT NULL AND c.primer_apellido IS NOT NULL'
        || ' AND LENGTHB(c.nombre) <= 150'
        || ' AND LENGTHB(c.primer_apellido) <= 50'
        || ' AND NVL(LENGTHB(c.segundo_apellido), 0) <= 50';

    e_resource_busy EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_resource_busy, -54);

    e_external_read EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_external_read, -29913);

    e_no_directory EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_no_directory, -6564);

    g_last  t_load_result;
    g_empty t_load_result;


    FUNCTION normalize_id(
        p_identification IN VARCHAR2
    ) RETURN VARCHAR2 DETERMINISTIC
    IS
        v_text VARCHAR2(4000) := TRIM(p_identification);
    BEGIN

        IF v_text IS NULL
           OR NOT REGEXP_LIKE(v_text, '^[1-9]-?[0-9]{4}-?[0-9]{4}$') THEN
            RETURN NULL;
        END IF;

        RETURN REPLACE(v_text, '-');

    END normalize_id;


    FUNCTION find_padron_id(
        p_identification IN VARCHAR2
    ) RETURN NUMBER
    IS
        v_id     CP_PADRON_NACIONAL.id_padron%TYPE;
        v_cedula VARCHAR2(9);
    BEGIN

        v_cedula := normalize_id(p_identification);

        IF v_cedula IS NULL THEN
            RETURN NULL;
        END IF;

        SELECT id_padron
        INTO v_id
        FROM CP_PADRON_NACIONAL
        WHERE cedula = v_cedula;

        RETURN v_id;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
        WHEN OTHERS THEN
            PKG_CP_ERROR.registrar_inesperado(
                c_modulo,
                'find_padron_id identificacion=' || SUBSTR(p_identification, 1, 30)
            );
            RAISE;
    END find_padron_id;


    PROCEDURE complete_person(
        p_identification   IN     VARCHAR2,
        p_padron_id           OUT NUMBER,
        p_first_name       IN OUT VARCHAR2,
        p_second_name      IN OUT VARCHAR2,
        p_last_name        IN OUT VARCHAR2,
        p_second_last_name IN OUT VARCHAR2
    )
    IS
        v_row    CP_PADRON_NACIONAL%ROWTYPE;
        v_cedula VARCHAR2(9);
        v_found  BOOLEAN := FALSE;
        v_space  PLS_INTEGER;
    BEGIN

        p_padron_id := NULL;
        v_cedula    := normalize_id(p_identification);

        IF v_cedula IS NOT NULL THEN
            BEGIN
                SELECT *
                INTO v_row
                FROM CP_PADRON_NACIONAL
                WHERE cedula = v_cedula;

                v_found     := TRUE;
                p_padron_id := v_row.id_padron;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_found := FALSE;
            END;
        END IF;

        -- El padron trae los nombres juntos ("MARIA JOSE"): la primera
        -- palabra es el primer nombre y el resto el segundo.
        IF v_found AND p_first_name IS NULL THEN
            v_space := INSTR(v_row.nombre, ' ');

            IF v_space = 0 THEN
                p_first_name := SUBSTRB(v_row.nombre, 1, c_person_name_bytes);
            ELSE
                p_first_name := SUBSTRB(SUBSTR(v_row.nombre, 1, v_space - 1),
                                        1, c_person_name_bytes);
                IF p_second_name IS NULL THEN
                    p_second_name := SUBSTRB(TRIM(SUBSTR(v_row.nombre, v_space + 1)),
                                             1, c_person_name_bytes);
                END IF;
            END IF;
        END IF;

        IF v_found THEN
            p_last_name        := NVL(p_last_name, v_row.primer_apellido);
            p_second_last_name := NVL(p_second_last_name, v_row.segundo_apellido);
        END IF;

        IF p_first_name IS NULL OR p_last_name IS NULL THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_no_name,
                'La persona con identificacion ' || SUBSTR(p_identification, 1, 30)
                || ' no tiene nombre y su identificacion no esta en el padron.'
            );
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            PKG_CP_ERROR.registrar_inesperado(
                c_modulo,
                'complete_person identificacion=' || SUBSTR(p_identification, 1, 30)
            );
            RAISE;
    END complete_person;


    -- Actualiza id_padron solo donde cambia. TRG_CP_PERSONA_PADRON
    -- vuelve a calcular el mismo valor desde la identificacion, asi que
    -- el enlace nunca puede quedar distinto de la cedula de la persona.
    FUNCTION link_all RETURN NUMBER
    IS
    BEGIN

        UPDATE CP_PERSONA p
        SET p.id_padron = (SELECT pn.id_padron
                           FROM CP_PADRON_NACIONAL pn
                           WHERE pn.cedula = PKG_CP_PADRON.normalize_id(p.identificacion))
        WHERE DECODE(p.id_padron,
                     (SELECT pn.id_padron
                      FROM CP_PADRON_NACIONAL pn
                      WHERE pn.cedula = PKG_CP_PADRON.normalize_id(p.identificacion)),
                     0, 1) = 1;

        RETURN SQL%ROWCOUNT;

    END link_all;


    -- Nombre de archivo leido del parametro o recibido; solo letras,
    -- numeros, punto, guion y guion bajo (va dentro de un SQL dinamico).
    FUNCTION checked_file(
        p_file IN VARCHAR2
    ) RETURN VARCHAR2
    IS
        v_file VARCHAR2(4000);
    BEGIN

        v_file := TRIM(NVL(p_file, PKG_CP_PARAMETRO.obtener_texto(c_param_file)));

        IF v_file IS NULL
           OR LENGTH(v_file) > 100
           OR NOT REGEXP_LIKE(v_file, '^[A-Za-z0-9_][A-Za-z0-9_.-]*$')
           OR INSTR(v_file, '..') > 0 THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_file,
                'El nombre de archivo "' || SUBSTR(v_file, 1, 100) || '" no es valido: '
                || 'use solo letras, numeros, punto, guion y guion bajo.'
            );
        END IF;

        RETURN v_file;

    END checked_file;


    -- Codificacion del parametro; debe ser un juego de caracteres de Oracle.
    FUNCTION checked_charset RETURN VARCHAR2
    IS
        v_charset VARCHAR2(4000);
        v_id      NUMBER;
    BEGIN

        v_charset := UPPER(TRIM(PKG_CP_PARAMETRO.obtener_texto(c_param_charset)));

        IF v_charset IS NOT NULL AND REGEXP_LIKE(v_charset, '^[A-Z0-9]{1,30}$') THEN
            SELECT NLS_CHARSET_ID(v_charset) INTO v_id FROM DUAL;
        END IF;

        IF v_id IS NULL THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_charset,
                'El parametro ' || c_param_charset || ' ("' || SUBSTR(v_charset, 1, 30)
                || '") no es un juego de caracteres de Oracle; por ejemplo WE8MSWIN1252 o AL32UTF8.'
            );
        END IF;

        RETURN v_charset;

    END checked_charset;


    -- Parametros de acceso de la tabla externa; son los mismos de la
    -- seccion 3 del script, con la codificacion recibida.
    FUNCTION access_parameters(
        p_charset IN VARCHAR2
    ) RETURN VARCHAR2
    IS
    BEGIN

        RETURN 'RECORDS DELIMITED BY DETECTED NEWLINE'
            || ' CHARACTERSET ' || p_charset
            || ' BADFILE DIR_PADRON:''padron_rechazos.bad'''
            || ' LOGFILE DIR_PADRON:''padron_carga.log'''
            || ' FIELDS TERMINATED BY '','' LRTRIM'
            || ' MISSING FIELD VALUES ARE NULL'
            || ' REJECT ROWS WITH ALL NULL FIELDS'
            || ' (cedula CHAR(30), codigo_electoral CHAR(30), sexo CHAR(10),'
            || ' fecha_caducidad CHAR(20), junta CHAR(20), nombre CHAR(200),'
            || ' primer_apellido CHAR(100), segundo_apellido CHAR(100))';

    END access_parameters;


    -- Consulta que lee el archivo, ya limpia de espacios y de fines de
    -- linea de Windows, con el numero de linea para resolver repetidas.
    -- EXTERNAL MODIFY cambia el archivo solo para esta consulta, sin DDL.
    FUNCTION source_query(
        p_file IN VARCHAR2
    ) RETURN VARCHAR2
    IS
    BEGIN

        RETURN 'SELECT ROWNUM AS line_no,'
            || ' TRIM(RTRIM(cedula, CHR(13))) AS cedula,'
            || ' TRIM(RTRIM(codigo_electoral, CHR(13))) AS codigo_electoral,'
            || ' TRIM(RTRIM(nombre, CHR(13))) AS nombre,'
            || ' TRIM(RTRIM(primer_apellido, CHR(13))) AS primer_apellido,'
            || ' TRIM(RTRIM(segundo_apellido, CHR(13))) AS segundo_apellido'
            || ' FROM CP_PADRON_EXTERNO EXTERNAL MODIFY ('
            || ' LOCATION (''' || p_file || '''))';

    END source_query;


    PROCEDURE load_file(
        p_file   IN VARCHAR2 DEFAULT NULL,
        p_commit IN BOOLEAN  DEFAULT TRUE
    )
    IS
        v_file     VARCHAR2(100);
        v_source   VARCHAR2(4000);
        v_distinct NUMBER;
        v_before   NUMBER;
        v_after    NUMBER;
        v_merged   NUMBER;
        v_result   t_load_result;
    BEGIN

        SAVEPOINT sp_padron_load;
        g_last := g_empty;

        v_file   := checked_file(p_file);
        v_source := source_query(v_file);

        -- Dos cargas a la vez se pisarian: la segunda se rechaza sin esperar
        BEGIN
            LOCK TABLE CP_PADRON_NACIONAL IN EXCLUSIVE MODE NOWAIT;
        EXCEPTION
            WHEN e_resource_busy THEN
                PKG_CP_ERROR.lanzar(
                    c_modulo,
                    c_err_busy,
                    'Hay otra carga del padron en curso; intente de nuevo cuando termine.'
                );
        END;

        EXECUTE IMMEDIATE
               'SELECT COUNT(*),'
            || ' COUNT(CASE WHEN ' || c_valid_row || ' THEN 1 END),'
            || ' COUNT(DISTINCT CASE WHEN ' || c_valid_row || ' THEN c.cedula END)'
            || ' FROM (' || v_source || ') c'
        INTO v_result.lines_read, v_result.valid_rows, v_distinct;

        v_result.file_name     := v_file;
        v_result.invalid_rows  := v_result.lines_read - v_result.valid_rows;
        v_result.repeated_rows := v_result.valid_rows - v_distinct;

        SELECT COUNT(*) INTO v_before FROM CP_PADRON_NACIONAL;

        -- Si una cedula se repite en el archivo gana la ultima linea.
        -- Solo se actualiza lo que cambio: repetir la carga no genera
        -- redo de millones de filas iguales hacia la standby.
        EXECUTE IMMEDIATE
               'MERGE INTO CP_PADRON_NACIONAL t'
            || ' USING (SELECT cedula, codigo_electoral, nombre,'
            || '               primer_apellido, segundo_apellido'
            || '        FROM (SELECT c.*,'
            || '                     ROW_NUMBER() OVER (PARTITION BY c.cedula'
            || '                                        ORDER BY c.line_no DESC) AS rn'
            || '              FROM (' || v_source || ') c'
            || '              WHERE ' || c_valid_row || ')'
            || '        WHERE rn = 1) s'
            || ' ON (t.cedula = s.cedula)'
            || ' WHEN MATCHED THEN UPDATE SET'
            || '     t.nombre           = s.nombre,'
            || '     t.primer_apellido  = s.primer_apellido,'
            || '     t.segundo_apellido = s.segundo_apellido,'
            || '     t.codigo_electoral = s.codigo_electoral'
            || '   WHERE DECODE(t.nombre, s.nombre, 0, 1)'
            || '       + DECODE(t.primer_apellido, s.primer_apellido, 0, 1)'
            || '       + DECODE(t.segundo_apellido, s.segundo_apellido, 0, 1)'
            || '       + DECODE(t.codigo_electoral, s.codigo_electoral, 0, 1) > 0'
            || ' WHEN NOT MATCHED THEN INSERT'
            || '     (cedula, nombre, primer_apellido, segundo_apellido, codigo_electoral)'
            || '   VALUES (s.cedula, s.nombre, s.primer_apellido,'
            || '           s.segundo_apellido, s.codigo_electoral)';

        v_merged := SQL%ROWCOUNT;

        SELECT COUNT(*) INTO v_after FROM CP_PADRON_NACIONAL;

        v_result.inserted_rows  := v_after - v_before;
        v_result.updated_rows   := v_merged - v_result.inserted_rows;
        v_result.linked_persons := link_all;

        g_last := v_result;

        IF p_commit THEN
            COMMIT;
        END IF;

        DBMS_OUTPUT.PUT_LINE('Carga del padron: ' || v_file);
        DBMS_OUTPUT.PUT_LINE('  Lineas leidas      : ' || v_result.lines_read);
        DBMS_OUTPUT.PUT_LINE('  Validas            : ' || v_result.valid_rows);
        DBMS_OUTPUT.PUT_LINE('  Invalidas          : ' || v_result.invalid_rows);
        DBMS_OUTPUT.PUT_LINE('  Repetidas          : ' || v_result.repeated_rows);
        DBMS_OUTPUT.PUT_LINE('  Insertadas         : ' || v_result.inserted_rows);
        DBMS_OUTPUT.PUT_LINE('  Actualizadas       : ' || v_result.updated_rows);
        DBMS_OUTPUT.PUT_LINE('  Personas enlazadas : ' || v_result.linked_persons);

    EXCEPTION
        WHEN e_external_read OR e_no_directory THEN
            ROLLBACK TO SAVEPOINT sp_padron_load;
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_read,
                'No se pudo leer el archivo ' || v_file || ' en DIR_PADRON: revise que exista '
                || 'y que CP_POS tenga READ y WRITE sobre el directorio.',
                SUBSTR(SQLERRM, 1, 1000)
            );
        WHEN OTHERS THEN
            ROLLBACK TO SAVEPOINT sp_padron_load;
            PKG_CP_ERROR.registrar_inesperado(c_modulo, 'load_file archivo=' || v_file);
            RAISE;
    END load_file;


    PROCEDURE link_persons(
        p_commit IN BOOLEAN DEFAULT TRUE
    )
    IS
    BEGIN

        SAVEPOINT sp_padron_link;
        g_last := g_empty;

        g_last.linked_persons := link_all;

        IF p_commit THEN
            COMMIT;
        END IF;

        DBMS_OUTPUT.PUT_LINE('Personas con enlace actualizado: ' || g_last.linked_persons);

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK TO SAVEPOINT sp_padron_link;
            PKG_CP_ERROR.registrar_inesperado(c_modulo, 'link_persons');
            RAISE;
    END link_persons;


    PROCEDURE apply_charset
    IS
        v_charset VARCHAR2(30);
    BEGIN

        v_charset := checked_charset;

        EXECUTE IMMEDIATE 'ALTER TABLE CP_PADRON_EXTERNO ACCESS PARAMETERS ('
                          || access_parameters(v_charset) || ')';

        DBMS_OUTPUT.PUT_LINE('CP_PADRON_EXTERNO lee el archivo en ' || v_charset);

    EXCEPTION
        WHEN OTHERS THEN
            PKG_CP_ERROR.registrar_inesperado(c_modulo, 'apply_charset');
            RAISE;
    END apply_charset;


    FUNCTION last_result RETURN t_load_result
    IS
    BEGIN
        RETURN g_last;
    END last_result;

END PKG_CP_PADRON;
/

SHOW ERRORS PACKAGE BODY PKG_CP_PADRON

-- ============================================================
-- 6. TRIGGER TRG_CP_PERSONA_PADRON
-- ============================================================
-- El enlace se calcula siempre desde la identificacion: si alguien
-- escribe id_padron a mano, el trigger lo vuelve a calcular. Los nombres
-- solo se completan cuando vienen vacios.

CREATE OR REPLACE TRIGGER TRG_CP_PERSONA_PADRON
BEFORE INSERT OR UPDATE OF identificacion, id_padron ON CP_PERSONA
FOR EACH ROW
BEGIN
    PKG_CP_PADRON.complete_person(
        p_identification   => :NEW.identificacion,
        p_padron_id        => :NEW.id_padron,
        p_first_name       => :NEW.primer_nombre,
        p_second_name      => :NEW.segundo_nombre,
        p_last_name        => :NEW.primer_apellido,
        p_second_last_name => :NEW.segundo_apellido
    );
END;
/

SHOW ERRORS TRIGGER TRG_CP_PERSONA_PADRON

-- ============================================================
-- 7. VISTA VW_CP_CLIENTE_PADRON
-- ============================================================

CREATE OR REPLACE VIEW VW_CP_CLIENTE_PADRON AS
SELECT c.id_cliente,
       p.id_persona,
       p.identificacion,
       p.primer_nombre,
       p.segundo_nombre,
       p.primer_apellido,
       p.segundo_apellido,
       pn.cedula           AS cedula_padron,
       pn.nombre           AS nombre_padron,
       pn.primer_apellido  AS primer_apellido_padron,
       pn.segundo_apellido AS segundo_apellido_padron,
       pn.codigo_electoral,
       CASE WHEN pn.id_padron IS NULL THEN 'N' ELSE 'S' END AS en_padron
FROM CP_CLIENTE c
JOIN CP_CLIENTE_PERSONA cp
  ON cp.id_cliente = c.id_cliente
JOIN CP_PERSONA p
  ON p.id_persona = cp.id_persona
LEFT JOIN CP_PADRON_NACIONAL pn
  ON pn.id_padron = p.id_padron;

COMMENT ON TABLE VW_CP_CLIENTE_PADRON IS
'Clientes persona con sus datos basicos del padron nacional (en_padron = N si su identificacion no esta en el padron).';

-- ============================================================
-- 8. CODIFICACION Y ENLACE DE LAS PERSONAS QUE YA EXISTIAN
-- ============================================================

BEGIN
    PKG_CP_PADRON.apply_charset;
    PKG_CP_PADRON.link_persons;
END;
/

-- ============================================================
-- 9. PRUEBAS DEL PADRON
-- ============================================================
-- Todas deben salir OK. Se ejecutan como CP_POS y todo se deshace con
-- ROLLBACK. Las pruebas escriben un archivo pequeno en DIR_PADRON en
-- la codificacion de PADRON_CHARSET (Windows-1252 por defecto) y con
-- fin de linea CRLF, igual que el del TSE, con
-- cedulas 99999000x que no son reales; al terminar lo borran. Solo se
-- borran de la bitacora los errores provocados a proposito.

DECLARE
    c_file     CONSTANT VARCHAR2(40) := 'padron_prueba_cp.txt';
    c_padding  CONSTANT VARCHAR2(20) := '          ';

    v_antes    NUMBER;
    v_ok       NUMBER := 0;
    v_falla    NUMBER := 0;
    v_res      PKG_CP_PADRON.t_load_result;
    v_count    NUMBER;
    v_code     NUMBER;

    v_nac      NUMBER;
    v_civil    NUMBER;
    v_sexo     NUMBER;
    v_esc      NUMBER;
    v_resid    NUMBER;
    v_tipo_cli NUMBER;
    v_est_cli  NUMBER;
    v_cliente  NUMBER;

    v_p0       NUMBER;
    v_p1       NUMBER;
    v_p2       NUMBER;
    v_p3       NUMBER;
    v_pad1     NUMBER;
    v_pad2     NUMBER;
    v_pad3     NUMBER;
    v_link     NUMBER;

    v_name1    VARCHAR2(50);
    v_name2    VARCHAR2(50);
    v_last1    VARCHAR2(50);
    v_last2    VARCHAR2(50);
    v_flag     VARCHAR2(1);
    v_cedula   VARCHAR2(9);

    v_munoz    VARCHAR2(20) := UNISTR('MU\00D1OZ');
    v_charset  VARCHAR2(30) := UPPER(TRIM(PKG_CP_PARAMETRO.obtener_texto('PADRON_CHARSET')));

    PROCEDURE reportar(
        p_prueba IN VARCHAR2,
        p_ok     IN BOOLEAN
    )
    IS
    BEGIN
        IF p_ok THEN
            v_ok := v_ok + 1;
        ELSE
            v_falla := v_falla + 1;
        END IF;
        DBMS_OUTPUT.PUT_LINE(
            RPAD(p_prueba, 72, '.') || CASE WHEN p_ok THEN ' OK' ELSE ' FALLA' END
        );
    END reportar;

    -- Escribe el archivo de prueba como lo entrega el TSE
    PROCEDURE write_file(
        p_lines IN SYS.ODCIVARCHAR2LIST
    )
    IS
        v_handle UTL_FILE.FILE_TYPE;
    BEGIN
        v_handle := UTL_FILE.FOPEN('DIR_PADRON', c_file, 'wb', 32767);
        FOR i IN 1 .. p_lines.COUNT LOOP
            UTL_FILE.PUT_RAW(
                v_handle,
                UTL_I18N.STRING_TO_RAW(p_lines(i) || CHR(13) || CHR(10), v_charset),
                TRUE
            );
        END LOOP;
        UTL_FILE.FCLOSE(v_handle);
    EXCEPTION
        WHEN OTHERS THEN
            IF UTL_FILE.IS_OPEN(v_handle) THEN
                UTL_FILE.FCLOSE(v_handle);
            END IF;
            RAISE;
    END write_file;

    -- Carga sin confirmar y devuelve el codigo de error (0 si no hubo)
    FUNCTION load_code(
        p_file IN VARCHAR2
    ) RETURN NUMBER
    IS
    BEGIN
        PKG_CP_PADRON.load_file(p_file, FALSE);
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN SQLCODE;
    END load_code;

    FUNCTION new_person(
        p_identification IN VARCHAR2,
        p_first_name     IN VARCHAR2,
        p_last_name      IN VARCHAR2
    ) RETURN NUMBER
    IS
        v_id NUMBER;
    BEGIN
        INSERT INTO CP_PERSONA (
            id_nacionalidad, id_estado_civil, id_sexo, id_escolaridad,
            id_tipo_residencia, identificacion, primer_nombre,
            primer_apellido, fecha_nacimiento
        )
        VALUES (
            v_nac, v_civil, v_sexo, v_esc,
            v_resid, p_identification, p_first_name,
            p_last_name, DATE '1990-01-01'
        )
        RETURNING id_persona INTO v_id;
        RETURN v_id;
    END new_person;

    FUNCTION person_code(
        p_identification IN VARCHAR2
    ) RETURN NUMBER
    IS
        v_id NUMBER;
    BEGIN
        v_id := new_person(p_identification, NULL, NULL);
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN SQLCODE;
    END person_code;

    FUNCTION padron_of(
        p_cedula IN VARCHAR2
    ) RETURN NUMBER
    IS
        v_id NUMBER;
    BEGIN
        SELECT id_padron INTO v_id FROM CP_PADRON_NACIONAL WHERE cedula = p_cedula;
        RETURN v_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END padron_of;

    FUNCTION link_of(
        p_persona IN NUMBER
    ) RETURN NUMBER
    IS
        v_id NUMBER;
    BEGIN
        SELECT id_padron INTO v_id FROM CP_PERSONA WHERE id_persona = p_persona;
        RETURN v_id;
    END link_of;

BEGIN

    SELECT NVL(MAX(id_bitacora_error), 0) INTO v_antes FROM CP_BITACORA_ERROR;

    SELECT MIN(id_nacionalidad)    INTO v_nac   FROM CP_NACIONALIDAD;
    SELECT MIN(id_estado_civil)    INTO v_civil FROM CP_ESTADO_CIVIL;
    SELECT MIN(id_sexo)            INTO v_sexo  FROM CP_SEXO;
    SELECT MIN(id_escolaridad)     INTO v_esc   FROM CP_ESCOLARIDAD;
    SELECT MIN(id_tipo_residencia) INTO v_resid FROM CP_TIPO_RESIDENCIA;

    -- 1
    SELECT COUNT(*) INTO v_count
    FROM CP_PADRON_NACIONAL
    WHERE cedula IN ('999990001', '999990002', '999990003', '999990004');

    reportar('01. Las cedulas de prueba no existen antes de empezar', v_count = 0);

    -- 2
    v_p0 := new_person('9-9999-0003', 'Ana', 'Perez');

    reportar('02. Persona que no esta en el padron queda sin enlace',
             link_of(v_p0) IS NULL);

    -- 3 y 4: tres validas, una cedula repetida, una cedula mala y una
    -- linea incompleta. La 1 trae espacios de relleno como el TSE.
    write_file(SYS.ODCIVARCHAR2LIST(
        '999990001,101001,2,20301231,00001,MARIA JOSE' || c_padding || ','
            || v_munoz || c_padding || ',ROJAS' || c_padding,
        '999990002,101001,1,20301231,00001,CARLOS,SOLIS,',
        '999990003,101001,2,20301231,00001,ANA,PEREZ,MORA',
        'ABC123,101001,1,20301231,00001,MAL,CEDULA,X',
        '999990004,101001',
        '999990003,101001,2,20301231,00001,ANA,PEREZ,MORA'
    ));

    v_code := load_code(c_file);
    v_res  := PKG_CP_PADRON.last_result;

    reportar('03. Carga: 6 leidas, 4 validas, 2 invalidas, 1 repetida',
             v_code = 0 AND v_res.lines_read = 6 AND v_res.valid_rows = 4
             AND v_res.invalid_rows = 2 AND v_res.repeated_rows = 1);

    reportar('04. Carga: 3 insertadas y 0 actualizadas',
             v_code = 0 AND v_res.inserted_rows = 3 AND v_res.updated_rows = 0);

    -- 5
    SELECT primer_apellido INTO v_last1
    FROM CP_PADRON_NACIONAL WHERE cedula = '999990001';

    reportar('05. La enie llega bien con la codificacion del archivo (MUNOZ)',
             v_last1 = v_munoz);

    -- 6
    SELECT nombre, segundo_apellido INTO v_name1, v_last2
    FROM CP_PADRON_NACIONAL WHERE cedula = '999990001';

    SELECT COUNT(*) INTO v_count
    FROM CP_PADRON_NACIONAL
    WHERE cedula = '999990002' AND segundo_apellido IS NULL;

    reportar('06. Sin espacios de relleno ni fin de linea; apellido vacio queda NULL',
             v_name1 = 'MARIA JOSE' AND v_last2 = 'ROJAS' AND v_count = 1);

    -- 7
    v_pad1 := padron_of('999990001');
    v_pad2 := padron_of('999990002');
    v_pad3 := padron_of('999990003');

    reportar('07. La carga enlaza a la persona que ya existia (cedula con guiones)',
             v_res.linked_persons >= 1 AND link_of(v_p0) = v_pad3);

    -- 8
    v_code := load_code(c_file);
    v_res  := PKG_CP_PADRON.last_result;

    reportar('08. Repetir la misma carga no inserta ni actualiza nada',
             v_code = 0 AND v_res.inserted_rows = 0 AND v_res.updated_rows = 0);

    -- 9
    write_file(SYS.ODCIVARCHAR2LIST(
        '999990002,101001,1,20301231,00001,CARLOS ANDRES,SOLIS,'
    ));

    v_code := load_code(c_file);
    v_res  := PKG_CP_PADRON.last_result;

    SELECT nombre INTO v_name1 FROM CP_PADRON_NACIONAL WHERE cedula = '999990002';

    reportar('09. Un nombre que cambio en el archivo se actualiza (1 fila)',
             v_code = 0 AND v_res.updated_rows = 1 AND v_res.inserted_rows = 0
             AND v_name1 = 'CARLOS ANDRES');

    -- 10
    v_p1 := new_person('999990001', NULL, NULL);

    SELECT primer_nombre, segundo_nombre, primer_apellido, segundo_apellido
    INTO v_name1, v_name2, v_last1, v_last2
    FROM CP_PERSONA WHERE id_persona = v_p1;

    reportar('10. Persona registrada solo con la cedula: nombre y apellidos del padron',
             link_of(v_p1) = v_pad1 AND v_name1 = 'MARIA' AND v_name2 = 'JOSE'
             AND v_last1 = v_munoz AND v_last2 = 'ROJAS');

    -- 11
    v_p2 := new_person('9-9999-0002', 'Carlos', 'Solis');

    SELECT primer_nombre INTO v_name1 FROM CP_PERSONA WHERE id_persona = v_p2;

    reportar('11. Cedula con guiones se enlaza y respeta el nombre escrito',
             link_of(v_p2) = v_pad2 AND v_name1 = 'Carlos');

    -- 12
    v_p3 := new_person('P-12345678', 'John', 'Smith');

    reportar('12. Pasaporte (fuera del padron) con nombre: se registra sin enlace',
             link_of(v_p3) IS NULL);

    -- 13
    v_code := person_code('P-87654321');

    reportar('13. Fuera del padron y sin nombre: se rechaza con -20361',
             v_code = -20361);

    -- 14
    UPDATE CP_PERSONA SET identificacion = '999990004' WHERE id_persona = v_p3;
    v_link := link_of(v_p3);

    UPDATE CP_PERSONA SET identificacion = '999990003' WHERE id_persona = v_p3;
    UPDATE CP_PERSONA SET id_padron = v_pad1 WHERE id_persona = v_p3;

    reportar('14. Cambiar la identificacion recalcula el enlace; a mano no se puede',
             v_link IS NULL AND link_of(v_p3) = v_pad3);

    -- 15
    SELECT id_tipo_cliente INTO v_tipo_cli
    FROM CP_TIPO_CLIENTE WHERE nombre_tipo_cliente = 'PERSONA';

    SELECT id_estado_cliente INTO v_est_cli
    FROM CP_ESTADO_CLIENTE WHERE nombre_estado_cliente = 'ACTIVO';

    INSERT INTO CP_CLIENTE (id_tipo_cliente, id_estado_cliente, fecha_ingreso)
    VALUES (v_tipo_cli, v_est_cli, TRUNC(SYSDATE))
    RETURNING id_cliente INTO v_cliente;

    INSERT INTO CP_CLIENTE_PERSONA (id_cliente, id_persona)
    VALUES (v_cliente, v_p1);

    SELECT en_padron, cedula_padron INTO v_flag, v_cedula
    FROM VW_CP_CLIENTE_PADRON WHERE id_cliente = v_cliente;

    reportar('15. La vista muestra al cliente con sus datos del padron',
             v_flag = 'S' AND v_cedula = '999990001');

    -- 16
    v_code := load_code('../etc/passwd');

    reportar('16. Nombre de archivo con ruta se rechaza con -20360', v_code = -20360);

    -- 17
    v_code := load_code('no_existe_padron_cp.txt');

    reportar('17. Archivo que no existe se rechaza con -20363', v_code = -20363);

    -- 18
    ROLLBACK;

    SELECT COUNT(*) INTO v_count
    FROM CP_PADRON_NACIONAL
    WHERE cedula IN ('999990001', '999990002', '999990003', '999990004');

    SELECT v_count + COUNT(*) INTO v_count
    FROM CP_PERSONA
    WHERE id_persona IN (v_p0, v_p1, v_p2, v_p3);

    reportar('18. El ROLLBACK deja la base sin las cedulas ni las personas de prueba',
             v_count = 0);

    UTL_FILE.FREMOVE('DIR_PADRON', c_file);

    DELETE FROM CP_BITACORA_ERROR
    WHERE id_bitacora_error > v_antes
      AND modulo = 'PADRON';
    COMMIT;

    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'Resultado: ' || v_ok || ' OK, '
                         || v_falla || ' FALLA');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        BEGIN
            UTL_FILE.FREMOVE('DIR_PADRON', c_file);
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
        DBMS_OUTPUT.PUT_LINE('ERROR en las pruebas: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        RAISE;
END;
/

-- ============================================================
-- 10. JOB MENSUAL DE CARGA
-- ============================================================
-- Corre el dia 1 de cada mes a las 02:00 con el archivo del parametro
-- PADRON_ARCHIVO. No se lanza al instalar porque la carga completa
-- tarda varios minutos. A peticion del profesor:
--   EXEC PKG_CP_PADRON.load_file;
-- o lanzar el job al instante con:
--   EXEC DBMS_SCHEDULER.RUN_JOB('JOB_CP_CARGA_PADRON', FALSE);

BEGIN

    BEGIN
        DBMS_SCHEDULER.DROP_JOB('JOB_CP_CARGA_PADRON', force => TRUE);
    EXCEPTION
        WHEN OTHERS THEN
            -- ORA-27475: el job no existe todavia, no es un error
            IF SQLCODE != -27475 THEN
                RAISE;
            END IF;
    END;

    DBMS_SCHEDULER.CREATE_JOB(
        job_name        => 'JOB_CP_CARGA_PADRON',
        job_type        => 'PLSQL_BLOCK',
        job_action      => 'BEGIN PKG_CP_PADRON.load_file; END;',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=MONTHLY;BYMONTHDAY=1;BYHOUR=2;BYMINUTE=0;BYSECOND=0',
        enabled         => TRUE,
        comments        => 'Carga mensual del padron nacional del TSE y enlace con las personas.'
    );

END;
/

SELECT job_name, enabled, state, repeat_interval, next_run_date
FROM   user_scheduler_jobs
WHERE  job_name = 'JOB_CP_CARGA_PADRON';

-- ============================================================
-- 11. RECOMPILAR LO QUE INVALIDO EL CAMBIO DE MODELO
-- ============================================================
-- El ALTER TABLE de la seccion 1 cambia CP_PERSONA, y Oracle puede
-- marcar INVALID a las rutinas que la usan (por ejemplo
-- PRC_CP_NOTIFICACION_MORA_GERENTE_COORDINADOR). Se compilan solo las
-- invalidas del esquema; asi el control diario de objetos invalidos
-- no envia una alerta falsa.

BEGIN
    DBMS_UTILITY.COMPILE_SCHEMA(schema => USER, compile_all => FALSE);
END;
/

-- Debe salir 0
SELECT COUNT(*) AS objetos_invalidos
FROM   user_objects
WHERE  status = 'INVALID';

-- ============================================================
-- 12. CONSULTAS PARA LA DEFENSA
-- ============================================================

-- Objetos del modulo (todos VALID)
SELECT object_name, object_type, status
FROM   user_objects
WHERE  object_name IN ('PKG_CP_PADRON', 'TRG_CP_PERSONA_PADRON',
                       'VW_CP_CLIENTE_PADRON', 'CP_PADRON_EXTERNO')
ORDER  BY object_name, object_type;

-- Registros en el padron y personas enlazadas
SELECT (SELECT COUNT(*) FROM CP_PADRON_NACIONAL)               AS registros_padron,
       (SELECT COUNT(*) FROM CP_PERSONA)                       AS personas,
       (SELECT COUNT(*) FROM CP_PERSONA WHERE id_padron IS NOT NULL) AS personas_enlazadas
FROM   dual;

-- Clientes con sus datos del padron
SELECT id_cliente, identificacion, primer_nombre, primer_apellido,
       en_padron, nombre_padron, primer_apellido_padron, codigo_electoral
FROM   VW_CP_CLIENTE_PADRON
ORDER  BY id_cliente;

-- Ultimas corridas del job
SELECT job_name, status, actual_start_date, run_duration, errors
FROM   user_scheduler_job_run_details
WHERE  job_name = 'JOB_CP_CARGA_PADRON'
ORDER  BY log_date DESC
FETCH FIRST 3 ROWS ONLY;
