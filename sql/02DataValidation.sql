-- 1. Check duplicate customer IDs
SELECT customer_id, COUNT(*)
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- 2. Check duplicate order IDs
SELECT order_id, COUNT(*)
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- 3. Check orders without customers
SELECT COUNT(*) AS orphan_orders
FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- 4. Check orders without order items
SELECT COUNT(*) AS orders_without_items
FROM orders o
LEFT JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL;

-- 5. Check invalid review scores
SELECT COUNT(*) AS invalid_reviews
FROM reviews
WHERE review_score NOT BETWEEN 1 AND 5;

-- 6. Check negative product prices
SELECT COUNT(*) AS negative_prices
FROM order_items
WHERE price < 0;

-- 7. Check missing purchase timestamps
SELECT COUNT(*) AS missing_purchase_dates
FROM orders
WHERE order_purchase_timestamp IS NULL;
