## Swiggy Food Delivery Sales Analysis | SQL Project
-- End-to-end SQL project covering data cleaning, modeling, and business analysis

-- Create project database
CREATE DATABASE SwiggyDB;
USE swiggydb;

-- Create table for raw data
CREATE TABLE swiggy_data (
    State VARCHAR(50),
    City VARCHAR(50),
    Order_Date DATE,
    Restaurant_Name VARCHAR(255),
    Location VARCHAR(255),
    Category VARCHAR(255),
    Dish_Name TEXT,
    Price_INR DECIMAL(10 , 2 ),
	Rating DECIMAL(3 , 1 ),
    Rating_Count INT
);

-- Verify file import permissions
SHOW VARIABLES LIKE 'secure_file_priv';

-- Load Swiggy CSV data into the table
load data infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Swiggy_Data.csv' into table swiggy_data
fields terminated by ','
ignore 1 lines;

-- Verify successful data load
SELECT * FROM swiggy_data;

# DATA Validation and Cleaning
-- Check NULL values
SELECT
SUM(CASE WHEN State IS NULL THEN 1 ELSE 0 END) AS null_state,
SUM(CASE WHEN City IS NULL THEN 1 ELSE 0 END) AS null_city,
SUM(CASE WHEN Order_Date IS NULL THEN 1 ELSE 0 END) AS null_order_date,
SUM(CASE WHEN Restaurant_Name IS NULL THEN 1 ELSE 0 END) AS null_restaurant,
SUM(CASE WHEN Location IS NULL THEN 1 ELSE 0 END) AS null_location,
SUM(CASE WHEN Category IS NULL THEN 1 ELSE 0 END) AS null_category,
SUM(CASE WHEN Dish_Name IS NULL THEN 1 ELSE 0 END) AS null_dish,
SUM(CASE WHEN Price_INR IS NULL THEN 1 ELSE 0 END) AS null_price,
SUM(CASE WHEN Rating IS NULL THEN 1 ELSE 0 END) AS null_rating,
SUM(CASE WHEN Rating_Count IS NULL THEN 1 ELSE 0 END) AS null_rating_count
FROM swiggy_data;


-- Check Blank or Empty Strings
SELECT 
    SUM(CASE WHEN TRIM(State) = '' THEN 1 ELSE 0 END) AS blank_state,
    SUM(CASE WHEN TRIM(City) = '' THEN 1 ELSE 0 END) AS blank_city,
    SUM(CASE WHEN TRIM(Restaurant_Name) = '' THEN 1 ELSE 0 END) AS blank_restaurant,
    SUM(CASE WHEN TRIM(Location) = '' THEN 1 ELSE 0 END) AS blank_location,
    SUM(CASE WHEN TRIM(Category) = '' THEN 1 ELSE 0 END) AS blank_category,
    SUM(CASE WHEN TRIM(Dish_Name) = '' THEN 1 ELSE 0 END) AS blank_dish_name
FROM swiggy_data;

-- Duplicate Detection
SELECT 
    TRIM(COALESCE(State,'')) AS state_clean,
    TRIM(COALESCE(City,'')) AS city_clean,
    TRIM(COALESCE(Order_Date,'')) AS order_date_clean,
    TRIM(COALESCE(Restaurant_Name,'')) AS restaurant_clean,
    TRIM(COALESCE(Location,'')) AS location_clean,
    TRIM(COALESCE(Category,'')) AS category_clean,
    TRIM(COALESCE(Dish_Name,'')) AS dish_clean,
    COALESCE(Price_INR,0) AS price_clean,
    COALESCE(Rating,0) AS rating_clean,
    COALESCE(Rating_Count,0) AS rating_count_clean,
    COUNT(*) AS duplicate_count
FROM swiggy_data
GROUP BY 
    state_clean, city_clean, order_date_clean, restaurant_clean, 
    location_clean, category_clean, dish_clean, price_clean, rating_clean, rating_count_clean
HAVING COUNT(*) > 1;

-- Delete Duplication
-- Create Clean Table Structure
CREATE TABLE swiggy_clean LIKE swiggy_data;
     
-- Remove duplicates using ROW_NUMBER
INSERT INTO swiggy_clean
SELECT 
    State, City, Order_Date, Restaurant_Name, Location, 
    Category, Dish_Name, Price_INR, Rating, Rating_Count
FROM (
    SELECT 
        State, City, Order_Date, Restaurant_Name, Location, 
        Category, Dish_Name, Price_INR, Rating, Rating_Count,
        ROW_NUMBER() OVER (
            PARTITION BY 
                TRIM(COALESCE(State,'')), 
                TRIM(COALESCE(City,'')), 
                TRIM(COALESCE(Order_Date,'')), 
                TRIM(COALESCE(Restaurant_Name,'')), 
                TRIM(COALESCE(Location,'')), 
                TRIM(COALESCE(Category,'')), 
                TRIM(COALESCE(Dish_Name,'')), 
                COALESCE(Price_INR,0),
                COALESCE(Rating, 0), 
                COALESCE(Rating_Count, 0)
            ORDER BY Order_Date
        ) as row_num
    FROM swiggy_data
) t
WHERE row_num = 1;

-- Validate deduplication
SELECT (SELECT COUNT(*) FROM swiggy_data) - (SELECT COUNT(*) FROM swiggy_clean) AS rows_removed;

-- Cleaning : Trim text columns
UPDATE swiggy_clean 
SET 
    State = TRIM(State),
    City = TRIM(City),
    Restaurant_Name = TRIM(Restaurant_Name),
    Location = TRIM(Location),
    Category = TRIM(Category),
    Dish_Name = TRIM(Dish_Name);
    
# CREATING STAR SCHEMA.
-- DIMENSION TABLES
-- Date dimension
CREATE TABLE dim_date (
    date_id INT AUTO_INCREMENT PRIMARY KEY,
    Full_Date DATE,
    Year INT,
    Month INT,
    Month_Name VARCHAR(20),
    Quarter INT,
    Day INT,
    Week INT
);

-- Location dimension
CREATE TABLE dim_location (
    Location_id INT AUTO_INCREMENT PRIMARY KEY,
    State VARCHAR(100),
    City VARCHAR(100),
    Location VARCHAR(200)
);

-- Restaurant dimension
CREATE TABLE dim_restaurant (
    restaurant_id INT AUTO_INCREMENT PRIMARY KEY,
    Restaurant_Name VARCHAR(200)
);

-- Category dimension
CREATE TABLE dim_category (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    Category VARCHAR(200)
);

-- Dish dimension
CREATE TABLE dim_dish (
    dish_id INT AUTO_INCREMENT PRIMARY KEY,
    Dish_Name VARCHAR(200)
);

-- CREATE FACT TABLE
CREATE TABLE fact_swiggy_orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    date_id INT,
    Price_INR DECIMAL(10 , 2 ),
    Rating DECIMAL(4 , 2 ),
    Rating_Count INT,
    location_id INT,
    restaurant_id INT,
    category_id INT,
    dish_id INT,
    FOREIGN KEY (date_id)
        REFERENCES dim_date (date_id),
    FOREIGN KEY (location_id)
        REFERENCES dim_location (location_id),
    FOREIGN KEY (restaurant_id)
        REFERENCES dim_restaurant (restaurant_id),
    FOREIGN KEY (category_id)
        REFERENCES dim_category (category_id),
    FOREIGN KEY (dish_id)
        REFERENCES dim_dish (dish_id)
);


-- Insert Data in all Tables

-- dim_date
INSERT INTO dim_date (Full_Date, Year, Month, Month_Name, Quarter, Day, Week)
SELECT DISTINCT
    order_date,
    YEAR(order_date),
    MONTH(order_date),
    MONTHNAME(order_date),
    QUARTER(order_date),
    DAY(order_date),
    WEEK(order_date) 
FROM swiggy_clean
WHERE order_date IS NOT NULL;


-- dim_location
INSERT INTO dim_location (State, City, Location)
SELECT DISTINCT
	State,
	City,
	Location
FROM swiggy_clean;

-- dim_restaurant
INSERT INTO dim_restaurant (Restaurant_Name)
SELECT DISTINCT
	Restaurant_Name
FROM swiggy_clean;

-- dim_category
INSERT INTO dim_category (Category)
SELECT DISTINCT
	Category
FROM swiggy_clean;

-- dim_dish
INSERT INTO dim_dish (Dish_Name)
SELECT DISTINCT
	Dish_Name
FROM swiggy_clean;

-- INSERT INTO FACT TABLE
INSERT INTO fact_swiggy_orders
(
	date_id,
	Price_INR,
	Rating,
	Rating_Count,
	location_id,
	restaurant_id,
	category_id,
	dish_id
)
SELECT 
    dd.date_id,
    s.Price_INR,
    s.Rating,
    s.Rating_Count,
    dl.location_id,
    dr.restaurant_id,
    dc.category_id,
    dsh.dish_id
FROM
    swiggy_clean s
        JOIN
    dim_date dd ON dd.Full_Date = s.Order_Date
        JOIN
    dim_location dl ON dl.State = s.State AND dl.City = s.City
        AND dl.Location = s.Location
        JOIN
    dim_restaurant dr ON dr.Restaurant_Name = s.Restaurant_Name
        JOIN
    dim_category dc ON dc.Category = s.Category
        JOIN
    dim_dish dsh ON dsh.Dish_Name = s.Dish_Name;

-- All tables together
SELECT 
    *
FROM
    fact_swiggy_orders f
        JOIN
    dim_date d ON f.date_id = d.date_id
        JOIN
    dim_location l ON f.location_id = l.location_id
        JOIN
    dim_restaurant r ON f.restaurant_id = r.restaurant_id
        JOIN
    dim_category c ON f.category_id = c.category_id
        JOIN
    dim_dish di ON f.dish_id = di.dish_id;


-- KPI's
-- Total Orders
SELECT 
    COUNT(*) AS Total_Orders
FROM
    fact_swiggy_orders;
    
-- Total Revenue (INR Million)
SELECT 
    CONCAT(FORMAT(SUM(price_inr) / 1000000, 2),
            ' INR Million') AS Total_Revenue
FROM
    fact_swiggy_orders;

-- Average Dish Price
SELECT 
    CONCAT(ROUND(AVG(price_inr), 2), ' INR') AS Average_Price
FROM
    fact_swiggy_orders;

-- Average Rating
SELECT 
    ROUND(AVG(rating), 2)
FROM
    fact_swiggy_orders;
    
-- Deep-Dive Business Analysis
-- Monthly order and revenue trends
SELECT 
    d.year,
    d.month,
    d.month_name,
    COUNT(*) AS total_orders,
    SUM(price_INR) AS total_revenue
FROM
    fact_swiggy_orders f
        JOIN
    dim_date d ON f.date_id = d.date_id
GROUP BY d.year , d.month , d.month_name
ORDER BY d.year , d.month;

-- Quarterly order trends
SELECT 
    d.year, d.quarter, COUNT(*) AS total_orders
FROM
    fact_swiggy_orders f
        JOIN
    dim_date d ON f.date_id = d.date_id
GROUP BY d.year , d.quarter
ORDER BY total_orders;

-- Year-wise growth analysis
SELECT 
    d.year, COUNT(*) AS total_orders
FROM
    fact_swiggy_orders f
        JOIN
    dim_date d ON f.date_id = d.date_id
GROUP BY d.year;


-- Day-of-week order patterns
SELECT 
    DAYNAME(d.full_date) AS day_name,
    COUNT(f.order_id) AS total_orders
FROM
    fact_swiggy_orders f
        JOIN
    dim_date d ON f.date_id = d.date_id
GROUP BY day_name , DAYOFWEEK(d.full_date)
ORDER BY DAYOFWEEK(d.full_date);

-- Top 10 cities by order volume
SELECT 
    l.city, COUNT(*) AS total_orders
FROM
    fact_swiggy_orders f
        JOIN
    dim_location l ON f.location_id = l.location_id
GROUP BY l.city
ORDER BY total_orders DESC
LIMIT 10;

-- Revenue contribution by states
SELECT 
    l.state, SUM(price_INR) AS total_revenue
FROM
    fact_swiggy_orders f
        JOIN
    dim_location l ON f.location_id = l.location_id
GROUP BY l.state
ORDER BY total_revenue DESC;

-- Top 10 restaurants by orders
SELECT 
    r.restaurant_name, COUNT(*) AS total_order
FROM
    fact_swiggy_orders f
        JOIN
    dim_restaurant r ON r.restaurant_id = f.restaurant_id
GROUP BY r.restaurant_name
ORDER BY total_order DESC
LIMIT 10;

-- Top food categories by order volume
SELECT 
    c.category, COUNT(*) AS total_order
FROM
    fact_swiggy_orders f
        JOIN
    dim_category c ON c.category_id = f.category_id
GROUP BY c.category
ORDER BY total_order DESC;

-- Most ordered dishes
SELECT 
    d.dish_name, COUNT(*) AS order_count
FROM
    fact_swiggy_orders f
        JOIN
    dim_dish d ON d.dish_id = f.dish_id
GROUP BY d.dish_name
ORDER BY order_count DESC;

-- Cuisine performance (Orders + Avg Rating)
SELECT 
    c.category,
    COUNT(*) AS total_orders,
    ROUND(AVG(rating), 2) AS avg_rating
FROM
    fact_swiggy_orders f
        JOIN
    dim_category c ON c.category_id = f.category_id
GROUP BY c.category
ORDER BY total_orders DESC;

-- Total order distribution by Price Range
SELECT 
    CASE
        WHEN price_inr < 100 THEN 'Under 100'
        WHEN price_inr BETWEEN 100 AND 199 THEN '100 - 199'
        WHEN price_inr BETWEEN 200 AND 299 THEN '200 - 299'
        WHEN price_inr BETWEEN 300 AND 499 THEN '300 - 499'
        ELSE '500+'
    END AS price_range,
    COUNT(*) AS total_orders
FROM
    fact_swiggy_orders
GROUP BY price_range
ORDER BY total_orders DESC;

-- Rating count distribution (1-5)
SELECT 
    rating, COUNT(*) AS total_orders
FROM
    fact_swiggy_orders
GROUP BY rating
ORDER BY rating DESC;

