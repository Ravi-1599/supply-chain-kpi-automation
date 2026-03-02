DROP TABLE IF EXISTS fact_order_line;

CREATE TABLE fact_order_line AS
SELECT
  row_number() OVER () AS order_line_id,
  order_id::TEXT,
  customer_id::TEXT,
  product_id::TEXT,
  to_date(order_placement_date, 'DD-MM-YYYY') AS order_placement_date,
  to_date(agreed_delivery_date, 'DD-MM-YYYY') AS agreed_delivery_date,
  to_date(actual_delivery_date, 'DD-MM-YYYY') AS actual_delivery_date,
  order_qty::NUMERIC,
  delivery_qty::NUMERIC,
  (to_date(actual_delivery_date, 'DD-MM-YYYY') <= to_date(agreed_delivery_date, 'DD-MM-YYYY')) AS on_time,
  (delivery_qty::NUMERIC >= order_qty::NUMERIC) AS in_full,
  (
    to_date(actual_delivery_date, 'DD-MM-YYYY') <= to_date(agreed_delivery_date, 'DD-MM-YYYY')
    AND delivery_qty::NUMERIC >= order_qty::NUMERIC
  ) AS otif
FROM stg_fact_order_line
WHERE order_qty IS NOT NULL
  AND delivery_qty IS NOT NULL
  AND agreed_delivery_date IS NOT NULL;


SELECT COUNT(*) FROM fact_order_line;
SELECT MIN(order_placement_date), MAX(order_placement_date) FROM fact_order_line;



--let’s do B2: clean + create fact_aggregate the right way (IDs as TEXT + date parsing + boolean cleanup).

DROP TABLE IF EXISTS fact_aggregate;

CREATE TABLE fact_aggregate AS
SELECT DISTINCT ON (order_id)
  order_id::TEXT    AS order_id,
  customer_id::TEXT AS customer_id,

  -- parse DD-MM-YYYY safely
  to_date(order_placement_date, 'DD-MM-YYYY') AS order_placement_date,

  -- normalize booleans
  CASE
    WHEN lower(on_time) IN ('1','true','t','yes','y') THEN TRUE
    WHEN lower(on_time) IN ('0','false','f','no','n') THEN FALSE
    ELSE NULL
  END AS on_time,

  CASE
    WHEN lower(in_full) IN ('1','true','t','yes','y') THEN TRUE
    WHEN lower(in_full) IN ('0','false','f','no','n') THEN FALSE
    ELSE NULL
  END AS in_full,

  CASE
    WHEN lower(otif) IN ('1','true','t','yes','y') THEN TRUE
    WHEN lower(otif) IN ('0','false','f','no','n') THEN FALSE
    ELSE NULL
  END AS otif

FROM stg_fact_aggregate
WHERE order_id IS NOT NULL
ORDER BY order_id, to_date(order_placement_date, 'DD-MM-YYYY') DESC;
--check 

SELECT COUNT(*) FROM fact_aggregate;
SELECT * FROM fact_aggregate LIMIT 10;
--checking date range

SELECT MIN(order_placement_date), MAX(order_placement_date)
FROM fact_aggregate;

--checking if boolens became NULL (uexpected values)
SELECT
  SUM(CASE WHEN on_time IS NULL THEN 1 ELSE 0 END) AS null_on_time,
  SUM(CASE WHEN in_full IS NULL THEN 1 ELSE 0 END) AS null_in_full,
  SUM(CASE WHEN otif IS NULL THEN 1 ELSE 0 END) AS null_otif
FROM fact_aggregate;

-- moving raw data into different schema
CREATE SCHEMA staging;
ALTER TABLE stg_fact_order_line SET SCHEMA staging;
ALTER TABLE stg_fac SET SCHEMA staging;

--we are deleting the the data within the stg dim because uploaded wrong data in that
TRUNCATE TABLE stg_dim_products;

--checking the products 
SELECT COUNT(*) FROM stg_dim_products;
SELECT * FROM stg_dim_products LIMIT 5;

TRUNCATE TABLE stg_dim_targets_orders;

SELECT COUNT(*) FROM stg_dim_targets_orders;
SELECT * FROM stg_dim_targets_orders LIMIT 5;
-- everything is working fine 

--let's make KPI's 
-- Monthly KPI view from fact_order_line
-- The positions (1, 2) refer to the order in the SELECT list, not to column positions in the table.
-- Take this number and make it a decimal with up to 10 total digits, 4 of which are after the decimal point."

CREATE OR REPLACE VIEW v_kpi_customer_month AS
SELECT
  date_trunc('month', order_placement_date)::date AS month,
  customer_id,

  COUNT(*)::int AS total_order_lines,
  COUNT(DISTINCT order_id)::int AS total_orders,

  -- Line Fill Rate (lines fully delivered / total lines)
  AVG(CASE WHEN in_full THEN 1 ELSE 0 END)::numeric(10,4) AS line_fill_rate,

  -- Volume Fill Rate (delivered qty / ordered qty)
  (SUM(delivery_qty) / NULLIF(SUM(order_qty),0))::numeric(10,4) AS volume_fill_rate,

  -- On Time %
  AVG(CASE WHEN on_time THEN 1 ELSE 0 END)::numeric(10,4) AS on_time_pct,

  -- In Full %
  AVG(CASE WHEN in_full THEN 1 ELSE 0 END)::numeric(10,4) AS in_full_pct,

  -- OTIF %
  AVG(CASE WHEN otif THEN 1 ELSE 0 END)::numeric(10,4) AS otif_pct

FROM fact_order_line
GROUP BY 1,2;

--This compares actual performance vs your dim_targets_orders.
--C2 
DROP VIEW IF EXISTS v_kpi_vs_target;


CREATE VIEW v_kpi_vs_target AS
SELECT
  k.month,
  k.customer_id,
  c.customer_name,

  k.total_orders,
  k.total_order_lines,

  ROUND(k.line_fill_rate, 3)::numeric(10,3)   AS line_fill_rate,
  ROUND(k.volume_fill_rate, 3)::numeric(10,3) AS volume_fill_rate,
  ROUND(k.on_time_pct, 3)::numeric(10,3)      AS on_time_pct,
  ROUND(k.in_full_pct, 3)::numeric(10,3)      AS in_full_pct,
  ROUND(k.otif_pct, 3)::numeric(10,3)         AS otif_pct,

  ROUND(t.ontime_target, 3)::numeric(10,3) AS ontime_target,
  ROUND(t.infull_target, 3)::numeric(10,3) AS infull_target,
  ROUND(t.otif_target, 3)::numeric(10,3)   AS otif_target,

  (k.on_time_pct >= t.ontime_target) AS meet_on_time,
  (k.in_full_pct >= t.infull_target) AS meet_in_full,
  (k.otif_pct    >= t.otif_target)   AS meet_otif

FROM v_kpi_customer_month k
LEFT JOIN dim_customers c
  ON TRIM(c.customer_id::text) = TRIM(k.customer_id::text)
LEFT JOIN dim_targets_orders t
  ON TRIM(t.customer_id::text) = TRIM(k.customer_id::text);


--confirming that dim targets orders work 
SELECT COUNT(*) FROM dim_targets_orders;
SELECT * FROM dim_targets_orders LIMIT 5;

--staging dim data recreate 
DROP TABLE IF EXISTS dim_targets_orders;

CREATE TABLE dim_targets_orders AS
SELECT
  TRIM(customer_id)::text AS customer_id,
  (TRIM("ontime_target%")::numeric / 100.0) AS ontime_target,
  (TRIM("infull_target%")::numeric / 100.0) AS infull_target,
  (TRIM("otif_target%")::numeric / 100.0)   AS otif_target
FROM stg_dim_targets_orders
WHERE customer_id IS NOT NULL;

--INSERTING DATA INTO IT 
INSERT INTO dim_targets_orders (customer_id, ontime_target, infull_target, otif_target)
SELECT
  TRIM(customer_id)::integer,
  (TRIM("ontime_target%")::numeric / 100.0),
  (TRIM("infull_target%")::numeric / 100.0),
  (TRIM("otif_target%")::numeric / 100.0)
FROM stg_dim_targets_orders
WHERE customer_id IS NOT NULL;

SELECT COUNT(*) FROM dim_targets_orders;
SELECT * FROM dim_targets_orders LIMIT 10;

-----------------------------------------------------------------------------------
SELECT COUNT(*) FROM dim_customers;
SELECT * FROM dim_customers LIMIT 5;

-- populating dim customers 
TRUNCATE TABLE dim_customers;

INSERT INTO dim_customers (customer_id, customer_name, city, currency)
SELECT DISTINCT
  TRIM(customer_id)::integer,
  TRIM(customer_name),
  TRIM(city),
  TRIM(currency)
FROM stg_dim_customers
WHERE customer_id IS NOT NULL;

-- verifying the data 
SELECT COUNT(*) FROM dim_customers;
SELECT * FROM dim_customers LIMIT 10;

SELECT customer_id, customer_name
FROM v_kpi_vs_target
ORDER BY month DESC
LIMIT 20;

SELECT COUNT(*) FROM v_kpi_vs_target;
SELECT * FROM v_kpi_vs_target ORDER BY month DESC LIMIT 5;

----------------------------------------------------------------------------------------------------
--N8N Automation

-- 1. Create user
CREATE USER n8n_user WITH PASSWORD 'Patidar@123';

-- 2. Allow connection to your database
GRANT CONNECT ON DATABASE demo TO n8n_user;

-- 3. Allow schema access
GRANT USAGE ON SCHEMA public TO n8n_user;

-- 4. Allow read-only access
GRANT SELECT ON ALL TABLES IN SCHEMA public TO n8n_user;

-- 5. Auto-grant SELECT on future tables/views
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT ON TABLES TO n8n_user;

SELECT current_database();
--VALIDATING ID THE CONNECTIONS HAS BEEN MADE
SELECT current_user, current_database();




