
CREATE OR REPLACE PROCEDURE PRC_CP_ALERTA_CXP_GERENTE
AS
    v_correo             VARCHAR2(320);
    v_umbral             NUMBER;
    v_id_tipo_contacto   CP_TIPO_DE_CONTACTO.ID_TIPO_CONTACTO%TYPE;
    v_id_contacto        CP_CONTACTO.ID_CONTACTO%TYPE;
    v_id_configuracion   CP_CONFIGURACION_CORREO.ID_CONFIGURACION_CORREO%TYPE;
    v_id_destinatario    CP_DESTINATARIO_NOTIFICACION.ID_DESTINATARIO%TYPE;
    v_id_notificacion    CP_NOTIFICACION.ID_NOTIFICACION%TYPE;
    v_mensaje            VARCHAR2(32767);
    v_cantidad           NUMBER := 0;
    v_porcentaje         NUMBER;
    v_saldo              NUMBER;
    v_limite             NUMBER;
    v_proveedor          VARCHAR2(500);
    v_id_proveedor       NUMBER;
    v_id_credito         NUMBER;

    CURSOR c_proveedores IS
        WITH ABONOS AS (
            SELECT id_cuenta_pagar,
                   SUM(monto_abono) AS total_abonado
            FROM CP_ABONO_CUENTA_PAGAR
            GROUP BY id_cuenta_pagar
        ),
        SALDOS AS (
            SELECT cp.id_factura_compra,
                   SUM(
                       GREATEST(
                           fc.total - NVL(a.total_abonado, 0),
                           0
                       )
                   ) AS saldo_pendiente
            FROM CP_CUENTA_PAGAR cp
            JOIN CP_FACTURA_COMPRA fc
              ON fc.id_factura_compra = cp.id_factura_compra
            LEFT JOIN ABONOS a
              ON a.id_cuenta_pagar = cp.id_cuenta_pagar
            JOIN CP_ESTADO_CUENTA_PAGAR ec
              ON ec.id_estado_cuenta_pagar = cp.id_estado_cuenta_pagar
            WHERE UPPER(ec.nombre_estado_cuenta_pagar)
                  IN ('PENDIENTE', 'PARCIAL', 'VENCIDA')
            GROUP BY cp.id_factura_compra
        )
        SELECT cr.id_credito_proveedor,
               p.id_proveedor,
               p.razon_social,
               cr.limite_credito,
               SUM(s.saldo_pendiente) AS saldo_pendiente,
               ROUND(
                   SUM(s.saldo_pendiente) /
                   NULLIF(cr.limite_credito, 0) * 100,
                   2
               ) AS porcentaje_utilizado
        FROM CP_CREDITO_PROVEEDOR cr
        JOIN CP_PROVEEDOR p
          ON p.id_proveedor = cr.id_proveedor
        JOIN CP_ESTADO_CREDITO e
          ON e.id_estado_credito = cr.id_estado_credito
        JOIN CP_FACTURA_COMPRA fc
          ON fc.id_proveedor = p.id_proveedor
         AND fc.id_negocio = cr.id_negocio
        JOIN SALDOS s
          ON s.id_factura_compra = fc.id_factura_compra
        WHERE UPPER(e.nombre_estado_credito) = 'ACTIVO'
          AND cr.limite_credito > 0
        GROUP BY cr.id_credito_proveedor,
                 p.id_proveedor,
                 p.razon_social,
                 cr.limite_credito
        HAVING SUM(s.saldo_pendiente) >=
               cr.limite_credito * (
                   SELECT TO_NUMBER(valor) / 100
                   FROM CP_PARAMETRO
                   WHERE codigo_parametro = 'UMBRAL_CXP_GERENTE_PCT'
               )
        ORDER BY porcentaje_utilizado DESC;

BEGIN
    v_correo := PKG_CP_PARAMETRO.obtener_texto('CORREO_ALERTAS_BD');
    v_umbral := PKG_CP_PARAMETRO.obtener_numero('UMBRAL_CXP_GERENTE_PCT');

    IF v_correo IS NULL OR v_umbral IS NULL THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'Falta configurar CORREO_ALERTAS_BD o UMBRAL_CXP_GERENTE_PCT.'
        );
    END IF;

    -- Evitar generar más de una alerta diaria.
    SELECT COUNT(*)
      INTO v_cantidad
      FROM CP_NOTIFICACION
     WHERE TIPO_NOTIFICACION = 'ALERTA_CXP_GERENTE_70'
       AND FECHA_CREACION >= TRUNC(SYSDATE)
       AND FECHA_CREACION < TRUNC(SYSDATE) + 1;

    IF v_cantidad > 0 THEN
        RETURN;
    END IF;

    -- Obtener el tipo de contacto CORREO.
    SELECT MIN(id_tipo_contacto)
      INTO v_id_tipo_contacto
      FROM CP_TIPO_DE_CONTACTO
     WHERE UPPER(nombre_tipo_contacto) = 'CORREO';

    IF v_id_tipo_contacto IS NULL THEN
        RAISE_APPLICATION_ERROR(
            -20002,
            'No existe el tipo de contacto CORREO.'
        );
    END IF;

    -- Buscar el correo configurado o registrarlo.
    BEGIN
        SELECT id_contacto
          INTO v_id_contacto
          FROM CP_CONTACTO
         WHERE id_tipo_contacto = v_id_tipo_contacto
           AND LOWER(valor_contacto) = LOWER(v_correo)
           AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO CP_CONTACTO (
                id_tipo_contacto,
                valor_contacto
            )
            VALUES (
                v_id_tipo_contacto,
                v_correo
            )
            RETURNING id_contacto INTO v_id_contacto;
    END;

    -- Obtener una configuración de correo activa.
    SELECT MIN(id_configuracion_correo)
      INTO v_id_configuracion
      FROM CP_CONFIGURACION_CORREO
     WHERE activo = 'S';

    IF v_id_configuracion IS NULL THEN
        RAISE_APPLICATION_ERROR(
            -20003,
            'No existe una configuración de correo activa.'
        );
    END IF;

    v_mensaje :=
        'ALERTA DE CUENTAS POR PAGAR A PROVEEDORES' ||
        CHR(10) || CHR(10) ||
        'Los siguientes proveedores alcanzaron o superaron el ' ||
        TO_CHAR(v_umbral) || '% de utilización de su límite de crédito:' ||
        CHR(10) || CHR(10);

    v_cantidad := 0;

    FOR r IN c_proveedores LOOP
        v_cantidad := v_cantidad + 1;

        v_mensaje := v_mensaje ||
            'Proveedor: ' || r.razon_social || CHR(10) ||
            'ID proveedor: ' || r.id_proveedor || CHR(10) ||
            'Límite de crédito: ' ||
                TO_CHAR(r.limite_credito, 'FM999G999G999G990D00') ||
                CHR(10) ||
            'Saldo pendiente: ' ||
                TO_CHAR(r.saldo_pendiente, 'FM999G999G999G990D00') ||
                CHR(10) ||
            'Porcentaje utilizado: ' ||
                TO_CHAR(r.porcentaje_utilizado) || '%' ||
                CHR(10) ||
            '----------------------------------------' || CHR(10);
    END LOOP;

    -- No enviar correo si ningún proveedor alcanza el umbral.
    IF v_cantidad = 0 THEN
        RETURN;
    END IF;

    v_mensaje := v_mensaje ||
        CHR(10) ||
        'Total de proveedores identificados: ' || v_cantidad ||
        CHR(10) ||
        'Umbral configurado: ' || TO_CHAR(v_umbral) || '%';

    -- Activar o registrar el destinatario.
    MERGE INTO CP_DESTINATARIO_NOTIFICACION d
    USING (
        SELECT v_id_contacto AS id_contacto
        FROM DUAL
    ) x
    ON (d.id_contacto = x.id_contacto)
    WHEN MATCHED THEN
        UPDATE SET d.activo = 'S'
    WHEN NOT MATCHED THEN
        INSERT (id_contacto, activo)
        VALUES (x.id_contacto, 'S');

    SELECT id_destinatario
      INTO v_id_destinatario
      FROM CP_DESTINATARIO_NOTIFICACION
     WHERE id_contacto = v_id_contacto;

    -- Crear una única notificación agrupada.
    INSERT INTO CP_NOTIFICACION (
        id_configuracion_correo,
        asunto,
        mensaje,
        tipo_notificacion
    )
    VALUES (
        v_id_configuracion,
        'Alerta: proveedores cerca del limite de credito',
        v_mensaje,
        'ALERTA_CXP_GERENTE_70'
    )
    RETURNING id_notificacion INTO v_id_notificacion;

    INSERT INTO CP_NOTIFICACION_DESTINATARIO (
        id_notificacion,
        id_destinatario,
        estado_envio
    )
    VALUES (
        v_id_notificacion,
        v_id_destinatario,
        'PENDIENTE'
    );

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        PKG_CP_ERROR.registrar_inesperado(
            'PRC_CP_ALERTA_CXP_GERENTE',
            SQLERRM
        );
        RAISE;
END;
/
