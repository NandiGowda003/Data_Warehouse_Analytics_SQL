/*
===============================================================================
Customer Report
===============================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.
	2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
	   - total orders
	   - total sales
	   - total quantity purchased
	   - total products
	   - lifespan (in months)
    4. Calculates valuable KPIs:
	    - recency (months since last order)
		- average order value
		- average monthly spend
===============================================================================
*/
-- =============================================================================
-- Create Report: gold.report_customers
-- =============================================================================
IF OBJECT_ID('gold.report_customers', 'V') IS NOT NULL
	DROP VIEW gold.report_customers;
GO

-- Create View in Database
CREATE VIEW gold.report_ustomers AS
WITH base_query AS(
	SELECT
	-- retrive core columns from tables
		f.order_number,
		f.product_key,
		f.order_date,
		f.sales_amount,
		f.quantity,
		c.customer_key,
		c.customer_number,
		CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
		DATEDIFF(YEAR,c.birthdate, GETDATE()) age
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_customers c
	ON f.customer_key = c.customer_key
	WHERE order_date IS NOT NULL
	),
 customer_aggregation AS (
		SELECT
			customer_key,
			customer_number,
			customer_name,
			age,
			COUNT(DISTINCT order_number) total_orders,
			SUM(sales_amount) total_sales,
			SUM(quantity) total_quantity,
			COUNT(DISTINCT product_key) total_products,
			MAX(order_date) last_order_date,
			DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) lifespan_months
		FROM base_query
		GROUP BY customer_key,
				 customer_number, 
				 customer_name, 
				 age
		)
		SELECT
			customer_key,
			customer_number, 
			customer_name, 
			age,
			CASE WHEN age < 20 THEN 'Under 20'
				 WHEN age between 20 and 29 THEN '20-29'
				 WHEN age between 30 and 39 THEN '30-39'
				 WHEN age between 40 and 49 THEN '40-49'
				 ELSE '50 and above'
             END AS age_group,
			CASE WHEN lifespan_months >= 12 AND total_sales > 5000 THEN 'VIP'
				 WHEN lifespan_months >= 12 AND total_sales <= 5000 THEN 'Regular'
					ELSE 'New'
             END AS customer_segment,
			last_order_date,
			DATEDIFF(MONTH, last_order_date, GETDATE()) recency_months,
			total_orders,
			total_sales,
			total_quantity,
			total_products,
			lifespan_months,
			-- Calculate average order value
			CASE WHEN total_orders = 0 THEN 0
				 ELSE total_sales/total_orders
			END AS avg_order_value, 
			-- Calculate average monthly spend
			CASE WHEN lifespan_months = 0 THEN 0
				 ELSE total_sales/lifespan_months
			END AS avg_monthly_spend
		FROM customer_aggregation;
