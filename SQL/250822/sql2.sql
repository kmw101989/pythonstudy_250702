
-- 등급 컷 (원하면 바꾸세요)
SET @EXCELLENT := 4.90;
SET @AVERAGE   := 4.50;

SELECT
  category,
  COUNT(*)                                  AS product_cnt,
  ROUND(AVG(rating), 2)                     AS avg_rating,     -- NULL 평점은 AVG에서 자동 제외
  SUM(review_count)                         AS total_reviews,
  CASE
    WHEN ROUND(AVG(rating), 2) >= @EXCELLENT THEN 'Excellent'
    WHEN ROUND(AVG(rating), 2) >= @AVERAGE   THEN 'Average'
    ELSE 'Poor'
  END AS grade
FROM products
GROUP BY category
HAVING COUNT(*) >= 30
ORDER BY avg_rating DESC, total_reviews DESC;
