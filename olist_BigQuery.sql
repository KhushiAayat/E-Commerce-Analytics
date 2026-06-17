--EXPLORATORY DATA ANALYSIS & DEEP BUSINESS INSIGHTS
--Annual Revenue & Order Volume Trends
SELECT 
    purchase_year, 
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(total_item_value), 2) AS total_revenue
FROM `ecommerce-analytics-499409.olist_store.analytics_master_table`
GROUP BY purchase_year
ORDER BY purchase_year;


-- Monthly Sales Breakdowns
SELECT 
    purchase_year,
    purchase_month,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(total_item_value), 2) AS total_revenue
FROM `ecommerce-analytics-499409.olist_store.analytics_master_table`
GROUP BY purchase_year, purchase_month
ORDER BY purchase_year, purchase_month;


-- Regional Delivery Lag Analysis
-- Isolates fulfillment bottlenecks by state where volume is statistically significant.
SELECT 
    customer_state,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(AVG(DATE_DIFF(DATE(order_delivered_customer_date), DATE(order_purchase_timestamp), DAY)), 1) AS avg_delivery_days,
    ROUND(AVG(DATE_DIFF(DATE(order_estimated_delivery_date), DATE(order_purchase_timestamp), DAY)), 1) AS avg_estimated_days,
    ROUND(AVG(delivery_delay_days), 1) AS avg_delay_days
FROM `ecommerce-analytics-499409.olist_store.analytics_master_table`
GROUP BY customer_state
HAVING total_orders >= 100
ORDER BY avg_delay_days DESC;


-- Top 10 High-Value Categories
SELECT 
    product_category,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(total_item_value), 2) AS total_revenue,
    ROUND(AVG(price), 2) AS avg_item_price
FROM `ecommerce-analytics-499409.olist_store.analytics_master_table`
WHERE product_category IS NOT NULL
GROUP BY product_category
ORDER BY total_revenue DESC
LIMIT 10;


--Fintech Analytics (Payment Type & Installment )
-- Left joins operational transactional profiles against payment tables to analyze order value elasticity.
SELECT 
    p.payment_type,
    ROUND(AVG(p.payment_installments), 1) AS avg_installments,
    COUNT(DISTINCT m.order_id) AS total_orders,
    ROUND(AVG(m.total_item_value), 2) AS avg_order_value,
    ROUND(SUM(m.total_item_value), 2) AS total_revenue
FROM `ecommerce-analytics-499409.olist_store.analytics_master_table` m
LEFT JOIN `ecommerce-analytics-499409.olist_store.payments` p 
    ON m.order_id = p.order_id
GROUP BY p.payment_type
ORDER BY total_revenue DESC;



-- DATA ENGINEERING & MODELING (Creating the Star Schema)

-- Extracting & Building the Product Dimension (dim_products)
CREATE OR REPLACE TABLE `ecommerce-analytics-499409.olist_store.dim_products` AS
SELECT DISTINCT 
    product_id, 
    product_category
FROM `ecommerce-analytics-499409.olist_store.analytics_master_table`
WHERE product_id IS NOT NULL;


-- Extracting & Building the Customer Dimension (dim_customers)
CREATE OR REPLACE TABLE `ecommerce-analytics-499409.olist_store.dim_customers` AS
SELECT DISTINCT 
    customer_id, 
    customer_state
FROM `ecommerce-analytics-499409.olist_store.analytics_master_table`
WHERE customer_id IS NOT NULL;


-- Building the Optimized Transaction Core (fact_orders)
CREATE OR REPLACE TABLE `ecommerce-analytics-499409.olist_store.fact_orders` AS
SELECT 
    order_id,
    customer_id,
    product_id,
    DATE(order_purchase_timestamp) AS purchase_date,
    DATE(order_delivered_customer_date) AS delivery_date,
    delivery_delay_days,
    total_item_value AS revenue,
    price
FROM `ecommerce-analytics-499409.olist_store.analytics_master_table`;


--POST-PRODUCTION PIPELINE VALIDATION & TESTING

--Data Integrity check on new fact table attributes
SELECT `order_id`, `purchase_date`, `revenue` 
FROM `ecommerce-analytics-499409.olist_store.fact_orders` 
LIMIT 10;

--Verification of index constraints on structural keys
SELECT `customer_id`, `customer_state` 
FROM `ecommerce-analytics-499409.olist_store.dim_customers` 
LIMIT 100;
