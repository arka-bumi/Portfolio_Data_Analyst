-- 1. For each director, count the number of movies and tv shows created by director who have both!
SELECT
	nd.director_name,
	COUNT(CASE WHEN nc.type = 'Movie' THEN 1 END) AS movies,
	COUNT(CASE WHEN nc.type = 'TV Show' THEN 1 END) AS tv_shows,
	COUNT(*) AS total 
FROM netflix_director AS nd
JOIN netflix_clean AS nc
ON nd.show_id = nc.show_id
GROUP BY 1
HAVING COUNT(CASE WHEN nc.type = 'Movie' THEN 1 END) > 0
AND COUNT(CASE WHEN nc.type = 'TV Show' THEN 1 END) > 0
ORDER BY 4 DESC
-- Successfully retrieve 83 rows.
-- Marcus Raboy was a director with the most highest directed film (15 movies and 1 tv show), following by Anurag Kashyap.
-- Approximately 45% of the data have more than 2 directed film


-- 2. Which country has highest number of comedy genre?
-- Assessing what keyword used to call comedy accross genres
SELECT
	DISTINCT(genre_name)
FROM netflix_genre
WHERE genre_name LIKE '%Comed%'
-- Assuming every genre with comedy themes means including 4 of it.
-- Generating top 10 country with highest comedy genre
SELECT
	nc.country_name,
	COUNT(CASE WHEN ng.genre_name LIKE '%Comed%' THEN ng.genre_name ELSE NULL END) AS comedy_number
FROM netflix_genre AS ng
JOIN netflix_country AS nc
ON ng.show_id = nc.show_id
GROUP BY nc.country_name
ORDER BY comedy_number DESC
LIMIT 10
-- Make it precise. Devide by detailed comedy genre!
SELECT
	nc.country_name,
	COUNT(CASE WHEN ng.genre_name LIKE 'Comedies' THEN ng.genre_name ELSE NULL END) AS "Comedies",
	COUNT(CASE WHEN ng.genre_name LIKE 'Stand-Up Comedy & Talk Shows' THEN ng.genre_name ELSE NULL END) AS "Stand-Up Comedy & Talk Shows",
	COUNT(CASE WHEN ng.genre_name LIKE 'Stand-Up Comedy' THEN ng.genre_name ELSE NULL END) AS "Stand-Up Comedy",
	COUNT(CASE WHEN ng.genre_name LIKE 'TV Comedies' THEN ng.genre_name ELSE NULL END) AS "TV Comedies",
	COUNT(CASE WHEN ng.genre_name LIKE '%Comed%' THEN ng.genre_name ELSE NULL END) AS total
FROM netflix_genre AS ng
JOIN netflix_country AS nc
ON ng.show_id = nc.show_id
GROUP BY nc.country_name
ORDER BY total DESC
-- Only 71 out of 123 country which have comedy themes in the dataset. Even half of it only have less than 10 films. 
-- US (1,200) placed first in term of comedy genre production, following by India (371) and UK (160).


-- 3. For each year (as per date_added to netflix_clean), which director has maximum number of movies releases?
-- Retrieving id, director, and release_year
SELECT
	nd.show_id,
	nd.director_name,
	nc.release_year
FROM netflix_director AS nd
JOIN netflix_clean AS nc
ON nd.show_id = nc.show_id
-- Found 6,976 rows before grouping
-- Grouping rows per director and release_year and ranking it inside the CTE.
WITH year_ranking AS (
	SELECT
		nd.director_name,
		nc.release_year,
		COUNT(*) AS freq,
		ROW_NUMBER() OVER (PARTITION BY nc.release_year ORDER BY COUNT(*) DESC, nd.director_name) AS rn
	FROM netflix_director AS nd
	JOIN netflix_clean AS nc
	ON nd.show_id = nc.show_id
	GROUP BY 1, 2
	ORDER BY 2 DESC, 4
)
SELECT
	release_year,
	director_name,
	freq
FROM year_ranking
WHERE rn = 1
ORDER BY 1 DESC
-- Successfully analys most productive director per year (73 year from 1942-2021).


-- 4. What is average duration for each movie in every genres
-- Analysing movies genres available
SELECT
	DISTINCT(genre_name)
FROM (
	SELECT
		ng.show_id,
		ng.genre_name,
		nc.type
	FROM netflix_genre AS ng
	JOIN netflix_clean as nc
	ON ng.show_id = nc.show_id
	WHERE nc.type = 'Movie'
)
-- Found 20 different genres in Movie type.
WITH avg_durations AS (
	SELECT 
		ng.genre_name,
		nc.type,
		ROUND(AVG(SPLIT_PART(duration, ' ', 1)::INT), 2) ||' min' AS avg_duration
	FROM netflix_genre AS ng
	JOIN netflix_clean AS nc
	ON ng.show_id = nc.show_id
	GROUP BY 1, 2
)
SELECT
	*
FROM avg_durations
WHERE type = 'Movie'
ORDER BY avg_duration;
-- The longest movies duration came from Classical Movies genre with 118 minutes.
-- While the shortest can be found in Movie Movies genre and Stand Up Comedy Movies genre with 47 and 67 minutes.
-- Alternative query
SELECT
	ng.genre_name,
	AVG(CAST(REPLACE(nc.duration, ' min', '') AS INT)) AS avg_duration
FROM netflix_genre AS ng
JOIN netflix_clean AS nc
ON ng.show_id = nc.show_id
WHERE nc.type = 'Movie'
GROUP BY ng.genre_name
ORDER BY avg_duration DESC


-- 5. Find directors who already work on both horror movies and comedy movies!
WITH horror_comedy AS (
	SELECT
		nd.director_name,
		ng.genre_name
	FROM netflix_director AS nd
	JOIN netflix_genre AS ng
	ON nd.show_id = ng.show_id
	WHERE ng.genre_name IN ('Horror Movies', 'Comedies')
),
count_genre AS (
	SELECT
		director_name,
		COUNT(CASE WHEN genre_name = 'Horror Movies' THEN 1 END) AS horror,
		COUNT(CASE WHEN genre_name = 'Comedies' THEN 1 END) AS comedy
	FROM horror_comedy
	GROUP BY director_name
)
SELECT
	*,
	(horror + comedy) AS total
FROM count_genre
WHERE horror > 0 AND comedy > 0
ORDER BY total DESC
-- Found 55 rows of director with Kevin Smith and Poj Arnon placed the top leaderboard (8 movies).
-- Alternative solution
SELECT
	nd.director_name,
	COUNT(CASE WHEN ng.genre_name = 'Comedies' THEN nd.show_id END) AS count_comedy,
	COUNT(CASE WHEN ng.genre_name = 'Horror Movies' THEN nd.show_id END) AS count_horror
FROM netflix_director AS nd
JOIN netflix_genre AS ng
ON nd.show_id = ng.show_id
GROUP BY nd.director_name
HAVING COUNT(CASE WHEN ng.genre_name = 'Comedies' THEN nd.show_id END) > 0
AND COUNT(CASE WHEN ng.genre_name = 'Horror Movies' THEN nd.show_id END) > 0
-- Done!