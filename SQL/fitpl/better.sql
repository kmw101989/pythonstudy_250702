/* ╔══════════════════════════════════════════════════════════════════╗
   ║   개선화 버전 — 현재 상태용 (product_id/serial 이미 존재)         ║
   ╚══════════════════════════════════════════════════════════════════╝ */
USE fitpl;
SET SESSION sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));
SET SQL_SAFE_UPDATES = 0;

/* [1] product_id 값 채우기 (URL 끝 숫자 → product_id), 이미 값 있는 행은 보존 */
UPDATE products
SET product_id = CAST(REGEXP_SUBSTR(product_url, '[0-9]+$') AS UNSIGNED)
WHERE product_id IS NULL
  AND product_url REGEXP '[0-9]+$';

/* (선택) 추출 실패 점검 */
SELECT COUNT(*) AS failed_extract
FROM products
WHERE (product_url IS NOT NULL AND product_url <> '')
  AND product_id IS NULL;

/* (선택) 실패 0이면 제약/인덱스 강화 추천
-- ALTER TABLE products MODIFY COLUMN product_id BIGINT NOT NULL;
-- CREATE UNIQUE INDEX ux_products_product_id ON products(product_id);
*/

/* [2] 영향 받는 뷰 드롭 */
DROP VIEW IF EXISTS v_user_top20_products;
DROP VIEW IF EXISTS v_user_top5cat_4item;
DROP VIEW IF EXISTS v_user_product_candidates;
DROP VIEW IF EXISTS v_products_norm;

/* [3] v_products_norm — product_id 기준으로 동상품 묶기 */
CREATE OR REPLACE VIEW v_products_norm AS
WITH ranked AS (
  SELECT
    p.brand, p.main_category, p.color, p.discount_rate, p.gender_en, p.img_url,
    p.material, p.monthly_views, p.price,
    p.product_serial,               -- 시리얼 보존
    p.product_id,                   -- 통일된 숫자 ID
    p.product_name, p.product_name_detail,
    p.product_url, p.rating, p.review_count, p.sales, p.season, p.style_tag, p.category,
    REGEXP_REPLACE(REGEXP_REPLACE(LOWER(TRIM(p.category)),'\\s+',' '),'[-_/]',' ') AS category_norm,
    ROW_NUMBER() OVER (
      PARTITION BY p.product_id
      ORDER BY p.product_serial DESC, p.product_url
    ) AS rn
  FROM products p
  WHERE p.product_id IS NOT NULL
)
SELECT
  brand, main_category, color, discount_rate, gender_en, img_url,
  material, monthly_views, price,
  product_serial, product_id,
  product_name, product_name_detail,
  product_url, rating, review_count, sales, season, style_tag, category, category_norm
FROM ranked
WHERE rn=1;

/* [4] v_user_product_candidates — 컬럼 보존 + 카테고리 매칭 동일 */
CREATE OR REPLACE VIEW v_user_product_candidates AS
SELECT
  ucs.user_id,
  c.category_id,
  p.brand, p.main_category, p.color, p.discount_rate, p.gender_en, p.img_url,
  p.material, p.monthly_views, p.price,
  p.product_serial, p.product_id,
  p.product_name, p.product_name_detail,
  p.product_url, p.rating, p.review_count, p.sales, p.season, p.style_tag, p.category,
  ucs.final_cat_score AS base_score
FROM v_user_category_score ucs
JOIN v_category_norm c ON c.category_id = ucs.category_id
JOIN v_products_norm p ON p.category_norm = c.category_norm
LEFT JOIN v_user_primary_bucket ub ON ub.user_id = ucs.user_id
WHERE ucs.final_cat_score > 0
  AND NOT (
    ub.bucket_norm IN ('hot humid','warm','warm humid')
    AND (LOWER(p.category) REGEXP 'coat|jacket|padding|down|sweater|cardigan|hood|long\\s*sleeve|knit|pique|collar')
  )
  AND NOT (
    LOWER(p.category) REGEXP 'organiz(e|ation)|suppl(y|ies)|equipment|stationer(y|ies)|office|tool(s)?'
    OR LOWER(c.category) REGEXP 'organiz(e|ation)|suppl(y|ies)|equipment|stationer(y|ies)|office|tool(s)?'
  );

/* [5] v_user_top5cat_4item — NOT EXISTS를 product_id 기준으로 통일 */
CREATE OR REPLACE VIEW v_user_top5cat_4item AS
WITH ranked_cats AS (
  SELECT
    user_id, category_id, final_cat_score,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY final_cat_score DESC) AS cat_rank
  FROM v_user_category_score
),
top_cats AS (
  SELECT DISTINCT user_id, category_id
  FROM ranked_cats
  WHERE cat_rank <= 5
),
strict AS (
  SELECT
    upc.user_id, upc.category_id,
    upc.product_id,  -- ✅ user_id 다음으로 배치
    upc.brand, upc.main_category, upc.color, upc.discount_rate, upc.gender_en, upc.img_url,
    upc.material, upc.monthly_views, upc.price,
    upc.product_serial,
    upc.product_name, upc.product_name_detail,
    upc.product_url, upc.rating, upc.review_count, upc.sales, upc.season, upc.style_tag, upc.category,
    upc.base_score AS score, 2 AS src_priority
  FROM v_user_product_candidates upc
  JOIN top_cats t ON t.user_id=upc.user_id AND t.category_id=upc.category_id
),
relaxed AS (
  SELECT
    ucs.user_id, ucs.category_id,
    p.product_id,  -- ✅ 동일하게 user_id 바로 뒤
    p.brand, p.main_category, p.color, p.discount_rate, p.gender_en, p.img_url,
    p.material, p.monthly_views, p.price,
    p.product_serial,
    p.product_name, p.product_name_detail,
    p.product_url, p.rating, p.review_count, p.sales, p.season, p.style_tag, p.category,
    (ucs.final_cat_score * 0.90) AS score, 1 AS src_priority
  FROM v_user_category_score ucs
  JOIN top_cats t ON t.user_id=ucs.user_id AND t.category_id=ucs.category_id
  JOIN v_category_norm c ON c.category_id = ucs.category_id
  JOIN v_products_norm p ON p.category_norm = c.category_norm
  WHERE NOT EXISTS (
    SELECT 1 FROM v_user_product_candidates s
    WHERE s.user_id=ucs.user_id
      AND s.category_id=ucs.category_id
      AND s.product_id = p.product_id
  )
),
ranked_products AS (
  SELECT
    x.*,
    ROW_NUMBER() OVER (
      PARTITION BY x.user_id, x.category_id
      ORDER BY x.src_priority DESC, x.score DESC, x.product_name, x.product_url
    ) AS prod_rank
  FROM (SELECT * FROM strict UNION ALL SELECT * FROM relaxed) x
)
SELECT
  r.user_id,
  r.product_id,  -- ✅ 위치 조정 완료
  r.brand, r.main_category, r.color, r.discount_rate, r.gender_en, r.img_url,
  r.material, r.monthly_views, r.price,
  r.product_serial,
  r.product_name, r.product_name_detail,
  r.product_url, r.rating, r.review_count, r.sales, r.season, r.style_tag, r.category,
  r.score AS base_score
FROM ranked_products r
WHERE r.prod_rank <= 4;

/* [6] v_user_top20_products — NOT EXISTS를 product_id 기준으로 통일
       (※ 기존 스크립트의 사소한 버그: NOT EXISTS 안에서 s.category_id=c.category_id 로 쓰였던 부분을
          s.category_id=ucs.category_id 로 수정했습니다.) */
CREATE OR REPLACE VIEW v_user_top20_products AS
WITH strict AS (
  SELECT
    upc.user_id,
    upc.product_id,                              -- ✅ user_id 다음
    upc.brand, upc.main_category, upc.color, upc.discount_rate, upc.gender_en, upc.img_url,
    upc.material, upc.monthly_views, upc.price,
    upc.product_serial,
    upc.product_name, upc.product_name_detail,
    upc.product_url, upc.rating, upc.review_count, upc.sales, upc.season, upc.style_tag, upc.category,
    upc.base_score AS score, 2 AS src_priority
  FROM v_user_product_candidates upc
),
relaxed AS (
  SELECT
    ucs.user_id,
    p.product_id,                                -- ✅ user_id 다음
    p.brand, p.main_category, p.color, p.discount_rate, p.gender_en, p.img_url,
    p.material, p.monthly_views, p.price,
    p.product_serial,
    p.product_name, p.product_name_detail,
    p.product_url, p.rating, p.review_count, p.sales, p.season, p.style_tag, p.category,
    (ucs.final_cat_score * 0.90) AS score, 1 AS src_priority
  FROM v_user_category_score ucs
  JOIN v_category_norm c ON c.category_id=ucs.category_id
  JOIN v_products_norm p ON p.category_norm=c.category_norm
  WHERE NOT EXISTS (
    SELECT 1
    FROM v_user_product_candidates s
    WHERE s.user_id     = ucs.user_id
      AND s.category_id = ucs.category_id
      AND s.product_id  = p.product_id
  )
),
pool AS (
  SELECT * FROM strict
  UNION ALL
  SELECT * FROM relaxed
),
ranked AS (
  SELECT
    p.*,
    ROW_NUMBER() OVER (
      PARTITION BY p.user_id
      ORDER BY p.src_priority DESC, p.score DESC, p.product_name, p.product_url
    ) AS rn
  FROM pool p
)
SELECT
  user_id,
  product_id,                                     -- ✅ 위치 고정
  brand, main_category, color, discount_rate, gender_en, img_url,
  material, monthly_views, price,
  product_serial,
  product_name, product_name_detail,
  product_url, rating, review_count, sales, season, style_tag, category,
  score AS base_score
FROM ranked
WHERE rn <= 20;


/* [7] 테스트 */
SET @uid = 2;
SELECT * FROM v_user_top5cat_4item  WHERE user_id=@uid;
-- SELECT * FROM v_user_top20_products WHERE user_id=@uid;

SHOW columns FROM v_user_top5cat_4item ;

/*-----*/

SET @uid = 2;
SELECT * FROM v_country_activity_top20_products;


SET @uid = 2;
SELECT *
FROM v_country_activity_top20_products
WHERE user_id = @uid;

SELECT *
FROM v_country_climate_top20_products
WHERE user_id = @uid;

SELECT *
FROM v_country_photo_top20_products
WHERE user_id = @uid;


SELECT * 
FROM v_user_top5cat_4item 
WHERE user_id = @uid;

SHOW COLUMNS FROM v_country_photo_top20_products;

