-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- BASE DE DATOS: Oracle 21c
-- SCRIPT: 33_negocio_pruebas_usuarios.sql
-- DESCRIPCION: Pruebas de los paquetes y vistas de la Fase 4 y del
--              padron con usuarios reales. Cada usuario activa su rol
--              y comprueba que puede usar lo que el script 13 le
--              concedio y que lo demas le es negado:
--
--              Objeto                     GER  JEFE  PROV  DIG
--              VW_CP_ACCIONES_PROMOCION    S    S     S     S
--              PKG_CP_PROMOCION            S    S     S     S
--              PKG_CP_VENCIMIENTO          S    S     S     -
--              PKG_CP_CIERRE               -    S     -     -
--              PKG_CP_DESCUENTO            -    S     -     -
--              PKG_CP_PREMIACION           -    S     -     -
--              VW_CP_VENTA_NETA_FACTURA    S    S     -     -
--              VW_CP_CLIENTE_PADRON        S    S     -     S
--              CP_PADRON_NACIONAL (leer)   S    S     -     S
--              PKG_CP_PADRON               -    -     -     -
--              PKG_CP_AVISO                -    -     -     -
--              CP_PADRON_EXTERNO           -    -     -     -
--              DELETE en el padron         -    -     -     -
--
--              Las llamadas van por SQL dinamico: sin EXECUTE sobre un
--              paquete Oracle responde ORA-06550 (PLS-00201) y sin
--              SELECT sobre una vista o tabla, ORA-00942. Cualquier otro
--              resultado (incluido un error propio del paquete) cuenta
--              como acceso concedido. No crea objetos; lo que cambie el
--              descuento se deshace con ROLLBACK al final.
--
-- EJECUTAR COMO: cada uno de los usuarios USR_CP_GERENTE,
--                USR_CP_JEFE_DEPTO, USR_CP_JEFE_PROVEEDURIA y
--                USR_CP_DIGITADOR (el mismo script, una vez por
--                usuario, cada uno en su conexion de XEPDB1).
--                Requiere los scripts 13, 16, 27 al 31 y el modulo del
--                padron ya ejecutados, y el 13 corrido al final.
-- ============================================================

SET SERVEROUTPUT ON SIZE UNLIMITED

-- ============================================================
-- 1. IDENTIFICACION DEL USUARIO DE LA PRUEBA
-- ============================================================

VARIABLE v_role VARCHAR2(30)

BEGIN
    :v_role := CASE USER
        WHEN 'USR_CP_GERENTE' THEN 'ROL_CP_GERENTE'
        WHEN 'USR_CP_JEFE_DEPTO' THEN 'ROL_CP_JEFE_DEPARTAMENTO'
        WHEN 'USR_CP_JEFE_PROVEEDURIA' THEN 'ROL_CP_JEFE_PROVEEDURIA'
        WHEN 'USR_CP_DIGITADOR' THEN 'ROL_CP_DIGITADOR'
    END;

    DBMS_OUTPUT.PUT_LINE('Usuario conectado ........ ' || USER);
    DBMS_OUTPUT.PUT_LINE('Rol de negocio ........... ' || :v_role);
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
END;
/

-- ============================================================
-- 2. SIN EL ROL ACTIVO NO HAY ACCESO
-- ============================================================

DECLARE
    v_code PLS_INTEGER := 0;
BEGIN
    BEGIN
        EXECUTE IMMEDIATE
            'DECLARE n NUMBER; BEGIN n := CP_POS.PKG_CP_PROMOCION.invoice_actions(-1); END;';
    EXCEPTION
        WHEN OTHERS THEN
            v_code := SQLCODE;
    END;

    DBMS_OUTPUT.PUT_LINE(
        RPAD('00. Sin activar el rol no se puede usar PKG_CP_PROMOCION', 72, '.')
        || CASE WHEN v_code = -6550 THEN ' OK' ELSE ' FALLA (' || v_code || ')' END
    );
END;
/

-- ============================================================
-- 3. ACTIVACION DEL ROL DE NEGOCIO
-- ============================================================

BEGIN
    CP_POS.PKG_CP_SESION.activar_rol(:v_role);
    DBMS_OUTPUT.PUT_LINE('Rol activado correctamente.');
END;
/

-- ============================================================
-- 4. PRUEBAS DE ACCESO POR ROL
-- ============================================================

DECLARE
    v_ger   BOOLEAN := USER = 'USR_CP_GERENTE';
    v_jefe  BOOLEAN := USER = 'USR_CP_JEFE_DEPTO';
    v_prov  BOOLEAN := USER = 'USR_CP_JEFE_PROVEEDURIA';
    v_dig   BOOLEAN := USER = 'USR_CP_DIGITADOR';

    v_ok    NUMBER := 0;
    v_falla NUMBER := 0;
    v_code  PLS_INTEGER;
    v_msg   VARCHAR2(300);

    -- Ejecuta un bloque o sentencia y devuelve SQLCODE (0 si no fallo)
    FUNCTION run(
        p_sql IN VARCHAR2
    ) RETURN PLS_INTEGER
    IS
    BEGIN
        v_msg := NULL;
        EXECUTE IMMEDIATE p_sql;
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            v_msg := SUBSTR(SQLERRM, 1, 300);
            RETURN SQLCODE;
    END run;

    -- Cuenta las filas de una consulta; devuelve SQLCODE si falla
    FUNCTION run_count(
        p_sql IN VARCHAR2
    ) RETURN PLS_INTEGER
    IS
        v_rows NUMBER;
    BEGIN
        v_msg := NULL;
        EXECUTE IMMEDIATE p_sql INTO v_rows;
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            v_msg := SUBSTR(SQLERRM, 1, 300);
            RETURN SQLCODE;
    END run_count;

    -- Compara lo obtenido con lo que el rol deberia poder hacer
    PROCEDURE check_access(
        p_prueba   IN VARCHAR2,
        p_expected IN BOOLEAN,
        p_code     IN PLS_INTEGER
    )
    IS
        v_denied BOOLEAN := p_code IN (-6550, -942, -1031);
        v_passed BOOLEAN := (p_expected AND NOT v_denied)
                            OR (NOT p_expected AND v_denied);
    BEGIN
        IF v_passed THEN
            v_ok := v_ok + 1;
        ELSE
            v_falla := v_falla + 1;
        END IF;

        DBMS_OUTPUT.PUT_LINE(
            RPAD(p_prueba || CASE WHEN p_expected THEN ' (permitido)' ELSE ' (negado)' END,
                 72, '.')
            || CASE WHEN v_passed THEN ' OK' ELSE ' FALLA' END
        );

        IF NOT v_passed THEN
            DBMS_OUTPUT.PUT_LINE('    codigo ' || p_code || ': ' || v_msg);
        END IF;
    END check_access;

BEGIN

    v_code := run_count('SELECT COUNT(*) FROM CP_POS.VW_CP_ACCIONES_PROMOCION');
    check_access('01. Leer VW_CP_ACCIONES_PROMOCION', TRUE, v_code);

    v_code := run('DECLARE n NUMBER; BEGIN '
                  || 'n := CP_POS.PKG_CP_PROMOCION.invoice_actions(-1); END;');
    check_access('02. PKG_CP_PROMOCION.invoice_actions', TRUE, v_code);

    v_code := run('DECLARE c CLOB; BEGIN '
                  || 'c := CP_POS.PKG_CP_VENCIMIENTO.build_report(TRUNC(SYSDATE)); END;');
    check_access('03. PKG_CP_VENCIMIENTO.build_report', NOT v_dig, v_code);

    v_code := run('DECLARE c CLOB; BEGIN '
                  || 'c := CP_POS.PKG_CP_CIERRE.build_day_message(TRUNC(SYSDATE) - 1); END;');
    check_access('04. PKG_CP_CIERRE.build_day_message', v_jefe, v_code);

    v_code := run('DECLARE v VARCHAR2(4000); BEGIN '
                  || 'v := CP_POS.PKG_CP_PREMIACION.is_due(TRUNC(SYSDATE)); END;');
    check_access('05. PKG_CP_PREMIACION.is_due', v_jefe, v_code);

    v_code := run('DECLARE n NUMBER; BEGIN '
                  || 'CP_POS.PKG_CP_DESCUENTO.apply_scheduled_discounts(TRUNC(SYSDATE), n, FALSE); END;');
    check_access('06. PKG_CP_DESCUENTO.apply_scheduled_discounts', v_jefe, v_code);

    v_code := run_count('SELECT COUNT(*) FROM CP_POS.VW_CP_VENTA_NETA_FACTURA');
    check_access('07. Leer VW_CP_VENTA_NETA_FACTURA', v_ger OR v_jefe, v_code);

    v_code := run_count('SELECT COUNT(*) FROM CP_POS.VW_CP_CLIENTE_PADRON');
    check_access('08. Leer VW_CP_CLIENTE_PADRON', NOT v_prov, v_code);

    v_code := run_count('SELECT COUNT(*) FROM CP_POS.CP_PADRON_NACIONAL WHERE ROWNUM = 1');
    check_access('09. Leer CP_PADRON_NACIONAL', NOT v_prov, v_code);

    v_code := run('BEGIN CP_POS.PKG_CP_PADRON.load_file(''no_existe.txt'', FALSE); END;');
    check_access('10. PKG_CP_PADRON.load_file', FALSE, v_code);

    v_code := run('BEGIN CP_POS.PKG_CP_AVISO.queue_notice(''PRUEBA'', ''x'', ''x''); END;');
    check_access('11. PKG_CP_AVISO.queue_notice', FALSE, v_code);

    v_code := run_count('SELECT COUNT(*) FROM CP_POS.CP_PADRON_EXTERNO WHERE ROWNUM = 1');
    check_access('12. Leer la tabla externa CP_PADRON_EXTERNO', FALSE, v_code);

    v_code := run('DELETE FROM CP_POS.CP_PADRON_NACIONAL WHERE ROWNUM = 1');
    check_access('13. Borrar filas del padron', FALSE, v_code);

    ROLLBACK;

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
