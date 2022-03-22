-- What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, SUM(m.price) AS total_amount_spent
FROM sales s 
JOIN menu m 
ON s.product_id = m.product_id 
GROUP BY s.customer_id
ORDER BY s.customer_id;

-- How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT(order_date)) AS number_of_visits
FROM sales 
GROUP BY customer_id
ORDER BY customer_id;

-- What was the first item from the menu purchased by each customer?
WITH cte AS (
    SELECT customer_id, order_date, product_id,
    RANK() OVER (PARTITION BY customer_id ORDER BY order_date) AS rank
    FROM sales
)
SELECT customer_id, product_name AS first_purchased_item
FROM cte c
JOIN menu m
ON c.product_id = m.product_id
WHERE rank = 1
ORDER BY customer_id, product_name;

-- What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT product_name, COUNT(*) AS purchase_count
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
GROUP BY product_name
ORDER BY count(*) DESC
LIMIT 1;

-- Which item was the most popular for each customer?
WITH cte AS (
    SELECT customer_id, product_id,
    RANK() OVER (PARTITION BY customer_id ORDER BY count(*) DESC) AS rank
    FROM sales
    GROUP BY customer_id, product_id
)
SELECT customer_id, product_name AS popular_item
FROM cte c
JOIN menu m
ON m.product_id = c.product_id
WHERE rank =1
ORDER BY customer_id, product_name;

-- Which item was purchased first by the customer after they became a member?
WITH cte AS (
    SELECT s.customer_id, order_date, product_id, join_date,
    RANK() OVER (PARTITION BY s.customer_id ORDER BY order_date) AS rank
    FROM sales s
    JOIN members mb
    on s.customer_id = mb.customer_id
    where order_date >= join_date

)
SELECT customer_id, product_name AS first_purchase_after_member
FROM cte c
JOIN menu m
ON c.product_id = m.product_id
WHERE rank = 1
ORDER BY customer_id;

-- Which item was purchased just before the customer became a member?
WITH cte AS (
    SELECT s.customer_id, order_date, product_id, join_date,
    RANK() OVER (PARTITION BY s.customer_id ORDER BY order_date desc) AS rank
    FROM sales s
    JOIN members mb
    on s.customer_id = mb.customer_id
    where order_date < join_date

)
SELECT customer_id, product_name AS last_purchase_before_member
FROM cte c
JOIN menu m
ON c.product_id = m.product_id
WHERE rank = 1
ORDER BY customer_id;

-- What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id, COUNT(*) AS total_items_bought, SUM(price) AS total_amount_spent
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
JOIN members mb
ON s.customer_id = mb.customer_id
WHERE order_date < join_date
GROUP BY s.customer_id
ORDER BY s.customer_id;

-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT customer_id, 
    SUM(
        CASE 
            WHEN product_name = 'sushi' THEN price * 10 * 2
            ELSE price * 10
        END
        ) AS total_points
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
GROUP BY customer_id
ORDER BY customer_id;

-- In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT s.customer_id, 
    SUM(
        CASE 
            WHEN order_date BETWEEN join_date AND join_date + INTERVAL '1 WEEK' THEN price * 10 * 2
            WHEN product_name = 'sushi' THEN price * 10 * 2
            ELSE price * 10
        END
        ) AS total_points
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
JOIN members mb
ON s.customer_id = mb.customer_id 
WHERE order_date < '2021-02-01' 
GROUP BY s.customer_id
ORDER BY s.customer_id;

--BONUS: Join all the things
SELECT s.customer_id, order_date, product_name, price, 
CASE 
    WHEN order_date >= join_date THEN 'Y'
    ELSE 'N'
END as member
FROM sales s
LEFT OUTER JOIN menu m
ON s.product_id = m.product_id
LEFT OUTER JOIN members mb
ON s.customer_id = mb.customer_id
ORDER BY s.customer_id, order_date, price DESC;

-- BONUS: Rank all the things
WITH cte AS (
    SELECT s.customer_id, order_date, product_name, price, 
    CASE 
        WHEN order_date >= join_date THEN 'Y'
        ELSE 'N'
    END as member
    FROM sales s
    LEFT OUTER JOIN menu m
    ON s.product_id = m.product_id
    LEFT OUTER JOIN members mb
    ON s.customer_id = mb.customer_id
    ORDER BY s.customer_id, order_date, price DESC
)
SELECT *,
    CASE
        WHEN member = 'Y' THEN DENSE_RANK() OVER (PARTITION BY customer_id, member ORDER BY order_date)
        ELSE null
    END as ranking
FROM cte;
