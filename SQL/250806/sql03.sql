# 여러분들은 모두 나이키 브랜드의 데이터 마케팅 담당자  
# 어떤 데이터가 존재 -> 최근 1년간 월별 제품별 평균 매출을 계산해야하는 미션 
# 제품id / 판매 날자 / 제품 판매가 / 판매 횟수 
CREATE DATABASE nike ; 
-- CREATE TABLE sales (
-- 	prod_id INT NOT NULL PRIMARY KEY ,
--     sale_date date NOT NULL,
--     prod_price DECIMAL(10,2) NOT NULL,
--     sale_quantity INT NOT NULL
-- );

-- DESC sales ;

-- INSERT INTO sales (prod_id, sale_date,prod_price,sale_quantity)
-- VALUES(

CREATE TABLE sales2 (
	sales_id INT PRIMARY KEY ,
    product_id INT,
    sales_date DATE,
    amount int
);
INSERT INTO sales2 (sales_id, product_id, sales_date , amount)
VALUES 
(201,100,"2025-07-15",200),
(202,100,"2025-07-20",180),
(203,200,"2025-06-05",150),
(204,100,"2025-06-10",210),
(205,200,"2025-05-11",160),
(206,300,"2025-05-20",240),
(207,100,"2025-04-01",200),
(208,300,"2025-04-15",220),
(209,200,"2025-03-05",130);

SELECT * FROM sales2;

SELECT product_id , sum(amount) as total_revenue  FROM sales2 
GROUP BY product_id
ORDER BY total_revenue desc;

SELECT 
	product_id,
	DATE_FORMAT(sales_date, '%Y-%m') AS sales_month,
	AVG(amount) as avg_monthly
FROM sales2
WHERE sales_date >= CURDATE() - INTERVAL 1 YEAR
GROUP BY product_id, sales_month 
ORDER BY product_id , sales_month ; 
