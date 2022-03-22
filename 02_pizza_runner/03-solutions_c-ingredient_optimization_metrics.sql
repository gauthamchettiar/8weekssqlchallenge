-- *** C. Ingredient Optimization ***

-- What are the standard ingredients for each pizza?
WITH unnested_toppings AS (
	SELECT pizza_name, pizza_id, UNNEST(STRING_TO_ARRAY(toppings, ','))::NUMERIC AS topping_id
	FROM pizza_recipes
	JOIN pizza_names
	USING (pizza_id)
)
SELECT pizza_name, topping_name
FROM unnested_toppings
JOIN pizza_toppings
USING (topping_id)
ORDER BY pizza_name;

-- OR

SELECT pizza_name, STRING_AGG(pt.topping_name, ',') as standard_toppings
FROM pizza_recipes
LEFT JOIN pizza_toppings pt
ON pt.topping_id = ANY(STRING_TO_ARRAY(toppings, ',')::numeric[])
JOIN pizza_names
USING (pizza_id)
GROUP BY pizza_name;

-- What was the most commonly added extra?
WITH unnested_extras AS (
	SELECT UNNEST(STRING_TO_ARRAY(extras, ','))::NUMERIC AS topping_id
	FROM v_customer_orders
)
SELECT topping_name, COUNT(topping_id) AS added_times
FROM unnested_extras
JOIN pizza_toppings
USING (topping_id)
GROUP BY topping_name
ORDER BY added_times DESC
LIMIT 1;

-- What was the most common exclusion?
WITH unnested_exclusions AS (
	SELECT UNNEST(STRING_TO_ARRAY(exclusions, ','))::NUMERIC AS topping_id
	FROM v_customer_orders
)
SELECT topping_name, COUNT(topping_id) AS excluded_times
FROM unnested_exclusions
JOIN pizza_toppings
USING (topping_id)
GROUP BY topping_name
ORDER BY excluded_times DESC
LIMIT 1;

-- Generate an order item for each record in the customers_orders table in the format of one of the following:
-- 	Meat Lovers
-- 	Meat Lovers - Exclude Beef
-- 	Meat Lovers - Extra Bacon
-- 	Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
WITH co_with_item_id AS 
(
	SELECT co.*,
	ROW_NUMBER() OVER (PARTITION BY co.order_id) AS item_id
	FROM v_customer_orders co
)
, co_with_exclusion_string AS 
(
	SELECT order_id, customer_id, pizza_id, item_id, STRING_AGG(pt.topping_name, ',') as exclusions
	FROM co_with_item_id
	LEFT JOIN pizza_toppings pt
	ON pt.topping_id = ANY(STRING_TO_ARRAY(exclusions, ',')::numeric[])
	GROUP BY order_id, customer_id, pizza_id, item_id
)
, co_with_extra_string AS 
(
	SELECT order_id, customer_id, pizza_id, item_id, STRING_AGG(pt.topping_name, ',') as extras
	FROM co_with_item_id
	LEFT JOIN pizza_toppings pt
	ON pt.topping_id = ANY(STRING_TO_ARRAY(extras, ',')::numeric[])
	GROUP BY order_id, customer_id, pizza_id, item_id
)
SELECT order_id, customer_id, CONCAT_WS(' - Extra ', CONCAT_WS(' - Exclude ', pizza_name, exclusions), extras) AS order_string
FROM co_with_exclusion_string
JOIN co_with_extra_string
USING (order_id, customer_id, pizza_id, item_id)
JOIN pizza_names
USING (pizza_id)
ORDER BY order_id, customer_id, pizza_id, item_id;

-- Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- 	For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
WITH co_with_item_id AS 
(
	SELECT co.*,
	ROW_NUMBER() OVER (PARTITION BY co.order_id) AS item_id
	FROM v_customer_orders co
)
, co_with_extras_unnested AS 
(
	SELECT order_id, customer_id, pizza_id, item_id, 
	UNNEST(
		CASE 
			WHEN extras is null then '{}'
			ELSE STRING_TO_ARRAY(extras, ',') 
		END
	)::NUMERIC AS extras_topping_id
	FROM co_with_item_id co
)
, co_with_exclusions_unnested AS
(
	SELECT order_id, customer_id, pizza_id, item_id,
	UNNEST(
		CASE 
			WHEN exclusions is null then '{}'
			ELSE STRING_TO_ARRAY(exclusions, ',') 
		END
	)::NUMERIC AS exclusions_topping_id
	FROM co_with_item_id co
)
, co_with_ingredients_unnested AS
(
	SELECT order_id, customer_id, pizza_id, item_id,
	UNNEST(STRING_TO_ARRAY(toppings, ','))::numeric AS ingredients_topping_id
	FROM co_with_item_id co
	JOIN pizza_recipes pr
	USING (pizza_id)
)
, co_with_merged_unnested AS 
(
	SELECT order_id, customer_id, pizza_id, item_id, ingredients_topping_id
	FROM co_with_ingredients_unnested
	EXCEPT
	SELECT order_id, customer_id, pizza_id, item_id, exclusions_topping_id
	FROM co_with_exclusions_unnested
	UNION ALL
	SELECT order_id, customer_id, pizza_id, item_id, extras_topping_id
	FROM co_with_extras_unnested
)
, co_with_names AS 
(
	SELECT order_id, customer_id, pizza_name, item_id, 
	CASE
		WHEN COUNT(topping_name) > 1 THEN CONCAT(COUNT(topping_name), 'x',topping_name)
		ELSE topping_name
	END AS topping_name
	FROM co_with_merged_unnested
	JOIN pizza_toppings
	ON ingredients_topping_id = topping_id
	JOIN pizza_names
	USING (pizza_id)
	GROUP BY order_id, customer_id, pizza_name, item_id, topping_name
	ORDER BY order_id, customer_id, pizza_name, item_id, topping_name
)
SELECT order_id, customer_id, CONCAT_WS(' - ',pizza_name, STRING_AGG(topping_name, ',')) AS ingredient_list
FROM co_with_names
GROUP BY order_id, customer_id, pizza_name, item_id
ORDER BY order_id, customer_id, pizza_name, item_id;

-- What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
WITH co_with_item_id AS 
(
	SELECT co.*,
	ROW_NUMBER() OVER (PARTITION BY co.order_id) AS item_id
	FROM v_customer_orders co
)
, co_with_extras_unnested AS 
(
	SELECT order_id, customer_id, pizza_id, item_id, 
	UNNEST(
		CASE 
			WHEN extras is null then '{}'
			ELSE STRING_TO_ARRAY(extras, ',') 
		END
	)::NUMERIC AS extras_topping_id
	FROM co_with_item_id co
)
, co_with_exclusions_unnested AS
(
	SELECT order_id, customer_id, pizza_id, item_id,
	UNNEST(
		CASE 
			WHEN exclusions is null then '{}'
			ELSE STRING_TO_ARRAY(exclusions, ',') 
		END
	)::NUMERIC AS exclusions_topping_id
	FROM co_with_item_id co
)
, co_with_ingredients_unnested AS
(
	SELECT order_id, customer_id, pizza_id, item_id,
	UNNEST(STRING_TO_ARRAY(toppings, ','))::numeric AS ingredients_topping_id
	FROM co_with_item_id co
	JOIN pizza_recipes pr
	USING (pizza_id)
)
, co_with_merged_unnested AS 
(
	SELECT order_id, customer_id, pizza_id, item_id, ingredients_topping_id
	FROM co_with_ingredients_unnested
	EXCEPT
	SELECT order_id, customer_id, pizza_id, item_id, exclusions_topping_id
	FROM co_with_exclusions_unnested
	UNION ALL
	SELECT order_id, customer_id, pizza_id, item_id, extras_topping_id
	FROM co_with_extras_unnested
)
SELECT topping_name AS ingredient_name, COUNT(topping_name) AS ingredient_usage_count
FROM co_with_merged_unnested
JOIN v_runner_orders
USING (order_id)
JOIN pizza_toppings
ON ingredients_topping_id =  topping_id
WHERE pickup_time IS NOT NULL
GROUP BY topping_name
ORDER BY ingredient_usage_count DESC;
