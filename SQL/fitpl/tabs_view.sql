USE fitpl;
SET SESSION sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));

-- ─────────────────────────────────────────────────────────
-- [A] 신호 정규화(스케일링) 뷰: 각 신호를 user별 max로 0~1 스케일
-- ─────────────────────────────────────────────────────────
DROP VIEW IF EXISTS v_user_category_signal_scaled;
CREATE OR REPLACE VIEW v_user_category_signal_scaled AS
SELECT
  user_id,
  category_id,
  activity_cat_w,
  climate_cat_w,
  blog_score,
  snap_score,
  -- user별 최대값으로 나눠 0~1 정규화
  activity_cat_w / NULLIF(MAX(activity_cat_w) OVER (PARTITION BY user_id), 0) AS activity_n,
  climate_cat_w  / NULLIF(MAX(climate_cat_w)  OVER (PARTITION BY user_id), 0) AS climate_n,
  blog_score     / NULLIF(MAX(blog_score)     OVER (PARTITION BY user_id), 0) AS blog_n,
  snap_score     / NULLIF(MAX(snap_score)     OVER (PARTITION BY user_id), 0) AS snap_n
FROM v_user_category_signal;

-- ─────────────────────────────────────────────────────────
-- [B] 목적별 카테고리 점수 뷰 3개 (가중치만 다르게)
--   - 모두 동일한 fallback(모든 신호 0이면 0.05)
-- ─────────────────────────────────────────────────────────

-- 1) 기후 중심: climate 0.9, activity 0.1 (기존 철학 유지)
DROP VIEW IF EXISTS v_user_category_score_climate;
CREATE OR REPLACE VIEW v_user_category_score_climate AS
SELECT
  user_id,
  category_id,
  CASE
    WHEN COALESCE(climate_n,0)+COALESCE(activity_n,0)+COALESCE(blog_n,0)+COALESCE(snap_n,0) = 0
      THEN 0.05
    ELSE (0.9*COALESCE(climate_n,0)) + (0.1*COALESCE(activity_n,0))
  END AS final_cat_score
FROM v_user_category_signal_scaled;

-- 2) 활동 중심: activity 0.9, climate 0.1
DROP VIEW IF EXISTS v_user_category_score_activity;
CREATE OR REPLACE VIEW v_user_category_score_activity AS
SELECT
  user_id,
  category_id,
  CASE
    WHEN COALESCE(climate_n,0)+COALESCE(activity_n,0)+COALESCE(blog_n,0)+COALESCE(snap_n,0) = 0
      THEN 0.05
    ELSE (0.9*COALESCE(activity_n,0)) + (0.1*COALESCE(climate_n,0))
  END AS final_cat_score
FROM v_user_category_signal_scaled;

-- 3) 사진(포토) 중심: 스냅 0.7, 블로그 0.3  (+ 미세 보정 0.0)
--    스냅/블로그가 ‘사진 친화 신호’라는 가정 (인플루언서/사진 트렌드 반영)
DROP VIEW IF EXISTS v_user_category_score_photo;
CREATE OR REPLACE VIEW v_user_category_score_photo AS
SELECT
  user_id,
  category_id,
  CASE
    WHEN COALESCE(climate_n,0)+COALESCE(activity_n,0)+COALESCE(blog_n,0)+COALESCE(snap_n,0) = 0
      THEN 0.05
    ELSE (0.7*COALESCE(snap_n,0)) + (0.3*COALESCE(blog_n,0))
  END AS final_cat_score
FROM v_user_category_signal_scaled;

-- ─────────────────────────────────────────────────────────
-- [C] 목적별 후보군 뷰 3개 (기존 후보 로직 재사용, 점수만 교체)
--     - products 매칭/필터는 기존과 동일
-- ─────────────────────────────────────────────────────────

DROP VIEW IF EXISTS v_user_product_candidates_climate;
CREATE OR REPLACE VIEW v_user_product_candidates_climate AS
SELECT
  ucs.user_id,
  c.category_id,
  p.brand, p.main_category, p.color, p.discount_rate, p.gender_en, p.img_url,
  p.material, p.monthly_views, p.price, p.product_serial, p.product_id,
  p.product_name, p.product_name_detail, p.product_url, p.rating, p.review_count,
  p.sales, p.season, p.style_tag, p.category,
  ucs.final_cat_score AS base_score
FROM v_user_category_score_climate ucs
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

DROP VIEW IF EXISTS v_user_product_candidates_activity;
CREATE OR REPLACE VIEW v_user_product_candidates_activity AS
SELECT
  ucs.user_id,
  c.category_id,
  p.brand, p.main_category, p.color, p.discount_rate, p.gender_en, p.img_url,
  p.material, p.monthly_views, p.price, p.product_serial, p.product_id,
  p.product_name, p.product_name_detail, p.product_url, p.rating, p.review_count,
  p.sales, p.season, p.style_tag, p.category,
  ucs.final_cat_score AS base_score
FROM v_user_category_score_activity ucs
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

DROP VIEW IF EXISTS v_user_product_candidates_photo;
CREATE OR REPLACE VIEW v_user_product_candidates_photo AS
SELECT
  ucs.user_id,
  c.category_id,
  p.brand, p.main_category, p.color, p.discount_rate, p.gender_en, p.img_url,
  p.material, p.monthly_views, p.price, p.product_serial, p.product_id,
  p.product_name, p.product_name_detail, p.product_url, p.rating, p.review_count,
  p.sales, p.season, p.style_tag, p.category,
  ucs.final_cat_score AS base_score
FROM v_user_category_score_photo ucs
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

-- ─────────────────────────────────────────────────────────
-- [D] 최종 출력 뷰 3개 (Top20 기준, user_id 다음에 product_id)
--     필요하면 Top5×4 버전도 그대로 복제 가능
-- ─────────────────────────────────────────────────────────

DROP VIEW IF EXISTS v_country_climate_top20_products;
CREATE OR REPLACE VIEW v_country_climate_top20_products AS
WITH pool AS (
  SELECT
    upc.user_id, upc.product_id,
    upc.brand, upc.main_category, upc.color, upc.discount_rate, upc.gender_en, upc.img_url,
    upc.material, upc.monthly_views, upc.price, upc.product_serial,
    upc.product_name, upc.product_name_detail, upc.product_url, upc.rating, upc.review_count,
    upc.sales, upc.season, upc.style_tag, upc.category,
    upc.base_score AS score
  FROM v_user_product_candidates_climate upc
),
ranked AS (
  SELECT
    p.*,
    ROW_NUMBER() OVER (
      PARTITION BY p.user_id
      ORDER BY p.score DESC, p.product_name, p.product_url
    ) AS rn
  FROM pool p
)
SELECT
  user_id,
  product_id,
  brand, main_category, color, discount_rate, gender_en, img_url,
  material, monthly_views, price, product_serial,
  product_name, product_name_detail, product_url, rating, review_count,
  sales, season, style_tag, category,
  score AS base_score
FROM ranked
WHERE rn <= 20;

DROP VIEW IF EXISTS v_country_activity_top20_products;
CREATE OR REPLACE VIEW v_country_activity_top20_products AS
WITH pool AS (
  SELECT
    upc.user_id, upc.product_id,
    upc.brand, upc.main_category, upc.color, upc.discount_rate, upc.gender_en, upc.img_url,
    upc.material, upc.monthly_views, upc.price, upc.product_serial,
    upc.product_name, upc.product_name_detail, upc.product_url, upc.rating, upc.review_count,
    upc.sales, upc.season, upc.style_tag, upc.category,
    upc.base_score AS score
  FROM v_user_product_candidates_activity upc
),
ranked AS (
  SELECT
    p.*,
    ROW_NUMBER() OVER (
      PARTITION BY p.user_id
      ORDER BY p.score DESC, p.product_name, p.product_url
    ) AS rn
  FROM pool p
)
SELECT
  user_id,
  product_id,
  brand, main_category, color, discount_rate, gender_en, img_url,
  material, monthly_views, price, product_serial,
  product_name, product_name_detail, product_url, rating, review_count,
  sales, season, style_tag, category,
  score AS base_score
FROM ranked
WHERE rn <= 20;

DROP VIEW IF EXISTS v_country_photo_top20_products;
CREATE OR REPLACE VIEW v_country_photo_top20_products AS
WITH pool AS (
  SELECT
    upc.user_id, upc.product_id,
    upc.brand, upc.main_category, upc.color, upc.discount_rate, upc.gender_en, upc.img_url,
    upc.material, upc.monthly_views, upc.price, upc.product_serial,
    upc.product_name, upc.product_name_detail, upc.product_url, upc.rating, upc.review_count,
    upc.sales, upc.season, upc.style_tag, upc.category,
    upc.base_score AS score
  FROM v_user_product_candidates_photo upc
),
ranked AS (
  SELECT
    p.*,
    ROW_NUMBER() OVER (
      PARTITION BY p.user_id
      ORDER BY p.score DESC, p.product_name, p.product_url
    ) AS rn
  FROM pool p
)
SELECT
  user_id,
  product_id,
  brand, main_category, color, discount_rate, gender_en, img_url,
  material, monthly_views, price, product_serial,
  product_name, product_name_detail, product_url, rating, review_count,
  sales, season, style_tag, category,
  score AS base_score
FROM ranked
WHERE rn <= 20;



show columns from users;


SET @uid = 12;
SELECT * FROM v_country_activity_top20_products
WHERE user_id = @uid;
SELECT * FROM region;
SELECT * FROM climate_category_map;
SELECT * FROM products ;