-- 04_views.sql
-- Views only: pricing, labels, and menu with final price

USE pizza_ordering;

-- Creation of pizza base cost view
CREATE OR REPLACE VIEW v_pizza_cost_base AS
SELECT
  mi.menu_item_id,
  mi.name,
  SUM(mii.qty * i.cost) AS cost_base
FROM menu_item mi
JOIN menu_item_ingredient mii ON mii.menu_item_id = mi.menu_item_id
JOIN ingredient i ON i.ingredient_id = mii.ingredient_id
WHERE mi.category = 'PIZZA'
GROUP BY mi.menu_item_id, mi.name;

-- Creation of pizza dynamic price view
-- Formula: price = cost * 1.40 margin, then * 1.09 VAT; round to 2 decimals
CREATE OR REPLACE VIEW v_pizza_price_dynamic AS
SELECT
  c.menu_item_id,
  c.name,
  ROUND(c.cost_base * 1.40, 2) AS price_no_vat,
  ROUND(c.cost_base * 1.40 * 1.09, 2) AS price_with_vat
FROM v_pizza_cost_base c;

-- Creation of pizza labels view
CREATE OR REPLACE VIEW v_pizza_labels AS
SELECT
  mi.menu_item_id,
  mi.name,
  mi.is_vegetarian,
  mi.is_vegan,
  CASE
    WHEN mi.is_vegan THEN 'VEGAN'
    WHEN mi.is_vegetarian THEN 'VEGETARIAN'
    ELSE 'MEAT'
  END AS label
FROM menu_item mi
WHERE mi.category = 'PIZZA';

-- Creation of menu view with final price
-- PIZZA uses dynamic price; DRINK/DESSERT use base_price
CREATE OR REPLACE VIEW v_menu_with_price AS
SELECT
  mi.menu_item_id,
  mi.name,
  mi.category,
  p.price_with_vat AS price
FROM menu_item mi
JOIN v_pizza_price_dynamic p ON p.menu_item_id = mi.menu_item_id
WHERE mi.category = 'PIZZA'

UNION ALL

SELECT
  mi.menu_item_id,
  mi.name,
  mi.category,
  mi.base_price AS price
FROM menu_item mi
WHERE mi.category IN ('DRINK','DESSERT');
