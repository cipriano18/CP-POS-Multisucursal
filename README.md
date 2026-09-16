# CP-POS Multisucursal

Sistema de Punto de Venta Multisucursal desarrollado como proyecto del curso de **Administración de Bases de Datos II**.

El proyecto consiste en el diseño e implementación de una base de datos para administrar las operaciones de un sistema de punto de venta con múltiples sucursales, usuarios, productos, inventarios, proveedores, clientes, ventas, compras, créditos, promociones y devoluciones.

## Tecnologías utilizadas

- Oracle Database 21c
- SQL
- PL/SQL
- Oracle SQL Developer / PL/SQL Developer

## Características principales

El sistema permite gestionar:

- Múltiples sucursales y usuarios.
- Productos y familias de productos.
- Proveedores.
- Clientes personales y empresariales.
- Inventario por almacén y lote.
- Traslados de inventario entre almacenes.
- Compras a proveedores.
- Ventas de productos y servicios.
- Cuentas por pagar.
- Cuentas por cobrar.
- Créditos para clientes y proveedores.
- Diferentes tipos de pago.
- Promociones.
- Descuentos.
- Devoluciones de compras y ventas.
- Notas de crédito.
- Historial de cambios de precios.
- Bitácoras de operaciones y movimientos.

## Estructura de la base de datos

La base de datos fue diseñada utilizando el prefijo `CP_` para identificar los objetos correspondientes al sistema.

El proyecto cuenta con **100 tablas**, organizadas para mantener la información normalizada y facilitar la administración de las diferentes operaciones del punto de venta.

También se utilizan tres tablespaces:

- `CP_POS_DATOS`: almacenamiento de las tablas principales.
- `CP_POS_INDICES`: almacenamiento de índices.
- `CP_POS_AUDITORIA`: almacenamiento de las tablas de bitácora y auditoría.

## Scripts del proyecto

El proyecto está dividido en diferentes scripts SQL que deben ejecutarse en un orden específico.

Los scripts incluidos son:

```text
CP_tablespaces.sql
CP_usuario_esquema.sql
CP_secuencias.sql
CP_tablas.sql
CP_constraints.sql
CP_indices.sql
CP_triggers_reglas.sql
CP_comentarios.sql
CP_datos_prueba.sql
CP_vistas.sql
CP_pruebas.sql
```

## Usuarios y orden de ejecución

Para crear correctamente la base de datos, los scripts deben ejecutarse en el siguiente orden y con el usuario correspondiente.

### Usuario SYS / Administrador

Primero se debe ingresar a Oracle utilizando un usuario con permisos de administrador, por ejemplo `SYS`.

Con este usuario se deben ejecutar:

```text
1. CP_tablespaces.sql
2. CP_usuario_esquema.sql
```

El primer script crea los tablespaces utilizados por el proyecto y el segundo crea el usuario `CP_POS`, que será utilizado para trabajar con la base de datos.

### Usuario CP_POS

Después de ejecutar los dos primeros scripts, se debe iniciar sesión con el usuario:

```text
CP_POS
```

Con este usuario se deben ejecutar los demás scripts en el siguiente orden:

```text
3.  CP_secuencias.sql
4.  CP_tablas.sql
5.  CP_constraints.sql
6.  CP_indices.sql
7.  CP_triggers_reglas.sql
8.  CP_comentarios.sql
9.  CP_datos_prueba.sql
10. CP_vistas.sql
11. CP_pruebas.sql
```

## Resumen del orden de ejecución

| Orden | Script | Usuario |
|---|---|---|
| 1 | `CP_tablespaces.sql` | SYS / Administrador |
| 2 | `CP_usuario_esquema.sql` | SYS / Administrador |
| 3 | `CP_secuencias.sql` | CP_POS |
| 4 | `CP_tablas.sql` | CP_POS |
| 5 | `CP_constraints.sql` | CP_POS |
| 6 | `CP_indices.sql` | CP_POS |
| 7 | `CP_triggers_reglas.sql` | CP_POS |
| 8 | `CP_comentarios.sql` | CP_POS |
| 9 | `CP_datos_prueba.sql` | CP_POS |
| 10 | `CP_vistas.sql` | CP_POS |
| 11 | `CP_pruebas.sql` | CP_POS |


## Autor

**Cipriano Rivera Escobar**

Universidad Nacional de Costa Rica  
Sede Regional Brunca  
Administración de Bases de Datos II  
II Ciclo 2026
