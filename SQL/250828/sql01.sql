 WITH customer_unique_films AS(
 SELECT 
	C.customer_id ,
    CONCAT(first_name," ",last_name) as customer_name ,
    COUNT(DISTINCT I.film_id) as unique_films_rented 
    
FROM customer C 
JOIN rental R USING(customer_id)
JOIN inventory I USING(inventory_id)
GROUP BY C.customer_id  
),
MaxUniqueFilms AS(
	SELECT MAX(unique_films_rented) AS max_unique_films
    FROM customer_unique_films
)
SELECT 
	CUF.customer_id,
    CUF.customer_name,
    CUF.unique_films_rented,
	(
		SELECT GROUP_CONCAT(name ORDER BY name)
        FROM (
			SELECT 
				CAT.name,
                COUNT(*) AS category_count
            FROM category CAT 
            JOIN film_category FC USING(category_id)
            JOIN inventory INV USING(film_id)
            JOIN rental REN USING(inventory_id)
            WHERE REN.customer_id = CUF.customer_id
            GROUP BY CAT.name 
 
			) AS inner_cat
            WHERE category_count = (
				SELECT MAX(category_count2)
                FROM (
					SELECT  COUNT(*) AS category_count2 
					FROM category CAT2                                                                                                                 
					JOIN film_category FC2 USING(category_id)
					JOIN inventory INV2 USING(film_id)
					JOIN rental REN2 USING(inventory_id)
					WHERE REN2.customer_id = CUF.customer_id
					GROUP BY CAT2.name
                ) as subquery_cat
				
            )
    ) as cat
FROM customer_unique_films AS CUF
JOIN MaxUniqueFilms M ;

