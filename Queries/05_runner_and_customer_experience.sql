SELECT
    DATE_ADD('2021-01-01', INTERVAL FLOOR(DATEDIFF(registration_date, '2021-01-01')/7)*7 DAY) AS week_start,
    COUNT(*) AS runner_signups
FROM runners
GROUP BY week_start ORDER BY week_start;

SELECT r.runner_id, ROUND(AVG(TIMESTAMPDIFF(MINUTE, co.order_time, r.pickup_time)), 2) AS avg_pickup_minutes
FROM runner_orders_clean r
JOIN (SELECT DISTINCT order_id, order_time FROM customer_orders_clean) co ON r.order_id = co.order_id
WHERE r.pickup_time IS NOT NULL
GROUP BY r.runner_id ORDER BY r.runner_id;

WITH order_pizza_count AS (
    SELECT order_id, COUNT(*) AS pizza_count FROM customer_orders_clean GROUP BY order_id
)
SELECT opc.pizza_count, ROUND(AVG(TIMESTAMPDIFF(MINUTE, co.order_time, r.pickup_time)), 2) AS avg_prep_minutes
FROM order_pizza_count opc
JOIN runner_orders_clean r ON opc.order_id = r.order_id
JOIN (SELECT DISTINCT order_id, order_time FROM customer_orders_clean) co ON opc.order_id = co.order_id
WHERE r.pickup_time IS NOT NULL
GROUP BY opc.pizza_count ORDER BY opc.pizza_count;

WITH order_distance AS (
    SELECT DISTINCT co.order_id, co.customer_id, r.distance
    FROM customer_orders_clean co
    JOIN runner_orders_clean r ON co.order_id = r.order_id
    WHERE r.cancellation IS NULL
)
SELECT customer_id, ROUND(AVG(distance), 2) AS avg_distance_km
FROM order_distance GROUP BY customer_id ORDER BY customer_id;

SELECT MAX(duration) - MIN(duration) AS delivery_duration_range_minutes
FROM runner_orders_clean WHERE cancellation IS NULL;

SELECT r.runner_id, r.order_id, r.distance, r.duration,
    ROUND(r.distance / (r.duration / 60.0), 2) AS avg_speed_kmh
FROM runner_orders_clean r
WHERE r.cancellation IS NULL
ORDER BY r.runner_id, r.order_id;

SELECT runner_id,
    ROUND(100.0 * SUM(CASE WHEN cancellation IS NULL THEN 1 ELSE 0 END) / COUNT(*), 1) AS success_pct
FROM runner_orders_clean
GROUP BY runner_id ORDER BY runner_id;

