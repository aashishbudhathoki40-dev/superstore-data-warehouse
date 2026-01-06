--INSERING INTO dim_location
INSERT INTO dim_location (
  country, city, state, postal_code, 
  region
) 
SELECT 
  DISTINCT "Country", 
  "City", 
  "State", 
  "Postal Code", 
  "Region" 
FROM 
  superstore_raw 
ORDER BY 
  "Country", 
  "State", 
  "City";

--INSERT INTO dim_customer
INSERT INTO dim_customer (
  customer_id, customer_name, segment
) 
SELECT 
  DISTINCT "Customer ID", 
  "Customer Name", 
  "Segment" 
FROM 
  superstore_raw 
ORDER BY 
  "Customer ID";

-- 1. Check current table
SELECT 
  * 
FROM 
  dim_product 
WHERE 
  product_id = 'FUR-BO-10002213';
-- 2. Check source data
SELECT 
  "Row ID", 
  "Product ID", 
  "Product Name", 
  "Category", 
  "Sub-Category" 
FROM 
  superstore_raw 
WHERE 
  "Product ID" = 'FUR-BO-10002213';
-- Drop old constraint
ALTER TABLE 
  dim_product 
DROP 
  CONSTRAINT dim_product_product_id_key;
-- Add new constraint that allows SOME flexibility
ALTER TABLE 
  dim_product 
ADD 
  CONSTRAINT dim_product_natural_key UNIQUE (
    product_id, product_name, category, 
    sub_category
  );
-- Now same product_id can exist if ANY other column differs
INSERT INTO dim_product (
  product_id, product_name, category, 
  sub_category
) 
SELECT 
  DISTINCT "Product ID", 
  "Product Name", 
  "Category", 
  "Sub-Category" 
FROM 
  superstore_raw ON CONFLICT (
    product_id, product_name, category, 
    sub_category
  ) DO NOTHING;

--INSERT INTO date_dimension
SELECT 
  LEAST(
    MIN("Order Date"), 
    MIN("Ship Date")
  ) as min_date, 
  GREATEST(
    MAX("Order Date"), 
    MAX("Ship Date")
  ) as max_date 
FROM 
  superstore_raw;
-- Clear existing data
TRUNCATE TABLE date_dimension RESTART IDENTITY;
-- Generate dates from 2014-01-03 to 2018-01-05
INSERT INTO date_dimension (
  date_key, full_date, day, month, month_name, 
  quarter, year, week_of_year, day_name, 
  is_weekend
) 
SELECT 
  TO_CHAR(d, 'YYYYMMDD'):: INTEGER as date_key, 
  d :: date as full_date, 
  EXTRACT(
    DAY 
    FROM 
      d
  ):: SMALLINT as day, 
  EXTRACT(
    MONTH 
    FROM 
      d
  ):: SMALLINT as month, 
  TO_CHAR(d, 'Month') as month_name, 
  EXTRACT(
    QUARTER 
    FROM 
      d
  ):: SMALLINT as quarter, 
  EXTRACT(
    YEAR 
    FROM 
      d
  ):: SMALLINT as year, 
  EXTRACT(
    WEEK 
    FROM 
      d
  ):: SMALLINT as week_of_year, 
  TO_CHAR(d, 'Day') as day_name, 
  EXTRACT(
    DOW 
    FROM 
      d
  ) IN (0, 6) as is_weekend 
FROM 
  generate_series(
    '2014-01-03' :: date, '2018-01-05' :: date, 
    '1 day' :: interval
  ) d;
-- Verify the load
SELECT 
  COUNT(*) as total_days_loaded, 
  MIN(full_date) as first_date, 
  MAX(full_date) as last_date, 
  COUNT(CASE WHEN is_weekend THEN 1 END) as weekend_days, 
  COUNT(CASE WHEN NOT is_weekend THEN 1 END) as weekday_days 
FROM 
  date_dimension;


--INSERT INTO fact_sales
INSERT INTO fact_sales (
  row_id, order_id, customer_key, location_key, 
  product_key, order_date_key, ship_date_key, 
  sales, quantity, discount, profit
) 
SELECT 
  sr."Row ID", 
  sr."Order ID", 
  dc.customer_key, 
  dl.location_key, 
  dp.product_key, 
  TO_CHAR(sr."Order Date", 'YYYYMMDD'):: INTEGER, 
  TO_CHAR(sr."Ship Date", 'YYYYMMDD'):: INTEGER, 
  sr."Sales", 
  sr."Quantity", 
  sr."Discount", 
  sr."Profit" 
FROM 
  superstore_raw sr 
  JOIN dim_customer dc ON sr."Customer ID" = dc.customer_id 
  JOIN dim_location dl ON sr."City" = dl.city 
  AND sr."State" = dl.state 
  AND sr."Postal Code" = dl.postal_code 
  JOIN dim_product dp ON sr."Product ID" = dp.product_id 
  AND sr."Product Name" = dp.product_name 
  AND sr."Category" = dp.category 
  AND sr."Sub-Category" = dp.sub_category;
-- 1. Create indexes on fact_sales foreign keys (MOST IMPORTANT)
CREATE INDEX idx_fact_customer ON fact_sales (customer_key);
CREATE INDEX idx_fact_location ON fact_sales (location_key);
CREATE INDEX idx_fact_product ON fact_sales (product_key);
CREATE INDEX idx_fact_order_date ON fact_sales (order_date_key);
CREATE INDEX idx_fact_ship_date ON fact_sales (ship_date_key);



-- 2. Create index on degenerate dimension (order_id for quick lookups)
CREATE INDEX idx_fact_order_id ON fact_sales (order_id);
-- 3. Create composite indexes for common query patterns
CREATE INDEX idx_fact_date_customer ON fact_sales (order_date_key, customer_key);
CREATE INDEX idx_fact_date_product ON fact_sales (order_date_key, product_key);



-- 4. Create indexes on dimension tables for faster lookups
CREATE INDEX idx_customer_id ON dim_customer (customer_id);
CREATE INDEX idx_product_id ON dim_product (product_id);
CREATE INDEX idx_date_full_date ON date_dimension (full_date);
CREATE INDEX idx_location_city_state ON dim_location (city, state);
CREATE INDEX idx_location_postal ON dim_location (postal_code);

