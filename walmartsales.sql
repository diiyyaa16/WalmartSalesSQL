CREATE DATABASE IF NOT EXISTS WalmartSales;

CREATE TABLE IF NOT EXISTS sales(
invoice_id VARCHAR(30) NOT NULL PRIMARY KEY,
branch VARCHAR(5) NOT NULL,
city VARCHAR(30) NOT NULL,
customer_type VARCHAR(30) NOT NULL,
gender VARCHAR(10) NOT NULL,
product_line VARCHAR(100) NOT NULL,
unit_price DECIMAL(10,2) NOT NULL,
quantity INT NOT NULL,
VAT FLOAT(6,4) NOT NULL,
total DECIMAL (12,4) not null,
DATE datetime not null,
time TIME NOT NULL,
payment_method VARCHAR(15) NOT NULL,
cogs DECIMAL(10,2) NOT NULL,
gross_margin_pct FLOAT (11,9),
gross_income DECIMAL (12, 4) NOT NULL,
rating FLOAT (2,1)
);

SELECT * FROM Walmartsales.sales;

#--FEATURE ENGINEERING --#
##using CASE STATEMENT to segregate time of day (morning, afternoon, evening)
SELECT time,
(CASE WHEN 	`time` BETWEEN "00:00:00" AND "12:00:00" THEN "Morning"
WHEN `time` BETWEEN "12:01:00" AND "16:00:00" THEN "Afternoon"
ELSE "Evening"
END) AS time_of_day
FROM sales;

ALTER table sales ADD COLUMN time_of_day VARCHAR(20);

UPDATE sales 
SET time_of_day = (CASE WHEN 	`time` BETWEEN "00:00:00" AND "12:00:00" THEN "Morning"
WHEN `time` BETWEEN "12:01:00" AND "16:00:00" THEN "Afternoon"
ELSE "Evening"
END);

##ADDING DAY NAME

SELECT DATE,
dayname(DATE)
 from sales;
 
 ALTER TABLE sales ADD COLUMN day_name VARCHAR(10);
 
 UPDATE sales
 SET day_name = dayname(DATE);
 
 #ADD MONTH NAME
 
 SELECT date,
 monthname(date)
 FROM Sales;
 
 ALTER TABLE sales ADD COLUMN month_name VARCHAR(15);
 
 UPDATE sales
 SET month_name =  monthname(date);
 
#######EXPLORATORY DATA ANALYSIS#######

#Number of unique cities

SELECT distinct CITY
FROM sales;

#In which city is each branch?

SELECT DISTINCT branch, city
FROM sales;

#How many unique product lines do we have?

SELECT COUNT(DISTINCT product_line) FROM sales;

#What is the most common payment method?

SELECT payment_method,COUNT(payment_method) FROM sales
GROUP BY payment_method
ORDER BY COUNT(payment_method) DESC
LIMIT 1;

#Product line that sells the most

SELECT product_line, COUNT(product_line) from sales
GROUP BY product_line
ORDER BY COUNT(product_line)DESC;


#Total revenue by month

SELECT SUM(total) as revenue,month_name from sales
GROUP BY month_name;

#Month with the largest COGS

select month_name,SUM(cogs) AS cogs from sales
GROUP BY month_name
ORDER BY cogs DESC
limit 1;


# product line with the largest revenue

Select product_line, SUM(total) AS revenue FROM sales
GROUP BY product_line
ORDER BY revenue DESC 
LIMIT 1;

#City with largest revenue

Select city, SUM(total) AS revenue FROM sales
GROUP BY city
ORDER BY revenue DESC 
LIMIT 1;

#Product line with highest VAT

Select product_line, SUM(VAT) AS VAT FROM sales
GROUP BY product_line
ORDER BY VAT DESC 
LIMIT 1;

#Branch that sold more product than average product sold

SELECT branch,
SUM(quantity)
FROM sales
GROUP BY branch
HAVING SUM(quantity) > (SELECT AVG(quantity) FROM sales);

#Common product line by gender

SELECT gender,product_line, COUNT(product_line) as count
FROM sales
GROUP BY gender, product_line
ORDER BY count DESC;

#Average rating for each product line

SELECT product_line, ROUND(AVG(rating),2) as rating 
FROM sales
GROUP by product_line;

#Product line with categorization

SELECT AVG(quantity) 
FROM sales;

SELECT product_line, avg(quantity),
CASE WHEN avg(quantity)> 5.4 THEN "Good"
ELSE "Bad"
END AS remark
FROM sales
GROUP BY product_line;

#Number of sales made according to time of day

SELECT COUNT(*), time_of_day
FROM sales
GROUP BY time_of_Day;

#Types of customer that brings the most revenue

SELECT customer_type, SUM(total) as revenue
FROM sales
GROUP BY customer_type
ORDER BY revenue DESC;

#City with largest tax percent (VAT)

SELECT city, SUM(VAT) as VAT
FROM sales
GROUP BY city
ORDER BY VAT DESC;

#Number of unique customers

SELECT DISTINCT customer_type
from Sales;

#Customer type that buys the most

SELECT customer_type, COUNT(quantity)
FROM sales
GROUP BY customer_type;

#Gender distribution per branch

SELECT 
branch, gender, count(gender) as count
FROM sales
GROUP BY branch, gender
ORDER BY count DESC;

CREATE TABLE customers (
    customer_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    customer_name VARCHAR(50) NOT NULL,
    city VARCHAR(30) NOT NULL,
    gender VARCHAR(10) NOT NULL,
    customer_type VARCHAR(30) NOT NULL
);
INSERT INTO customers (customer_name, city, gender, customer_type)
VALUES
    ('John Doe', 'New York', 'Male', 'Regular'),
    ('Jane Smith', 'Los Angeles', 'Female', 'Regular'),
    ('Michael Johnson', 'Chicago', 'Male', 'VIP'),
    ('Emily Davis', 'Houston', 'Female', 'Regular'),
    ('David Brown', 'Miami', 'Male', 'Regular');
    
    ALTER TABLE sales
ADD COLUMN customer_id INT;

UPDATE sales
SET customer_id = 
    CASE 
        WHEN branch = 'BranchA' THEN 1
        WHEN branch = 'BranchB' THEN 2
        ELSE 3
    END;

##########ADVANCED DQL#####################

#JOINS
#Customer details along with sales

SELECT c.customer_name, c.city, c.gender, c.customer_type, s.total_sales
FROM customers c
JOIN (
    SELECT customer_id, SUM(total) AS total_sales
    FROM sales
    GROUP BY customer_id
) s ON c.customer_id = s.customer_id;

#WINDOWS FUNCTION
#Rank customers based on their spending 

SELECT invoice_id, customer_type, total, 
       RANK() OVER (ORDER BY total DESC) AS customer_rank
FROM sales;

#CTE
#Customers who made multiple purchases on the same day 

WITH multiple_purchases AS (SELECT 
invoice_id, DATE,COUNT(*)
FROM sales
GROUP BY invoice_id, DATE
HAVING COUNT(*)>1)

SELECT * FROM multiple_purchases;

#STORED PROCEDURE
#Total sales for each branch based on given time period
DELIMITER $$

CREATE PROCEDURE CalculateBranchSales(
    IN branch_name VARCHAR(50),
    IN start_date DATE,
    IN end_date DATE
)
BEGIN
    DECLARE total_sales DECIMAL(12, 4);

    SELECT SUM(total) INTO total_sales
    FROM sales
    WHERE branch = branch_name
    AND DATE BETWEEN start_date AND end_date;

    SELECT total_sales AS branch_sales;
END$$

DELIMITER ;


CALL CalculateBranchSales('C', '2019-03-13', '2019-03-30');

#JOINS + AGGREGATION 

SELECT 
    c.customer_id,
    c.customer_name,
    p.product_category,
    SUM(o.order_quantity) AS total_quantity_ordered,
    SUM(o.order_quantity * o.unit_price) AS total_order_value
FROM 
    customers c
JOIN 
    orders o ON c.customer_id = o.customer_id
JOIN 
    products p ON o.product_id = p.product_id
WHERE 
    o.order_date BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    c.customer_id, c.customer_name, p.product_category
ORDER BY 
    total_order_value DESC;
