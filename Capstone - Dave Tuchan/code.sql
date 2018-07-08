--Code written by: Dave Tuchan, Date: 8th of July 2018, Capstone Churn Rates 

--1. Get familiar with the company
SELECT MIN(subscription_start) AS 'First subscription',
       MAX(subscription_start) AS 'Last subscription'
FROM subscriptions;

SELECT DISTINCT segment
FROM subscriptions;

--2. Overall churn trend since the company started &
--3. Compare the churn rates between user segments

--Temporary table: Months
WITH months AS (
SELECT
  '2017-01-01' AS first_day,
  '2017-01-31' AS last_day
UNION
SELECT
  '2017-02-01' AS first_day,
  '2017-02-28' AS last_day
UNION
SELECT
  '2017-03-01' AS first_day,
  '2017-03-31' AS last_day
),
--Temporary table: Subscriptions combined with Months
cross_join AS (
SELECT *
FROM subscriptions
CROSS JOIN months
),
--Temporary table: Active / Canceled users
status AS (
SELECT id, 
       first_day AS 'month',
       CASE
       	WHEN (segment = '87')
  	AND (subscription_start < first_day)
  	AND ((subscription_end > first_day)
              OR (subscription_end IS NULL))
  	THEN 1
  	ELSE 0
       END AS 'is_active_87',
       CASE
	WHEN (segment = '30')
  	AND (subscription_start < first_day)
  	AND ((subscription_end > first_day)
              OR (subscription_end IS NULL))
  	THEN 1
  	ELSE 0            
       END AS 'is_active_30',      
       CASE
       	WHEN (segment = '87')
  	AND (subscription_end 
             BETWEEN first_day 
             AND last_day)
  	THEN 1
  	ELSE 0
       END AS 'is_canceled_87',
       CASE
	WHEN (segment = '30')
  	AND (subscription_end 
             BETWEEN first_day 
             AND last_day)
  	THEN 1
  	ELSE 0            
       END AS 'is_canceled_30'  
FROM cross_join
),
--Temporary table: Aggregated fields
status_aggregate AS (
SELECT month, 
       SUM(is_active_30) AS 'sum_active_30',
       SUM(is_active_87) AS 'sum_active_87',
       SUM(is_canceled_30) AS 'sum_canceled_30',
       SUM(is_canceled_87) AS 'sum_canceled_87',
       SUM(is_active_30) + SUM(is_active_87) AS 'Sum_active_total',
       SUM(is_canceled_30) + SUM(is_canceled_87) AS 'Sum_canceled_total'
FROM status
GROUP BY 1
ORDER BY 1 ASC
)
--Calculate churn rate statistics
SELECT month,
       ROUND(1.0 * sum_canceled_87 / 
             sum_active_87 * 100, 2) AS 'Segment 87',
       ROUND(1.0 * sum_canceled_30 /
             sum_active_30 * 100, 2) AS 'Segment 30',
       ROUND(1.0 *  Sum_canceled_total / 
             Sum_active_total * 100, 2) AS 'Overall'
FROM status_aggregate
GROUP BY 1
ORDER BY 1 ASC;