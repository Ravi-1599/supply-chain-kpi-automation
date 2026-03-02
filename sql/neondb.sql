-- Table: public.dim_customers

-- DROP TABLE IF EXISTS public.dim_customers;

CREATE TABLE IF NOT EXISTS public.dim_customers
(
    customer_id integer NOT NULL,
    customer_name character varying(255) COLLATE pg_catalog."default",
    city character varying(255) COLLATE pg_catalog."default",
    currency character varying(10) COLLATE pg_catalog."default",
    CONSTRAINT dim_customers_pkey PRIMARY KEY (customer_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.dim_customers
    OWNER to postgres;

REVOKE ALL ON TABLE public.dim_customers FROM n8n_user;

GRANT SELECT ON TABLE public.dim_customers TO n8n_user;

GRANT ALL ON TABLE public.dim_customers TO postgres;



SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema IN ('public','staging')
ORDER BY table_schema, table_name;

SELECT * FROM dim_customers LIMIT 5;
SELECT * FROM dim_products LIMIT 5;
SELECT * FROM dim_targets_orders LIMIT 5;
SELECT * FROM fact_order_line LIMIT 5;
SELECT * FROM fact_aggregate LIMIT 5;



SELECT current_database(), current_schema();
SHOW search_path;

SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_name = 'dim_products';

SELECT * FROM public.dim_products LIMIT 5;

SELECT current_database();
SELECT current_database();






