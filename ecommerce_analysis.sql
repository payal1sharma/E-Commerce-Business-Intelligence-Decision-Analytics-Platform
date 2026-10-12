
-- ============================================================
-- E-COMMERCE PROJECT
-- ============================================================


-- 1. TABLE ROW COUNTS
-- Verify that all 9 dataset tables contain the expected rows.

SELECT 'customers' AS table_name, COUNT(*) AS total_rows FROM customers
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'payments', COUNT(*) FROM payments
UNION ALL
SELECT 'reviews', COUNT(*) FROM reviews
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL
SELECT 'geolocation', COUNT(*) FROM geolocation
UNION ALL
SELECT 'category_translation', COUNT(*) FROM category_translation;


-- ============================================================
-- 2. NULL CHECKS FOR IMPORTANT ID COLUMNS
-- Expected: issue_count = 0 for every check.
-- ============================================================

SELECT 'customers: NULL customer_id' AS validation,
       COUNT(*) AS issue_count
FROM customers
WHERE customer_id IS NULL

UNION ALL
SELECT 'orders: NULL order_id', COUNT(*)
FROM orders
WHERE order_id IS NULL

UNION ALL
SELECT 'orders: NULL customer_id', COUNT(*)
FROM orders
WHERE customer_id IS NULL

UNION ALL
SELECT 'order_items: NULL order_id', COUNT(*)
FROM order_items
WHERE order_id IS NULL

UNION ALL
SELECT 'order_items: NULL product_id', COUNT(*)
FROM order_items
WHERE product_id IS NULL

UNION ALL
SELECT 'order_items: NULL seller_id', COUNT(*)
FROM order_items
WHERE seller_id IS NULL

UNION ALL
SELECT 'payments: NULL order_id', COUNT(*)
FROM payments
WHERE order_id IS NULL

UNION ALL
SELECT 'products: NULL product_id', COUNT(*)
FROM products
WHERE product_id IS NULL

UNION ALL
SELECT 'sellers: NULL seller_id', COUNT(*)
FROM sellers
WHERE seller_id IS NULL;


-- ============================================================
-- 3. DUPLICATE PRIMARY / COMPOSITE KEY CHECKS
-- Expected: duplicate_count = 0 for every check.
-- ============================================================

SELECT 'customers: duplicate customer_id' AS validation,
       COUNT(*) - COUNT(DISTINCT customer_id) AS duplicate_count
FROM customers

UNION ALL
SELECT 'orders: duplicate order_id',
       COUNT(*) - COUNT(DISTINCT order_id)
FROM orders

UNION ALL
SELECT 'products: duplicate product_id',
       COUNT(*) - COUNT(DISTINCT product_id)
FROM products

UNION ALL
SELECT 'sellers: duplicate seller_id',
       COUNT(*) - COUNT(DISTINCT seller_id)
FROM sellers

UNION ALL
SELECT 'order_items: duplicate order_id + order_item_id',
       COUNT(*) - (
           SELECT COUNT(*)
           FROM (
               SELECT DISTINCT order_id, order_item_id
               FROM order_items
           )
       )
FROM order_items;


-- ============================================================
-- 4. FOREIGN KEY / ORPHAN RECORD CHECKS
-- Expected: issue_count = 0 for every check.
-- ============================================================

SELECT 'Orders with missing customer' AS validation,
       COUNT(*) AS issue_count
FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL

UNION ALL
SELECT 'Order items with missing order',
       COUNT(*)
FROM order_items oi
LEFT JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL
SELECT 'Order items with missing product',
       COUNT(*)
FROM order_items oi
LEFT JOIN products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL

UNION ALL
SELECT 'Order items with missing seller',
       COUNT(*)
FROM order_items oi
LEFT JOIN sellers s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL

UNION ALL
SELECT 'Payments with missing order',
       COUNT(*)
FROM payments p
LEFT JOIN orders o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL;


-- ============================================================
-- 5. CORE BUSINESS METRICS
-- ============================================================

SELECT 'Total Orders' AS metric,
       COUNT(DISTINCT order_id) AS metric_value
FROM orders

UNION ALL
SELECT 'Unique Customers',
       COUNT(DISTINCT customer_unique_id)
FROM customers

UNION ALL
SELECT 'Total Payment Records',
       COUNT(*)
FROM payments

UNION ALL
SELECT 'Total Order Items',
       COUNT(*)
FROM order_items

UNION ALL
SELECT 'Total Reviews',
       COUNT(*)
FROM reviews;


-- ============================================================
-- 6. PAYMENT VALUE VALIDATION
-- ============================================================

SELECT
    COUNT(*) AS payment_records,
    ROUND(SUM(payment_value), 2) AS total_payment_value,
    ROUND(AVG(payment_value), 2) AS avg_payment_record_value
FROM payments;


-- ============================================================
-- 7. REVIEW SCORE DISTRIBUTION
-- ============================================================

SELECT
    review_score,
    COUNT(*) AS review_count
FROM reviews
GROUP BY review_score
ORDER BY review_score;


-- ============================================================
-- 8. REVIEW DATA QUALITY CHECK
-- ============================================================

SELECT
    COUNT(*) AS total_reviews,
    COUNT(DISTINCT review_id) AS unique_review_ids,
    COUNT(DISTINCT order_id) AS unique_orders_reviewed,
    SUM(
        CASE
            WHEN review_score NOT BETWEEN 1 AND 5
                 OR review_score IS NULL
            THEN 1
            ELSE 0
        END
    ) AS invalid_scores
FROM reviews;


-- ============================================================
-- 9. FIND REPEATED REVIEW IDs
-- Repeated IDs are flagged for investigation, not deletion.
-- ============================================================

SELECT
    review_id,
    COUNT(*) AS occurrences
FROM reviews
GROUP BY review_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC
LIMIT 20;


-- ============================================================
-- 10. CHECK MISSING REVIEW IDs AND SCORES
-- Expected: both counts = 0.
-- ============================================================

SELECT
    SUM(
        CASE
            WHEN review_id IS NULL OR TRIM(review_id) = ''
            THEN 1
            ELSE 0
        END
    ) AS missing_review_ids,
    SUM(
        CASE
            WHEN review_score IS NULL
            THEN 1
            ELSE 0
        END
    ) AS missing_review_scores
FROM reviews;


-- ============================================================
-- 11. CHECK FULLY IDENTICAL REVIEW ROWS
-- Checks all seven review columns together.
-- Expected: zero rows returned.
-- ============================================================

SELECT
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp,
    COUNT(*) AS identical_row_count
FROM reviews
GROUP BY
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
HAVING COUNT(*) > 1
ORDER BY identical_row_count DESC
LIMIT 20;


-- ============================================================
-- 12. ORDER STATUS DISTRIBUTION
-- Shows order counts and percentage of all orders.
-- ============================================================

SELECT
    order_status,
    COUNT(*) AS total_orders,
    ROUND(
        100.0 * COUNT(*) / (SELECT COUNT(*) FROM orders),
        2
    ) AS percentage
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;
