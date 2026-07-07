-- Run each statement in Snowsight; download results as CSV for Tableau Public.
-- Record the row counts and export date — they belong in the README and on
-- the dashboard caption.

USE DATABASE OLIST_DB;

-- Tab 1 source
SELECT * FROM STAGING_marts.mart_daily_revenue ORDER BY order_date;

-- Tab 2 source
SELECT * FROM STAGING_marts.mart_customer_lifetime_value;

-- Tab 3 source
SELECT * FROM STAGING_marts.mart_seller_performance;

-- Row-count record (paste output into README data notes):
SELECT 'mart_daily_revenue' AS mart, COUNT(*) AS n FROM STAGING_marts.mart_daily_revenue
UNION ALL
SELECT 'mart_customer_lifetime_value', COUNT(*) FROM STAGING_marts.mart_customer_lifetime_value
UNION ALL
SELECT 'mart_seller_performance', COUNT(*) FROM STAGING_marts.mart_seller_performance;
