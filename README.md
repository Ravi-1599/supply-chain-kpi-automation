# AI-Powered Supply Chain KPI Automation

> End-to-end automated KPI monitoring & executive reporting system for supply chain performance.

---

## Executive Summary

Designed and implemented a cloud-connected KPI automation system that transforms raw supply chain order data into structured, executive-level performance insights.

The solution eliminates manual Excel reporting and automatically delivers monthly OTIF performance summaries to stakeholders via email.

---

## Business Problem

Supply chain teams faced:

- Limited visibility into OTIF performance  
- Manual Excel-based KPI tracking  
- Delayed decision-making  
- Inconsistent performance reporting  
- No automated executive communication  

This created reporting inefficiencies and reduced leadership visibility into operational performance.

---

## Solution Built

We engineered a fully automated KPI intelligence pipeline that:

- Centralizes raw order-line data into a structured warehouse
- Cleans and standardizes operational data
- Computes monthly customer-level performance KPIs
- Converts structured metrics into executive-readable summaries
- Automatically distributes performance reports via email
- Enables repeatable, scalable performance tracking

This transformed static reporting into a continuous KPI monitoring system.

---

## What This System Enables

With this solution, stakeholders can now:

- Monitor OTIF trends at customer level
- Identify fulfillment gaps instantly
- Compare volume vs line-level performance
- Track on-time vs in-full breakdown
- Receive automated monthly summaries without manual intervention
- Scale KPI tracking to additional metrics with minimal changes

The system converts raw operational data into actionable business intelligence.

---

## KPI Metrics Automated

- **Total Order Lines** – Measures total fulfillment activity volume at order-line level.  
- **Total Orders** – Tracks distinct customer purchase transactions within the month.  
- **Line Fill Rate** – Percentage of order lines fulfilled completely (service reliability at line level).  
- **Volume Fill Rate** – Percentage of total ordered quantity successfully delivered (volume accuracy).  
- **On-Time %** – Percentage of deliveries made within the promised delivery window.  
- **In-Full %** – Percentage of orders delivered without quantity shortfall.  
- **OTIF %** – Percentage of orders delivered both On-Time and In-Full (end-to-end service performance metric).  

Example KPI Computation:

```sql
SELECT 
    date_trunc('month', order_placement_date)::date AS month,
    customer_id,
    COUNT(*) AS total_order_lines,
    COUNT(DISTINCT order_id) AS total_orders,
    AVG(CASE WHEN in_full THEN 1 ELSE 0 END) AS line_fill_rate,
    SUM(delivery_qty) / NULLIF(SUM(order_qty), 0) AS volume_fill_rate,
    AVG(CASE WHEN on_time THEN 1 ELSE 0 END) AS on_time_pct,
    AVG(CASE WHEN otif THEN 1 ELSE 0 END) AS otif_pct
FROM fact_order_line
GROUP BY 1,2;
