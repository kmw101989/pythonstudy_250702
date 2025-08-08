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

