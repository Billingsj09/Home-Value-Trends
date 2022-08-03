--1. How many distinct zip codes are in this dataset?

SELECT COUNT(DISTINCT zip_code)
FROM home_value_data;	

-- 2. How many zip codes are from each state?

SELECT state, COUNT(DISTINCT zip_code)
FROM home_value_data
GROUP BY 1;	

-- 3. What range of years are represented in the data?

SELECT 
	MIN(substr(date, 1, 4)) || ' - ' || MAX(substr(date, 1, 4)) AS 'Year Range'
FROM home_value_data;

-- 4. Using the most recent month of data available, what is the range of estimated home values across the nation?

SELECT date, value
FROM home_value_data
WHERE date = (SELECT MAX(date) FROM home_value_data)
ORDER BY 2;

-- 5. Using the most recent month of data available, which states have the highest average home values? How about the lowest?

SELECT date, state, ROUND(AVG(value), 2) 'Avg Value'
FROM home_value_data 
WHERE date = (SELECT MAX(date) FROM home_value_data)
GROUP BY state
ORDER BY 3 DESC;

-- 6. Which states have the highest/lowest average home values for the year of 2017?

SELECT substr(date, 1, 4) AS 'Year', state, ROUND(AVG(value), 2) 'Average Value'
FROM home_value_data
WHERE substr(date, 1, 4) = '2017'
GROUP BY state
ORDER BY 3 DESC;

-- Intermediate Problems

-- 7. What is the percent change 59 in average home values from 2007 to 2017 by state?

WITH baseyear AS(
		SELECT state, 
		substr(date, 1, 4), 
		ROUND(AVG(value), 2) AS 'Average'
	FROM home_value_data 
	WHERE substr(date, 1, 4) = '2007'
	GROUP BY 1
), 
	
	endyear AS(
		SELECT state, 
		substr(date, 1, 4), 
		ROUND(AVG(value), 2) AS 'Average'
	FROM home_value_data
	WHERE substr(date, 1, 4) = '2017'
	GROUP BY 1
)

SELECT 
	baseyear.state, 
	baseyear.Average 'Base Average', 
	endyear.Average 'End Average', 
	ROUND((endyear.Average - baseyear.Average)/baseyear.Average * 100,1) 'Percent Change'
FROM baseyear
JOIN endyear 
ON baseyear.state = endyear.state; 

-- 8. How would you describe the trend in home values for each state from 2007 to 2017?

WITH new_val AS(
	SELECT	
		substr(date,1,4) year,
		state,
		ROUND(AVG(value),2) AS average
	FROM home_value_data
	WHERE year = '2017'
	GROUP BY 2,1
),
	old_val1 AS(
	SELECT	
		substr(date,1,4) year,
		state,
		ROUND(AVG(value),2) AS average
	FROM home_value_data
	WHERE year = '2007'
	GROUP BY 2,1
),
	old_val2 AS(
	SELECT	
		substr(date,1,4) year,
		state,
		ROUND(AVG(value),2) AS average
	FROM home_value_data
	WHERE year = '1997'
	GROUP BY 2,1
)

SELECT 
	new_val.state,
	old_val2.average '1997 Average',
	ROUND((100.0 * (new_val.average - old_val2.average) / old_val2.average),2) AS '% Change 1997-2017',
	old_val1.average '2007 Average',
	ROUND((100.0 * (new_val.average - old_val1.average) / old_val1.average),2) AS '% Change 2007-2017',
	new_val.average '2017 Average'
FROM new_val
JOIN old_val1
	ON new_val.state = old_val1.state
JOIN old_val2
	ON old_val1.state = old_val2.state
ORDER BY 3 DESC, 5 DESC;


--OR--

WITH table1 AS (
	SELECT state, AVG(value) AS baseYear
	FROM home_value_data
	WHERE substr(date, 1, 4) = '1997'
GROUP BY 1),

table2 AS (
	SELECT state, AVG(value) AS testYear
	FROM home_value_data
	WHERE substr(date, 1, 4) = '2017'
GROUP BY 1),

--In order to be able to use CASE statement for Trend, we have to add the calculation to WITH statement

table3 AS(
	SELECT table1.state, ROUND(((testYear / baseYear)*100)-100, 2) AS Trend
	FROM table1, table2
GROUP BY 1)

SELECT state, Trend,
	CASE
		WHEN Trend > 150 THEN 'Recommended'
		ELSE 'Not Recommended'
	END AS 'Verdict'
FROM table3
GROUP BY 1;


/* Join the house value data with the table of zip-code level census data. 
	Do there seem to be any correlations between the estimated house values and 
	characteristics of the area, such as population count or median household income? */
SELECT 
	census_data.zip_code, 
	state, 
	pop_total, 
	median_household_income, 
	ROUND(AVG(value),2) AS 'Average Home Value'
FROM census_data
JOIN home_value_data
ON census_data.zip_code = home_value_data.zip_code
WHERE median_household_income != 'NULL'
GROUP BY 1
ORDER BY 4
LIMIT 100;