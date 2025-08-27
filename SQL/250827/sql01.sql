	
WITH cat_count as(
    SELECT 
		CONCAT(first_name," ",last_name) as full_name,
		CAT.name as category_name,
		count(*) cnt
	FROM customer C 
	JOIN rental R USING(customer_id)
	JOIN inventory I USING(inventory_Id)
	JOIN film F USING(film_id)
	JOIN film_category FC USING(film_id)
	JOIN category CAT USING(category_id)
	GROUP BY full_name, category_name
	ORDER BY full_name
)
SELECT
  full_name,
  MIN(category_name) AS top_category,
  cnt
FROM cat_count
WHERE (full_name, cnt) IN (
  SELECT full_name, MAX(cnt)
  FROM cat_count
  GROUP BY full_name
)
GROUP BY full_name , cnt
ORDER BY full_name;



SELECT C.first_name,
	C.last_name,
    CAT.name,
    count(*)
FROM customer C 
JOIN rental R USING(customer_id)
JOIN inventory I USING(inventory_id)
JOIN film_category FC USING(film_id)
JOIN category CAT USING(category_id)
group by C.customer_id, CAT.name
HAVING count(*) = (
	SELECT COUNT(*) FROM rental R2 
    JOIN inventory I2 USING(inventory_id)
    JOIN film_category FC2 USING(film_id) 
    WHERE R2.customer_id = C.customer_id 
    group by FC2.category_id
    ORDER BY COUNT(*) DESC
    LIMIT 1
);




#2006-02-14 를 기준으로 , 2006-01-15부터 2006-02-14 까지 영화를 대여하지 않은 고객 찾기 
SELECT 
	C.customer_id,
	CONCAT(first_name," ",last_name) as full_name 
FROM customer C 
WHERE NOT exists (
	SELECT 1 
    FROM rental R 
    WHERE R.customer_id = C.customer_id
		And R.rental_date >= '2006-01-15'
        and R.rental_date < '2006-02-14'
)
ORDER By full_name;


SELECT 
	C.first_name ,C.last_name
FROM customer C 
LEFT OUTER JOIN rental R 
ON C.customer_id = R.customer_id 
AND TIMESTAMPDIFF(DAY,R.rental_date, '2006-02-14') <= 30 
WHERE R.rental_id IS NULL 
;

#가장 최근에 영화를 반납한 상위 10명의 고객 이름과 해당 고객들이 대여한 영화의 이름 그리고 대여 기간 
SELECT 
	CONCAT(first_name," ",last_name) as full_name,
	F.title,
    TIMESTAMPDIFF(DAY,R.rental_date,return_date) as duration
FROM customer C 
JOIN rental R USING(customer_id)
JOIN inventory I USING(inventory_id)
JOIN film F USING(film_id) 
ORDER by R.return_date DESC
lIMIT 10;

#각 직원의 매출을 찾고 , 각 직원의 매출이 회사 전체 매출 중 어느 정도 비율을 차지하는지 출력해주세요. 
# 직원id,이름 , 매출 , 전체 매출 중 비율 
SELECT 
	staff_id,
	CONCAT(first_name," ",last_name) as full_name,
    SUM(P.amount) as sales_staff,
   (SUM(P.amount)/(SELECT sum(amount) from payment)) * 100 AS sales_ratio
FROM staff S 
JOIN payment P USING(staff_id)
GROUP BY staff_id
;

SELECT 
	title,	
    length,
    RANK() OVER (ORDER BY length DESC) as ranking,
    DENSE_RANK() OVER (ORDER BY length DESC) as dense_ranking,
    ROW_NUMBER() OVER (ORDER BY length DESC) as row_num
FROM film
ORDER BY length desc ;

SELECT 
	C.customer_id,
    CONCAT(C.first_name, " " , C.last_name) customer_name ,
    SUM(P.amount) total_amount,
    RANK() OVER (ORDER BY SUM(P.amount) DESC) as ranking,
    DENSE_RANK() OVER (ORDER BY SUM(P.amount)DESC) AS d_ranking,
    ROW_NUMBER() OVER (ORDER BY SUM(P.amount)DESC) AS row_num
FROM customer C 
JOIN payment P USING(customer_id)
GROUP BY C.customer_id;

SELECT 
	customer_id,
    rental_date,
    COUNT(*) OVER (PARTITION BY customer_id ORDER BY rental_date 
					ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) cumulate_rentals
FROM rental;

SELECT 
	R.customer_id,
    R.rental_date,
    P.amount ,
    SUM(P.amount) OVER (PARTITION BY R.customer_id ORDER BY DATE(R.rental_date)) 
FROM rental R 
JOIN payment P USING(rental_id)
;

# customer 테이블에서 고객의 총 지출 금액을 계산하고, 총 지출 금애에 따라 고객의 순위를 매기세요. 
# 출력 값은 고객id, 이름, 총 금액 , 순위 
SELECT 
	C.customer_id,
    CONCAT(first_name," ",last_name) as full_name ,
    SUM(P.amount) as total_amount,
    RANK() OVER (ORDER BY SUM(P.amount) DESC) AS ranking 
FROM customer C 
JOIN payment p USING(customer_id)
GROUP BY C.customer_id ;  

#film 테이블에서 각 영화의 대여횟수를 계산하고 횟수에 따라 영화의 순위를 매겨주세요 만약 동률 이있을 때는 건너뛰지 않고 출력 . 필요한 값은 제목,횟수,순위 
SELECT 
	title,
    count(*) rental_count,
    DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) as ranking 
FROM film F
JOIN inventory I USING (film_id)
JOIN rental R USING (inventory_id) 
GROUP BY F.title;

SELECT 
	customer_id ,
    rental_date,
    COUNT(*) OVER (PARTITION BY customer_id ORDER BY rental_date) AS count
FROM rental;

#고객별 대여날짜별 누적 대여 횟수 계산 

SELECT 
	customer_id,
	rental_date,
    COUNT(*) OVER (PARTITION BY customer_id ORDER BY rental_date 
					ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) counts 
FROM rental;

SELECT 
	customer_id,
	rental_date,
    COUNT(*) OVER (PARTITION BY customer_id ORDER BY rental_date 
					ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) counts 
FROM rental;

SELECT 
	R.customer_id,
	R.rental_date,
	P.amount,
    DATE(R.rental_date),
    SUM(P.amount) OVER (PARTITION BY R.customer_id ORDER BY rental_date
						ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as sample
FROM payment P
JOIN rental R USING(rental_id);

SELECT 
	R.customer_id,
	R.rental_date,
	P.amount,
    DATE(R.rental_date),
    SUM(P.amount) OVER (PARTITION BY R.customer_id ORDER BY DATE(rental_date)
						RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as sample
FROM payment P
JOIN rental R USING(rental_id);

SELECT
	I.film_id,
	P.amount,
    P.payment_date,
    SUM(P.amount) OVER (PARTITION BY I.film_id ORDER BY P.payment_date 
						ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) revenue
FROM payment P
JOIN rental R USING(rental_id)
JOIN inventory I USING(inventory_id);

SELECT 
	R.customer_id,
    
FROM rental R ;


#장르별 영화 대여 수익 
#영화 장르의 수익성 분석 필요 
#장르별 대여 수익의 누적합계와 전체 대여 수익 비율을 출력 
SELECT 
	CT.name,
	SUM(P.amount) revenue,
	ROUND(100 * SUM(p.amount) / SUM(SUM(p.amount)) OVER (), 2) AS share_pct
FROM category CT
JOIN film_category FC USING(category_id)
JOIN inventory I USING(film_id)
JOIN rental R USING(inventory_id)
JOIN payment P USING(rental_id)
GROUP BY CT.name;

SELECT * FROM inventory;


WITH category_rev AS (
	SELECT
		C.name cat ,
		SUM(P.amount) revenue
	FROM payment P 
	JOIN rental R USING(rental_id)
	JOIN inventory I USING(inventory_id)
	JOIN film_category FC USING(film_id)
	JOIN category C USING(category_id)
	GROUP BY C.name 
)
SELECT 
	cat,
    revenue,
    SUM(revenue) OVER (ORDER BY revenue DESC
						ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as revenue2 ,
	revenue / SUM(revenue) OVER() as ratio
FROM category_rev
GROUP BY cat 
ORDER BY ratio DESC;


SELECT rental_id,
	rental_date,
    LAG(rental_id, 1,0) OVER (ORDER BY rental_date) prev_rental,
    LEAD(rental_id,1,0) OVER (ORDER BY rental_date) next_rental
FROM rental;

SELECT 
	I.film_id,
    R.rental_date,
    FIRST_VALUE(R.rental_date) OVER (PARTITION BY I.film_id ORDER BY R.rental_date) ,
    last_VALUE(R.rental_date) OVER (PARTITION BY I.film_id ORDER BY R.rental_date) 
FROM rental R 
JOIN inventory I USING(inventory_id);


