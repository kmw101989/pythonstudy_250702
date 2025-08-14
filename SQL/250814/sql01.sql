USE sakila ;
SHOW TABLES ;

SELECT 
	p.customer_id, p.amount, p.payment_date 
FROM payment AS p
WHERE p.amount > (
	SELECT
		AVG(amount)
    FROM payment 
);

SELECT 
	p.customer_id, p.amount, p.payment_date 
FROM payment AS p
WHERE p.amount > (
	SELECT AVG(amount)
    FROM payment 
    WHERE customer_id = p.customer_id
);


# 중고급 서브쿼리 시작 

SELECT 
	first_name,
    last_name
FROM customer 
WHERE customer_id IN (
	SELECT customer_id
    FROM payment
    WHERE amount > (SELECT AVG(amount) FROM payment)
);

SELECT 
	first_name,
    last_name
FROM customer
WHERE customer_id IN (
	SELECT customer_id 
    FROM payment 
    GROUP BY customer_id
    HAVING COUNT(*) > (
		SELECT 
			AVG(payment_count)
        FROM (
			SELECT COUNT(*) as payment_count
            FROM payment
            GROUP BY customer_id
            
		) AS payment_counts
        ORDER By payment_Count DESC 
        limit 1
	)
);


# 상관 서브쿼리 
SELECT 
	p.customer_id,
    p.amount, 
	p.payment_date
FROM payment p
WHERE p.amount > (
	SELECT 
		avg(amount)
    FROM payment
    WHERE customer_id = p.customer_id
);


#film 테이블에서 평균 영화 길이보다 긴 영화들의 제목을 출력 
SELECT 
	f.title,f.length
FROM film as f
WHERE f.length > (
	SELECT AVG(length)
	FROM film 
);
SELECT count(*) ,customer_id
FROM rental
group by customer_id ;
#rental 테이블에서 고객별 평균 대여 횟수보다 많은 대여를 한 고객들의 이(first_name , last 모두 )

SELECT concat(first_name," ", last_name) as full_name 
FROM customer 
WHERE customer_id IN (
	SELECT customer_id
    FROM rental 
    group by customer_id
    HAVING COUNT(*) > (
		select AVG(rental_count)
		from (
			SELECT count(*) as rental_count
			FROM rental 
			GROUP BY customer_id
		) as rental_counts
	)
);
#SQL 에서 서브쿼리 구문이 등장하는 경우가 거의 대부분 WHERE 절에 나온다 

#가장 많은 영화를 대여한 고객의 이름 을 찾기 
SELECT count(*) as rental_count, customer_id
FROM rental
GROUP BY customer_id
order by rental_count desc;

SELECT first_name, last_name ,customer_id
FROM customer 
WHERE customer_id = (
	SELECT customer_id
	FROM rental
	GROUP BY customer_id
	order by COUNT(*) desc
    limit 1
);

SELECT first_name,last_name
FROM customer 
WHERE customer_id = (
	SELECT customer_id 
    FROM (
		SELECT customer_id, COUNT(*) as rental_count
        FROM rental
        GROUP BY customer_id
	) as rental_counts 
    ORDER BY rental_count desc
    limit 1
);

# 각 고객에 대해 자신이 대여한 평균 영화 길이보다 긴 영화들의 제목 출력 
SELECT title FROM film f
WHERE f.length > (
	SELECT AVG(length)
    FROM film 
    WHERE film_id = f.film_id
);

SELECT customer_id FROM rental;
SELECT * FROM inventory;

SELECT AVG(length) 
FROM film 
WHERE customer (
	SELECT customer_id
    FROM rental
);



# 1.rental의 inventory_id를 inventory의 inventory_id로 연결해 film_id로 바꾸기 2, rental에서 customer_id , film_id 찾기 3, film_id로 길이 찾기 , 고객별 평균 길이 찾기 


    
SELECT customer_id , inventory_id
FROM rental
WHERE inventory_id IN (
	SELECT inventory_id 
    FROM rental 
    );
SELECT length,count(*),film_id
FROM film 
group by film_id
having film_id IN (
	SELECT film_id 
    FROM inventory
    WHERE inventory_id IN (
		SELECT inventory_id 
        FROM rental
	)
);

SELECT c.first_name, c.last_name, f.title
FROM customer c
JOIN rental r ON r.customer_id = c.customer_id
JOIN inventory i ON i.inventory_id = r.inventory_id
JOIN film f ON f.film_id = i.film_id 
WHERE f.length > (
	SELECT AVG (FIL.length)
    FROM film FIL 
    JOIN inventory INV on INV.film_id = FIL.film_id
    JOIN rental REN on REN.inventory_id = INV.inventory_id
    WHERE REN.customer_id = C.customer_id
);

    