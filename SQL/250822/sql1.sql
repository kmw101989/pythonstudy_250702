
SET @main_products := 20;
SET @excellent := 4.50;
SET @average := 4.00;

WITH cat AS (
	SELECT 
		category,
        COUNT(*) as product_count,
        SUM(review_count) as total_reviews,
		ROUND(AVG(avg_rating),2) As avg_rating
    FROM top100_products
    GROUP BY category
    HAVING COUNT(*) >= @main_products
)
SELECT
	category,
    product_count,
    total_reviews,
    avg_rating,
    CASE 
		WHEN avg_rating >= @excellent THEN "Excellent"
        WHEN avg_rating >= @average THEN "Average"
        ELSE "Poor"
    END AS grade
FROM cat 
ORDER BY avg_rating DESC;


# 카테고리 별 리뷰 수 기준, 상위 10%에 해당하는 상품목록 
# 그룹으로 정렬 GROUP BY 아님 
# 전체 총 데이터를 10등굽으로 균등하게 나눠서 10%에 해당하는 자료값만 찾아오기 

WITH ranked as (
	SELECT *,
		NTILE(10) OVER (PARTITION BY category ORDER BY review_count DESC) AS decile
    FROM top100_products 
)
SELECT 
	category,
    product_name,
    review_count,
	avg_rating
FROM ranked
WHERE decile = 1
ORDER BY review_count DESC ;