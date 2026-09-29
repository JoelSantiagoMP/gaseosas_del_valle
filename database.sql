
-- Garantiza que los literales UTF-8 (ñ, tildes) se almacenen bien
-- aunque el cliente se conecte con latin1 por defecto.
SET NAMES utf8mb4;

DROP DATABASE IF EXISTS gaseosas_del_valle;
CREATE DATABASE gaseosas_del_valle
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE gaseosas_del_valle;

-- ============================================================================
-- TABLES
-- ============================================================================

-- ---------------------------------------------------------------------------
-- productos
-- Catálogo de productos con umbrales de control de stock.
-- ---------------------------------------------------------------------------
CREATE TABLE productos (
    id_producto   INT           NOT NULL AUTO_INCREMENT,
    nombre        VARCHAR(150)  NOT NULL,
    categoria     VARCHAR(80)   NOT NULL,
    precio        DECIMAL(12,2) NOT NULL,
    volumen_ml    INT           NOT NULL,
    stock_actual  INT           NOT NULL DEFAULT 0,
    stock_minimo  INT           NOT NULL DEFAULT 0,
    PRIMARY KEY (id_producto),
    -- CHECK: impedir valores negativos en campos financieros y de stock
    CONSTRAINT chk_precio_positivo    CHECK (precio >= 0),
    CONSTRAINT chk_stock_actual_pos   CHECK (stock_actual >= 0),
    CONSTRAINT chk_stock_minimo_pos   CHECK (stock_minimo >= 0)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------------
-- clientes
-- Base de clientes del distribuidor; identificacion es única (NIT / CC).
-- ---------------------------------------------------------------------------
CREATE TABLE clientes (
    id_cliente          INT          NOT NULL AUTO_INCREMENT,
    nombre_completo     VARCHAR(200) NOT NULL,
    identificacion      VARCHAR(20)  NOT NULL,
    direccion           VARCHAR(255) NOT NULL,
    telefono            VARCHAR(20)  NOT NULL,
    correo_electronico  VARCHAR(150) NOT NULL,
    PRIMARY KEY (id_cliente),
    UNIQUE KEY uq_identificacion (identificacion)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------------
-- sedes
-- Sedes de distribución física (Girón, Bucaramanga, Piedecuesta).
-- ---------------------------------------------------------------------------
CREATE TABLE sedes (
    id_sede                   INT          NOT NULL AUTO_INCREMENT,
    nombre_sede               VARCHAR(120) NOT NULL,
    ubicacion                 VARCHAR(255) NOT NULL,
    capacidad_almacenamiento  INT          NOT NULL,
    encargado                 VARCHAR(200) NOT NULL,
    PRIMARY KEY (id_sede)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------------
-- pedidos
-- Encabezado de cada pedido de venta.
-- ON DELETE RESTRICT previene la eliminación accidental de clientes/sedes
-- con pedidos asociados.
-- ON UPDATE CASCADE propaga cambios de clave (buena práctica).
-- ---------------------------------------------------------------------------
CREATE TABLE pedidos (
    id_pedido      INT           NOT NULL AUTO_INCREMENT,
    fecha_pedido   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    id_cliente     INT           NOT NULL,
    id_sede        INT           NOT NULL,
    total_sin_iva  DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_con_iva  DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    PRIMARY KEY (id_pedido),
    CONSTRAINT fk_pedido_cliente
        FOREIGN KEY (id_cliente) REFERENCES clientes (id_cliente)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_pedido_sede
        FOREIGN KEY (id_sede) REFERENCES sedes (id_sede)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;


CREATE TABLE detalle_pedidos (
    id_detalle   INT           NOT NULL AUTO_INCREMENT,
    id_pedido    INT           NOT NULL,
    id_producto  INT           NOT NULL,
    cantidad     INT           NOT NULL,
    subtotal     DECIMAL(12,2) NOT NULL,
    PRIMARY KEY (id_detalle),
    CONSTRAINT chk_cantidad_positiva   CHECK (cantidad > 0),
    CONSTRAINT chk_subtotal_no_negativo CHECK (subtotal >= 0),
    CONSTRAINT fk_detalle_pedido
        FOREIGN KEY (id_pedido) REFERENCES pedidos (id_pedido)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_detalle_producto
        FOREIGN KEY (id_producto) REFERENCES productos (id_producto)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE auditoria_precios (
    id_auditoria   INT           NOT NULL AUTO_INCREMENT,
    id_producto    INT           NOT NULL,
    precio_anterior DECIMAL(12,2) NOT NULL,
    precio_nuevo   DECIMAL(12,2) NOT NULL,
    fecha_cambio   TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_auditoria),
    CONSTRAINT fk_auditoria_producto
        FOREIGN KEY (id_producto) REFERENCES productos (id_producto)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;


INSERT INTO productos (nombre, categoria, precio, volumen_ml, stock_actual, stock_minimo) VALUES
('Coca-Cola Original',           'Gaseosas',       3500.00,  350, 120, 30),
('Coca-Cola 1.5L',               'Gaseosas',       6500.00, 1500,  80, 20),
('Pepsi Lata',                   'Gaseosas',       3200.00,  330,  95, 25),
('Sprite 600ml',                 'Gaseosas',       3000.00,  600, 110, 25),
('Fanta Naranja 350ml',          'Gaseosas',       3300.00,  350,  70, 20),
('Agua Cristal 600ml',           'Aguas',          2000.00,  600, 200, 50),
('Agua Cristal 1.5L',            'Aguas',          3500.00, 1500, 150, 40),
('Jugo Hit Mango 250ml',         'Jugos',          2800.00,  250, 130, 30),
('Jugo Hit Lulo 250ml',          'Jugos',          2800.00,  250, 100, 30),
('Jugo Hit Mora 250ml',          'Jugos',          2800.00,  250,  90, 30),
('Pony Malta 330ml',             'Maltas',         3000.00,  330, 160, 35),
('Pony Malta 1.5L',              'Maltas',         6000.00, 1500,  60, 15),
('Colombiana 350ml',             'Gaseosas',       3100.00,  350,  85, 25),
('Red Bull 250ml',               'Energizantes',   7500.00,  250,  40, 10),
('Gatorade Limón 500ml',         'Hidratantes',    4500.00,  500,  75, 20),
('Gatorade Naranja 500ml',       'Hidratantes',    4500.00,  500,  65, 20),
('Té Fuze Limón 400ml',          'Tés',            3800.00,  400,  55, 15),
('Té Fuze Durazno 400ml',        'Tés',            3800.00,  400,  50, 15),
('Agua con Gas Manantial 600ml', 'Aguas',          2500.00,  600,  90, 25),
('Manzana Postobón 350ml',       'Gaseosas',       3100.00,  350, 100, 25);

-- Clientes
INSERT INTO clientes (nombre_completo, identificacion, direccion, telefono, correo_electronico) VALUES
('Distribuciones El Valle SAS',  '900123456-1', 'Cra 25 #30-10, Girón',          '3101234567', 'ventas@elvalle.co'),
('Tienda Doña Rosa',             '1098765432',  'Cll 45 #12-05, Bucaramanga',    '3209876543', 'donarosa@mail.com'),
('Supermercado La Economía',     '900654321-7', 'Av 33 #20-50, Piedecuesta',     '3157778899', 'economia@mail.com'),
('Autoservicio San Martín',      '900111222-3', 'Cra 15 #22-30, Bucaramanga',    '3124445566', 'sanmartin@mail.com'),
('Cigarrería El Punto',          '37856421',    'Cll 10 #5-18, Girón',           '3176543210', 'elpunto@mail.com'),
('MiniMarket Express',           '900333444-5', 'Cra 27 #48-12, Bucaramanga',    '3148889900', 'express@minimarket.co'),
('Cafetería Universidad',        '900555666-8', 'Campus UIS, Bucaramanga',       '3161112233', 'cafe.uis@mail.com'),
('Panadería La Estrella',        '1055443322',  'Cll 30 #8-45, Piedecuesta',     '3193334455', 'estrella@pan.co'),
('Restaurante Sazón Criollo',    '900777888-2', 'Cra 20 #35-60, Girón',          '3132225566', 'sazon@criollo.co'),
('Hotel Chicamocha Plaza',       '900999000-1', 'Cll 50 #25-80, Bucaramanga',    '3105556677', 'reservas@chicamocha.co');

-- Sedes
INSERT INTO sedes (nombre_sede, ubicacion, capacidad_almacenamiento, encargado) VALUES
('Sede Girón',         'Zona Industrial Girón, Santander',     5000, 'Carlos Andrés Parra'),
('Sede Bucaramanga',   'Av. Quebrada Seca 42-10, Bucaramanga', 8000, 'Luisa Fernanda Rojas'),
('Sede Piedecuesta',   'Cra 6 #10-55, Piedecuesta',            4000, 'Andrés Felipe Díaz');

-- Pedidos (totales se recalculan después de crear triggers/funciones)
INSERT INTO pedidos (fecha_pedido, id_cliente, id_sede, total_sin_iva, total_con_iva) VALUES
('2026-04-01 08:30:00', 1, 1, 0.00, 0.00),
('2026-04-02 10:15:00', 2, 2, 0.00, 0.00),
('2026-04-03 14:00:00', 3, 3, 0.00, 0.00),
('2026-04-05 09:45:00', 4, 2, 0.00, 0.00),
('2026-04-07 11:00:00', 5, 1, 0.00, 0.00),
('2026-04-08 16:20:00', 6, 2, 0.00, 0.00),
('2026-04-10 08:00:00', 7, 2, 0.00, 0.00),
('2026-04-12 13:30:00', 8, 3, 0.00, 0.00),
('2026-04-14 10:00:00', 9, 1, 0.00, 0.00),
('2026-04-15 15:45:00', 10, 2, 0.00, 0.00);

-- Detalle de Pedidos
-- NOTA: Los triggers aún no existen; el stock NO se descuenta aquí.
-- Se ejecuta un UPDATE post-seed (ver sección final) para recalcular totales.
INSERT INTO detalle_pedidos (id_pedido, id_producto, cantidad, subtotal) VALUES
-- Pedido 1: Distribuciones El Valle
(1,  1,  24,  84000.00),
(1,  6,  30,  60000.00),
(1, 11,  20,  60000.00),
-- Pedido 2: Tienda Doña Rosa
(2,  3,  12,  38400.00),
(2,  8,  15,  42000.00),
-- Pedido 3: Supermercado La Economía
(3,  2,  10,  65000.00),
(3, 15,  20,  90000.00),
(3, 20,   8,  24800.00),
-- Pedido 4: Autoservicio San Martín
(4,  4,  18,  54000.00),
(4,  5,  10,  33000.00),
(4, 14,   6,  45000.00),
-- Pedido 5: Cigarrería El Punto
(5,  1,  10,  35000.00),
(5, 13,  12,  37200.00),
-- Pedido 6: MiniMarket Express
(6,  7,  25,  87500.00),
(6, 17,  10,  38000.00),
(6, 18,  10,  38000.00),
-- Pedido 7: Cafetería Universidad
(7,  6,  40,  80000.00),
(7,  9,  20,  56000.00),
-- Pedido 8: Panadería La Estrella
(8, 10,  15,  42000.00),
(8, 11,  10,  30000.00),
-- Pedido 9: Restaurante Sazón Criollo
(9,  1,  30, 105000.00),
(9,  4,  15,  45000.00),
(9, 19,  12,  30000.00),
-- Pedido 10: Hotel Chicamocha Plaza
(10,  2,  20, 130000.00),
(10, 14,  10,  75000.00),
(10, 16,  15,  67500.00);


