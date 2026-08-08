WITH RECURSIVE numbers AS (
    SELECT 1 AS n UNION ALL SELECT n + 1 FROM numbers WHERE n < 10
)
SELECT pn.pizza_name,
    GROUP_CONCAT(pt.topping_name ORDER BY pt.topping_name SEPARATOR ', ') AS standard_ingredients
FROM pizza_recipes pr
JOIN pizza_names pn ON pr.pizza_id = pn.pizza_id
JOIN numbers ON numbers.n <= 1 + LENGTH(pr.toppings) - LENGTH(REPLACE(pr.toppings, ',', ''))
JOIN pizza_toppings pt
    ON pt.topping_id = CAST(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(pr.toppings, ',', numbers.n), ',', -1)) AS UNSIGNED)
GROUP BY pn.pizza_name;

WITH RECURSIVE numbers AS (
    SELECT 1 AS n UNION ALL SELECT n + 1 FROM numbers WHERE n < 10
),
extras_split AS (
    SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(co.extras, ',', numbers.n), ',', -1)) AS topping_id
    FROM customer_orders_clean co
    JOIN numbers ON numbers.n <= 1 + LENGTH(co.extras) - LENGTH(REPLACE(co.extras, ',', ''))
    WHERE co.extras IS NOT NULL
)
SELECT pt.topping_name, COUNT(*) AS times_added
FROM extras_split e
JOIN pizza_toppings pt ON pt.topping_id = CAST(e.topping_id AS UNSIGNED)
GROUP BY pt.topping_name ORDER BY times_added DESC LIMIT 1;

WITH RECURSIVE numbers AS (
    SELECT 1 AS n UNION ALL SELECT n + 1 FROM numbers WHERE n < 10
),
exclusions_split AS (
    SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(co.exclusions, ',', numbers.n), ',', -1)) AS topping_id
    FROM customer_orders_clean co
    JOIN numbers ON numbers.n <= 1 + LENGTH(co.exclusions) - LENGTH(REPLACE(co.exclusions, ',', ''))
    WHERE co.exclusions IS NOT NULL
)
SELECT pt.topping_name, COUNT(*) AS times_excluded
FROM exclusions_split e
JOIN pizza_toppings pt ON pt.topping_id = CAST(e.topping_id AS UNSIGNED)
GROUP BY pt.topping_name ORDER BY times_excluded DESC LIMIT 1;

WITH RECURSIVE numbers AS (
    SELECT 1 AS n UNION ALL SELECT n + 1 FROM numbers WHERE n < 10
),
exclusions_list AS (
    SELECT co.row_id, GROUP_CONCAT(pt.topping_name ORDER BY pt.topping_name SEPARATOR ', ') AS excl_names
    FROM customer_orders_clean co
    JOIN numbers ON numbers.n <= 1 + LENGTH(co.exclusions) - LENGTH(REPLACE(co.exclusions, ',', ''))
    JOIN pizza_toppings pt
        ON pt.topping_id = CAST(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(co.exclusions, ',', numbers.n), ',', -1)) AS UNSIGNED)
    WHERE co.exclusions IS NOT NULL
    GROUP BY co.row_id
),
extras_list AS (
    SELECT co.row_id, GROUP_CONCAT(pt.topping_name ORDER BY pt.topping_name SEPARATOR ', ') AS extra_names
    FROM customer_orders_clean co
    JOIN numbers ON numbers.n <= 1 + LENGTH(co.extras) - LENGTH(REPLACE(co.extras, ',', ''))
    JOIN pizza_toppings pt
        ON pt.topping_id = CAST(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(co.extras, ',', numbers.n), ',', -1)) AS UNSIGNED)
    WHERE co.extras IS NOT NULL
    GROUP BY co.row_id
)
SELECT co.row_id, co.order_id,
    CONCAT(
        pn.pizza_name,
        IF(ex.excl_names IS NOT NULL, CONCAT(' - Exclude ', ex.excl_names), ''),
        IF(ea.extra_names IS NOT NULL, CONCAT(' - Extra ', ea.extra_names), '')
    ) AS order_item
FROM customer_orders_clean co
JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
LEFT JOIN exclusions_list ex ON co.row_id = ex.row_id
LEFT JOIN extras_list ea ON co.row_id = ea.row_id
ORDER BY co.row_id;

WITH RECURSIVE numbers AS (
    SELECT 1 AS n UNION ALL SELECT n + 1 FROM numbers WHERE n < 10
),
base_toppings AS (
    SELECT pr.pizza_id,
        CAST(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(pr.toppings, ',', numbers.n), ',', -1)) AS UNSIGNED) AS topping_id
    FROM pizza_recipes pr
    JOIN numbers ON numbers.n <= 1 + LENGTH(pr.toppings) - LENGTH(REPLACE(pr.toppings, ',', ''))
),
exclusions_split AS (
    SELECT co.row_id,
        CAST(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(co.exclusions, ',', numbers.n), ',', -1)) AS UNSIGNED) AS topping_id
    FROM customer_orders_clean co
    JOIN numbers ON numbers.n <= 1 + LENGTH(co.exclusions) - LENGTH(REPLACE(co.exclusions, ',', ''))
    WHERE co.exclusions IS NOT NULL
),
extras_split AS (
    SELECT co.row_id,
        CAST(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(co.extras, ',', numbers.n), ',', -1)) AS UNSIGNED) AS topping_id
    FROM customer_orders_clean co
    JOIN numbers ON numbers.n <= 1 + LENGTH(co.extras) - LENGTH(REPLACE(co.extras, ',', ''))
    WHERE co.extras IS NOT NULL
),
order_toppings AS (
    SELECT co.row_id, bt.topping_id
    FROM customer_orders_clean co
    JOIN base_toppings bt ON bt.pizza_id = co.pizza_id
    WHERE NOT EXISTS (
        SELECT 1 FROM exclusions_split ex WHERE ex.row_id = co.row_id AND ex.topping_id = bt.topping_id
    )
    UNION ALL
    SELECT row_id, topping_id FROM extras_split
),
topping_counts AS (
    SELECT row_id, topping_id, COUNT(*) AS qty FROM order_toppings GROUP BY row_id, topping_id
)
SELECT co.order_id,
    CONCAT(pn.pizza_name, ': ',
        GROUP_CONCAT(
            CASE WHEN tc.qty > 1 THEN CONCAT(tc.qty, 'x', pt.topping_name) ELSE pt.topping_name END
            ORDER BY pt.topping_name SEPARATOR ', '
        )
    ) AS ingredient_list
FROM topping_counts tc
JOIN customer_orders_clean co ON co.row_id = tc.row_id
JOIN pizza_names pn ON pn.pizza_id = co.pizza_id
JOIN pizza_toppings pt ON pt.topping_id = tc.topping_id
GROUP BY co.row_id, co.order_id, pn.pizza_name
ORDER BY co.row_id;

WITH RECURSIVE numbers AS (
    SELECT 1 AS n UNION ALL SELECT n + 1 FROM numbers WHERE n < 10
),
base_toppings AS (
    SELECT pr.pizza_id,
        CAST(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(pr.toppings, ',', numbers.n), ',', -1)) AS UNSIGNED) AS topping_id
    FROM pizza_recipes pr
    JOIN numbers ON numbers.n <= 1 + LENGTH(pr.toppings) - LENGTH(REPLACE(pr.toppings, ',', ''))
),
delivered_orders AS (
    SELECT co.row_id, co.pizza_id, co.exclusions, co.extras
    FROM customer_orders_clean co
    JOIN runner_orders_clean r ON co.order_id = r.order_id
    WHERE r.cancellation IS NULL
),
exclusions_split AS (
    SELECT d.row_id,
        CAST(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(d.exclusions, ',', numbers.n), ',', -1)) AS UNSIGNED) AS topping_id
    FROM delivered_orders d
    JOIN numbers ON numbers.n <= 1 + LENGTH(d.exclusions) - LENGTH(REPLACE(d.exclusions, ',', ''))
    WHERE d.exclusions IS NOT NULL
),
extras_split AS (
    SELECT d.row_id,
        CAST(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(d.extras, ',', numbers.n), ',', -1)) AS UNSIGNED) AS topping_id
    FROM delivered_orders d
    JOIN numbers ON numbers.n <= 1 + LENGTH(d.extras) - LENGTH(REPLACE(d.extras, ',', ''))
    WHERE d.extras IS NOT NULL
),
order_toppings AS (
    SELECT d.row_id, bt.topping_id
    FROM delivered_orders d
    JOIN base_toppings bt ON bt.pizza_id = d.pizza_id
    WHERE NOT EXISTS (
        SELECT 1 FROM exclusions_split ex WHERE ex.row_id = d.row_id AND ex.topping_id = bt.topping_id
    )
    UNION ALL
    SELECT row_id, topping_id FROM extras_split
)
SELECT pt.topping_name, COUNT(*) AS total_quantity
FROM order_toppings ot
JOIN pizza_toppings pt ON pt.topping_id = ot.topping_id
GROUP BY pt.topping_name
ORDER BY total_quantity DESC;