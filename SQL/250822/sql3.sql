USE wconcept;

WITH base AS (
  SELECT
    id, category, title, rating, review_count,
    CUME_DIST() OVER (
      PARTITION BY category
      ORDER BY review_count DESC
    ) AS cd_cat
  FROM products
  WHERE rating IS NOT NULL
),
cash_cow AS (
  SELECT *
  FROM base
  WHERE cd_cat <= 0.10       -- 카테고리별 상위 10%
    AND rating >= 4.3
),
ranked AS (
  SELECT
    category, title, rating, review_count,
    ROW_NUMBER() OVER (
      PARTITION BY category
      ORDER BY review_count DESC, rating DESC, title
    ) AS rnk
  FROM cash_cow
)
SELECT category, title, rating, review_count
FROM ranked
WHERE rnk <= 5
ORDER BY category, rnk;
