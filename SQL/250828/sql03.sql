# customer 테이블과 payment 테이블을 사용해서 각 도시별 고객의 총 결제 금액 순위 
# customer_id, city, 총 결제금액, 도시 순위 
WITH total AS(	
    SELECT 
		c.customer_id id ,
		ct.city city,
		sum(p.amount) total_payment 
	FROM customer c
	JOIN address USING(address_id)
	JOIN city ct USING(city_id)
	JOIN payment P USING(customer_id)
	GROUP BY ct.city, c.customer_id
)
SELECT 
	id,
	city,
	total_payment, 
	RANK() OVER (ORDER BY total_payment DESC) AS city_rank
FROM total;

SELECT 
	CONCAT(first_name," ",last_name), 
	c.customer_id, ct.city, 
	sum(p.amount) ,
    RANK() OVER (ORDER BY SUM(p.amount) DESC) AS city_rank
FROM customer c 
JOIN address USING(address_id) 
JOIN city ct USING(city_id) 
JOIN payment P USING(customer_id) 
GROUP BY ct.city, c.customer_id;


#customer 테이블에서 고객별 대여 횟수에 따라 4개의 그룹으로 나눠주세요 
#고객 id , 대여횟수, 그룹 출력 
SELECT 	
	c.customer_id,
    count(*) as total_rent,
    NTILE(4) OVER (ORDER BY count(*) DESC) as rent_group
FROM customer c
JOIN rental r USING(customer_id)
GROUP BY c.customer_id;

#film 테이블에서 영화 대여기간에 따라 5개 그룹으로 나누기 
#film_id, duration, group 
SELECT 
	film_id,
    rental_duration,
    NTILE(5) OVER (ORDER BY rental_duration DESC) AS rent_group
FROM film ;

#payment 테이블에서 각 고객별로 지불 내열에 행 번호 부여하기 
#고객 별 지불 내역의 행 번호는 payment_date 가 낮은 순으로 
#payment_id, customer_id , payment_date, amount, rownum

SELECT 
	payment_id ,
    customer_id,
    payment_date,
    amount,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY payment_date ASC) as rownum
FROM payment p ;


#film 테이블에서 각 등급별로 행 번호 부여 
#영화는 대여기간에 따라 정렬 , film_id, rating, rental_duration, rownum 
SELECT 
	film_id,
    rating,
    rental_duration,
    ROW_NUMBER() OVER (PARTITION BY rating ORDER BY rental_duration DESC) as rownum
fROM film;


#customer 테이블과 payment 테이블을 사용해서 고객을 총 결제금액에 따라 10개의 그룹으로 나누고 
#각 그룹 안에서 고객별 총 결제 금액에 따라 번호 부여 
#customer_id, sum(amount), GROUP , rownum
WITH total AS (
	SELECT 
		c.customer_id id,
		sum(p.amount) total_amount,
		NTILE (10) OVER (ORDER BY sum(p.amount)) as amount_group
	FROM customer c 
	JOIN payment p USING(customer_id)
	GROUP BY c.customer_id
)
SELECT
	id,total_amount,amount_group,
	ROW_NUMBER() OVER (PARTITION BY amount_group ORDER BY total_amount) as rownum
FROM total;

#1. 각 고객별 결제 금액에 따른 순위를 출력해주세요
#customer_id ,rental_id ,결제 금액 순위 

SELECT 
	r.customer_id,
    r.rental_id,
    SUM(p.amount),
    DENSE_RANK() OVER (ORDER BY sum(p.amount)DESC) as payment_rank
FROM rental r
JOIN payment p USING(customer_id)
GROUP BY r.customer_id,r.rental_id;

#2. 고객별 대여날짜 시간 순으로 정렬 후 아래 내용을 출력 
#customer_id , rental_id , rental_date , rental_date 기준으로 다음 rental_date 

SELECT 
	customer_id,
    rental_id,
    rental_date,
    LEAD(rental_date) OVER (PARTITION BY customer_id ORDER BY rental_date) AS next_rental_date
FROM rental
;

#각 등급별로 대여기간이 가장 긴 영화의 제목 

SELECT 
	DISTINCT rating,
    FIRST_VALUE(title) OVER(PARTITION BY rating ORDER BY rental_duration DESC) as longest_rental_movie
FROM film;


#4. 각 고객을 활동상태가 높은 순으로 정렬하고, 이를 기준으로 3개의 그룹으로 나누기 
# 그룹 내 고객의 순서를 customer_id가 낮은 순으로 정렬 
# customer_id, first_name,last_name , active,active_group ,group_row_number
WITH grouped AS(
	SELECT
		customer_id id,
		first_name first_name,
		last_name last_name,
		active active,
		NTILE(3) OVER (ORDER BY active DESC) as active_group
		FROM customer
)
SELECT 
	id,first_name,last_name,active,
    active_group,
    ROW_NUMBER() OVER (PARTITION BY active_group ORDER BY id) AS group_row_number
FROM grouped 
order by active_group, group_row_number asc;
    
 
	
