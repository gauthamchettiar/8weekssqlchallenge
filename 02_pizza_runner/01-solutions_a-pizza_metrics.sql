-- *** Pizza Metrics ***
-- How many pizzas were ordered?
SELECT COUNT(*) as pizzas_ordered 
FROM v_customer_orders;

-- How many unique customer orders were made?
SELECT COUNT(DISTINCT(order_id)) as unique_orders
FROM v_customer_orders;

-- How many successful orders were delivered by each runner?
SELECT runner_id, COUNT(*) as pizzas_delivered
FROM v_runner_orders
WHERE pickup_time IS NOT NULL
GROUP BY runner_id
ORDER BY runner_id;

-- How many of each type of pizza was delivered?
SELECT pizza_name, count(*)
FROM v_customer_orders
JOIN pizza_names
USING (pizza_id)
JOIN v_runner_orders
USING (order_id)
WHERE pickup_time IS NOT NULL
GROUP BY pizza_name
ORDER BY pizza_name;

-- How many Vegetarian and Meatlovers were ordered by each customer?
SELECT customer_id, pizza_name, count(*)
FROM v_customer_orders
JOIN pizza_names
USING (pizza_id)
GROUP BY customer_id, pizza_name
ORDER BY customer_id, pizza_name;

-- What was the maximum number of pizzas delivered in a single order?
SELECT count(*)
FROM v_customer_orders
JOIN v_runner_orders
USING (order_id)
WHERE pickup_time IS NOT NULL
GROUP BY order_id
ORDER BY count(*) DESC
LIMIT 1;

-- For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT customer_id,
    SUM(
        CASE 
            WHEN exclusions IS NOT NULL OR extras IS NOT NULL THEN 1
            ELSE 0
        END
    ) AS atleast_1_change,
    SUM(
        CASE 
            WHEN exclusions IS NULL ANd extras IS NULL THEN 1
            ELSE 0
        END
    ) AS no_change
FROM v_runner_orders
JOIN v_customer_orders
USING (order_id)
GROUP BY customer_id;
    
-- How many pizzas were delivered that had both exclusions and extras?
SELECT COUNT(*) AS pizza_with_both_exclusion_and_extras
FROM v_customer_orders
JOIN v_runner_orders
USING (order_id)
WHERE exclusions IS NOT NULL AND extras IS NOT NULL AND pickup_time IS NOT NULL;

-- What was the total volume of pizzas ordered for each hour of the day?
SELECT EXTRACT(HOUR FROM order_time), COUNT(*) AS pizzas_ordered
FROM v_customer_orders
GROUP BY EXTRACT(HOUR FROM order_time)
ORDER BY EXTRACT(HOUR FROM order_time);

-- What was the volume of orders for each day of the week?
SELECT EXTRACT(ISODOW FROM order_time), COUNT(*) AS pizzas_ordered
FROM v_customer_orders
GROUP BY EXTRACT(ISODOW FROM order_time)
ORDER BY EXTRACT(ISODOW FROM order_time);