SELECT * FROM reviews;
DESC reviews ;

#크롤링한 데이터를 기반으로 상품에 대한 충성도 및 어뷰징 검증을 위한 댓글 길이 추출 
SELECT 
	`상품명` , 
	AVG(CHAR_LENGTH(`리뷰`)) 평균_리뷰_길이 
FROM reviews 
GROUP BY 상품명 
ORDER BY 평균_리뷰_길이 DESC ; 

SELECT *
FROM reviews
WHERE `리뷰` LIKE "%별로%" or `리뷰` LIKE "%불편%" ;