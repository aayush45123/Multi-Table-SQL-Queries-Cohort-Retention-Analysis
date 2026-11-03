-- STEP 1: Customer acquisition cohort

WITH customer_first_purchase AS (
    SELECT
        c.customer_unique_id,
        MIN(o.order_purchase_timestamp) AS first_purchase_date
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp IS NOT NULL
    GROUP BY c.customer_unique_id
)

SELECT
    customer_unique_id,
    first_purchase_date,
    DATE_TRUNC('month', first_purchase_date)::DATE
        AS cohort_month
FROM customer_first_purchase
ORDER BY first_purchase_date
LIMIT 20;


-- STEP 2: Monthly customer activity

SELECT
    c.customer_unique_id,
    DATE_TRUNC(
        'month',
        o.order_purchase_timestamp
    )::DATE AS purchase_month,

    COUNT(DISTINCT o.order_id) AS total_orders

FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id

WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp IS NOT NULL

GROUP BY
    c.customer_unique_id,
    DATE_TRUNC('month', o.order_purchase_timestamp)

ORDER BY
    c.customer_unique_id,
    purchase_month;


-- STEP 3: Monthly cohort retention analysis

WITH customer_first_purchase AS (

    SELECT
        c.customer_unique_id,
        MIN(o.order_purchase_timestamp) AS first_purchase_date

    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id

    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp IS NOT NULL

    GROUP BY c.customer_unique_id
),

cohort_data AS (

    SELECT
        customer_unique_id,

        DATE_TRUNC(
            'month',
            first_purchase_date
        )::DATE AS cohort_month

    FROM customer_first_purchase
),

customer_activity AS (

    SELECT DISTINCT
        c.customer_unique_id,

        DATE_TRUNC(
            'month',
            o.order_purchase_timestamp
        )::DATE AS activity_month

    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id

    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp IS NOT NULL
),

cohort_activity AS (

    SELECT
        cd.cohort_month,
        ca.activity_month,

        (
            EXTRACT(YEAR FROM ca.activity_month) * 12
            + EXTRACT(MONTH FROM ca.activity_month)
        ) -
        (
            EXTRACT(YEAR FROM cd.cohort_month) * 12
            + EXTRACT(MONTH FROM cd.cohort_month)
        ) AS month_number,

        cd.customer_unique_id

    FROM cohort_data cd

    JOIN customer_activity ca
        ON cd.customer_unique_id = ca.customer_unique_id

    WHERE ca.activity_month >= cd.cohort_month
),

cohort_sizes AS (

    SELECT
        cohort_month,
        COUNT(DISTINCT customer_unique_id) AS cohort_size

    FROM cohort_data

    GROUP BY cohort_month
),

retention_data AS (

    SELECT
        cohort_month,
        month_number,
        COUNT(DISTINCT customer_unique_id) AS active_customers

    FROM cohort_activity

    GROUP BY cohort_month, month_number
)

SELECT
    rd.cohort_month,
    rd.month_number,
    cs.cohort_size,
    rd.active_customers,

    ROUND(
        100.0 * rd.active_customers /
        NULLIF(cs.cohort_size, 0),
        2
    ) AS retention_percentage

FROM retention_data rd

JOIN cohort_sizes cs
    ON rd.cohort_month = cs.cohort_month

ORDER BY
    rd.cohort_month,
    rd.month_number;



-- STEP 4: Cohort retention matrix
-- Convert monthly retention rows into columns

WITH customer_first_purchase AS (
    SELECT
        c.customer_unique_id,
        MIN(o.order_purchase_timestamp) AS first_purchase_date
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),

cohort_data AS (
    SELECT
        customer_unique_id,
        DATE_TRUNC('month', first_purchase_date)::DATE
            AS cohort_month
    FROM customer_first_purchase
),

customer_activity AS (
    SELECT DISTINCT
        c.customer_unique_id,
        DATE_TRUNC('month', o.order_purchase_timestamp)::DATE
            AS activity_month
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
),

cohort_activity AS (
    SELECT
        cd.cohort_month,
        ca.customer_unique_id,
        (
            EXTRACT(YEAR FROM ca.activity_month) * 12
            + EXTRACT(MONTH FROM ca.activity_month)
        ) -
        (
            EXTRACT(YEAR FROM cd.cohort_month) * 12
            + EXTRACT(MONTH FROM cd.cohort_month)
        ) AS month_number
    FROM cohort_data cd
    JOIN customer_activity ca
        ON cd.customer_unique_id = ca.customer_unique_id
    WHERE ca.activity_month >= cd.cohort_month
),

cohort_sizes AS (
    SELECT
        cohort_month,
        COUNT(*) AS cohort_size
    FROM cohort_data
    GROUP BY cohort_month
),

retention AS (
    SELECT
        cohort_month,
        month_number,
        COUNT(DISTINCT customer_unique_id) AS active_customers
    FROM cohort_activity
    GROUP BY cohort_month, month_number
)

SELECT
    r.cohort_month,
    cs.cohort_size,

    ROUND(100.0 * MAX(r.active_customers)
        FILTER (WHERE month_number = 0) / cs.cohort_size, 2)
        AS month_0,

    ROUND(100.0 * MAX(r.active_customers)
        FILTER (WHERE month_number = 1) / cs.cohort_size, 2)
        AS month_1,

    ROUND(100.0 * MAX(r.active_customers)
        FILTER (WHERE month_number = 2) / cs.cohort_size, 2)
        AS month_2,

    ROUND(100.0 * MAX(r.active_customers)
        FILTER (WHERE month_number = 3) / cs.cohort_size, 2)
        AS month_3,

    ROUND(100.0 * MAX(r.active_customers)
        FILTER (WHERE month_number = 4) / cs.cohort_size, 2)
        AS month_4,

    ROUND(100.0 * MAX(r.active_customers)
        FILTER (WHERE month_number = 5) / cs.cohort_size, 2)
        AS month_5,

    ROUND(100.0 * MAX(r.active_customers)
        FILTER (WHERE month_number = 6) / cs.cohort_size, 2)
        AS month_6,

    ROUND(100.0 * MAX(r.active_customers)
        FILTER (WHERE month_number = 7) / cs.cohort_size, 2)
        AS month_7,

    ROUND(100.0 * MAX(r.active_customers)
        FILTER (WHERE month_number = 8) / cs.cohort_size, 2)
        AS month_8,

    ROUND(100.0 * MAX(r.active_customers)
        FILTER (WHERE month_number = 9) / cs.cohort_size, 2)
        AS month_9,

    ROUND(100.0 * MAX(r.active_customers)
        FILTER (WHERE month_number = 10) / cs.cohort_size, 2)
        AS month_10,

    ROUND(100.0 * MAX(r.active_customers)
        FILTER (WHERE month_number = 11) / cs.cohort_size, 2)
        AS month_11,

    ROUND(100.0 * MAX(r.active_customers)
        FILTER (WHERE month_number = 12) / cs.cohort_size, 2)
        AS month_12

FROM retention r
JOIN cohort_sizes cs
    ON r.cohort_month = cs.cohort_month

GROUP BY r.cohort_month, cs.cohort_size
ORDER BY r.cohort_month;


--A. Which cohorts have the highest Month 1 retention?
WITH first_purchase AS (
    SELECT
        c.customer_unique_id,
        MIN(o.order_purchase_timestamp) AS first_date
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
activity AS (
    SELECT DISTINCT
        c.customer_unique_id,
        DATE_TRUNC('month', o.order_purchase_timestamp)::DATE
            AS activity_month
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
),
cohorts AS (
    SELECT
        customer_unique_id,
        DATE_TRUNC('month', first_date)::DATE AS cohort_month
    FROM first_purchase
)
SELECT
    cd.cohort_month,
    COUNT(DISTINCT cd.customer_unique_id) AS cohort_size,
    COUNT(DISTINCT ca.customer_unique_id) AS month_1_customers,
    ROUND(
        100.0 * COUNT(DISTINCT ca.customer_unique_id)
        / NULLIF(COUNT(DISTINCT cd.customer_unique_id), 0),
        2
    ) AS month_1_retention
FROM cohorts cd
LEFT JOIN activity ca
    ON cd.customer_unique_id = ca.customer_unique_id
    AND ca.activity_month =
        (cd.cohort_month + INTERVAL '1 month')::DATE
GROUP BY cd.cohort_month
ORDER BY month_1_retention DESC NULLS LAST;


--B. Overall repeat customer percentage
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT
    COUNT(*) AS total_customers,
    COUNT(*) FILTER (
        WHERE order_count > 1
    ) AS repeat_customers,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE order_count > 1
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS repeat_customer_percentage
FROM customer_orders;