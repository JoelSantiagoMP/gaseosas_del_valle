
USE gaseosas_del_valle;

-- ============================================================================
-- VISTAS (VIEWS)
-- ============================================================================

-- ---------------------------------------------------------------------------
-- vista_resumen_pedidos_por_sede
-- Muestra el total de pedidos y el volumen de ventas por cada sede.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW vista_resumen_pedidos_por_sede AS
SELECT
    s.id_sede,
    s.nombre_sede,
    s.ubicacion,
    COUNT(p.id_pedido)                AS total_pedidos,
    IFNULL(SUM(p.total_sin_iva), 0)  AS ingresos_sin_iva,
    IFNULL(SUM(p.total_con_iva), 0)  AS ingresos_con_iva
FROM sedes s
LEFT JOIN pedidos p ON p.id_sede = s.id_sede
GROUP BY s.id_sede, s.nombre_sede, s.ubicacion;

-- ---------------------------------------------------------------------------
-- vista_productos_bajo_stock
-- Productos cuyo stock_actual es igual o inferior al stock_minimo.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW vista_productos_bajo_stock AS
SELECT
    id_producto,
    nombre,
    categoria,
    stock_actual,
    stock_minimo,
    (stock_minimo - stock_actual) AS deficit
FROM productos
WHERE stock_actual <= stock_minimo;

-- ---------------------------------------------------------------------------
-- vista_clientes_activos
-- Clientes que han realizado al menos un pedido.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW vista_clientes_activos AS
SELECT DISTINCT
    c.id_cliente,
    c.nombre_completo,
    c.identificacion,
    c.telefono,
    c.correo_electronico
FROM clientes c
INNER JOIN pedidos p ON p.id_cliente = c.id_cliente;


-- ============================================================================
-- CONSULTAS ANALÍTICAS (8 requeridas)
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Consulta 1: Productos por debajo del umbral mínimo de stock
-- Identifica productos que necesitan reposición urgente.
-- ---------------------------------------------------------------------------
SELECT
    id_producto,
    nombre,
    categoria,
    stock_actual,
    stock_minimo,
    (stock_minimo - stock_actual) AS unidades_faltantes
FROM productos
WHERE stock_actual <= stock_minimo
ORDER BY unidades_faltantes DESC;

-- Alternativa usando la vista:
-- SELECT * FROM vista_productos_bajo_stock ORDER BY deficit DESC;


-- ---------------------------------------------------------------------------
-- Consulta 2: Pedidos dentro de un rango de fechas (BETWEEN)
-- Permite filtrar la actividad comercial en un período específico.
-- ---------------------------------------------------------------------------
SELECT
    pe.id_pedido,
    pe.fecha_pedido,
    c.nombre_completo   AS cliente,
    s.nombre_sede       AS sede,
    pe.total_sin_iva,
    pe.total_con_iva
FROM pedidos pe
JOIN clientes c ON c.id_cliente = pe.id_cliente
JOIN sedes    s ON s.id_sede    = pe.id_sede
WHERE pe.fecha_pedido BETWEEN '2026-04-01' AND '2026-04-10'
ORDER BY pe.fecha_pedido;


-- ---------------------------------------------------------------------------
-- Consulta 3: Productos más vendidos (JOIN + GROUP BY, ranking por cantidad)
-- Muestra qué productos generan mayor volumen de ventas.
-- ---------------------------------------------------------------------------
SELECT
    pr.id_producto,
    pr.nombre,
    pr.categoria,
    SUM(dp.cantidad)  AS total_unidades_vendidas,
    SUM(dp.subtotal)  AS ingresos_totales
FROM detalle_pedidos dp
JOIN productos pr ON pr.id_producto = dp.id_producto
GROUP BY pr.id_producto, pr.nombre, pr.categoria
ORDER BY total_unidades_vendidas DESC;


-- ---------------------------------------------------------------------------
-- Consulta 4: Frecuencia de pedidos por cliente (conteo por cliente)
-- Evalúa la lealtad y recurrencia de cada cliente.
-- ---------------------------------------------------------------------------
SELECT
    c.id_cliente,
    c.nombre_completo,
    COUNT(pe.id_pedido)             AS cantidad_pedidos,
    IFNULL(SUM(pe.total_con_iva), 0) AS valor_total_compras
FROM clientes c
LEFT JOIN pedidos pe ON pe.id_cliente = c.id_cliente
GROUP BY c.id_cliente, c.nombre_completo
ORDER BY cantidad_pedidos DESC;


-- ---------------------------------------------------------------------------
-- Consulta 5: Búsqueda de clientes por nombre parcial (LIKE)
-- Permite encontrar clientes sin conocer el nombre exacto.
-- ---------------------------------------------------------------------------
-- Ejemplo A: clientes cuyo nombre contiene 'market' (insensible a mayúsculas)
SELECT *
FROM clientes
WHERE nombre_completo LIKE '%market%';

-- Ejemplo B: clientes cuyo nombre empieza con 'Tienda'
SELECT *
FROM clientes
WHERE nombre_completo LIKE 'Tienda%';

-- Ejemplo C: clientes cuyo nombre contiene 'restaurant' o 'café'
SELECT *
FROM clientes
WHERE nombre_completo LIKE '%Restaurante%'
   OR nombre_completo LIKE '%Cafetería%';


-- ---------------------------------------------------------------------------
-- Consulta 6: Filtrar productos por categorías específicas (IN)
-- Útil para reportes segmentados por tipo de bebida.
-- ---------------------------------------------------------------------------
SELECT
    id_producto,
    nombre,
    categoria,
    precio,
    stock_actual
FROM productos
WHERE categoria IN ('Gaseosas', 'Jugos', 'Energizantes')
ORDER BY categoria, nombre;


-- ---------------------------------------------------------------------------
-- Consulta 7: Cliente con el mayor número total de pedidos (Subconsulta)
-- Identifica al cliente más frecuente del sistema.
-- ---------------------------------------------------------------------------
SELECT
    c.id_cliente,
    c.nombre_completo,
    c.identificacion,
    sub.cantidad_pedidos
FROM clientes c
JOIN (
    -- Subconsulta: contar pedidos por cliente y quedarse con el máximo
    SELECT id_cliente, COUNT(*) AS cantidad_pedidos
    FROM pedidos
    GROUP BY id_cliente
    ORDER BY cantidad_pedidos DESC
    LIMIT 1
) sub ON sub.id_cliente = c.id_cliente;


-- ---------------------------------------------------------------------------
-- Consulta 8: Ingresos agrupados por sede
-- Visión de rendimiento comercial de cada sede de distribución.
-- ---------------------------------------------------------------------------
SELECT
    s.id_sede,
    s.nombre_sede,
    COUNT(pe.id_pedido)                  AS total_pedidos,
    IFNULL(SUM(pe.total_sin_iva), 0)    AS ingresos_sin_iva,
    IFNULL(SUM(pe.total_con_iva), 0)    AS ingresos_con_iva
FROM sedes s
LEFT JOIN pedidos pe ON pe.id_sede = s.id_sede
GROUP BY s.id_sede, s.nombre_sede
ORDER BY ingresos_con_iva DESC;

-- ============================================================================
-- END OF views_and_queries.sql
-- ============================================================================
