-- =====================================================
-- E-COMMERCE CUSTOMER & PRODUCT ANALYTICS PROJECT
-- Dataset: Online Retail II (~1M rows)
-- =====================================================


-- =====================================================
-- 1. TOP 10 REVENUE-GENERATING PRODUCTS
-- =====================================================

WITH product_metrics AS (
    SELECT 
        description AS product_description,
        SUM(quantity) AS total_quantity,
        SUM(quantity * unit_price) AS total_revenue,
        COUNT(DISTINCT customer_id) AS unique_customers
    FROM retail_clean
    WHERE description IS NOT NULL
    GROUP BY description
),
ranked_products AS (
    SELECT *,
           DENSE_RANK() OVER (ORDER BY total_revenue DESC) AS rank_by_revenue
    FROM product_metrics
)
SELECT *
FROM ranked_products
WHERE rank_by_revenue <= 10;



-- =====================================================
-- 2. MONTHLY REVENUE, ARPU & MoM GROWTH
-- =====================================================

WITH monthly_data AS (
    SELECT
        DATE_FORMAT(invoice_date, '%Y-%m') AS sale_month,
        SUM(quantity * unit_price) AS total_revenue,
        COUNT(DISTINCT customer_id) AS active_customers,
        SUM(quantity * unit_price) / COUNT(DISTINCT customer_id) AS arpu
    FROM retail_clean
    GROUP BY DATE_FORMAT(invoice_date, '%Y-%m')
),
growth_calc AS (
    SELECT *,
           (total_revenue - LAG(total_revenue) OVER (ORDER BY sale_month)) 
           / LAG(total_revenue) OVER (ORDER BY sale_month) 
           AS mom_revenue_growth
    FROM monthly_data
)
SELECT 
    sale_month,
    ROUND(total_revenue, 2) AS total_revenue,
    active_customers,
    ROUND(arpu, 2) AS arpu,
    ROUND(mom_revenue_growth * 100, 2) AS mom_revenue_growth_percent
FROM growth_calc
ORDER BY sale_month;



-- =====================================================
-- 3. TOP 5 CUSTOMERS BY LIFETIME VALUE
-- =====================================================

WITH customer_metrics AS (
    SELECT 
        customer_id,
        SUM(quantity * unit_price) AS total_revenue,
        COUNT(DISTINCT invoice_no) AS total_orders,
        ROUND(SUM(quantity * unit_price) / COUNT(DISTINCT invoice_no), 2) AS aov
    FROM retail_clean
    GROUP BY customer_id
),
ranked_customers AS (
    SELECT *,
           DENSE_RANK() OVER (ORDER BY total_revenue DESC) AS customer_rank
    FROM customer_metrics
)
SELECT *
FROM ranked_customers
WHERE customer_rank <= 5;



-- =====================================================
-- 4. REVENUE SHARE OF TOP 10% CUSTOMERS
-- =====================================================

WITH customer_metrics AS (
    SELECT 
        customer_id,
        SUM(revenue) AS total_revenue
    FROM retail_clean
    GROUP BY customer_id
),
ranked_customers AS (
    SELECT *,
           NTILE(10) OVER (ORDER BY total_revenue DESC) AS revenue_decile
    FROM customer_metrics
)
SELECT 
    ROUND(
        SUM(CASE WHEN revenue_decile = 1 THEN total_revenue END) 
        * 100.0 / SUM(total_revenue),
    2) AS revenue_share_top_10_percent
FROM ranked_customers;



-- =====================================================
-- 5. COHORT RETENTION ANALYSIS
-- =====================================================

WITH first_purchase_data AS (
    SELECT 
        customer_id,
        MIN(invoice_date) AS first_purchase
    FROM retail_clean
    GROUP BY customer_id
),
cohort_data AS (
    SELECT
        R.customer_id,
        DATE_FORMAT(F.first_purchase, '%Y-%m') AS cohort_month,
        TIMESTAMPDIFF(MONTH, F.first_purchase, R.invoice_date) AS month_diff
    FROM retail_clean R
    JOIN first_purchase_data F
        ON R.customer_id = F.customer_id
),
retention_counts AS (
    SELECT 
        cohort_month, 
        month_diff,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM cohort_data
    GROUP BY cohort_month, month_diff
),
cohort_size AS (
    SELECT 
        cohort_month,
        active_customers AS cohort_customers
    FROM retention_counts
    WHERE month_diff = 0
)
SELECT 
    r.cohort_month,
    r.month_diff,
    r.active_customers,
    ROUND(r.active_customers * 100.0 / c.cohort_customers, 2) AS retention_rate
FROM retention_counts r
JOIN cohort_size c
    ON r.cohort_month = c.cohort_month
ORDER BY r.cohort_month, r.month_diff;



-- =====================================================
-- 6. REPEAT PURCHASE RATE
-- =====================================================

WITH customer_data AS (
    SELECT 
        customer_id,
        COUNT(DISTINCT invoice_no) AS total_orders
    FROM retail_clean
    GROUP BY customer_id
)
SELECT 
    COUNT(*) AS total_customers,
    SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END) AS repeat_customers,
    ROUND(
        SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END) * 100.0 
        / COUNT(*), 
    2) AS repeat_purchase_percentage
FROM customer_data;



-- =====================================================
-- 7. AVERAGE DAYS BETWEEN ORDERS
-- =====================================================

WITH order_data AS (
    SELECT DISTINCT
        customer_id,
        invoice_no,
        invoice_date
    FROM retail_clean
),
order_lag AS (
    SELECT 
        customer_id,
        invoice_date,
        LAG(invoice_date) OVER (
            PARTITION BY customer_id 
            ORDER BY invoice_date
        ) AS previous_order_date
    FROM order_data
),
order_diff AS (
    SELECT 
        DATEDIFF(invoice_date, previous_order_date) AS diff
    FROM order_lag
)
SELECT 
    AVG(diff) AS average_days_between_orders
FROM order_diff
WHERE diff IS NOT NULL;



-- =====================================================
-- 8. ORDER RETURN RATE
-- =====================================================

WITH invoice_status AS (
    SELECT 
        invoice_no,
        MAX(CASE 
            WHEN invoice_no LIKE 'C%' OR quantity < 0 
            THEN 1 ELSE 0 
        END) AS is_returned
    FROM retail_transactions
    GROUP BY invoice_no
)
SELECT
    COUNT(*) AS total_orders,
    SUM(is_returned) AS returned_orders,
    ROUND(SUM(is_returned) * 100.0 / COUNT(*), 2) AS return_rate
FROM invoice_status;



-- =====================================================
-- 9. PRODUCT RETURN RATE
-- =====================================================

SELECT 
    description AS product,
    SUM(CASE WHEN quantity > 0 THEN quantity ELSE 0 END) AS total_sold,
    SUM(CASE WHEN quantity < 0 THEN ABS(quantity) ELSE 0 END) AS total_returned,
    ROUND(
        SUM(CASE WHEN quantity < 0 THEN ABS(quantity) ELSE 0 END) * 100.0
        / NULLIF(SUM(CASE WHEN quantity > 0 THEN quantity ELSE 0 END), 0),
    2) AS return_rate
FROM retail_transactions
WHERE description IS NOT NULL
GROUP BY description
HAVING total_sold > 100
ORDER BY return_rate DESC;



-- =====================================================
-- 10. PARETO ANALYSIS (80/20 RULE)
-- =====================================================

WITH product_revenue AS (
    SELECT 
        description AS product,
        SUM(revenue) AS total_revenue
    FROM retail_clean
    WHERE description IS NOT NULL
    GROUP BY description
),
cumulative_calc AS (
    SELECT 
        product,
        total_revenue,
        SUM(total_revenue) OVER (ORDER BY total_revenue DESC) AS cumulative_revenue,
        SUM(total_revenue) OVER () AS overall_revenue
    FROM product_revenue
)
SELECT 
    COUNT(*) AS products_contributing_80_percent
FROM cumulative_calc
WHERE cumulative_revenue * 100.0 / overall_revenue <= 80;



-- =====================================================
-- 11. RFM SEGMENTATION
-- =====================================================

WITH rfm_base AS (
    SELECT 
        customer_id,
        DATEDIFF('2011-12-31', MAX(invoice_date)) AS recency,
        COUNT(DISTINCT invoice_no) AS frequency,
        SUM(revenue) AS monetary
    FROM retail_clean
    GROUP BY customer_id
),
rfm_scores AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recency ASC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency DESC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary DESC) AS m_score
    FROM rfm_base
),
rfm_segments AS (
    SELECT *,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal Customers'
            WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
            WHEN r_score = 1 AND f_score = 1 THEN 'Hibernating'
            ELSE 'Potential'
        END AS customer_segment
    FROM rfm_scores
)
SELECT 
    customer_segment,
    COUNT(*) AS number_of_customers,
    ROUND(SUM(monetary), 2) AS total_revenue,
    ROUND(AVG(monetary), 2) AS avg_revenue
FROM rfm_segments
GROUP BY customer_segment
ORDER BY total_revenue DESC;
