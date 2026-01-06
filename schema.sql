--CREATING RAW TABLE
CREATE TABLE superstore_raw (
  "Row ID" INTEGER, 
  "Order ID" TEXT, 
  "Order Date" DATE, 
  "Ship Date" DATE, 
  "Ship Mode" TEXT, 
  "Customer ID" TEXT, 
  "Customer Name" TEXT, 
  "Segment" TEXT, 
  "Country" TEXT, 
  "City" TEXT, 
  "State" TEXT, 
  "Postal Code" TEXT, 
  "Region" TEXT, 
  "Product ID" TEXT, 
  "Category" TEXT, 
  "Sub-Category" TEXT, 
  "Product Name" TEXT, 
  "Sales" DECIMAL(10, 2), 
  "Quantity" INTEGER, 
  "Discount" DECIMAL(4, 2), 
  "Profit" DECIMAL(10, 2)
);
show data_directory;
select 
  version();
--Verifying Import
select 
  count(*) as total_rows 
from 
  superstore_raw;
select 
  * 
from 
  superstore_raw 
limit 
  5;
SELECT 
  MIN("Order Date") as first_order, 
  MAX("Order Date") as last_order, 
  COUNT(DISTINCT "Customer ID") as unique_customers, 
  COUNT(DISTINCT "Product ID") as unique_products 
FROM 
  superstore_raw;
SELECT 
  column_name, 
  data_type, 
  character_maximum_length AS max_length, 
  is_nullable, 
  column_default AS default_value 
FROM 
  information_schema.columns 
WHERE 
  table_name = 'superstore_raw' 
  AND table_schema = 'public';


--CREATING DATE DIMENSION 
CREATE TABLE date_dimension (
  date_key INTEGER PRIMARY KEY, 
  full_date DATE NOT NULL UNIQUE, 
  day SMALLINT NOT NULL, 
  month SMALLINT NOT NULL, 
  month_name VARCHAR(20) NOT NULL, 
  quarter SMALLINT NOT NULL, 
  year SMALLINT NOT NULL, 
  week_of_year SMALLINT NOT NULL, 
  day_name VARCHAR(20) NOT NULL, 
  is_weekend BOOLEAN NOT NULL
);

--CREATING CUSTOMER DIMENSION
CREATE TABLE dim_customer (
  customer_key SERIAL PRIMARY KEY, 
  customer_id VARCHAR(50) NOT NULL UNIQUE, 
  customer_name VARCHAR(100) NOT NULL, 
  segment VARCHAR(50) NOT NULL
);

--CREATING LOCATION DIMENSION
CREATE TABLE dim_location (
  location_key SERIAL PRIMARY KEY, 
  country VARCHAR(50) NOT NULL, 
  city VARCHAR(50) NOT NULL, 
  state VARCHAR(50), 
  postal_code VARCHAR(20), 
  region VARCHAR(50)
);

--CREATING PRODUCT DIMENSION
CREATE TABLE dim_product (
  product_key SERIAL PRIMARY KEY, 
  product_id VARCHAR(50) NOT NULL UNIQUE, 
  product_name VARCHAR(150) NOT NULL, 
  category VARCHAR(50) NOT NULL, 
  sub_category VARCHAR(50) NOT NULL
);

--CREATING FACT SALES
CREATE TABLE fact_sales (
  sales_key SERIAL PRIMARY KEY, 
  row_id INTEGER NOT NULL, 
  order_id VARCHAR(50) NOT NULL, 
  customer_key INTEGER NOT NULL, 
  location_key INTEGER NOT NULL, 
  product_key INTEGER NOT NULL, 
  order_date_key INTEGER NOT NULL, 
  ship_date_key INTEGER NOT NULL, 
  sales NUMERIC(12, 2) NOT NULL, 
  quantity INTEGER NOT NULL, 
  discount NUMERIC(5, 2), 
  profit NUMERIC(12, 2), 
  -- Foreign Key Constraints (AFTER all columns, BEFORE closing parenthesis)
  CONSTRAINT fk_customer FOREIGN KEY (customer_key) REFERENCES dim_customer (customer_key), 
  CONSTRAINT fk_location FOREIGN KEY (location_key) REFERENCES dim_location (location_key), 
  CONSTRAINT fk_product FOREIGN KEY (product_key) REFERENCES dim_product (product_key), 
  CONSTRAINT fk_order_date FOREIGN KEY (order_date_key) REFERENCES date_dimension (date_key), 
  CONSTRAINT fk_ship_date FOREIGN KEY (ship_date_key) REFERENCES date_dimension (date_key)
);


