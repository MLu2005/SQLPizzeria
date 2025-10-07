-- 03_logic.sql
-- Triggers and procedures (no tables, no views)

USE pizza_ordering;

-- Creation of customer DOB check (insert)
DELIMITER $$
DROP TRIGGER IF EXISTS trg_customer_dob_ins $$
CREATE TRIGGER trg_customer_dob_ins
BEFORE INSERT ON customer
FOR EACH ROW
BEGIN
  IF NEW.dob > CURDATE() THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'DOB must be <= today';
  END IF;
END $$
DELIMITER ;

-- Creation of customer DOB check (update)
DELIMITER $$
DROP TRIGGER IF EXISTS trg_customer_dob_upd $$
CREATE TRIGGER trg_customer_dob_upd
BEFORE UPDATE ON customer
FOR EACH ROW
BEGIN
  IF NEW.dob > CURDATE() THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'DOB must be <= today';
  END IF;
END $$
DELIMITER ;

-- Creation of "only pizza can have ingredients" (insert)
DELIMITER $$
DROP TRIGGER IF EXISTS trg_only_pizza_can_have_ingredients_ins $$
CREATE TRIGGER trg_only_pizza_can_have_ingredients_ins
BEFORE INSERT ON menu_item_ingredient
FOR EACH ROW
BEGIN
  IF (SELECT category FROM menu_item WHERE menu_item_id = NEW.menu_item_id) <> 'PIZZA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only PIZZA can have ingredients';
  END IF;
END $$
DELIMITER ;

-- Creation of "only pizza can have ingredients" (update)
DELIMITER $$
DROP TRIGGER IF EXISTS trg_only_pizza_can_have_ingredients_upd $$
CREATE TRIGGER trg_only_pizza_can_have_ingredients_upd
BEFORE UPDATE ON menu_item_ingredient
FOR EACH ROW
BEGIN
  IF (SELECT category FROM menu_item WHERE menu_item_id = NEW.menu_item_id) <> 'PIZZA' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only PIZZA can have ingredients';
  END IF;
END $$
DELIMITER ;

-- Creation of vegetarian rule (insert)
DELIMITER $$
DROP TRIGGER IF EXISTS trg_veg_pizza_no_meat_ins $$
CREATE TRIGGER trg_veg_pizza_no_meat_ins
BEFORE INSERT ON menu_item_ingredient
FOR EACH ROW
BEGIN
  IF (SELECT is_vegetarian FROM menu_item WHERE menu_item_id = NEW.menu_item_id) = TRUE
     AND (SELECT is_meat FROM ingredient WHERE ingredient_id = NEW.ingredient_id) = TRUE THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Vegetarian pizza cannot contain meat ingredient';
  END IF;
END $$
DELIMITER ;

-- Creation of vegetarian rule (update)
DELIMITER $$
DROP TRIGGER IF EXISTS trg_veg_pizza_no_meat_upd $$
CREATE TRIGGER trg_veg_pizza_no_meat_upd
BEFORE UPDATE ON menu_item_ingredient
FOR EACH ROW
BEGIN
  IF (SELECT is_vegetarian FROM menu_item WHERE menu_item_id = NEW.menu_item_id) = TRUE
     AND (SELECT is_meat FROM ingredient WHERE ingredient_id = NEW.ingredient_id) = TRUE THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Vegetarian pizza cannot contain meat ingredient';
  END IF;
END $$
DELIMITER ;

-- Creation of place_order procedure
-- Uses v_pizza_price_dynamic for pizza pricing; DRINK/DESSERT use base_price
DELIMITER $$
DROP PROCEDURE IF EXISTS place_order $$
CREATE PROCEDURE place_order(
  IN p_session_id    VARCHAR(64),
  IN p_customer_id   INT,
  IN p_discount_code VARCHAR(50)
)
BEGIN
  DECLARE v_now               DATETIME;
  DECLARE v_order_id          BIGINT;
  DECLARE v_subtotal          DECIMAL(10,2) DEFAULT 0.00;
  DECLARE v_discount_loy      DECIMAL(10,2) DEFAULT 0.00;
  DECLARE v_discount_bday     DECIMAL(10,2) DEFAULT 0.00;
  DECLARE v_discount_code_amt DECIMAL(10,2) DEFAULT 0.00;
  DECLARE v_grand_total       DECIMAL(10,2) DEFAULT 0.00;
  DECLARE v_has_pizza         INT DEFAULT 0;
  DECLARE v_pizza_count_hist  BIGINT DEFAULT 0;
  DECLARE v_is_birthday       BOOLEAN DEFAULT FALSE;
  DECLARE v_code_id           INT;
  DECLARE v_code_pct          DECIMAL(5,2);
  DECLARE v_code_single       BOOLEAN;
  DECLARE v_code_used         BOOLEAN;
  DECLARE v_code_ok_dates     BOOLEAN;
  DECLARE v_tmp               DECIMAL(10,2);
  DECLARE v_postcode          VARCHAR(20);
  DECLARE v_driver_id         INT;

  DECLARE exit handler for SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'place_order failed and was rolled back';
  END;

  SET v_now = NOW();
  START TRANSACTION;

  -- Basic checks
  IF NOT EXISTS (SELECT 1 FROM customer WHERE customer_id = p_customer_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Unknown customer_id';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM cart_item WHERE session_id = p_session_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cart is empty';
  END IF;

  -- Must contain at least one pizza
  SELECT COUNT(*) INTO v_has_pizza
  FROM cart_item ci
  JOIN menu_item mi ON mi.menu_item_id = ci.menu_item_id
  WHERE ci.session_id = p_session_id AND mi.category = 'PIZZA';
  IF v_has_pizza = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order must contain at least one PIZZA';
  END IF;

  -- Order header
  INSERT INTO `order` (customer_id, order_ts, subtotal, discount_total, grand_total,
                       birthday_applied, loyalty_applied, discount_code_id)
  VALUES (p_customer_id, v_now, 0, 0, 0, FALSE, FALSE, NULL);
  SET v_order_id = LAST_INSERT_ID();

  -- Move cart → order_item with price snapshot
  INSERT INTO order_item (order_id, menu_item_id, qty, unit_price, line_total)
  SELECT
    v_order_id,
    ci.menu_item_id,
    ci.qty,
    CASE
      WHEN mi.category = 'PIZZA' THEN
        COALESCE((SELECT p.price_with_vat FROM v_pizza_price_dynamic p WHERE p.menu_item_id = mi.menu_item_id), 0.00)
      ELSE COALESCE(mi.base_price, 0.00)
    END AS unit_price,
    ci.qty * CASE
               WHEN mi.category = 'PIZZA' THEN
                 COALESCE((SELECT p.price_with_vat FROM v_pizza_price_dynamic p WHERE p.menu_item_id = mi.menu_item_id), 0.00)
               ELSE COALESCE(mi.base_price, 0.00)
             END AS line_total
  FROM cart_item ci
  JOIN menu_item mi ON mi.menu_item_id = ci.menu_item_id
  WHERE ci.session_id = p_session_id;

  -- Subtotal
  SELECT IFNULL(SUM(line_total),0) INTO v_subtotal
  FROM order_item WHERE order_id = v_order_id;

  -- Loyalty 10% after 10 pizzas in history
  SELECT IFNULL(SUM(oi.qty),0) INTO v_pizza_count_hist
  FROM `order` o
  JOIN order_item oi ON oi.order_id = o.order_id
  JOIN menu_item mi ON mi.menu_item_id = oi.menu_item_id
  WHERE o.customer_id = p_customer_id
    AND mi.category = 'PIZZA'
    AND o.order_id <> v_order_id;

  IF v_pizza_count_hist >= 10 THEN
    SELECT IFNULL(SUM(oi.line_total),0) INTO v_tmp
    FROM order_item oi
    JOIN menu_item mi ON mi.menu_item_id = oi.menu_item_id
    WHERE oi.order_id = v_order_id AND mi.category = 'PIZZA';
    SET v_discount_loy = ROUND(v_tmp * 0.10, 2);
    UPDATE `order` SET loyalty_applied = TRUE WHERE order_id = v_order_id;
  END IF;

  -- Birthday free (cheapest pizza + drink)
  SELECT (DATE_FORMAT(dob,'%m-%d') = DATE_FORMAT(CURDATE(),'%m-%d'))
  INTO v_is_birthday
  FROM customer WHERE customer_id = p_customer_id;

  IF v_is_birthday THEN
    SELECT IFNULL(MIN(oi.unit_price),0) INTO v_tmp
    FROM order_item oi
    JOIN menu_item mi ON mi.menu_item_id = oi.menu_item_id
    WHERE oi.order_id = v_order_id AND mi.category = 'PIZZA';
    SET v_discount_bday = v_discount_bday + v_tmp;

    SELECT IFNULL(MIN(oi.unit_price),0) INTO v_tmp
    FROM order_item oi
    JOIN menu_item mi ON mi.menu_item_id = oi.menu_item_id
    WHERE oi.order_id = v_order_id AND mi.category = 'DRINK';
    SET v_discount_bday = v_discount_bday + v_tmp;

    IF v_discount_bday > 0 THEN
      UPDATE `order` SET birthday_applied = TRUE WHERE order_id = v_order_id;
    END IF;
  END IF;

  -- Discount code (percentage)
  IF p_discount_code IS NOT NULL AND p_discount_code <> '' THEN
    SELECT dc.discount_code_id, dc.percentage, dc.is_single_use, dc.is_used,
           ((dc.valid_from IS NULL OR dc.valid_from <= CURDATE())
            AND (dc.valid_to IS NULL OR dc.valid_to >= CURDATE()))
    INTO v_code_id, v_code_pct, v_code_single, v_code_used, v_code_ok_dates
    FROM discount_code dc
    WHERE dc.code = p_discount_code;

    IF v_code_id IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid discount code';
    END IF;
    IF v_code_single AND v_code_used THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Discount code already used';
    END IF;
    IF NOT v_code_ok_dates THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Discount code expired or not yet valid';
    END IF;

    SET v_tmp = GREATEST(v_subtotal - v_discount_loy - v_discount_bday, 0);
    IF v_code_pct IS NOT NULL AND v_code_pct > 0 THEN
      SET v_discount_code_amt = ROUND(v_tmp * (v_code_pct/100.0), 2);
    END IF;

    UPDATE `order` SET discount_code_id = v_code_id WHERE order_id = v_order_id;
    IF v_code_single THEN
      UPDATE discount_code SET is_used = TRUE WHERE discount_code_id = v_code_id;
    END IF;
  END IF;

  -- Totals
  SET v_grand_total = GREATEST(ROUND(v_subtotal - v_discount_loy - v_discount_bday - v_discount_code_amt, 2), 0.00);

  UPDATE `order`
     SET subtotal       = v_subtotal,
         discount_total = ROUND(v_discount_loy + v_discount_bday + v_discount_code_amt, 2),
         grand_total    = v_grand_total
   WHERE order_id = v_order_id;

  -- Delivery assignment
  SELECT postcode INTO v_postcode FROM customer WHERE customer_id = p_customer_id;

  SELECT dp.delivery_person_id
    INTO v_driver_id
  FROM driver_postcode dp
  LEFT JOIN delivery_person d ON d.delivery_person_id = dp.delivery_person_id
  WHERE dp.postcode = v_postcode
    AND (d.last_delivery_at IS NULL OR d.last_delivery_at <= (v_now - INTERVAL 30 MINUTE))
  ORDER BY (d.last_delivery_at IS NOT NULL), d.last_delivery_at ASC
  LIMIT 1;

  INSERT INTO delivery (order_id, delivery_person_id, status, assigned_at)
  VALUES (v_order_id,
          v_driver_id,
          IF(v_driver_id IS NULL, 'PENDING', 'ASSIGNED'),
          IF(v_driver_id IS NULL, NULL, v_now));

  -- Clear cart
  DELETE FROM cart_item WHERE session_id = p_session_id;

  COMMIT;

  -- Return summary
  SELECT v_order_id AS order_id,
         v_subtotal AS subtotal,
         ROUND(v_discount_loy + v_discount_bday + v_discount_code_amt, 2) AS total_discount,
         v_grand_total AS grand_total;
END $$
DELIMITER ;

-- Creation of set_delivery_status procedure
-- Updates delivery timestamps and driver cooldown
DELIMITER $$
DROP PROCEDURE IF EXISTS set_delivery_status $$
CREATE PROCEDURE set_delivery_status(
  IN p_order_id BIGINT,
  IN p_status   VARCHAR(20)
)
BEGIN
  DECLARE v_driver_id INT;

  IF NOT EXISTS (SELECT 1 FROM delivery WHERE order_id = p_order_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Unknown order_id in delivery';
  END IF;

  UPDATE delivery
     SET status = p_status,
         out_at = CASE WHEN p_status = 'OUT_FOR_DELIVERY' AND out_at IS NULL THEN NOW() ELSE out_at END,
         delivered_at = CASE WHEN p_status = 'DELIVERED' AND delivered_at IS NULL THEN NOW() ELSE delivered_at END,
         cancelled_at = CASE WHEN p_status = 'CANCELLED' AND cancelled_at IS NULL THEN NOW() ELSE cancelled_at END
   WHERE order_id = p_order_id;

  IF p_status = 'DELIVERED' THEN
    SELECT delivery_person_id INTO v_driver_id FROM delivery WHERE order_id = p_order_id;
    IF v_driver_id IS NOT NULL THEN
      UPDATE delivery_person SET last_delivery_at = NOW() WHERE delivery_person_id = v_driver_id;
    END IF;
  END IF;
END $$
DELIMITER ;
