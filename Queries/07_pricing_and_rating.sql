SELECT SUM(CASE WHEN pn.pizza_name = 'Meat Lovers' THEN 12 ELSE 10 END) AS total_revenue
FROM customer_orders_clean co
JOIN runner_orders_clean r ON co.order_id = r.order_id
JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
WHERE r.cancellation IS NULL;

SELECT SUM(
    CASE WHEN pn.pizza_name = 'Meat Lovers' THEN 12 ELSE 10 END
    + IFNULL(1 + LENGTH(co.extras) - LENGTH(REPLACE(co.extras, ',', '')), 0)
) AS total_revenue
FROM customer_orders_clean co
JOIN runner_orders_clean r ON co.order_id = r.order_id
JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
WHERE r.cancellation IS NULL;

CREATE TABLE runner_ratings (
    order_id  INT PRIMARY KEY,
    runner_id INT NOT NULL,
    rating    INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    rated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO runner_ratings (order_id, runner_id, rating) VALUES
    (1, 1, 5), (2, 1, 4), (3, 1, 3), (4, 2, 5),
    (5, 3, 4), (7, 2, 5), (8, 2, 4), (10, 1, 5);
    
WITH order_info AS (
    SELECT order_id, customer_id, COUNT(*) AS pizza_count, MIN(order_time) AS order_time
    FROM customer_orders_clean
    GROUP BY order_id, customer_id
)
SELECT
    oi.customer_id, oi.order_id, r.runner_id, rr.rating,
    oi.order_time, r.pickup_time,
    TIMESTAMPDIFF(MINUTE, oi.order_time, r.pickup_time) AS order_to_pickup_minutes,
    r.duration AS delivery_duration_minutes,
    ROUND(r.distance / (r.duration / 60.0), 2) AS avg_speed_kmh,
    oi.pizza_count
FROM order_info oi
JOIN runner_orders_clean r ON oi.order_id = r.order_id
JOIN runner_ratings rr ON rr.order_id = oi.order_id
WHERE r.cancellation IS NULL
ORDER BY oi.order_id;

WITH revenue AS (
    SELECT SUM(CASE WHEN pn.pizza_name = 'Meat Lovers' THEN 12 ELSE 10 END) AS total_rev
    FROM customer_orders_clean co
    JOIN runner_orders_clean r ON co.order_id = r.order_id
    JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
    WHERE r.cancellation IS NULL
),
runner_cost AS (
    SELECT SUM(distance) * 0.30 AS total_cost
    FROM (SELECT DISTINCT order_id, distance FROM runner_orders_clean WHERE cancellation IS NULL) d
)
SELECT revenue.total_rev - runner_cost.total_cost AS net_revenue
FROM revenue, runner_cost;