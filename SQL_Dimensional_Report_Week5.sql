-- SQL DIMENSIONAL REPORT — WEEK 5
-- Topics: Star Schema, Window Function Rankings, CTE MoM Report,
--         ROLLUP, EXPLAIN Optimization
-- Compatible with MySQL 8+

DROP DATABASE IF EXISTS sql_dimensional_report;
CREATE DATABASE sql_dimensional_report;
USE sql_dimensional_report;

-- ============================================================
-- 1. STAR SCHEMA
-- ============================================================

CREATE TABLE dim_date (
    date_key INT PRIMARY KEY,
    full_date DATE NOT NULL,
    year INT NOT NULL,
    month INT NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    quarter INT NOT NULL
);

CREATE TABLE dim_customer (
    customer_key INT PRIMARY KEY AUTO_INCREMENT,
    customer_name VARCHAR(100) NOT NULL,
    city VARCHAR(50),
    segment VARCHAR(30)
);

CREATE TABLE dim_product (
    product_key INT PRIMARY KEY AUTO_INCREMENT,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    unit_price DECIMAL(10,2) NOT NULL
);

CREATE TABLE dim_location (
    location_key INT PRIMARY KEY AUTO_INCREMENT,
    city VARCHAR(50) NOT NULL,
    state VARCHAR(50),
    region VARCHAR(30)
);

CREATE TABLE fact_sales (
    sales_key INT PRIMARY KEY AUTO_INCREMENT,
    date_key INT NOT NULL,
    customer_key INT NOT NULL,
    product_key INT NOT NULL,
    location_key INT NOT NULL,
    quantity INT NOT NULL,
    sales_amount DECIMAL(12,2) NOT NULL,
    FOREIGN KEY (date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (customer_key) REFERENCES dim_customer(customer_key),
    FOREIGN KEY (product_key) REFERENCES dim_product(product_key),
    FOREIGN KEY (location_key) REFERENCES dim_location(location_key),
    INDEX idx_sales_date (date_key),
    INDEX idx_sales_product (product_key),
    INDEX idx_sales_customer (customer_key)
);

-- ============================================================
-- 2. SAMPLE DIMENSION DATA
-- ============================================================

INSERT INTO dim_date VALUES
(20260105,'2026-01-05',2026,1,'January',1),
(20260115,'2026-01-15',2026,1,'January',1),
(20260205,'2026-02-05',2026,2,'February',1),
(20260215,'2026-02-15',2026,2,'February',1),
(20260305,'2026-03-05',2026,3,'March',1),
(20260315,'2026-03-15',2026,3,'March',1),
(20260405,'2026-04-05',2026,4,'April',2),
(20260415,'2026-04-15',2026,4,'April',2);

INSERT INTO dim_customer (customer_name,city,segment) VALUES
('Aarav Sharma','Bengaluru','Premium'),
('Diya Nair','Chennai','Regular'),
('Rohan Mehta','Mumbai','Premium'),
('Ananya Rao','Hyderabad','Regular'),
('Kabir Singh','Delhi','Corporate');

INSERT INTO dim_product (product_name,category,unit_price) VALUES
('Laptop Pro','Electronics',75000.00),
('Smartphone X','Electronics',45000.00),
('Office Chair','Furniture',12000.00),
('Wireless Headset','Accessories',5000.00),
('Mechanical Keyboard','Accessories',7000.00);

INSERT INTO dim_location (city,state,region) VALUES
('Bengaluru','Karnataka','South'),
('Chennai','Tamil Nadu','South'),
('Mumbai','Maharashtra','West'),
('Hyderabad','Telangana','South'),
('Delhi','Delhi','North');

-- ============================================================
-- 3. FACT DATA
-- ============================================================

INSERT INTO fact_sales
(date_key,customer_key,product_key,location_key,quantity,sales_amount)
VALUES
(20260105,1,1,1,2,150000),
(20260115,2,2,2,3,135000),
(20260115,3,3,3,4,48000),
(20260205,1,2,1,2,90000),
(20260215,4,4,4,6,30000),
(20260215,5,1,5,1,75000),
(20260305,2,3,2,5,60000),
(20260315,3,2,3,3,135000),
(20260315,1,5,1,5,35000),
(20260405,5,1,5,2,150000),
(20260415,4,4,4,8,40000),
(20260415,2,2,2,4,180000),
(20260415,3,3,3,3,36000);

-- ============================================================
-- 4. BASIC STAR-SCHEMA REPORT
-- ============================================================

SELECT
    d.year,
    d.month_name,
    p.category,
    SUM(f.quantity) AS units_sold,
    SUM(f.sales_amount) AS total_sales
FROM fact_sales f
JOIN dim_date d ON f.date_key = d.date_key
JOIN dim_product p ON f.product_key = p.product_key
GROUP BY d.year, d.month, d.month_name, p.category
ORDER BY d.year, d.month, total_sales DESC;

-- ============================================================
-- 5. WINDOW FUNCTION RANKINGS
-- Rank products by sales within each category
-- ============================================================

WITH product_sales AS (
    SELECT
        p.category,
        p.product_name,
        SUM(f.sales_amount) AS total_sales
    FROM fact_sales f
    JOIN dim_product p ON f.product_key = p.product_key
    GROUP BY p.category, p.product_key, p.product_name
)
SELECT
    category,
    product_name,
    total_sales,
    RANK() OVER (
        PARTITION BY category
        ORDER BY total_sales DESC
    ) AS sales_rank
FROM product_sales
ORDER BY category, sales_rank;

-- Rank customers by total spending
SELECT
    c.customer_name,
    c.segment,
    SUM(f.sales_amount) AS total_spending,
    DENSE_RANK() OVER (
        ORDER BY SUM(f.sales_amount) DESC
    ) AS customer_rank
FROM fact_sales f
JOIN dim_customer c ON f.customer_key = c.customer_key
GROUP BY c.customer_key, c.customer_name, c.segment
ORDER BY customer_rank;

-- ============================================================
-- 6. CTE MONTH-OVER-MONTH (MoM) REPORT
-- ============================================================

WITH monthly_sales AS (
    SELECT
        d.year,
        d.month,
        d.month_name,
        SUM(f.sales_amount) AS total_sales
    FROM fact_sales f
    JOIN dim_date d ON f.date_key = d.date_key
    GROUP BY d.year, d.month, d.month_name
),
mom_report AS (
    SELECT
        year,
        month,
        month_name,
        total_sales,
        LAG(total_sales) OVER (ORDER BY year, month) AS previous_month_sales
    FROM monthly_sales
)
SELECT
    year,
    month_name,
    total_sales,
    previous_month_sales,
    CASE
        WHEN previous_month_sales IS NULL THEN NULL
        ELSE total_sales - previous_month_sales
    END AS sales_change,
    CASE
        WHEN previous_month_sales IS NULL OR previous_month_sales = 0 THEN NULL
        ELSE ROUND(
            ((total_sales - previous_month_sales) / previous_month_sales) * 100,
            2
        )
    END AS mom_growth_percent
FROM mom_report
ORDER BY year, month;

-- ============================================================
-- 7. ROLLUP
-- Subtotals by region and grand total
-- ============================================================

SELECT
    l.region,
    p.category,
    SUM(f.sales_amount) AS total_sales
FROM fact_sales f
JOIN dim_location l ON f.location_key = l.location_key
JOIN dim_product p ON f.product_key = p.product_key
GROUP BY l.region, p.category WITH ROLLUP;

-- Monthly totals + grand total
SELECT
    d.year,
    d.month_name,
    SUM(f.sales_amount) AS total_sales
FROM fact_sales f
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY d.year, d.month, d.month_name WITH ROLLUP;

-- ============================================================
-- 8. EXPLAIN — QUERY OPTIMIZATION
-- ============================================================

-- Before/after style check using EXPLAIN.
-- The fact table already contains useful indexes on common join/filter keys.

EXPLAIN
SELECT
    p.category,
    SUM(f.sales_amount) AS total_sales
FROM fact_sales f
JOIN dim_product p ON f.product_key = p.product_key
WHERE f.date_key >= 20260201
GROUP BY p.category;

-- Index used for a date-based query
EXPLAIN
SELECT *
FROM fact_sales
WHERE date_key = 20260415;

-- ============================================================
-- 9. OPTIONAL OPTIMIZATION INDEX
-- If EXPLAIN shows a full table scan for a common date/product
-- filter, create a composite index:
-- ============================================================

CREATE INDEX idx_sales_date_product
ON fact_sales(date_key, product_key);

EXPLAIN
SELECT
    product_key,
    SUM(sales_amount) AS total_sales
FROM fact_sales
WHERE date_key >= 20260201
GROUP BY product_key;

-- ============================================================
-- END OF PROJECT
-- ============================================================
