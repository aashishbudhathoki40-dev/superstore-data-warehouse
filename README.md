# Superstore Data Warehouse & Sales Analytics

## Overview
This project demonstrates the design and implementation of a sales data warehouse using PostgreSQL.
Raw transactional sales data was transformed into a star-schema model to support analytical queries.

## Technologies Used
- PostgreSQL
- SQL
- DBeaver

## Data Model
- Fact Table: fact_sales
- Dimension Tables:
  - dim_customer
  - dim_product
  - dim_location
  - date_dimension

## Key Features
- Star schema data warehouse design
- ETL process from raw sales data
- Date dimension with weekend and time attributes
- Advanced SQL analytics using joins, CTEs, and window functions

## Business Insights
- Most profitable customer segments
- Top customers by profit
- Monthly top-performing locations and products
- Product sales and profit margin analysis
- Shipping efficiency by state

## How to Run
1. Execute schema.sql
2. Load raw data into superstore_raw
3. Execute etl.sql
4. Run analytics.sql

## Author
Aashish Budhathoki
