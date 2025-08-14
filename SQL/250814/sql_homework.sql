# 1
SELECT 
	actor_id,
    first_name,
    last_name
FROM actor 
WHERE last_name LIKE "%SON"
ORDER BY last_name ASC;

# 2 
SELECT 
	film_id,
    title,
    rating
FROM film 
WHERE rating="PG-13"
ORDER BY title ASC 
LIMIT 10;

#3
SELECT
	film_id
    title,
    rental_rate
FROM film
ORDER BY rental_rate DESC
limit 15;

#4 
SELECT count(*),C.name
FROM film F
join film_category FC USING(film_id)
JOIN category C USING(CATEGORY_id)
group by C.name
ORDER BY C.name DESC ;

