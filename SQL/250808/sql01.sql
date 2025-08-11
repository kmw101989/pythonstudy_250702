USE musinsa2;

#등급별 인원 분포 구하기
SELECT grade,count(*) FROM customers
group by grade 
order by count(*) DESC;

#
SELECT customer_id,name FROM customers 
WHERE grade = "VIP" or "골드";

#사용자별 소비 금액 구하기
SELECT name, grade,sum(P.discount_price * O.quantity) AS spend_money  FROM customers C
JOIN orders O ON C.customer_id = O.customer_id
JOIN products P ON O.product_id = P.product_id
GROUP BY C.grade, C.name 
ORDER BY spend_money DESC;

#등급별 총 소비 금액 구하기
SELECT grade,sum(P.discount_price * O.quantity) AS spend_money  FROM customers C
JOIN orders O ON C.customer_id = O.customer_id
JOIN products P ON O.product_id = P.product_id
GROUP BY C.grade
ORDER BY spend_money DESC;

#등급별 개인 평균 소비 금액 
SELECT 
    C.grade,
    SUM(P.discount_price * O.quantity) AS total_spend,
    COUNT(DISTINCT C.customer_id) AS num_customers,
    ROUND(SUM(P.discount_price * O.quantity) / COUNT(DISTINCT C.customer_id)) AS avg_spend_per_person
FROM customers C
JOIN orders O ON C.customer_id = O.customer_id
JOIN products P ON O.product_id = P.product_id
GROUP BY C.grade
ORDER BY avg_spend_per_person DESC;

#상품별 평균 평점 구하기 
SELECT P.product_name,AVG(rating) as AVR 
FROM reviews AS R
JOIN products as P 
ON R.product_id = P.product_id
GROUP by P.product_name  
ORDER BY AVR DESC;

#등급별 소비 최대 최소 평균 
SELECT 
    C.grade, 
    AVG(P.price*O.quantity) as AVG ,
    MAX(P.price*O.quantity) as MAX,
    MIN(P.price*O.quantity) as MIN
FROM customers C
JOIN orders O ON C.customer_id = O.customer_id
JOIN products P ON O.product_id = P.product_id
GROUP BY C.grade
ORDER BY AVG DESC;

#최근 1달내 전체 주문 건수
SELECT count(*) recent_orderss FROM orders
WHERE order_date  >= CURDATE() - INTERVAL 1 MONTH;

#상품별 최근 한달간 주문 건수
select count(*) as order_count ,p.product_name,p.product_id,SUM(o.quantity) AS total_quantity
FROM orders o
JOIN products p 
ON p.product_id = o.product_id 
WHERE o.order_date >= CURDATE()  - INTERVAL 1 MONTH
GROUP BY p.product_name , p.product_id
ORDER BY COUNT(*) DESC;


# 고객별 총 구매 건수와 구매 수량을 을 구하고  출력
SELECT 
c.customer_id ,
c.name ,
COUNT(*) order_count , 
SUM(o.quantity) order_quantity ,
SUM(p.discount_price*o.quantity) as spend_money

FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id
JOIN products p 
ON p.product_id = o.product_id

GROUP BY c.customer_id , c.name 
ORDER BY spend_money DESC ; 

#고객별 총 구매금액을 계산 후 출력해주세요 
SELECT 
	o.customer_id,
    c.name,
	SUM(p.discount_price*o.quantity) total_spent
FROM orders o 
JOIN customers c ON o.customer_id = c.customer_id
JOIN products p ON o.product_id = p.product_id 
GROUP BY o.customer_id
ORDER BY total_spent DESC;

SELECT * FROM orders 
WHERE customer_id = "69";

SELECT * FROM products 
WHERE product_id = 36;


#지금까지 가장 많이 판매된 상품 (*수량) TOp 5
SELECT p.product_name ,SUM(o.quantity) total_sold
FROM orders o 
JOIN products p ON o.product_id = p.product_id 
GROUP BY o.product_id 
ORDER BY total_sold DESC;


#평균 평점이 4.5 이상인 상품명과 평점 출력 
SELECT p.product_name , AVG(r.rating) avg_rating
FROM products p
JOIN reviews r ON p.product_id = r.product_id 
GROUP BY r.product_id
HAVING avg_rating >= 4.5
ORDER BY avg_rating DESC;