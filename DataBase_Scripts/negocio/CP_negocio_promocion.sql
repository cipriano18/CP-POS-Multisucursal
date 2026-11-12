-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- BASE DE DATOS: Oracle 21c
-- SCRIPT: 30_negocio_promocion.sql
-- DESCRIPCION: Calculo automatico de las acciones que otorga cada
--              promocion en una factura de venta. Vista
--              VW_CP_ACCIONES_PROMOCION (el calculo, en SQL) y paquete
--              PKG_CP_PROMOCION (consulta por regla, total de la
--              factura y texto para mostrar al cliente), trigger de
--              auditoria del tipo de promocion y pruebas.
--
-- REGLAS DEL CALCULO:
--   * Se cuenta POR FACTURA: solo las lineas de producto de esa
--     factura (varias lineas del mismo producto se suman antes).
--   * La promocion aplica si esta ACTIVA, es del mismo negocio que la
--     sucursal de la factura y la fecha de emision cae entre
--     fecha_inicio y fecha_final (inclusive; sin final no vence).
--     Una factura ANULADA no otorga acciones.
--   * Para cada patrocinador de la regla:
--       FLOOR(cantidad comprada / cantidad_requerida)
--     y segun el tipo de la promocion:
--       POR CANTIDAD DE PATROCINADORES -> veces = SUMA de esos valores
--       COMBO DE PATROCINADORES        -> veces = MINIMO de esos valores
--     (en el combo manda el patrocinador que menos alcanza).
--   * acciones otorgadas = veces * cantidad_acciones de la regla.
--     Las unidades de premio = veces * cantidad_premio.
--   * Una regla sin patrocinadores no otorga acciones.
--
-- No necesita job: las acciones se calculan al consultar la factura,
-- asi que siempre reflejan sus lineas y su estado actuales.
--
-- AUDITORIA: TRG_CP_AUD_PROMOCION (Parte 1) no conoce la columna
-- id_tipo_promocion (la agrega el script 26). El trigger
-- TRG_CP_AUD_PROMOCION_TIPO de este script registra cada cambio de tipo
-- en CP_BITACORA_PROMOCION, sin modificar el trigger de la Parte 1.
--
-- ERRORES PROPIOS (tramo -20320 a -20329):
--   -20320 la factura de venta no existe
--
-- EJECUTAR COMO: CP_POS en XEPDB1 (despues del script 26 seccion 2 y
--                de los scripts 15 y 25). Se puede volver a ejecutar
--                completo las veces que haga falta.
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED

-- ============================================================
-- 1. VISTA VW_CP_ACCIONES_PROMOCION
-- ============================================================
-- Una fila por factura y regla de promocion que otorga al menos una
-- accion. El calculo vive aqui (y no repetido en el paquete) para que
-- haya una sola fuente de verdad, consultable tambien con EXPLAIN PLAN.

CREATE OR REPLACE VIEW VW_CP_ACCIONES_PROMOCION AS
WITH vendido AS (
    -- Cantidad comprada por producto en cada factura
    SELECT d.id_factura_venta, d.id_producto, SUM(d.cantidad) AS cantidad
    FROM CP_DETALLE_VENTA_PRODUCTO d
    GROUP BY d.id_factura_venta, d.id_producto
),
aplicable AS (
    -- Reglas de las promociones vigentes para cada factura
    SELECT f.id_factura_venta, f.numero_factura,
           pr.id_promocion, pr.nombre_promocion, tp.nombre_tipo_promocion,
           r.id_regla_promocion, ac.nombre_accion_promocion, r.cantidad_acciones
    FROM CP_FACTURA_VENTA f
    JOIN CP_ESTADO_FACTURA_VENTA ef
      ON ef.id_estado_factura_venta = f.id_estado_factura_venta
    JOIN CP_SUCURSAL s
      ON s.id_sucursal = f.id_sucursal
    JOIN CP_PROMOCION pr
      ON pr.id_negocio = s.id_negocio
    JOIN CP_ESTADO_PROMOCION ep
      ON ep.id_estado_promocion = pr.id_estado_promocion
    JOIN CP_TIPO_PROMOCION tp
      ON tp.id_tipo_promocion = pr.id_tipo_promocion
    JOIN CP_REGLA_PROMOCION r
      ON r.id_promocion = pr.id_promocion
    JOIN CP_ACCION_PROMOCION ac
      ON ac.id_accion_promocion = r.id_accion_promocion
    WHERE ef.nombre_estado_factura <> 'ANULADA'
      AND ep.nombre_estado_promocion = 'ACTIVA'
      AND f.fecha_emision >= pr.fecha_inicio
      AND (pr.fecha_final IS NULL OR f.fecha_emision < pr.fecha_final + 1)
),
veces AS (
    -- Cuantas veces se cumple cada regla; un patrocinador que no se
    -- compro cuenta 0 (LEFT JOIN + NVL). Un tipo que esta vista no
    -- conoce da NULL y no aparece: hay que programar su calculo.
    SELECT ap.id_factura_venta, ap.numero_factura, ap.id_promocion,
           ap.nombre_promocion, ap.nombre_tipo_promocion,
           ap.id_regla_promocion, ap.nombre_accion_promocion,
           ap.cantidad_acciones,
           CASE ap.nombre_tipo_promocion
               WHEN 'POR CANTIDAD DE PATROCINADORES'
                   THEN SUM(FLOOR(NVL(v.cantidad, 0) / pp.cantidad_requerida))
               WHEN 'COMBO DE PATROCINADORES'
                   THEN MIN(FLOOR(NVL(v.cantidad, 0) / pp.cantidad_requerida))
           END AS veces_cumplida
    FROM aplicable ap
    JOIN CP_PROMOCION_PATROCINADOR pp
      ON pp.id_regla_promocion = ap.id_regla_promocion
    LEFT JOIN vendido v
      ON v.id_factura_venta = ap.id_factura_venta
     AND v.id_producto = pp.id_producto
    GROUP BY ap.id_factura_venta, ap.numero_factura, ap.id_promocion,
             ap.nombre_promocion, ap.nombre_tipo_promocion,
             ap.id_regla_promocion, ap.nombre_accion_promocion,
             ap.cantidad_acciones
)
SELECT id_factura_venta, numero_factura, id_promocion, nombre_promocion,
       nombre_tipo_promocion, id_regla_promocion, nombre_accion_promocion,
       cantidad_acciones, veces_cumplida,
       veces_cumplida * cantidad_acciones AS acciones_otorgadas
FROM veces
WHERE veces_cumplida > 0;

COMMENT ON TABLE VW_CP_ACCIONES_PROMOCION IS
'Acciones que otorga cada regla de promocion en cada factura de venta (solo las que otorgan al menos una).';
COMMENT ON COLUMN VW_CP_ACCIONES_PROMOCION.veces_cumplida IS
'Veces que la factura cumple la regla segun el tipo de promocion (suma o minimo por patrocinador).';
COMMENT ON COLUMN VW_CP_ACCIONES_PROMOCION.acciones_otorgadas IS
'veces_cumplida multiplicado por cantidad_acciones de la regla.';

-- ============================================================
-- 2. PAQUETE PKG_CP_PROMOCION (ESPECIFICACION)
-- ============================================================

CREATE OR REPLACE PACKAGE PKG_CP_PROMOCION AUTHID DEFINER AS

    -- Nombres de CP_TIPO_PROMOCION que la vista sabe calcular
    c_type_by_quantity CONSTANT VARCHAR2(50) := 'POR CANTIDAD DE PATROCINADORES';
    c_type_combo       CONSTANT VARCHAR2(50) := 'COMBO DE PATROCINADORES';

    -- Acciones que otorga una regla en una factura (0 si no aplica).
    FUNCTION rule_actions(
        p_id_factura_venta   IN NUMBER,
        p_id_regla_promocion IN NUMBER
    ) RETURN NUMBER;

    -- Suma de las acciones de todas las promociones de la factura.
    FUNCTION invoice_actions(
        p_id_factura_venta IN NUMBER
    ) RETURN NUMBER;

    -- Texto con cada promocion que aplica, sus acciones y sus premios.
    FUNCTION actions_text(
        p_id_factura_venta IN NUMBER
    ) RETURN VARCHAR2;

    -- Muestra actions_text con DBMS_OUTPUT (para la caja o la defensa).
    PROCEDURE show_actions(
        p_id_factura_venta IN NUMBER
    );

END PKG_CP_PROMOCION;
/

-- ============================================================
-- 3. PAQUETE PKG_CP_PROMOCION (CUERPO)
-- ============================================================
-- Solo lee datos: por eso no usa SAVEPOINT ni COMMIT. Cada rutina
-- tiene su manejador de excepciones, que registra lo inesperado en la
-- bitacora de errores y vuelve a lanzar el error.

CREATE OR REPLACE PACKAGE BODY PKG_CP_PROMOCION AS

    c_modulo CONSTANT VARCHAR2(20) := 'PROMOCION';

    c_err_factura CONSTANT PLS_INTEGER := -20320;


    -- Lanza -20320 si la factura no existe (un 0 seria enganoso).
    PROCEDURE check_invoice(
        p_id_factura_venta IN NUMBER
    )
    IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM CP_FACTURA_VENTA
        WHERE id_factura_venta = p_id_factura_venta;

        IF v_count = 0 THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_factura,
                'La factura de venta ' || NVL(TO_CHAR(p_id_factura_venta), '<NULL>')
                || ' no existe.'
            );
        END IF;
    END check_invoice;


    FUNCTION rule_actions(
        p_id_factura_venta   IN NUMBER,
        p_id_regla_promocion IN NUMBER
    ) RETURN NUMBER
    IS
        v_actions NUMBER;
    BEGIN
        check_invoice(p_id_factura_venta);

        SELECT NVL(SUM(acciones_otorgadas), 0) INTO v_actions
        FROM VW_CP_ACCIONES_PROMOCION
        WHERE id_factura_venta = p_id_factura_venta
          AND id_regla_promocion = p_id_regla_promocion;

        RETURN v_actions;
    EXCEPTION
        WHEN OTHERS THEN
            PKG_CP_ERROR.registrar_inesperado(
                c_modulo,
                'factura=' || p_id_factura_venta || ' regla=' || p_id_regla_promocion
            );
            RAISE;
    END rule_actions;


    FUNCTION invoice_actions(
        p_id_factura_venta IN NUMBER
    ) RETURN NUMBER
    IS
        v_actions NUMBER;
    BEGIN
        check_invoice(p_id_factura_venta);

        SELECT NVL(SUM(acciones_otorgadas), 0) INTO v_actions
        FROM VW_CP_ACCIONES_PROMOCION
        WHERE id_factura_venta = p_id_factura_venta;

        RETURN v_actions;
    EXCEPTION
        WHEN OTHERS THEN
            PKG_CP_ERROR.registrar_inesperado(c_modulo, 'factura=' || p_id_factura_venta);
            RAISE;
    END invoice_actions;


    FUNCTION actions_text(
        p_id_factura_venta IN NUMBER
    ) RETURN VARCHAR2
    IS
        v_number CP_FACTURA_VENTA.numero_factura%TYPE;
        v_text   VARCHAR2(32767);
        v_lines  PLS_INTEGER := 0;
    BEGIN
        check_invoice(p_id_factura_venta);

        SELECT numero_factura INTO v_number
        FROM CP_FACTURA_VENTA
        WHERE id_factura_venta = p_id_factura_venta;

        FOR r IN (SELECT a.nombre_promocion, a.nombre_tipo_promocion,
                         a.nombre_accion_promocion, a.veces_cumplida,
                         a.acciones_otorgadas,
                         -- Premios de la regla: unidades = veces * cantidad_premio
                         (SELECT LISTAGG(p.nombre_producto || ' x '
                                         || TO_CHAR(a.veces_cumplida * pz.cantidad_premio),
                                         ', ')
                                 WITHIN GROUP (ORDER BY p.nombre_producto)
                          FROM CP_PROMOCION_PREMIO pz
                          JOIN CP_PRODUCTO p
                            ON p.id_producto = pz.id_producto_premio
                          WHERE pz.id_regla_promocion = a.id_regla_promocion) AS premios
                  FROM VW_CP_ACCIONES_PROMOCION a
                  WHERE a.id_factura_venta = p_id_factura_venta
                  ORDER BY a.nombre_promocion, a.id_regla_promocion) LOOP

            v_lines := v_lines + 1;
            v_text := v_text || CHR(10) || '- ' || r.nombre_promocion
                      || ' [' || r.nombre_tipo_promocion || ']: '
                      || r.veces_cumplida
                      || CASE WHEN r.veces_cumplida = 1 THEN ' vez -> ' ELSE ' veces -> ' END
                      || r.acciones_otorgadas
                      || CASE WHEN r.acciones_otorgadas = 1 THEN ' accion ' ELSE ' acciones ' END
                      || r.nombre_accion_promocion
                      || CASE WHEN r.premios IS NOT NULL
                              THEN ' | premio: ' || r.premios END;
        END LOOP;

        IF v_lines = 0 THEN
            RETURN 'Factura ' || v_number || ': ninguna promocion aplica.';
        END IF;

        RETURN 'Factura ' || v_number || ': ' || v_lines
               || ' regla(s) de promocion aplican.' || v_text;
    EXCEPTION
        WHEN OTHERS THEN
            PKG_CP_ERROR.registrar_inesperado(c_modulo, 'factura=' || p_id_factura_venta);
            RAISE;
    END actions_text;


    PROCEDURE show_actions(
        p_id_factura_venta IN NUMBER
    )
    IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(actions_text(p_id_factura_venta));
    EXCEPTION
        WHEN OTHERS THEN
            PKG_CP_ERROR.registrar_inesperado(c_modulo, 'factura=' || p_id_factura_venta);
            RAISE;
    END show_actions;

END PKG_CP_PROMOCION;
/

SHOW ERRORS PACKAGE BODY PKG_CP_PROMOCION

-- ============================================================
-- 3B. AUDITORIA DEL TIPO DE PROMOCION
-- ============================================================
-- Solo registra cambios (UPDATE): el tipo inicial de una promocion se
-- conoce por su fila actual o por el valor_anterior de su primer cambio,
-- asi que registrar tambien el INSERT duplicaria la fila que ya escribe
-- TRG_CP_AUD_PROMOCION. Mismo formato columna=valor de la Parte 1, con el
-- nombre del tipo para que la bitacora se lea sin consultar el catalogo.

CREATE OR REPLACE TRIGGER TRG_CP_AUD_PROMOCION_TIPO
AFTER UPDATE OF id_tipo_promocion ON CP_PROMOCION
FOR EACH ROW
WHEN (NVL(OLD.id_tipo_promocion, -1) <> NVL(NEW.id_tipo_promocion, -1))
DECLARE
    v_old_text CP_BITACORA_PROMOCION.valor_anterior%TYPE;
    v_new_text CP_BITACORA_PROMOCION.valor_nuevo%TYPE;

    -- id y nombre del tipo, por ejemplo: 2 (COMBO DE PATROCINADORES)
    FUNCTION type_text(
        p_id_tipo IN NUMBER
    ) RETURN VARCHAR2
    IS
        v_name CP_TIPO_PROMOCION.nombre_tipo_promocion%TYPE;
    BEGIN
        SELECT MAX(nombre_tipo_promocion) INTO v_name
        FROM CP_TIPO_PROMOCION
        WHERE id_tipo_promocion = p_id_tipo;

        RETURN 'id_tipo_promocion=' || NVL(TO_CHAR(p_id_tipo), '<NULL>')
               || CASE WHEN v_name IS NOT NULL THEN ' (' || v_name || ')' END;
    END type_text;
BEGIN
    -- Una funcion local no se puede llamar dentro de un SQL (PLS-00231),
    -- por eso los textos se calculan antes del INSERT.
    v_old_text := type_text(:OLD.id_tipo_promocion);
    v_new_text := type_text(:NEW.id_tipo_promocion);

    INSERT INTO CP_BITACORA_PROMOCION (
        id_promocion, id_usuario, operacion,
        valor_anterior, valor_nuevo, fecha_hora
    ) VALUES (
        :NEW.id_promocion, PKG_CP_CONTEXTO.g_id_usuario, 'MODIFICACION',
        v_old_text, v_new_text,
        SYSTIMESTAMP
    );
END;
/

SHOW ERRORS TRIGGER TRG_CP_AUD_PROMOCION_TIPO

-- ============================================================
-- 4. PRUEBAS DEL CALCULO
-- ============================================================
-- Todas deben salir OK. Se ejecutan como CP_POS y todo se deshace con
-- ROLLBACK (compras y ventas con p_commit => FALSE). Se compran dos
-- productos (A y B) en una sucursal con un solo almacen activo, se
-- crean promociones de prueba T30-... en el negocio de esa sucursal y
-- se registran ventas con distintas cantidades. Las pruebas miran solo
-- las promociones de prueba, asi que no importan las promociones reales
-- (que tambien pueden aplicar a estas ventas).
--
-- Promociones de prueba (regla -> patrocinadores):
--   CANT    POR CANTIDAD, 1 accion por vez, A x2, premio B x1
--   COMBO   COMBO,        1 accion por vez, A x2 + B x1
--   PUNTOS  POR CANTIDAD, 5 acciones por vez (puntos), A x3
--   SUMA    POR CANTIDAD, 1 accion por vez, A x2 + B x2
--   SUSP    SUSPENDIDA, A x1          VIEJA  vigencia terminada, A x1
--   FUTURA  empieza en 5 dias, A x1

DECLARE
    v_antes       NUMBER;
    v_ok          NUMBER := 0;
    v_falla       NUMBER := 0;

    v_today       DATE         := TRUNC(SYSDATE);
    v_stamp       VARCHAR2(20) := TO_CHAR(SYSDATE, 'MMDDHH24MISS');

    v_almacen     NUMBER;
    v_sucursal    NUMBER;
    v_negocio     NUMBER;
    v_cliente     NUMBER;
    v_user        NUMBER;

    v_pp_a        NUMBER;
    v_pp_b        NUMBER;
    v_prov_a      NUMBER;
    v_prov_b      NUMBER;
    v_prod_a      NUMBER;
    v_prod_b      NUMBER;
    v_name_b      CP_PRODUCTO.nombre_producto%TYPE;

    v_buy_a       NUMBER;
    v_buy_b       NUMBER;

    r_cant        NUMBER;
    r_combo       NUMBER;
    r_puntos      NUMBER;
    r_suma        NUMBER;
    r_susp        NUMBER;
    r_vieja       NUMBER;
    r_futura      NUMBER;

    s1            NUMBER;
    s2            NUMBER;
    s3            NUMBER;
    s4            NUMBER;
    v_code        NUMBER;
    v_count       NUMBER;
    v_total       NUMBER;
    v_text        VARCHAR2(32767);
    v_promo       NUMBER;

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

    -- Compra de contado de 20 unidades al almacen de prueba; 0 si salio bien
    FUNCTION buy(
        p_pp     IN NUMBER,
        p_prov   IN NUMBER,
        p_suffix IN VARCHAR2
    ) RETURN NUMBER
    IS
        v_lots    PKG_CP_FACTURACION.t_lineas_compra;
        v_invoice NUMBER;
    BEGIN
        v_lots(1).id_producto_proveedor := p_pp;
        v_lots(1).cantidad := 20;
        v_lots(1).precio_costo_unitario := 1000;
        v_lots(1).numero_lote := 'T30-' || p_suffix || '-' || v_stamp;
        v_lots(1).fecha_vencimiento := v_today + 60;

        PKG_CP_FACTURACION.registrar_compra(
            p_id_proveedor         => p_prov,
            p_id_negocio           => v_negocio,
            p_id_almacen_recepcion => v_almacen,
            p_id_usuario           => v_user,
            p_numero_factura       => 'T30-C' || p_suffix || '-' || v_stamp,
            p_lineas               => v_lots,
            p_id_factura           => v_invoice,
            p_a_credito            => FALSE,
            p_commit               => FALSE
        );
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('  compra ' || p_suffix || ': ' || SQLERRM);
            RETURN SQLCODE;
    END buy;

    -- Venta de contado. Cada cantidad > 0 es una linea; p_qty_a2 agrega
    -- una segunda linea del producto A (para probar que se suman).
    FUNCTION sell(
        p_suffix IN VARCHAR2,
        p_qty_a  IN NUMBER,
        p_qty_b  IN NUMBER,
        p_qty_a2 IN NUMBER DEFAULT 0
    ) RETURN NUMBER
    IS
        v_lines PKG_CP_FACTURACION.t_lineas_venta;
        v_n     PLS_INTEGER := 0;
        v_id    NUMBER;

        PROCEDURE add_line(p_product IN NUMBER, p_qty IN NUMBER) IS
        BEGIN
            IF p_qty > 0 THEN
                v_n := v_n + 1;
                v_lines(v_n).id_producto := p_product;
                v_lines(v_n).cantidad := p_qty;
                v_lines(v_n).precio_unitario := 1500;
            END IF;
        END add_line;
    BEGIN
        add_line(v_prod_a, p_qty_a);
        add_line(v_prod_b, p_qty_b);
        add_line(v_prod_a, p_qty_a2);

        PKG_CP_FACTURACION.registrar_venta(
            p_id_cliente     => v_cliente,
            p_id_sucursal    => v_sucursal,
            p_id_usuario     => v_user,
            p_numero_factura => 'T30-V' || p_suffix || '-' || v_stamp,
            p_lineas         => v_lines,
            p_id_factura     => v_id,
            p_a_credito      => FALSE,
            p_commit         => FALSE
        );
        RETURN v_id;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('  venta ' || p_suffix || ': ' || SQLERRM);
            RETURN NULL;
    END sell;

    -- Crea una promocion de prueba con una regla y devuelve la regla
    FUNCTION make_rule(
        p_name    IN VARCHAR2,
        p_type    IN VARCHAR2,
        p_state   IN VARCHAR2,
        p_start   IN DATE,
        p_end     IN DATE,
        p_action  IN VARCHAR2,
        p_actions IN NUMBER
    ) RETURN NUMBER
    IS
        v_promo NUMBER;
        v_rule  NUMBER;
    BEGIN
        INSERT INTO CP_PROMOCION
            (id_estado_promocion, id_negocio, id_tipo_promocion,
             nombre_promocion, descripcion, fecha_inicio, fecha_final)
        VALUES
            ((SELECT id_estado_promocion FROM CP_ESTADO_PROMOCION
              WHERE nombre_estado_promocion = p_state),
             v_negocio,
             (SELECT id_tipo_promocion FROM CP_TIPO_PROMOCION
              WHERE nombre_tipo_promocion = p_type),
             'T30-' || p_name || '-' || v_stamp, 'Promocion de prueba',
             p_start, p_end)
        RETURNING id_promocion INTO v_promo;

        INSERT INTO CP_REGLA_PROMOCION
            (id_promocion, id_accion_promocion, cantidad_acciones, descripcion)
        VALUES
            (v_promo,
             (SELECT id_accion_promocion FROM CP_ACCION_PROMOCION
              WHERE nombre_accion_promocion = p_action),
             p_actions, 'Regla de prueba')
        RETURNING id_regla_promocion INTO v_rule;

        RETURN v_rule;
    END make_rule;

    PROCEDURE add_sponsor(p_rule IN NUMBER, p_product IN NUMBER, p_qty IN NUMBER) IS
    BEGIN
        INSERT INTO CP_PROMOCION_PATROCINADOR (id_regla_promocion, id_producto, cantidad_requerida)
        VALUES (p_rule, p_product, p_qty);
    END add_sponsor;

    PROCEDURE add_prize(p_rule IN NUMBER, p_product IN NUMBER, p_qty IN NUMBER) IS
    BEGIN
        INSERT INTO CP_PROMOCION_PREMIO (id_regla_promocion, id_producto_premio, cantidad_premio)
        VALUES (p_rule, p_product, p_qty);
    END add_prize;

    -- Acciones de una regla en una factura; NULL si la factura no se creo
    FUNCTION acts(p_invoice IN NUMBER, p_rule IN NUMBER) RETURN NUMBER IS
    BEGIN
        IF p_invoice IS NULL THEN
            RETURN NULL;
        END IF;
        RETURN PKG_CP_PROMOCION.rule_actions(p_invoice, p_rule);
    END acts;

BEGIN

    SELECT NVL(MAX(id_bitacora_error), 0) INTO v_antes FROM CP_BITACORA_ERROR;

    -- Sucursal con un solo almacen activo (el inventario de venta sale de ahi)
    SELECT a.id_almacen, a.id_sucursal, s.id_negocio
    INTO v_almacen, v_sucursal, v_negocio
    FROM CP_ALMACEN a
    JOIN CP_ESTADO e
      ON e.id_estado = a.id_estado
    JOIN CP_SUCURSAL s
      ON s.id_sucursal = a.id_sucursal
    WHERE e.nombre = 'ACTIVO'
      AND (SELECT COUNT(*)
           FROM CP_ALMACEN a2
           JOIN CP_ESTADO e2
             ON e2.id_estado = a2.id_estado
           WHERE a2.id_sucursal = a.id_sucursal
             AND e2.nombre = 'ACTIVO') = 1
    ORDER BY a.id_almacen
    FETCH FIRST 1 ROW ONLY;

    SELECT MIN(id_cliente) INTO v_cliente FROM CP_CLIENTE;
    SELECT MIN(id_usuario) INTO v_user FROM CP_USUARIO;

    -- Dos productos distintos con su proveedor
    SELECT id_producto_proveedor, id_proveedor, id_producto
    INTO v_pp_a, v_prov_a, v_prod_a
    FROM CP_PRODUCTO_PROVEEDOR
    ORDER BY id_producto_proveedor
    FETCH FIRST 1 ROW ONLY;

    SELECT id_producto_proveedor, id_proveedor, id_producto
    INTO v_pp_b, v_prov_b, v_prod_b
    FROM CP_PRODUCTO_PROVEEDOR
    WHERE id_producto <> v_prod_a
    ORDER BY id_producto_proveedor
    FETCH FIRST 1 ROW ONLY;

    SELECT nombre_producto INTO v_name_b FROM CP_PRODUCTO WHERE id_producto = v_prod_b;

    v_buy_a := buy(v_pp_a, v_prov_a, 'A');
    v_buy_b := buy(v_pp_b, v_prov_b, 'B');

    reportar('1. Las compras de prueba dejaron existencia de A y de B',
             v_buy_a = 0 AND v_buy_b = 0);

    -- ------------------------------------------------------------
    -- A. Modelo (script 26 seccion 2)
    -- ------------------------------------------------------------
    SELECT COUNT(*) INTO v_count FROM CP_PROMOCION WHERE id_tipo_promocion IS NULL;
    reportar('2. Ninguna promocion existente quedo sin tipo', v_count = 0);

    SELECT COUNT(*) INTO v_count
    FROM CP_TIPO_PROMOCION
    WHERE nombre_tipo_promocion IN (PKG_CP_PROMOCION.c_type_by_quantity,
                                    PKG_CP_PROMOCION.c_type_combo);
    reportar('3. Existen los dos tipos de promocion que se calculan', v_count = 2);

    BEGIN
        INSERT INTO CP_PROMOCION
            (id_estado_promocion, id_negocio, nombre_promocion, fecha_inicio)
        SELECT id_estado_promocion, v_negocio, 'T30-SINTIPO-' || v_stamp, v_today
        FROM CP_ESTADO_PROMOCION WHERE nombre_estado_promocion = 'ACTIVA';
        v_code := 0;
    EXCEPTION
        WHEN OTHERS THEN
            v_code := SQLCODE;
    END;
    reportar('4. Una promocion sin tipo se rechaza (ORA-01400)', v_code = -1400);

    -- ------------------------------------------------------------
    -- B. Promociones de prueba
    -- ------------------------------------------------------------
    r_cant := make_rule('CANT', PKG_CP_PROMOCION.c_type_by_quantity, 'ACTIVA',
                        v_today - 1, v_today + 30, 'ENTREGAR PRODUCTO', 1);
    add_sponsor(r_cant, v_prod_a, 2);
    add_prize(r_cant, v_prod_b, 1);

    r_combo := make_rule('COMBO', PKG_CP_PROMOCION.c_type_combo, 'ACTIVA',
                         v_today - 1, v_today + 30, 'ENTREGAR PRODUCTO', 1);
    add_sponsor(r_combo, v_prod_a, 2);
    add_sponsor(r_combo, v_prod_b, 1);

    r_puntos := make_rule('PUNTOS', PKG_CP_PROMOCION.c_type_by_quantity, 'ACTIVA',
                          v_today - 1, NULL, 'ACUMULAR PUNTOS', 5);
    add_sponsor(r_puntos, v_prod_a, 3);

    r_suma := make_rule('SUMA', PKG_CP_PROMOCION.c_type_by_quantity, 'ACTIVA',
                        v_today - 1, v_today + 30, 'ENTREGAR PRODUCTO', 1);
    add_sponsor(r_suma, v_prod_a, 2);
    add_sponsor(r_suma, v_prod_b, 2);

    r_susp := make_rule('SUSP', PKG_CP_PROMOCION.c_type_by_quantity, 'SUSPENDIDA',
                        v_today - 1, v_today + 30, 'ENTREGAR PRODUCTO', 1);
    add_sponsor(r_susp, v_prod_a, 1);

    r_vieja := make_rule('VIEJA', PKG_CP_PROMOCION.c_type_by_quantity, 'ACTIVA',
                         v_today - 30, v_today - 1, 'ENTREGAR PRODUCTO', 1);
    add_sponsor(r_vieja, v_prod_a, 1);

    r_futura := make_rule('FUTURA', PKG_CP_PROMOCION.c_type_by_quantity, 'ACTIVA',
                          v_today + 5, v_today + 30, 'ENTREGAR PRODUCTO', 1);
    add_sponsor(r_futura, v_prod_a, 1);

    -- ------------------------------------------------------------
    -- C. Venta 1: 5 de A
    -- ------------------------------------------------------------
    s1 := sell('1', 5, 0);

    reportar('5. POR CANTIDAD: 5 de A pidiendo 2 da 2 acciones',
             acts(s1, r_cant) = 2);

    reportar('6. COMBO: sin el producto B no se otorga ninguna accion',
             acts(s1, r_combo) = 0);

    reportar('7. Cada vez otorga cantidad_acciones (5 de A pidiendo 3 = 1 x 5)',
             acts(s1, r_puntos) = 5);

    reportar('8. Una promocion SUSPENDIDA no otorga acciones',
             acts(s1, r_susp) = 0);

    reportar('9. Una promocion con la vigencia terminada no otorga acciones',
             acts(s1, r_vieja) = 0);

    reportar('10. Una promocion que aun no empieza no otorga acciones',
             acts(s1, r_futura) = 0);

    -- ------------------------------------------------------------
    -- D. Venta 2: 4 de A y 3 de B
    -- ------------------------------------------------------------
    s2 := sell('2', 4, 3);

    reportar('11. COMBO: manda el patrocinador que menos alcanza (min(2,3) = 2)',
             acts(s2, r_combo) = 2);

    reportar('12. POR CANTIDAD con dos patrocinadores suma (2 + 1 = 3)',
             acts(s2, r_suma) = 3);

    -- ------------------------------------------------------------
    -- E. Venta 3 (1 de A) y venta 4 (1 + 3 de A en dos lineas)
    -- ------------------------------------------------------------
    s3 := sell('3', 1, 0);
    v_count := NULL;

    IF s3 IS NOT NULL THEN
        SELECT COUNT(*) INTO v_count
        FROM VW_CP_ACCIONES_PROMOCION
        WHERE id_factura_venta = s3 AND id_regla_promocion = r_cant;
    END IF;

    reportar('13. Debajo del minimo da 0 y la vista no muestra la regla',
             acts(s3, r_cant) = 0 AND v_count = 0);

    s4 := sell('4', 1, 0, 3);

    reportar('14. Varias lineas del mismo producto se suman antes de dividir',
             acts(s4, r_cant) = 2);

    -- ------------------------------------------------------------
    -- F. Total, texto y anulacion
    -- ------------------------------------------------------------
    -- Venta 2 en las promociones de prueba: CANT 2 + COMBO 2 + PUNTOS 5 + SUMA 3
    v_count := NULL;
    v_total := NULL;
    v_code  := NULL;

    IF s2 IS NOT NULL THEN
        SELECT NVL(SUM(acciones_otorgadas), 0) INTO v_count
        FROM VW_CP_ACCIONES_PROMOCION
        WHERE id_factura_venta = s2 AND nombre_promocion LIKE 'T30-%';

        SELECT NVL(SUM(acciones_otorgadas), 0) INTO v_total
        FROM VW_CP_ACCIONES_PROMOCION
        WHERE id_factura_venta = s2;

        v_code := PKG_CP_PROMOCION.invoice_actions(s2);
    END IF;

    reportar('15. La venta 2 suma 12 acciones y el total coincide con la vista',
             v_count = 12 AND v_code = v_total);

    IF s1 IS NOT NULL THEN
        v_text := PKG_CP_PROMOCION.actions_text(s1);
        PKG_CP_PROMOCION.show_actions(s1);
    END IF;

    reportar('16. El texto nombra la promocion y su premio',
             INSTR(v_text, 'T30-CANT-') > 0 AND INSTR(v_text, v_name_b || ' x 2') > 0);

    BEGIN
        PKG_CP_FACTURACION.anular_venta(s1, FALSE);
        v_code := 0;
    EXCEPTION
        WHEN OTHERS THEN
            v_code := SQLCODE;
            DBMS_OUTPUT.PUT_LINE('  anular venta 1: ' || SQLERRM);
    END;

    reportar('17. Una factura ANULADA ya no otorga acciones',
             v_code = 0 AND acts(s1, r_cant) = 0);

    BEGIN
        v_count := PKG_CP_PROMOCION.rule_actions(-1, r_cant);
        v_code := 0;
    EXCEPTION
        WHEN OTHERS THEN
            v_code := SQLCODE;
    END;

    reportar('18. Una factura que no existe da el error -20320',
             v_code = -20320);

    -- Cambiar el tipo de la promocion SUMA queda en la bitacora de promociones
    SELECT id_promocion INTO v_promo
    FROM CP_REGLA_PROMOCION WHERE id_regla_promocion = r_suma;

    UPDATE CP_PROMOCION
    SET id_tipo_promocion = (SELECT id_tipo_promocion FROM CP_TIPO_PROMOCION
                             WHERE nombre_tipo_promocion = PKG_CP_PROMOCION.c_type_combo)
    WHERE id_promocion = v_promo;

    SELECT COUNT(*) INTO v_count
    FROM CP_BITACORA_PROMOCION
    WHERE id_promocion = v_promo
      AND operacion = 'MODIFICACION'
      AND DBMS_LOB.INSTR(valor_anterior, PKG_CP_PROMOCION.c_type_by_quantity) > 0
      AND DBMS_LOB.INSTR(valor_nuevo, PKG_CP_PROMOCION.c_type_combo) > 0;

    reportar('19. Cambiar el tipo de una promocion queda en la bitacora',
             v_count = 1);

    -- ------------------------------------------------------------
    -- G. Limpieza
    -- ------------------------------------------------------------
    SELECT COUNT(*) INTO v_count
    FROM CP_BITACORA_ERROR
    WHERE id_bitacora_error > v_antes
      AND modulo = 'PROMOCION'
      AND codigo_error <> -20320;

    reportar('20. No quedaron errores inesperados en la bitacora',
             v_count = 0);

    ROLLBACK;

    SELECT COUNT(*) INTO v_count
    FROM CP_PROMOCION WHERE nombre_promocion LIKE 'T30-%';

    reportar('21. El ROLLBACK deja la base sin las promociones de prueba',
             v_count = 0);

    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'Resultado: ' || v_ok || ' OK, '
                         || v_falla || ' FALLA');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR en las pruebas: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        RAISE;
END;
/

-- ============================================================
-- 5. CONSULTA DE EJEMPLO (para la defensa)
-- ============================================================
-- Acciones de las facturas reales que ya cumplen alguna promocion:
--   EXEC PKG_CP_PROMOCION.show_actions(<id_factura_venta>);

SELECT numero_factura, nombre_promocion, nombre_tipo_promocion,
       veces_cumplida, acciones_otorgadas, nombre_accion_promocion
FROM   VW_CP_ACCIONES_PROMOCION
ORDER  BY id_factura_venta DESC, nombre_promocion
FETCH FIRST 10 ROWS ONLY;
