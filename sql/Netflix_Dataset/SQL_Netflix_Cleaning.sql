-- Pre-defined new table structure.
CREATE TABLE netflix_raw (
	show_id varchar(10),
	type varchar(10),
	title varchar(200),
	director varchar(250),
	"cast" varchar(1000),
	country varchar(150),
	date_added varchar(25),
	release_year int,
	rating varchar(10),
	duration varchar(15),
	listed_in varchar(100),
	description varchar(500)
)


-- Find any duplicated row for primary key (soon to be)
SELECT
	show_id,
	COUNT(*)
FROM netflix_raw
GROUP BY 1
HAVING COUNT(*) > 1
-- Duplicated row doesnt exist


-- Find any null value for each column
SELECT
	COUNT(*) FILTER(WHERE show_id IS NULL) AS show_id,
	COUNT(*) FILTER(WHERE type IS NULL) AS type,
	COUNT(*) FILTER(WHERE title IS NULL) AS title,
	COUNT(*) FILTER(WHERE director IS NULL) AS director,
	COUNT(*) FILTER(WHERE "cast" IS NULL) AS cast,
	COUNT(*) FILTER(WHERE country IS NULL) AS country,
	COUNT(*) FILTER(WHERE date_added IS NULL) AS date_added,
	COUNT(*) FILTER(WHERE release_year IS NULL) AS release_year,
	COUNT(*) FILTER(WHERE rating IS NULL) AS rating,
	COUNT(*) FILTER(WHERE duration IS NULL) AS duration,
	COUNT(*) FILTER(WHERE listed_in IS NULL) AS listed_in,
	COUNT(*) FILTER(WHERE description IS NULL) AS description
FROM netflix_raw
-- Found null values in director (2634), cast (825), country (832), date_added (10), rating (4), and duration (3)


-- show_id no duplicated row, no null value. Set to primary key
ALTER TABLE netflix_raw
ADD CONSTRAINT pk_showid PRIMARY KEY (show_id)


-- Find duplicated row in similar show_id
SELECT
	*
FROM netflix_raw
WHERE TRIM(LOWER(title)) IN (
	SELECT
		title
	FROM (
		SELECT
			TRIM(LOWER(title)) AS title,
			COUNT(TRIM(LOWER(title))) AS freq
		FROM netflix_raw
		GROUP BY TRIM(LOWER(title))
		HAVING COUNT(TRIM(LOWER(title))) > 1
		)
)
ORDER BY title
-- Found 10 rows result with 6 rows with exact data


-- Specify finding to exact data. Duplicated row with 2 considerations. Same title and type.
SELECT
	*
FROM netflix_raw
WHERE TRIM(LOWER(title)) IN (
	SELECT
		title
	FROM (
		SELECT
			TRIM(LOWER(title)) AS title,
			type,
			COUNT(*) AS freq
		FROM netflix_raw
		GROUP BY 1, 2
		HAVING COUNT(*) > 1
		)
)


-- Generate full table without duplicated title and type
WITH vt AS (
	SELECT
		*,
		ROW_NUMBER() OVER (PARTITION BY LOWER(title), type ORDER BY show_id) AS freq
	FROM netflix_raw
)
SELECT
	*
FROM vt
WHERE freq = 1
-- Found 8804 rows, 3 rows are duplicated title and type


-- Assign different table dedicated for show_id with (single) director, listed_in, country, and cast
-- Assign cast
SELECT
	show_id,
	TRIM(UNNEST(STRING_TO_ARRAY("cast", ','))) AS cast_name
INTO netflix_cast
FROM netflix_raw
-- Successfully attempt 64126 entries

-- Assign listed_in
SELECT
	show_id,
	TRIM(UNNEST(STRING_TO_ARRAY(listed_in, ','))) AS genre_name
INTO netflix_genre
FROM netflix_raw
-- Successfully attempt 19323 entries

-- Assign country
SELECT
	show_id,
	TRIM(UNNEST(STRING_TO_ARRAY(country, ','))) AS country_name
INTO netflix_country
FROM netflix_raw
-- Successfully attempt 10019 entries

-- Assign directors
SELECT
	show_id,
	TRIM(UNNEST(STRING_TO_ARRAY(director, ','))) AS director_name
INTO netflix_director
FROM netflix_raw
-- Successfully attempt 6978 entries


-- Populate countrys' null value by assuming the same director whould have the same country
INSERT INTO netflix_country
SELECT
	nr.show_id,
	dc.country_name
FROM netflix_raw AS nr
INNER JOIN (
	SELECT
		nd.director_name,
		nc.country_name
	FROM netflix_director AS nd
	INNER JOIN netflix_country as nc
	ON nd.show_id = nc.show_id
	GROUP BY 1, 2) AS dc
ON nr.director = dc.director_name	
WHERE nr.country IS NULL
-- Found 194 values to insert to recurring country table (now 10213 values)


-- Examine null value in duration and fix it
SELECT
	*
FROM netflix_raw
WHERE duration ISNULL
-- There are 3 rows with duration values misplaced in ratig instead of duration.


-- Exchange data from both place.
UPDATE netflix_raw
SET
	duration = rating,
	rating = NULL
WHERE duration IS NULL
-- Null values in duration already resolved.


-- Reformatting date_added column from varchar to date
ALTER TABLE netflix_raw
ALTER COLUMN date_added TYPE DATE
USING TO_DATE(date_added, 'Month DD, YYYY')
-- Reformatting success from November 25, 2016


-- Retrieve main columns for analysis, excluding duplicated rows. Generate new table of it.
WITH helper AS (
SELECT
	*,
	ROW_NUMBER() OVER (PARTITION BY LOWER(title), type ORDER BY show_id) AS rn
FROM netflix_raw
)
SELECT
	show_id,
	type,
	title,
	date_added,
	release_year,
	rating,
	duration,
	description
INTO netflix_clean	
FROM helper
WHERE rn = 1
-- Table consists 8804 row including rows with null value.


-- Check null existances in the table.
WITH helper AS (
SELECT
	*,
	ROW_NUMBER() OVER (PARTITION BY LOWER(title), type ORDER BY show_id) AS rn
FROM netflix_raw
)
SELECT
	COUNT(*) FILTER(WHERE show_id IS NULL) AS show_id,
	COUNT(*) FILTER(WHERE type IS NULL) AS type,
	COUNT(*) FILTER(WHERE title IS NULL) AS title,
	COUNT(*) FILTER(WHERE date_added IS NULL) AS date_added,
	COUNT(*) FILTER(WHERE release_year IS NULL) AS release_year,
	COUNT(*) FILTER(WHERE rating IS NULL) AS rating,
	COUNT(*) FILTER(WHERE duration IS NULL) AS duration,
	COUNT(*) FILTER(WHERE description IS NULL) AS description
FROM helper
WHERE rn = 1
-- Found in date_added (10) and rating (7).


-- Go to analysis