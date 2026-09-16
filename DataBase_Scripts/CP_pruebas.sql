-- ============================================================
-- 10_pruebas.sql
-- PRUEBAS DEL SISTEMA CP_POS
-- PRUEBAS 1 A 10
-- ============================================================

-- IMPORTANTE:
-- Estas pruebas intentan violar restricciones del sistema.
-- Si la restriccion rechaza la operacion, la prueba es correcta.


-- ============================================================
-- PRUEBA 1
-- PRIMARY KEY - CP_TIPO_NEGOCIO
-- ============================================================

BEGIN
    INSERT INTO CP_TIPO_NEGOCIO
    (id_tipo_negocio, nombre_tipo_negocio, descripcion)
    SELECT id_tipo_negocio,
           'NEGOCIO PRUEBA',
           'Registro utilizado para probar la PK'
    FROM CP_TIPO_NEGOCIO
    WHERE ROWNUM = 1;

    DBMS_OUTPUT.PUT_LINE(
        'PRUEBA 1: ERROR - Permitio una PK duplicada.'
    );

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        DBMS_OUTPUT.PUT_LINE(
            'PRUEBA 1: CORRECTA - La PK impidio el valor duplicado.'
        );
END;
/

ROLLBACK;


-- ============================================================
-- PRUEBA 2
-- UNIQUE - CP_TIPO_OPERACION
-- ============================================================

BEGIN
    INSERT INTO CP_TIPO_OPERACION
    (nombre_tipo_operacion, descripcion)
    VALUES
    ('MODIFICACION', 'Prueba de valor duplicado');

    DBMS_OUTPUT.PUT_LINE(
        'PRUEBA 2: ERROR - Permitio duplicar el tipo de operacion.'
    );

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        DBMS_OUTPUT.PUT_LINE(
            'PRUEBA 2: CORRECTA - UNIQUE impidio el valor duplicado.'
        );
END;
/

ROLLBACK;


-- ============================================================
-- PRUEBA 3
-- FOREIGN KEY - CP_CANTON
-- ============================================================

BEGIN
    INSERT INTO CP_CANTON
    (id_provincia, nombre)
    VALUES
    (999999, 'CANTON DE PRUEBA');

    DBMS_OUTPUT.PUT_LINE(
        'PRUEBA 3: ERROR - Permitio una provincia inexistente.'
    );

EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -2291 THEN
            DBMS_OUTPUT.PUT_LINE(
                'PRUEBA 3: CORRECTA - La FK rechazo la provincia inexistente.'
            );
        ELSE
            RAISE;
        END IF;
END;
/

ROLLBACK;


-- ============================================================
-- PRUEBA 4
-- FOREIGN KEY - CP_DISTRITO
-- ============================================================

BEGIN
    INSERT INTO CP_DISTRITO
    (id_canton, nombre)
    VALUES
    (999999, 'DISTRITO DE PRUEBA');

    DBMS_OUTPUT.PUT_LINE(
        'PRUEBA 4: ERROR - Permitio un canton inexistente.'
    );

EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -2291 THEN
            DBMS_OUTPUT.PUT_LINE(
                'PRUEBA 4: CORRECTA - La FK rechazo el canton inexistente.'
            );
        ELSE
            RAISE;
        END IF;
END;
/

ROLLBACK;


-- ============================================================
-- PRUEBA 5
-- CHECK - CP_PRODUCTO_NEGOCIO
-- ============================================================

BEGIN
    UPDATE CP_PRODUCTO_NEGOCIO
    SET porcentaje_utilidad = 150
    WHERE id_producto_negocio =
          (
              SELECT MIN(id_producto_negocio)
              FROM CP_PRODUCTO_NEGOCIO
          );

    DBMS_OUTPUT.PUT_LINE(
        'PRUEBA 5: ERROR - Permitio porcentaje_utilidad mayor a 100.'
    );

EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -2290 THEN
            DBMS_OUTPUT.PUT_LINE(
                'PRUEBA 5: CORRECTA - CHECK rechazo porcentaje_utilidad = 150.'
            );
        ELSE
            RAISE;
        END IF;
END;
/

ROLLBACK;


-- ============================================================
-- PRUEBA 6
-- CHECK - CP_PRODUCTO_NEGOCIO
-- ============================================================

BEGIN
    UPDATE CP_PRODUCTO_NEGOCIO
    SET descuento_maximo = -10
    WHERE id_producto_negocio =
          (
              SELECT MIN(id_producto_negocio)
              FROM CP_PRODUCTO_NEGOCIO
          );

    DBMS_OUTPUT.PUT_LINE(
        'PRUEBA 6: ERROR - Permitio descuento_maximo negativo.'
    );

EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -2290 THEN
            DBMS_OUTPUT.PUT_LINE(
                'PRUEBA 6: CORRECTA - CHECK rechazo descuento_maximo = -10.'
            );
        ELSE
            RAISE;
        END IF;
END;
/

ROLLBACK;


-- ============================================================
-- PRUEBA 7
-- INVENTARIO NEGATIVO
-- CP_INVENTARIO_ALMACEN
-- ============================================================

BEGIN
    UPDATE CP_INVENTARIO_ALMACEN
    SET cantidad_actual = -5
    WHERE id_inventario_almacen =
          (
              SELECT MIN(id_inventario_almacen)
              FROM CP_INVENTARIO_ALMACEN
          );

    DBMS_OUTPUT.PUT_LINE(
        'PRUEBA 7: ERROR - Permitio inventario negativo.'
    );

EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20009 OR SQLCODE = -2290 THEN
            DBMS_OUTPUT.PUT_LINE(
                'PRUEBA 7: CORRECTA - Se impidio inventario negativo.'
            );
        ELSE
            RAISE;
        END IF;
END;
/

ROLLBACK;


-- ============================================================
-- PRUEBA 8
-- CHECK - CP_LOTE_PRODUCTO
-- ============================================================

BEGIN
    UPDATE CP_LOTE_PRODUCTO
    SET cantidad_recibida = 0
    WHERE id_lote_producto =
          (
              SELECT MIN(id_lote_producto)
              FROM CP_LOTE_PRODUCTO
          );

    DBMS_OUTPUT.PUT_LINE(
        'PRUEBA 8: ERROR - Permitio cantidad_recibida = 0.'
    );

EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -2290 THEN
            DBMS_OUTPUT.PUT_LINE(
                'PRUEBA 8: CORRECTA - CHECK rechazo cantidad_recibida = 0.'
            );
        ELSE
            RAISE;
        END IF;
END;
/

ROLLBACK;


-- ============================================================
-- PRUEBA 9
-- CHECK - CP_DETALLE_TRASLADO
-- ============================================================

BEGIN
    UPDATE CP_DETALLE_TRASLADO
    SET cantidad = 0
    WHERE id_detalle_traslado =
          (
              SELECT MIN(id_detalle_traslado)
              FROM CP_DETALLE_TRASLADO
          );

    DBMS_OUTPUT.PUT_LINE(
        'PRUEBA 9: ERROR - Permitio cantidad de traslado = 0.'
    );

EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -2290 THEN
            DBMS_OUTPUT.PUT_LINE(
                'PRUEBA 9: CORRECTA - CHECK rechazo cantidad = 0.'
            );
        ELSE
            RAISE;
        END IF;
END;
/

ROLLBACK;


-- ============================================================
-- PRUEBA 10
-- FOREIGN KEY - CP_PRODUCTO
-- ============================================================

BEGIN
    UPDATE CP_PRODUCTO
    SET id_familia_producto = 999999
    WHERE id_producto =
          (
              SELECT MIN(id_producto)
              FROM CP_PRODUCTO
          );

    DBMS_OUTPUT.PUT_LINE(
        'PRUEBA 10: ERROR - Permitio una familia inexistente.'
    );

EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -2291 THEN
            DBMS_OUTPUT.PUT_LINE(
                'PRUEBA 10: CORRECTA - La FK rechazo la familia inexistente.'
            );
        ELSE
            RAISE;
        END IF;
END;
/

ROLLBACK;


-- ============================================================
-- FIN DE PRUEBAS 1 A 10
-- ============================================================
