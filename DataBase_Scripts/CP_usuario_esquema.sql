-- ============================================================
-- PROYECTO: Sistema de Punto de Venta Multisucursal
-- BASE DE DATOS: Oracle 21c
-- SCRIPT: 02_usuario_esquema.sql
-- DESCRIPCION: Creacion del usuario y esquema CP_POS
-- ============================================================


-- ============================================================
-- 1. CREACION DEL USUARIO
-- ============================================================

CREATE USER CP_POS
IDENTIFIED BY CP_POS_2026
DEFAULT TABLESPACE CP_POS_DATOS
TEMPORARY TABLESPACE TEMP
QUOTA UNLIMITED ON CP_POS_DATOS
QUOTA UNLIMITED ON CP_POS_INDICES
QUOTA UNLIMITED ON CP_POS_AUDITORIA;


-- ============================================================
-- 2. PERMISO PARA INICIAR SESION
-- ============================================================

GRANT CREATE SESSION TO CP_POS;


-- ============================================================
-- 3. PERMISO PARA CREAR TABLAS
-- ============================================================

GRANT CREATE TABLE TO CP_POS;


-- ============================================================
-- 4. PERMISO PARA CREAR SECUENCIAS
-- ============================================================

GRANT CREATE SEQUENCE TO CP_POS;


-- ============================================================
-- 5. PERMISO PARA CREAR VISTAS
-- ============================================================

GRANT CREATE VIEW TO CP_POS;


-- ============================================================
-- 6. PERMISO PARA CREAR PROCEDIMIENTOS, FUNCIONES Y PAQUETES
-- ============================================================

GRANT CREATE PROCEDURE TO CP_POS;


-- ============================================================
-- 7. PERMISO PARA CREAR TRIGGERS
-- ============================================================

GRANT CREATE TRIGGER TO CP_POS;