/*

Analysis for a Pizza shop

*/

-- We will start by create Database, tables and inserting columns:

CREATE DATABASE pizza_shop;

CREATE TABLE orders (
    row_id INT NOT NULL,
    order_id VARCHAR(10) NOT NULL,
    created_at DATETIME NOT NULL,
    item_id VARCHAR(10) NOT NULL,
    quantity INT NOT NULL,
    cust_id INT NOT NULL,
    delivery BOOLEAN NOT NULL,
    add_id INT NOT NULL,
    PRIMARY KEY (row_id)
);

CREATE TABLE customers (
    cust_id INT NOT NULL,
    cust_firstname VARCHAR(50) NOT NULL,
    cust_lastname VARCHAR(50) NOT NULL,
    PRIMARY KEY (cust_id)
);

CREATE TABLE address (
    add_id INT NOT NULL,
    delivery_address1 VARCHAR(200) NOT NULL,
    delivery_address2 VARCHAR(200) NULL,
    delivery_city VARCHAR(50) NOT NULL,
    delivery_zipcode VARCHAR(20) NOT NULL,
    PRIMARY KEY (add_id)
);

CREATE TABLE item (
    item_id VARCHAR(10) NOT NULL,
    sku VARCHAR(20) NOT NULL,
    item_name VARCHAR(100) NOT NULL,
    item_cat VARCHAR(100) NOT NULL,
    item_size VARCHAR(10) NOT NULL,
    item_price DECIMAL(10 , 2 ) NOT NULL,
    PRIMARY KEY (item_id)
);

CREATE TABLE ingredient (
    ing_id VARCHAR(10) NOT NULL,
    ing_name VARCHAR(200) NOT NULL,
    ing_weight INT NOT NULL,
    ing_meas VARCHAR(20) NOT NULL,
    ing_price DECIMAL(5 , 2 ) NOT NULL,
    PRIMARY KEY (ing_id)
);

CREATE TABLE recipe (
    row_id INT NOT NULL,
    recipe_id VARCHAR(20) NOT NULL,
    ing_id VARCHAR(10) NOT NULL,
    quantity INT NOT NULL,
    PRIMARY KEY (row_id)
);

CREATE TABLE inventory (
    inv_id INT NOT NULL,
    item_id VARCHAR(10) NOT NULL,
    quantity INT NOT NULL,
    PRIMARY KEY (inv_id)
);

CREATE TABLE staff (
    staff_id VARCHAR(20) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    position VARCHAR(100) NOT NULL,
    hourly_rate DECIMAL(5 , 2 ) NOT NULL,
    PRIMARY KEY (staff_id)
);

CREATE TABLE shift (
    shift_id VARCHAR(20) NOT NULL,
    day_of_week VARCHAR(10) NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    PRIMARY KEY (shift_id)
);

CREATE TABLE rota (
    row_id INT NOT NULL,
    rota_id VARCHAR(20) NOT NULL,
    date DATETIME NOT NULL,
    shift_id VARCHAR(20) NOT NULL,
    staff_id VARCHAR(20) NOT NULL,
    PRIMARY KEY (row_id)
);
-- After creating tables, the records for each table were imported from csv file


-- Schema diagram was prepared and completed on QuickDBD (link: https://app.quickdatabasediagrams.com/#/d/M6btdm)


-- We will be writing custom queries to create 3 Dashboards in the future (1 for Orders, 2 for Stock and 3 for staff)


USE pizza_shop;


-- Dashboard 1 (Orders):
-- We will need Total orders, total sales, total items, avg order value, sales by category, top selling items
-- Orders by hour, sales by hour, orders by address, orders by delivery/pickup (all shown in query below)


SELECT
	o.order_id,
	i.item_price,
	o.quantity,
	i.item_cat,
	i.item_name,
	o.created_at,
	a.delivery_address1,
	a.delivery_address2,
	a.delivery_city,
	a.delivery_zipcode,
	o.delivery 
FROM
	orders o
	LEFT JOIN item i ON o.item_id = i.item_id
	LEFT JOIN address a ON o.add_id = a.add_id
 

-- Dashboard 2 (Inventory management):
-- We would be calculating how much inventory to be used and identify those that require reordering
-- also calculating cost to make Pizza based on ingredients cost to assess pricing & Profit/Loss
-- We would need Total quantity by ingredient, Total cost of ingredients, Calculated cost of pizza and % stock remaining by ingredient

CREATE VIEW stock_1 AS
    SELECT 
        s1.item_name,
        s1.ing_id,
        s1.ing_name,
        s1.ing_weight,
        s1.ing_price,
        s1.order_quantity,
        s1.recipe_quantity,
        s1.order_quantity * s1.recipe_quantity AS ordered_weight,
        s1.ing_price / s1.ing_weight AS unit_cost,
        (s1.order_quantity * s1.recipe_quantity) * (s1.ing_price / s1.ing_weight) AS ingredient_cost
    FROM
        (SELECT 
            o.item_id,
                i.sku,
                i.item_name,
                r.ing_id,
                ing.ing_name,
                r.quantity AS recipe_quantity,
                SUM(o.quantity) AS order_quantity,
                ing.ing_weight,
                ing.ing_price
        FROM
            orders o
        LEFT JOIN item i ON o.item_id = i.item_id
        LEFT JOIN recipe r ON i.sku = r.recipe_id
        LEFT JOIN ingredient ing ON ing.ing_id = r.ing_id
        GROUP BY o.item_id , i.sku , i.item_name , r.ing_id , r.quantity , ing.ing_name , ing.ing_weight , ing.ing_price) s1;
	
-- a subquery is used in this case to be able to achieve columns for ordered_weight, unit_cost and ingredient_cost
-- a view is created for the above query to avoid writing the same complex statement in below query    


SELECT 
    s2.ing_name,
    s2.ordered_weight,
    ing.ing_weight * inv.quantity AS total_inv_weight,
    (ing.ing_weight * inv.quantity) - s2.ordered_weight AS remaining_weight
FROM
    (SELECT 
        ing_id, ing_name, SUM(ordered_weight) AS ordered_weight
    FROM
        stock_1
    GROUP BY ing_name , ing_id) s2
        LEFT JOIN
    inventory inv ON inv.item_id = s2.ing_id
        LEFT JOIN
    ingredient ing ON ing.ing_id = s2.ing_id;
    


-- Dashboard 3 (Staff):
-- We would be calculating the staff cost by shifts


SELECT 
    r.date,
    s.first_name,
    s.last_name,
    s.hourly_rate,
    sh.start_time,
    sh.end_time,
    ((HOUR(TIMEDIFF(sh.end_time, sh.start_time)) * 60) + (MINUTE(TIMEDIFF(sh.end_time, sh.start_time)))) / 60 AS hours_in_shift,
    ((HOUR(TIMEDIFF(sh.end_time, sh.start_time)) * 60) + (MINUTE(TIMEDIFF(sh.end_time, sh.start_time)))) / 60 * s.hourly_rate AS staff_cost
FROM
    rota r
        LEFT JOIN
    staff s ON r.staff_id = s.staff_id
        LEFT JOIN
    shift sh ON r.shift_id = sh.shift_id;
-- To get hours_in_shift column, we convert hours to minutes by multiplying hours by 60 and then dividing the sum of minutes by 60
-- Note that hours_in_shift column is in decimal
-- multiplying hourly_rate by hours_in_shift, we get staff_cost 