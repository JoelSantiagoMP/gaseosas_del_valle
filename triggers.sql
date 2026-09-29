
SET NAMES utf8mb4;
USE gaseosas_del_valle;

DROP TRIGGER IF EXISTS tr_actualizar_stock;
DROP TRIGGER IF EXISTS tr_auditar_cambio_precio;

DELIMITER //

-- ---------------------------------------------------------------------------
-- tr_actualizar_stock
-- ---------------------------------------------------------------------------
-- Evento   : AFTER INSERT en detalle_pedidos
-- Propósito : Cada vez que se inserta una línea de detalle de pedido,
--             este trigger descuenta automáticamente la cantidad vendida
--             del stock_actual del producto correspondiente.
--
-- Lógica:
--   1. Obtiene el stock_actual del producto referenciado.
--   2. Si el stock resultante sería negativo, lanza un error SQLSTATE 45000
--      (señal de error definida por el usuario) para impedir la operación.
--   3. Descuenta la cantidad del stock_actual.
--   4. Recalcula los totales del pedido (total_sin_iva y total_con_iva)
--      usando la función fn_calcular_total_con_iva.
--
-- Manejo de errores:
--   SIGNAL SQLSTATE '45000' cancela la transacción si no hay stock
--   suficiente, garantizando la integridad de los datos.
-- ---------------------------------------------------------------------------
CREATE TRIGGER tr_actualizar_stock
AFTER INSERT ON detalle_pedidos
FOR EACH ROW
BEGIN
    DECLARE v_stock_actual INT;

    -- 1. Consultar el stock actual del producto
    SELECT stock_actual
      INTO v_stock_actual
      FROM productos
     WHERE id_producto = NEW.id_producto;

    -- 2. Validar que el stock no quedará negativo
    IF v_stock_actual < NEW.cantidad THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: Stock insuficiente para completar la venta.';
    END IF;

    -- 3. Descontar la cantidad vendida del stock del producto
    UPDATE productos
       SET stock_actual = stock_actual - NEW.cantidad
     WHERE id_producto = NEW.id_producto;

    -- 4. Recalcular los totales del pedido padre
    --    total_sin_iva = suma de subtotales de todas las líneas
    --    total_con_iva = resultado de fn_calcular_total_con_iva
    UPDATE pedidos
       SET total_sin_iva = (
               SELECT IFNULL(SUM(subtotal), 0)
                 FROM detalle_pedidos
                WHERE id_pedido = NEW.id_pedido
           ),
           total_con_iva = fn_calcular_total_con_iva(NEW.id_pedido)
     WHERE id_pedido = NEW.id_pedido;
END//

-- ---------------------------------------------------------------------------
-- tr_auditar_cambio_precio
-- ---------------------------------------------------------------------------
-- Evento   : BEFORE UPDATE en productos
-- Propósito : Cada vez que se modifica el campo 'precio' de un producto,
--             este trigger registra automáticamente el cambio en la tabla
--             auditoria_precios, almacenando:
--               - El producto afectado (id_producto)
--               - El precio anterior (OLD.precio)
--               - El precio nuevo (NEW.precio)
--               - La fecha y hora exacta del cambio (NOW())
--
-- Lógica:
--   Solo se inserta un registro de auditoría cuando el valor del precio
--   REALMENTE cambia (OLD.precio <> NEW.precio), evitando registros
--   innecesarios en actualizaciones que no modifican el precio.
--
-- Ejemplo de activación:
--   UPDATE productos SET precio = 4000.00 WHERE id_producto = 1;
--   → Se inserta: (1, 3500.00, 4000.00, '2026-04-17 ...')
-- ---------------------------------------------------------------------------
CREATE TRIGGER tr_auditar_cambio_precio
BEFORE UPDATE ON productos
FOR EACH ROW
BEGIN
    -- Solo registrar si el precio realmente cambió
    IF OLD.precio <> NEW.precio THEN
        INSERT INTO auditoria_precios (id_producto, precio_anterior, precio_nuevo, fecha_cambio)
        VALUES (OLD.id_producto, OLD.precio, NEW.precio, NOW());
    END IF;
END//

DELIMITER ;

-- ============================================================================
-- POST-SEED: Recalcular totales de pedidos existentes
-- ============================================================================
-- Los datos semilla (database.sql) se insertaron ANTES de que los triggers
-- existieran, por lo que los totales están en 0.00.
-- Esta actualización recalcula los totales para todos los pedidos usando
-- la función fn_calcular_total_con_iva.
-- El stock semilla no se descuenta aquí: las ventas históricas se cargan
-- como saldo inicial y tr_actualizar_stock solo aplica a ventas nuevas.
-- ---------------------------------------------------------------------------

UPDATE pedidos p
   SET total_sin_iva = (
           SELECT IFNULL(SUM(dp.subtotal), 0)
             FROM detalle_pedidos dp
            WHERE dp.id_pedido = p.id_pedido
       ),
       total_con_iva = fn_calcular_total_con_iva(p.id_pedido);

-- ============================================================================
-- END OF triggers.sql
-- ============================================================================
