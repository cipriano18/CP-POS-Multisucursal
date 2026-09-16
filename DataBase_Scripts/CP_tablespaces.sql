-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- BASE DE DATOS: Oracle 21c
-- SCRIPT: 01_tablespaces.sql
-- DESCRIPCION: Creacion de los tablespaces del sistema
-- ============================================================


-- ============================================================
-- 1. TABLESPACE PARA LAS TABLAS DEL SISTEMA
-- ============================================================

CREATE TABLESPACE CP_POS_DATOS
DATAFILE 'cp_pos_datos01.dbf'
SIZE 100M
AUTOEXTEND ON
NEXT 10M
MAXSIZE UNLIMITED;


-- ============================================================
-- 2. TABLESPACE PARA LOS INDICES
-- ============================================================

CREATE TABLESPACE CP_POS_INDICES
DATAFILE 'cp_pos_indices01.dbf'
SIZE 50M
AUTOEXTEND ON
NEXT 10M
MAXSIZE UNLIMITED;


-- ============================================================
-- 3. TABLESPACE PARA AUDITORIA Y BITACORAS
-- ============================================================

CREATE TABLESPACE CP_POS_AUDITORIA
DATAFILE 'cp_pos_auditoria01.dbf'
SIZE 50M
AUTOEXTEND ON
NEXT 10M
MAXSIZE UNLIMITED;