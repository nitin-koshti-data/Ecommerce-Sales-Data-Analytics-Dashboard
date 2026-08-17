SELECT * FROM ecommerce_sales;

--Total Order
SELECT COUNT(*) AS total_order FROM ecommerce_sales;

--total sales
SELECT SUM(net_amount) AS Total_sales FROM ecommerce_sales;

--list all order where order status ='cancelled'
SELECT * FROM ecommerce_sales WHERE order_status='Cancelled'

--list all order where order status ='Returned'
SELECT * FROM ecommerce_sales where order_status ='Returned'

--top product
SELECT product,SUM(net_amount) AS Total_sales 
FROM ecommerce_sales
GROUP BY product
ORDER BY Total_sales DESC ;

--TOP Cities
SELECT city,SUM(net_amount) AS Total_sales 
FROM ecommerce_sales
GROUP BY city
ORDER BY Total_sales DESC ;

--TOP State
SELECT state,SUM(net_amount) AS Total_sales 
FROM ecommerce_sales
GROUP BY state
ORDER BY Total_sales DESC ;

--monthly sales
SELECT month,SUM(net_amount) AS Total_sales 
FROM ecommerce_sales
GROUP BY month
ORDER BY Total_sales DESC ;


--highest profit product
SELECT product,SUM(profit) AS Total_profit
FROM ecommerce_sales
GROUP BY product
ORDER BY Total_profit DESC ;

--payment mode distribution 
SELECT payment_mode,COUNT(*) AS total_order
FROM ecommerce_sales
GROUP BY payment_mode
ORDER BY total_order DESC ;

--Find the total sales and profit for each category
SELECT category,SUM(net_amount) AS Total_sales ,SUM(profit) AS Total_profit
FROM ecommerce_sales
GROUP BY category
ORDER BY Total_sales DESC ;

--Top 5 Customer by total net_amount spent
SELECT customer_name,SUM(net_amount) AS Total_sales 
FROM ecommerce_sales
GROUP BY customer_name
ORDER BY Total_sales DESC LIMIT 5;

--Calculate month-over-month growth
WITH monthly_sales AS(
	SELECT year,month,EXTRACT(MONTH FROM order_date::date)AS month_num,
	ROUND(SUM(net_amount)::numeric,2) AS Total_sales
	FROM ecommerce_sales
	WHERE year IS NOT NULL AND month IS NOT NULL
	GROUP BY year,month,EXTRACT(MONTH FROM order_date::date)
)
SELECT year,month,Total_sales,
		LAG(Total_sales) OVER(ORDER BY year,month_num) AS previous_year_sales,
		ROUND((Total_sales-LAG(Total_sales) OVER(ORDER BY year,month_num))*100/
		LAG(Total_sales) OVER(ORDER BY year,month_num)::NUMERIC,2) AS GROWTH
		FROM monthly_sales
		ORDER BY year,month_num

--For each state find the avg discount given and the avg profit margin
SELECT state,ROUND(AVG(discount)::NUMERIC,2) AS avg_discount,
		ROUND(AVG((profit/sales)*100)::NUMERIC,2) AS avg_profit_margin_pct
		FROM ecommerce_sales
		GROUP BY state
		ORDER BY avg_profit_margin_pct DESC;

--Find the most popular payment mode for each category
WITH payment_count AS (
	SELECT category,payment_mode,
	COUNT(*) AS Total_order,
	RANK() OVER(PARTITION BY category ORDER BY COUNT(*) DESC) AS RANK
	FROM ecommerce_sales
	GROUP BY category,payment_mode
)
SELECT category,payment_mode AS MOST_POPULAR_PAYMENT_MODE,Total_order
		FROM payment_count
		WHERE RANK=1

--Identify product where return rate exceeds 20%
SELECT product,COUNT(*) AS total_order,
 COUNT(*) FILTER(WHERE order_status='Returned') AS returned_order,
 ROUND(COUNT(*) FILTER(WHERE order_status='Returned')*100/Count(*),2) AS returned_rate
FROM ecommerce_sales
GROUP BY product
HAVING COUNT(*) FILTER(WHERE order_status='Returned')*100/Count(*) > 20
ORDER BY returned_rate DESC;

--Rank customer within each state by total spend
SELECT state,customer_name,total_spent,
	RANK() OVER(PARTITION BY state ORDER BY total_spent DESC) AS RANK
	FROM(
	 SELECT state,customer_name,
		SUM(net_amount) AS total_spent
		FROM ecommerce_sales
		GROUP BY state,customer_name
	)T ORDER BY state,RANK ;

--Find the customer who placed order in atleast 3 different month
SELECT customer_name,
		COUNT(DISTINCT EXTRACT(MONTH FROM order_date::date)) AS distinct_month,
		COUNT(*) total_order
FROM ecommerce_sales
GROUP BY customer_name
HAVING COUNT(DISTINCT EXTRACT(MONTH FROM order_date::date)) >=3
ORDER BY distinct_month,total_order DESC;

--Using order_date and delivery_date  calculate avg delivery time per city
--and flag order where delivery_date < order_date 
SELECT city,
		ROUND(AVG(delivery_date::date-order_date::date),2) AS avg_delivery_time,
		COUNT(*) FILTER(WHERE delivery_date::date < order_date::date) AS flag_order,
		COUNT(*) AS total_order
FROM ecommerce_sales
GROUP BY city
ORDER BY avg_delivery_time DESC;