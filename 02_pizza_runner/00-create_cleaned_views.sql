SET search_path = pizza_runner;

DROP VIEW IF EXISTS v_customer_orders;
CREATE VIEW v_customer_orders AS
    SELECT order_id, customer_id, pizza_id, 
    CASE 
            WHEN exclusions = 'null' OR exclusions = '' THEN NULL
            ELSE exclusions
    END as exclusions,
    CASE 
            WHEN extras = 'null' OR extras = '' THEN NULL
            ELSE extras
    END as extras,
    order_time
    FROM customer_orders;

DROP VIEW IF EXISTS v_runner_orders;
CREATE VIEW v_runner_orders AS
    SELECT 
        order_id, runner_id, 
        CAST(NULLIF(pickup_time, 'null') AS TIMESTAMP) AS pickup_time, 
        CAST(SUBSTRING(NULLIF(distance, 'null') FROM '[0-9]*') AS FLOAT) AS distance, 
        CAST(SUBSTRING(NULLIF(duration, 'null') FROM '[0-9]*') AS INT) AS duration, 
        CASE 
            WHEN cancellation = 'null' THEN NULL
            WHEN cancellation = '' THEN NULL  
            ELSE cancellation
        END AS cancellation
    FROM runner_orders;