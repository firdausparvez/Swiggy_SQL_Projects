## Project: Swiggy Food Delivery Sales Analysis | SQL
**Analyst:** Firdaus Parvez

**Purpose:**
* Analyze Swiggy order data to clean raw transactions, model it into an analytics-friendly structure, and derive business KPIs and insights.

---

### 1. DATABASE SETUP & RAW DATA STORAGE
**Goal:**
* Create a dedicated database and store raw Swiggy transactional data without modification.

```sql
CREATE DATABASE SwiggyDB;
USE swiggydb;

```

### 2. RAW DATA TABLE CREATION
**Goal:**

* Store raw CSV data exactly as received to preserve data lineage and enable safe transformations.

```sql
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

```

### 3. FILE IMPORT VALIDATION
**Goal:**

* Verify MySQL file import permissions before loading external CSV data.

```sql
SHOW VARIABLES LIKE 'secure_file_priv';

```

### 4. RAW DATA INGESTION
**Goal:**

* Load Swiggy CSV data into the raw staging table.

```sql
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Swiggy_Data.csv'
INTO TABLE swiggy_data
FIELDS TERMINATED BY ','
IGNORE 1 LINES;

```

### 5. DATA LOAD VERIFICATION
**Goal:**

* Confirm successful ingestion of raw data.

```sql
SELECT * FROM swiggy_data;

```

---

## 6. DATA EXPLORATION & VALIDATION
**Goal:**
* Identify missing, invalid, or inconsistent values before performing any transformations.

### 6.1 NULL VALUE ANALYSIS**Business Reason:**

* NULL values can break joins, distort KPIs, and lead to inaccurate analysis.

```sql
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

```

### 6.2 BLANK / EMPTY STRING CHECK
**Business Reason:**

* Blank strings behave differently from NULLs and can fragment dimension values.

```sql
SELECT 
    SUM(CASE WHEN TRIM(State) = '' THEN 1 ELSE 0 END) AS blank_state,
    SUM(CASE WHEN TRIM(City) = '' THEN 1 ELSE 0 END) AS blank_city,
    SUM(CASE WHEN TRIM(Restaurant_Name) = '' THEN 1 ELSE 0 END) AS blank_restaurant,
    SUM(CASE WHEN TRIM(Location) = '' THEN 1 ELSE 0 END) AS blank_location,
    SUM(CASE WHEN TRIM(Category) = '' THEN 1 ELSE 0 END) AS blank_category,
    SUM(CASE WHEN TRIM(Dish_Name) = '' THEN 1 ELSE 0 END) AS blank_dish_name
FROM swiggy_data;

```

### 7. DUPLICATE DETECTION
**Goal:**

* Identify duplicate transactional records that can inflate order counts and revenue metrics.

```sql
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
    state_clean, city_clean, order_date_clean,
    restaurant_clean, location_clean,
    category_clean, dish_clean,
    price_clean, rating_clean, rating_count_clean
HAVING COUNT(*) > 1;

```

### 8. DEDUPLICATION & CLEAN TABLE CREATION
**Goal:**

* Remove duplicate records and create a clean, analytics-ready dataset.

```sql
CREATE TABLE swiggy_clean LIKE swiggy_data;

```

### Deduplication Strategy:
* Use ROW_NUMBER() to retain a single valid record per duplicate group.

```sql
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
        ) AS row_num
    FROM swiggy_data
) t
WHERE row_num = 1;

```

### 9. DEDUPLICATION VALIDATION
**Goal:**

* Confirm that duplicate records were successfully removed.

```sql
SELECT 
    (SELECT COUNT(*) FROM swiggy_data)
  - (SELECT COUNT(*) FROM swiggy_clean) AS rows_removed;

```
## 10. DATA STANDARDIZATION
**Goal:**

* Clean text fields to ensure consistent joins and accurate aggregations.

```sql
UPDATE swiggy_clean 
SET 
    State = TRIM(State),
    City = TRIM(City),
    Restaurant_Name = TRIM(Restaurant_Name),
    Location = TRIM(Location),
    Category = TRIM(Category),
    Dish_Name = TRIM(Dish_Name);

```

---

## 11. STAR SCHEMA MODELING
**Goal:**

* Transform transactional data into an analytics-optimized star schema.

### 11.1 DIMENSION TABLES
* Date dimension
```sql
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
```
* Location dimension
```sql
CREATE TABLE dim_location (
    location_id INT AUTO_INCREMENT PRIMARY KEY,
    State VARCHAR(100),
    City VARCHAR(100),
    Location VARCHAR(200)
);
```
* Restaurant dimension
```sql
CREATE TABLE dim_restaurant (
    restaurant_id INT AUTO_INCREMENT PRIMARY KEY,
    Restaurant_Name VARCHAR(200)
);
```
* Category dimension
```sql
CREATE TABLE dim_category (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    Category VARCHAR(200)
);
```
* Dish dimension
```sql
CREATE TABLE dim_dish (
    dish_id INT AUTO_INCREMENT PRIMARY KEY,
    Dish_Name VARCHAR(200)
);

```

### 11.2 FACT TABLE
```sql
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
    FOREIGN KEY (date_id) REFERENCES dim_date (date_id),
    FOREIGN KEY (location_id) REFERENCES dim_location (location_id),
    FOREIGN KEY (restaurant_id) REFERENCES dim_restaurant (restaurant_id),
    FOREIGN KEY (category_id) REFERENCES dim_category (category_id),
    FOREIGN KEY (dish_id) REFERENCES dim_dish (dish_id)
);

```
---

### 12. DATA LOADING INTO STAR SCHEMA
**Goal:**

Populate dimension and fact tables using clean data.
* dim_date
```sql
INSERT INTO dim_date (Full_Date, Year, Month, Month_Name, Quarter, Day, Week)
SELECT DISTINCT
    Order_Date,
    YEAR(Order_Date),
    MONTH(Order_Date),
    MONTHNAME(Order_Date),
    QUARTER(Order_Date),
    DAY(Order_Date),
    WEEK(Order_Date)
FROM swiggy_clean
WHERE Order_Date IS NOT NULL;
```
* dim_location
```sql
INSERT INTO dim_location (State, City, Location)
SELECT DISTINCT State, City, Location
FROM swiggy_clean;
```
* dim_restaurant
```sql
INSERT INTO dim_restaurant (Restaurant_Name)
SELECT DISTINCT Restaurant_Name
FROM swiggy_clean;
```
* dim_category
```sql
INSERT INTO dim_category (Category)
SELECT DISTINCT Category
FROM swiggy_clean;
```
* dim_dish
```sql
INSERT INTO dim_dish (Dish_Name)
SELECT DISTINCT Dish_Name
FROM swiggy_clean;
```

* fact table
```sql
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
FROM swiggy_clean s
JOIN dim_date dd ON dd.Full_Date = s.Order_Date
JOIN dim_location dl ON dl.State = s.State AND dl.City = s.City AND dl.Location = s.Location
JOIN dim_restaurant dr ON dr.Restaurant_Name = s.Restaurant_Name
JOIN dim_category dc ON dc.Category = s.Category
JOIN dim_dish dsh ON dsh.Dish_Name = s.Dish_Name;

```

### 13. MODEL VALIDATION
**Goal:**

* Verify fact and dimension table relationships.

```sql
SELECT *
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
JOIN dim_location l ON f.location_id = l.location_id
JOIN dim_restaurant r ON f.restaurant_id = r.restaurant_id
JOIN dim_category c ON f.category_id = c.category_id
JOIN dim_dish di ON f.dish_id = di.dish_id;

```

---

### 14. KPI DEVELOPMENT
**Goal:**

* Derive core business metrics for reporting.
  
**Total Orders**
```sql
SELECT COUNT(*) AS Total_Orders
FROM fact_swiggy_orders;
```
**Total Revenue (INR Million)**
```sql
SELECT 
    CONCAT(FORMAT(SUM(price_inr) / 1000000, 2), ' INR Million') AS Total_Revenue
FROM fact_swiggy_orders;
```
**Average Dish Price**
```sql
SELECT 
    CONCAT(ROUND(AVG(price_inr), 2), ' INR') AS Average_Price
FROM fact_swiggy_orders;
```
**Average Rating**
```sql
SELECT ROUND(AVG(rating), 2)
FROM fact_swiggy_orders;

```

---

## 15. DEEP-DIVE BUSINESS ANALYSIS
**Goal:**

* Answer key business questions using the star schema.

**Monthly order and revenue trends**
```sql
SELECT 
    d.year,
    d.month,
    d.month_name,
    COUNT(*) AS total_orders,
    SUM(price_INR) AS total_revenue
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.year, d.month, d.month_name
ORDER BY d.year, d.month;
```
**Quarterly order trends**
```sql
SELECT 
    d.year, d.quarter, COUNT(*) AS total_orders
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.year, d.quarter
ORDER BY total_orders;
```
**Day-of-week order patterns**
```sql
SELECT 
    DAYNAME(d.full_date) AS day_name,
    COUNT(f.order_id) AS total_orders
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY day_name, DAYOFWEEK(d.full_date)
ORDER BY DAYOFWEEK(d.full_date);
```
**Top cities by order volume**
```sql
SELECT 
    l.city, COUNT(*) AS total_orders
FROM fact_swiggy_orders f
JOIN dim_location l ON f.location_id = l.location_id
GROUP BY l.city
ORDER BY total_orders DESC
LIMIT 10;
```
**Revenue contribution by states**
```sql
SELECT 
    l.state, SUM(price_INR) AS total_revenue
FROM fact_swiggy_orders f
JOIN dim_location l ON f.location_id = l.location_id
GROUP BY l.state
ORDER BY total_revenue DESC;
```
**Top restaurants by orders**
```sql
SELECT 
    r.restaurant_name, COUNT(*) AS total_order
FROM fact_swiggy_orders f
JOIN dim_restaurant r ON r.restaurant_id = f.restaurant_id
GROUP BY r.restaurant_name
ORDER BY total_order DESC
LIMIT 10;
```
**Top food categories**
```sql
SELECT 
    c.category, COUNT(*) AS total_order
FROM fact_swiggy_orders f
JOIN dim_category c ON c.category_id = f.category_id
GROUP BY c.category
ORDER BY total_order DESC;
```
**Most ordered dishes**
```sql
SELECT 
    d.dish_name, COUNT(*) AS order_count
FROM fact_swiggy_orders f
JOIN dim_dish d ON d.dish_id = f.dish_id
GROUP BY d.dish_name
ORDER BY order_count DESC;
```
**Price range distribution**
```sql
SELECT 
    CASE
        WHEN price_inr < 100 THEN 'Under 100'
        WHEN price_inr BETWEEN 100 AND 199 THEN '100 - 199'
        WHEN price_inr BETWEEN 200 AND 299 THEN '200 - 299'
        WHEN price_inr BETWEEN 300 AND 499 THEN '300 - 499'
        ELSE '500+'
    END AS price_range,
    COUNT(*) AS total_orders
FROM fact_swiggy_orders
GROUP BY price_range
ORDER BY total_orders DESC;
```
**Rating distribution**
```sql
SELECT 
    rating, COUNT(*) AS total_orders
FROM fact_swiggy_orders
GROUP BY rating
ORDER BY rating DESC;

```
