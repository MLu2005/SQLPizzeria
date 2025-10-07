-- 05_reports.sql
-- Reporting queries. Run them directly in Workbench.

USE pizza_ordering;

-- Creation of helper view for order lines
CREATE OR REPLACE VIEW v_order_items_ex AS
SELECT
  o.order_id,
  o.order_ts,
  o.customer_id,
  oi.order_item_id,
  oi.menu_item_id,
  mi.name        AS item_name,
  mi.category    AS item_category,
  oi.qty,
  oi.unit_price,
  oi.line_total
FROM `order` o
JOIN order_item oi ON oi.order_id = o.order_id
JOIN menu_item mi  ON mi.menu_item_id = oi.menu_item_id;

-- Undelivered orders. Good for daily operations.
SELECT
  o.order_id,
  o.order_ts,
  c.first_name, c.last_name, c.postcode,
  IFNULL(d.status,'NO_DELIVERY') AS status,
  d.assigned_at, d.out_at, d.delivered_at, d.cancelled_at
FROM `order` o
LEFT JOIN delivery d ON d.order_id = o.order_id
LEFT JOIN customer c ON c.customer_id = o.customer_id
WHERE (d.order_id IS NULL) OR (d.status <> 'DELIVERED' AND d.cancelled_at IS NULL)
ORDER BY o.order_id DESC;

-- Long trips. Out for delivery > 60 minutes.
SELECT
  d.order_id, d.out_at,
  TIMESTAMPDIFF(MINUTE, d.out_at, NOW()) AS minutes_out
FROM delivery d
WHERE d.status = 'OUT_FOR_DELIVERY'
  AND d.out_at IS NOT NULL
  AND TIMESTAMPDIFF(MINUTE, d.out_at, NOW()) > 60
ORDER BY minutes_out DESC;

-- Top 3 pizzas by quantity in the last 30 days.
SELECT
  ioe.item_name AS pizza,
  SUM(ioe.qty)  AS qty_30d
FROM v_order_items_ex ioe
WHERE ioe.item_category = 'PIZZA'
  AND ioe.order_ts >= (CURDATE() - INTERVAL 30 DAY)
GROUP BY ioe.item_name
ORDER BY qty_30d DESC
LIMIT 3;

-- Top 3 pizzas by revenue in the last 30 days.
SELECT
  ioe.item_name AS pizza,
  ROUND(SUM(ioe.line_total),2) AS revenue_30d
FROM v_order_items_ex ioe
WHERE ioe.item_category = 'PIZZA'
  AND ioe.order_ts >= (CURDATE() - INTERVAL 30 DAY)
GROUP BY ioe.item_name
ORDER BY revenue_30d DESC
LIMIT 3;

-- Revenue by gender.
SELECT
  c.gender,
  COUNT(DISTINCT o.order_id)         AS orders_cnt,
  ROUND(SUM(o.grand_total), 2)       AS revenue
FROM `order` o
JOIN customer c ON c.customer_id = o.customer_id
GROUP BY c.gender
ORDER BY revenue DESC;

-- Revenue by age bands.
SELECT
  CASE
    WHEN age < 18 THEN '0-17'
    WHEN age BETWEEN 18 AND 24 THEN '18-24'
    WHEN age BETWEEN 25 AND 34 THEN '25-34'
    WHEN age BETWEEN 35 AND 44 THEN '35-44'
    WHEN age BETWEEN 45 AND 54 THEN '45-54'
    ELSE '55+'
  END AS age_band,
  COUNT(DISTINCT o.order_id)   AS orders_cnt,
  ROUND(SUM(o.grand_total),2)  AS revenue
FROM (
  SELECT customer_id, TIMESTAMPDIFF(YEAR, dob, CURDATE()) AS age
  FROM customer
) ages
JOIN `order` o ON o.customer_id = ages.customer_id
GROUP BY age_band
ORDER BY revenue DESC;

-- Revenue by postcode.
SELECT
  c.postcode,
  COUNT(DISTINCT o.order_id)  AS orders_cnt,
  ROUND(SUM(o.grand_total),2) AS revenue
FROM `order` o
JOIN customer c ON c.customer_id = o.customer_id
GROUP BY c.postcode
ORDER BY revenue DESC, c.postcode;

-- Driver performance (30 days). Average minutes and count.
SELECT
  dp.delivery_person_id,
  CONCAT(dp.first_name, ' ', dp.last_name) AS driver,
  COUNT(*) AS delivered_cnt,
  ROUND(AVG(TIMESTAMPDIFF(MINUTE, d.out_at, d.delivered_at)), 1) AS avg_minutes
FROM delivery d
JOIN delivery_person dp ON dp.delivery_person_id = d.delivery_person_id
WHERE d.status = 'DELIVERED'
  AND d.delivered_at IS NOT NULL
  AND d.out_at IS NOT NULL
  AND d.delivered_at >= (CURDATE() - INTERVAL 30 DAY)
GROUP BY dp.delivery_person_id, driver
ORDER BY avg_minutes ASC;

-- Delivered by postcode. Quick heat map baseline.
SELECT
  c.postcode,
  COUNT(*) AS delivered_cnt
FROM delivery d
JOIN `order` o ON o.order_id = d.order_id
JOIN customer c ON c.customer_id = o.customer_id
WHERE d.status = 'DELIVERED'
GROUP BY c.postcode
ORDER BY delivered_cnt DESC;

-- Orders per day (last 30 days).
SELECT
  DATE(o.order_ts) AS day,
  COUNT(*)         AS orders_cnt,
  ROUND(SUM(o.grand_total),2) AS revenue
FROM `order` o
WHERE o.order_ts >= (CURDATE() - INTERVAL 30 DAY)
GROUP BY DATE(o.order_ts)
ORDER BY day;

-- Customer lifetime. Orders, pizzas total, spend.
SELECT
  c.customer_id,
  CONCAT(c.first_name,' ',c.last_name) AS customer,
  COUNT(DISTINCT o.order_id)           AS orders_cnt,
  SUM(CASE WHEN mi.category='PIZZA' THEN oi.qty ELSE 0 END) AS pizzas_total,
  ROUND(SUM(o.grand_total),2)         AS lifetime_value
FROM customer c
LEFT JOIN `order` o     ON o.customer_id = c.customer_id
LEFT JOIN order_item oi ON oi.order_id = o.order_id
LEFT JOIN menu_item mi  ON mi.menu_item_id = oi.menu_item_id
GROUP BY c.customer_id, customer
ORDER BY lifetime_value DESC;

-- Drinks most often paired with pizza (last 30 days).
WITH orders_with_pizza AS (
  SELECT DISTINCT o.order_id
  FROM v_order_items_ex o
  WHERE o.item_category='PIZZA'
    AND o.order_ts >= (CURDATE() - INTERVAL 30 DAY)
)
SELECT
  mi.name AS drink,
  SUM(oi.qty) AS qty_with_pizza_30d
FROM orders_with_pizza p
JOIN order_item oi ON oi.order_id = p.order_id
JOIN menu_item mi  ON mi.menu_item_id = oi.menu_item_id
WHERE mi.category='DRINK'
GROUP BY mi.name
ORDER BY qty_with_pizza_30d DESC;
