USE sakila;
SELECT * FROM address
LIMIT 1;

SELECT * FROM customer
limit 1;

SELECT COUNT(*) count FROM customer C
RIGHT OUTER JOIN address A
ON C.address_id = A.address_id 
WHERE customer_id IS NULL ;

#서브 카테고리가 "여성신발" 인 상품 타이틀만 가져오기 
SELECT title FROM items I 
JOIN ranking R 
ON I.item_code = R.item_code 
WHERE sub_category = "여성신발";

#서브쿼리 구문을 활용해서 서로 다른 두개의 테이블을 연결해서 값을 찾아온다면? 
SELECT item_code FROM items
limit 3;

SELECT title FROM items I 
WHERE 
	item_code = "102425348" OR 
    item_code = "104914497" OR 
    item_code = "106332300" ;
    
    
SELECT title FROM items I 
WHERE item_code IN 
	("102425348" ,"104914497" ,"106332300") ;
    
SELECT title FROM items I 
WHERE item_code IN 
	(SELECT item_code FROM ranking
    WHERE sub_category="여성신발") ;
    

USE sakila;
SELECT title FROM film 
WHERE film_id in
	(SELECT film_id FROM film_category
    WHERE category_id = 5);
    
    
SELECT category_id , count(*)
FROM film_category
WHERE film_category.category_id > 
	(SELECT category.category_id FROM category
    WHERE category.name = "Comedy")
GROUP BY film_category.category_id; 


#bestproducts > 메인 카테고리별로 할인 가격이 10만원 이상인 상품이 몇개인지 
SELECT 	R.main_category, COUNT(*) FROM items I 
JOIN ranking R 
ON r.item_code = i.item_code 
WHERE dis_price >= 100000
GROUP BY main_category 
ORDER By Count(*) DESC;


SELECT main_category , count(*) FROM ranking
WHERE item_code IN(
	SELECT item_code FROM items
    WHERE dis_price >= 100000
    )
GROUP BY main_category ;

# dis_price가 20만원 이상인 아이템들의 서브카테고리별 개수
SELECT sub_category, count(*) FROM ranking R 
JOIN items I 
ON I.item_code = R.item_code 
WHERE dis_price >= 200000
group by sub_category
ORDER BY count(*) DESC;



SELECT sub_category, COUNT(*) FROM ranking 
WHERE item_code IN(
	SELECT item_code FROM items 
    Where dis_price >= 200000) 
GROUP BY sub_category 
ORDER BY COUNT(*) DESC;


SELECT main_category , AVG(discount_percent) as AVD, MAX(discount_percent) as MAXD ,count(*)
FROM ranking R 
JOIN items I 
ON I.item_code = R.item_code 
WHERE dis_price
GROUP By main_category
ORDER BY count(*) DESC;