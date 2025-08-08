DESC ranking ; 
DESC items ; 

SELECT COUNT(*) from items ;  #(10201)
SELECT * FROM ranking
limit 1000;



SELECT * FROM items 
INNER JOIN ranking ON ranking.item_code = items.item_code
WHERE ranking.main_category = "ALL"; 

SELECT * FROM items AS A
JOIN ranking AS B
ON B.item_code = A.items_code
WHERE B.category = 'ALL'; #만약 조건절에서 설정한 데이터값이 특정 테이블에서만 

#관습적으로 특정 테이블을 생략해서 키워드를 입력 
SELECT * FROM Items I 
join ranking R
ON R.item_code = I.item_code 
WHERE main_category = "ALL";

select * from items
order by dis_price desc;


select * from ranking;



#메인카테고리 ALL 에서 판매자별 베스트상품 갯수를 출력해주세요 
SELECT provider, COUNT(*) FROM Items I 
JOIN ranking R 
ON R.item_code = I.item_code
WHERE main_category = "ALL"
group by provider
ORDER BY COUNT(*) DESC; 

# 메인 카테고리가 패션의류인 서브카테고리 포함, 패션의류 전체 베스트상품에서 판매자별 베스트상품 개수가 5이상인 판매ㅔ자와 해당 개수 출력 
SELECT provider , count(*) FROM Items I 
JOIN ranking R 
ON R.item_code =  I.item_code 
WHERE main_category = "패션의류" 
GROUP BY provider 
HAVING count(*) >= 5
ORDER BY COUNT(*) ASC ; 

SELECT DISTINCT main_category FROM ranking;

SELECT provider, COUNT(*) FROM items 
JOIN ranking 
ON ranking.item_code = items.item_code 
WHERE main_category = "패션의류"
GROUP BY provider 
HAVING COUNT(*) >= 5 
ORDER BY COUNT(*) DESC;


#메인카테고리가 신발/잡화 , 판매자별 상품개수가 10개 이상인 판매자명 & 개수 
SELECT provider, COUNT(*) FROM items 
JOIN ranking 
ON ranking.item_code = items.item_code 
WHERE main_category = "신발/잡화"
GROUP BY provider 
HAVING COUNT(*) >= 10 
ORDER BY COUNT(*) DESC;


#메인카테고리가 화장품/케어 해당 카테고리 내 평균 최대 최소 할인 가격 출력 
SELECT 
	AVG(dis_price) as avp,
	MIN(dis_price) as minp,
	MAX(dis_price) as maxp
FROM items 
JOIN ranking 
ON ranking.item_code = items.item_code 
WHERE main_category = "화장품/헤어"

