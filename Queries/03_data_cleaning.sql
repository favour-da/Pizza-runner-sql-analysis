DROP TABLE IF EXISTS customer_orders_clean;
CREATE TABLE customer_orders_clean AS
SELECT
    ROW_NUMBER() OVER () AS row_id,
    order_id,
    customer_id,
    pizza_id,
    CASE 
        WHEN exclusions IS NULL OR exclusions IN ('', 'null', 'NaN') THEN NULL 
		ELSE exclusions END AS exclusions,
    CASE 
        WHEN extras IS NULL OR extras IN ('', 'null', 'NaN') THEN NULL 
        ELSE extras END AS extras,
    order_time
FROM customer_orders;

DROP TABLE IF EXISTS runner_orders_clean;
CREATE TABLE runner_orders_clean AS
SELECT
    order_id,
    runner_id,
    CASE
        WHEN pickup_time = 'null' THEN NULL
        WHEN order_id IN (7, 8, 10) THEN CAST(REPLACE(pickup_time, '2020', '2021') AS DATETIME)
        ELSE CAST(pickup_time AS DATETIME)
    END AS pickup_time,
    CASE
        WHEN distance IS NULL OR distance IN ('', 'null') THEN NULL
        ELSE CAST(REGEXP_REPLACE(distance, '[a-zA-Z ]', '') AS DECIMAL(5,2))
    END AS distance,
    CASE
        WHEN duration IS NULL OR duration IN ('', 'null') THEN NULL
        ELSE CAST(REGEXP_REPLACE(duration, '[a-zA-Z ]', '') AS UNSIGNED)
    END AS duration,
    CASE
        WHEN cancellation IS NULL OR cancellation IN ('', 'null', 'NaN') THEN NULL
        ELSE cancellation
    END AS cancellation
FROM runner_orders;
