-- 01_schema.sql
-- DDL only: database, tables, FKs, indexes (no data, no triggers, no views)

CREATE DATABASE IF NOT EXISTS pizza_ordering
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE pizza_ordering;

-- == Table: menu_item ==
CREATE TABLE IF NOT EXISTS menu_item (
  menu_item_id   INT AUTO_INCREMENT PRIMARY KEY,
  name           VARCHAR(100) NOT NULL UNIQUE,
  category       VARCHAR(10)  NOT NULL,          -- 'PIZZA' | 'DRINK' | 'DESSERT'
  base_price     DECIMAL(10,2) NULL,             -- used for DRINK / DESSERT
  is_vegetarian  BOOLEAN NOT NULL DEFAULT FALSE,
  is_vegan       BOOLEAN NOT NULL DEFAULT FALSE
) ENGINE=InnoDB;

-- == Table: ingredient ==
CREATE TABLE IF NOT EXISTS ingredient (
  ingredient_id  INT AUTO_INCREMENT PRIMARY KEY,
  name           VARCHAR(100) NOT NULL UNIQUE,
  is_meat        BOOLEAN NOT NULL DEFAULT FALSE,
  is_dairy       BOOLEAN NOT NULL DEFAULT FALSE,
  is_vegan       BOOLEAN NOT NULL DEFAULT TRUE,
  cost           DECIMAL(8,2) NOT NULL,
  CHECK (cost > 0)
) ENGINE=InnoDB;

-- == Table: menu_item_ingredient (M:N) ==
CREATE TABLE IF NOT EXISTS menu_item_ingredient (
  menu_item_id   INT NOT NULL,
  ingredient_id  INT NOT NULL,
  qty            DECIMAL(6,2) NOT NULL DEFAULT 1,
  CHECK (qty > 0),
  PRIMARY KEY (menu_item_id, ingredient_id),
  CONSTRAINT fk_mii_item       FOREIGN KEY (menu_item_id)  REFERENCES menu_item(menu_item_id),
  CONSTRAINT fk_mii_ingredient FOREIGN KEY (ingredient_id) REFERENCES ingredient(ingredient_id)
) ENGINE=InnoDB;

CREATE INDEX idx_mii_item       ON menu_item_ingredient(menu_item_id);
CREATE INDEX idx_mii_ingredient ON menu_item_ingredient(ingredient_id);

-- == Table: customer ==
CREATE TABLE IF NOT EXISTS customer (
  customer_id INT AUTO_INCREMENT PRIMARY KEY,
  first_name  VARCHAR(100) NOT NULL,
  last_name   VARCHAR(100) NOT NULL,
  email       VARCHAR(200) NOT NULL UNIQUE,
  phone       VARCHAR(40),
  street      VARCHAR(200),
  city        VARCHAR(100),
  postcode    VARCHAR(20),
  gender      VARCHAR(10),
  dob         DATE NOT NULL
) ENGINE=InnoDB;

-- == Table: delivery_person ==
CREATE TABLE IF NOT EXISTS delivery_person (
  delivery_person_id INT AUTO_INCREMENT PRIMARY KEY,
  first_name         VARCHAR(100) NOT NULL,
  last_name          VARCHAR(100) NOT NULL,
  phone              VARCHAR(40),
  last_delivery_at   DATETIME NULL
) ENGINE=InnoDB;

-- == Table: driver_postcode (coverage per driver) ==
CREATE TABLE IF NOT EXISTS driver_postcode (
  delivery_person_id INT NOT NULL,
  postcode           VARCHAR(20) NOT NULL,
  PRIMARY KEY (delivery_person_id, postcode),
  CONSTRAINT fk_driverpostcode_driver FOREIGN KEY (delivery_person_id)
    REFERENCES delivery_person(delivery_person_id)
) ENGINE=InnoDB;

CREATE INDEX idx_driverpostcode_postcode ON driver_postcode(postcode);

-- == Table: discount_code ==
CREATE TABLE IF NOT EXISTS discount_code (
  discount_code_id INT AUTO_INCREMENT PRIMARY KEY,
  code             VARCHAR(50) NOT NULL,
  description      VARCHAR(255),
  percentage       DECIMAL(5,2) NULL,
  is_single_use    BOOLEAN NOT NULL DEFAULT FALSE,
  is_used          BOOLEAN NOT NULL DEFAULT FALSE,
  valid_from       DATE NULL,
  valid_to         DATE NULL,
  UNIQUE KEY uq_discount_code (code)
) ENGINE=InnoDB;

-- == Table: order (header) ==
CREATE TABLE IF NOT EXISTS `order` (
  order_id         BIGINT AUTO_INCREMENT PRIMARY KEY,
  customer_id      INT NOT NULL,
  order_ts         DATETIME NOT NULL,
  subtotal         DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  discount_total   DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  grand_total      DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  birthday_applied BOOLEAN NOT NULL DEFAULT FALSE,
  loyalty_applied  BOOLEAN NOT NULL DEFAULT FALSE,
  discount_code_id INT NULL,
  CONSTRAINT fk_order_customer FOREIGN KEY (customer_id) REFERENCES customer(customer_id),
  CONSTRAINT fk_order_discount FOREIGN KEY (discount_code_id) REFERENCES discount_code(discount_code_id)
) ENGINE=InnoDB;

CREATE INDEX idx_order_customer ON `order`(customer_id);
CREATE INDEX idx_order_ts       ON `order`(order_ts);

-- == Table: order_item (lines) ==
CREATE TABLE IF NOT EXISTS order_item (
  order_item_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  order_id      BIGINT NOT NULL,
  menu_item_id  INT NOT NULL,
  qty           INT NOT NULL,
  unit_price    DECIMAL(10,2) NOT NULL,
  line_total    DECIMAL(10,2) NOT NULL,
  CHECK (qty > 0),
  CONSTRAINT fk_orderitem_order FOREIGN KEY (order_id)     REFERENCES `order`(order_id),
  CONSTRAINT fk_orderitem_menu  FOREIGN KEY (menu_item_id) REFERENCES menu_item(menu_item_id)
) ENGINE=InnoDB;

CREATE INDEX idx_orderitem_order ON order_item(order_id);
CREATE INDEX idx_orderitem_menu  ON order_item(menu_item_id);

-- == Table: delivery (assignment/status per order) ==
CREATE TABLE IF NOT EXISTS delivery (
  order_id           BIGINT NOT NULL PRIMARY KEY,
  delivery_person_id INT NULL,
  status             VARCHAR(20) NOT NULL DEFAULT 'PENDING', -- PENDING | ASSIGNED | OUT_FOR_DELIVERY | DELIVERED | CANCELLED
  assigned_at        DATETIME NULL,
  out_at             DATETIME NULL,
  delivered_at       DATETIME NULL,
  cancelled_at       DATETIME NULL,
  CONSTRAINT fk_delivery_order  FOREIGN KEY (order_id)           REFERENCES `order`(order_id),
  CONSTRAINT fk_delivery_driver FOREIGN KEY (delivery_person_id) REFERENCES delivery_person(delivery_person_id)
) ENGINE=InnoDB;

CREATE INDEX idx_delivery_driver ON delivery(delivery_person_id);
