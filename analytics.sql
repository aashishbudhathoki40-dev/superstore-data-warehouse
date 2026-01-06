select * from superstore_raw sr ;
select * from date_dimension dd ;
select * from dim_customer dc ;
select * from dim_location dl ;
select * from dim_product dp ;
select *from fact_sales;

--Customer segment that generates the most profit
select c.segment, sum(f.sales) from fact_sales f 
join dim_customer c on f.customer_key =c.customer_key group by c.segment;

--top 10 customer providing the most profit and the discounr given to them
SELECT 
    customer_name,
    total_profit,
    avg_discount
FROM (
    SELECT 
        c.customer_name,
        SUM(f.profit) AS total_profit,
        AVG(f.discount) AS avg_discount,
        RANK() OVER (ORDER BY SUM(f.profit) DESC) AS profit_rank
    FROM fact_sales f
    JOIN dim_customer c
        ON f.customer_key = c.customer_key
    GROUP BY c.customer_name
) ranked_customers
WHERE profit_rank <= 10
ORDER BY profit_rank;


--location with top sales per month and the most saling product at that time

WITH monthly_location_sales AS (
    SELECT 
        EXTRACT(YEAR FROM dd_order.full_date) AS sale_year,
        EXTRACT(MONTH FROM dd_order.full_date) AS sale_month_num,
        TO_CHAR(dd_order.full_date, 'Month') AS month_name,
        dl.city AS location_name,
        dp.product_name,
        SUM(fs.sales) AS total_sales,
        RANK() OVER (
            PARTITION BY EXTRACT(YEAR FROM dd_order.full_date), 
                         EXTRACT(MONTH FROM dd_order.full_date)
            ORDER BY SUM(fs.sales) DESC
        ) AS location_rank,
        ROW_NUMBER() OVER (
            PARTITION BY EXTRACT(YEAR FROM dd_order.full_date), 
                         EXTRACT(MONTH FROM dd_order.full_date), 
                         dl.location_key 
            ORDER BY SUM(fs.sales) DESC
        ) AS product_rank
    FROM fact_sales fs
    JOIN dim_location dl ON fs.location_key = dl.location_key
    JOIN dim_product dp ON fs.product_key = dp.product_key
    JOIN date_dimension dd_order ON fs.order_date_key = dd_order.date_key
    GROUP BY EXTRACT(YEAR FROM dd_order.full_date),
             EXTRACT(MONTH FROM dd_order.full_date),
             TO_CHAR(dd_order.full_date, 'Month'),
             dl.location_key, 
             dl.city, 
             dp.product_name
)
SELECT 
    sale_year,
    sale_month_num,
    TRIM(month_name) AS month,
    location_name AS top_location,
    product_name AS top_product_in_location,
    ROUND(total_sales::numeric, 2) AS location_sales_amount
FROM monthly_location_sales
WHERE location_rank = 1 
    AND product_rank = 1
ORDER BY sale_year, sale_month_num;


--top 10 best selling products and the profit generated from them in percentage

WITH product_performance AS (
    SELECT 
        dp.product_name,
        dp.category,
        dp.sub_category,
        SUM(fs.sales) AS total_sales,
        SUM(fs.profit) AS total_profit,
        COUNT(DISTINCT fs.order_id) AS order_count,
        SUM(fs.quantity) AS total_quantity_sold,
        -- Calculate profit margin percentage
        CASE 
            WHEN SUM(fs.sales) = 0 THEN 0
            ELSE ROUND((SUM(fs.profit) / SUM(fs.sales)) * 100, 2)
        END AS profit_margin_percentage,
        -- Rank by sales
        ROW_NUMBER() OVER (ORDER BY SUM(fs.sales) DESC) AS sales_rank
    FROM fact_sales fs
    JOIN dim_product dp ON fs.product_key = dp.product_key
    GROUP BY dp.product_name, dp.category, dp.sub_category
)
SELECT 
    sales_rank,
    product_name,
    category,
    sub_category,
    ROUND(total_sales::numeric, 2) AS total_sales,
    ROUND(total_profit::numeric, 2) AS total_profit,
    profit_margin_percentage,
    total_quantity_sold,
    order_count,
    ROUND(total_sales / total_quantity_sold, 2) AS avg_price_per_unit
FROM product_performance
WHERE sales_rank <= 10
ORDER BY sales_rank;


--avg number of days for shipping in each state
SELECT 
    dl.state,
    COUNT(*) AS total_orders,
    ROUND(
        AVG(
            (dd_ship.full_date - dd_order.full_date)
        ), 2
    ) AS avg_shipping_days,
    MIN(
        (dd_ship.full_date - dd_order.full_date)
    ) AS min_shipping_days,
    MAX(
        (dd_ship.full_date - dd_order.full_date)
    ) AS max_shipping_days,
    -- Shipping efficiency indicator
    CASE 
        WHEN AVG(dd_ship.full_date - dd_order.full_date) <= 3 
            THEN 'Fast'
        WHEN AVG(dd_ship.full_date - dd_order.full_date) <= 7 
            THEN 'Standard'
        ELSE 'Slow'
    END AS shipping_efficiency
FROM fact_sales fs
JOIN dim_location dl ON fs.location_key = dl.location_key
JOIN date_dimension dd_order ON fs.order_date_key = dd_order.date_key
JOIN date_dimension dd_ship ON fs.ship_date_key = dd_ship.date_key
WHERE dd_ship.full_date >= dd_order.full_date  -- Ensure valid dates
GROUP BY dl.state
ORDER BY avg_shipping_days;














