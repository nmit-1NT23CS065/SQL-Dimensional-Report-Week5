# SQL Dimensional Report — Week 5

## 📌 Project Overview

This project demonstrates SQL-based dimensional analysis using a **Star Schema** for sales data.

The project covers important SQL concepts including:

- Star Schema
- Window Function Rankings
- CTE (Common Table Expression)
- Month-over-Month (MoM) Analysis
- ROLLUP
- EXPLAIN and Query Optimization
- SQL Indexing

The project is implemented using **MySQL 8+**.

---

## 🎯 Objectives

The main objectives of this project are:

1. Design a dimensional database using a Star Schema.
2. Analyze sales data using SQL aggregation.
3. Rank products and customers using window functions.
4. Generate a Month-over-Month sales report using CTEs and `LAG()`.
5. Generate subtotals and grand totals using `ROLLUP`.
6. Analyze query execution using `EXPLAIN`.
7. Improve query performance using indexes.

---

## ⭐ Star Schema

The database consists of one central fact table and four dimension tables.

### Fact Table

**fact_sales**

Contains measurable sales information:

- sales_key
- date_key
- customer_key
- product_key
- location_key
- quantity
- sales_amount

### Dimension Tables

**dim_date**
- date
- year
- month
- month name
- quarter

**dim_customer**
- customer name
- city
- customer segment

**dim_product**
- product name
- category
- unit price

**dim_location**
- city
- state
- region

The `fact_sales` table connects the dimension tables through foreign keys, forming a Star Schema.

---

## 📊 SQL Concepts Implemented

### 1. Window Function Rankings

`RANK()` is used to rank products based on their sales within each category.

`DENSE_RANK()` is used to rank customers according to their total spending.

Example:

```sql
RANK() OVER (
    PARTITION BY category
    ORDER BY total_sales DESC
)

A Common Table Expression is used to calculate monthly sales.
The LAG() window function retrieves the previous month's sales.
The report calculates:
- Current month sales
- Previous month sales
- Sales change
- MoM growth percentage
Formula:
 MoM Growth % =
((Current Month Sales - Previous Month Sales)
 / Previous Month Sales) × 100

ROLLUP
WITH ROLLUP is used to generate:
- Category-level totals
- Regional subtotals
- Grand totals
Example:
GROUP BY region, category WITH ROLLUP;

MySQL EXPLAIN is used to analyze how queries are executed.
It helps identify:
- Tables accessed
- Possible indexes
- Index actually selected
- Number of rows examined
- Query execution strategy
Indexes are created on frequently used columns such as:
date_key
product_key
customer_key

🛠️ Technologies Used
- Database: MySQL 8+
- Language: SQL
- Tool: MySQL Workbench
- Version Control: GitHub

🚀 How to Run
1. Install MySQL 8+.
2. Open MySQL Workbench.
3. Open: SQL_Dimensional_Report_Week5.sql
Execute the complete SQL script.
The script automatically:- Creates the database
- Creates dimension tables
- Creates the fact table
- Inserts sample data
- Runs analytical queries
- Demonstrates rankings
- Generates the MoM report
- Demonstrates ROLLUP
- Demonstrates EXPLAIN optimization

✅ Project Requirements Completed
Requirement	Status
Star Schema	✅
Window Function Rankings	✅
CTE MoM Report	✅
ROLLUP	✅
EXPLAIN Optimization	✅
SQL Indexing	✅
