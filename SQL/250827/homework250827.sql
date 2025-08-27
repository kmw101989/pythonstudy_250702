#가장 많은 영화를 대여한 고객(*단,  가장 많은 영화의 기준 -> 동일한 영화를 반복해서 대여한 경우의 수는 제외, 오직 서로 다른 영화를 대여했다는 기준으로만) 을 찾아내고, 
#해당 고객이 대여한 영화 갯수를 찾아주세요. 또한 해당 고객이 대여한 영화가 가장 많이 속한 카테고리(*단, 이때에는 동일한 영화를 반복해서 대여한 경우의 수도 포함)도 찾아주세요.
WITH film_count AS(
	SELECT 
		C.customer_id as id,
		CONCAT(first_name," ",last_name) as full_name,
        COUNT(DISTINCT F.film_id) AS df_count
	FROM customer C
    JOIN rental R USING(customer_id)
    JOIN inventory I USING(inventory_id)
    JOIN film F USING(film_id)
    GROUP BY C.customer_id,full_name
    ORDER BY df_count DESC 
    limit 1
),
most_cat AS(
	SELECT 
		ct.name as cat_name, 
        c.customer_id as id,
		count(*) as rental_cnt
    FROM customer c
	JOIN rental r      USING (customer_id)
	JOIN inventory i   USING (inventory_id)
	JOIN film f        USING (film_id)
	JOIN film_category fc USING (film_id)
	JOIN category ct  USING (category_id)
	GROUP BY customer_id, ct.name 
)
SELECT id,
	full_name,
    df_count,
    rental_cnt,
    cat_name
FROM film_count
JOIN most_cat USING(id)
ORDER By rental_cnt DESC
limit 1;

