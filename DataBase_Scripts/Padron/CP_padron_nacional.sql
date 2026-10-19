-- CP-POS Multisucursal | Importacion del Padron Nacional Electoral
-- Requiere: CP_PADRON_NACIONAL, SEQ_CP_PADRON_NACIONAL y DIR_PADRON.
-- Ejecutar conectado como CP_POS en XEPDB1, en una ventana SQL Script.

CREATE OR REPLACE PACKAGE PKG_CP_PADRON AS
    PROCEDURE CARGAR_ARCHIVO(p_archivo IN VARCHAR2);
END PKG_CP_PADRON;
/

CREATE OR REPLACE PACKAGE BODY PKG_CP_PADRON AS
    PROCEDURE CARGAR_ARCHIVO(p_archivo IN VARCHAR2) IS
        v_archivo      UTL_FILE.FILE_TYPE;
        v_linea        VARCHAR2(32767);
        v_cedula       VARCHAR2(32767);
        v_codigo       VARCHAR2(32767);
        v_nombre       VARCHAR2(32767);
        v_apellido1    VARCHAR2(32767);
        v_apellido2    VARCHAR2(32767);
        v_total        PLS_INTEGER := 0;
        v_insertados   PLS_INTEGER := 0;
        v_duplicados   PLS_INTEGER := 0;
        v_errores      PLS_INTEGER := 0;
        v_pos1         PLS_INTEGER;
        v_pos2         PLS_INTEGER;
        v_pos3         PLS_INTEGER;
        v_pos4         PLS_INTEGER;
        v_pos5         PLS_INTEGER;
        v_pos6         PLS_INTEGER;
        v_pos7         PLS_INTEGER;
    BEGIN
        IF p_archivo IS NULL THEN
            RAISE_APPLICATION_ERROR(-20010, 'Debe indicar el nombre del archivo TXT');
        END IF;

        v_archivo := UTL_FILE.FOPEN('DIR_PADRON', p_archivo, 'R', 32767);

        LOOP
            BEGIN
                UTL_FILE.GET_LINE(v_archivo, v_linea);
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    EXIT;
            END;

            v_total := v_total + 1;
            SAVEPOINT sp_linea_padron;

            BEGIN
                -- Formato TSE: cedula,codigo_electoral,otro,otro,otro,nombre,apellido1,apellido2
                v_pos1 := INSTR(v_linea, ',', 1, 1);
                v_pos2 := INSTR(v_linea, ',', 1, 2);
                v_pos3 := INSTR(v_linea, ',', 1, 3);
                v_pos4 := INSTR(v_linea, ',', 1, 4);
                v_pos5 := INSTR(v_linea, ',', 1, 5);
                v_pos6 := INSTR(v_linea, ',', 1, 6);
                v_pos7 := INSTR(v_linea, ',', 1, 7);

                IF v_pos1 = 0 OR v_pos2 = 0 OR v_pos3 = 0
                   OR v_pos4 = 0 OR v_pos5 = 0 OR v_pos6 = 0
                   OR v_pos7 = 0 OR INSTR(v_linea, ',', 1, 8) > 0 THEN
                    RAISE_APPLICATION_ERROR(-20011, 'Formato incorrecto: se esperan 8 campos');
                END IF;

                v_cedula    := TRIM(SUBSTR(v_linea, 1, v_pos1 - 1));
                v_codigo    := TRIM(SUBSTR(v_linea, v_pos1 + 1, v_pos2 - v_pos1 - 1));
                v_nombre    := TRIM(SUBSTR(v_linea, v_pos5 + 1, v_pos6 - v_pos5 - 1));
                v_apellido1 := TRIM(SUBSTR(v_linea, v_pos6 + 1, v_pos7 - v_pos6 - 1));
                v_apellido2 := TRIM(SUBSTR(v_linea, v_pos7 + 1));

                IF NOT REGEXP_LIKE(v_cedula, '^[0-9]{9}$')
                   OR NOT REGEXP_LIKE(v_codigo, '^[0-9]{6}$')
                   OR v_nombre IS NULL OR v_apellido1 IS NULL
                   OR LENGTH(v_nombre) > 150
                   OR LENGTH(v_apellido1) > 50
                   OR LENGTH(v_apellido2) > 50 THEN
                    RAISE_APPLICATION_ERROR(-20012, 'Datos invalidos o longitud fuera de rango');
                END IF;

                -- La secuencia solo se consume si no existe la cedula.
                INSERT INTO CP_PADRON_NACIONAL
                    (ID_PADRON, CEDULA, NOMBRE, PRIMER_APELLIDO,
                     SEGUNDO_APELLIDO, CODIGO_ELECTORAL)
                SELECT SEQ_CP_PADRON_NACIONAL.NEXTVAL,
                       v_cedula, v_nombre, v_apellido1, v_apellido2, v_codigo
                  FROM DUAL
                 WHERE NOT EXISTS (
                     SELECT 1 FROM CP_PADRON_NACIONAL p
                      WHERE p.CEDULA = v_cedula
                 );

                IF SQL%ROWCOUNT = 1 THEN
                    v_insertados := v_insertados + 1;
                ELSE
                    v_duplicados := v_duplicados + 1;
                END IF;
            EXCEPTION
                WHEN DUP_VAL_ON_INDEX THEN
                    ROLLBACK TO sp_linea_padron;
                    v_duplicados := v_duplicados + 1;
                WHEN OTHERS THEN
                    ROLLBACK TO sp_linea_padron;
                    v_errores := v_errores + 1;
                    IF v_errores <= 10 THEN
                        DBMS_OUTPUT.PUT_LINE('Error linea ' || v_total || ': ' || SQLERRM);
                    END IF;
            END;

            -- Confirmar por lotes para evitar una transaccion demasiado grande.
            IF MOD(v_total, 1000) = 0 THEN
                COMMIT;
            END IF;
        END LOOP;

        UTL_FILE.FCLOSE(v_archivo);
        COMMIT;

        DBMS_OUTPUT.PUT_LINE('Carga finalizada: ' || p_archivo);
        DBMS_OUTPUT.PUT_LINE('Registros leidos: ' || v_total);
        DBMS_OUTPUT.PUT_LINE('Insertados: ' || v_insertados);
        DBMS_OUTPUT.PUT_LINE('Duplicados: ' || v_duplicados);
        DBMS_OUTPUT.PUT_LINE('Errores: ' || v_errores);
    EXCEPTION
        WHEN OTHERS THEN
            IF UTL_FILE.IS_OPEN(v_archivo) THEN
                UTL_FILE.FCLOSE(v_archivo);
            END IF;
            -- Revierte el lote no confirmado; los lotes anteriores ya tienen COMMIT.
            ROLLBACK;
            RAISE;
    END CARGAR_ARCHIVO;
END PKG_CP_PADRON;
/
