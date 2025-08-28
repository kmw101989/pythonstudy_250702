-- 문제1. sakila DB의 “영화 대여 내역”을 바탕으로 다음 항목을 모두 출력하는 SQL 쿼리문을 작성해주세요
-- 고객별 대여 순위, 이전 대여와의 간격, 다음 대여와의 간격,고객별 첫 번째 및 마지막 대여 일자, 
-- 고객별 대여 건의 백분위 순위 및 누적분포, 고객별 대여 내역의 3개 그룹 분할, 분할된 그룹 내 대여날짜 기준 오름차순 정렬
-- 위 항목들을 customer_id, rental_date와 함께 “모두 포함하여 출력”하는 SQL 쿼리를 작성해주세요.


WITH customer_rank AS(
	SELECT
	customer_id id,
	count(*),
    RANK() OVER(PARTITION BY count(*)order by customer_id) AS rental_rank
	FROM rental 
	GROUP BY customer_id
),
rental_interval AS(
	SELECT 
		customer_id id,
		LAG(rental_date) OVER(PARTITION BY customer_id ORDER BY rental_date,rental_id) as prev,
        LEAD(rental_date) OVER(PARTITION BY customer_id ORDER BY rental_date,rental_id) as next
	FROM rental
),
first_last AS(
	SELECT 
    customer_id id,
		MIN(rental_date) OVER (PARTITION BY customer_id) AS first_rental,
		MAX(rental_date) OVER (PARTITION BY customer_id) AS last_rental
	FROM rental
),
percentile_rank AS(
	SELECT
    customer_id id,
		PERCENT_RANK() OVER (PARTITION BY customer_id ORDER BY rental_date) as pct_rank,
        CUME_DIST() OVER (PARTITION BY customer_id ORDER BY rental_date) as cume_rank
	FROM rental
),
grouped AS (
	SELECT 
    customer_id id,
		NTILE(3) OVER (PARTITION BY customer_id ORDER BY rental_date) as group3
        FROM rental
)
SELECT 
	cr.id,
	cr.rental_rank,
    RI.prev,
    RI.next,
    FL.first_rental,
    FL.last_rental,
    PR.pct_rank,
    PR.cume_rank,
    GR.group3
FROM customer_rank AS cr
JOIN rental_interval  AS RI USING(id)
JOIN first_last AS FL USING(id)
JOIN percentile_rank AS PR USING(id)
JOIN grouped AS GR USING(id)
order by rental_rank, id
;
 
SELECT 
	customer_id,
    
    RANK() OVER(PARTITION BY count(*)order by customer_id) AS rental_rank,
    
    LAG(rental_date) OVER(PARTITION BY customer_id ORDER BY rental_date,rental_id) as prev,
    LEAD(rental_date) OVER(PARTITION BY customer_id ORDER BY rental_date,rental_id) as next,
    
    MIN(rental_date) OVER (PARTITION BY customer_id) AS first_rental,
    MAX(rental_date) OVER (PARTITION BY customer_id) AS last_rental,
    
	PERCENT_RANK() OVER (PARTITION BY customer_id ORDER BY rental_date) as pct_rank,
    CUME_DIST() OVER (PARTITION BY customer_id ORDER BY rental_date) as cume_rank,
    
    NTILE(3) OVER (PARTITION BY customer_id ORDER BY rental_date) as group3
FROM rental 
GROUP BY customer_id,rental_id;

