-- The first query to see the contents of all columns in the table
SELECT *
FROM courier;

-- JOIN all tables to see which column to use for analysis
SELECT *
FROM courier c1
JOIN mapping_province m1
	ON c1.province_code = m1.province_code;

-- Change data type that still doesn't match the contents of the column using CAST function
SELECT
	CAST(expedition AS character varying)
FROM courier;

-- Looking for data that has a NULL value
SELECT id
FROM courier
WHERE id IS NULL;

SELECT province_code
FROM mapping_province
WHERE province_code IS NULL;

-- Combines the columns that will be used to create a new table file
SELECT
	id,
	expedition,
	mode_of_shipment,
	customer_care_calls,
	customer_rating,
	cost_of_the_product,
	prior_purchases,
	product_importance,
	gender,
	discount_offered,
	weight_in_gms,
	delay_or_ontime,
	province
FROM (
	SELECT *
	FROM courier c1
	JOIN mapping_province m1
		ON c1.province_code = m1.province_code ) tablebefore;

-- Look for outlier data by using shipping rate price data
WITH percentile AS(
		SELECT percentile_cont(0.25) within group (order by cost_of_the_product) q1,
			percentile_cont(0.75) within group (order by cost_of_the_product) q3
		FROM courier),

	iqrtable AS(
		SELECT q3-q1 AS iqr
		FROM percentile),

	outlier AS(
		SELECT 
			q1-(1.5*iqr) minimum,
			q3+(1.5*iqr) maximum
		FROM percentile
		JOIN iqrtable
		ON 1=1)
	
SELECT typeoutlier, count(typeoutlier)
FROM(
	SELECT 
		cost_of_the_product,
		CASE 
			WHEN cost_of_the_product <= 660744 THEN 'negative outlier'
			WHEN cost_of_the_product >= 5372136 THEN 'positive outlier'
			ELSE 'inlier'
			END AS typeoutlier
	FROM courier) t2
GROUP BY 1;

-- Look for outlier data by using data on the number of expedition users
WITH tableuses AS(
		SELECT expedition, count(expedition) AS numberofuses
		FROM courier
		GROUP BY 1),
	percentile AS(
		SELECT 
			percentile_cont(0.25) within group (order by numberofuses) q1,
			percentile_cont(0.75) within group (order by numberofuses) q3
		FROM tableuses),
	iqrtable AS(
		SELECT q3-q1 AS iqr
		FROM percentile),
	outlier AS(
		SELECT 
			q1-(1.5*iqr) minimum,
			q3+(1.5*iqr) maximum
		FROM percentile
		JOIN iqrtable
		ON 1=1)
SELECT 
	expedition,
	CASE 
		WHEN numberofuses <= 1831.5 THEN 'negative outlier'
		WHEN numberofuses >= 1835.5 THEN 'positive outlier'
		ELSE 'inlier'
		END AS typeoutlier
FROM tableuses;

-- How to change data dimensions using ALTER function
ALTER TABLE courier
ALTER COLUMN id TYPE character varying
USING id::character varying;


