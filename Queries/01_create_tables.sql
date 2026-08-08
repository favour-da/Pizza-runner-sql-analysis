USE pizza_runner;

CREATE TABLE runners (
    runner_id INT,
    registration_date DATE
);

CREATE TABLE customer_orders (
    order_id INT,
    customer_id INT,
    pizza_id INT,
    exclusions VARCHAR(4),
    extras VARCHAR(4),
    order_time DATETIME
);

CREATE TABLE runner_orders (
    order_id INT,
    runner_id INT,
    pickup_time VARCHAR(19),
    distance VARCHAR(7),
    duration VARCHAR(10),
    cancellation VARCHAR(23)
);

CREATE TABLE pizza_names (
    pizza_id INT,
    pizza_name TEXT
);

CREATE TABLE pizza_recipes (
    pizza_id INT,
    toppings TEXT
);

CREATE TABLE pizza_toppings (
    topping_id INT,
    topping_name TEXT
);