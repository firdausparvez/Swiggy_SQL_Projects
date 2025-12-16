# Swiggy Food Delivery Sales Analysis | SQL Project

### Quick Summary
This is an end-to-end SQL data analytics project based on Swiggy food delivery data.
The project demonstrates how raw transactional data is cleaned, structured, and analyzed to generate business-ready insights using SQL.

**Skills Demonstrated:**

* Data Cleaning & Validation · Deduplication · Star Schema Modeling · KPI Development · Business Analysis · Window Functions

> *"**Note:** Review the logic behind the validation checks, deduplication strategies, and complex joins in the **[Technical SQL Walkthrough](SQL_WALKTHROUGH.md)**."*

---
### Data Model (Star Schema)
The project uses a **Star Schema** to support efficient analytics and reporting. A central fact table is connected to multiple dimension tables, enabling simplified queries and scalable analysis.

![Swiggy Star Schema](https://github.com/user-attachments/assets/9334f424-4a98-481e-a5f6-f5e1184bf431)


**Fact Table:**
* `fact_swiggy_orders`
    * **Measures:** `Price_INR`, `Rating`, `Rating_Count`
    * **Keys:** Foreign keys linking to all dimension tables

**Dimension Tables:**
* `dim_date` – Year, Month, Quarter, Week
* `dim_location` – State, City, Location
* `dim_restaurant` – Restaurant name
* `dim_category` – Cuisine / Food category
* `dim_dish` – Dish name

---

### Business Context
The dataset contains food delivery orders across:
* States and cities
* Restaurants and locations
* Food categories and dishes

**The Challenge:**
The raw data was not analysis-ready due to missing values, inconsistent text fields, and duplicate records.

**The Goal:**
To prepare clean, structured data and analyze it to understand **Order trends**, **Revenue patterns**, **Customer spending behavior**, and **Food performance**.

---

### Data Cleaning & Validation
To ensure reliable analysis, the following steps were performed:

**1. Null and Blank Value Handling**
* Checked missing values in key columns such as location, dish, price, rating, and date.
* Removed extra spaces using `TRIM()`.
* Converted blank strings into `NULL`.
> **Why it matters:** Prevents incorrect grouping, filtering issues, and misleading aggregates.

**2. Duplicate Detection & Removal**
* Identified duplicate records using business-critical columns.
* Used the `ROW_NUMBER()` window function to retain one valid record per order.
> **Why it matters:** Duplicates inflate KPIs such as total orders and total revenue.

---

### Dimensional Modeling
After cleaning, the data was transformed into a Star Schema, a standard design used in analytics and BI systems.

**Benefits of this design:**
* Faster query performance
* Simpler SQL for reporting
* Analytics-ready structure

---

### Key KPIs Developed
* **Total Orders**
* **Total Revenue**
* **Average Dish Price**
* **Average Customer Rating**

These KPIs provide a high-level view of platform performance.

---

### Business Analysis & Insights
The cleaned and modeled data were analyzed to derive the following insights:

* **Location Trends:** A small group of top cities contributes a significant share of total orders and revenue.
* **Price Behavior:** Most orders fall within the **₹100–₹299** range, indicating a budget-conscious customer base.
* **Ratings Impact:** Lower-rated dishes tend to show weaker repeat demand compared to higher-rated items.
* **Time Patterns:** Order volume is consistently higher on **weekends** than on weekdays.

*These insights demonstrate how SQL can be used to translate raw data into actionable business understanding.*

---

### Tools & Skills Used
* **SQL (MySQL)**
* **Data Cleaning & Validation**
* **Window Functions**
* **Deduplication Techniques**
* **Star Schema / Dimensional Modeling**
* **Business-Focused Data Analysis**

---

### Key Takeaways
* Managed the full analytics lifecycle from raw data to insights.
* Learned the importance of data quality before KPI analysis.
* Applied industry-style data modeling for scalable analysis.
* Focused on answering business questions, not just writing queries.
---
## 🤝 Connect with Me
I am currently **Open to Work** and actively seeking full-time **Data Analyst** opportunities. If you are looking for someone who can transform raw data into actionable insights, I would love to chat!

* 💼 **LinkedIn:** [Let's Connect!](https://www.linkedin.com/in/firdaus-parvez/)
* 📧 **Email:** [firdaus.parvez290@gmail.com](mailto:firdaus.parvez290@gmail.com)

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/firdaus-parvez/)
[![Email](https://img.shields.io/badge/Gmail-D14836?style=for-the-badge&logo=gmail&logoColor=white)](mailto:firdaus.parvez290@gmail.com)
