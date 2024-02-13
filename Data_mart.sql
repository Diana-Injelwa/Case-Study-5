USE data_mart;

SELECT *
FROM weekly_sales
LIMIT 15;

DESCRIBE weekly_sales;

-- DATA CLEANING
-- Changing the date format of week_date column to MySQL format
SELECT week_date FROM weekly_sales;

UPDATE weekly_sales
SET week_date = CASE
    WHEN week_date LIKE '%/%' THEN DATE_FORMAT(STR_TO_DATE(week_date, '%d/%m/%Y'), '%Y-%m-%d')
    ELSE NULL
END;

-- Changing the week_date column data type
ALTER TABLE weekly_sales
MODIFY COLUMN week_date DATE;

-- Convert sales column to INTEGER
ALTER TABLE weekly_sales
MODIFY COLUMN sales INT;

-- Convert transcations column to INTEGER
ALTER TABLE weekly_sales
MODIFY COLUMN transactions INT;

/* In a single query, perform the following operations and generate 
a new table in the data_mart schema named clean_weekly_sales:

1. Add a week_number as the second column for each week_date value, 
for example any value from the 1st of January to 7th of January 
will be 1, 8th to 14th will be 2 etc.

2. Add a month_number with the calendar month for each week_date
value as the 3rd column.

3. Add a calender_year column as the 4th column containing either 2018
2019 or 2020 values.

4. Add a new column called age_band after the original segment column
using the following mapping on the number inside the segment value 
1 = Young Adults, 2 = Middle Aged, 3 or 4 = Retirees.

5. Add a new demographic column using the following mapping for the
first letter in the segment values C = Couples, F = Families.

6. Ensure all null string values are with an 'unknown' string value
in the original segment column as well as the new age_band and demographic
columns

7. Generate a new avg_transaction column as the sales value divided by 
transactions rounded to 2 decimal places for each record
*/
CREATE TABLE clean_weekly_sales AS
SELECT
    week_date,
    WEEKOFYEAR(week_date) AS week_number,
    MONTH(week_date) AS month_number,
    YEAR(week_date) AS calender_year,
    region,
    platform,
    CASE
        WHEN segment = 'null' THEN 'Unknown'
        ELSE segment
    END AS segment,
    CASE
        WHEN segment LIKE '%1%' THEN 'Young Adults'
        WHEN segment LIKE '%2%' THEN 'Middle Aged'
        WHEN segment LIKE '%3%' OR segment LIKE '%4%' THEN 'Retirees'
        ELSE 'Unknown'
    END AS age_band,
    CASE
        WHEN segment LIKE 'C%' THEN 'Couples'
        WHEN segment LIKE 'F%' THEN 'Families'
        ELSE 'Unknown'
    END AS demographic,
    customer_type,
    transactions,
    sales,
    ROUND(sales/transactions, 2) AS avg_transaction
FROM weekly_sales;

SELECT *
FROM clean_weekly_sales
LIMIT 10;

-- DATA EXPLORATION
/* 1. What day of the week is used for each week_date value? */
SELECT DISTINCT DAYNAME(week_date) AS day_of_week
FROM clean_weekly_sales;

/* 2. What range of week numbers are missing from the dataset? */
WITH RECURSIVE missing_weeks AS(
    SELECT 1 AS n
    UNION
    SELECT n + 1
    FROM missing_weeks
    WHERE n < 52
)
SELECT n AS missing_week_numbers
FROM missing_weeks
WHERE n NOT IN (SELECT DISTINCT week_number FROM clean_weekly_sales);

/* 3. How many transactions were there for each year in the dataset? */
SELECT
    calender_year,
    SUM(transactions) AS total_transactions
FROM clean_weekly_sales
GROUP BY calender_year
ORDER BY calender_year;

/* 4. What is the total sales for each region for each month? */
SELECT
    region,
    MONTHNAME(week_date) AS month,
    SUM(sales) AS total_sales
FROM clean_weekly_sales
GROUP BY region, month
ORDER BY region, month_number;

/* 5. What is the total count of transactions for each platform? */
SELECT
    platform,
    COUNT(transactions) AS total_transactions
FROM clean_weekly_sales
GROUP BY platform;

/* 6. What is the percentage of sales for Retail vs Shopify
each month? */
WITH retail_shopify_sales AS(
    SELECT
        MONTHNAME(week_date) AS month,
        SUM(CASE WHEN platform = 'Retail' THEN sales END) AS retail_sales,
        SUM(CASE WHEN platform = 'Shopify' THEN sales END) AS shopify_sales,
        SUM(sales) AS total_sales
    FROM clean_weekly_sales
    GROUP BY month
)
SELECT
    month,
    CONCAT(ROUND((retail_sales / total_sales) * 100, 2),'%') AS retail_percent,
    CONCAT(ROUND((shopify_sales / total_sales) * 100, 2),'%') AS shopify_percent
FROM retail_shopify_sales
GROUP BY month
ORDER BY month;

/* 7. What is the percentage of sales by demographic 
for each year in the dataset? */
WITH demographics AS(
    SELECT
        calender_year,
        SUM(CASE WHEN demographic = 'Couples' THEN sales END) AS couples_sales,
        SUM(CASE WHEN demographic = 'Families' THEN sales END) AS families_sales,
        SUM(CASE WHEN demographic = 'Unknown' THEN sales END) AS unknown_sales,
        SUM(sales) AS total_sales
    FROM clean_weekly_sales
    GROUP BY calender_year
)
SELECT
    calender_year,
    CONCAT(ROUND((couples_sales / total_sales) * 100, 2),'%') AS couples_percent,
    CONCAT(ROUND((families_sales / total_sales) * 100, 2),'%') AS families_percent,
    CONCAT(ROUND((unknown_sales / total_sales) * 100, 2),'%') AS unknown_percent
FROM demographics
GROUP BY calender_year
ORDER BY calender_year;

/* 8.  Which age_band and demographic values contribute the most to 
Retail sales? */
SELECT
    age_band,
    demographic,
    SUM(CASE WHEN platform = 'Retail' THEN sales END) AS retail_sales
FROM clean_weekly_sales
GROUP BY age_band, demographic
ORDER BY retail_sales DESC;

/* 9. Can we use the avg_transaction column to find the average 
transaction size for each year for Retail vs Shopify? 
If not - how would you calculate it instead? */
WITH transactions AS(
    SELECT
        calender_year,
        SUM(CASE WHEN platform = 'Retail' THEN transactions END) AS retail_trans,
        SUM(CASE WHEN platform = 'Shopify' THEN transactions END) AS shopify_trans
        FROM clean_weekly_sales
        GROUP BY calender_year
),
sales AS(
    SELECT
        calender_year,
        SUM(CASE WHEN platform = 'Retail' THEN sales END) AS retail_sales,
        SUM(CASE WHEN platform = 'Shopify' THEN sales END) AS shopify_sales
        FROM clean_weekly_sales
        GROUP BY calender_year
)
SELECT
    s.calender_year,
    ROUND(AVG((retail_sales / retail_trans)), 2) AS retail_trans_size,
    ROUND(AVG((shopify_sales / shopify_trans)), 2) AS shopify_trans_size
FROM sales s
JOIN transactions t ON s. calender_year = t. calender_year
GROUP BY s.calender_year;

-- BEFORE AND AFTER ANALYSIS
/* Taking the week_date value of 2020-06-15 as the baseline week 
where the Data Mart sustainable packaging changes came into effect.
We would include all week_date values for 2020-06-15 as the start of 
the period after the change and the previous week_date values would be
 before. 
1. What is the total sales for the 4 weeks before and after 2020-06-15? 
What is the growth or reduction rate in actual values and percentage of sales? */
WITH 4_weeks_before AS(
    SELECT DISTINCT week_date
    FROM clean_weekly_sales
    WHERE week_date BETWEEN (DATE_ADD('2020-06-15', INTERVAL -4 WEEK)) AND (DATE_ADD('2020-06-15', INTERVAL -1 WEEK))    
),
4_weeks_after AS(
    SELECT DISTINCT week_date
    FROM clean_weekly_sales
    WHERE week_date BETWEEN '2020-06-15' AND (DATE_ADD('2020-06-15', INTERVAL 3 WEEK))    
),
sales AS(
    SELECT
        SUM(CASE WHEN week_date IN (SELECT * FROM 4_weeks_before) THEN sales END) AS 4weeks_before_sales,
        SUM(CASE WHEN week_date IN (SELECT * FROM 4_weeks_after) THEN sales END) AS 4weeks_after_sales
    FROM clean_weekly_sales
)
SELECT *,
    (4weeks_after_sales - 4weeks_before_sales) AS variance,
    CONCAT(ROUND(((4weeks_after_sales - 4weeks_before_sales) / 4weeks_before_sales) * 100, 2),'%') AS percentage
FROM sales;

-- 2. What about the entire 12 weeks before and after?
WITH 12_weeks_before AS(
    SELECT DISTINCT week_date
    FROM clean_weekly_sales
    WHERE week_date BETWEEN (DATE_ADD('2020-06-15', INTERVAL -12 WEEK)) AND (DATE_ADD('2020-06-15', INTERVAL -1 WEEK))    
),
12_weeks_after AS(
    SELECT DISTINCT week_date
    FROM clean_weekly_sales
    WHERE week_date BETWEEN '2020-06-15' AND (DATE_ADD('2020-06-15', INTERVAL 11 WEEK))    
),
sales AS(
    SELECT
            SUM(CASE WHEN week_date IN (SELECT * FROM 12_weeks_before) THEN sales END) AS 12weeks_before_sales,
            SUM(CASE WHEN week_date IN (SELECT * FROM 12_weeks_after) THEN sales END) AS 12weeks_after_sales
    FROM clean_weekly_sales    
)
SELECT *,
    (12weeks_after_sales - 12weeks_before_sales) AS variance,
    CONCAT(ROUND(((12weeks_after_sales - 12weeks_before_sales) / 12weeks_before_sales) * 100, 2),'%') AS percentage
FROM sales;


