#각 고객이 어떤 영화 카테고리를 가장 자주 대여하는지 알고 싶습니다. 각 고객별로 가장많이 대여한 영화 카테고리와 해당 카테고리에서의 총 대여 횟수, 
#그리고 해당 고객 이름을 조회하는 SQL 구문을 작성해주세요. 자주 대여하는 카테고리에 동률이 있을 경우 모두 보여주세요.

-- SELECT 
-- 	CONCAT(first_name,' ',last_name) as full_name,
--     count(*),
--     count(CT.name)
-- FROM customer C
-- JOIN rental R USING(customer_id)
-- JOIN inventory I USING(inventory_id)
-- JOIN film F USING(film_id)
-- JOIN film_category FC USING(film_id)
-- JOIN category CT USING(category_id)
-- group by C.customer_id, CT.category_id;

-- SELECT * FROM film_category;



CREATE VIEW customer_category AS (
    SELECT 
        C.customer_id,
        CONCAT(C.first_name, ' ', C.last_name) AS full_name,
        CT.name AS category_name,
        COUNT(*) AS rental_count
    FROM customer C
    JOIN rental R     USING(customer_id)
    JOIN inventory I  USING(inventory_id)
    JOIN film F       USING(film_id)
    JOIN film_category FC USING(film_id)
    JOIN category CT  USING(category_id)
    GROUP BY C.customer_id, CT.category_id, full_name, CT.name
);

SELECT * FROM customer_category;
-- -----------------------------------------------------------


CREATE VIEW max_counts AS (
    SELECT 
		customer_id, 
		MAX(rental_count) AS rental_count
    FROM customer_category
    GROUP BY customer_id
);

SELECT * FROM max_counts;
-- ----------------------------------

SELECT 
    distinct(CC.full_name),
    CC.category_name,
    CC.rental_count
FROM customer_category CC
JOIN max_counts m USING(customer_id)
JOIN max_counts ON m.rental_count = CC.rental_count
ORDER BY CC.full_name, rental_count DESC;


DROP view customer_category;
DROP view max_counts;

# max_count, fullname,category_name,rental_count