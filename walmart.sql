
-- EDA - Lets get to know our data

-- lets see the data
select * from walmart;

-- lets verify the rows 
select count(*) from walmart; -- 9969

-- lets look at the different types of payment methods 
select distinct(payment_method) from walmart; --Credit card, Ewallet, Cash

-- we can also see the total num of transactions that took place via each method

select payment_method, count(*)
from walmart
group by payment_method; -- Credit card : 4256, Ewallet : 3881, Cash : 1832

-- lets check the cities we have this data for
select count(distinct(city)) from walmart;  -- there are 98 city

-- lets see the branches
select count(distinct(branch)) from walmart; --100

-- we can see where does each branch belong to
select city, count(branch)
from walmart
group by city; 
 
-- check the max and min qty

select max(quantity)
from walmart;  -- 10

select min(quantity)
from walmart;  -- 1


-- check the max and min rating

select max(rating)
from walmart;  -- 10

select min(rating)
from walmart;  -- 3


-- check the max and min unit price

select max(unit_price)
from walmart;  -- 99.96

select min(unit_price)
from walmart;  -- 10.08



-- check the max and min total amount

select max(total_amt)
from walmart;  -- 993 dollars

select min(total_amt)
from walmart;  -- 10.17 dollars
-------------------------------------------------------------------------------------------------------------------------

-- LETS SEE THE QUESTIONS

-------------------------------------------------------------------------------------------------------------------------

-- 1. Analyze Payment Methods and Sales
--● Question: What are the different payment methods, and how many transactions and items were sold with each method?
-- ● Purpose: This helps understand customer preferences for payment methods, aiding in payment optimization strategies.

select * from walmart;

select payment_method, count(invoice_id) as total_transactions, count(quantity) as total_items_sold
from walmart
group by payment_method;

-------------------------------------------------------------------------------------------------------------------------

-- 2. Identify the Highest-Rated Category in Each Branch
-- ● Question: Which category received the highest average rating in each branch and category?
-- ● Purpose: This allows Walmart to recognize and promote popular categories in specific branches, enhancing customer satisfaction and branch-specific marketing.

select * from walmart;

-- The rating is a double precision so lets convert first to numeric so we can round it

select * from
	(select branch,category, round(avg(rating) :: NUMERIC, 2) as average_rating,
		RANK() OVER(partition by branch order by round(avg(rating) :: NUMERIC, 2) desc) as rank
	from walmart
	group by branch, category)
where rank =1

-------------------------------------------------------------------------------------------------------------------------

-- 3. Determine the Busiest Day for Each Branch
-- ● Question: What is the busiest day of the week for each branch based on transaction volume?
-- ● Purpose: This insight helps in optimizing staffing and inventory management to accommodate peak days.

select * from walmart;
-- convert date type from text to date
select * from 
	(select branch, 
		TO_CHAR(TO_DATE(date, 'DD/MM/YY'), 'Day') as day_name, --first convert to date and find the day
		count(*) as num_transactions,
		RANK() OVER(partition by branch order by count(*) desc ) as rank
	from walmart
	group by 1,2)
where rank = 1;

-------------------------------------------------------------------------------------------------------------------------

-- 4. Calculate Total Quantity Sold by Payment Method
-- ● Question: How many items were sold through each payment method?
-- ● Purpose: This helps Walmart track sales volume by payment type, providing insights into customer purchasing habits.

select * from walmart;


select payment_method, count(quantity)as total_quantity_sold
from walmart
group by payment_method

-------------------------------------------------------------------------------------------------------------------------

-- 5. Analyze Category Ratings by City
-- ● Question: What are the average, minimum, and maximum ratings for each category in each city?
-- ● Purpose: This data can guide city-level promotions, allowing Walmart to address regional preferences and improve customer experiences.

select * from walmart;

select city, category, round(avg(rating) :: NUMERIC, 2) as average_rating, min(rating) as minimum_ratings, max(rating) as maximum_ratings
from walmart
group by 1, 2
order by 1,3 desc

-------------------------------------------------------------------------------------------------------------------------

-- 6. Calculate Total Profit by Category
-- ● Question: What is the total profit for each category, ranked from highest to lowest?
-- ● Purpose: Identifying high-profit categories helps focus efforts on expanding these products or managing pricing strategies effectively.

select * from walmart;

select category, 
	round(sum(total_amt) :: NUMERIC, 2) as total_revenue,
	round(sum(total_amt * profit_margin) :: NUMERIC,2) as total_profit
from walmart
group by 1
order by 3 desc;

-------------------------------------------------------------------------------------------------------------------------

-- 7. Determine the Most Common Payment Method per Branch
-- ● Question: What is the most frequently used payment method in each branch? Display branch and the preferred payment method
-- ● Purpose: This information aids in understanding branch-specific payment preferences, potentially allowing branches to streamline their payment processing systems.

select * from walmart;

select branch, payment_method, count(*) total_count,
	rank() over(partition by branch order by count(*) desc) as rank
from walmart
group by branch, payment_method;

-- with cte

WITH cte
as 
	(select branch, payment_method, count(*) total_count,
		rank() over(partition by branch order by count(*) desc) as rank
	from walmart
	group by branch, payment_method)

select  * 
from cte
where rank = 1;

-------------------------------------------------------------------------------------------------------------------------

-- 8. Analyze Sales Shifts Throughout the Day
-- ● Question: How many transactions occur in each shift (Morning, Afternoon, Evening) across branches?
-- ● Purpose: This insight helps in managing staff shifts and stock replenishment schedules, especially during high-sales periods.

select * from walmart;

-- based on time column, we need to categorize. First change time from text to time

select branch, 
	CASE 
		WHEN EXTRACT (HOUR FROM(time::time)) < 12 THEN 'Morning'
		WHEN EXTRACT (HOUR FROM(time::time)) BETWEEN 12 AND 17 THEN 'Afternoon'
		ELSE 'Evening'
	END day_time,
	count(*)
from walmart
group by 1,2
order by 1,3 desc;

-------------------------------------------------------------------------------------------------------------------------

-- 9. Identify 5 Branches with Highest Revenue Decline Year-Over-Year
-- ● Question: Which branches experienced the largest decrease in revenue compared to the previous year?
-- ● Purpose: Detecting branches with declining revenue is crucial for understanding possible local issues and creating strategies to boost sales or mitigate losses.

select * from walmart;

--rdr = last_rev - cr_rev / last_rev*100

-- i want the total revenue for the years 2023 and 2022 and then take the ratio
select *, 
	EXTRACT(YEAR FROM TO_DATE(date, 'DD/MM/YY')) as formatted_date
from walmart

-- 2022 sales 
with rev_2022
as
(
	select branch, sum(total_amt) as revenue
	from walmart
	where EXTRACT(YEAR FROM TO_DATE(date, 'DD/MM/YY')) = 2022
	group by branch
), 



-- 2023 sales 
rev_2023
as 
(
	select branch, sum(total_amt) as revenue
	from walmart
	where EXTRACT(YEAR FROM TO_DATE(date, 'DD/MM/YY')) = 2023
	group by branch
)

-- lets join them
select ls.branch, 
		ls.revenue as last_year_rev,
		cs.revenue as current_year_rev,
		round(
			(ls.revenue - cs.revenue) :: numeric / 
			ls.revenue :: numeric * 100, 
			2) as revenue_dec_ratio

from rev_2022 as ls
join rev_2023 as cs
on ls.branch = cs.branch
where ls.revenue > cs.revenue
order by 4 desc
LIMIT 5;

-------------------------------------------------------------------------------------------------------------------------