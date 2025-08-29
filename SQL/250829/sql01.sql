#5. 영화 대여 매역에서 고객별 대여순서 출력, 이전 대여와의 간격 day 단위 기준, 첫번째 대여 일시 출력 
#customer_id , rental_id , rental_date , rental_order, prev_rental_gap, first_rental_date

SELECT 
	customer_id, rental_id, rental_date,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY rental_date) AS rental_order, 
    TIMESTAMPDIFF (DAY ,LAG(rental_date) OVER (PARTITION BY customer_id ORDER BY rental_date),rental_date) as prev_rental_gap,
    FIRST_VALUE(rental_date) OVER(PARTITION BY customer_id) AS first_rental_date 
FROM rental;


#각 고객의 결제 금액에 따른 순위  (결제금액이 높은 순으로 정렬, 만약 동일한 값이 존재하는 경우 같은 순위) 
#백분위 순위 (결제금액이 높은 순) 
WITH customer_amount AS(
	SELECT 
		customer_id,
		SUM(amount) as total_amount
	FROM payment
	GROUP BY customer_id
)
SELECT 
	customer_id,
    total_amount,
    DENSE_RANK() OVER (ORDER BY total_amount DESC) as amount_rank,
    PERCENT_RANK() OVER (ORDER BY total_amount DESC) AS percentile_rank
FROM customer_amount;

#7. 각 등급별로 영화를 대여기간에 따라 4개의 그룹으로 나누고 , 각 그룹 내에서 
#rental_duration이 낮은 순으로 번호를 매겨 영화를 출력 
#film_id, title,rating,rental_duration, rental_duration_group, group_rownum 
WITH film_group AS(
	SELECT 
		film_id,title,rating,rental_duration,
		NTILE(4) OVER(PARTITION BY rating ORDER BY rental_duration) AS rental_duration_group
	FROM film
)
SELECT 
	film_id,title,rating,rental_duration,
    rental_duration_group,
    ROW_NUMBER() OVER (PARTITION BY rental_duration ORDER BY rental_duration ASC) AS group_rownum
FROM film_group;

#8. 각 배우의 출연 영화 수에 따른 누적 분포를 다음정보와 함께 출력 
# actor_id ,first_name,last_name,film_count,film_count_cume_dist 

SELECT 
	actor_id ,first_name,last_name,
    COUNT(*) AS film_count,
    CUME_DIST() OVER (ORDER BY COUNT(*)) AS film_count_cume_dist
FROM actor A
JOIN film_actor FA USING(actor_id) 
GROUP BY actor_id 
ORDER BY film_count_cume_dist 
;


