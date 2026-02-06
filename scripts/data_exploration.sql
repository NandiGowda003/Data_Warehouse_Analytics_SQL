/*
===============================================================================
Database Exploration
===============================================================================
Purpose:
    - To explore the structure of the database, including the list of tables and their schemas.
    - To inspect the columns and metadata for specific tables.

Table Used:
    - INFORMATION_SCHEMA.TABLES
    - INFORMATION_SCHEMA.COLUMNS
*/

USE DataWarehouseAnalytics;
GO

-- 1. Database Exploration
-- Explore all objects in the database
SELECT *
FROM 
	INFORMATION_SCHEMA.TABLES

-- Explore all columns in the database
SELECT *
FROM 
	INFORMATION_SCHEMA.COLUMNS
WHERE 
	TABLE_NAME IN ('dim_customers', 'dim_products', 'fact_sales')

	===============================================================================
	Database Explore dimension
	===============================================================================
	-- explore dimension exploration by looking at the dim_customers and dim_products tables
	-- explore all countries in the dim_customers table
SELECT DISTINCT country FROM gold.dim_customers;

-- explore all categories for " major division" in the dim_products table
SELECT DISTINCT 
	category, 
	subcategory, 
	product_name 
FROM gold.dim_products
ORDER BY 1,2,3;

	===============================================================================
	Database Explore date_range
	===============================================================================
	-- Date exploration
	-- find first and last date order
SELECT 
	MIN(order_date) AS first_order,
	MAX(order_date) AS last_order,
	DATEDIFF(year, MIN(order_date), MAX(order_date)) AS order_range_years
FROM gold.fact_sales

-- find youngest and oldest birtdate
SELECT
	MIN(birthdate) AS youngest_birthdate,
	DATEDIFF(year, MIN(birthdate), GETDATE()) AS oldest_age,
	MAX(birthdate) AS oldest_birthdate,
	DATEDIFF(year, MAX(birthdate), GETDATE()) AS youngest_age
	FROM gold.dim_customers

	==========================================================================
	Database Measure Exploration
	==========================================================================
	--measure exploration
	--find the total sales
SELECT 
	SUM(sales_amount) AS total_sales
FROM gold.fact_sales

-- find how many items are sold
SELECT
	SUM(quantity) total_quantity
FROM gold.fact_sales

--find avg selling price
SELECT
	AVG(price) avg_price
FROM gold.fact_sales

-- find the total number of orders
SELECT
	COUNT(order_number) total_orders
FROM gold.fact_sales

-- unique orders
SELECT
	COUNT(DISTINCT order_number) total_orders
FROM gold.fact_sales

--Find the total number of products
SELECT COUNT(product_name) AS total_products FROM gold.dim_products

--Find the total number of customers
SELECT COUNT(customer_key) AS total_customers FROM gold.dim_customers;

--Find the total number of customers that has place the order
SELECT COUNT(DISTINCT customer_key) AS total_customers FROM gold.dim_customers;

-- Generate a Report that shows all key metrics of the business
SELECT 'Total Sales' AS measure_name, SUM(sales_amount) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Quantity', SUM(quantity) FROM gold.fact_sales
UNION ALL
SELECT 'Average Price', AVG(price) FROM gold.fact_sales
UNION ALL
SELECT 'Total Orders', COUNT(DISTINCT order_number) FROM gold.fact_sales
UNION ALL
SELECT 'Total Products', COUNT(DISTINCT product_name) FROM gold.dim_products
UNION ALL
SELECT 'Total Customers', COUNT(customer_key) FROM gold.dim_customers;

