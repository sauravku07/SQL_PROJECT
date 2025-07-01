
-- status, -- text rating


-- Total Views
WITH Total_views as
(
SELECT
	content_ID,
	COUNT(content_ID) as total_views
FROM
tbl_Consumption
GROUP by content_id
),

-- Completion Rate
Completion_Rate as 
(
SELECT 
	content_Id, 
	Round(Sum(user_duration)*100/ Sum(content_duration),2) as completion_rate
FROM tbl_consumption
GROUP BY content_id
),

-- Rating

 ALL_rating as
(
SELECT 
usersessionid, 
	CASE
		WHEN rating='Awesome' THEN 4
		WHEN rating='Good' Then 3
		When rating='BAD' Then 2
		When rating='Terrible' Then 1
		ELSe NULL
	END as rating_score

from tbl_rating
),
Content_rating as 
(
Select 
	content_Id,
	Sum(cast(rating_score as float)) / count(rating_score) as avg_rating,
	Count(rating_score) as number_of_ratings

From tbl_consumption con
INNER JOIN ALL_rating R
ON con.usersessionid=R.usersessionid
GROUP By content_id
),

Content_Live as 
(
Select 
	content_ID,
	DATEDIFF(Month,Date_added,'01-01-2022') as month_live
From tbl_catalogue
Where DATEDIFF(Month,Date_added,'01-01-2022')>6
)


SELECT cat.content_ID, cat.status, TV.total_views, CR.completion_rate, S.avg_rating, S.number_of_ratings

FROM 
tbl_Catalogue cat
LEFT JOIN Total_views TV ON cat.content_id=TV.content_id
LEFT JOIN Completion_Rate CR ON cat.content_ID=CR.content_ID
LEFT JOIN Content_rating S ON cat.content_Id=S.content_ID
INNER JOIN Content_live CL ON Cat.content_id=CL.content_id
Where 
cat.status='Live'
and
S.number_of_ratings>300

--Completion_Rate
--Content_rating
--Total_views 

