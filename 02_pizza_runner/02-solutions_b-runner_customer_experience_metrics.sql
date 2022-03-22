-- *** B. Runner and Customer Experience ***

-- How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT 
    TO_CHAR(registration_date::date, 'W'), COUNT(*) AS  signups
FROM runners
GROUP BY TO_CHAR(registration_date::date, 'W')
ORDER BY TO_CHAR(registration_date::date, 'W');

-- What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT
    runner_id, ROUND(AVG(EXTRACT('EPOCH' FROM (pickup_time - order_time)::INTERVAL)/60)) AS  avg_pickup_time
FROM v_customer_orders co
JOIN v_runner_orders ro
ON co.order_id = ro.order_id
GROUP BY runner_id
ORDER BY runner_id;

-- Is there any relationship between the number of pizzas and how long the order takes to prepare?
WITH co_with_order_count AS 
	(
		SELECT *
		FROM pizza_runner.v_customer_orders co
		JOIN (
			SELECT order_id, count(*) AS pizza_count
			FROM pizza_runner.v_customer_orders
			GROUP BY order_id
		) gco
		USING (order_id)
	)
SELECT pizza_count, ROUND(AVG(EXTRACT('EPOCH' FROM (pickup_time - order_time)::INTERVAL)/60)) AS avg_time
FROM co_with_order_count oc
JOIN pizza_runner.v_runner_orders ro
USING (order_id)
GROUP BY pizza_count
ORDER BY pizza_count;

-- What was the average distance travelled for each customer?
SELECT customer_id, ROUND(AVG(distance)) as avg_distance_travelled
FROM v_runner_orders
JOIN v_customer_orders
USING (order_id)
GROUP BY customer_id
ORDER BY customer_id;

-- What was the difference between the longest and shortest delivery times for all orders?
SELECT MAX(duration) - MIN(duration) as diff_delivery_time
FROM v_runner_orders;

-- What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT runner_id, order_id, distance/duration * 60 as speed_km_h
FROM v_runner_orders
WHERE distance IS NOT NULL
ORDER BY runner_id, order_id;

-- What is the successful delivery percentage for each runner?
SELECT runner_id, 100 * SUM(
    CASE
        WHEN distance IS NULL THEN 0
        ELSE 1
    END
) / COUNT(*)
FROM v_runner_orders
GROUP BY runner_id
ORDER BY runner_id;