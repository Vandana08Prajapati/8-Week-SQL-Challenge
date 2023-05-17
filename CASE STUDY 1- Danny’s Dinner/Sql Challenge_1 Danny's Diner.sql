-- Danny Ma 8 Week SQL Challenge: Case Study- 1 : Danny's Dinner

CREATE DATABASE dannys_diner; -- creates the database
USE dannys_diner;   -- sets the database as the current database

-- creating the sales table
CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
 );
 
 -- inserting values into the sales table
INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
  
  
  -- creating the menu table
CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

-- inserting values into the menu table
INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

-- creating the members table
CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

-- inserting values into the members table
INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
---------------------------------------------- CASE STUDY QUESTIONS -----------------------------------------------------------

-- 1. What is the total amount each customer spent at the restaurant ?
-- soln1 
SELECT customer_id, SUM(price) as total_spent
FROM sales s
INNER JOIN menu m
ON s.product_id = m.product_id
GROUP BY 1
ORDER BY 1;

-- soln2 
SELECT s.customer_id,
	   concat('$ ',SUM(m.price)) AS total_amount_spent
FROM sales AS s
     INNER JOIN menu m 
     USING(product_id)
GROUP BY s.customer_id
ORDER BY total_amount_spent DESC;

-- Q2. How many days has each customer visited the restaurant?
SELECT customer_id,
  COUNT(DISTINCT order_date)as days
FROM sales
GROUP BY customer_id
ORDER BY customer_id;

-- Q3. What was the first item from the menu purchased by each customer?
WITH first_purchase AS(
SELECT customer_id,  MIN(order_date) AS min_date
FROM sales 
 GROUP BY customer_id  )
SELECT DISTINCT s.customer_id,  f.min_date,  s.product_id,  m.product_name
FROM sales AS S
INNER JOIN first_purchase AS f
ON f.customer_id = S.customer_id 
AND f.min_date = S.order_date
INNER JOIN menu m 
ON m.product_id = s.product_id
ORDER BY s.customer_id;

-- Q4. What is the most purchased item on the menu and how many times was it purchased by all customers ?
-- soln1
SELECT product_name,  COUNT(*) as number_items,
ROW_NUMBER() OVER(ORDER BY COUNT(*) desc)as ranking
FROM sales S
LEFT JOIN menu M
ON S.product_id = M.product_id 
GROUP BY product_name 
ORDER BY 2 DESC;

-- soln2
SELECT m.product_id,  m.product_name,  COUNT(*) AS number_of_orders
FROM sales AS s 
INNER JOIN menu m
USING(product_id)
GROUP BY m.product_id, m.product_name
ORDER BY number_of_orders DESC
LIMIT 1;

-- Q5. Which item was the most popular for each customer?
WITH item_rank AS(
SELECT customer_id,  product_name,  COUNT(*) as number_items,
ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY COUNT(*) desc)as ranking
FROM sales S
LEFT JOIN menu M
ON S.product_id = M.product_id 
GROUP BY 1,2 
ORDER BY 1,3 DESC  )
SELECT customer_id, product_name, number_items
FROM item_rank 
WHERE ranking = 1;

-- Q6. Which item was purchased first by the customer after they became a member?
WITH item_rank AS(
SELECT S.customer_id, order_date, join_date, product_name,
ROW_NUMBER() OVER(PARTITION BY S.customer_id ORDER BY order_date)as ranking
FROM sales S
LEFT JOIN menu m1 ON S.product_id = m1.product_id
LEFT JOIN members m2 ON S.customer_id = m2.customer_id
WHERE order_date >= join_date   )
SELECT customer_id,  order_date as first_date,  product_name as first_item
FROM item_rank
WHERE ranking = 1; 

-- Q7. Which item was purchased just before the customer became a member ?
WITH item_rank AS(
SELECT S.customer_id, order_date, join_date, product_name,
ROW_NUMBER() OVER(PARTITION BY S.customer_id ORDER BY order_date)as ranking
FROM sales S
LEFT JOIN menu m1 ON S.product_id = m1.product_id
LEFT JOIN members m2 ON S.customer_id = m2.customer_id
WHERE order_date < join_date	)
 
 SELECT customer_id,  order_date as date_before_member,  product_name as first_item
 FROM item_rank
 WHERE ranking = 1;
 
 -- Q8. What is the total items and amount spent for each member before they became a member?
SELECT S.customer_id,  COUNT(S.product_id)as total_items,  SUM(price)as amount_spent
FROM sales S
LEFT JOIN menu m1 ON S.product_id = m1.product_id
LEFT JOIN members m2 ON S.customer_id = m2.customer_id
 WHERE order_date < join_date
 GROUP BY customer_id
 ORDER BY customer_id;
 
 -- Q9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
 SELECT s.customer_id, SUM(CASE WHEN m.product_name = 'sushi' THEN 10 * 2 * m.price
 ELSE 10 * m.price END) AS total_points
 FROM sales AS s
 INNER JOIN menu AS m  ON s.product_id = m.product_id
 GROUP BY s.customer_id
 ORDER BY customer_id;
 
 -- Q10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - 
 -- how many points do customer A and B have at the end of January?
 
 WITH pointers AS (
SELECT s.customer_id,  s.order_date,  m.join_date,
	 DATE_ADD(m.join_date, INTERVAL 7 DAY) 
	 AS week_after_join_date, me.product_name,   me.price
     FROM sales AS s
	 INNER JOIN menu AS me
	 ON me.product_id = s.product_id
	 INNER JOIN members AS m
	 ON m.customer_id = s.customer_id        )
SELECT customer_id,
    SUM(CASE WHEN order_date BETWEEN join_date AND week_after_join_date 
                  THEN 2 * 10 * price
		WHEN order_date NOT BETWEEN join_date AND week_after_join_date 
                  AND product_name = 'sushi' THEN 2 * 10 * price
		WHEN order_date NOT BETWEEN join_date AND week_after_join_date 
                  AND product_name != 'sushi' THEN 10 * price
		END) AS total_points
FROM pointers
WHERE MONTH(order_date) = 1
GROUP BY customer_id
ORDER BY customer_id;

---------------------------------------------- Bonus Questions -------------------------------------------------------------

Join All The Things -------- Recreating the table

CREATE TEMPORARY TABLE IF NOT EXISTS updated_customers
SELECT s.customer_id,  s.order_date, me.product_name, me.price,
CASE WHEN s.order_date < m.join_date THEN 'N'
	 WHEN s.order_date >= m.join_date THEN 'Y'
	 ELSE 'N' 
	 END AS member
FROM sales AS s
LEFT JOIN menu AS me  ON me.product_id = s.product_id
LEFT JOIN members AS m ON m.customer_id = s.customer_id;

Rank All The Things ---------------------------------------------
SELECT *,
    CASE WHEN member = 'Y' THEN 
	RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date)
	END AS ranking
FROM updated_customers -- temporary table created in the previous table
 
 ------------------------------------------------Insight and Recommendation -------------------------------------------------------
 
Insight :
-- Customer patterns improved during January. For customer A’s total spend, that increased 67% from $25 to $76. And for customer B’s total spend, this increased 46% from $40 to $74.
-- Customer B was the person who frequents the restaurant the most. Meanwhile, Customer A generated the highest total spending and it could be an initial diagnosis of a customer being interested or satisfied with the menu.
-- Ramen was favourite menu for customer A and C whereas B likes all three items equally as per the data.
-- Even though Ramen was popular but before and after joining ‘Customer loyalty’ program, both customer ordered ‘sushi’ and ‘curry’.
-- Customer A was the first ‘Loyal Customer’ followed by B .
-- Customer C has purchased the lowest out of all three customer and also, he is not a member of ‘loyalty program’.

Recommendation :
-- Find out what makes sushi their favorite menu for customers made first order and apply the same strategy in other customer cities.
-- With the majority of revenue coming from members, Danny and team can focus campaigns and budgets on loyal and potential customers.
-- The restaurant should utilize customer and product information for marketing strategies that will help in get loyal customer.
