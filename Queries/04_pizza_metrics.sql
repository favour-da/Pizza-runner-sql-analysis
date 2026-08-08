SELECT COUNT(*) AS pizza_count FROM customer_orders_clean;

SELECT COUNT(DISTINCT order_id) AS unique_orders FROM customer_orders_clean;

SELECT runner_id, COUNT(*) AS delivered_orders
FROM runner_orders_clean
WHERE cancellation IS NULL
GROUP BY runner_id ORDER BY runner_id;

SELECT pn.pizza_name, COUNT(*) AS delivered_count
FROM customer_orders_clean co
JOIN runner_orders_clean r ON co.order_id = r.order_id
JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
WHERE r.cancellation IS NULL
GROUP BY pn.pizza_name;

SELECT co.customer_id, pn.pizza_name, COUNT(*) AS order_count
FROM customer_orders_clean co
JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
GROUP BY co.customer_id, pn.pizza_name
ORDER BY co.customer_id, pn.pizza_name;

SELECT co.order_id, COUNT(*) AS pizza_count
FROM customer_orders_clean co
JOIN runner_orders_clean r ON co.order_id = r.order_id
WHERE r.cancellation IS NULL
GROUP BY co.order_id
ORDER BY pizza_count DESC LIMIT 1;

SELECT co.customer_id,
    SUM(CASE WHEN co.exclusions IS NOT NULL OR co.extras IS NOT NULL THEN 1 ELSE 0 END) AS at_least_1_change,
    SUM(CASE WHEN co.exclusions IS NULL AND co.extras IS NULL THEN 1 ELSE 0 END) AS no_changes
FROM customer_orders_clean co
JOIN runner_orders_clean r ON co.order_id = r.order_id
WHERE r.cancellation IS NULL
GROUP BY co.customer_id ORDER BY co.customer_id;

SELECT COUNT(*) AS pizzas_with_both
FROM customer_orders_clean co
JOIN runner_orders_clean r ON co.order_id = r.order_id
WHERE r.cancellation IS NULL AND co.exclusions IS NOT NULL AND co.extras IS NOT NULL;

SELECT HOUR(order_time) AS hour_of_day, COUNT(*) AS pizza_count
FROM customer_orders_clean
GROUP BY hour_of_day ORDER BY hour_of_day;

SELECT DAYNAME(order_time) AS day_of_week, COUNT(*) AS pizza_count
FROM customer_orders_clean
GROUP BY day_of_week, WEEKDAY(order_time)
ORDER BY WEEKDAY(order_time);