-- 02_sample_data.sql
-- Insert sample data into all tables: ingredients, menu, links, customers, drivers, discount codes, orders

USE pizza_ordering;

-- Creation of ingredient table data
INSERT INTO ingredient (name, is_meat, is_dairy, is_vegan, cost) VALUES
                                                                     ('Tomato sauce', FALSE, FALSE, TRUE, 0.40),
                                                                     ('Garlic',       FALSE, FALSE, TRUE, 0.10),
                                                                     ('Basil',        FALSE, FALSE, TRUE, 0.12),
                                                                     ('Oregano',      FALSE, FALSE, TRUE, 0.08),
                                                                     ('Mushroom',     FALSE, FALSE, TRUE, 0.50),
                                                                     ('Onion',        FALSE, FALSE, TRUE, 0.20),
                                                                     ('Olives',       FALSE, FALSE, TRUE, 0.45),
                                                                     ('Bell pepper',  FALSE, FALSE, TRUE, 0.35),
                                                                     ('Corn',         FALSE, FALSE, TRUE, 0.25),
                                                                     ('Pineapple',    FALSE, FALSE, TRUE, 0.60),
                                                                     ('Mozzarella',   FALSE, TRUE,  FALSE, 0.90),
                                                                     ('Gorgonzola',   FALSE, TRUE,  FALSE, 1.10),
                                                                     ('Parmesan',     FALSE, TRUE,  FALSE, 0.95),
                                                                     ('Ricotta',      FALSE, TRUE,  FALSE, 0.85),
                                                                     ('Pepperoni',    TRUE,  FALSE, FALSE, 1.20),
                                                                     ('Ham',          TRUE,  FALSE, FALSE, 1.00),
                                                                     ('Prosciutto',   TRUE,  FALSE, FALSE, 1.30),
                                                                     ('Sausage',      TRUE,  FALSE, FALSE, 1.10),
                                                                     ('Tuna',         TRUE,  FALSE, FALSE, 1.15),
                                                                     ('Chili',        FALSE, FALSE, TRUE, 0.10),
                                                                     ('Arugula',      FALSE, FALSE, TRUE, 0.30),
                                                                     ('Capers',       FALSE, FALSE, TRUE, 0.35);

-- Creation of menu_item table data
INSERT INTO menu_item (name, category, base_price, is_vegetarian, is_vegan) VALUES
                                                                                ('Margherita', 'PIZZA', NULL, TRUE, FALSE),
                                                                                ('Cola 0.5l', 'DRINK', 5.00, FALSE, FALSE),
                                                                                ('Marinara', 'PIZZA', NULL, TRUE, TRUE),
                                                                                ('Funghi', 'PIZZA', NULL, TRUE, FALSE),
                                                                                ('Quattro Formaggi', 'PIZZA', NULL, TRUE, FALSE),
                                                                                ('Veggie', 'PIZZA', NULL, TRUE, TRUE),
                                                                                ('Diavola', 'PIZZA', NULL, FALSE, FALSE),
                                                                                ('Pepperoni', 'PIZZA', NULL, FALSE, FALSE),
                                                                                ('Capricciosa', 'PIZZA', NULL, FALSE, FALSE),
                                                                                ('Prosciutto', 'PIZZA', NULL, FALSE, FALSE),
                                                                                ('Hawaiian', 'PIZZA', NULL, FALSE, FALSE),
                                                                                ('Water 0.5l', 'DRINK', 5.00, FALSE, TRUE),
                                                                                ('Orange Juice', 'DRINK', 7.50, FALSE, TRUE),
                                                                                ('Tiramisu', 'DESSERT', 12.00, FALSE, FALSE),
                                                                                ('Panna Cotta', 'DESSERT', 11.00, FALSE, FALSE);

-- Creation of menu_item_ingredient links
-- Map each pizza to its ingredients
INSERT INTO menu_item_ingredient (menu_item_id, ingredient_id, qty)
SELECT mi.menu_item_id, i.ingredient_id, 1
FROM menu_item mi JOIN ingredient i
WHERE mi.name='Margherita' AND i.name IN ('Tomato sauce','Mozzarella','Basil');

INSERT INTO menu_item_ingredient (menu_item_id, ingredient_id, qty)
SELECT mi.menu_item_id, i.ingredient_id, 1
FROM menu_item mi JOIN ingredient i
WHERE mi.name='Marinara' AND i.name IN ('Tomato sauce','Garlic','Oregano');

INSERT INTO menu_item_ingredient (menu_item_id, ingredient_id, qty)
SELECT mi.menu_item_id, i.ingredient_id, 1
FROM menu_item mi JOIN ingredient i
WHERE mi.name='Funghi' AND i.name IN ('Tomato sauce','Mozzarella','Mushroom');

INSERT INTO menu_item_ingredient (menu_item_id, ingredient_id, qty)
SELECT mi.menu_item_id, i.ingredient_id, 1
FROM menu_item mi JOIN ingredient i
WHERE mi.name='Quattro Formaggi' AND i.name IN ('Mozzarella','Gorgonzola','Parmesan','Ricotta');

INSERT INTO menu_item_ingredient (menu_item_id, ingredient_id, qty)
SELECT mi.menu_item_id, i.ingredient_id, 1
FROM menu_item mi JOIN ingredient i
WHERE mi.name='Veggie' AND i.name IN ('Tomato sauce','Mozzarella','Bell pepper','Onion','Olives','Corn');

INSERT INTO menu_item_ingredient (menu_item_id, ingredient_id, qty)
SELECT mi.menu_item_id, i.ingredient_id, 1
FROM menu_item mi JOIN ingredient i
WHERE mi.name='Diavola' AND i.name IN ('Tomato sauce','Mozzarella','Pepperoni','Chili');

INSERT INTO menu_item_ingredient (menu_item_id, ingredient_id, qty)
SELECT mi.menu_item_id, i.ingredient_id, 1
FROM menu_item mi JOIN ingredient i
WHERE mi.name='Pepperoni' AND i.name IN ('Tomato sauce','Mozzarella','Pepperoni');

INSERT INTO menu_item_ingredient (menu_item_id, ingredient_id, qty)
SELECT mi.menu_item_id, i.ingredient_id, 1
FROM menu_item mi JOIN ingredient i
WHERE mi.name='Capricciosa' AND i.name IN ('Tomato sauce','Mozzarella','Ham','Mushroom','Olives');

INSERT INTO menu_item_ingredient (menu_item_id, ingredient_id, qty)
SELECT mi.menu_item_id, i.ingredient_id, 1
FROM menu_item mi JOIN ingredient i
WHERE mi.name='Prosciutto' AND i.name IN ('Tomato sauce','Mozzarella','Prosciutto');

INSERT INTO menu_item_ingredient (menu_item_id, ingredient_id, qty)
SELECT mi.menu_item_id, i.ingredient_id, 1
FROM menu_item mi JOIN ingredient i
WHERE mi.name='Hawaiian' AND i.name IN ('Tomato sauce','Mozzarella','Ham','Pineapple');

-- Creation of customer table data
INSERT INTO customer (first_name,last_name,email,phone,street,city,postcode,gender,dob) VALUES
                                                                                            ('Anna','Kowalska','anna@example.com','+48111111','ul. Kwiatowa 1','Kraków','30-001','F','1995-05-20'),
                                                                                            ('Jan','Nowak','jan@example.com','+48222222','ul. Leśna 2','Kraków','30-002','M','1990-10-02'),
                                                                                            ('Ewa','Sikora','ewa@example.com','+48333333','ul. Polna 3','Kraków','30-003','F','1988-03-15'),
                                                                                            ('Piotr','Zieliński','piotr@example.com','+48444444','ul. Długa 4','Kraków','30-004','M','1985-01-01'),
                                                                                            ('Ola','Wiśniewska','ola@example.com','+48555555','ul. Słoneczna 5','Kraków','30-005','F','2000-07-07'),
                                                                                            ('Marek','Krawczyk','marek@example.com','+48666666','ul. Lipowa 6','Kraków','30-001','M','1992-09-09'),
                                                                                            ('Iza','Lewandowska','iza@example.com','+48777777','ul. Cisowa 7','Kraków','30-002','F','1998-12-12'),
                                                                                            ('Bartek','Mazur','bartek@example.com','+48888888','ul. Tatrzańska 8','Kraków','30-003','M','1993-06-30'),
                                                                                            ('Karolina','Wójcik','karolina@example.com','+48999999','ul. Krótka 9','Kraków','30-004','F','1989-11-11'),
                                                                                            ('Tomek','Bąk','tomek@example.com','+48101010','ul. Nowa 10','Kraków','30-005','M','1997-04-22');

-- Creation of delivery_person table data
INSERT INTO delivery_person (first_name,last_name,phone) VALUES
                                                             ('Kamil','Driver','+48555123456'),
                                                             ('Ola','Kurier','+48555987654'),
                                                             ('Paweł','Go','+48555777000'),
                                                             ('Nadia','Rush','+48555888000'),
                                                             ('Kuba','Sprint','+48555999000');

-- Creation of driver_postcode data
INSERT INTO driver_postcode (delivery_person_id, postcode) VALUES
                                                               (1,'30-001'), (1,'30-002'),
                                                               (2,'30-003'), (2,'30-004'),
                                                               (3,'30-005'),
                                                               (4,'30-001'), (4,'30-003'),
                                                               (5,'30-002'), (5,'30-004'), (5,'30-005');

-- Creation of discount_code table data
INSERT INTO discount_code (code, description, percentage, is_single_use, is_used, valid_from, valid_to) VALUES
                                                                                                            ('WELCOME10','Welcome 10% off',10.00, TRUE, FALSE, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 30 DAY)),
                                                                                                            ('SAVE5','Save 5%',5.00, FALSE, FALSE, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 365 DAY));

-- Creation of example orders (≥20 rows)
-- Simplified static inserts for demonstration
INSERT INTO `order` (customer_id, order_ts, subtotal, discount_total, grand_total, birthday_applied, loyalty_applied)
VALUES
    (1, NOW() - INTERVAL 20 DAY, 20.00, 0.00, 20.00, FALSE, FALSE),
    (2, NOW() - INTERVAL 18 DAY, 30.00, 0.00, 30.00, FALSE, FALSE),
    (3, NOW() - INTERVAL 17 DAY, 25.00, 5.00, 20.00, FALSE, TRUE),
    (4, NOW() - INTERVAL 15 DAY, 15.00, 0.00, 15.00, FALSE, FALSE),
    (5, NOW() - INTERVAL 14 DAY, 35.00, 0.00, 35.00, FALSE, FALSE),
    (6, NOW() - INTERVAL 13 DAY, 40.00, 5.00, 35.00, TRUE, FALSE),
    (7, NOW() - INTERVAL 12 DAY, 22.00, 0.00, 22.00, FALSE, FALSE),
    (8, NOW() - INTERVAL 11 DAY, 18.00, 0.00, 18.00, FALSE, FALSE),
    (9, NOW() - INTERVAL 10 DAY, 27.00, 0.00, 27.00, FALSE, FALSE),
    (10, NOW() - INTERVAL 9 DAY, 30.00, 0.00, 30.00, FALSE, FALSE),
    (1, NOW() - INTERVAL 8 DAY, 22.00, 0.00, 22.00, FALSE, FALSE),
    (2, NOW() - INTERVAL 7 DAY, 28.00, 0.00, 28.00, FALSE, FALSE),
    (3, NOW() - INTERVAL 6 DAY, 26.00, 0.00, 26.00, FALSE, FALSE),
    (4, NOW() - INTERVAL 5 DAY, 19.00, 0.00, 19.00, FALSE, FALSE),
    (5, NOW() - INTERVAL 4 DAY, 21.00, 0.00, 21.00, FALSE, FALSE),
    (6, NOW() - INTERVAL 3 DAY, 24.00, 0.00, 24.00, FALSE, FALSE),
    (7, NOW() - INTERVAL 2 DAY, 31.00, 0.00, 31.00, FALSE, FALSE),
    (8, NOW() - INTERVAL 1 DAY, 16.00, 0.00, 16.00, FALSE, FALSE),
    (9, NOW(), 29.00, 0.00, 29.00, FALSE, FALSE),
    (10, NOW(), 33.00, 3.00, 30.00, FALSE, TRUE);

-- Example order_item lines
-- Only a few lines per order for demo, adjust as needed
INSERT INTO order_item (order_id, menu_item_id, qty, unit_price, line_total)
VALUES
    (1, 1, 1, 20.00, 20.00),
    (2, 8, 2, 15.00, 30.00),
    (3, 4, 1, 25.00, 25.00),
    (4, 3, 1, 15.00, 15.00),
    (5, 9, 1, 35.00, 35.00),
    (6, 7, 2, 20.00, 40.00),
    (7, 5, 1, 22.00, 22.00),
    (8, 6, 1, 18.00, 18.00),
    (9, 10,1, 27.00, 27.00),
    (10,1, 1, 30.00, 30.00);

-- Example delivery records
INSERT INTO delivery (order_id, delivery_person_id, status, assigned_at, out_at, delivered_at)
VALUES
    (1,1,'DELIVERED',NOW()-INTERVAL 20 DAY,NOW()-INTERVAL 20 DAY+INTERVAL 1 HOUR,NOW()-INTERVAL 20 DAY+INTERVAL 1 HOUR),
    (2,2,'DELIVERED',NOW()-INTERVAL 18 DAY,NOW()-INTERVAL 18 DAY+INTERVAL 1 HOUR,NOW()-INTERVAL 18 DAY+INTERVAL 1 HOUR),
    (3,3,'DELIVERED',NOW()-INTERVAL 17 DAY,NOW()-INTERVAL 17 DAY+INTERVAL 1 HOUR,NOW()-INTERVAL 17 DAY+INTERVAL 1 HOUR),
    (4,4,'DELIVERED',NOW()-INTERVAL 15 DAY,NOW()-INTERVAL 15 DAY+INTERVAL 1 HOUR,NOW()-INTERVAL 15 DAY+INTERVAL 1 HOUR),
    (5,5,'DELIVERED',NOW()-INTERVAL 14 DAY,NOW()-INTERVAL 14 DAY+INTERVAL 1 HOUR,NOW()-INTERVAL 14 DAY+INTERVAL 1 HOUR);
