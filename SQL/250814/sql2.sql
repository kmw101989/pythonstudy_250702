#rental과 inventory를 조인하고 film에 있는 replacement_cost가 20 이상인 영화 대여한 고객의 이름 출력 
#고객의 이름은 소문자로 춫력

SELECT DISTINCT(LOWER(CONCAT(first_name," ",last_name)))
FROM customer c
JOIN rental r ON r.customer_id = c.customer_id
JOIN inventory i ON i.inventory_id = r.inventory_id
JOIN film f ON f.film_id = i.film_id 
WHERE f.replacement_cost >= 20;
	
SELECT  C.first_name,C.last_name
FROM rental R 
JOIN customer C on R.customer_id = C.customer_id
JOIN inventory I on I.inventory_id = R.inventory_id
JOIN film F ON F.film_id = I.film_id
WHERE F.replacement_cost >= 20;

#film 테이블에서 rating이 pg-13 등급인 영화들중에서 description 의 길이가 pg-13 등급 평균 decription 길이보다 긴 영화 제목 찾기 
SELECT title, length(description)
FROM film 
WHERE length(description) > (
	SELECT AVG(length(description))
    FROM film 
    WHERE rating = "PG-13"
)
ORDER By length(description) DESC;

#customer와 rental, inventory, film 을 join하여 2005년 8월에 대여된 모든 R등급 영화의 제목과 해당영화를 대여한 고객의 이메일 
SELECT f.title, c.email, f.rating
FROM customer c
JOIN rental r ON r.customer_id = c.customer_id 
JOIN inventory i ON i.inventory_id = r.inventory_id
JOIN film f USING(film_id)
WHERE year(r.rental_date) = 2005 and month(r.rental_date) = 8 and f.rating = "R";

# payment 테이블에서 가장 마지막에 결제된 일시에서 30일 이전까지의 모든 결제 내역을 찾고 해당 결제 내역에 대해서 각 고객별 총 결제 금액과 평균 결제 금액 소수점 둘째자리에서 반올림해 출력 

SELECT * FROM payment;
	
SELECT 
	round(SUM(amount) ,1),
    round(AVG(amount),1),
    CONCAT(first_name," ",last_name)
FROM payment 
JOIN customer c USING(customer_id)
WHERE payment_date >= date_sub(
	(SELECT MAX(payment_date) from payment ), INTERVAL 30 day
)
GROUP BY c.customer_id ;

# actor 와 film_actor 테이블을 join하고 Sci-Fi 카테고리에 속한 영화에 출연한 배우의 이름을 찾으세요. 그리고 해당 배우의 이름은 성과 이름을 연결하여 대문자로 출력 
SELECT UPPER(CONCAT(a.first_name," ", a.last_name)) AS full_name
FROM actor a
WHERE a.actor_id IN (
  SELECT fa.actor_id
  FROM film_actor fa
  JOIN film_category fc USING (film_id)
  WHERE fc.category_id = 14
)
ORDER BY full_name;




