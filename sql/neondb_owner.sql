DROP TABLE IF EXISTS public.dim_customers;

CREATE TABLE public.dim_customers (
  customer_id integer NOT NULL,
  customer_name varchar(255),
  city varchar(255),
  currency varchar(10),
  CONSTRAINT dim_customers_pkey PRIMARY KEY (customer_id)
);

--------------------------------------------------------------

DROP TABLE IF EXISTS public.dim_products;

CREATE TABLE public.dim_products (
  product_id   text PRIMARY KEY,
  product_name varchar(255),
  category     varchar(255),
  price_inr    numeric,
  price_usd    numeric
);

SELECT COUNT(*) FROM public.dim_products;
SELECT * FROM public.dim_products LIMIT 5;

---------------------------------------------------------------

DROP TABLE IF EXISTS public.dim_targets_orders;

CREATE TABLE public.dim_targets_orders (
  customer_id    text PRIMARY KEY,
  ontime_target  numeric,
  infull_target  numeric,
  otif_target    numeric
);

SELECT COUNT(*) FROM public.dim_targets_orders;
SELECT * FROM public.dim_targets_orders LIMIT 5;

---------------------------------------------------------------

DROP TABLE IF EXISTS public.fact_order_line;

CREATE TABLE public.fact_order_line (
  order_line_id           bigint,
  order_id                text,
  customer_id             text,
  product_id              text,
  order_placement_date    date,
  agreed_delivery_date    date,
  actual_delivery_date    date,
  order_qty               numeric,
  delivery_qty            numeric
);

SELECT COUNT(*) FROM public.fact_order_line;
SELECT * FROM public.fact_order_line LIMIT 5;

SELECT * FROM public.dim_products LIMIT 5;
SELECT current_database();

SELECT * FROM dim_customers LIMIT 5;
SELECT * FROM dim_products LIMIT 5;
SELECT * FROM dim_targets_orders LIMIT 5;
SELECT * FROM fact_order_line LIMIT 5;
SELECT * FROM fact_aggregate LIMIT 5;

SELECT current_database();

SELECT COUNT(*) AS fact_order_line_rows FROM public.fact_order_line;

SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_name ILIKE '%fact%order%line%'
ORDER BY table_schema, table_name;

SELECT COUNT(*) AS fact_order_line_rows FROM public.fact_order_line;
SELECT current_database();

--adding the missing data 
--1
ALTER TABLE fact_order_line
ADD COLUMN "In Full" INT;
--2
ALTER TABLE fact_order_line
ADD COLUMN "On Time" INT;
--3
ALTER TABLE fact_order_line
ADD COLUMN "On Time In Full" INT;

ALTER TABLE public.fact_order_line
ADD COLUMN order_line_id BIGINT;

select *
from fact_order_line

---------------------------------------------------------------------------------------
---creating the fact orderline table again

CREATE TABLE public.fact_order_line_new AS
SELECT order_line_id, order_id, customer_id, product_id, order_placement_date, 
       agreed_delivery_date, actual_delivery_date, order_qty, delivery_qty, 
       "In Full", "On Time", "On Time In Full"
FROM public.fact_order_line;

DROP TABLE public.fact_order_line;

ALTER TABLE public.fact_order_line_new RENAME TO fact_order_line;

---------------------------------------------------------------------

--GETTING TO KNOW THE STRUCTURE
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'  -- Change schema name if needed
AND table_name = 'fact_order_line';  -- Replace with your table name

----changing the data type of the last 3 columns to text 
ALTER TABLE public.fact_order_line
    ALTER COLUMN "In Full" TYPE text USING "In Full"::text;

ALTER TABLE public.fact_order_line
    ALTER COLUMN "On Time" TYPE text USING "On Time"::text;

ALTER TABLE public.fact_order_line
    ALTER COLUMN "On Time In Full" TYPE text USING "On Time In Full"::text;

--Changing t to true and f to false 
UPDATE public.fact_order_line
SET "In Full" = CASE WHEN "In Full" = 't' THEN True ELSE False END,
    "On Time" = CASE WHEN "On Time" = 't' THEN True ELSE False END,
    "On Time In Full" = CASE WHEN "On Time In Full" = 't' THEN True ELSE False END;

---creating the table again 
DROP TABLE IF EXISTS public.fact_order_line;

CREATE TABLE public.fact_order_line (
    order_line_id BIGINT PRIMARY KEY,  -- Assuming BIGINT for order_line_id
    order_id TEXT,                      -- Assuming TEXT for order_id
    customer_id TEXT,                   -- Assuming TEXT for customer_id
    product_id TEXT,                    -- Assuming TEXT for product_id
    order_placement_date DATE,          -- Assuming DATE for order_placement_date
    agreed_delivery_date DATE,          -- Assuming DATE for agreed_delivery_date
    actual_delivery_date DATE,          -- Assuming DATE for actual_delivery_date
    order_qty NUMERIC,                  -- Assuming NUMERIC for order_qty
    delivery_qty NUMERIC,               -- Assuming NUMERIC for delivery_qty
    "In Full" BOOLEAN,                  -- Assuming BOOLEAN for "In Full"
    "On Time" BOOLEAN,                  -- Assuming BOOLEAN for "On Time"
    "On Time In Full" BOOLEAN           -- Assuming BOOLEAN for "On Time In Full"
);

SELECT version();
SELECT current_database();
SELECT 1;

--creating views
-- vkpi customer month
-- Create or replace the view for the customer KPI calculation
-- 1. Create the table (replace with actual schema as needed)
CREATE OR REPLACE VIEW public.v_kpi_customer_month AS
SELECT 
    date_trunc('month'::text, order_placement_date::timestamp with time zone)::date AS month,
    customer_id,
    count(*)::integer AS total_order_lines,
    count(DISTINCT order_id)::integer AS total_orders,
    avg(CASE WHEN "In Full" THEN 1 ELSE 0 END)::numeric(10,4) AS line_fill_rate,
    (sum(delivery_qty) / NULLIF(sum(order_qty), 0::numeric))::numeric(10,4) AS volume_fill_rate,
    avg(CASE WHEN "On Time" THEN 1 ELSE 0 END)::numeric(10,4) AS on_time_pct,
    avg(CASE WHEN "In Full" THEN 1 ELSE 0 END)::numeric(10,4) AS in_full_pct,
    avg(CASE WHEN "On Time In Full" THEN 1 ELSE 0 END)::numeric(10,4) AS otif_pct
FROM 
    public.fact_order_line
GROUP BY 
    date_trunc('month'::text, order_placement_date::timestamp with time zone)::date, customer_id;

GRANT SELECT ON public.v_kpi_vs_target TO neon_user;
GRANT ALL PRIVILEGES ON DATABASE neondb TO neon_superuser;
---------------------------------------------------------------------------------------------------------------
--creating publicv kpi vs target 
CREATE OR REPLACE VIEW public.v_kpi_vs_target AS
SELECT 
    date_trunc('month'::text, order_placement_date::timestamp with time zone)::date AS month,
    customer_id,
    count(*)::integer AS total_order_lines,
    count(DISTINCT order_id)::integer AS total_orders,
    avg(CASE WHEN "In Full" THEN 1 ELSE 0 END)::numeric(10,4) AS line_fill_rate,
    (sum(delivery_qty) / NULLIF(sum(order_qty), 0::numeric))::numeric(10,4) AS volume_fill_rate,
    avg(CASE WHEN "On Time" THEN 1 ELSE 0 END)::numeric(10,4) AS on_time_pct,
    avg(CASE WHEN "In Full" THEN 1 ELSE 0 END)::numeric(10,4) AS in_full_pct,
    avg(CASE WHEN "On Time In Full" THEN 1 ELSE 0 END)::numeric(10,4) AS otif_pct
FROM 
    public.fact_order_line
GROUP BY 
    date_trunc('month'::text, order_placement_date::timestamp with time zone)::date, customer_id;

-----------------------------------------------------------------------------------------------------------------
-- viewing all the roles
SELECT * FROM pg_roles;

-- checking why the view is not working 
SELECT * FROM public.v_kpi_vs_target LIMIT 10;
--checking for connection
SELECT * FROM pg_catalog.pg_tables LIMIT 5;

--table/view exist
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public' AND table_name = 'v_kpi_vs_target';
--permissions
GRANT SELECT ON public.v_kpi_vs_target TO neon_superuser;
GRANT SELECT ON public.v_kpi_vs_target TO neondb_owner;
--checking the schema 
SELECT * FROM public.v_kpi_vs_target WHERE month = date_trunc('month', current_date) LIMIT 10;

select * 
from public.v_kpi_vs_target 
---information about table
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public';

---
SELECT 
    f.customer_id,
    c.customer_name,  
    COUNT(DISTINCT f.order_id) AS total_orders,
    SUM(f.delivery_qty) AS total_delivery_qty
FROM 
    public.fact_order_line f
JOIN 
    public.dim_customers c ON f.customer_id = c.customer_id::text  -- Cast c.customer_id to text
GROUP BY 
    f.customer_id, c.customer_name;

SELECT
    p.product_name,
    p.category,
    COUNT(f.order_id) AS total_orders,
    SUM(f.delivery_qty) AS total_quantity_sold,
    SUM(f.delivery_qty * p.price_inr) AS total_revenue_inr,
    SUM(f.delivery_qty * p.price_usd) AS total_revenue_usd
FROM
    public.fact_order_line f
JOIN
    public.dim_products p
ON
    f.product_id = p.product_id
GROUP BY
    p.product_name, p.category
ORDER BY
    total_quantity_sold DESC;


SELECT
    p.product_name,
    p.product_id
FROM
    public.fact_order_line f
JOIN
    public.dim_products p
ON
    f.product_id = p.product_id
LIMIT 10;


SELECT DISTINCT product_id FROM public.fact_order_line LIMIT 10;
SELECT DISTINCT product_id FROM public.dim_products LIMIT 10;


SELECT 
    f.product_id,
    p.product_id
FROM 
    public.fact_order_line f
JOIN 
    public.dim_products p
ON 
    CAST(f.product_id AS TEXT) = p.product_id
LIMIT 10;


SELECT 
    p.product_name,
    p.category,
    COUNT(f.order_id) AS total_orders,
    SUM(f.delivery_qty) AS total_quantity_sold,
    SUM(f.delivery_qty * p.price_inr) AS total_revenue_inr,
    SUM(f.delivery_qty * p.price_usd) AS total_revenue_usd
FROM 
    public.fact_order_line f
JOIN 
    public.dim_products p 
ON 
    TRIM(CAST(f.product_id AS TEXT)) = TRIM(p.product_id)  -- Removing any leading/trailing spaces
GROUP BY 
    p.product_name, p.category
ORDER BY 
    total_quantity_sold DESC;




