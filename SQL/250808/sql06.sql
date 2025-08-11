USE bestproducts;

#메인카테고리와 서브카테고리별 평균할인가격과 평균할인율을 출력해주세요. 
SELECT r.main_category , r.sub_category , AVG(i.dis_price) avg_Dprice, AVG(i.discount_percent) avg_Dpercent
FROM ranking r 
JOIN items i ON i.item_code = r.item_code 
group by r.main_category , r.sub_category
ORDER BY avg_Dpercent DESC;

# 판매자별 베스트상품 갯수, 평균할인가격, 평균할인율을 내림 
SELECT i.provider , 
COUNT(distinct i.item_code) product_count ,
AVG(dis_price) "평균할인가격" , 
AVG(discount_percent) "평균할인율"
FROM items i 
WHERE i.provider <> "" 
GROUP BY i.provider
ORDER BY product_count DESC ;

# 메인카테고리별 베스트 상품 개수가 20개 이상인 판매자의 판매자별 평균할인가격,평균할인율 ,베스트상품개수 출력 
SELECT 
	r.main_category,
	i.provider, 
	AVG(i.dis_price) `평균할인가격` ,
	AVG(i.discount_percent) `평균할인율`,
	COUNT(distinct i.item_code) `상품개수`
FROM items i
JOIN ranking r ON r.item_code = i.item_code 
WHERE provider != ""
GROUP BY i.provider ,r.main_category
HAVING `상품개수` >= 20
ORDER BY `상품개수` DESC;

# items에서 dis_price가 5만원 이상인 상품 중 메인카테고리별 평균 할인가와 할인율 출력 
SELECT 
	r.main_category `메인카테고리`,
    AVG(i.dis_price) `평균할인가`,
    AVG(i.discount_percent) `평균할인율`
FROM ranking r
JOIN items i ON i.item_code = r.item_code 
WHERE i.dis_price >= 50000
GROUP BY r.main_category
ORDER BY `평균할인가` DESC;



    