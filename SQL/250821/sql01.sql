SELECT 
	COUNT(A.address_id)
FROM address A 
JOIN customer C USING(address_id);

SELECT
	(SELECT count(*) FROM address) -
	(SELECT 
		COUNT(A.address_id)
	FROM address A 
	JOIN customer C USING(address_id))
    AS no_customer_address;
    
SELECT count(*) 
FROM customer C 
RIGHT OUTER JOIN address A
ON A.address_id = C.address_id
WHERE customer_id IS NULL ;

#문제 10 캐나다 고객에게 이메일 마케팅 캠페인을 진행하고자 합니다. 캐나다 고객의 이름과 이멘일 주소 리스트를 출력 
SELECT 
	CONCAT(first_name," ",last_name) as full_name,
    email
FROM customer c
JOIN address addr USING(address_id)
JOIN city on city.city_id = addr.city_id
JOIN country CTR on CTR.country_id = city.country_id
WHERE CTR.country="Canada";

SELECT * FROM city
WHERE country_id = 20;
#179,196,300,313,383,430,565 

SELECT * FROM address
WHERE city_id IN (179,196,300,313,383,430,565);
#481,468,1,3,193,415,441

SELECT * FROM customer 
where address_id IN (481,468,1,3,193,415,441);

#문제 11 신혼부부 타겟고객들의 매출이 최근 저조하여 가족영화를 홍보대상으로 삼고자한다. 가족영화로 분류된 모든 영화 리스트 

SELECT title from film
join film_category as FC USING (film_id)
join category as C using(category_id)
WHERE C.name = "Family";

#문제 12 : 가장 자주 대여하는 영화 리스트를 참고로 보고 싶다. 가장 자주 대여하는 영화 순으로 100개 출력 (제목,렌탈횟수)
SELECT 
	F.title, 
    count(*) as rental_count
FROM film F 
JOIN inventory I using(film_id)
JOIN rental R using(inventory_id)
GROUP BY F.title
ORDER BY rental_count DESC
LIMIT 100;

#문제 13 : 각 스토어별로 매출을 확인하고 싶습니다. 관련 데이터를 출력해주세요 (도시,국가,store_id,스토어 별 총 매출)\

SELECT 
	CONCAT(c.city," , ",CTR.country) as store,
    s.store_id,
    sum(p.amount) as sales
FROM store s
JOIN address addr USING(address_id)
JOIN staff USING(store_id)
JOIN payment p USING(staff_id)
JOIN city c using(city_id)
JOIN country CTR USING(country_id)
group by s.store_id;


#문제 14 : 가장 렌탈비용을 많이 지불한 상위 10명의 vip 고객에게 선물을 배송하고자 함. 해당 vip고객들의 주소와 이메일,그리고 고객별 지불 비용 출력 

SELECT 
	CONCAT(first_name," ",last_name) as full_name,
    address,
    CONCAT(country," , ",city) as full_address ,
    C.email,
    SUM(P.amount) as total_uses
FROM customer C
JOIN address A USING(address_id)
JOIN payment P USING(customer_id)
JOIN city CI USING(city_id)
JOIN country CO USING(country_id)
GROUP BY C.customer_id
ORDER BY total_uses DESC
limit 10 ;

#문제 15: actor 테이블의 배우 이름을 first_name과 last_name의 조합으로 출력 단 소문자로. 필드명은 Actor_name  
SELECT LOWER(CONCAT(first_name," ",last_name)) as Actor_name
FROM actor;

SELECT 
	CONCAT(
		UPPER(LEFT(first_name,1)),
        LOWER(SUBSTRING(first_name,2)),
        " ",
        UPPER(LEFT(last_name,1)),
        LOWER(SUBSTRING(last_name,2))
    ) as Actor_name
FROM actor;

#언어가 영어인 영화중 타이틀이 K 와 Q로 시작하는 영화의 타이틀만 출력 (서브쿼리 사용) 
SELECT title
FROM film
WHERE title IN(
	SELECT title 
	FROM film 
	WHERE (
		SELECT language_id 
		FROM language
		WHERE name ="English"
	)
)
AND title like 'K%' or title like 'Q%';

#문제 17 Alone Trip에 나오는 배우 이름을 모두 출력. 배우이름은 actor_name이라는 필드값으로 
SELECT 
	CONCAT(first_name," ",last_name) as actor_name
FROM actor 
WHERE actor_id IN (
    SELECT actor_id FROM film_actor
	WHERE film_id = (
		SELECT film_id FROM film 
		WHERE title = "Alone Trip")
);


# 문제 18 : 2005년 8월에 각 스태프 멤버가 올린 매출을 출력 멤버 필드 :Staff_Member , 매출  Total_Amount

SELECT 
	CONCAT(S.first_name," ",S.last_name) as Staff_Member,
	SUM(p.amount) as Total_Amount
FROM staff S 
JOIN payment p USING(staff_id)
WHERE P.payment_date LIKE "2005-08%"
GROUP BY S.staff_id;

SELECT 
	CONCAT(S.first_name," ",S.last_name) as Staff_Member,
	SUM(p.amount) as Total_Amount
FROM staff S 
JOIN payment p USING(staff_id)
WHERE 
	YEAR(P.payment_date) = 2005 and 
	MONTH(P.payment_date) = 8
GROUP BY S.staff_id;

#문제 20 : 각 카테고리의 평균 영화 러닝타임이 전체 평균 러닝타임보다 긴 카테고리들의 카테고리명과 해당 카테고리의 평균 러닝 타임 출력
SELECT AVG(length) FROM film; # 전체 평균 

SELECT 
    c.name AS category_name,
    AVG(f.length) AS avg_length
FROM category c
JOIN film_category fc USING(category_id)
JOIN film f USING(film_id)
GROUP BY c.category_id, c.name
HAVING AVG(f.length) > (
    SELECT AVG(length)
    FROM film
);

#문제 21 : 각 카테고리별 평균 영화 대여 시간과 해당 카테고리명을 출력. 단. 대여 ~ 반납 시간차 hour 를 단위로 

SELECT 
    c.name AS category_name,
    AVG(TIMESTAMPDIFF(HOUR, r.rental_date, r.return_date)) AS avg_rental_hours
FROM category c
JOIN film_category fc USING(category_id)
JOIN film f USING(film_id)
JOIN inventory i USING(film_id)
JOIN rental r USING(inventory_id)
GROUP BY c.category_id, c.name 
ORDER BY avg_rental_hours DESC;
    
#문제 22: 새로운 임원이 부임했습니다. 총 매출액 상위 5개 장르의 매출액을 수시로 확인하고자 한다. 각 장르별 총 매출, 장르명으로 해당 데이터를 수시로 확인할 수 있는 VIEW를 생성
#top5_genres , 상위 5개 장르의 매출액 출력 
drop view top5_genres ;

CREATE VIEW top5_genres AS 
SELECT sum(amount) as amount ,
	f.film_id
FROM payment p
JOIN rental r USING(rental_id)
JOIN inventory i using(inventory_id)
JOIN film f USING(film_id)
GROUP BY f.film_id;

SELECT 
	c.name AS Genre,
	SUM(tg.amount) AS total_sales
FROM category c
JOIN film_category fc ON c.category_id = fc.category_id
JOIN top5_genres tg ON fc.film_id = tg.film_id
GROUP BY c.category_id, c.name
ORDER BY total_sales DESC
LIMIT 5;   

#문제 23 : 2005년 5월에 가장 많이 대여된 영화 3개 , 대여 횟수
SELECT
	title,
	count(*) as rent_count
FROM film f
join inventory USING(film_id)
JOIN rental USING(inventory_id)
WHERE rental_date like "2005-05%"
Group by title
order by rent_count desc
limit 3;

#문제 24. 대여된 적이 없는 영화를 찾으세요 
SELECT f.title
FROM film f
WHERE f.film_id NOT IN (
    SELECT i.film_id
    FROM inventory i
    JOIN rental r ON i.inventory_id = r.inventory_id
);

#문제 25. 각 고객의 총 지출 금애그이 편균보다 총 지출 금액이 더 큰 고객 리스트 출력 이름과 총 금액 

SELECT 
	CONCAT(first_name,' ',last_name) as full_name,
    sum(p.amount) as spent_money
FROM customer c
JOIN payment p USING(customer_id)
JOIN rental r USING(rental_id)
GROUP BY c.customer_id
having sum(p.amount) > (
	SELECT AVG(total)
    FROM(
		SELECT sum(amount) as total
		FROM payment 
		group by customer_id
	) as sub
)
ORDER BY spent_money desc ;

#문제 26. 가장 많은 결제건을 처리한 직원이 누구인지 출력 
SELECT
	CONCAT(first_name," ",last_name),
    COUNT(p.payment_id) AS staff_worked
FROM staff s
JOIN payment p USING(staff_id)
GROUP BY s.staff_id
ORDER by staff_worked DESC
limit 1;

#문제 27. 액션 카테고리에서 높은 영화 영상 등급을 받은 순으로 상위 5개의 영화 출력 (기준: ORDER BY rating DESC)
SELECT 
	title,
    rating
FROM film f
JOIN film_category FC USING(film_id)
JOIN category c USING(category_id)
WHERE c.name = "Action"
ORDER By f.rating DESC
limit 5;

#문제 28. 각 등급을 기준으로 영화별 대여기간의 평균을 찾아주세요. 
SELECT 
	rating,
    AVG(rental_duration)
FROM film
GROUP BY rating; 

#29. 매장ID 별 총 매출을 출력하는 view를 생성 

CREATE VIEW store_rev AS 
	SELECT
		store_id,
		sum(amount) total_rev
    FROM payment p
    JOIN staff s using(staff_id)
    JOIN store ST using(store_id)
    GROUP BY store_id;
    
SELECT * FROM store_rev;
DROP VIEW store_rev;

#30. 가장 많은 고객이 있는 상위 5개국가 출력 
SELECT 
	c.country,
    count(*) AS customer_count
FROM country c 
JOIN city CT USING(country_id)
JOIN address ADR USING(city_id)
JOIN customer CS USING(address_id)
GROUP BY c.country
ORDER BY customer_count DESC 
Limit 5;
