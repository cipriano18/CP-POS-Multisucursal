-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- BASE DE DATOS: Oracle 21c
-- SCRIPT: CP_notificaciones_paquetes.sql
-- DESCRIPCION: Avisos de negocio y monitoreo de la base de datos en
--              dos paquetes (requisitos 1 y 13). Reemplaza los nueve
--              procedimientos sueltos de Notificaciones/procedures/ y
--              sus jobs de jobs/diarios/ (los retira en la seccion 1).
--              PKG_CP_ALERTA: clientes con el 85% de su credito,
--              proveedores con el 85% (coordinador) y el 70% (gerente),
--              clientes en mora (gerente y coordinador, y a cada
--              cliente) y productos vencidos con su total.
--              PKG_CP_MONITOREO: uso de tablespaces, objetos invalidos,
--              indices inutilizables, sesiones y bloqueos, errores de
--              la bitacora y crecimiento de la base (CP_MONITOREO_TABLESPACE).
--              Todos los avisos pasan por PKG_CP_AVISO (script 26A) a la
--              cola de PKG_CP_NOTIFICACIONES; los envia el job
--              JOB_CP_PROCESAR_NOTIFICACIONES.
--
-- PARAMETROS (CP_PARAMETRO):
--   UMBRAL_CXC_CLIENTE_PCT      (85)  aviso a cada cliente
--   UMBRAL_CXP_COORDINADOR_PCT  (85)  proveedores, al coordinador
--   UMBRAL_CXP_GERENTE_PCT      (70)  proveedores, al gerente
--   MOROSIDAD_DIAS_SIN_PAGO     (30)  dias sin pagar para estar en mora
--   TABLESPACE_UMBRAL_PCT       (85)  ocupacion de un tablespace
--   SESIONES_UMBRAL_PCT         (85)  sesiones o procesos usados (nuevo)
--   SESION_BLOQUEO_SEGUNDOS     (60)  espera de una sesion bloqueada (nuevo)
--
-- EJECUTAR COMO: CP_POS en XEPDB1, despues del 26A (con queue_notice_to)
--                y del modulo de notificaciones (pasos 1 a 4). Antes, como
--                SYS, los GRANT de V_$PARAMETER y V_$PROCESS de la
--                seccion 10 de CP_usuario_esquema.sql.
--                Se puede volver a ejecutar completo.
--
-- ERRORES PROPIOS:
--   -20380 un porcentaje de alerta no es mayor que cero
--   -20381 los dias de morosidad no son un entero mayor que cero
--   -20390 un parametro de monitoreo no es valido
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED

-- ============================================================
-- 1. RETIRO DE LOS PROCEDIMIENTOS SUELTOS Y SUS JOBS
-- ============================================================
-- Primero los jobs, para que no llamen a un procedimiento borrado.
-- JOB_CP_PROCESAR_NOTIFICACIONES (el envio de la cola) se conserva.
-- ORA-27475: el job no existe. ORA-04043: el objeto no existe.

DECLARE
    TYPE t_names IS TABLE OF VARCHAR2(128);

    v_jobs t_names := t_names(
        'JOB_CP_ALERTA_CREDITO_85',
        'JOB_CP_ALERTA_MORA_CLIENTES',
        'JOB_CP_NOTIFICACION_MORA_GERENTE_COORDINADOR',
        'JOB_CP_ALERTA_CXP_COORDINADOR',
        'JOB_CP_ALERTA_CXP_GERENTE',
        'JOB_CP_NOTIFICACION_PRODUCTOS_VENCIDOS_COORD',
        'JOB_CP_VERIFICAR_TABLESPACES',
        'JOB_CP_VERIFICAR_OBJETOS_INVALIDOS',
        'JOB_CP_VERIFICAR_INDICES'
    );

    v_procedures t_names := t_names(
        'PRC_CP_ALERTA_CREDITO_85',
        'PRC_CP_ALERTA_MORA_CLIENTES',
        'PRC_CP_NOTIFICACION_MORA_GERENTE_COORDINADOR',
        'PRC_CP_ALERTA_CXP_COORDINADOR',
        'PRC_CP_ALERTA_CXP_GERENTE',
        'PRC_CP_NOTIFICACION_PRODUCTOS_VENCIDOS_COORD',
        'VERIFICAR_TABLESPACES',
        'VERIFICAR_OBJETOS_INVALIDOS',
        'VERIFICAR_INDICES'
    );
BEGIN

    FOR i IN 1 .. v_jobs.COUNT LOOP
        BEGIN
            DBMS_SCHEDULER.DROP_JOB(v_jobs(i), force => TRUE);
            DBMS_OUTPUT.PUT_LINE('Job retirado: ' || v_jobs(i));
        EXCEPTION
            WHEN OTHERS THEN
                IF SQLCODE != -27475 THEN
                    RAISE;
                END IF;
        END;
    END LOOP;

    FOR i IN 1 .. v_procedures.COUNT LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP PROCEDURE '
                || DBMS_ASSERT.SIMPLE_SQL_NAME(v_procedures(i));
            DBMS_OUTPUT.PUT_LINE('Procedimiento retirado: ' || v_procedures(i));
        EXCEPTION
            WHEN OTHERS THEN
                IF SQLCODE != -4043 THEN
                    RAISE;
                END IF;
        END;
    END LOOP;

END;
/

-- ============================================================
-- 2. PARAMETROS NUEVOS DEL MONITOREO
-- ============================================================
-- Solo se agregan si faltan: volver a ejecutar no pisa un valor ajustado.

MERGE INTO CP_PARAMETRO p
USING (
    SELECT 'SESIONES_UMBRAL_PCT' AS codigo, 'PORCENTAJE' AS unidad, '85' AS valor,
           'Porcentaje de sesiones o procesos usados (frente al limite de la instancia) que dispara la alerta.' AS descripcion
    FROM dual
    UNION ALL
    SELECT 'SESION_BLOQUEO_SEGUNDOS', 'SEGUNDOS', '60',
           'Segundos que una sesion puede esperar bloqueada por otra antes de alertar.'
    FROM dual
) n
ON (p.codigo_parametro = n.codigo)
WHEN NOT MATCHED THEN
    INSERT (codigo_parametro, modulo, tipo_dato, unidad, valor, descripcion)
    VALUES (n.codigo, 'MONITOREO', 'NUMERO', n.unidad, n.valor, n.descripcion);

COMMIT;

-- ============================================================
-- 3. TABLA CP_MONITOREO_TABLESPACE (CRECIMIENTO DE LA BASE)
-- ============================================================
-- Una muestra por tablespace en cada corrida del monitoreo diario. Guarda
-- historia, por eso solo se crea si falta y nunca se borra.

DECLARE
    v_count NUMBER;
BEGIN

    SELECT COUNT(*) INTO v_count
    FROM user_sequences WHERE sequence_name = 'SEQ_CP_MONITOREO_TABLESPACE';

    IF v_count = 0 THEN
        EXECUTE IMMEDIATE
            'CREATE SEQUENCE SEQ_CP_MONITOREO_TABLESPACE START WITH 1 INCREMENT BY 1 NOCACHE';
    END IF;

    SELECT COUNT(*) INTO v_count
    FROM user_tables WHERE table_name = 'CP_MONITOREO_TABLESPACE';

    IF v_count = 0 THEN
        EXECUTE IMMEDIATE q'[
            CREATE TABLE CP_MONITOREO_TABLESPACE (
                id_monitoreo_tablespace NUMBER
                    DEFAULT SEQ_CP_MONITOREO_TABLESPACE.NEXTVAL
                    NOT NULL,
                fecha_muestra     DATE DEFAULT SYSDATE NOT NULL,
                nombre_tablespace VARCHAR2(128) NOT NULL,
                mb_asignados      NUMBER(14,2)  NOT NULL,
                mb_usados         NUMBER(14,2)  NOT NULL,
                mb_maximos        NUMBER(14,2)  NOT NULL,
                porcentaje_uso    NUMBER(7,2),
                CONSTRAINT PK_CP_MONITOREO_TABLESPACE
                    PRIMARY KEY (id_monitoreo_tablespace)
                    USING INDEX TABLESPACE CP_POS_INDICES,
                CONSTRAINT UK_CP_MONITOREO_TABLESPACE_MUESTRA
                    UNIQUE (nombre_tablespace, fecha_muestra)
                    USING INDEX TABLESPACE CP_POS_INDICES,
                CONSTRAINT CK_CP_MONITOREO_TABLESPACE_MB
                    CHECK (mb_asignados >= 0 AND mb_usados >= 0 AND mb_maximos >= 0)
            ) TABLESPACE CP_POS_DATOS]';

        EXECUTE IMMEDIATE q'[COMMENT ON TABLE CP_MONITOREO_TABLESPACE IS
            'Muestras diarias del uso de cada tablespace para medir el crecimiento de la base (PKG_CP_MONITOREO.record_growth)']';
        EXECUTE IMMEDIATE q'[COMMENT ON COLUMN CP_MONITOREO_TABLESPACE.fecha_muestra IS
            'Momento en que se tomo la muestra']';
        EXECUTE IMMEDIATE q'[COMMENT ON COLUMN CP_MONITOREO_TABLESPACE.mb_usados IS
            'MB ocupados por segmentos en ese momento']';
        EXECUTE IMMEDIATE q'[COMMENT ON COLUMN CP_MONITOREO_TABLESPACE.mb_maximos IS
            'MB a los que puede llegar el tablespace contando el autoextend']';
        EXECUTE IMMEDIATE q'[COMMENT ON COLUMN CP_MONITOREO_TABLESPACE.porcentaje_uso IS
            'mb_usados sobre mb_maximos, en porcentaje']';
    END IF;

END;
/

-- ============================================================
-- 4. VISTAS DE APOYO
-- ============================================================
-- Cada regla vive en una vista: los paquetes y las pruebas leen la misma
-- definicion. El credito usado se calcula igual que PKG_CP_CREDITO al
-- validar el limite: suma de saldo_pendiente de las cuentas no anuladas
-- ligadas a la linea de credito.

-- Correo y nombre de cada cliente, sea persona o empresa. Se prefiere el
-- correo marcado como principal; si no hay, el primero registrado.
CREATE OR REPLACE VIEW VW_CP_CLIENTE_CORREO AS
SELECT cp.id_cliente,
       'PERSONA' AS clase_cliente,
       TRIM(REGEXP_REPLACE(p.primer_nombre || ' ' || p.segundo_nombre || ' '
                           || p.primer_apellido || ' ' || p.segundo_apellido,
                           ' {2,}', ' ')) AS nombre_cliente,
       (SELECT MIN(TRIM(c.valor_contacto))
                   KEEP (DENSE_RANK FIRST ORDER BY pc.es_principal DESC, c.id_contacto)
        FROM CP_PERSONA_CONTACTO pc
        JOIN CP_CONTACTO c
          ON c.id_contacto = pc.id_contacto
        JOIN CP_TIPO_DE_CONTACTO tc
          ON tc.id_tipo_contacto = c.id_tipo_contacto
        WHERE pc.id_persona = p.id_persona
          AND UPPER(TRIM(tc.nombre_tipo_contacto)) = 'CORREO') AS correo
FROM CP_CLIENTE_PERSONA cp
JOIN CP_PERSONA p
  ON p.id_persona = cp.id_persona
UNION ALL
SELECT ce.id_cliente,
       'EMPRESA',
       ce.razon_social,
       (SELECT MIN(TRIM(c.valor_contacto))
                   KEEP (DENSE_RANK FIRST ORDER BY ec.es_principal DESC, c.id_contacto)
        FROM CP_CLIENTE_EMPRESA_CONTACTO ec
        JOIN CP_CONTACTO c
          ON c.id_contacto = ec.id_contacto
        JOIN CP_TIPO_DE_CONTACTO tc
          ON tc.id_tipo_contacto = c.id_tipo_contacto
        WHERE ec.id_cliente_empresa = ce.id_cliente_empresa
          AND UPPER(TRIM(tc.nombre_tipo_contacto)) = 'CORREO')
FROM CP_CLIENTE_EMPRESA ce;

COMMENT ON TABLE VW_CP_CLIENTE_CORREO IS
    'Nombre y correo de cada cliente (persona o empresa) para los avisos';

CREATE OR REPLACE VIEW VW_CP_CREDITO_CLIENTE_USO AS
SELECT cc.id_credito_cliente,
       cc.id_cliente,
       cc.id_negocio,
       n.nombre_negocio,
       ec.nombre_estado_credito                                   AS estado_credito,
       cc.limite_credito,
       NVL(u.saldo_utilizado, 0)                                  AS saldo_utilizado,
       CASE WHEN cc.limite_credito > 0
            THEN ROUND(NVL(u.saldo_utilizado, 0) / cc.limite_credito * 100, 2)
       END                                                        AS porcentaje_uso,
       cv.clase_cliente,
       cv.nombre_cliente,
       cv.correo
FROM CP_CREDITO_CLIENTE cc
JOIN CP_ESTADO_CREDITO ec
  ON ec.id_estado_credito = cc.id_estado_credito
JOIN CP_NEGOCIO n
  ON n.id_negocio = cc.id_negocio
LEFT JOIN (
        SELECT cu.id_credito_cliente, SUM(cu.saldo_pendiente) AS saldo_utilizado
        FROM CP_CUENTA_COBRAR cu
        JOIN CP_ESTADO_CUENTA_COBRAR e
          ON e.id_estado_cuenta_cobrar = cu.id_estado_cuenta_cobrar
        WHERE e.nombre_estado_cuenta_cobrar <> 'ANULADA'
        GROUP BY cu.id_credito_cliente
     ) u
  ON u.id_credito_cliente = cc.id_credito_cliente
LEFT JOIN VW_CP_CLIENTE_CORREO cv
  ON cv.id_cliente = cc.id_cliente;

COMMENT ON TABLE VW_CP_CREDITO_CLIENTE_USO IS
    'Uso de cada linea de credito de cliente con la misma regla de PKG_CP_CREDITO';

CREATE OR REPLACE VIEW VW_CP_CREDITO_PROVEEDOR_USO AS
SELECT cr.id_credito_proveedor,
       cr.id_proveedor,
       pr.razon_social,
       cr.id_negocio,
       n.nombre_negocio,
       ec.nombre_estado_credito                                   AS estado_credito,
       cr.limite_credito,
       NVL(u.saldo_utilizado, 0)                                  AS saldo_utilizado,
       CASE WHEN cr.limite_credito > 0
            THEN ROUND(NVL(u.saldo_utilizado, 0) / cr.limite_credito * 100, 2)
       END                                                        AS porcentaje_uso
FROM CP_CREDITO_PROVEEDOR cr
JOIN CP_PROVEEDOR pr
  ON pr.id_proveedor = cr.id_proveedor
JOIN CP_ESTADO_CREDITO ec
  ON ec.id_estado_credito = cr.id_estado_credito
JOIN CP_NEGOCIO n
  ON n.id_negocio = cr.id_negocio
LEFT JOIN (
        SELECT cp.id_credito_proveedor, SUM(cp.saldo_pendiente) AS saldo_utilizado
        FROM CP_CUENTA_PAGAR cp
        JOIN CP_ESTADO_CUENTA_PAGAR e
          ON e.id_estado_cuenta_pagar = cp.id_estado_cuenta_pagar
        WHERE e.nombre_estado_cuenta_pagar <> 'ANULADA'
        GROUP BY cp.id_credito_proveedor
     ) u
  ON u.id_credito_proveedor = cr.id_credito_proveedor;

COMMENT ON TABLE VW_CP_CREDITO_PROVEEDOR_USO IS
    'Uso de cada linea de credito con proveedores con la misma regla de PKG_CP_CREDITO';

-- Clientes con saldo pendiente. fecha_referencia es su ultimo pago o, si
-- nunca ha pagado, la creacion de su cuenta abierta mas antigua. Los dias
-- se cuentan en el paquete, para poder probarlo con otra fecha "de hoy".
CREATE OR REPLACE VIEW VW_CP_CLIENTE_MORA AS
WITH abiertas AS (
    SELECT fv.id_cliente,
           cc.saldo_pendiente,
           cc.fecha_creacion,
           cc.fecha_vencimiento
    FROM CP_CUENTA_COBRAR cc
    JOIN CP_ESTADO_CUENTA_COBRAR e
      ON e.id_estado_cuenta_cobrar = cc.id_estado_cuenta_cobrar
    JOIN CP_FACTURA_VENTA fv
      ON fv.id_factura_venta = cc.id_factura_venta
    WHERE e.nombre_estado_cuenta_cobrar <> 'ANULADA'
      AND cc.saldo_pendiente > 0
),
pagos AS (
    SELECT fv.id_cliente,
           MAX(CAST(a.fecha_abono AS DATE)) AS ultimo_pago
    FROM CP_ABONO_CUENTA_COBRAR a
    JOIN CP_CUENTA_COBRAR cc
      ON cc.id_cuenta_cobrar = a.id_cuenta_cobrar
    JOIN CP_FACTURA_VENTA fv
      ON fv.id_factura_venta = cc.id_factura_venta
    GROUP BY fv.id_cliente
),
resumen AS (
    SELECT id_cliente,
           COUNT(*)               AS cuentas_abiertas,
           SUM(saldo_pendiente)   AS saldo_pendiente,
           MIN(fecha_vencimiento) AS vencimiento_mas_antiguo,
           MIN(fecha_creacion)    AS primera_cuenta
    FROM abiertas
    GROUP BY id_cliente
)
SELECT r.id_cliente,
       cv.nombre_cliente,
       cv.correo,
       r.cuentas_abiertas,
       r.saldo_pendiente,
       r.vencimiento_mas_antiguo,
       p.ultimo_pago,
       NVL(p.ultimo_pago, r.primera_cuenta) AS fecha_referencia
FROM resumen r
LEFT JOIN pagos p
  ON p.id_cliente = r.id_cliente
LEFT JOIN VW_CP_CLIENTE_CORREO cv
  ON cv.id_cliente = r.id_cliente;

COMMENT ON TABLE VW_CP_CLIENTE_MORA IS
    'Clientes con saldo pendiente y la fecha de su ultimo pago (base del aviso de mora)';

-- Ocupacion de cada tablespace frente a su maximo (con autoextend)
CREATE OR REPLACE VIEW VW_CP_USO_TABLESPACE AS
WITH archivos AS (
    SELECT tablespace_name,
           SUM(bytes) AS bytes_asignados,
           SUM(CASE WHEN autoextensible = 'YES'
                    THEN GREATEST(bytes, maxbytes)
                    ELSE bytes END) AS bytes_maximos
    FROM DBA_DATA_FILES
    GROUP BY tablespace_name
),
libres AS (
    SELECT tablespace_name, SUM(bytes) AS bytes_libres
    FROM DBA_FREE_SPACE
    GROUP BY tablespace_name
)
SELECT a.tablespace_name,
       ROUND(a.bytes_asignados / 1048576, 2)                            AS mb_asignados,
       ROUND((a.bytes_asignados - NVL(l.bytes_libres, 0)) / 1048576, 2) AS mb_usados,
       ROUND(a.bytes_maximos / 1048576, 2)                              AS mb_maximos,
       ROUND((a.bytes_asignados - NVL(l.bytes_libres, 0))
             / NULLIF(a.bytes_maximos, 0) * 100, 2)                     AS porcentaje_uso
FROM archivos a
LEFT JOIN libres l
  ON l.tablespace_name = a.tablespace_name;

COMMENT ON TABLE VW_CP_USO_TABLESPACE IS
    'Ocupacion actual de cada tablespace frente a su tamano maximo';

-- Crecimiento entre una muestra y la anterior del mismo tablespace
CREATE OR REPLACE VIEW VW_CP_CRECIMIENTO_TABLESPACE AS
SELECT nombre_tablespace,
       fecha_muestra,
       mb_usados,
       porcentaje_uso,
       mb_usados - LAG(mb_usados) OVER (PARTITION BY nombre_tablespace
                                         ORDER BY fecha_muestra) AS crecimiento_mb,
       fecha_muestra - LAG(fecha_muestra) OVER (PARTITION BY nombre_tablespace
                                                 ORDER BY fecha_muestra) AS dias_desde_anterior
FROM CP_MONITOREO_TABLESPACE;

COMMENT ON TABLE VW_CP_CRECIMIENTO_TABLESPACE IS
    'Crecimiento en MB de cada tablespace entre muestras consecutivas';

-- ============================================================
-- 5. PAQUETE PKG_CP_ALERTA (ESPECIFICACION)
-- ============================================================

CREATE OR REPLACE PACKAGE PKG_CP_ALERTA AUTHID DEFINER AS

    -- Tipos con que quedan los avisos en CP_NOTIFICACION
    c_type_customer_credit  CONSTANT VARCHAR2(50) := 'ALERTA_CREDITO_CLIENTE';
    c_type_supplier_coord   CONSTANT VARCHAR2(50) := 'ALERTA_CXP_COORDINADOR';
    c_type_supplier_manager CONSTANT VARCHAR2(50) := 'ALERTA_CXP_GERENTE';
    c_type_overdue          CONSTANT VARCHAR2(50) := 'ALERTA_MORA';
    c_type_overdue_customer CONSTANT VARCHAR2(50) := 'ALERTA_MORA_CLIENTE';
    c_type_expired          CONSTANT VARCHAR2(50) := 'ALERTA_PRODUCTOS_VENCIDOS';

    TYPE t_customer_credit_row IS RECORD (
        id_credito_cliente NUMBER,
        id_cliente         NUMBER,
        nombre_cliente     VARCHAR2(400),
        correo             VARCHAR2(100),
        limite_credito     NUMBER,
        saldo_utilizado    NUMBER,
        porcentaje_uso     NUMBER
    );

    TYPE t_supplier_credit_row IS RECORD (
        id_credito_proveedor NUMBER,
        id_proveedor         NUMBER,
        razon_social         VARCHAR2(150),
        nombre_negocio       VARCHAR2(100),
        limite_credito       NUMBER,
        saldo_utilizado      NUMBER,
        porcentaje_uso       NUMBER
    );

    TYPE t_overdue_row IS RECORD (
        id_cliente              NUMBER,
        nombre_cliente          VARCHAR2(400),
        correo                  VARCHAR2(100),
        cuentas_abiertas        NUMBER,
        saldo_pendiente         NUMBER,
        vencimiento_mas_antiguo DATE,
        ultimo_pago             DATE,
        fecha_referencia        DATE,
        dias_sin_pago           NUMBER
    );

    TYPE t_expired_row IS RECORD (
        nombre_sucursal   VARCHAR2(100),
        nombre_almacen    VARCHAR2(100),
        codigo_producto   VARCHAR2(30),
        nombre_producto   VARCHAR2(150),
        numero_lote       VARCHAR2(50),
        fecha_vencimiento DATE,
        cantidad          NUMBER,
        valor_costo       NUMBER
    );

    -- Listas (quien llama cierra el cursor). El porcentaje y los dias se
    -- reciben como argumento para poder probar las fronteras; los
    -- procedimientos notify_* los leen de CP_PARAMETRO.
    FUNCTION customer_credits_over(
        p_percent IN NUMBER
    ) RETURN SYS_REFCURSOR;

    FUNCTION supplier_credits_over(
        p_percent IN NUMBER
    ) RETURN SYS_REFCURSOR;

    -- Clientes con saldo pendiente y MAS de p_days dias sin pagar
    FUNCTION overdue_customers(
        p_days  IN NUMBER,
        p_today IN DATE DEFAULT TRUNC(SYSDATE)
    ) RETURN SYS_REFCURSOR;

    -- Lotes con existencia cuya fecha de vencimiento ya paso
    FUNCTION expired_lots(
        p_today IN DATE DEFAULT TRUNC(SYSDATE)
    ) RETURN SYS_REFCURSOR;

    -- Mensajes. Los reportes devuelven NULL cuando no hay nada que avisar.
    FUNCTION customer_credit_message(
        p_row     IN t_customer_credit_row,
        p_percent IN NUMBER
    ) RETURN CLOB;

    FUNCTION supplier_credit_report(
        p_percent IN NUMBER
    ) RETURN CLOB;

    FUNCTION overdue_report(
        p_days  IN NUMBER,
        p_today IN DATE DEFAULT TRUNC(SYSDATE)
    ) RETURN CLOB;

    FUNCTION overdue_customer_message(
        p_row IN t_overdue_row
    ) RETURN CLOB;

    FUNCTION expired_products_report(
        p_today IN DATE DEFAULT TRUNC(SYSDATE)
    ) RETURN CLOB;

    -- Avisos. Con p_force = FALSE no repiten un aviso que ya se encolo hoy;
    -- con p_commit = FALSE dejan el aviso sin confirmar (pruebas).
    PROCEDURE notify_customer_credit(
        p_force  IN BOOLEAN DEFAULT FALSE,
        p_commit IN BOOLEAN DEFAULT TRUE
    );

    PROCEDURE notify_supplier_credit_coordinator(
        p_force  IN BOOLEAN DEFAULT FALSE,
        p_commit IN BOOLEAN DEFAULT TRUE
    );

    PROCEDURE notify_supplier_credit_manager(
        p_force  IN BOOLEAN DEFAULT FALSE,
        p_commit IN BOOLEAN DEFAULT TRUE
    );

    -- Un solo aviso con todos los clientes en mora, al gerente y al coordinador
    PROCEDURE notify_overdue(
        p_today  IN DATE    DEFAULT TRUNC(SYSDATE),
        p_force  IN BOOLEAN DEFAULT FALSE,
        p_commit IN BOOLEAN DEFAULT TRUE
    );

    -- Un aviso a cada cliente en mora que tenga correo
    PROCEDURE notify_overdue_customers(
        p_today  IN DATE    DEFAULT TRUNC(SYSDATE),
        p_force  IN BOOLEAN DEFAULT FALSE,
        p_commit IN BOOLEAN DEFAULT TRUE
    );

    PROCEDURE notify_expired_products(
        p_today  IN DATE    DEFAULT TRUNC(SYSDATE),
        p_force  IN BOOLEAN DEFAULT FALSE,
        p_commit IN BOOLEAN DEFAULT TRUE
    );

    -- Todos los avisos; uno que falle no detiene a los demas. Lo ejecuta
    -- JOB_CP_ALERTAS_NEGOCIO y el profesor a peticion.
    PROCEDURE run_daily(
        p_force IN BOOLEAN DEFAULT FALSE
    );

END PKG_CP_ALERTA;
/

-- ============================================================
-- 6. PAQUETE PKG_CP_ALERTA (CUERPO)
-- ============================================================

CREATE OR REPLACE PACKAGE BODY PKG_CP_ALERTA AS

    c_modulo CONSTANT VARCHAR2(20) := 'ALERTA';

    c_err_percent CONSTANT PLS_INTEGER := -20380;
    c_err_days    CONSTANT PLS_INTEGER := -20381;

    -- Maximo de lineas por reporte; los totales siempre son completos
    c_max_lines CONSTANT PLS_INTEGER := 200;

    c_lf CONSTANT VARCHAR2(1) := CHR(10);


    FUNCTION fmt_amount(
        p_value IN NUMBER
    ) RETURN VARCHAR2
    IS
    BEGIN
        RETURN TO_CHAR(NVL(p_value, 0), 'FM999,999,999,990.00',
                       'NLS_NUMERIC_CHARACTERS=''.,''');
    END fmt_amount;


    FUNCTION fmt_percent(
        p_value IN NUMBER
    ) RETURN VARCHAR2
    IS
    BEGIN
        RETURN TO_CHAR(NVL(p_value, 0), 'FM999990.00',
                       'NLS_NUMERIC_CHARACTERS=''.,''');
    END fmt_percent;


    FUNCTION fmt_date(
        p_value IN DATE
    ) RETURN VARCHAR2
    IS
    BEGIN
        RETURN TO_CHAR(p_value, 'DD/MM/YYYY');
    END fmt_date;


    -- Un porcentaje en 0 avisaria a todos y uno negativo no tiene sentido
    FUNCTION percent_parameter(
        p_codigo IN VARCHAR2
    ) RETURN NUMBER
    IS
        v_value NUMBER := PKG_CP_PARAMETRO.obtener_numero(p_codigo);
    BEGIN
        IF v_value IS NULL OR v_value <= 0 THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_percent,
                'El parametro ' || p_codigo || ' debe ser un porcentaje mayor que cero.'
            );
        END IF;
        RETURN v_value;
    END percent_parameter;


    FUNCTION days_parameter RETURN NUMBER
    IS
        v_value NUMBER := PKG_CP_PARAMETRO.obtener_numero('MOROSIDAD_DIAS_SIN_PAGO');
    BEGIN
        IF v_value IS NULL OR v_value < 1 OR v_value <> TRUNC(v_value) THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_days,
                'El parametro MOROSIDAD_DIAS_SIN_PAGO debe ser un entero mayor que cero.'
            );
        END IF;
        RETURN v_value;
    END days_parameter;


    -- Encola un reporte para el correo de avisos (gerente y coordinador).
    -- Un reporte NULL significa que no hay nada que avisar.
    PROCEDURE send_report(
        p_type    IN VARCHAR2,
        p_subject IN VARCHAR2,
        p_report  IN CLOB,
        p_force   IN BOOLEAN
    )
    IS
    BEGIN
        IF p_report IS NULL THEN
            RETURN;
        END IF;

        IF NOT p_force AND PKG_CP_AVISO.already_queued(p_type) THEN
            RETURN;
        END IF;

        PKG_CP_AVISO.queue_notice(
            p_type    => p_type,
            p_subject => p_subject,
            p_message => p_report
        );
    END send_report;


    FUNCTION customer_credits_over(
        p_percent IN NUMBER
    ) RETURN SYS_REFCURSOR
    IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        -- Se compara el saldo con el limite (no el porcentaje redondeado)
        OPEN v_cursor FOR
            SELECT u.id_credito_cliente,
                   u.id_cliente,
                   u.nombre_cliente,
                   u.correo,
                   u.limite_credito,
                   u.saldo_utilizado,
                   u.porcentaje_uso
            FROM VW_CP_CREDITO_CLIENTE_USO u
            WHERE u.estado_credito = 'ACTIVO'
              AND u.limite_credito > 0
              AND u.saldo_utilizado > 0
              AND u.saldo_utilizado >= u.limite_credito * p_percent / 100
            ORDER BY u.saldo_utilizado / u.limite_credito DESC, u.id_credito_cliente;

        RETURN v_cursor;
    END customer_credits_over;


    FUNCTION supplier_credits_over(
        p_percent IN NUMBER
    ) RETURN SYS_REFCURSOR
    IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
            SELECT u.id_credito_proveedor,
                   u.id_proveedor,
                   u.razon_social,
                   u.nombre_negocio,
                   u.limite_credito,
                   u.saldo_utilizado,
                   u.porcentaje_uso
            FROM VW_CP_CREDITO_PROVEEDOR_USO u
            WHERE u.estado_credito = 'ACTIVO'
              AND u.limite_credito > 0
              AND u.saldo_utilizado > 0
              AND u.saldo_utilizado >= u.limite_credito * p_percent / 100
            ORDER BY u.saldo_utilizado / u.limite_credito DESC, u.id_credito_proveedor;

        RETURN v_cursor;
    END supplier_credits_over;


    FUNCTION overdue_customers(
        p_days  IN NUMBER,
        p_today IN DATE DEFAULT TRUNC(SYSDATE)
    ) RETURN SYS_REFCURSOR
    IS
        v_cursor SYS_REFCURSOR;
        v_today  DATE := TRUNC(p_today);
    BEGIN
        OPEN v_cursor FOR
            SELECT m.id_cliente,
                   m.nombre_cliente,
                   m.correo,
                   m.cuentas_abiertas,
                   m.saldo_pendiente,
                   m.vencimiento_mas_antiguo,
                   m.ultimo_pago,
                   m.fecha_referencia,
                   v_today - TRUNC(m.fecha_referencia) AS dias_sin_pago
            FROM VW_CP_CLIENTE_MORA m
            WHERE v_today - TRUNC(m.fecha_referencia) > p_days
            ORDER BY m.fecha_referencia, m.id_cliente;

        RETURN v_cursor;
    END overdue_customers;


    FUNCTION expired_lots(
        p_today IN DATE DEFAULT TRUNC(SYSDATE)
    ) RETURN SYS_REFCURSOR
    IS
        v_cursor SYS_REFCURSOR;
        v_today  DATE := TRUNC(p_today);
    BEGIN
        OPEN v_cursor FOR
            SELECT s.nombre_sucursal,
                   a.nombre_almacen,
                   p.codigo_producto,
                   p.nombre_producto,
                   lp.numero_lote,
                   lp.fecha_vencimiento,
                   ia.cantidad_actual,
                   ia.cantidad_actual * dc.precio_costo_unitario
            FROM CP_INVENTARIO_ALMACEN ia
            JOIN CP_ALMACEN a
              ON a.id_almacen = ia.id_almacen
            JOIN CP_SUCURSAL s
              ON s.id_sucursal = a.id_sucursal
            JOIN CP_LOTE_PRODUCTO lp
              ON lp.id_lote_producto = ia.id_lote_producto
            JOIN CP_DETALLE_COMPRA dc
              ON dc.id_detalle_compra = lp.id_detalle_compra
            JOIN CP_PRODUCTO_PROVEEDOR pp
              ON pp.id_producto_proveedor = dc.id_producto_proveedor
            JOIN CP_PRODUCTO p
              ON p.id_producto = pp.id_producto
            WHERE lp.fecha_vencimiento < v_today
              AND ia.cantidad_actual > 0
            ORDER BY lp.fecha_vencimiento, s.nombre_sucursal, p.nombre_producto, lp.numero_lote;

        RETURN v_cursor;
    END expired_lots;


    FUNCTION customer_credit_message(
        p_row     IN t_customer_credit_row,
        p_percent IN NUMBER
    ) RETURN CLOB
    IS
    BEGIN
        RETURN 'Estimado(a) ' || NVL(p_row.nombre_cliente, 'cliente') || ':' || c_lf || c_lf
            || 'Su credito numero ' || p_row.id_credito_cliente
            || ' tiene un uso del ' || fmt_percent(p_row.porcentaje_uso)
            || '% de su limite.' || c_lf || c_lf
            || 'Limite de credito: ' || fmt_amount(p_row.limite_credito) || c_lf
            || 'Saldo utilizado:   ' || fmt_amount(p_row.saldo_utilizado) || c_lf
            || 'Disponible:        '
            || fmt_amount(GREATEST(p_row.limite_credito - p_row.saldo_utilizado, 0)) || c_lf || c_lf
            || 'Le avisamos porque su saldo alcanzo el ' || fmt_percent(p_percent)
            || '% de su limite de credito.' || c_lf
            || 'Mensaje automatico del sistema CP-POS.';
    END customer_credit_message;


    FUNCTION supplier_credit_report(
        p_percent IN NUMBER
    ) RETURN CLOB
    IS
        v_cursor SYS_REFCURSOR;
        v_row    t_supplier_credit_row;
        v_text   CLOB;
        v_count  PLS_INTEGER := 0;
        v_total  NUMBER := 0;
    BEGIN
        v_cursor := supplier_credits_over(p_percent);

        LOOP
            FETCH v_cursor INTO v_row;
            EXIT WHEN v_cursor%NOTFOUND;

            v_count := v_count + 1;
            v_total := v_total + v_row.saldo_utilizado;

            IF v_count <= c_max_lines THEN
                v_text := v_text
                    || 'Credito ' || v_row.id_credito_proveedor
                    || ' | ' || v_row.razon_social
                    || ' (' || v_row.nombre_negocio || ')'
                    || ' | limite ' || fmt_amount(v_row.limite_credito)
                    || ' | saldo ' || fmt_amount(v_row.saldo_utilizado)
                    || ' | uso ' || fmt_percent(v_row.porcentaje_uso) || '%' || c_lf;
            END IF;
        END LOOP;

        CLOSE v_cursor;

        IF v_count = 0 THEN
            RETURN NULL;
        END IF;

        IF v_count > c_max_lines THEN
            v_text := v_text || '... y ' || (v_count - c_max_lines) || ' mas' || c_lf;
        END IF;

        RETURN 'Proveedores que usan el ' || fmt_percent(p_percent)
            || '% o mas de su limite de credito' || c_lf
            || 'Fecha: ' || fmt_date(SYSDATE) || c_lf || c_lf
            || v_text || c_lf
            || 'Total de proveedores: ' || v_count || c_lf
            || 'Saldo total por pagar: ' || fmt_amount(v_total);
    EXCEPTION
        WHEN OTHERS THEN
            IF v_cursor%ISOPEN THEN
                CLOSE v_cursor;
            END IF;
            RAISE;
    END supplier_credit_report;


    FUNCTION overdue_report(
        p_days  IN NUMBER,
        p_today IN DATE DEFAULT TRUNC(SYSDATE)
    ) RETURN CLOB
    IS
        v_cursor SYS_REFCURSOR;
        v_row    t_overdue_row;
        v_text   CLOB;
        v_count  PLS_INTEGER := 0;
        v_total  NUMBER := 0;
    BEGIN
        v_cursor := overdue_customers(p_days, p_today);

        LOOP
            FETCH v_cursor INTO v_row;
            EXIT WHEN v_cursor%NOTFOUND;

            v_count := v_count + 1;
            v_total := v_total + v_row.saldo_pendiente;

            IF v_count <= c_max_lines THEN
                v_text := v_text
                    || 'ID cliente: ' || v_row.id_cliente
                    || ' | ' || NVL(v_row.nombre_cliente, '(sin nombre)')
                    || ' | cuentas abiertas ' || v_row.cuentas_abiertas
                    || ' | saldo ' || fmt_amount(v_row.saldo_pendiente)
                    || ' | ' || CASE WHEN v_row.ultimo_pago IS NULL
                                     THEN 'sin pagos (cuenta del ' || fmt_date(v_row.fecha_referencia) || ')'
                                     ELSE 'ultimo pago ' || fmt_date(v_row.ultimo_pago)
                                END
                    || ' | ' || v_row.dias_sin_pago || ' dias sin pagar' || c_lf;
            END IF;
        END LOOP;

        CLOSE v_cursor;

        IF v_count = 0 THEN
            RETURN NULL;
        END IF;

        IF v_count > c_max_lines THEN
            v_text := v_text || '... y ' || (v_count - c_max_lines) || ' mas' || c_lf;
        END IF;

        RETURN 'Clientes en mora: saldo pendiente y mas de ' || p_days
            || ' dias desde su ultimo pago' || c_lf
            || 'Para: gerente y coordinador' || c_lf
            || 'Fecha: ' || fmt_date(p_today) || c_lf || c_lf
            || v_text || c_lf
            || 'Total de clientes en mora: ' || v_count || c_lf
            || 'Saldo total pendiente: ' || fmt_amount(v_total);
    EXCEPTION
        WHEN OTHERS THEN
            IF v_cursor%ISOPEN THEN
                CLOSE v_cursor;
            END IF;
            RAISE;
    END overdue_report;


    FUNCTION overdue_customer_message(
        p_row IN t_overdue_row
    ) RETURN CLOB
    IS
    BEGIN
        RETURN 'Estimado(a) ' || NVL(p_row.nombre_cliente, 'cliente') || ':' || c_lf || c_lf
            || 'Registramos un saldo pendiente de ' || fmt_amount(p_row.saldo_pendiente)
            || ' en ' || p_row.cuentas_abiertas || ' cuenta(s).' || c_lf
            || CASE WHEN p_row.ultimo_pago IS NULL
                    THEN 'No tenemos pagos registrados a su nombre desde el '
                         || fmt_date(p_row.fecha_referencia) || '.'
                    ELSE 'Su ultimo pago fue el ' || fmt_date(p_row.ultimo_pago) || '.'
               END || c_lf || c_lf
            || 'Por favor comuniquese con nosotros para ponerse al dia.' || c_lf
            || 'Mensaje automatico del sistema CP-POS.';
    END overdue_customer_message;


    FUNCTION expired_products_report(
        p_today IN DATE DEFAULT TRUNC(SYSDATE)
    ) RETURN CLOB
    IS
        TYPE t_seen IS TABLE OF BOOLEAN INDEX BY VARCHAR2(30);

        v_cursor   SYS_REFCURSOR;
        v_row      t_expired_row;
        v_products t_seen;
        v_text     CLOB;
        v_count    PLS_INTEGER := 0;
        v_units    NUMBER := 0;
        v_value    NUMBER := 0;
    BEGIN
        v_cursor := expired_lots(p_today);

        LOOP
            FETCH v_cursor INTO v_row;
            EXIT WHEN v_cursor%NOTFOUND;

            v_count := v_count + 1;
            v_units := v_units + v_row.cantidad;
            v_value := v_value + NVL(v_row.valor_costo, 0);
            v_products(v_row.codigo_producto) := TRUE;

            IF v_count <= c_max_lines THEN
                v_text := v_text
                    || v_row.nombre_sucursal || ' / ' || v_row.nombre_almacen
                    || ' | ' || v_row.codigo_producto || ' - ' || v_row.nombre_producto
                    || ' | lote ' || v_row.numero_lote
                    || ' | vencio el ' || fmt_date(v_row.fecha_vencimiento)
                    || ' | ' || fmt_amount(v_row.cantidad) || ' unidades'
                    || ' | costo ' || fmt_amount(v_row.valor_costo) || c_lf;
            END IF;
        END LOOP;

        CLOSE v_cursor;

        IF v_count = 0 THEN
            RETURN NULL;
        END IF;

        IF v_count > c_max_lines THEN
            v_text := v_text || '... y ' || (v_count - c_max_lines) || ' mas' || c_lf;
        END IF;

        RETURN 'Productos vencidos en inventario' || c_lf
            || 'Para: coordinador' || c_lf
            || 'Fecha: ' || fmt_date(p_today) || c_lf || c_lf
            || v_text || c_lf
            || 'TOTAL' || c_lf
            || 'Lotes vencidos con existencia: ' || v_count || c_lf
            || 'Productos distintos: ' || v_products.COUNT || c_lf
            || 'Unidades vencidas: ' || fmt_amount(v_units) || c_lf
            || 'Valor al costo: ' || fmt_amount(v_value);
    EXCEPTION
        WHEN OTHERS THEN
            IF v_cursor%ISOPEN THEN
                CLOSE v_cursor;
            END IF;
            RAISE;
    END expired_products_report;


    PROCEDURE notify_customer_credit(
        p_force  IN BOOLEAN DEFAULT FALSE,
        p_commit IN BOOLEAN DEFAULT TRUE
    )
    IS
        v_percent NUMBER;
        v_cursor  SYS_REFCURSOR;
        v_row     t_customer_credit_row;
        v_subject VARCHAR2(200);
    BEGIN

        SAVEPOINT sp_notify_customer_credit;

        v_percent := percent_parameter('UMBRAL_CXC_CLIENTE_PCT');
        v_cursor := customer_credits_over(v_percent);

        LOOP
            FETCH v_cursor INTO v_row;
            EXIT WHEN v_cursor%NOTFOUND;

            -- Un cliente sin correo no se puede avisar; queda en el reporte
            -- de la vista VW_CP_CREDITO_CLIENTE_USO
            IF v_row.correo IS NOT NULL THEN
                v_subject := 'Aviso del uso de su credito ' || v_row.id_credito_cliente;

                IF p_force OR NOT PKG_CP_AVISO.already_queued(c_type_customer_credit, v_subject) THEN
                    PKG_CP_AVISO.queue_notice_to(
                        p_type    => c_type_customer_credit,
                        p_subject => v_subject,
                        p_message => customer_credit_message(v_row, v_percent),
                        p_mail    => v_row.correo
                    );
                END IF;
            END IF;
        END LOOP;

        CLOSE v_cursor;

        IF p_commit THEN
            COMMIT;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            IF v_cursor%ISOPEN THEN
                CLOSE v_cursor;
            END IF;
            ROLLBACK TO SAVEPOINT sp_notify_customer_credit;
            PKG_CP_ERROR.registrar_inesperado(c_modulo, 'notify_customer_credit');
            RAISE;
    END notify_customer_credit;


    PROCEDURE notify_supplier_credit_coordinator(
        p_force  IN BOOLEAN DEFAULT FALSE,
        p_commit IN BOOLEAN DEFAULT TRUE
    )
    IS
        v_percent NUMBER;
    BEGIN

        SAVEPOINT sp_notify_supplier_coord;

        v_percent := percent_parameter('UMBRAL_CXP_COORDINADOR_PCT');

        send_report(
            p_type    => c_type_supplier_coord,
            p_subject => 'CP-POS: proveedores con el ' || fmt_percent(v_percent)
                         || '% o mas de su credito (coordinador)',
            p_report  => supplier_credit_report(v_percent),
            p_force   => p_force
        );

        IF p_commit THEN
            COMMIT;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK TO SAVEPOINT sp_notify_supplier_coord;
            PKG_CP_ERROR.registrar_inesperado(c_modulo, 'notify_supplier_credit_coordinator');
            RAISE;
    END notify_supplier_credit_coordinator;


    PROCEDURE notify_supplier_credit_manager(
        p_force  IN BOOLEAN DEFAULT FALSE,
        p_commit IN BOOLEAN DEFAULT TRUE
    )
    IS
        v_percent NUMBER;
    BEGIN

        SAVEPOINT sp_notify_supplier_manager;

        v_percent := percent_parameter('UMBRAL_CXP_GERENTE_PCT');

        send_report(
            p_type    => c_type_supplier_manager,
            p_subject => 'CP-POS: proveedores con el ' || fmt_percent(v_percent)
                         || '% o mas de su credito (gerente)',
            p_report  => supplier_credit_report(v_percent),
            p_force   => p_force
        );

        IF p_commit THEN
            COMMIT;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK TO SAVEPOINT sp_notify_supplier_manager;
            PKG_CP_ERROR.registrar_inesperado(c_modulo, 'notify_supplier_credit_manager');
            RAISE;
    END notify_supplier_credit_manager;


    PROCEDURE notify_overdue(
        p_today  IN DATE    DEFAULT TRUNC(SYSDATE),
        p_force  IN BOOLEAN DEFAULT FALSE,
        p_commit IN BOOLEAN DEFAULT TRUE
    )
    IS
        v_days NUMBER;
    BEGIN

        SAVEPOINT sp_notify_overdue;

        v_days := days_parameter;

        send_report(
            p_type    => c_type_overdue,
            p_subject => 'CP-POS: clientes en mora del ' || fmt_date(p_today)
                         || ' (gerente y coordinador)',
            p_report  => overdue_report(v_days, p_today),
            p_force   => p_force
        );

        IF p_commit THEN
            COMMIT;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK TO SAVEPOINT sp_notify_overdue;
            PKG_CP_ERROR.registrar_inesperado(c_modulo, 'notify_overdue');
            RAISE;
    END notify_overdue;


    PROCEDURE notify_overdue_customers(
        p_today  IN DATE    DEFAULT TRUNC(SYSDATE),
        p_force  IN BOOLEAN DEFAULT FALSE,
        p_commit IN BOOLEAN DEFAULT TRUE
    )
    IS
        v_days    NUMBER;
        v_cursor  SYS_REFCURSOR;
        v_row     t_overdue_row;
        v_subject VARCHAR2(200);
    BEGIN

        SAVEPOINT sp_notify_overdue_customers;

        v_days := days_parameter;
        v_cursor := overdue_customers(v_days, p_today);

        LOOP
            FETCH v_cursor INTO v_row;
            EXIT WHEN v_cursor%NOTFOUND;

            IF v_row.correo IS NOT NULL THEN
                v_subject := 'Aviso de saldo pendiente - cliente ' || v_row.id_cliente;

                IF p_force OR NOT PKG_CP_AVISO.already_queued(c_type_overdue_customer, v_subject) THEN
                    PKG_CP_AVISO.queue_notice_to(
                        p_type    => c_type_overdue_customer,
                        p_subject => v_subject,
                        p_message => overdue_customer_message(v_row),
                        p_mail    => v_row.correo
                    );
                END IF;
            END IF;
        END LOOP;

        CLOSE v_cursor;

        IF p_commit THEN
            COMMIT;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            IF v_cursor%ISOPEN THEN
                CLOSE v_cursor;
            END IF;
            ROLLBACK TO SAVEPOINT sp_notify_overdue_customers;
            PKG_CP_ERROR.registrar_inesperado(c_modulo, 'notify_overdue_customers');
            RAISE;
    END notify_overdue_customers;


    PROCEDURE notify_expired_products(
        p_today  IN DATE    DEFAULT TRUNC(SYSDATE),
        p_force  IN BOOLEAN DEFAULT FALSE,
        p_commit IN BOOLEAN DEFAULT TRUE
    )
    IS
    BEGIN

        SAVEPOINT sp_notify_expired;

        send_report(
            p_type    => c_type_expired,
            p_subject => 'CP-POS: productos vencidos en inventario al ' || fmt_date(p_today),
            p_report  => expired_products_report(p_today),
            p_force   => p_force
        );

        IF p_commit THEN
            COMMIT;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK TO SAVEPOINT sp_notify_expired;
            PKG_CP_ERROR.registrar_inesperado(c_modulo, 'notify_expired_products');
            RAISE;
    END notify_expired_products;


    -- Cada aviso confirma lo suyo. Si uno falla, su error ya quedo en la
    -- bitacora (lo registro el propio aviso) y se sigue con el siguiente.
    PROCEDURE run_daily(
        p_force IN BOOLEAN DEFAULT FALSE
    )
    IS
    BEGIN
        BEGIN notify_customer_credit(p_force);             EXCEPTION WHEN OTHERS THEN NULL; END;
        BEGIN notify_supplier_credit_coordinator(p_force); EXCEPTION WHEN OTHERS THEN NULL; END;
        BEGIN notify_supplier_credit_manager(p_force);     EXCEPTION WHEN OTHERS THEN NULL; END;
        BEGIN notify_overdue(TRUNC(SYSDATE), p_force);     EXCEPTION WHEN OTHERS THEN NULL; END;
        BEGIN notify_overdue_customers(TRUNC(SYSDATE), p_force); EXCEPTION WHEN OTHERS THEN NULL; END;
        BEGIN notify_expired_products(TRUNC(SYSDATE), p_force);  EXCEPTION WHEN OTHERS THEN NULL; END;
    END run_daily;

END PKG_CP_ALERTA;
/

SHOW ERRORS PACKAGE BODY PKG_CP_ALERTA

-- ============================================================
-- 7. PAQUETE PKG_CP_MONITOREO (ESPECIFICACION)
-- ============================================================

CREATE OR REPLACE PACKAGE PKG_CP_MONITOREO AUTHID DEFINER AS

    c_type_tablespace CONSTANT VARCHAR2(50) := 'MONITOREO_TABLESPACES';
    c_type_invalid    CONSTANT VARCHAR2(50) := 'MONITOREO_OBJETOS_INVALIDOS';
    c_type_index      CONSTANT VARCHAR2(50) := 'MONITOREO_INDICES';
    c_type_session    CONSTANT VARCHAR2(50) := 'MONITOREO_SESIONES';
    c_type_error      CONSTANT VARCHAR2(50) := 'MONITOREO_ERRORES';

    -- Reportes: devuelven NULL cuando no hay nada que avisar
    FUNCTION tablespace_report(
        p_percent IN NUMBER
    ) RETURN CLOB;

    FUNCTION invalid_objects_report RETURN CLOB;

    FUNCTION unusable_indexes_report RETURN CLOB;

    FUNCTION sessions_report(
        p_percent       IN NUMBER,
        p_block_seconds IN NUMBER
    ) RETURN CLOB;

    FUNCTION errors_report(
        p_since IN DATE
    ) RETURN CLOB;

    -- Crecimiento de cada tablespace en los ultimos 30 dias y tamano del
    -- esquema; siempre devuelve texto (informativo)
    FUNCTION growth_report RETURN CLOB;

    -- Toma una muestra de cada tablespace en CP_MONITOREO_TABLESPACE
    PROCEDURE record_growth(
        p_commit IN BOOLEAN DEFAULT TRUE
    );

    -- Controles. Con p_force = FALSE no repiten un aviso ya encolado en el
    -- periodo (el dia; una hora para las sesiones).
    PROCEDURE check_tablespaces(
        p_force  IN BOOLEAN DEFAULT FALSE,
        p_commit IN BOOLEAN DEFAULT TRUE
    );

    PROCEDURE check_invalid_objects(
        p_force  IN BOOLEAN DEFAULT FALSE,
        p_commit IN BOOLEAN DEFAULT TRUE
    );

    PROCEDURE check_indexes(
        p_force  IN BOOLEAN DEFAULT FALSE,
        p_commit IN BOOLEAN DEFAULT TRUE
    );

    PROCEDURE check_sessions(
        p_force  IN BOOLEAN DEFAULT FALSE,
        p_commit IN BOOLEAN DEFAULT TRUE
    );

    -- Errores registrados en CP_BITACORA_ERROR en las ultimas 24 horas
    PROCEDURE check_errors(
        p_force  IN BOOLEAN DEFAULT FALSE,
        p_commit IN BOOLEAN DEFAULT TRUE
    );

    -- Muestra de crecimiento y los cuatro controles diarios; uno que falle
    -- no detiene a los demas. Lo ejecuta JOB_CP_MONITOREO_DIARIO.
    PROCEDURE run_daily(
        p_force IN BOOLEAN DEFAULT FALSE
    );

END PKG_CP_MONITOREO;
/

-- ============================================================
-- 8. PAQUETE PKG_CP_MONITOREO (CUERPO)
-- ============================================================
-- Lee vistas del diccionario (DBA_DATA_FILES, DBA_FREE_SPACE, V$SESSION,
-- V$PROCESS y V$PARAMETER). Por ser AUTHID DEFINER solo cuentan los permisos
-- dados directamente a CP_POS (seccion 10 de CP_usuario_esquema.sql).

CREATE OR REPLACE PACKAGE BODY PKG_CP_MONITOREO AS

    c_modulo CONSTANT VARCHAR2(20) := 'MONITOREO';

    c_err_parameter CONSTANT PLS_INTEGER := -20390;

    c_growth_days     CONSTANT PLS_INTEGER := 30;
    c_session_repeat  CONSTANT NUMBER := 1 / 24;
    c_error_window    CONSTANT NUMBER := 1;
    c_max_lines       CONSTANT PLS_INTEGER := 200;

    c_lf CONSTANT VARCHAR2(1) := CHR(10);


    FUNCTION fmt_number(
        p_value IN NUMBER
    ) RETURN VARCHAR2
    IS
    BEGIN
        RETURN TO_CHAR(NVL(p_value, 0), 'FM999,999,999,990.00',
                       'NLS_NUMERIC_CHARACTERS=''.,''');
    END fmt_number;


    FUNCTION build_header(
        p_title IN VARCHAR2
    ) RETURN VARCHAR2
    IS
    BEGIN
        RETURN p_title || c_lf
            || 'Base de datos: ' || SYS_CONTEXT('USERENV', 'DB_NAME')
            || ' / contenedor ' || SYS_CONTEXT('USERENV', 'CON_NAME') || c_lf
            || 'Fecha: ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI') || c_lf || c_lf;
    END build_header;


    FUNCTION positive_parameter(
        p_codigo  IN VARCHAR2,
        p_integer IN BOOLEAN
    ) RETURN NUMBER
    IS
        v_value NUMBER := PKG_CP_PARAMETRO.obtener_numero(p_codigo);
    BEGIN
        IF v_value IS NULL OR v_value <= 0
           OR (p_integer AND v_value <> TRUNC(v_value)) THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_parameter,
                'El parametro ' || p_codigo || ' debe ser '
                || CASE WHEN p_integer THEN 'un entero ' ELSE 'un numero ' END
                || 'mayor que cero.'
            );
        END IF;
        RETURN v_value;
    END positive_parameter;


    PROCEDURE send_check(
        p_type    IN VARCHAR2,
        p_subject IN VARCHAR2,
        p_report  IN CLOB,
        p_force   IN BOOLEAN,
        p_since   IN DATE
    )
    IS
    BEGIN
        IF p_report IS NULL THEN
            RETURN;
        END IF;

        IF NOT p_force AND PKG_CP_AVISO.already_queued(p_type, NULL, p_since) THEN
            RETURN;
        END IF;

        PKG_CP_AVISO.queue_notice(
            p_type    => p_type,
            p_subject => p_subject,
            p_message => p_report
        );
    END send_check;


    FUNCTION growth_report RETURN CLOB
    IS
        v_text   CLOB;
        v_schema NUMBER;
        v_count  PLS_INTEGER := 0;
    BEGIN
        SELECT ROUND(NVL(SUM(bytes), 0) / 1048576, 2)
        INTO v_schema
        FROM USER_SEGMENTS;

        v_text := 'Crecimiento de los tablespaces (ultimos ' || c_growth_days || ' dias)' || c_lf;

        FOR r IN (
            SELECT nombre_tablespace,
                   MAX(mb_usados) KEEP (DENSE_RANK LAST ORDER BY fecha_muestra)  AS mb_actual,
                   MIN(mb_usados) KEEP (DENSE_RANK FIRST ORDER BY fecha_muestra) AS mb_inicial,
                   MAX(fecha_muestra) - MIN(fecha_muestra)                         AS dias
            FROM CP_MONITOREO_TABLESPACE
            WHERE fecha_muestra >= SYSDATE - c_growth_days
            GROUP BY nombre_tablespace
            ORDER BY nombre_tablespace
        ) LOOP
            v_count := v_count + 1;
            v_text := v_text || r.nombre_tablespace || ': '
                || fmt_number(r.mb_actual) || ' MB usados; '
                || CASE WHEN r.dias > 0
                        THEN 'crecio ' || fmt_number(r.mb_actual - r.mb_inicial)
                             || ' MB en ' || fmt_number(r.dias) || ' dias ('
                             || fmt_number((r.mb_actual - r.mb_inicial) / r.dias)
                             || ' MB por dia)'
                        ELSE 'una sola muestra, todavia no hay crecimiento que medir'
                   END || c_lf;
        END LOOP;

        IF v_count = 0 THEN
            v_text := v_text || 'Todavia no hay muestras: las toma el monitoreo diario.' || c_lf;
        END IF;

        RETURN v_text || 'Tamano actual del esquema CP_POS: ' || fmt_number(v_schema) || ' MB';
    END growth_report;


    FUNCTION tablespace_report(
        p_percent IN NUMBER
    ) RETURN CLOB
    IS
        v_text  CLOB;
        v_count PLS_INTEGER := 0;
    BEGIN
        FOR r IN (
            SELECT tablespace_name, mb_usados, mb_maximos, porcentaje_uso
            FROM VW_CP_USO_TABLESPACE
            WHERE porcentaje_uso >= p_percent
            ORDER BY porcentaje_uso DESC, tablespace_name
        ) LOOP
            v_count := v_count + 1;
            v_text := v_text || 'Tablespace ' || r.tablespace_name || ': '
                || fmt_number(r.porcentaje_uso) || '% usado ('
                || fmt_number(r.mb_usados) || ' MB de ' || fmt_number(r.mb_maximos)
                || ' MB)' || c_lf;
        END LOOP;

        IF v_count = 0 THEN
            RETURN NULL;
        END IF;

        RETURN build_header('Tablespaces al ' || fmt_number(p_percent) || '% o mas de su tamano maximo')
            || v_text || c_lf
            || 'Total de tablespaces: ' || v_count || c_lf || c_lf
            || growth_report;
    END tablespace_report;


    FUNCTION invalid_objects_report RETURN CLOB
    IS
        v_text  CLOB;
        v_count PLS_INTEGER := 0;
    BEGIN
        FOR r IN (
            SELECT object_type, object_name, last_ddl_time
            FROM USER_OBJECTS
            WHERE status = 'INVALID'
            ORDER BY object_type, object_name
        ) LOOP
            v_count := v_count + 1;
            IF v_count <= c_max_lines THEN
                v_text := v_text || r.object_type || ' ' || r.object_name
                    || ' (ultimo cambio ' || TO_CHAR(r.last_ddl_time, 'DD/MM/YYYY HH24:MI') || ')' || c_lf;
            END IF;
        END LOOP;

        IF v_count = 0 THEN
            RETURN NULL;
        END IF;

        RETURN build_header('Objetos invalidos en el esquema ' || USER)
            || v_text || c_lf
            || 'Total de objetos invalidos: ' || v_count || c_lf
            || 'Sugerencia: EXEC DBMS_UTILITY.COMPILE_SCHEMA(USER, FALSE) y revisar USER_ERRORS.';
    END invalid_objects_report;


    FUNCTION unusable_indexes_report RETURN CLOB
    IS
        v_text  CLOB;
        v_count PLS_INTEGER := 0;
    BEGIN
        FOR r IN (
            SELECT 'INDICE' AS tipo, index_name AS nombre, table_name AS tabla
            FROM USER_INDEXES
            WHERE status = 'UNUSABLE'
            UNION ALL
            SELECT 'PARTICION', index_name || '.' || partition_name, NULL
            FROM USER_IND_PARTITIONS
            WHERE status = 'UNUSABLE'
            UNION ALL
            SELECT 'SUBPARTICION', index_name || '.' || subpartition_name, NULL
            FROM USER_IND_SUBPARTITIONS
            WHERE status = 'UNUSABLE'
            ORDER BY 1, 2
        ) LOOP
            v_count := v_count + 1;
            IF v_count <= c_max_lines THEN
                v_text := v_text || r.tipo || ' ' || r.nombre
                    || CASE WHEN r.tabla IS NOT NULL THEN ' de la tabla ' || r.tabla END || c_lf;
            END IF;
        END LOOP;

        IF v_count = 0 THEN
            RETURN NULL;
        END IF;

        RETURN build_header('Indices inutilizables (UNUSABLE) en el esquema ' || USER)
            || v_text || c_lf
            || 'Total: ' || v_count || c_lf
            || 'Sugerencia: ALTER INDEX <nombre> REBUILD;';
    END unusable_indexes_report;


    FUNCTION sessions_report(
        p_percent       IN NUMBER,
        p_block_seconds IN NUMBER
    ) RETURN CLOB
    IS
        v_text     CLOB;
        v_count    PLS_INTEGER := 0;
        v_sessions NUMBER;
    BEGIN
        -- El limite sale de V$PARAMETER y el uso se cuenta en V$SESSION y
        -- V$PROCESS. No se usa V$RESOURCE_LIMIT porque dentro de una PDB no
        -- informa limites (en XEPDB1 devuelve UNLIMITED o nada).
        FOR r IN (
            SELECT 'sessions' AS resource_name,
                   (SELECT COUNT(*) FROM V$SESSION) AS en_uso,
                   (SELECT TO_NUMBER(TRIM(value) DEFAULT NULL ON CONVERSION ERROR)
                    FROM V$PARAMETER WHERE name = 'sessions') AS limite
            FROM dual
            UNION ALL
            SELECT 'processes',
                   (SELECT COUNT(*) FROM V$PROCESS),
                   (SELECT TO_NUMBER(TRIM(value) DEFAULT NULL ON CONVERSION ERROR)
                    FROM V$PARAMETER WHERE name = 'processes')
            FROM dual
        ) LOOP
            IF r.limite > 0 AND r.en_uso >= r.limite * p_percent / 100 THEN
                v_count := v_count + 1;
                v_text := v_text || 'Recurso ' || r.resource_name || ': '
                    || r.en_uso || ' en uso de ' || r.limite
                    || ' (' || fmt_number(r.en_uso / r.limite * 100) || '%)' || c_lf;
            END IF;
        END LOOP;

        FOR b IN (
            SELECT s.sid,
                   s.serial# AS serial_number,
                   s.username,
                   s.blocking_session,
                   s.seconds_in_wait,
                   s.event
            FROM V$SESSION s
            WHERE s.blocking_session IS NOT NULL
              AND s.seconds_in_wait >= p_block_seconds
            ORDER BY s.seconds_in_wait DESC
        ) LOOP
            v_count := v_count + 1;
            IF v_count <= c_max_lines THEN
                v_text := v_text || 'Sesion ' || b.sid || ',' || b.serial_number
                    || ' (' || NVL(b.username, 'sin usuario') || ') bloqueada por la sesion '
                    || b.blocking_session || ' desde hace ' || b.seconds_in_wait
                    || ' s; espera: ' || b.event || c_lf;
            END IF;
        END LOOP;

        IF v_count = 0 THEN
            RETURN NULL;
        END IF;

        SELECT COUNT(*) INTO v_sessions FROM V$SESSION WHERE type = 'USER';

        RETURN build_header('Sesiones y recursos criticos')
            || v_text || c_lf
            || 'Sesiones de usuario abiertas ahora: ' || v_sessions || c_lf
            || 'Umbral de uso: ' || fmt_number(p_percent) || '%; espera maxima por bloqueo: '
            || p_block_seconds || ' s';
    END sessions_report;


    FUNCTION errors_report(
        p_since IN DATE
    ) RETURN CLOB
    IS
        v_text  CLOB;
        v_count PLS_INTEGER := 0;
        v_total NUMBER := 0;
    BEGIN
        FOR r IN (
            SELECT modulo,
                   codigo_error,
                   COUNT(*)        AS veces,
                   MAX(fecha_hora) AS ultima,
                   MAX(SUBSTR(mensaje_error, 1, 300))
                       KEEP (DENSE_RANK LAST ORDER BY fecha_hora, id_bitacora_error) AS ultimo_mensaje
            FROM CP_BITACORA_ERROR
            WHERE fecha_hora >= CAST(p_since AS TIMESTAMP)
            GROUP BY modulo, codigo_error
            ORDER BY COUNT(*) DESC, modulo, codigo_error
        ) LOOP
            v_count := v_count + 1;
            v_total := v_total + r.veces;
            IF v_count <= c_max_lines THEN
                v_text := v_text || r.modulo || ' ' || r.codigo_error
                    || ': ' || r.veces || ' vez(ces), la ultima '
                    || TO_CHAR(r.ultima, 'DD/MM/YYYY HH24:MI') || ' - ' || r.ultimo_mensaje || c_lf;
            END IF;
        END LOOP;

        IF v_count = 0 THEN
            RETURN NULL;
        END IF;

        RETURN build_header('Errores registrados en CP_BITACORA_ERROR desde el '
                      || TO_CHAR(p_since, 'DD/MM/YYYY HH24:MI'))
            || v_text || c_lf
            || 'Total de errores: ' || v_total;
    END errors_report;


    PROCEDURE record_growth(
        p_commit IN BOOLEAN DEFAULT TRUE
    )
    IS
    BEGIN

        SAVEPOINT sp_record_growth;

        INSERT INTO CP_MONITOREO_TABLESPACE (
            nombre_tablespace,
            mb_asignados,
            mb_usados,
            mb_maximos,
            porcentaje_uso
        )
        SELECT tablespace_name,
               mb_asignados,
               mb_usados,
               mb_maximos,
               porcentaje_uso
        FROM VW_CP_USO_TABLESPACE;

        IF p_commit THEN
            COMMIT;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK TO SAVEPOINT sp_record_growth;
            PKG_CP_ERROR.registrar_inesperado(c_modulo, 'record_growth');
            RAISE;
    END record_growth;


    PROCEDURE check_tablespaces(
        p_force  IN BOOLEAN DEFAULT FALSE,
        p_commit IN BOOLEAN DEFAULT TRUE
    )
    IS
        v_percent NUMBER;
    BEGIN

        SAVEPOINT sp_check_tablespaces;

        v_percent := positive_parameter('TABLESPACE_UMBRAL_PCT', FALSE);

        send_check(
            p_type    => c_type_tablespace,
            p_subject => 'Monitoreo CP-POS: tablespaces al ' || fmt_number(v_percent) || '% o mas',
            p_report  => tablespace_report(v_percent),
            p_force   => p_force,
            p_since   => TRUNC(SYSDATE)
        );

        IF p_commit THEN
            COMMIT;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK TO SAVEPOINT sp_check_tablespaces;
            PKG_CP_ERROR.registrar_inesperado(c_modulo, 'check_tablespaces');
            RAISE;
    END check_tablespaces;


    PROCEDURE check_invalid_objects(
        p_force  IN BOOLEAN DEFAULT FALSE,
        p_commit IN BOOLEAN DEFAULT TRUE
    )
    IS
    BEGIN

        SAVEPOINT sp_check_invalid;

        send_check(
            p_type    => c_type_invalid,
            p_subject => 'Monitoreo CP-POS: objetos invalidos',
            p_report  => invalid_objects_report,
            p_force   => p_force,
            p_since   => TRUNC(SYSDATE)
        );

        IF p_commit THEN
            COMMIT;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK TO SAVEPOINT sp_check_invalid;
            PKG_CP_ERROR.registrar_inesperado(c_modulo, 'check_invalid_objects');
            RAISE;
    END check_invalid_objects;


    PROCEDURE check_indexes(
        p_force  IN BOOLEAN DEFAULT FALSE,
        p_commit IN BOOLEAN DEFAULT TRUE
    )
    IS
    BEGIN

        SAVEPOINT sp_check_indexes;

        send_check(
            p_type    => c_type_index,
            p_subject => 'Monitoreo CP-POS: indices inutilizables',
            p_report  => unusable_indexes_report,
            p_force   => p_force,
            p_since   => TRUNC(SYSDATE)
        );

        IF p_commit THEN
            COMMIT;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK TO SAVEPOINT sp_check_indexes;
            PKG_CP_ERROR.registrar_inesperado(c_modulo, 'check_indexes');
            RAISE;
    END check_indexes;


    PROCEDURE check_sessions(
        p_force  IN BOOLEAN DEFAULT FALSE,
        p_commit IN BOOLEAN DEFAULT TRUE
    )
    IS
        v_percent NUMBER;
        v_seconds NUMBER;
    BEGIN

        SAVEPOINT sp_check_sessions;

        v_percent := positive_parameter('SESIONES_UMBRAL_PCT', FALSE);
        v_seconds := positive_parameter('SESION_BLOQUEO_SEGUNDOS', TRUE);

        -- Un problema de sesiones puede durar: se avisa a lo sumo una vez por hora
        send_check(
            p_type    => c_type_session,
            p_subject => 'Monitoreo CP-POS: sesiones y recursos criticos',
            p_report  => sessions_report(v_percent, v_seconds),
            p_force   => p_force,
            p_since   => SYSDATE - c_session_repeat
        );

        IF p_commit THEN
            COMMIT;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK TO SAVEPOINT sp_check_sessions;
            PKG_CP_ERROR.registrar_inesperado(c_modulo, 'check_sessions');
            RAISE;
    END check_sessions;


    PROCEDURE check_errors(
        p_force  IN BOOLEAN DEFAULT FALSE,
        p_commit IN BOOLEAN DEFAULT TRUE
    )
    IS
    BEGIN

        SAVEPOINT sp_check_errors;

        send_check(
            p_type    => c_type_error,
            p_subject => 'Monitoreo CP-POS: errores de las ultimas 24 horas',
            p_report  => errors_report(SYSDATE - c_error_window),
            p_force   => p_force,
            p_since   => TRUNC(SYSDATE)
        );

        IF p_commit THEN
            COMMIT;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK TO SAVEPOINT sp_check_errors;
            PKG_CP_ERROR.registrar_inesperado(c_modulo, 'check_errors');
            RAISE;
    END check_errors;


    -- La muestra va primero para que el aviso de tablespaces ya traiga el
    -- crecimiento de hoy; los errores van al final para incluir los de
    -- los controles anteriores.
    PROCEDURE run_daily(
        p_force IN BOOLEAN DEFAULT FALSE
    )
    IS
    BEGIN
        BEGIN record_growth;                  EXCEPTION WHEN OTHERS THEN NULL; END;
        BEGIN check_tablespaces(p_force);     EXCEPTION WHEN OTHERS THEN NULL; END;
        BEGIN check_invalid_objects(p_force); EXCEPTION WHEN OTHERS THEN NULL; END;
        BEGIN check_indexes(p_force);         EXCEPTION WHEN OTHERS THEN NULL; END;
        BEGIN check_errors(p_force);          EXCEPTION WHEN OTHERS THEN NULL; END;
    END run_daily;

END PKG_CP_MONITOREO;
/

SHOW ERRORS PACKAGE BODY PKG_CP_MONITOREO

-- ============================================================
-- 9. PRUEBAS
-- ============================================================
-- Todas deben salir OK. Se ejecutan como CP_POS. Las listas se prueban
-- con el credito (o el cliente) de mas uso y se mueve el umbral alrededor de
-- su valor para probar la frontera. Si ningun credito tiene saldo, las
-- pruebas crean una venta y una compra a credito que nunca se confirman, y
-- la mora se mide con una fecha "de hoy" 40 dias adelante.
-- Las pruebas 4 y 5 crean y borran objetos temporales (DDL, que confirma),
-- por eso van antes de cualquier cambio de datos. Lo demas se deshace con
-- ROLLBACK, y de la bitacora solo se borran los errores provocados.
-- Si no hay correo configurado, un aviso queda FALLIDO y eso tambien vale.

DECLARE
    v_antes       NUMBER;
    v_notif_antes NUMBER;
    v_start       DATE := SYSDATE;
    v_ok          NUMBER := 0;
    v_falla       NUMBER := 0;
    v_count       NUMBER;
    v_count2      NUMBER;
    v_expected    NUMBER;
    v_code        NUMBER;
    v_text        CLOB;
    v_status      VARCHAR2(12);
    v_done        BOOLEAN;

    v_credit      NUMBER;
    v_pct         NUMBER;
    v_have_credit BOOLEAN := FALSE;
    v_credit_row  PKG_CP_ALERTA.t_customer_credit_row;

    v_supplier    NUMBER;
    v_sup_pct     NUMBER;
    v_have_sup    BOOLEAN := FALSE;

    v_client       NUMBER;
    v_days         NUMBER;
    v_ref          DATE;
    v_mora_today   DATE;
    v_have_overdue BOOLEAN := FALSE;
    v_overdue_row  PKG_CP_ALERTA.t_overdue_row;

    v_expired     NUMBER;
    v_has_limit   NUMBER;

    v_orig_cxc    VARCHAR2(500);
    v_orig_ger    VARCHAR2(500);
    v_orig_mora   VARCHAR2(500);
    v_orig_ts     VARCHAR2(500);
    v_orig_ses    VARCHAR2(500);
    v_orig_blk    VARCHAR2(500);

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
            RPAD(p_prueba, 76, '.') || CASE WHEN p_ok THEN ' OK' ELSE ' FALLA' END
        );
    END reportar;

    PROCEDURE omitir(
        p_prueba IN VARCHAR2,
        p_motivo IN VARCHAR2
    )
    IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(RPAD(p_prueba, 76, '.') || ' omitida (' || p_motivo || ')');
    END omitir;

    FUNCTION has(
        p_text IN CLOB,
        p_part IN VARCHAR2
    ) RETURN BOOLEAN
    IS
    BEGIN
        RETURN p_text IS NOT NULL AND DBMS_LOB.INSTR(p_text, p_part) > 0;
    END has;

    FUNCTION param_text(
        p_codigo IN VARCHAR2
    ) RETURN VARCHAR2
    IS
    BEGIN
        RETURN PKG_CP_PARAMETRO.obtener_texto(p_codigo);
    END param_text;

    FUNCTION as_text(
        p_value IN NUMBER
    ) RETURN VARCHAR2
    IS
    BEGIN
        RETURN TO_CHAR(p_value, 'FM999999999990.99', 'NLS_NUMERIC_CHARACTERS=''.,''');
    END as_text;

    FUNCTION notices_of(
        p_type IN VARCHAR2
    ) RETURN NUMBER
    IS
        v_total NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_total
        FROM CP_NOTIFICACION
        WHERE id_notificacion > v_notif_antes AND tipo_notificacion = p_type;
        RETURN v_total;
    END notices_of;

    -- p_ignore: codigo de error que se espera y no es una falla (0 = ninguno)
    PROCEDURE exec_ddl(
        p_sql    IN VARCHAR2,
        p_ignore IN NUMBER
    )
    IS
    BEGIN
        EXECUTE IMMEDIATE p_sql;
    EXCEPTION
        WHEN OTHERS THEN
            IF p_ignore = 0 OR SQLCODE != p_ignore THEN
                RAISE;
            END IF;
    END exec_ddl;

    FUNCTION customer_listed(
        p_id      IN NUMBER,
        p_percent IN NUMBER
    ) RETURN BOOLEAN
    IS
        v_cursor SYS_REFCURSOR;
        v_row    PKG_CP_ALERTA.t_customer_credit_row;
        v_found  BOOLEAN := FALSE;
    BEGIN
        v_cursor := PKG_CP_ALERTA.customer_credits_over(p_percent);
        LOOP
            FETCH v_cursor INTO v_row;
            EXIT WHEN v_cursor%NOTFOUND;
            IF v_row.id_credito_cliente = p_id THEN
                v_credit_row := v_row;
                v_found := TRUE;
                EXIT;
            END IF;
        END LOOP;
        CLOSE v_cursor;
        RETURN v_found;
    END customer_listed;

    FUNCTION supplier_listed(
        p_id      IN NUMBER,
        p_percent IN NUMBER
    ) RETURN BOOLEAN
    IS
        v_cursor SYS_REFCURSOR;
        v_row    PKG_CP_ALERTA.t_supplier_credit_row;
        v_found  BOOLEAN := FALSE;
    BEGIN
        v_cursor := PKG_CP_ALERTA.supplier_credits_over(p_percent);
        LOOP
            FETCH v_cursor INTO v_row;
            EXIT WHEN v_cursor%NOTFOUND;
            IF v_row.id_credito_proveedor = p_id THEN
                v_found := TRUE;
                EXIT;
            END IF;
        END LOOP;
        CLOSE v_cursor;
        RETURN v_found;
    END supplier_listed;

    FUNCTION overdue_listed(
        p_id    IN NUMBER,
        p_days  IN NUMBER,
        p_today IN DATE
    ) RETURN BOOLEAN
    IS
        v_cursor SYS_REFCURSOR;
        v_row    PKG_CP_ALERTA.t_overdue_row;
        v_found  BOOLEAN := FALSE;
    BEGIN
        v_cursor := PKG_CP_ALERTA.overdue_customers(p_days, p_today);
        LOOP
            FETCH v_cursor INTO v_row;
            EXIT WHEN v_cursor%NOTFOUND;
            IF v_row.id_cliente = p_id THEN
                v_overdue_row := v_row;
                v_found := TRUE;
                EXIT;
            END IF;
        END LOOP;
        CLOSE v_cursor;
        RETURN v_found;
    END overdue_listed;

    FUNCTION expired_rows(
        p_today IN DATE
    ) RETURN NUMBER
    IS
        v_cursor SYS_REFCURSOR;
        v_row    PKG_CP_ALERTA.t_expired_row;
        v_total  NUMBER := 0;
    BEGIN
        v_cursor := PKG_CP_ALERTA.expired_lots(p_today);
        LOOP
            FETCH v_cursor INTO v_row;
            EXIT WHEN v_cursor%NOTFOUND;
            v_total := v_total + 1;
        END LOOP;
        CLOSE v_cursor;
        RETURN v_total;
    END expired_rows;

    -- Venta a credito de 1 unidad a 1000, sin confirmar, para un cliente con
    -- credito activo y espacio en su limite, en una sucursal de ese negocio
    -- con un solo almacen activo (criterio de las pruebas de los scripts 25 y 27)
    FUNCTION create_credit_sale RETURN BOOLEAN
    IS
        v_cliente  NUMBER;
        v_sucursal NUMBER;
        v_producto NUMBER;
        v_usuario  NUMBER;
        v_factura  NUMBER;
        v_lines    PKG_CP_FACTURACION.t_lineas_venta;
    BEGIN
        SELECT u.id_cliente, s.id_sucursal, v.id_producto
        INTO v_cliente, v_sucursal, v_producto
        FROM VW_CP_CREDITO_CLIENTE_USO u
        JOIN CP_CREDITO_CLIENTE cc
          ON cc.id_credito_cliente = u.id_credito_cliente
        JOIN CP_SUCURSAL s
          ON s.id_negocio = u.id_negocio
        JOIN CP_ALMACEN a
          ON a.id_sucursal = s.id_sucursal
        JOIN CP_ESTADO e
          ON e.id_estado = a.id_estado
        JOIN VW_CP_INVENTARIO_ACTUAL v
          ON v.id_almacen = a.id_almacen
        WHERE u.estado_credito = 'ACTIVO'
          AND u.limite_credito - u.saldo_utilizado >= 2000
          AND cc.fecha_autorizacion <= SYSDATE
          AND (cc.fecha_vencimiento IS NULL OR cc.fecha_vencimiento >= TRUNC(SYSDATE))
          AND e.nombre = 'ACTIVO'
          AND v.cantidad_actual >= 1
          AND (v.fecha_vencimiento IS NULL OR v.fecha_vencimiento >= TRUNC(SYSDATE))
          AND (SELECT COUNT(*)
               FROM CP_ALMACEN a2
               JOIN CP_ESTADO e2
                 ON e2.id_estado = a2.id_estado
               WHERE a2.id_sucursal = s.id_sucursal
                 AND e2.nombre = 'ACTIVO') = 1
        ORDER BY u.correo NULLS LAST, u.id_credito_cliente, v.id_producto
        FETCH FIRST 1 ROW ONLY;

        SELECT MIN(id_usuario) INTO v_usuario FROM CP_USUARIO;

        v_lines(1).id_producto := v_producto;
        v_lines(1).cantidad := 1;
        v_lines(1).precio_unitario := 1000;

        PKG_CP_FACTURACION.registrar_venta(
            p_id_cliente     => v_cliente,
            p_id_sucursal    => v_sucursal,
            p_id_usuario     => v_usuario,
            p_numero_factura => 'TN-V-' || TO_CHAR(SYSDATE, 'MMDDHH24MISS'),
            p_lineas         => v_lines,
            p_id_factura     => v_factura,
            p_a_credito      => TRUE,
            p_commit         => FALSE
        );

        DBMS_OUTPUT.PUT_LINE('   venta a credito de prueba creada para el cliente ' || v_cliente);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('   no se pudo crear la venta a credito de prueba: ' || SQLERRM);
            RETURN FALSE;
    END create_credit_sale;

    -- Compra a credito de 1 unidad a 1000, sin confirmar, a un proveedor con
    -- credito activo y espacio en su limite
    FUNCTION create_credit_purchase RETURN BOOLEAN
    IS
        v_prov    NUMBER;
        v_neg     NUMBER;
        v_pp      NUMBER;
        v_alm     NUMBER;
        v_usuario NUMBER;
        v_factura NUMBER;
        v_stamp   VARCHAR2(20) := TO_CHAR(SYSDATE, 'MMDDHH24MISS');
        v_lots    PKG_CP_FACTURACION.t_lineas_compra;
    BEGIN
        SELECT u.id_proveedor, u.id_negocio
        INTO v_prov, v_neg
        FROM VW_CP_CREDITO_PROVEEDOR_USO u
        JOIN CP_CREDITO_PROVEEDOR cr
          ON cr.id_credito_proveedor = u.id_credito_proveedor
        WHERE u.estado_credito = 'ACTIVO'
          AND u.limite_credito - u.saldo_utilizado >= 2000
          AND cr.fecha_autorizacion <= SYSDATE
          AND (cr.fecha_vencimiento IS NULL OR cr.fecha_vencimiento >= TRUNC(SYSDATE))
          AND EXISTS (SELECT 1 FROM CP_PRODUCTO_PROVEEDOR pp
                      WHERE pp.id_proveedor = u.id_proveedor)
          AND EXISTS (SELECT 1 FROM CP_ALMACEN a
                      JOIN CP_SUCURSAL s ON s.id_sucursal = a.id_sucursal
                      WHERE s.id_negocio = u.id_negocio)
        ORDER BY u.id_credito_proveedor
        FETCH FIRST 1 ROW ONLY;

        SELECT MIN(id_producto_proveedor) INTO v_pp
        FROM CP_PRODUCTO_PROVEEDOR WHERE id_proveedor = v_prov;

        SELECT MIN(a.id_almacen) INTO v_alm
        FROM CP_ALMACEN a
        JOIN CP_SUCURSAL s ON s.id_sucursal = a.id_sucursal
        WHERE s.id_negocio = v_neg;

        SELECT MIN(id_usuario) INTO v_usuario FROM CP_USUARIO;

        v_lots(1).id_producto_proveedor := v_pp;
        v_lots(1).cantidad := 1;
        v_lots(1).precio_costo_unitario := 1000;
        v_lots(1).porcentaje_descuento := 0;
        v_lots(1).porcentaje_impuesto := 0;
        v_lots(1).numero_lote := 'TN-L-' || v_stamp;
        v_lots(1).fecha_vencimiento := TRUNC(SYSDATE) + 365;

        PKG_CP_FACTURACION.registrar_compra(
            p_id_proveedor         => v_prov,
            p_id_negocio           => v_neg,
            p_id_almacen_recepcion => v_alm,
            p_id_usuario           => v_usuario,
            p_numero_factura       => 'TN-C-' || v_stamp,
            p_lineas               => v_lots,
            p_id_factura           => v_factura,
            p_a_credito            => TRUE,
            p_commit               => FALSE
        );

        DBMS_OUTPUT.PUT_LINE('   compra a credito de prueba creada para el proveedor ' || v_prov);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('   no se pudo crear la compra a credito de prueba: ' || SQLERRM);
            RETURN FALSE;
    END create_credit_purchase;

    -- Envoltorios: devuelven 0 o el codigo de error
    FUNCTION manager_code RETURN NUMBER
    IS
    BEGIN
        PKG_CP_ALERTA.notify_supplier_credit_manager(p_force => TRUE, p_commit => FALSE);
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN SQLCODE;
    END manager_code;

    FUNCTION overdue_code RETURN NUMBER
    IS
    BEGIN
        PKG_CP_ALERTA.notify_overdue(p_force => TRUE, p_commit => FALSE);
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN SQLCODE;
    END overdue_code;

    FUNCTION tablespace_code RETURN NUMBER
    IS
    BEGIN
        PKG_CP_MONITOREO.check_tablespaces(p_force => TRUE, p_commit => FALSE);
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN SQLCODE;
    END tablespace_code;

    FUNCTION sessions_code RETURN NUMBER
    IS
    BEGIN
        PKG_CP_MONITOREO.check_sessions(p_force => TRUE, p_commit => FALSE);
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN SQLCODE;
    END sessions_code;

BEGIN

    SELECT NVL(MAX(id_bitacora_error), 0) INTO v_antes FROM CP_BITACORA_ERROR;
    SELECT NVL(MAX(id_notificacion), 0) INTO v_notif_antes FROM CP_NOTIFICACION;

    v_orig_cxc  := param_text('UMBRAL_CXC_CLIENTE_PCT');
    v_orig_ger  := param_text('UMBRAL_CXP_GERENTE_PCT');
    v_orig_mora := param_text('MOROSIDAD_DIAS_SIN_PAGO');
    v_orig_ts   := param_text('TABLESPACE_UMBRAL_PCT');
    v_orig_ses  := param_text('SESIONES_UMBRAL_PCT');
    v_orig_blk  := param_text('SESION_BLOQUEO_SEGUNDOS');

    -- ------------------------------------------------------------
    -- A. PKG_CP_AVISO: aviso a un correo concreto
    -- ------------------------------------------------------------
    PKG_CP_AVISO.set_enabled(TRUE);
    BEGIN
        PKG_CP_AVISO.queue_notice_to('PRUEBA_NOTIF', 'Prueba', 'Mensaje de prueba', NULL);
        v_done := TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            v_done := FALSE;
    END;
    v_status := PKG_CP_AVISO.last_status;

    SELECT COUNT(*) INTO v_count
    FROM CP_BITACORA_ERROR
    WHERE id_bitacora_error > v_antes AND codigo_error = -20342;

    reportar('1. queue_notice_to sin correo no lanza error, queda FALLIDO y registra -20342',
             v_done AND v_status = PKG_CP_AVISO.c_status_failed AND v_count = 1);

    reportar('2. already_queued no encuentra un tipo que nunca se encolo',
             NOT PKG_CP_AVISO.already_queued('PRUEBA_NOTIF_NINGUNO'));

    PKG_CP_AVISO.set_enabled(FALSE);
    PKG_CP_AVISO.queue_notice_to('PRUEBA_NOTIF', 'Prueba', 'Mensaje de prueba', 'prueba@ejemplo.com');

    reportar('3. Con los avisos apagados queue_notice_to no encola (DESACTIVADO)',
             PKG_CP_AVISO.last_status = PKG_CP_AVISO.c_status_disabled
             AND notices_of('PRUEBA_NOTIF') = 0);

    -- ------------------------------------------------------------
    -- B. Objetos invalidos e indices inutilizables (DDL)
    -- ------------------------------------------------------------
    exec_ddl('DROP TABLE CP_T_NOTIF_MONITOREO PURGE', -942);
    exec_ddl('DROP PROCEDURE PRC_CP_T_NOTIF_INVALIDO', -4043);

    -- ORA-24344: se crea con errores de compilacion, que es lo que se busca
    exec_ddl('CREATE OR REPLACE PROCEDURE PRC_CP_T_NOTIF_INVALIDO IS BEGIN v_no_existe := 1; END;', -24344);
    v_done := has(PKG_CP_MONITOREO.invalid_objects_report, 'PROCEDURE PRC_CP_T_NOTIF_INVALIDO');
    exec_ddl('DROP PROCEDURE PRC_CP_T_NOTIF_INVALIDO', -4043);

    reportar('4. Un procedimiento invalido aparece en el reporte y sale al borrarlo',
             v_done AND NOT has(PKG_CP_MONITOREO.invalid_objects_report, 'PRC_CP_T_NOTIF_INVALIDO'));

    exec_ddl('CREATE TABLE CP_T_NOTIF_MONITOREO (id NUMBER) TABLESPACE CP_POS_DATOS', 0);
    exec_ddl('CREATE INDEX IX_CP_T_NOTIF_MONITOREO ON CP_T_NOTIF_MONITOREO (id) TABLESPACE CP_POS_INDICES', 0);
    exec_ddl('ALTER INDEX IX_CP_T_NOTIF_MONITOREO UNUSABLE', 0);
    v_done := has(PKG_CP_MONITOREO.unusable_indexes_report, 'INDICE IX_CP_T_NOTIF_MONITOREO');
    exec_ddl('DROP TABLE CP_T_NOTIF_MONITOREO PURGE', -942);

    reportar('5. Un indice UNUSABLE aparece en el reporte y sale al borrarlo',
             v_done AND NOT has(PKG_CP_MONITOREO.unusable_indexes_report, 'IX_CP_T_NOTIF_MONITOREO'));

    -- ------------------------------------------------------------
    -- C. Vistas de apoyo
    -- ------------------------------------------------------------
    SELECT COUNT(*), COUNT(DISTINCT id_cliente) INTO v_count, v_count2 FROM VW_CP_CLIENTE_CORREO;
    SELECT (SELECT COUNT(*) FROM CP_CLIENTE_PERSONA) + (SELECT COUNT(*) FROM CP_CLIENTE_EMPRESA)
    INTO v_expected FROM dual;

    reportar('6. VW_CP_CLIENTE_CORREO trae personas y empresas, una fila por cliente',
             v_count = v_count2 AND v_count = v_expected);

    SELECT COUNT(*) INTO v_count FROM VW_CP_CREDITO_CLIENTE_USO;
    SELECT COUNT(*) INTO v_count2 FROM CP_CREDITO_CLIENTE;

    reportar('7. VW_CP_CREDITO_CLIENTE_USO: una fila por linea de credito de cliente',
             v_count = v_count2);

    SELECT COUNT(*) INTO v_count FROM VW_CP_CREDITO_PROVEEDOR_USO;
    SELECT COUNT(*) INTO v_count2 FROM CP_CREDITO_PROVEEDOR;

    reportar('8. VW_CP_CREDITO_PROVEEDOR_USO: una fila por linea de credito de proveedor',
             v_count = v_count2);

    -- ------------------------------------------------------------
    -- D. Credito de clientes
    -- ------------------------------------------------------------
    SELECT COUNT(*) INTO v_count
    FROM VW_CP_CREDITO_CLIENTE_USO
    WHERE estado_credito = 'ACTIVO' AND limite_credito > 0 AND saldo_utilizado > 0;

    IF v_count = 0 THEN
        v_done := create_credit_sale;
    END IF;

    BEGIN
        SELECT id_credito_cliente, saldo_utilizado / limite_credito * 100
        INTO v_credit, v_pct
        FROM VW_CP_CREDITO_CLIENTE_USO
        WHERE estado_credito = 'ACTIVO' AND limite_credito > 0 AND saldo_utilizado > 0
        ORDER BY saldo_utilizado / limite_credito DESC, id_credito_cliente
        FETCH FIRST 1 ROW ONLY;
        v_have_credit := TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_have_credit := FALSE;
    END;

    IF v_have_credit THEN
        DBMS_OUTPUT.PUT_LINE('   credito de cliente de prueba: ' || v_credit
                             || ' con ' || as_text(v_pct) || '% de uso');

        reportar('9. Credito de cliente: entra con su porcentaje y no con uno mayor',
                 customer_listed(v_credit, TRUNC(v_pct, 2))
                 AND NOT customer_listed(v_credit, TRUNC(v_pct, 2) + 0.01));

        v_done := customer_listed(v_credit, TRUNC(v_pct, 2));
        v_text := PKG_CP_ALERTA.customer_credit_message(v_credit_row, 85);

        reportar('10. El mensaje al cliente trae su credito, el limite y el umbral',
                 v_done
                 AND has(v_text, 'Su credito numero ' || v_credit)
                 AND has(v_text, 'Limite de credito:')
                 AND has(v_text, '85.00% de su limite'));
    ELSE
        omitir('9 y 10. Credito de clientes', 'ningun credito con saldo y no se pudo crear uno');
    END IF;

    -- ------------------------------------------------------------
    -- E. Credito de proveedores (coordinador y gerente)
    -- ------------------------------------------------------------
    SELECT COUNT(*) INTO v_count
    FROM VW_CP_CREDITO_PROVEEDOR_USO
    WHERE estado_credito = 'ACTIVO' AND limite_credito > 0 AND saldo_utilizado > 0;

    IF v_count = 0 THEN
        v_done := create_credit_purchase;
    END IF;

    BEGIN
        SELECT id_credito_proveedor, saldo_utilizado / limite_credito * 100
        INTO v_supplier, v_sup_pct
        FROM VW_CP_CREDITO_PROVEEDOR_USO
        WHERE estado_credito = 'ACTIVO' AND limite_credito > 0 AND saldo_utilizado > 0
        ORDER BY saldo_utilizado / limite_credito DESC, id_credito_proveedor
        FETCH FIRST 1 ROW ONLY;
        v_have_sup := TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_have_sup := FALSE;
    END;

    IF v_have_sup THEN
        DBMS_OUTPUT.PUT_LINE('   credito de proveedor de prueba: ' || v_supplier
                             || ' con ' || as_text(v_sup_pct) || '% de uso');

        reportar('11. Credito de proveedor: entra con su porcentaje y no con uno mayor',
                 supplier_listed(v_supplier, TRUNC(v_sup_pct, 2))
                 AND NOT supplier_listed(v_supplier, TRUNC(v_sup_pct, 2) + 0.01));

        v_text := PKG_CP_ALERTA.supplier_credit_report(TRUNC(v_sup_pct, 2));

        reportar('12. Un solo reporte con todos los proveedores y su total; vacio si nadie llega',
                 has(v_text, 'Credito ' || v_supplier || ' |')
                 AND has(v_text, 'Total de proveedores:')
                 AND PKG_CP_ALERTA.supplier_credit_report(1000000) IS NULL);
    ELSE
        omitir('11 y 12. Credito de proveedores', 'ningun credito con saldo y no se pudo crear uno');
    END IF;

    -- ------------------------------------------------------------
    -- F. Clientes en mora
    -- ------------------------------------------------------------
    -- Si la cuenta mas antigua es de hoy (por ejemplo la venta de prueba),
    -- se mide con una fecha "de hoy" 40 dias adelante.
    BEGIN
        SELECT id_cliente, TRUNC(fecha_referencia)
        INTO v_client, v_ref
        FROM VW_CP_CLIENTE_MORA
        ORDER BY fecha_referencia, id_cliente
        FETCH FIRST 1 ROW ONLY;
        v_have_overdue := TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_have_overdue := FALSE;
    END;

    IF v_have_overdue THEN
        v_mora_today := CASE WHEN TRUNC(SYSDATE) - v_ref >= 1
                             THEN TRUNC(SYSDATE)
                             ELSE v_ref + 40 END;
        v_days := v_mora_today - v_ref;

        DBMS_OUTPUT.PUT_LINE('   cliente de prueba: ' || v_client || ' con '
                             || v_days || ' dias sin pagar al '
                             || TO_CHAR(v_mora_today, 'DD/MM/YYYY'));

        reportar('13. Mora: con ' || v_days || ' dias sin pagar entra con ' || (v_days - 1)
                 || ' y no con ' || v_days,
                 overdue_listed(v_client, v_days - 1, v_mora_today)
                 AND NOT overdue_listed(v_client, v_days, v_mora_today));

        v_done := overdue_listed(v_client, v_days - 1, v_mora_today);
        v_text := PKG_CP_ALERTA.overdue_report(v_days - 1, v_mora_today);

        reportar('14. El reporte de mora trae al cliente y el total de clientes',
                 has(v_text, 'ID cliente: ' || v_client || ' |')
                 AND has(v_text, 'Total de clientes en mora:')
                 AND has(v_text, 'gerente y coordinador'));

        reportar('15. El mensaje al cliente en mora trae su saldo pendiente',
                 v_done AND has(PKG_CP_ALERTA.overdue_customer_message(v_overdue_row),
                                'saldo pendiente de'));
    ELSE
        omitir('13 a 15. Clientes en mora', 'ningun cliente con saldo pendiente');
    END IF;

    -- ------------------------------------------------------------
    -- G. Productos vencidos
    -- ------------------------------------------------------------
    SELECT COUNT(*) INTO v_expired
    FROM CP_INVENTARIO_ALMACEN ia
    JOIN CP_LOTE_PRODUCTO lp
      ON lp.id_lote_producto = ia.id_lote_producto
    WHERE lp.fecha_vencimiento < TRUNC(SYSDATE)
      AND ia.cantidad_actual > 0;

    DBMS_OUTPUT.PUT_LINE('   lotes vencidos con existencia: ' || v_expired);

    v_text := PKG_CP_ALERTA.expired_products_report(TRUNC(SYSDATE));

    reportar('16. Vencidos: la lista trae todos los lotes vencidos y el total',
             expired_rows(TRUNC(SYSDATE)) = v_expired
             AND ((v_expired = 0 AND v_text IS NULL)
                  OR (has(v_text, 'Lotes vencidos con existencia: ' || v_expired)
                      AND has(v_text, 'Valor al costo:'))));

    reportar('17. Antes de 1900 no hay vencidos: no hay nada que avisar',
             PKG_CP_ALERTA.expired_products_report(DATE '1900-01-01') IS NULL);

    -- ------------------------------------------------------------
    -- H. Parametros invalidos
    -- ------------------------------------------------------------
    PKG_CP_AVISO.set_enabled(FALSE);

    PKG_CP_PARAMETRO.guardar('UMBRAL_CXP_GERENTE_PCT', '0');
    v_code := manager_code;
    PKG_CP_PARAMETRO.guardar('UMBRAL_CXP_GERENTE_PCT', v_orig_ger);

    reportar('18. Un porcentaje de alerta en 0 da -20380', v_code = -20380);

    PKG_CP_PARAMETRO.guardar('MOROSIDAD_DIAS_SIN_PAGO', '0');
    v_code := overdue_code;
    PKG_CP_PARAMETRO.guardar('MOROSIDAD_DIAS_SIN_PAGO', v_orig_mora);

    reportar('19. Unos dias de morosidad en 0 dan -20381', v_code = -20381);

    PKG_CP_PARAMETRO.guardar('TABLESPACE_UMBRAL_PCT', '0');
    v_code := tablespace_code;
    PKG_CP_PARAMETRO.guardar('TABLESPACE_UMBRAL_PCT', v_orig_ts);

    reportar('20. Un umbral de tablespaces en 0 da -20390', v_code = -20390);

    -- ------------------------------------------------------------
    -- I. Avisos de negocio (encendidos y sin confirmar)
    -- ------------------------------------------------------------
    PKG_CP_AVISO.set_enabled(TRUE);
    PKG_CP_PARAMETRO.guardar('UMBRAL_CXP_GERENTE_PCT', '1000000');
    v_code := manager_code;
    v_status := PKG_CP_AVISO.last_status;
    PKG_CP_PARAMETRO.guardar('UMBRAL_CXP_GERENTE_PCT', v_orig_ger);

    reportar('21. Sin proveedores sobre el umbral no se encola nada',
             v_code = 0 AND v_status IS NULL
             AND notices_of(PKG_CP_ALERTA.c_type_supplier_manager) = 0);

    PKG_CP_AVISO.set_enabled(TRUE);
    BEGIN
        PKG_CP_ALERTA.notify_expired_products(p_force => TRUE, p_commit => FALSE);
        v_done := TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            v_done := FALSE;
    END;
    v_status := PKG_CP_AVISO.last_status;
    v_count := notices_of(PKG_CP_ALERTA.c_type_expired);

    DBMS_OUTPUT.PUT_LINE('   estado del aviso de vencidos: ' || NVL(v_status, '<ninguno>'));

    reportar('22. Vencidos: un aviso en cola, o registrado por que no pudo, o nada si no hay',
             v_done
             AND ((v_expired = 0 AND v_status IS NULL AND v_count = 0)
                  OR (v_status = PKG_CP_AVISO.c_status_queued AND v_count = 1)
                  OR (v_status = PKG_CP_AVISO.c_status_failed AND v_count = 0)));

    IF v_status = PKG_CP_AVISO.c_status_queued THEN
        PKG_CP_AVISO.set_enabled(TRUE);
        PKG_CP_ALERTA.notify_expired_products(p_force => FALSE, p_commit => FALSE);

        reportar('23. Sin forzar no se repite el aviso del mismo dia',
                 notices_of(PKG_CP_ALERTA.c_type_expired) = 1
                 AND PKG_CP_AVISO.last_status IS NULL);
    ELSE
        omitir('23. Sin forzar no se repite el aviso del mismo dia',
               'el aviso no quedo en cola: falta el correo o no hay vencidos');
    END IF;

    IF v_have_credit THEN
        PKG_CP_AVISO.set_enabled(TRUE);
        PKG_CP_PARAMETRO.guardar('UMBRAL_CXC_CLIENTE_PCT', as_text(GREATEST(TRUNC(v_pct, 2), 0.01)));
        BEGIN
            PKG_CP_ALERTA.notify_customer_credit(p_force => TRUE, p_commit => FALSE);
            v_done := TRUE;
        EXCEPTION
            WHEN OTHERS THEN
                v_done := FALSE;
        END;
        v_status := PKG_CP_AVISO.last_status;
        v_count := notices_of(PKG_CP_ALERTA.c_type_customer_credit);
        PKG_CP_PARAMETRO.guardar('UMBRAL_CXC_CLIENTE_PCT', v_orig_cxc);

        DBMS_OUTPUT.PUT_LINE('   estado del aviso al cliente: ' || NVL(v_status, '<ninguno>'));

        reportar('24. Aviso al cliente: en cola a su correo, o registrado por que no pudo',
                 v_done
                 AND ((v_status = PKG_CP_AVISO.c_status_queued AND v_count >= 1)
                      OR v_status = PKG_CP_AVISO.c_status_failed
                      OR (v_status IS NULL AND v_credit_row.correo IS NULL)));
    ELSE
        omitir('24. Aviso al cliente', 'ningun credito con saldo y no se pudo crear uno');
    END IF;

    -- ------------------------------------------------------------
    -- J. Monitoreo
    -- ------------------------------------------------------------
    SELECT COUNT(*) INTO v_count
    FROM VW_CP_USO_TABLESPACE
    WHERE tablespace_name IN ('CP_POS_DATOS', 'CP_POS_INDICES', 'CP_POS_AUDITORIA')
      AND porcentaje_uso BETWEEN 0 AND 100;

    reportar('25. VW_CP_USO_TABLESPACE mide los tres tablespaces de CP_POS',
             v_count = 3);

    reportar('26. Reporte de tablespaces: con umbral 0 los trae; con 101 no hay nada',
             has(PKG_CP_MONITOREO.tablespace_report(0), 'Tablespace CP_POS_DATOS:')
             AND PKG_CP_MONITOREO.tablespace_report(101) IS NULL);

    BEGIN
        PKG_CP_MONITOREO.record_growth(p_commit => FALSE);
        v_done := TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            v_done := FALSE;
    END;

    SELECT COUNT(*) INTO v_count FROM CP_MONITOREO_TABLESPACE WHERE fecha_muestra >= v_start;
    SELECT COUNT(*) INTO v_count2 FROM VW_CP_USO_TABLESPACE;

    reportar('27. record_growth guarda una muestra por tablespace y el crecimiento la usa',
             v_done AND v_count = v_count2
             AND has(PKG_CP_MONITOREO.growth_report, 'CP_POS_DATOS:')
             AND has(PKG_CP_MONITOREO.growth_report, 'Tamano actual del esquema CP_POS'));

    SELECT COUNT(*) INTO v_has_limit
    FROM V$PARAMETER
    WHERE name IN ('sessions', 'processes')
      AND TO_NUMBER(TRIM(value) DEFAULT NULL ON CONVERSION ERROR) > 0;

    IF v_has_limit > 0 THEN
        reportar('28. Con umbral 0 el reporte de sesiones muestra los recursos',
                 has(PKG_CP_MONITOREO.sessions_report(0, 1000000000), 'Recurso '));
    ELSE
        omitir('28. Con umbral 0 el reporte de sesiones muestra los recursos',
               'V$PARAMETER no da el limite de sesiones');
    END IF;

    reportar('29. Con umbral 1000% y sin bloqueos largos no hay nada que avisar',
             PKG_CP_MONITOREO.sessions_report(1000, 1000000000) IS NULL);

    PKG_CP_ERROR.registrar('MONITOREO_PRUEBA', -20999, 'Error de prueba del modulo de notificaciones');

    reportar('30. El reporte de errores agrupa por modulo y codigo',
             has(PKG_CP_MONITOREO.errors_report(SYSDATE - 1 / 24),
                 'MONITOREO_PRUEBA -20999: 1 vez(ces)'));

    PKG_CP_AVISO.set_enabled(TRUE);
    PKG_CP_PARAMETRO.guardar('TABLESPACE_UMBRAL_PCT', '0.01');
    v_code := tablespace_code;
    v_status := PKG_CP_AVISO.last_status;
    v_count := notices_of(PKG_CP_MONITOREO.c_type_tablespace);
    PKG_CP_PARAMETRO.guardar('TABLESPACE_UMBRAL_PCT', v_orig_ts);

    DBMS_OUTPUT.PUT_LINE('   estado del aviso de tablespaces: ' || NVL(v_status, '<ninguno>'));

    reportar('31. Tablespaces sobre el umbral: aviso en cola o registrado por que no pudo',
             v_code = 0
             AND ((v_status = PKG_CP_AVISO.c_status_queued AND v_count = 1)
                  OR (v_status = PKG_CP_AVISO.c_status_failed AND v_count = 0)));

    PKG_CP_AVISO.set_enabled(TRUE);
    PKG_CP_PARAMETRO.guardar('SESIONES_UMBRAL_PCT', '1000');
    PKG_CP_PARAMETRO.guardar('SESION_BLOQUEO_SEGUNDOS', '1000000000');
    v_code := sessions_code;
    v_status := PKG_CP_AVISO.last_status;
    PKG_CP_PARAMETRO.guardar('SESIONES_UMBRAL_PCT', v_orig_ses);
    PKG_CP_PARAMETRO.guardar('SESION_BLOQUEO_SEGUNDOS', v_orig_blk);

    reportar('32. check_sessions sin problemas no encola nada',
             v_code = 0 AND v_status IS NULL
             AND notices_of(PKG_CP_MONITOREO.c_type_session) = 0);

    SELECT COUNT(*) INTO v_count
    FROM CP_BITACORA_ERROR
    WHERE id_bitacora_error > v_antes
      AND codigo_error IN (-20342, -20380, -20381, -20390);

    reportar('33. Cada error provocado quedo UNA sola vez en la bitacora',
             v_count = 4);

    -- ------------------------------------------------------------
    -- K. Limpieza
    -- ------------------------------------------------------------
    ROLLBACK;

    SELECT COUNT(*) INTO v_count
    FROM CP_NOTIFICACION
    WHERE id_notificacion > v_notif_antes
      AND tipo_notificacion IN (PKG_CP_ALERTA.c_type_expired,
                                PKG_CP_ALERTA.c_type_customer_credit,
                                PKG_CP_ALERTA.c_type_supplier_manager,
                                PKG_CP_MONITOREO.c_type_tablespace,
                                PKG_CP_MONITOREO.c_type_session,
                                'PRUEBA_NOTIF');

    SELECT COUNT(*) INTO v_count2
    FROM CP_MONITOREO_TABLESPACE WHERE fecha_muestra >= v_start;

    reportar('34. El ROLLBACK deja la base sin avisos ni muestras y con los parametros originales',
             v_count = 0 AND v_count2 = 0
             AND param_text('UMBRAL_CXC_CLIENTE_PCT') = v_orig_cxc
             AND param_text('UMBRAL_CXP_GERENTE_PCT') = v_orig_ger
             AND param_text('MOROSIDAD_DIAS_SIN_PAGO') = v_orig_mora
             AND param_text('TABLESPACE_UMBRAL_PCT') = v_orig_ts
             AND param_text('SESIONES_UMBRAL_PCT') = v_orig_ses
             AND param_text('SESION_BLOQUEO_SEGUNDOS') = v_orig_blk);

    DELETE FROM CP_BITACORA_ERROR
    WHERE id_bitacora_error > v_antes
      AND modulo IN ('AVISO', 'ALERTA', 'MONITOREO', 'MONITOREO_PRUEBA', 'PARAMETRO');
    COMMIT;

    PKG_CP_AVISO.set_enabled(TRUE);

    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'Resultado: ' || v_ok || ' OK, '
                         || v_falla || ' FALLA');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        PKG_CP_AVISO.set_enabled(TRUE);
        DBMS_OUTPUT.PUT_LINE('ERROR en las pruebas: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        RAISE;
END;
/

-- ============================================================
-- 10. JOBS
-- ============================================================
-- Avisos de negocio: diario a las 07:00. Monitoreo diario: 06:30.
-- Sesiones: cada 15 minutos (avisa a lo sumo una vez por hora).
-- JOB_CP_PROCESAR_NOTIFICACIONES (jobs/diarios/) envia la cola cada 15
-- minutos y no se toca aqui. Se vuelven a crear en cada ejecucion.
-- A peticion del profesor (TRUE = aunque ya se haya avisado hoy):
--   EXEC PKG_CP_ALERTA.run_daily(TRUE);
--   EXEC PKG_CP_MONITOREO.run_daily(TRUE);
--   EXEC PKG_CP_MONITOREO.check_sessions(TRUE);
--   EXEC PKG_CP_NOTIFICACIONES.procesar_pendientes;

DECLARE
    PROCEDURE drop_job(
        p_name IN VARCHAR2
    )
    IS
    BEGIN
        DBMS_SCHEDULER.DROP_JOB(p_name, force => TRUE);
    EXCEPTION
        WHEN OTHERS THEN
            -- ORA-27475: el job no existe todavia, no es un error
            IF SQLCODE != -27475 THEN
                RAISE;
            END IF;
    END drop_job;
BEGIN

    drop_job('JOB_CP_ALERTAS_NEGOCIO');
    drop_job('JOB_CP_MONITOREO_DIARIO');
    drop_job('JOB_CP_MONITOREO_SESIONES');

    DBMS_SCHEDULER.CREATE_JOB(
        job_name        => 'JOB_CP_ALERTAS_NEGOCIO',
        job_type        => 'PLSQL_BLOCK',
        job_action      => 'BEGIN PKG_CP_ALERTA.run_daily; END;',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=DAILY;BYHOUR=7;BYMINUTE=0;BYSECOND=0',
        enabled         => TRUE,
        comments        => 'Avisos de credito, cuentas por pagar, mora y productos vencidos.'
    );

    DBMS_SCHEDULER.CREATE_JOB(
        job_name        => 'JOB_CP_MONITOREO_DIARIO',
        job_type        => 'PLSQL_BLOCK',
        job_action      => 'BEGIN PKG_CP_MONITOREO.run_daily; END;',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=DAILY;BYHOUR=6;BYMINUTE=30;BYSECOND=0',
        enabled         => TRUE,
        comments        => 'Crecimiento, tablespaces, objetos invalidos, indices y errores.'
    );

    DBMS_SCHEDULER.CREATE_JOB(
        job_name        => 'JOB_CP_MONITOREO_SESIONES',
        job_type        => 'PLSQL_BLOCK',
        job_action      => 'BEGIN PKG_CP_MONITOREO.check_sessions; END;',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=MINUTELY;INTERVAL=15',
        enabled         => TRUE,
        comments        => 'Uso de sesiones y procesos, y sesiones bloqueadas.'
    );

END;
/

-- Lanza los tres jobs una vez y espera para ver su resultado en el historial
BEGIN
    DBMS_SCHEDULER.RUN_JOB('JOB_CP_MONITOREO_DIARIO', FALSE);
    DBMS_SCHEDULER.RUN_JOB('JOB_CP_MONITOREO_SESIONES', FALSE);
    DBMS_SCHEDULER.RUN_JOB('JOB_CP_ALERTAS_NEGOCIO', FALSE);
    DBMS_SESSION.SLEEP(10);
END;
/

-- ============================================================
-- 11. VERIFICACION
-- ============================================================

-- Paquetes y vistas (todos VALID)
SELECT object_name, object_type, status
FROM   user_objects
WHERE  object_name IN ('PKG_CP_ALERTA', 'PKG_CP_MONITOREO', 'PKG_CP_AVISO',
                       'VW_CP_CLIENTE_CORREO', 'VW_CP_CREDITO_CLIENTE_USO',
                       'VW_CP_CREDITO_PROVEEDOR_USO', 'VW_CP_CLIENTE_MORA',
                       'VW_CP_USO_TABLESPACE', 'VW_CP_CRECIMIENTO_TABLESPACE',
                       'CP_MONITOREO_TABLESPACE')
ORDER  BY object_name, object_type;

-- Los procedimientos sueltos ya no existen (esperado: ninguna fila)
SELECT object_name, object_type
FROM   user_objects
WHERE  object_type = 'PROCEDURE'
  AND  object_name IN ('PRC_CP_ALERTA_CREDITO_85', 'PRC_CP_ALERTA_MORA_CLIENTES',
                       'PRC_CP_NOTIFICACION_MORA_GERENTE_COORDINADOR',
                       'PRC_CP_ALERTA_CXP_COORDINADOR', 'PRC_CP_ALERTA_CXP_GERENTE',
                       'PRC_CP_NOTIFICACION_PRODUCTOS_VENCIDOS_COORD',
                       'VERIFICAR_TABLESPACES', 'VERIFICAR_OBJETOS_INVALIDOS',
                       'VERIFICAR_INDICES');

-- Jobs del modulo
SELECT job_name, enabled, state, repeat_interval, next_run_date
FROM   user_scheduler_jobs
WHERE  job_name IN ('JOB_CP_ALERTAS_NEGOCIO', 'JOB_CP_MONITOREO_DIARIO',
                    'JOB_CP_MONITOREO_SESIONES', 'JOB_CP_PROCESAR_NOTIFICACIONES')
ORDER  BY job_name;

SELECT job_name, status, actual_start_date, run_duration, errors
FROM   user_scheduler_job_run_details
WHERE  job_name IN ('JOB_CP_ALERTAS_NEGOCIO', 'JOB_CP_MONITOREO_DIARIO',
                    'JOB_CP_MONITOREO_SESIONES')
ORDER  BY log_date DESC
FETCH FIRST 3 ROWS ONLY;

-- Uso actual de los tablespaces y ultima muestra de crecimiento
SELECT tablespace_name, mb_usados, mb_maximos, porcentaje_uso
FROM   VW_CP_USO_TABLESPACE
ORDER  BY porcentaje_uso DESC;

SELECT nombre_tablespace, fecha_muestra, mb_usados, crecimiento_mb, dias_desde_anterior
FROM   VW_CP_CRECIMIENTO_TABLESPACE
ORDER  BY fecha_muestra DESC, nombre_tablespace
FETCH FIRST 10 ROWS ONLY;

-- Avisos que dejaron hoy los jobs, por tipo
SELECT tipo_notificacion, COUNT(*) AS avisos
FROM   CP_NOTIFICACION
WHERE  fecha_creacion >= TRUNC(SYSDATE)
  AND  (tipo_notificacion LIKE 'ALERTA%' OR tipo_notificacion LIKE 'MONITOREO%')
GROUP  BY tipo_notificacion
ORDER  BY tipo_notificacion;

-- Errores de hoy del modulo (si el correo no esta configurado, aqui se ve por que)
SELECT modulo, codigo_error, COUNT(*) AS veces, MAX(SUBSTR(mensaje_error, 1, 120)) AS mensaje
FROM   CP_BITACORA_ERROR
WHERE  fecha_hora >= TRUNC(SYSDATE)
  AND  modulo IN ('ALERTA', 'MONITOREO', 'AVISO')
GROUP  BY modulo, codigo_error
ORDER  BY modulo, codigo_error;
