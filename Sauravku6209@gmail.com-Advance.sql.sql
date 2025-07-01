--SQL Advance Case Study
SELECT * FROM DIM_CUSTOMER;
SELECT * FROM DIM_DATE;
SELECT * FROM DIM_LOCATION;
SELECT * FROM DIM_MANUFACTURER;
SELECT * FROM DIM_MODEL;
SELECT * FROM FACT_TRANSACTIONS;

--Q1--BEGIN 
--List all the states in which we have customers who have bought cellphones  from 2005 till today. 	
Select distinct State
from
(
	SELECT l.State,Sum(quantity) as total_quantity ,year(t.Date) as year
	FROM FACT_TRANSACTIONS t 
	left join
	DIM_LOCATION l
	on t.IDLocation = l.IDLocation
	WHERE year(t.Date) >= '2005'
	group by l.State,year(t.Date)
) as a;

--Q1--END

--Q2--BEGIN
--What state in the US is buying the most 'Samsung' cell phones?  	
SELECT TOP 1 State,count(*) as cnt
FROM DIM_LOCATION l
JOIN 
FACT_TRANSACTIONS t
on l.IDLocation=t.IDlocation
JOIN DIM_MODEL m 
on t.IDModel=m.IDModel 
JOIN
DIM_MANUFACTURER mu
on m.IDManufacturer=mu.IDManufacturer
where Country = 'US' and Manufacturer_Name = ('Samsung')
Group By State
Order by cnt desc;
--Q2--END

--Q3--BEGIN      
--Show the number of transactions for each model per zip code per state.  	
SELECT m.Model_Name,l.state,l.ZipCode,Count(t.IDModel) as Number_of_transations
from FACT_TRANSACTIONS t
JOIN DIM_LOCATION l
on t.IDLocation=l.IDLocation
JOIN DIM_MODEL m
on t.IDModel=m.IDModel
group by l.state,l.ZipCode,m.Model_Name;

--Q3--END

--Q4--BEGIN
--Show the cheapest cellphone (Output should contain the price also) 
SELECT TOP 1 Model_Name,min(unit_price) AS MIN_PRICE
FROM DIM_MODEL 
Group BY Model_Name
ORDER BY MIN_PRICE;
--Q4--END

--Q5--BEGIN
--Find out the average price for each model in the top5 manufacturers in  
--terms of sales quantity and order by average price.  
Select t.IDModel,avg(totalprice) as avg_price , sum(quantity) as total_qty 
from 
FACT_TRANSACTIONS t
JOIN
DIM_MODEL m
on t.IDModel=m.IDModel
JOIN
DIM_MANUFACTURER mu
on m.IDManufacturer=mu.IDManufacturer
where Manufacturer_Name in(
                            Select TOP 5 manufacturer_name
							from FACT_TRANSACTIONS t
							join
							DIM_MODEL m
							on t.IDModel=m.IDModel
							join
							DIM_MANUFACTURER mu
							on m.IDManufacturer=mu.IDManufacturer
							group by Manufacturer_Name
							order by sum(totalprice) desc)
Group By t.IDModel
order by avg_price Desc;
--Q5--END

--Q6--BEGIN
--List the names of the customers and the average amount spent in 2009,  
--where the average is higher than 500 
Select customer_name,avg(totalprice) as avg_price
from
DIM_CUSTOMER c
JOIN
FACT_TRANSACTIONS t
on c.IDCustomer=t.IDCustomer
where year(date)=2009
Group by Customer_Name
having avg(totalprice) > 500;

--Q6--END
	
--Q7--BEGIN  
--List if there is any model that was in the top 5 in terms of quantity,  
--simultaneously in 2008, 2009 and 2010
WITH TOP_5_2008 AS
(
SELECT TOP 5 T.IDModel,M.Model_Name
FROM FACT_TRANSACTIONS T
JOIN 
dIM_MODEL M
ON T.IDModel = M.IDModel
WHERE YEAR(T.Date) = 2008
Group by T.IDModel,M.Model_Name
ORDER BY COUNT(T.Quantity) DESC
),
TOP_5_2009 AS
(
SELECT TOP 5 T.IDModel,M.Model_Name
FROM FACT_TRANSACTIONS T
JOIN 
dIM_MODEL M
ON T.IDModel = M.IDModel
WHERE YEAR(T.Date) = 2009
Group by T.IDModel,M.Model_Name
ORDER BY COUNT(T.Quantity) DESC
),
TOP_5_2010 AS
(
SELECT TOP 5 T.IDModel,M.Model_Name
FROM FACT_TRANSACTIONS T
JOIN 
dIM_MODEL M
ON T.IDModel = M.IDModel
WHERE YEAR(T.Date) = 2010
Group by T.IDModel,M.Model_Name
ORDER BY COUNT(T.Quantity) DESC
)
SELECT Model_Name FROM TOP_5_2008
INTERSECT
SELECT Model_Name FROM TOP_5_2009
INTERSECT
SELECT Model_Name FROM TOP_5_2010;

--Q7--END	
--Q8--BEGIN
--Show the manufacturer with the 2nd top sales in the year of 2009 and the  
--manufacturer with the 2nd top sales in the year of 2010.
SELECT * FROM(
		SELECT Top 1 * FROM
		(
			SELECT TOP 2 Manufacturer_Name,YEAR(T.Date) as year,sum(TotalPrice) as Total_sales
			FROM FACT_TRANSACTIONS T
			JOIN
			DIM_MODEL M
			ON T.IDModel=M.IDModel
			JOIN
			DIM_MANUFACTURER U
			ON M.IDManufacturer=U.IDManufacturer
			WHERE YEAR(T.Date)= 2009 
			GROUP BY U.Manufacturer_Name,YEAR(T.Date)
			order By Total_sales DESC
		) AS A
		order by Total_sales
) AS t2
UNION
SELECT * FROM(
			SELECT Top 1 * FROM
			(
				SELECT TOP 2 Manufacturer_Name,YEAR(T.Date) as year,sum(TotalPrice) as Total_sales
				FROM FACT_TRANSACTIONS T
				JOIN
				DIM_MODEL M
				ON T.IDModel=M.IDModel
				JOIN
				DIM_MANUFACTURER U
				ON M.IDManufacturer=U.IDManufacturer
				WHERE YEAR(T.Date)= 2010 
				GROUP BY U.Manufacturer_Name,YEAR(T.Date)
				order By Total_sales DESC
			) AS A
			order by Total_sales
) as t2;
--Q8--END

--Q9--BEGIN
-- Show the manufacturers that sold cellphones in 2010 but did not in 2009.	

(SELECT  M.IDManufacturer,U.Manufacturer_Name
FROM FACT_TRANSACTIONS T
JOIN
DIM_MODEL M
ON T.IDModel=M.IDModel
JOIN
DIM_MANUFACTURER U
ON M.IDManufacturer=U.IDManufacturer
WHERE YEAR(T.Date)= 2010 
GROUP BY M.IDManufacturer,U.Manufacturer_Name)
EXCEPT
(SELECT  M.IDManufacturer,U.Manufacturer_Name
FROM FACT_TRANSACTIONS T
JOIN
DIM_MODEL M
ON T.IDModel=M.IDModel
JOIN
DIM_MANUFACTURER U
ON M.IDManufacturer=U.IDManufacturer
WHERE YEAR(T.Date)= 2009 
GROUP BY M.IDManufacturer,U.Manufacturer_Name);
--Q9--END

--Q10--BEGIN
-- Find top 100 customers and their average spend, average quantity by each  
-- year. Also find the percentage of change in their spend.
SELECT *,((avg_price - lag_price)/lag_price) as percentage_change
from
(
	SELECT *,
	Lag(avg_price,1) over(partition by IDCustomer order by year) as lag_price
	from
	(
		SELECT IDCustomer,year(date) as year,
		avg(totalprice) as avg_price,
		Sum(Quantity) as qty 
		from FACT_TRANSACTIONS
		where IDCustomer in ( SELECT TOP 100 IDCustomer
								from FACT_TRANSACTIONS
								Group by IDCustomer
								order by sum(totalprice) desc)
		Group by IDCustomer,year(date)
	) as a
)as b;















--Q10--END
	