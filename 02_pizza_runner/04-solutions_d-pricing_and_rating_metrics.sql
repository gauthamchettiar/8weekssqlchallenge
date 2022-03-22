-- *** D. Pricing and Ratings ***

-- If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
WITH pizza_delivered_cost AS 
(
	SELECT
		pizza_name,
		CASE
			WHEN pizza_name = 'Meatlovers' THEN 12
			WHEN pizza_name = 'Vegetarian' THEN 10
		END AS pizza_cost
	FROM v_customer_orders
	JOIN v_runner_orders
	USING (order_id)
	JOIN pizza_names
	USING (pizza_id)
	WHERE pickup_time IS NOT NULL
)
SELECT SUM(pizza_cost)
FROM pizza_delivered_cost;

-- What if there was an additional $1 charge for any pizza extras?
-- 	Add cheese is $1 extra
WITH pizza_delivered_cost AS 
(
	SELECT
		pizza_name,
		CASE
			WHEN pizza_name = 'Meatlovers' THEN 12
			WHEN pizza_name = 'Vegetarian' THEN 10
		END AS pizza_cost,
		COALESCE(CARDINALITY(STRING_TO_ARRAY(extras,',')), 0) as extra_cost
	FROM v_customer_orders
	JOIN v_runner_orders
	USING (order_id)
	JOIN pizza_names
	USING (pizza_id)
	WHERE pickup_time IS NOT NULL
)
SELECT SUM(pizza_cost + extra_cost)
FROM pizza_delivered_cost;

-- The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
DROP TABLE IF EXISTS runner_ratings;
CREATE TABLE runner_ratings (
    "order_id" INTEGER,
    "runner_id" INTEGER,
    "rating" INTEGER
);

INSERT INTO runner_ratings 
    ("order_id", "runner_id", "rating")
VALUES
    ('1', '1', '5'),
    ('2', '1', '4'),
    ('3', '1', '5'),
    ('4', '2', '3'),
    ('5', '3', '1'),
    ('7', '2', '3'),
    ('8', '2', '4'),
    ('10', '1', '5');


-- Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
-- 	customer_id
-- 	order_id
-- 	runner_id
-- 	rating
-- 	order_time
-- 	pickup_time
-- 	Time between order and pickup
-- 	Delivery duration
-- 	Average speed
-- 	Total number of pizzas
SELECT order_id, customer_id, runner_id, rating, order_time, pickup_time, 
    ROUND(EXTRACT(EPOCH FROM pickup_time - order_time)/60) as time_between_order_and_pickup,
    duration as delivery_duration,
    ROUND(((distance/duration)*60)::numeric, 2) as avg_speed_kmph,
    COUNT(pizza_id) as total_number_of_pizza
FROM v_customer_orders
JOIN v_runner_orders
USING (order_id)
JOIN runner_ratings
using (order_id, runner_id)
GROUP BY customer_id, order_id, runner_id, rating, order_time, pickup_time, distance, duration
ORDER BY order_id, customer_id, runner_id;


-- If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
WITH pizza_delivered_cost AS 
(
	SELECT
		pizza_name,
		CASE
			WHEN pizza_name = 'Meatlovers' THEN 12
			WHEN pizza_name = 'Vegetarian' THEN 10
		END AS pizza_cost,
        ROUND((distance * 0.30)::numeric, 2) AS delivery_cost
	FROM v_customer_orders
	JOIN v_runner_orders
	USING (order_id)
	JOIN pizza_names
	USING (pizza_id)
	WHERE pickup_time IS NOT NULL
)
SELECT SUM(pizza_cost) - SUM(delivery_cost)
FROM pizza_delivered_cost;

-- BONUS: If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?
INSERT INTO pizza_names
  ("pizza_id", "pizza_name")
VALUES
  (3, 'Supreme');

INSERT INTO pizza_recipes
  ("pizza_id", "toppings")
VALUES
  (2, '1, 3, 5, 6, 7, 8, 9, 13, 14');

INSERT INTO pizza_toppings
  ("topping_id", "topping_name")
VALUES
  (13, 'Olives'),
  (14, 'Pineapple');