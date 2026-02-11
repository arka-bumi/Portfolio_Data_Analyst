/*
-- build pre-existing table before appending dataset from python
CREATE TABLE retail_orders (
	order_id INT PRIMARY KEY,
	order_date DATE,
	ship_mode VARCHAR(20),
	segment VARCHAR(20),
	country VARCHAR(20), 
	city VARCHAR(20), 
	state VARCHAR(20), 
	postal_code VARCHAR(20), 
	region VARCHAR(20), 
	category VARCHAR(20), 
	sub_category VARCHAR(20), 
	product_id VARCHAR(20), 
	cost_price DECIMAL(12,2), 
	list_price DECIMAL(12,2), 
	quantity INT, 
	discount_percent DECIMAL(7,2), 
	discount DECIMAL(12,2), 
	final_price DECIMAL(12,2), 
	total_cost DECIMAL(12,2), 
	net_revenue DECIMAL(12,2), 
	profit DECIMAL(12,2) 
)
*/

/*
-- 1) find top 10 highest revenue generating products
SELECT
	product_id,
	SUM(net_revenue) AS total_revenue
FROM retail_orders
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10
*/

/*
-- 2) find top 5 highest selling products in each region
WITH cte AS (
	SELECT
		region,
		product_id,
		SUM(net_revenue) AS total_sales,
		DENSE_RANK() OVER (PARTITION BY region ORDER BY SUM(net_revenue) DESC) AS RANK
	FROM retail_orders
	GROUP BY 1, 2
	ORDER BY 1, 4 ASC
)
SELECT
	*
FROM cte
WHERE rank <= 5
*/

/*
-- 3) find month over month growth comparison for 2022 and 2023 sales eg: jan 2022 vs jam 2023
WITH cte AS (
	SELECT
		EXTRACT(MONTH FROM order_date) AS order_month,
		EXTRACT(YEAR FROM order_date) AS order_year,
		SUM(net_revenue) AS total_sales
	FROM retail_orders
	GROUP BY 1, 2
	ORDER BY 1, 2
)
SELECT
	order_month,
	SUM(CASE WHEN order_year = 2022 THEN total_sales ELSE 0 END) AS sales_2022,
	SUM(CASE WHEN order_year = 2023 THEN total_sales ELSE 0 END) AS saleas_2023
FROM cte 
GROUP BY 1
ORDER BY 1
*/

/*
-- 4) for each category which month had highest sales
SELECT
	category,
	sales AS highest_sales,
	order_month AS peak_month,
	order_year AS peak_year
FROM (SELECT
		category,
		EXTRACT(MONTH FROM order_date) AS order_month,
		EXTRACT(YEAR FROM order_date) AS order_year,
		SUM(net_revenue) AS sales,
		DENSE_RANK() OVER (PARTITION BY category ORDER BY SUM(net_revenue) DESC) AS rank
	FROM retail_orders
	GROUP BY 1,2,3
)
WHERE rank = 1
*/

/*
-- 5) which sub_category had highest growth by profit in 2023 compare to 2022
WITH cte AS (
	SELECT
		sub_category,
		EXTRACT(YEAR FROM order_date) as profit_year,
		SUM(profit) as profit
	FROM retail_orders
	GROUP BY 1, 2
	ORDER BY 1, 2
),
cte2 AS (
	SELECT
		sub_category,
		SUM(CASE WHEN profit_year = 2022 THEN profit ELSE 0 END) AS profit_2022,
		SUM(CASE WHEN profit_year = 2023 THEN profit ELSE 0 END) AS profit_2023
	FROM cte
	GROUP BY 1
	ORDER BY 1
)
SELECT
	*,
	ROUND((profit_2023-profit_2022)*100/profit_2022, 2) AS "yoy_profit_%growth"
FROM cte2
ORDER BY 4 DESC
LIMIT 1
*/