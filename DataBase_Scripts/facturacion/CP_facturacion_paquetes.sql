-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- BASE DE DATOS: Oracle 21c
-- SCRIPT: 20_facturacion_paquetes.sql
-- DESCRIPCION: Estados de factura PENDIENTE y CANCELADA, parametros
--              de plazo de credito, paquete PKG_CP_CREDITO (limites
--              de credito de clientes y proveedores), paquete
--              PKG_CP_CUENTA (crea la cuenta cuando la factura pasa a
--              PENDIENTE, la anula con la factura y aplica cada abono
--              al saldo y al estado) y los triggers de facturas y
--              abonos, con sus pruebas.
--
-- EJECUTAR COMO: CP_POS en XEPDB1 (despues de los scripts 15, 18 y
--                19). Se puede volver a ejecutar completo las veces
--                que haga falta.
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED

-- ============================================================
-- 1. ESTADOS DE FACTURA
-- ============================================================
-- El enunciado habla de facturas pendientes que pasan a canceladas.
-- En venta, CREDITO pasa a PENDIENTE y PAGADA a CANCELADA; en compra,
-- PAGADA pasa a CANCELADA. EMITIDA queda para la venta de contado.
-- Cada UPDATE busca el nombre viejo, por lo que se puede repetir.

UPDATE CP_ESTADO_FACTURA_VENTA
SET nombre_estado_factura = 'PENDIENTE',
    descripcion = 'Factura a credito pendiente de pago'
WHERE nombre_estado_factura = 'CREDITO';

UPDATE CP_ESTADO_FACTURA_VENTA
SET nombre_estado_factura = 'CANCELADA',
    descripcion = 'Factura cancelada totalmente'
WHERE nombre_estado_factura = 'PAGADA';

UPDATE CP_ESTADO_FACTURA_COMPRA
SET nombre_estado_factura = 'CANCELADA',
    descripcion = 'Factura cancelada totalmente'
WHERE nombre_estado_factura = 'PAGADA';

COMMIT;

SELECT 'VENTA' AS tipo, nombre_estado_factura, descripcion
FROM CP_ESTADO_FACTURA_VENTA
UNION ALL
SELECT 'COMPRA', nombre_estado_factura, descripcion
FROM CP_ESTADO_FACTURA_COMPRA
ORDER BY 1, 2;

-- ============================================================
-- 2. PARAMETROS DE PLAZO
-- ============================================================
-- Dias que tiene un cliente (o la empresa con un proveedor) para
-- pagar una factura a credito. Solo se insertan si no existen, por
-- lo que un valor ya cambiado no se pisa al repetir el script.

MERGE INTO CP_PARAMETRO p
USING (
    SELECT 'PLAZO_CREDITO_CLIENTE_DIAS' AS codigo_parametro,
           'Dias de plazo para pagar una factura de venta a credito.' AS descripcion
    FROM DUAL
    UNION ALL
    SELECT 'PLAZO_CREDITO_PROVEEDOR_DIAS',
           'Dias de plazo para pagar una factura de compra a credito.'
    FROM DUAL
) n
ON (p.codigo_parametro = n.codigo_parametro)
WHEN NOT MATCHED THEN
    INSERT (codigo_parametro, modulo, tipo_dato, unidad, valor, descripcion)
    VALUES (n.codigo_parametro, 'FACTURACION', 'NUMERO', 'DIAS', '30', n.descripcion);

COMMIT;

SELECT codigo_parametro, valor, unidad
FROM CP_PARAMETRO
WHERE modulo = 'FACTURACION'
ORDER BY codigo_parametro;

-- ============================================================
-- 3. PAQUETE PKG_CP_CREDITO (ESPECIFICACION)
-- ============================================================
-- Valida el limite de credito de clientes y proveedores. Solo lo
-- llama PKG_CP_CUENTA al crear una cuenta.
-- Errores propios: -20260 a -20264.

CREATE OR REPLACE PACKAGE PKG_CP_CREDITO AUTHID DEFINER AS

    PROCEDURE validar_cliente(
        p_id_cliente IN  NUMBER,
        p_id_negocio IN  NUMBER,
        p_monto      IN  NUMBER,
        p_id_credito OUT NUMBER
    )
    ACCESSIBLE BY (PACKAGE PKG_CP_CUENTA);

    PROCEDURE validar_proveedor(
        p_id_proveedor IN  NUMBER,
        p_id_negocio   IN  NUMBER,
        p_monto        IN  NUMBER,
        p_id_credito   OUT NUMBER
    )
    ACCESSIBLE BY (PACKAGE PKG_CP_CUENTA);

END PKG_CP_CREDITO;
/

-- ============================================================
-- 4. PAQUETE PKG_CP_CREDITO (CUERPO)
-- ============================================================
-- Toma el credito mas reciente ya autorizado del cliente (o
-- proveedor) en el negocio, lo bloquea con FOR UPDATE WAIT para que
-- dos facturas simultaneas no gasten el mismo cupo, y rechaza si no
-- esta ACTIVO, si ya vencio o si el saldo pendiente de sus cuentas
-- no anuladas mas la factura nueva pasa del limite. Igualar el
-- limite se permite.

CREATE OR REPLACE PACKAGE BODY PKG_CP_CREDITO AS

    c_modulo CONSTANT VARCHAR2(20) := 'CREDITO';

    c_estado_activo  CONSTANT VARCHAR2(30) := 'ACTIVO';
    c_estado_anulada CONSTANT VARCHAR2(30) := 'ANULADA';

    c_err_sin_credito CONSTANT PLS_INTEGER := -20260;
    c_err_no_activo   CONSTANT PLS_INTEGER := -20261;
    c_err_vencido     CONSTANT PLS_INTEGER := -20262;
    c_err_supera      CONSTANT PLS_INTEGER := -20263;
    c_err_ocupado     CONSTANT PLS_INTEGER := -20264;


    -- Da formato de moneda (dos decimales) a un monto para los mensajes de error.
    FUNCTION monto_texto(
        p_monto IN NUMBER
    ) RETURN VARCHAR2
    IS
    BEGIN
        RETURN TO_CHAR(p_monto, 'FM999999999990.00');
    END monto_texto;


    -- Reglas comunes del credito: debe estar ACTIVO, no vencido y la factura no puede
    -- superar el cupo disponible (limite menos lo ya utilizado).
    PROCEDURE verificar(
        p_sujeto      IN VARCHAR2,
        p_estado      IN VARCHAR2,
        p_vencimiento IN DATE,
        p_limite      IN NUMBER,
        p_utilizado   IN NUMBER,
        p_monto       IN NUMBER
    )
    IS
    BEGIN

        IF p_estado <> c_estado_activo THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_no_activo,
                'El credito del ' || p_sujeto || ' esta ' || p_estado || '.'
            );
        END IF;

        IF p_vencimiento IS NOT NULL AND p_vencimiento < TRUNC(SYSDATE) THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_vencido,
                'El credito del ' || p_sujeto || ' vencio el '
                    || TO_CHAR(p_vencimiento, 'YYYY-MM-DD') || '.'
            );
        END IF;

        IF p_utilizado + p_monto > p_limite THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_supera,
                'La factura por ' || monto_texto(p_monto)
                    || ' supera el credito disponible del ' || p_sujeto
                    || ' (limite ' || monto_texto(p_limite)
                    || ', utilizado ' || monto_texto(p_utilizado) || ').'
            );
        END IF;

    END verificar;


    -- Valida el credito del cliente antes de crear su cuenta por cobrar. Toma la linea
    -- vigente y la bloquea con FOR UPDATE WAIT 5, para que dos facturas simultaneas no
    -- gasten el mismo cupo. Lo utilizado es la suma de saldos de sus cuentas no anuladas.
    -- Devuelve el id del credito aplicado.
    PROCEDURE validar_cliente(
        p_id_cliente IN  NUMBER,
        p_id_negocio IN  NUMBER,
        p_monto      IN  NUMBER,
        p_id_credito OUT NUMBER
    )
    ACCESSIBLE BY (PACKAGE PKG_CP_CUENTA)
    IS
        e_ocupado EXCEPTION;
        PRAGMA EXCEPTION_INIT(e_ocupado, -30006);

        v_limite      CP_CREDITO_CLIENTE.limite_credito%TYPE;
        v_vencimiento CP_CREDITO_CLIENTE.fecha_vencimiento%TYPE;
        v_estado      CP_ESTADO_CREDITO.nombre_estado_credito%TYPE;
        v_utilizado   NUMBER;
    BEGIN

        BEGIN
            SELECT id_credito_cliente
            INTO p_id_credito
            FROM CP_CREDITO_CLIENTE
            WHERE id_cliente = p_id_cliente
              AND id_negocio = p_id_negocio
              AND fecha_autorizacion <= SYSDATE
            ORDER BY fecha_autorizacion DESC, id_credito_cliente DESC
            FETCH FIRST 1 ROW ONLY;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                PKG_CP_ERROR.lanzar(
                    c_modulo,
                    c_err_sin_credito,
                    'El cliente ' || p_id_cliente
                        || ' no tiene credito autorizado en este negocio.'
                );
        END;

        BEGIN
            SELECT cc.limite_credito, cc.fecha_vencimiento,
                   ec.nombre_estado_credito
            INTO v_limite, v_vencimiento, v_estado
            FROM CP_CREDITO_CLIENTE cc
            JOIN CP_ESTADO_CREDITO ec
              ON ec.id_estado_credito = cc.id_estado_credito
            WHERE cc.id_credito_cliente = p_id_credito
            FOR UPDATE OF cc.limite_credito WAIT 5;
        EXCEPTION
            WHEN e_ocupado THEN
                PKG_CP_ERROR.lanzar(
                    c_modulo,
                    c_err_ocupado,
                    'El credito del cliente ' || p_id_cliente
                        || ' esta siendo usado por otra sesion.'
                );
        END;

        SELECT NVL(SUM(cc.saldo_pendiente), 0)
        INTO v_utilizado
        FROM CP_CUENTA_COBRAR cc
        JOIN CP_ESTADO_CUENTA_COBRAR ec
          ON ec.id_estado_cuenta_cobrar = cc.id_estado_cuenta_cobrar
        WHERE cc.id_credito_cliente = p_id_credito
          AND ec.nombre_estado_cuenta_cobrar <> c_estado_anulada;

        verificar('cliente', v_estado, v_vencimiento, v_limite,
                  v_utilizado, p_monto);

    EXCEPTION
        WHEN OTHERS THEN
            PKG_CP_ERROR.registrar_inesperado(c_modulo, 'credito de cliente ' || p_id_cliente);
            RAISE;
    END validar_cliente;


    -- Igual que validar_cliente, sobre el credito del proveedor y sus cuentas por pagar.
    PROCEDURE validar_proveedor(
        p_id_proveedor IN  NUMBER,
        p_id_negocio   IN  NUMBER,
        p_monto        IN  NUMBER,
        p_id_credito   OUT NUMBER
    )
    ACCESSIBLE BY (PACKAGE PKG_CP_CUENTA)
    IS
        e_ocupado EXCEPTION;
        PRAGMA EXCEPTION_INIT(e_ocupado, -30006);

        v_limite      CP_CREDITO_PROVEEDOR.limite_credito%TYPE;
        v_vencimiento CP_CREDITO_PROVEEDOR.fecha_vencimiento%TYPE;
        v_estado      CP_ESTADO_CREDITO.nombre_estado_credito%TYPE;
        v_utilizado   NUMBER;
    BEGIN

        BEGIN
            SELECT id_credito_proveedor
            INTO p_id_credito
            FROM CP_CREDITO_PROVEEDOR
            WHERE id_proveedor = p_id_proveedor
              AND id_negocio = p_id_negocio
              AND fecha_autorizacion <= SYSDATE
            ORDER BY fecha_autorizacion DESC, id_credito_proveedor DESC
            FETCH FIRST 1 ROW ONLY;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                PKG_CP_ERROR.lanzar(
                    c_modulo,
                    c_err_sin_credito,
                    'El proveedor ' || p_id_proveedor
                        || ' no tiene credito autorizado en este negocio.'
                );
        END;

        BEGIN
            SELECT cr.limite_credito, cr.fecha_vencimiento,
                   ec.nombre_estado_credito
            INTO v_limite, v_vencimiento, v_estado
            FROM CP_CREDITO_PROVEEDOR cr
            JOIN CP_ESTADO_CREDITO ec
              ON ec.id_estado_credito = cr.id_estado_credito
            WHERE cr.id_credito_proveedor = p_id_credito
            FOR UPDATE OF cr.limite_credito WAIT 5;
        EXCEPTION
            WHEN e_ocupado THEN
                PKG_CP_ERROR.lanzar(
                    c_modulo,
                    c_err_ocupado,
                    'El credito del proveedor ' || p_id_proveedor
                        || ' esta siendo usado por otra sesion.'
                );
        END;

        SELECT NVL(SUM(cp.saldo_pendiente), 0)
        INTO v_utilizado
        FROM CP_CUENTA_PAGAR cp
        JOIN CP_ESTADO_CUENTA_PAGAR ep
          ON ep.id_estado_cuenta_pagar = cp.id_estado_cuenta_pagar
        WHERE cp.id_credito_proveedor = p_id_credito
          AND ep.nombre_estado_cuenta_pagar <> c_estado_anulada;

        verificar('proveedor', v_estado, v_vencimiento, v_limite,
                  v_utilizado, p_monto);

    EXCEPTION
        WHEN OTHERS THEN
            PKG_CP_ERROR.registrar_inesperado(c_modulo, 'credito de proveedor ' || p_id_proveedor);
            RAISE;
    END validar_proveedor;

END PKG_CP_CREDITO;
/

-- ============================================================
-- 5. PAQUETE PKG_CP_CUENTA (ESPECIFICACION)
-- ============================================================
-- Crea y anula las cuentas segun el estado de la factura y aplica
-- los abonos al saldo y al estado de la cuenta. Solo pueden llamarlo
-- los triggers de las facturas y de los abonos.
-- Errores propios: -20250 a -20256 y -20265.

CREATE OR REPLACE PACKAGE PKG_CP_CUENTA AUTHID DEFINER AS

    PROCEDURE aplicar_abono_cobrar(
        p_id_cuenta IN NUMBER,
        p_monto     IN NUMBER
    )
    ACCESSIBLE BY (TRIGGER TRG_CP_ABONO_COBRAR_SALDO);

    PROCEDURE aplicar_abono_pagar(
        p_id_cuenta IN NUMBER,
        p_monto     IN NUMBER
    )
    ACCESSIBLE BY (TRIGGER TRG_CP_ABONO_PAGAR_SALDO);

    PROCEDURE rechazar_cambio_abono
    ACCESSIBLE BY (TRIGGER TRG_CP_ABONO_COBRAR_SALDO,
                   TRIGGER TRG_CP_ABONO_PAGAR_SALDO);

    PROCEDURE sincronizar_factura_venta(
        p_id_factura      IN NUMBER,
        p_id_cliente      IN NUMBER,
        p_id_sucursal     IN NUMBER,
        p_total           IN NUMBER,
        p_estado_anterior IN NUMBER,
        p_estado_nuevo    IN NUMBER
    )
    ACCESSIBLE BY (TRIGGER TRG_CP_FACTURA_VENTA_CUENTA);

    PROCEDURE sincronizar_factura_compra(
        p_id_factura      IN NUMBER,
        p_id_proveedor    IN NUMBER,
        p_id_negocio      IN NUMBER,
        p_total           IN NUMBER,
        p_estado_anterior IN NUMBER,
        p_estado_nuevo    IN NUMBER
    )
    ACCESSIBLE BY (TRIGGER TRG_CP_FACTURA_COMPRA_CUENTA);

END PKG_CP_CUENTA;
/

-- ============================================================
-- 6. PAQUETE PKG_CP_CUENTA (CUERPO)
-- ============================================================
-- Al pasar una factura a PENDIENTE valida el credito y crea su
-- cuenta con el monto de la factura y el vencimiento que marca el
-- parametro de plazo; al pasar a ANULADA anula la cuenta, salvo que
-- ya tenga abonos. Cada abono bloquea la cuenta con FOR UPDATE WAIT,
-- baja el saldo y cambia el estado: PARCIAL si queda saldo, PAGADA si
-- llega a cero (VENCIDA se conserva mientras haya saldo); al llegar a
-- cero tambien pasa la factura de PENDIENTE a CANCELADA. Nada usa
-- SAVEPOINT ni COMMIT porque lo llaman triggers: si algo falla,
-- Oracle deshace solo la sentencia que disparo el trigger.

CREATE OR REPLACE PACKAGE BODY PKG_CP_CUENTA AS

    c_modulo CONSTANT VARCHAR2(20) := 'CUENTA';

    c_estado_pagada  CONSTANT VARCHAR2(30) := 'PAGADA';
    c_estado_parcial CONSTANT VARCHAR2(30) := 'PARCIAL';
    c_estado_vencida CONSTANT VARCHAR2(30) := 'VENCIDA';
    c_estado_anulada CONSTANT VARCHAR2(30) := 'ANULADA';
    c_estado_pendiente CONSTANT VARCHAR2(30) := 'PENDIENTE';

    c_factura_pendiente CONSTANT VARCHAR2(30) := 'PENDIENTE';
    c_factura_cancelada CONSTANT VARCHAR2(30) := 'CANCELADA';
    c_factura_anulada   CONSTANT VARCHAR2(30) := 'ANULADA';

    c_param_plazo_cliente   CONSTANT VARCHAR2(40) := 'PLAZO_CREDITO_CLIENTE_DIAS';
    c_param_plazo_proveedor CONSTANT VARCHAR2(40) := 'PLAZO_CREDITO_PROVEEDOR_DIAS';

    c_err_cuenta_inexistente CONSTANT PLS_INTEGER := -20250;
    c_err_cuenta_anulada     CONSTANT PLS_INTEGER := -20251;
    c_err_supera_saldo       CONSTANT PLS_INTEGER := -20252;
    c_err_monto_invalido     CONSTANT PLS_INTEGER := -20253;
    c_err_abono_inmutable    CONSTANT PLS_INTEGER := -20254;
    c_err_cuenta_ocupada     CONSTANT PLS_INTEGER := -20255;
    c_err_sin_estado         CONSTANT PLS_INTEGER := -20256;
    c_err_con_abonos         CONSTANT PLS_INTEGER := -20265;


    -- Busca el id de un estado de cuenta por cobrar por su nombre (-20256 si no existe).
    FUNCTION id_estado_cobrar(
        p_nombre IN VARCHAR2
    ) RETURN NUMBER
    IS
        v_id CP_ESTADO_CUENTA_COBRAR.id_estado_cuenta_cobrar%TYPE;
    BEGIN

        SELECT id_estado_cuenta_cobrar
        INTO v_id
        FROM CP_ESTADO_CUENTA_COBRAR
        WHERE nombre_estado_cuenta_cobrar = p_nombre;

        RETURN v_id;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_sin_estado,
                'No existe el estado de cuenta por cobrar ' || p_nombre || '.'
            );
    END id_estado_cobrar;


    -- Busca el id de un estado de cuenta por pagar por su nombre (-20256 si no existe).
    FUNCTION id_estado_pagar(
        p_nombre IN VARCHAR2
    ) RETURN NUMBER
    IS
        v_id CP_ESTADO_CUENTA_PAGAR.id_estado_cuenta_pagar%TYPE;
    BEGIN

        SELECT id_estado_cuenta_pagar
        INTO v_id
        FROM CP_ESTADO_CUENTA_PAGAR
        WHERE nombre_estado_cuenta_pagar = p_nombre;

        RETURN v_id;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_sin_estado,
                'No existe el estado de cuenta por pagar ' || p_nombre || '.'
            );
    END id_estado_pagar;


    -- Busca el id de un estado de factura de venta por su nombre (-20256 si no existe).
    FUNCTION id_factura_venta_estado(
        p_nombre IN VARCHAR2
    ) RETURN NUMBER
    IS
        v_id CP_ESTADO_FACTURA_VENTA.id_estado_factura_venta%TYPE;
    BEGIN

        SELECT id_estado_factura_venta
        INTO v_id
        FROM CP_ESTADO_FACTURA_VENTA
        WHERE nombre_estado_factura = p_nombre;

        RETURN v_id;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_sin_estado,
                'No existe el estado de factura de venta ' || p_nombre || '.'
            );
    END id_factura_venta_estado;


    -- Busca el id de un estado de factura de compra por su nombre (-20256 si no existe).
    FUNCTION id_factura_compra_estado(
        p_nombre IN VARCHAR2
    ) RETURN NUMBER
    IS
        v_id CP_ESTADO_FACTURA_COMPRA.id_estado_factura_compra%TYPE;
    BEGIN

        SELECT id_estado_factura_compra
        INTO v_id
        FROM CP_ESTADO_FACTURA_COMPRA
        WHERE nombre_estado_factura = p_nombre;

        RETURN v_id;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_sin_estado,
                'No existe el estado de factura de compra ' || p_nombre || '.'
            );
    END id_factura_compra_estado;


    -- Aplica un abono a la cuenta por cobrar. Bloquea la cuenta (FOR UPDATE WAIT 5),
    -- valida monto, estado y saldo, descuenta el saldo y fija el estado (PARCIAL o PAGADA).
    -- Al saldarla pasa la factura de PENDIENTE a CANCELADA. Solo lo llama el trigger del abono.
    PROCEDURE aplicar_abono_cobrar(
        p_id_cuenta IN NUMBER,
        p_monto     IN NUMBER
    )
    ACCESSIBLE BY (TRIGGER TRG_CP_ABONO_COBRAR_SALDO)
    IS
        e_ocupada EXCEPTION;
        PRAGMA EXCEPTION_INIT(e_ocupada, -30006);

        v_saldo        CP_CUENTA_COBRAR.saldo_pendiente%TYPE;
        v_estado       CP_ESTADO_CUENTA_COBRAR.nombre_estado_cuenta_cobrar%TYPE;
        v_nuevo_saldo  CP_CUENTA_COBRAR.saldo_pendiente%TYPE;
        v_nuevo_estado CP_ESTADO_CUENTA_COBRAR.nombre_estado_cuenta_cobrar%TYPE;
        v_id_estado    NUMBER;
        v_id_factura   CP_CUENTA_COBRAR.id_factura_venta%TYPE;
        v_id_pendiente NUMBER;
        v_id_cancelada NUMBER;
    BEGIN

        IF p_monto IS NULL OR p_monto <= 0 THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_monto_invalido,
                'El monto del abono debe ser mayor que cero.'
            );
        END IF;

        BEGIN
            SELECT cc.saldo_pendiente, ec.nombre_estado_cuenta_cobrar,
                   cc.id_factura_venta
            INTO v_saldo, v_estado, v_id_factura
            FROM CP_CUENTA_COBRAR cc
            JOIN CP_ESTADO_CUENTA_COBRAR ec
              ON ec.id_estado_cuenta_cobrar = cc.id_estado_cuenta_cobrar
            WHERE cc.id_cuenta_cobrar = p_id_cuenta
            FOR UPDATE OF cc.saldo_pendiente WAIT 5;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                PKG_CP_ERROR.lanzar(
                    c_modulo,
                    c_err_cuenta_inexistente,
                    'No existe la cuenta por cobrar ' || p_id_cuenta || '.'
                );
            WHEN e_ocupada THEN
                PKG_CP_ERROR.lanzar(
                    c_modulo,
                    c_err_cuenta_ocupada,
                    'La cuenta por cobrar ' || p_id_cuenta
                        || ' esta siendo modificada por otra sesion.'
                );
        END;

        IF v_estado = c_estado_anulada THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_cuenta_anulada,
                'La cuenta por cobrar ' || p_id_cuenta || ' esta anulada.'
            );
        END IF;

        IF p_monto > v_saldo THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_supera_saldo,
                'El abono de ' || p_monto || ' supera el saldo pendiente de '
                    || v_saldo || ' de la cuenta por cobrar ' || p_id_cuenta || '.'
            );
        END IF;

        v_nuevo_saldo := v_saldo - p_monto;

        IF v_nuevo_saldo = 0 THEN
            v_nuevo_estado := c_estado_pagada;
        ELSIF v_estado = c_estado_vencida THEN
            v_nuevo_estado := c_estado_vencida;
        ELSE
            v_nuevo_estado := c_estado_parcial;
        END IF;

        v_id_estado := id_estado_cobrar(v_nuevo_estado);

        UPDATE CP_CUENTA_COBRAR
        SET saldo_pendiente = v_nuevo_saldo,
            id_estado_cuenta_cobrar = v_id_estado
        WHERE id_cuenta_cobrar = p_id_cuenta;

        IF v_nuevo_saldo = 0 THEN
            v_id_pendiente := id_factura_venta_estado(c_factura_pendiente);
            v_id_cancelada := id_factura_venta_estado(c_factura_cancelada);

            UPDATE CP_FACTURA_VENTA
            SET id_estado_factura_venta = v_id_cancelada
            WHERE id_factura_venta = v_id_factura
              AND id_estado_factura_venta = v_id_pendiente;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            PKG_CP_ERROR.registrar_inesperado(c_modulo, 'cuenta por cobrar ' || p_id_cuenta);
            RAISE;
    END aplicar_abono_cobrar;


    -- Igual que aplicar_abono_cobrar, para cuentas por pagar y facturas de compra.
    PROCEDURE aplicar_abono_pagar(
        p_id_cuenta IN NUMBER,
        p_monto     IN NUMBER
    )
    ACCESSIBLE BY (TRIGGER TRG_CP_ABONO_PAGAR_SALDO)
    IS
        e_ocupada EXCEPTION;
        PRAGMA EXCEPTION_INIT(e_ocupada, -30006);

        v_saldo        CP_CUENTA_PAGAR.saldo_pendiente%TYPE;
        v_estado       CP_ESTADO_CUENTA_PAGAR.nombre_estado_cuenta_pagar%TYPE;
        v_nuevo_saldo  CP_CUENTA_PAGAR.saldo_pendiente%TYPE;
        v_nuevo_estado CP_ESTADO_CUENTA_PAGAR.nombre_estado_cuenta_pagar%TYPE;
        v_id_estado    NUMBER;
        v_id_factura   CP_CUENTA_PAGAR.id_factura_compra%TYPE;
        v_id_pendiente NUMBER;
        v_id_cancelada NUMBER;
    BEGIN

        IF p_monto IS NULL OR p_monto <= 0 THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_monto_invalido,
                'El monto del abono debe ser mayor que cero.'
            );
        END IF;

        BEGIN
            SELECT cp.saldo_pendiente, ep.nombre_estado_cuenta_pagar,
                   cp.id_factura_compra
            INTO v_saldo, v_estado, v_id_factura
            FROM CP_CUENTA_PAGAR cp
            JOIN CP_ESTADO_CUENTA_PAGAR ep
              ON ep.id_estado_cuenta_pagar = cp.id_estado_cuenta_pagar
            WHERE cp.id_cuenta_pagar = p_id_cuenta
            FOR UPDATE OF cp.saldo_pendiente WAIT 5;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                PKG_CP_ERROR.lanzar(
                    c_modulo,
                    c_err_cuenta_inexistente,
                    'No existe la cuenta por pagar ' || p_id_cuenta || '.'
                );
            WHEN e_ocupada THEN
                PKG_CP_ERROR.lanzar(
                    c_modulo,
                    c_err_cuenta_ocupada,
                    'La cuenta por pagar ' || p_id_cuenta
                        || ' esta siendo modificada por otra sesion.'
                );
        END;

        IF v_estado = c_estado_anulada THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_cuenta_anulada,
                'La cuenta por pagar ' || p_id_cuenta || ' esta anulada.'
            );
        END IF;

        IF p_monto > v_saldo THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_supera_saldo,
                'El abono de ' || p_monto || ' supera el saldo pendiente de '
                    || v_saldo || ' de la cuenta por pagar ' || p_id_cuenta || '.'
            );
        END IF;

        v_nuevo_saldo := v_saldo - p_monto;

        IF v_nuevo_saldo = 0 THEN
            v_nuevo_estado := c_estado_pagada;
        ELSIF v_estado = c_estado_vencida THEN
            v_nuevo_estado := c_estado_vencida;
        ELSE
            v_nuevo_estado := c_estado_parcial;
        END IF;

        v_id_estado := id_estado_pagar(v_nuevo_estado);

        UPDATE CP_CUENTA_PAGAR
        SET saldo_pendiente = v_nuevo_saldo,
            id_estado_cuenta_pagar = v_id_estado
        WHERE id_cuenta_pagar = p_id_cuenta;

        IF v_nuevo_saldo = 0 THEN
            v_id_pendiente := id_factura_compra_estado(c_factura_pendiente);
            v_id_cancelada := id_factura_compra_estado(c_factura_cancelada);

            UPDATE CP_FACTURA_COMPRA
            SET id_estado_factura_compra = v_id_cancelada
            WHERE id_factura_compra = v_id_factura
              AND id_estado_factura_compra = v_id_pendiente;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            PKG_CP_ERROR.registrar_inesperado(c_modulo, 'cuenta por pagar ' || p_id_cuenta);
            RAISE;
    END aplicar_abono_pagar;


    -- Crea la cuenta por cobrar de una factura que pasa a PENDIENTE: valida el credito del
    -- cliente y fija monto, saldo y vencimiento (plazo del parametro). Si la factura ya
    -- tiene una cuenta activa no crea otra.
    PROCEDURE crear_cuenta_cobrar(
        p_id_factura  IN NUMBER,
        p_id_cliente  IN NUMBER,
        p_id_sucursal IN NUMBER,
        p_total       IN NUMBER
    )
    IS
        v_id_anulada   NUMBER;
        v_id_pendiente NUMBER;
        v_id_negocio   NUMBER;
        v_id_credito   NUMBER;
        v_plazo        NUMBER;
        v_existentes   NUMBER;
        v_hoy          DATE := SYSDATE;
    BEGIN

        v_id_anulada := id_estado_cobrar(c_estado_anulada);

        SELECT COUNT(*)
        INTO v_existentes
        FROM CP_CUENTA_COBRAR
        WHERE id_factura_venta = p_id_factura
          AND id_estado_cuenta_cobrar <> v_id_anulada;

        IF v_existentes > 0 THEN
            RETURN;
        END IF;

        SELECT id_negocio
        INTO v_id_negocio
        FROM CP_SUCURSAL
        WHERE id_sucursal = p_id_sucursal;

        PKG_CP_CREDITO.validar_cliente(
            p_id_cliente, v_id_negocio, p_total, v_id_credito
        );

        v_plazo := PKG_CP_PARAMETRO.obtener_numero(c_param_plazo_cliente);
        v_id_pendiente := id_estado_cobrar(c_estado_pendiente);

        INSERT INTO CP_CUENTA_COBRAR
            (id_factura_venta, id_credito_cliente, id_estado_cuenta_cobrar,
             fecha_creacion, fecha_vencimiento, monto_total, saldo_pendiente)
        VALUES
            (p_id_factura, v_id_credito, v_id_pendiente,
             v_hoy, v_hoy + v_plazo, p_total, p_total);

    END crear_cuenta_cobrar;


    -- Igual que crear_cuenta_cobrar, con el credito del proveedor.
    PROCEDURE crear_cuenta_pagar(
        p_id_factura   IN NUMBER,
        p_id_proveedor IN NUMBER,
        p_id_negocio   IN NUMBER,
        p_total        IN NUMBER
    )
    IS
        v_id_anulada   NUMBER;
        v_id_pendiente NUMBER;
        v_id_credito   NUMBER;
        v_plazo        NUMBER;
        v_existentes   NUMBER;
        v_hoy          DATE := SYSDATE;
    BEGIN

        v_id_anulada := id_estado_pagar(c_estado_anulada);

        SELECT COUNT(*)
        INTO v_existentes
        FROM CP_CUENTA_PAGAR
        WHERE id_factura_compra = p_id_factura
          AND id_estado_cuenta_pagar <> v_id_anulada;

        IF v_existentes > 0 THEN
            RETURN;
        END IF;

        PKG_CP_CREDITO.validar_proveedor(
            p_id_proveedor, p_id_negocio, p_total, v_id_credito
        );

        v_plazo := PKG_CP_PARAMETRO.obtener_numero(c_param_plazo_proveedor);
        v_id_pendiente := id_estado_pagar(c_estado_pendiente);

        INSERT INTO CP_CUENTA_PAGAR
            (id_factura_compra, id_credito_proveedor, id_estado_cuenta_pagar,
             fecha_creacion, fecha_vencimiento, monto_total, saldo_pendiente)
        VALUES
            (p_id_factura, v_id_credito, v_id_pendiente,
             v_hoy, v_hoy + v_plazo, p_total, p_total);

    END crear_cuenta_pagar;


    -- Anula la cuenta de una factura anulada y con ello libera su cupo de credito.
    -- Se niega con -20265 si la cuenta ya tiene abonos.
    PROCEDURE anular_cuenta_cobrar(
        p_id_factura IN NUMBER
    )
    IS
        v_id_anulada NUMBER;
        v_con_abonos NUMBER;
    BEGIN

        v_id_anulada := id_estado_cobrar(c_estado_anulada);

        SELECT COUNT(*)
        INTO v_con_abonos
        FROM CP_CUENTA_COBRAR
        WHERE id_factura_venta = p_id_factura
          AND id_estado_cuenta_cobrar <> v_id_anulada
          AND saldo_pendiente < monto_total;

        IF v_con_abonos > 0 THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_con_abonos,
                'No se puede anular la factura: su cuenta por cobrar ya tiene abonos.'
            );
        END IF;

        UPDATE CP_CUENTA_COBRAR
        SET id_estado_cuenta_cobrar = v_id_anulada
        WHERE id_factura_venta = p_id_factura
          AND id_estado_cuenta_cobrar <> v_id_anulada;

    END anular_cuenta_cobrar;


    -- Igual que anular_cuenta_cobrar, para cuentas por pagar.
    PROCEDURE anular_cuenta_pagar(
        p_id_factura IN NUMBER
    )
    IS
        v_id_anulada NUMBER;
        v_con_abonos NUMBER;
    BEGIN

        v_id_anulada := id_estado_pagar(c_estado_anulada);

        SELECT COUNT(*)
        INTO v_con_abonos
        FROM CP_CUENTA_PAGAR
        WHERE id_factura_compra = p_id_factura
          AND id_estado_cuenta_pagar <> v_id_anulada
          AND saldo_pendiente < monto_total;

        IF v_con_abonos > 0 THEN
            PKG_CP_ERROR.lanzar(
                c_modulo,
                c_err_con_abonos,
                'No se puede anular la factura: su cuenta por pagar ya tiene abonos.'
            );
        END IF;

        UPDATE CP_CUENTA_PAGAR
        SET id_estado_cuenta_pagar = v_id_anulada
        WHERE id_factura_compra = p_id_factura
          AND id_estado_cuenta_pagar <> v_id_anulada;

    END anular_cuenta_pagar;


    -- Segun el cambio de estado de la factura: PENDIENTE crea su cuenta por cobrar y
    -- ANULADA la anula. Lo invoca el trigger de la factura.
    PROCEDURE sincronizar_factura_venta(
        p_id_factura      IN NUMBER,
        p_id_cliente      IN NUMBER,
        p_id_sucursal     IN NUMBER,
        p_total           IN NUMBER,
        p_estado_anterior IN NUMBER,
        p_estado_nuevo    IN NUMBER
    )
    ACCESSIBLE BY (TRIGGER TRG_CP_FACTURA_VENTA_CUENTA)
    IS
        v_id_pendiente NUMBER;
        v_id_anulada   NUMBER;
    BEGIN

        IF p_estado_nuevo = NVL(p_estado_anterior, -1) THEN
            RETURN;
        END IF;

        v_id_pendiente := id_factura_venta_estado(c_factura_pendiente);
        v_id_anulada   := id_factura_venta_estado(c_factura_anulada);

        IF p_estado_nuevo = v_id_pendiente THEN
            crear_cuenta_cobrar(p_id_factura, p_id_cliente, p_id_sucursal, p_total);
        ELSIF p_estado_nuevo = v_id_anulada THEN
            anular_cuenta_cobrar(p_id_factura);
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            PKG_CP_ERROR.registrar_inesperado(c_modulo, 'factura de venta ' || p_id_factura);
            RAISE;
    END sincronizar_factura_venta;


    -- Segun el cambio de estado de la factura: PENDIENTE crea su cuenta por pagar y
    -- ANULADA la anula. Lo invoca el trigger de la factura.
    PROCEDURE sincronizar_factura_compra(
        p_id_factura      IN NUMBER,
        p_id_proveedor    IN NUMBER,
        p_id_negocio      IN NUMBER,
        p_total           IN NUMBER,
        p_estado_anterior IN NUMBER,
        p_estado_nuevo    IN NUMBER
    )
    ACCESSIBLE BY (TRIGGER TRG_CP_FACTURA_COMPRA_CUENTA)
    IS
        v_id_pendiente NUMBER;
        v_id_anulada   NUMBER;
    BEGIN

        IF p_estado_nuevo = NVL(p_estado_anterior, -1) THEN
            RETURN;
        END IF;

        v_id_pendiente := id_factura_compra_estado(c_factura_pendiente);
        v_id_anulada   := id_factura_compra_estado(c_factura_anulada);

        IF p_estado_nuevo = v_id_pendiente THEN
            crear_cuenta_pagar(p_id_factura, p_id_proveedor, p_id_negocio, p_total);
        ELSIF p_estado_nuevo = v_id_anulada THEN
            anular_cuenta_pagar(p_id_factura);
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            PKG_CP_ERROR.registrar_inesperado(c_modulo, 'factura de compra ' || p_id_factura);
            RAISE;
    END sincronizar_factura_compra;


    -- Los abonos son un historial contable: no se modifican ni se eliminan (-20254).
    PROCEDURE rechazar_cambio_abono
    ACCESSIBLE BY (TRIGGER TRG_CP_ABONO_COBRAR_SALDO,
                   TRIGGER TRG_CP_ABONO_PAGAR_SALDO)
    IS
    BEGIN

        PKG_CP_ERROR.lanzar(
            c_modulo,
            c_err_abono_inmutable,
            'Los abonos no se modifican ni se eliminan.'
        );

    END rechazar_cambio_abono;

END PKG_CP_CUENTA;
/

-- ============================================================
-- 7. TRIGGERS DE LOS ABONOS
-- ============================================================
-- Cada abono nuevo baja el saldo de su cuenta. Modificar o borrar
-- un abono se rechaza para que el saldo siempre coincida con ellos.

CREATE OR REPLACE TRIGGER TRG_CP_ABONO_COBRAR_SALDO
AFTER INSERT OR UPDATE OR DELETE ON CP_ABONO_CUENTA_COBRAR
FOR EACH ROW
BEGIN

    IF INSERTING THEN
        PKG_CP_CUENTA.aplicar_abono_cobrar(:NEW.id_cuenta_cobrar, :NEW.monto_abono);
    ELSE
        PKG_CP_CUENTA.rechazar_cambio_abono;
    END IF;

END TRG_CP_ABONO_COBRAR_SALDO;
/

CREATE OR REPLACE TRIGGER TRG_CP_ABONO_PAGAR_SALDO
AFTER INSERT OR UPDATE OR DELETE ON CP_ABONO_CUENTA_PAGAR
FOR EACH ROW
BEGIN

    IF INSERTING THEN
        PKG_CP_CUENTA.aplicar_abono_pagar(:NEW.id_cuenta_pagar, :NEW.monto_abono);
    ELSE
        PKG_CP_CUENTA.rechazar_cambio_abono;
    END IF;

END TRG_CP_ABONO_PAGAR_SALDO;
/

-- ============================================================
-- 8. TRIGGERS DE LAS FACTURAS
-- ============================================================
-- Cada factura nueva, o cuyo estado cambia, se revisa para crear o
-- anular su cuenta. Son AFTER para que la factura ya exista cuando se
-- inserta la cuenta que la referencia.

CREATE OR REPLACE TRIGGER TRG_CP_FACTURA_VENTA_CUENTA
AFTER INSERT OR UPDATE OF id_estado_factura_venta ON CP_FACTURA_VENTA
FOR EACH ROW
BEGIN

    PKG_CP_CUENTA.sincronizar_factura_venta(
        :NEW.id_factura_venta,
        :NEW.id_cliente,
        :NEW.id_sucursal,
        :NEW.total,
        :OLD.id_estado_factura_venta,
        :NEW.id_estado_factura_venta
    );

END TRG_CP_FACTURA_VENTA_CUENTA;
/

CREATE OR REPLACE TRIGGER TRG_CP_FACTURA_COMPRA_CUENTA
AFTER INSERT OR UPDATE OF id_estado_factura_compra ON CP_FACTURA_COMPRA
FOR EACH ROW
BEGIN

    PKG_CP_CUENTA.sincronizar_factura_compra(
        :NEW.id_factura_compra,
        :NEW.id_proveedor,
        :NEW.id_negocio,
        :NEW.total,
        :OLD.id_estado_factura_compra,
        :NEW.id_estado_factura_compra
    );

END TRG_CP_FACTURA_COMPRA_CUENTA;
/

-- ============================================================
-- 9. VERIFICACION
-- ============================================================
-- Deben salir 4 triggers ENABLED y los dos paquetes con
-- especificacion y cuerpo VALID.

SELECT trigger_name, table_name, status
FROM user_triggers
WHERE trigger_name LIKE 'TRG_CP_ABONO%_SALDO'
   OR trigger_name LIKE 'TRG_CP_FACTURA%_CUENTA'
ORDER BY trigger_name;

SELECT object_name, object_type, status
FROM user_objects
WHERE object_name IN ('PKG_CP_CREDITO', 'PKG_CP_CUENTA')
ORDER BY object_name, object_type;

-- ============================================================
-- 10. PRUEBAS DE CUENTAS POR COBRAR
-- ============================================================
-- Las 25 pruebas deben salir OK (la 8 se omite con OK si no hay un
-- cliente sin credito). Se crea un credito nuevo de 500000 para un
-- cliente existente y todo se deshace al final; solo se borran de la
-- bitacora los errores que la prueba provoca a proposito.

DECLARE
    v_antes        NUMBER;
    v_esperados    NUMBER := 0;
    v_errores      NUMBER;
    v_id_cliente   NUMBER;
    v_id_negocio   NUMBER;
    v_id_sucursal  NUMBER;
    v_id_sin_cred  NUMBER;
    v_id_usuario   NUMBER;
    v_id_tipo_pago NUMBER;
    v_id_credito   NUMBER;
    v_activo       NUMBER;
    v_suspendido   NUMBER;
    v_fv_pendiente NUMBER;
    v_fv_anulada   NUMBER;
    v_ultima       NUMBER;
    v_f1           NUMBER;
    v_f3           NUMBER;
    v_f4           NUMBER;
    v_c1           NUMBER;
    v_c3           NUMBER;
    v_c4           NUMBER;
    v_id_abono     NUMBER;
    v_codigo       NUMBER;

    PROCEDURE reportar(
        p_prueba IN VARCHAR2,
        p_ok     IN BOOLEAN
    )
    IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(
            RPAD(p_prueba, 62, '.') || CASE WHEN p_ok THEN ' OK' ELSE ' FALLA' END
        );
    END reportar;

    FUNCTION provoca(
        p_obtenido IN NUMBER,
        p_esperado IN NUMBER
    ) RETURN BOOLEAN
    IS
    BEGIN
        v_esperados := v_esperados + 1;
        RETURN p_obtenido = p_esperado;
    END provoca;

    FUNCTION nueva_factura(
        p_numero     IN VARCHAR2,
        p_id_cliente IN NUMBER,
        p_total      IN NUMBER
    ) RETURN NUMBER
    IS
    BEGIN
        INSERT INTO CP_FACTURA_VENTA
            (id_cliente, id_sucursal, id_usuario, id_estado_factura_venta,
             numero_factura, fecha_emision, subtotal, descuento_total,
             impuesto_total, total)
        VALUES
            (p_id_cliente, v_id_sucursal, v_id_usuario, v_fv_pendiente,
             p_numero, SYSDATE, p_total, 0, 0, p_total)
        RETURNING id_factura_venta INTO v_ultima;
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            v_ultima := NULL;
            RETURN SQLCODE;
    END nueva_factura;

    FUNCTION cuenta_de(
        p_id_factura IN NUMBER
    ) RETURN NUMBER
    IS
        v_id NUMBER;
    BEGIN
        SELECT MIN(id_cuenta_cobrar)
        INTO v_id
        FROM CP_CUENTA_COBRAR
        WHERE id_factura_venta = p_id_factura;
        RETURN v_id;
    END cuenta_de;

    FUNCTION cuentas_de(
        p_id_factura IN NUMBER
    ) RETURN NUMBER
    IS
        v_total NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_total
        FROM CP_CUENTA_COBRAR
        WHERE id_factura_venta = p_id_factura;
        RETURN v_total;
    END cuentas_de;

    FUNCTION facturas_con_numero(
        p_numero IN VARCHAR2
    ) RETURN NUMBER
    IS
        v_total NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_total
        FROM CP_FACTURA_VENTA
        WHERE numero_factura = p_numero;
        RETURN v_total;
    END facturas_con_numero;

    FUNCTION plazo_de(
        p_id IN NUMBER
    ) RETURN NUMBER
    IS
        v_dias NUMBER;
    BEGIN
        SELECT ROUND(fecha_vencimiento - fecha_creacion)
        INTO v_dias
        FROM CP_CUENTA_COBRAR
        WHERE id_cuenta_cobrar = p_id;
        RETURN v_dias;
    END plazo_de;

    FUNCTION credito_de(
        p_id IN NUMBER
    ) RETURN NUMBER
    IS
        v_credito NUMBER;
    BEGIN
        SELECT id_credito_cliente
        INTO v_credito
        FROM CP_CUENTA_COBRAR
        WHERE id_cuenta_cobrar = p_id;
        RETURN v_credito;
    END credito_de;

    FUNCTION saldo_de(
        p_id IN NUMBER
    ) RETURN NUMBER
    IS
        v_saldo NUMBER;
    BEGIN
        SELECT saldo_pendiente
        INTO v_saldo
        FROM CP_CUENTA_COBRAR
        WHERE id_cuenta_cobrar = p_id;
        RETURN v_saldo;
    END saldo_de;

    FUNCTION estado_de(
        p_id IN NUMBER
    ) RETURN VARCHAR2
    IS
        v_estado VARCHAR2(30);
    BEGIN
        SELECT ec.nombre_estado_cuenta_cobrar
        INTO v_estado
        FROM CP_CUENTA_COBRAR cc
        JOIN CP_ESTADO_CUENTA_COBRAR ec
          ON ec.id_estado_cuenta_cobrar = cc.id_estado_cuenta_cobrar
        WHERE cc.id_cuenta_cobrar = p_id;
        RETURN v_estado;
    END estado_de;

    FUNCTION estado_factura(
        p_id_factura IN NUMBER
    ) RETURN VARCHAR2
    IS
        v_estado VARCHAR2(30);
    BEGIN
        SELECT ef.nombre_estado_factura
        INTO v_estado
        FROM CP_FACTURA_VENTA fv
        JOIN CP_ESTADO_FACTURA_VENTA ef
          ON ef.id_estado_factura_venta = fv.id_estado_factura_venta
        WHERE fv.id_factura_venta = p_id_factura;
        RETURN v_estado;
    END estado_factura;

    FUNCTION abonar(
        p_id    IN NUMBER,
        p_monto IN NUMBER
    ) RETURN NUMBER
    IS
    BEGIN
        INSERT INTO CP_ABONO_CUENTA_COBRAR
            (id_cuenta_cobrar, id_tipo_pago, id_usuario, monto_abono, fecha_abono)
        VALUES
            (p_id, v_id_tipo_pago, v_id_usuario, p_monto, SYSTIMESTAMP);
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN SQLCODE;
    END abonar;

BEGIN

    SELECT NVL(MAX(id_bitacora_error), 0) INTO v_antes FROM CP_BITACORA_ERROR;

    SELECT id_cliente, id_negocio
    INTO v_id_cliente, v_id_negocio
    FROM CP_CREDITO_CLIENTE
    ORDER BY id_credito_cliente
    FETCH FIRST 1 ROW ONLY;

    SELECT MIN(id_sucursal) INTO v_id_sucursal
    FROM CP_SUCURSAL
    WHERE id_negocio = v_id_negocio;

    SELECT MIN(c.id_cliente) INTO v_id_sin_cred
    FROM CP_CLIENTE c
    WHERE NOT EXISTS (
        SELECT 1
        FROM CP_CREDITO_CLIENTE cr
        WHERE cr.id_cliente = c.id_cliente
          AND cr.id_negocio = v_id_negocio
    );

    SELECT MIN(id_usuario) INTO v_id_usuario FROM CP_USUARIO;
    SELECT MIN(id_tipo_pago) INTO v_id_tipo_pago FROM CP_TIPO_PAGO;

    SELECT id_estado_credito INTO v_activo
    FROM CP_ESTADO_CREDITO
    WHERE nombre_estado_credito = 'ACTIVO';

    SELECT id_estado_credito INTO v_suspendido
    FROM CP_ESTADO_CREDITO
    WHERE nombre_estado_credito = 'SUSPENDIDO';

    SELECT id_estado_factura_venta INTO v_fv_pendiente
    FROM CP_ESTADO_FACTURA_VENTA
    WHERE nombre_estado_factura = 'PENDIENTE';

    SELECT id_estado_factura_venta INTO v_fv_anulada
    FROM CP_ESTADO_FACTURA_VENTA
    WHERE nombre_estado_factura = 'ANULADA';

    INSERT INTO CP_CREDITO_CLIENTE
        (id_cliente, id_negocio, id_estado_credito, limite_credito,
         fecha_autorizacion, fecha_vencimiento)
    VALUES
        (v_id_cliente, v_id_negocio, v_activo, 500000,
         SYSDATE - 10, SYSDATE + 365)
    RETURNING id_credito_cliente INTO v_id_credito;

    -- Creacion de la cuenta al pasar la factura a PENDIENTE
    v_codigo := nueva_factura('TEST-FV-1', v_id_cliente, 400000);
    v_f1 := v_ultima;
    v_c1 := cuenta_de(v_f1);

    reportar('1. Factura PENDIENTE de 400000 crea su cuenta por cobrar',
             v_codigo = 0 AND cuentas_de(v_f1) = 1
             AND saldo_de(v_c1) = 400000
             AND estado_de(v_c1) = 'PENDIENTE');

    reportar('2. La cuenta vence 30 dias despues de crearse',
             v_c1 IS NOT NULL AND plazo_de(v_c1) = 30);

    reportar('3. La cuenta queda ligada al credito nuevo',
             v_c1 IS NOT NULL AND credito_de(v_c1) = v_id_credito);

    -- Limite de credito
    reportar('4. Factura de 150000 con cupo de 100000 da -20263',
             provoca(nueva_factura('TEST-FV-2', v_id_cliente, 150000), -20263));

    reportar('5. La factura rechazada no queda guardada',
             facturas_con_numero('TEST-FV-2') = 0);

    v_codigo := nueva_factura('TEST-FV-3', v_id_cliente, 100000);
    v_f3 := v_ultima;
    v_c3 := cuenta_de(v_f3);

    reportar('6. Factura de 100000 (justo el cupo) se acepta',
             v_codigo = 0 AND v_c3 IS NOT NULL);

    reportar('7. Con el cupo agotado, una factura de 1 da -20263',
             provoca(nueva_factura('TEST-FV-4', v_id_cliente, 1), -20263));

    IF v_id_sin_cred IS NULL THEN
        reportar('8. Cliente sin credito da -20260 (no hay cliente para probar)', TRUE);
    ELSE
        reportar('8. Cliente sin credito da -20260',
                 provoca(nueva_factura('TEST-FV-5', v_id_sin_cred, 1), -20260));
    END IF;

    UPDATE CP_CREDITO_CLIENTE
    SET id_estado_credito = v_suspendido
    WHERE id_credito_cliente = v_id_credito;

    reportar('9. Credito SUSPENDIDO da -20261',
             provoca(nueva_factura('TEST-FV-6', v_id_cliente, 1), -20261));

    UPDATE CP_CREDITO_CLIENTE
    SET id_estado_credito = v_activo,
        fecha_vencimiento = SYSDATE - 1
    WHERE id_credito_cliente = v_id_credito;

    reportar('10. Credito vencido da -20262',
             provoca(nueva_factura('TEST-FV-7', v_id_cliente, 1), -20262));

    UPDATE CP_CREDITO_CLIENTE
    SET fecha_vencimiento = SYSDATE + 365
    WHERE id_credito_cliente = v_id_credito;

    -- Anulacion de la factura
    UPDATE CP_FACTURA_VENTA
    SET id_estado_factura_venta = v_fv_anulada
    WHERE id_factura_venta = v_f1;

    reportar('11. Anular la factura anula su cuenta por cobrar',
             estado_de(v_c1) = 'ANULADA');

    v_codigo := nueva_factura('TEST-FV-8', v_id_cliente, 150000);
    v_f4 := v_ultima;
    v_c4 := cuenta_de(v_f4);

    reportar('12. La cuenta anulada libera cupo: 150000 ahora se acepta',
             v_codigo = 0 AND v_c4 IS NOT NULL);

    -- Abonos
    reportar('13. Abono de 30000 sobre 100000 deja saldo 70000',
             abonar(v_c3, 30000) = 0 AND saldo_de(v_c3) = 70000);
    reportar('14. La cuenta queda PARCIAL',
             estado_de(v_c3) = 'PARCIAL');
    reportar('15. La factura sigue PENDIENTE con saldo por cobrar',
             estado_factura(v_f3) = 'PENDIENTE');

    SELECT MIN(id_abono_cuenta_cobrar) INTO v_id_abono
    FROM CP_ABONO_CUENTA_COBRAR
    WHERE id_cuenta_cobrar = v_c3;

    reportar('16. Abono de 70000 deja saldo 0 y la cuenta PAGADA',
             abonar(v_c3, 70000) = 0 AND saldo_de(v_c3) = 0
             AND estado_de(v_c3) = 'PAGADA');
    reportar('17. Al saldar la cuenta, la factura pasa a CANCELADA',
             estado_factura(v_f3) = 'CANCELADA');
    reportar('18. Pasar a CANCELADA no crea otra cuenta',
             cuentas_de(v_f3) = 1);
    reportar('19. Abonar a una cuenta saldada da -20252',
             provoca(abonar(v_c3, 1), -20252));

    BEGIN
        UPDATE CP_ABONO_CUENTA_COBRAR
        SET monto_abono = 1
        WHERE id_abono_cuenta_cobrar = v_id_abono;
        reportar('20. Modificar un abono da -20254', FALSE);
    EXCEPTION
        WHEN OTHERS THEN
            reportar('20. Modificar un abono da -20254', provoca(SQLCODE, -20254));
    END;

    BEGIN
        DELETE FROM CP_ABONO_CUENTA_COBRAR
        WHERE id_abono_cuenta_cobrar = v_id_abono;
        reportar('21. Eliminar un abono da -20254', FALSE);
    EXCEPTION
        WHEN OTHERS THEN
            reportar('21. Eliminar un abono da -20254', provoca(SQLCODE, -20254));
    END;

    reportar('22. Abono de 200000 sobre saldo 150000 da -20252 y no cambia el saldo',
             provoca(abonar(v_c4, 200000), -20252) AND saldo_de(v_c4) = 150000);
    reportar('23. Abonar a una cuenta ANULADA da -20251',
             provoca(abonar(v_c1, 10), -20251));

    v_codigo := abonar(v_c4, 1000);

    BEGIN
        UPDATE CP_FACTURA_VENTA
        SET id_estado_factura_venta = v_fv_anulada
        WHERE id_factura_venta = v_f4;
        reportar('24. Anular una factura con abonos da -20265', FALSE);
    EXCEPTION
        WHEN OTHERS THEN
            reportar('24. Anular una factura con abonos da -20265', provoca(SQLCODE, -20265));
    END;

    ROLLBACK;

    SELECT COUNT(*)
    INTO v_errores
    FROM CP_BITACORA_ERROR
    WHERE id_bitacora_error > v_antes
      AND modulo IN ('CREDITO', 'CUENTA');

    reportar('25. Los ' || v_esperados || ' errores quedaron en la bitacora',
             v_errores = v_esperados);

    DELETE FROM CP_BITACORA_ERROR
    WHERE id_bitacora_error > v_antes
      AND modulo IN ('CREDITO', 'CUENTA');

    COMMIT;

END;
/

-- ============================================================
-- 11. PRUEBAS DE CUENTAS POR PAGAR
-- ============================================================
-- Las 17 pruebas deben salir OK (la 7 se omite con OK si no hay un
-- proveedor sin credito). Se crea un credito nuevo de 500000 para un
-- proveedor existente y todo se deshace al final.

DECLARE
    v_antes        NUMBER;
    v_esperados    NUMBER := 0;
    v_errores      NUMBER;
    v_id_proveedor NUMBER;
    v_id_negocio   NUMBER;
    v_id_almacen   NUMBER;
    v_id_sin_cred  NUMBER;
    v_id_usuario   NUMBER;
    v_id_tipo_pago NUMBER;
    v_id_credito   NUMBER;
    v_activo       NUMBER;
    v_fc_pendiente NUMBER;
    v_fc_anulada   NUMBER;
    v_ultima       NUMBER;
    v_f1           NUMBER;
    v_f3           NUMBER;
    v_f4           NUMBER;
    v_c1           NUMBER;
    v_c3           NUMBER;
    v_c4           NUMBER;
    v_id_abono     NUMBER;
    v_codigo       NUMBER;

    PROCEDURE reportar(
        p_prueba IN VARCHAR2,
        p_ok     IN BOOLEAN
    )
    IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(
            RPAD(p_prueba, 62, '.') || CASE WHEN p_ok THEN ' OK' ELSE ' FALLA' END
        );
    END reportar;

    FUNCTION provoca(
        p_obtenido IN NUMBER,
        p_esperado IN NUMBER
    ) RETURN BOOLEAN
    IS
    BEGIN
        v_esperados := v_esperados + 1;
        RETURN p_obtenido = p_esperado;
    END provoca;

    FUNCTION nueva_factura(
        p_numero       IN VARCHAR2,
        p_id_proveedor IN NUMBER,
        p_total        IN NUMBER
    ) RETURN NUMBER
    IS
    BEGIN
        INSERT INTO CP_FACTURA_COMPRA
            (id_proveedor, id_negocio, id_almacen_recepcion, id_usuario,
             id_estado_factura_compra, numero_factura, fecha_emision,
             subtotal, descuento_total, impuesto_total, total)
        VALUES
            (p_id_proveedor, v_id_negocio, v_id_almacen, v_id_usuario,
             v_fc_pendiente, p_numero, SYSDATE, p_total, 0, 0, p_total)
        RETURNING id_factura_compra INTO v_ultima;
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            v_ultima := NULL;
            RETURN SQLCODE;
    END nueva_factura;

    FUNCTION cuenta_de(
        p_id_factura IN NUMBER
    ) RETURN NUMBER
    IS
        v_id NUMBER;
    BEGIN
        SELECT MIN(id_cuenta_pagar)
        INTO v_id
        FROM CP_CUENTA_PAGAR
        WHERE id_factura_compra = p_id_factura;
        RETURN v_id;
    END cuenta_de;

    FUNCTION cuentas_de(
        p_id_factura IN NUMBER
    ) RETURN NUMBER
    IS
        v_total NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_total
        FROM CP_CUENTA_PAGAR
        WHERE id_factura_compra = p_id_factura;
        RETURN v_total;
    END cuentas_de;

    FUNCTION facturas_con_numero(
        p_numero IN VARCHAR2
    ) RETURN NUMBER
    IS
        v_total NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_total
        FROM CP_FACTURA_COMPRA
        WHERE numero_factura = p_numero;
        RETURN v_total;
    END facturas_con_numero;

    FUNCTION plazo_de(
        p_id IN NUMBER
    ) RETURN NUMBER
    IS
        v_dias NUMBER;
    BEGIN
        SELECT ROUND(fecha_vencimiento - fecha_creacion)
        INTO v_dias
        FROM CP_CUENTA_PAGAR
        WHERE id_cuenta_pagar = p_id;
        RETURN v_dias;
    END plazo_de;

    FUNCTION credito_de(
        p_id IN NUMBER
    ) RETURN NUMBER
    IS
        v_credito NUMBER;
    BEGIN
        SELECT id_credito_proveedor
        INTO v_credito
        FROM CP_CUENTA_PAGAR
        WHERE id_cuenta_pagar = p_id;
        RETURN v_credito;
    END credito_de;

    FUNCTION saldo_de(
        p_id IN NUMBER
    ) RETURN NUMBER
    IS
        v_saldo NUMBER;
    BEGIN
        SELECT saldo_pendiente
        INTO v_saldo
        FROM CP_CUENTA_PAGAR
        WHERE id_cuenta_pagar = p_id;
        RETURN v_saldo;
    END saldo_de;

    FUNCTION estado_de(
        p_id IN NUMBER
    ) RETURN VARCHAR2
    IS
        v_estado VARCHAR2(30);
    BEGIN
        SELECT ep.nombre_estado_cuenta_pagar
        INTO v_estado
        FROM CP_CUENTA_PAGAR cp
        JOIN CP_ESTADO_CUENTA_PAGAR ep
          ON ep.id_estado_cuenta_pagar = cp.id_estado_cuenta_pagar
        WHERE cp.id_cuenta_pagar = p_id;
        RETURN v_estado;
    END estado_de;

    FUNCTION estado_factura(
        p_id_factura IN NUMBER
    ) RETURN VARCHAR2
    IS
        v_estado VARCHAR2(30);
    BEGIN
        SELECT ef.nombre_estado_factura
        INTO v_estado
        FROM CP_FACTURA_COMPRA fc
        JOIN CP_ESTADO_FACTURA_COMPRA ef
          ON ef.id_estado_factura_compra = fc.id_estado_factura_compra
        WHERE fc.id_factura_compra = p_id_factura;
        RETURN v_estado;
    END estado_factura;

    FUNCTION abonar(
        p_id    IN NUMBER,
        p_monto IN NUMBER
    ) RETURN NUMBER
    IS
    BEGIN
        INSERT INTO CP_ABONO_CUENTA_PAGAR
            (id_cuenta_pagar, id_tipo_pago, id_usuario, monto_abono, fecha_abono)
        VALUES
            (p_id, v_id_tipo_pago, v_id_usuario, p_monto, SYSTIMESTAMP);
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN SQLCODE;
    END abonar;

BEGIN

    SELECT NVL(MAX(id_bitacora_error), 0) INTO v_antes FROM CP_BITACORA_ERROR;

    SELECT id_proveedor, id_negocio
    INTO v_id_proveedor, v_id_negocio
    FROM CP_CREDITO_PROVEEDOR
    ORDER BY id_credito_proveedor
    FETCH FIRST 1 ROW ONLY;

    SELECT MIN(a.id_almacen) INTO v_id_almacen
    FROM CP_ALMACEN a
    JOIN CP_SUCURSAL s ON s.id_sucursal = a.id_sucursal
    WHERE s.id_negocio = v_id_negocio;

    SELECT MIN(p.id_proveedor) INTO v_id_sin_cred
    FROM CP_PROVEEDOR p
    WHERE NOT EXISTS (
        SELECT 1
        FROM CP_CREDITO_PROVEEDOR cr
        WHERE cr.id_proveedor = p.id_proveedor
          AND cr.id_negocio = v_id_negocio
    );

    SELECT MIN(id_usuario) INTO v_id_usuario FROM CP_USUARIO;
    SELECT MIN(id_tipo_pago) INTO v_id_tipo_pago FROM CP_TIPO_PAGO;

    SELECT id_estado_credito INTO v_activo
    FROM CP_ESTADO_CREDITO
    WHERE nombre_estado_credito = 'ACTIVO';

    SELECT id_estado_factura_compra INTO v_fc_pendiente
    FROM CP_ESTADO_FACTURA_COMPRA
    WHERE nombre_estado_factura = 'PENDIENTE';

    SELECT id_estado_factura_compra INTO v_fc_anulada
    FROM CP_ESTADO_FACTURA_COMPRA
    WHERE nombre_estado_factura = 'ANULADA';

    INSERT INTO CP_CREDITO_PROVEEDOR
        (id_proveedor, id_negocio, id_estado_credito, limite_credito,
         fecha_autorizacion, fecha_vencimiento)
    VALUES
        (v_id_proveedor, v_id_negocio, v_activo, 500000,
         SYSDATE - 10, SYSDATE + 365)
    RETURNING id_credito_proveedor INTO v_id_credito;

    -- Creacion de la cuenta al pasar la factura a PENDIENTE
    v_codigo := nueva_factura('TEST-FC-1', v_id_proveedor, 400000);
    v_f1 := v_ultima;
    v_c1 := cuenta_de(v_f1);

    reportar('1. Factura PENDIENTE de 400000 crea su cuenta por pagar',
             v_codigo = 0 AND cuentas_de(v_f1) = 1
             AND saldo_de(v_c1) = 400000
             AND estado_de(v_c1) = 'PENDIENTE');

    reportar('2. La cuenta vence 30 dias despues de crearse',
             v_c1 IS NOT NULL AND plazo_de(v_c1) = 30);

    reportar('3. La cuenta queda ligada al credito nuevo',
             v_c1 IS NOT NULL AND credito_de(v_c1) = v_id_credito);

    -- Limite de credito
    reportar('4. Factura de 150000 con cupo de 100000 da -20263',
             provoca(nueva_factura('TEST-FC-2', v_id_proveedor, 150000), -20263));

    reportar('5. La factura rechazada no queda guardada',
             facturas_con_numero('TEST-FC-2') = 0);

    v_codigo := nueva_factura('TEST-FC-3', v_id_proveedor, 100000);
    v_f3 := v_ultima;
    v_c3 := cuenta_de(v_f3);

    reportar('6. Factura de 100000 (justo el cupo) se acepta',
             v_codigo = 0 AND v_c3 IS NOT NULL);

    IF v_id_sin_cred IS NULL THEN
        reportar('7. Proveedor sin credito da -20260 (no hay proveedor para probar)', TRUE);
    ELSE
        reportar('7. Proveedor sin credito da -20260',
                 provoca(nueva_factura('TEST-FC-4', v_id_sin_cred, 1), -20260));
    END IF;

    -- Anulacion de la factura
    UPDATE CP_FACTURA_COMPRA
    SET id_estado_factura_compra = v_fc_anulada
    WHERE id_factura_compra = v_f1;

    v_codigo := nueva_factura('TEST-FC-5', v_id_proveedor, 150000);
    v_f4 := v_ultima;
    v_c4 := cuenta_de(v_f4);

    reportar('8. Anular la factura anula su cuenta y libera cupo',
             estado_de(v_c1) = 'ANULADA' AND v_codigo = 0 AND v_c4 IS NOT NULL);

    -- Abonos
    reportar('9. Abono de 30000 sobre 100000 deja saldo 70000 y PARCIAL',
             abonar(v_c3, 30000) = 0 AND saldo_de(v_c3) = 70000
             AND estado_de(v_c3) = 'PARCIAL');
    reportar('10. La factura sigue PENDIENTE con saldo por pagar',
             estado_factura(v_f3) = 'PENDIENTE');

    SELECT MIN(id_abono_cuenta_pagar) INTO v_id_abono
    FROM CP_ABONO_CUENTA_PAGAR
    WHERE id_cuenta_pagar = v_c3;

    reportar('11. Abono de 70000 deja saldo 0, cuenta PAGADA y factura CANCELADA',
             abonar(v_c3, 70000) = 0 AND saldo_de(v_c3) = 0
             AND estado_de(v_c3) = 'PAGADA'
             AND estado_factura(v_f3) = 'CANCELADA');
    reportar('12. Pasar a CANCELADA no crea otra cuenta',
             cuentas_de(v_f3) = 1);
    reportar('13. Abonar a una cuenta saldada da -20252',
             provoca(abonar(v_c3, 1), -20252));

    BEGIN
        UPDATE CP_ABONO_CUENTA_PAGAR
        SET monto_abono = 1
        WHERE id_abono_cuenta_pagar = v_id_abono;
        reportar('14. Modificar un abono da -20254', FALSE);
    EXCEPTION
        WHEN OTHERS THEN
            reportar('14. Modificar un abono da -20254', provoca(SQLCODE, -20254));
    END;

    BEGIN
        DELETE FROM CP_ABONO_CUENTA_PAGAR
        WHERE id_abono_cuenta_pagar = v_id_abono;
        reportar('15. Eliminar un abono da -20254', FALSE);
    EXCEPTION
        WHEN OTHERS THEN
            reportar('15. Eliminar un abono da -20254', provoca(SQLCODE, -20254));
    END;

    v_codigo := abonar(v_c4, 1000);

    BEGIN
        UPDATE CP_FACTURA_COMPRA
        SET id_estado_factura_compra = v_fc_anulada
        WHERE id_factura_compra = v_f4;
        reportar('16. Anular una factura con abonos da -20265', FALSE);
    EXCEPTION
        WHEN OTHERS THEN
            reportar('16. Anular una factura con abonos da -20265', provoca(SQLCODE, -20265));
    END;

    ROLLBACK;

    SELECT COUNT(*)
    INTO v_errores
    FROM CP_BITACORA_ERROR
    WHERE id_bitacora_error > v_antes
      AND modulo IN ('CREDITO', 'CUENTA');

    reportar('17. Los ' || v_esperados || ' errores quedaron en la bitacora',
             v_errores = v_esperados);

    DELETE FROM CP_BITACORA_ERROR
    WHERE id_bitacora_error > v_antes
      AND modulo IN ('CREDITO', 'CUENTA');

    COMMIT;

END;
/
