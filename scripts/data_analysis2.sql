/*
===============================================================================
Performance Analysis (Year-over-Year, Month-over-Month)
    - To measure the performance of products, customers, or regions over time.
    - For benchmarking and identifying high-performing entities.
    - To track yearly trends and growth.
    - USING CTE
    - LAG(): Accesses data from previous rows.
    - AVG() OVER(): Computes average values within partitions.
    - CASE: Defines conditional logic for trend analysis.
===============================================================================
*/

/* Analyze the yearly performance of products by comparing their sales 
to both the average sales performance of the product and the previous year's sales */

WITH yearly_product_sales AS(
    SELECT
        YEAR(f.order_date) order_year,
        p.product_name,
        SUM(f.sales_amount) current_sales
    FROM gold.dim_products p
    LEFT JOIN gold.fact_sales f
    ON p.product_key = f.product_key
    WHERE f.order_date IS NOT NULL
    GROUP BY YEAR(f.order_date) ,
            p.product_name
)
SELECT
    order_year,
    product_name,
    current_sales,
    AVG(current_sales) OVER(PARTITION BY product_name) current_avg_sales,
    current_sales - AVG(current_sales) OVER(PARTITION BY product_name) diff_avg,
    CASE WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) > 0 THEN 'above avg'
         WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) < 0 THEN 'below avg'
         ELSE 'avg'
    END AS avg_name,
    LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) AS py_sales,
    current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) diff_previous_year,
    CASE WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) > 0 THEN 'inreasing'
         WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) < 0 THEN 'decresing'
         ELSE 'No change'
    END AS avg_name
FROM yearly_product_sales;

/*
===============================================================================
Data Segmentation Analysis
    - To group data into meaningful categories for targeted insights.
    - For customer segmentation, product categorization, or regional analysis.
    - CASE: Defines custom segmentation logic.
    - GROUP BY: Groups data into segments.
===============================================================================
*/

/*Segment products into cost ranges and 
count how many products fall into each segment*/

WITH product_segment AS (
SELECT
    product_key,
    product_name,
    cost,
    CASE WHEN cost < 100 THEN ' Below 100'
         WHEN cost BETWEEN 100 AND 500 THEN '100-500'
         WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
         ELSE 'Above 1000'
    END cost_range
FROM gold.dim_products
)
SELECT
    cost_range,
    COUNT(product_key) seg_count
FROM product_segment
GROUP BY cost_range
ORDER BY seg_count DESC;

/*Group customers into three segments based on their spending behavior:
	- VIP: Customers with at least 12 months of history and spending more than €5,000.
	- Regular: Customers with at least 12 months of history but spending €5,000 or less.
	- New: Customers with a lifespan less than 12 months.
And find the total number of customers by each group
*/

WITH customer_spending AS (
SELECT 
    d.customer_key,
    SUM(f.sales_amount) total_spending,
    MIN(order_date) first_order,
    MAX(order_date) last_order,
    DATEDIFF(month, MIN(order_date), MAX(order_date)) time_span
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers d
ON f.customer_key = d.customer_key
GROUP BY d.customer_key
)
SELECT
    cust_segment,
    COUNT(customer_key) c
FROM(
SELECT
    customer_key,
    CASE WHEN time_span = 12 AND total_spending > 5000 THEN 'VIP'
         WHEN time_span = 12 AND total_spending <= 5000 THEN 'Regular'
         ELSE 'New'
    END AS cust_segment
FROM customer_spending
)t
GROUP BY cust_segment
ORDER BY c DESC
