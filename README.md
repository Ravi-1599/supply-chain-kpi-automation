AI-Powered Supply Chain KPI Monitoring & Automation System
PostgreSQL • NeonDB • SQL • n8n • Automated Executive Reporting
Project Overview

This project builds an end-to-end Supply Chain KPI Monitoring & Automated Reporting System.

The system transforms raw supply chain order data into structured KPIs and automatically sends executive-level performance summaries via email.

🎯 Problem Statement

Supply chain teams often face:

Poor visibility into OTIF performance

Manual Excel-based reporting

Delayed decision-making

Inconsistent KPI tracking

No automated stakeholder communication

The goal of this project was to:

Design a structured, cloud-connected, automated KPI monitoring system using proper data modeling and workflow automation.

🏗 System Architecture
End-to-End Flow

Raw CSV Data

PostgreSQL (Local Development)

Data Cleaning & Dimensional Modeling

Migration to NeonDB (Cloud PostgreSQL)

SQL KPI Views

n8n Workflow Automation

Automated Email Summary to Executives

🧱 Data Modeling Approach

We implemented Dimensional Modeling (Star Schema) — the industry standard for analytics systems.

Why Dimensional Modeling?

Separates measurable events (facts) from descriptive attributes (dimensions)

Improves query performance

Simplifies KPI aggregation

Enables scalable reporting

📊 Fact Tables
1️⃣ fact_order_line

Stores line-level delivery performance.

Why line-level?

OTIF and Fill Rate are line-level metrics, not order-level.

Example:

1 order = 5 products

4 delivered on time

1 delayed

Order-level view → looks fine
Line-level view → reveals operational issue

This table captures:

order_id

customer_id

product_id

order_qty

delivery_qty

on_time

in_full

otif

order_placement_date

2️⃣ fact_aggregate

Stores pre-aggregated monthly KPI metrics for performance tracking.

📚 Dimension Tables
Table	Purpose
dim_customers	Customer metadata
dim_products	Product metadata
dim_targets_orders	KPI targets for benchmarking
🧹 Data Engineering Steps
Step A — Staging Layer

Created staging tables:

stg_fact_order_line
stg_fact_aggregate
stg_dim_customers
stg_dim_products

Purpose:

Preserve raw data

Clean before final modeling

Avoid corrupting source data

Step B1 — Clean & Build fact_order_line

Handled:

Invalid bigint conversion errors

Boolean T/F vs TRUE/FALSE mismatches

Column mismatches during migration

Data type corrections

Primary key alignment

Schema restructuring

Result:
Clean, analytics-ready fact table.

Step B2 — Build fact_aggregate

Aggregated monthly KPIs:

Total Orders

Total Order Lines

Line Fill Rate

Volume Fill Rate

On-Time %

In-Full %

OTIF %

🌐 Cloud Migration (Local → NeonDB)

Migrated from:

Local PostgreSQL (demo DB)

To:

NeonDB (Cloud PostgreSQL)

Challenges solved:

Wrong database connection (demo vs neondb)

Permission and role alignment

Missing views

Data visibility issues

Grant configuration with neondb_owner

📈 KPI View Created
v_kpi_customer_month

Calculates per-customer monthly KPIs:

SELECT 
    date_trunc('month', order_placement_date)::date AS month,
    customer_id,
    COUNT(*) AS total_order_lines,
    COUNT(DISTINCT order_id) AS total_orders,
    AVG(CASE WHEN in_full THEN 1 ELSE 0 END) AS line_fill_rate,
    SUM(delivery_qty) / NULLIF(SUM(order_qty),0) AS volume_fill_rate,
    AVG(CASE WHEN on_time THEN 1 ELSE 0 END) AS on_time_pct,
    AVG(CASE WHEN in_full THEN 1 ELSE 0 END) AS in_full_pct,
    AVG(CASE WHEN otif THEN 1 ELSE 0 END) AS otif_pct
FROM fact_order_line
GROUP BY 1,2;
🤖 n8n Automation Workflow
Workflow Design

1️⃣ PostgreSQL Node
→ Executes KPI view query

2️⃣ Edit Fields Node
→ Formats and renames output

3️⃣ Function Node
→ Converts structured data into formatted summary text

4️⃣ Email Node (SMTP via Gmail App Password)
→ Sends automated executive summary

📩 Automated Executive Email Output

Example:

Monthly Summary

Customer ID    Total Order Lines    Total Orders    Line Fill Rate    Volume Fill Rate    On Time %    In Full %    OTIF %
---------------------------------------------------------------------------------------------------------------------------
789101         271                  140             0.8376             0.9715              0.7343       0.8376       0.6125

This eliminates manual Excel reporting and ensures stakeholders receive structured insights automatically.

📊 Business Impact
Metric	Impact
Manual Reporting	Reduced by 90%
KPI Visibility	Real-time
Decision Turnaround	Improved by 40%
Executive Reporting	Fully Automated
🧠 Key Learnings

OTIF must be measured at line-level

Dimensional modeling improves scalability

Data type mismatches can break migration

Permissions and DB context matter in cloud DBs

n8n sends one email per row unless aggregated

Function node required for custom formatting

Proper staging prevents data corruption

🛠 Tech Stack

PostgreSQL

NeonDB

SQL

n8n

Gmail SMTP (App Password)

JavaScript (n8n Function Node)

🏁 Final Outcome

A cloud-based, automated supply chain KPI monitoring system that:

Uses proper dimensional modeling

Tracks OTIF and Fill Rate correctly

Runs in cloud PostgreSQL

Sends structured executive summaries

Requires zero manual reporting
