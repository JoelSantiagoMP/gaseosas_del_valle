
SET NAMES utf8mb4;
USE gaseosas_del_valle;

DROP FUNCTION IF EXISTS fn_calcular_total_con_iva;
DROP FUNCTION IF EXISTS fn_validar_stock;
DROP FUNCTION IF EXISTS fn_calcular_promedio_pedidos_cliente;

DELIMITER //

-- ---------------------------------------------------------------------------
-- fn_calcular_total_con_iva
-- ---------------------------------------------------------------------------
-- Propósito : Calcula el total de un pedido INCLUYENDO el 19 % de IVA
--             colombiano, sumando todos los subtotales de detalle_pedidos.
--
-- Parámetro : p_id_pedido — ID del pedido a calcular.
-- Retorna   : DECIMAL(12,2) — total con IVA.
--             Retorna 0.00 si el pedido no tiene detalles o no existe.
--
-- Ejemplo de uso:
--   SELECT fn_calcular_total_con_iva(1);
-- ---------------------------------------------------------------------------
CREATE FUNCTION fn_calcular_total_con_iva(p_id_pedido INT)
RETURNS DECIMAL(12,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_subtotal DECIMAL(12,2) DEFAULT 0.00;

    -- Sumar todos los subtotales de las líneas del pedido
    SELECT IFNULL(SUM(subtotal), 0.00)
      INTO v_subtotal
      FROM detalle_pedidos
     WHERE id_pedido = p_id_pedido;

    -- Aplicar el 19 % de IVA y retornar
    RETURN ROUND(v_subtotal * 1.19, 2);
END//

-- ---------------------------------------------------------------------------
-- fn_validar_stock
-- ---------------------------------------------------------------------------
-- Propósito : Verifica si hay stock suficiente de un producto para
--             satisfacer una cantidad solicitada antes de confirmar
--             un pedido.
--
-- Parámetros: p_id_producto  — ID del producto a validar.
--             p_cantidad     — cantidad requerida.
-- Retorna   : VARCHAR(150) con uno de tres estados:
--               'DISPONIBLE'   — el stock es suficiente.
--               'INSUFICIENTE' — el stock es menor a la cantidad pedida.
--               'NO_ENCONTRADO'— el producto no existe en la tabla.
--
-- Ejemplo de uso:
--   SELECT fn_validar_stock(1, 10);
-- ---------------------------------------------------------------------------
CREATE FUNCTION fn_validar_stock(p_id_producto INT, p_cantidad INT)
RETURNS VARCHAR(150)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_stock_actual INT DEFAULT NULL;

    -- Buscar el stock actual del producto
    SELECT stock_actual
      INTO v_stock_actual
      FROM productos
     WHERE id_producto = p_id_producto;

    -- El producto no existe
    IF v_stock_actual IS NULL THEN
        RETURN 'NO_ENCONTRADO: El producto no existe en el catálogo.';
    END IF;

    -- ¿Hay suficiente stock?
    IF v_stock_actual >= p_cantidad THEN
        RETURN CONCAT('DISPONIBLE: Stock actual = ', v_stock_actual,
                       ', solicitado = ', p_cantidad, '.');
    ELSE
        RETURN CONCAT('INSUFICIENTE: Stock actual = ', v_stock_actual,
                       ', solicitado = ', p_cantidad,
                       '. Faltan ', (p_cantidad - v_stock_actual), ' unidades.');
    END IF;
END//

-- ---------------------------------------------------------------------------
-- fn_calcular_promedio_pedidos_cliente
-- ---------------------------------------------------------------------------
-- Propósito : Calcula el promedio de total_sin_iva de los pedidos de un
--             cliente.
--
-- Parámetro : p_id_cliente — ID del cliente.
-- Retorna   : DECIMAL(12,2) — promedio sin IVA.
--             Retorna 0.00 si el cliente no existe o no tiene pedidos.
--
-- Ejemplo de uso:
--   SELECT fn_calcular_promedio_pedidos_cliente(1);
-- ---------------------------------------------------------------------------
CREATE FUNCTION fn_calcular_promedio_pedidos_cliente(p_id_cliente INT)
RETURNS DECIMAL(12,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_promedio_total DECIMAL(12,2) DEFAULT 0.00;

    SELECT IFNULL(AVG(total_sin_iva), 0.00)
      INTO v_promedio_total
      FROM pedidos
     WHERE id_cliente = p_id_cliente;

    RETURN v_promedio_total;
END//


DELIMITER ;


