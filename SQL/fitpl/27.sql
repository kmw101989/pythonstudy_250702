/* ╔══════════════════════════════════════════════════════════════════╗
   ║  FitPl 알고리즘 DDL (방법②: 실행 시 user_id=@uid 필터)          ║
   ║  - 전역 VIEW 생성                                                ║
   ║  - strict/relaxed 후보, 중복 제거 적용(수정안 1~4 반영)         ║
   ║  사용 예:                                                        ║
   ║    SET @uid = 2;                                                 ║
   ║    SELECT * FROM v_user_top5cat_4item  WHERE user_id=@uid;       ║
   ║    SELECT * FROM v_user_top20_products WHERE user_id=@uid;       ║
   ╚══════════════════════════════════════════════════════════════════╝ */
USE fitpl;
SET SESSION sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));
-- SET @uid = 2;  -- 실행 시점에 지정

/* ───────────────────────────────────────────────────────────────────
   [DROP] 의존 순서 고려
   ─────────────────────────────────────────────────────────────────── */
DROP VIEW IF EXISTS v_user_top20_products;
DROP VIEW IF EXISTS v_user_top5cat_4item;
DROP VIEW IF EXISTS v_user_product_candidates;
DROP VIEW IF EXISTS v_category_norm;
DROP VIEW IF EXISTS v_products_norm;
DROP VIEW IF EXISTS v_user_primary_bucket;

DROP VIEW IF EXISTS v_user_category_score;
DROP VIEW IF EXISTS v_user_category_signal;
DROP VIEW IF EXISTS v_region_content_cat;
DROP VIEW IF EXISTS v_user_region_month_categories;

DROP VIEW IF EXISTS v_blog_all;
DROP VIEW IF EXISTS v_blog_region_all;
DROP VIEW IF EXISTS v_blog_region_month;
DROP VIEW IF EXISTS v_blog_item_norm;

DROP VIEW IF EXISTS v_snap_all;
DROP VIEW IF EXISTS snap_category_stats;

DROP VIEW IF EXISTS v_user_activity_cat_fallback;
DROP VIEW IF EXISTS v_user_activity_cat;
DROP VIEW IF EXISTS v_activity_cat_equalweight;
DROP VIEW IF EXISTS v_activity_alias_map;
DROP VIEW IF EXISTS v_activity_map_norm;
DROP VIEW IF EXISTS v_users_activity_tags;

DROP VIEW IF EXISTS v_user_climate_cat;
DROP VIEW IF EXISTS v_climate_cat_equalweight;
DROP VIEW IF EXISTS v_region_climate_bucket_mode_norm;
DROP VIEW IF EXISTS v_region_climate_buckets_norm;
DROP VIEW IF EXISTS v_region_climate_buckets;
DROP VIEW IF EXISTS v_region_climate_monthfix;

DROP VIEW IF EXISTS v_region_alias;
DROP VIEW IF EXISTS v_user_trip_key;

/* ───────────────────────────────────────────────────────────────────
   [1] 여행키 (전 유저)
   ─────────────────────────────────────────────────────────────────── */
CREATE OR REPLACE VIEW v_user_trip_key AS
SELECT
  u.user_id,
  u.trip_region_id AS region_id,
  DATE_FORMAT(u.trip_start_date, '%Y-%m') AS month
FROM users u
WHERE u.trip_region_id IS NOT NULL
  AND u.trip_start_date IS NOT NULL;

/* ───────────────────────────────────────────────────────────────────
   [2] 활동 파이프라인
   ─────────────────────────────────────────────────────────────────── */
CREATE OR REPLACE VIEW v_users_activity_tags AS
SELECT user_id,
       REGEXP_REPLACE(REGEXP_REPLACE(LOWER(TRIM(activity_tag_1)),'\\s+',''), '[-_]', '') AS tag_norm
FROM users WHERE activity_tag_1 IS NOT NULL AND TRIM(activity_tag_1) <> ''
UNION ALL
SELECT user_id,
       REGEXP_REPLACE(REGEXP_REPLACE(LOWER(TRIM(activity_tag_2)),'\\s+',''), '[-_]', '')
FROM users WHERE activity_tag_2 IS NOT NULL AND TRIM(activity_tag_2) <> ''
UNION ALL
SELECT user_id,
       REGEXP_REPLACE(REGEXP_REPLACE(LOWER(TRIM(activity_tag_3)),'\\s+',''), '[-_]', '')
FROM users WHERE activity_tag_3 IS NOT NULL AND TRIM(activity_tag_3) <> '';

CREATE OR REPLACE VIEW v_activity_map_norm AS
SELECT REGEXP_REPLACE(REGEXP_REPLACE(LOWER(TRIM(activity_tag)),'\\s+',''), '[-_]', '') AS tag_norm,
       category_id
FROM activity_category_map;

CREATE OR REPLACE VIEW v_activity_alias_map AS
SELECT 'citytour'    AS tag_norm, 'citytour' AS tag_origin
UNION ALL SELECT 'urban'      ,'citytour'
UNION ALL SELECT 'shopping'   ,'shopping'
UNION ALL SELECT 'outletmall' ,'shopping'
UNION ALL SELECT 'food'       ,'food'
UNION ALL SELECT 'restaurant' ,'food'
UNION ALL SELECT 'gourmet'    ,'food'
UNION ALL SELECT 'surfing'    ,'water'
UNION ALL SELECT 'snorkeling' ,'water'
UNION ALL SELECT 'diving'     ,'water'
UNION ALL SELECT 'museum'     ,'culture'
UNION ALL SELECT 'art'        ,'culture'
UNION ALL SELECT 'hiking'     ,'nature'
UNION ALL SELECT 'trekking'   ,'nature'
UNION ALL SELECT 'walking'    ,'nature'
UNION ALL SELECT 'themepark'  ,'leisure'
UNION ALL SELECT 'amusement'  ,'leisure'
UNION ALL SELECT 'indoor'     ,'indoor'
UNION ALL SELECT 'outdoor'    ,'outdoor';

CREATE OR REPLACE VIEW v_activity_cat_equalweight AS
SELECT am.tag_norm, am.category_id, 1.0 / cnt.cnt AS w_eq
FROM v_activity_map_norm am
JOIN (SELECT tag_norm, COUNT(*) AS cnt FROM v_activity_map_norm GROUP BY tag_norm) cnt
  ON cnt.tag_norm = am.tag_norm;

CREATE OR REPLACE VIEW v_user_activity_cat AS
SELECT uat.user_id, e.category_id, AVG(e.w_eq) AS activity_cat_w
FROM v_users_activity_tags uat
LEFT JOIN v_activity_alias_map amap ON uat.tag_norm = amap.tag_norm
JOIN v_activity_cat_equalweight e
  ON e.tag_norm = COALESCE(amap.tag_origin, uat.tag_norm)
GROUP BY uat.user_id, e.category_id;

CREATE OR REPLACE VIEW v_user_activity_cat_fallback AS
SELECT u.user_id, c.category_id,
       1.0 / NULLIF((SELECT COUNT(*) FROM category),0) AS activity_cat_w_fb
FROM users u CROSS JOIN category c;

/* ───────────────────────────────────────────────────────────────────
   [3] 지역 별칭(ko/en)
   ─────────────────────────────────────────────────────────────────── */
CREATE OR REPLACE VIEW v_region_alias AS
SELECT region_id, TRIM(LOWER(region_name_en)) AS alias_norm FROM region
UNION ALL
SELECT region_id, TRIM(LOWER(region_name_ko)) FROM region;

/* ───────────────────────────────────────────────────────────────────
   [4] SNAP 점수
   ─────────────────────────────────────────────────────────────────── */
CREATE OR REPLACE VIEW snap_category_stats AS
SELECT
  COALESCE(sp.region_id, ra.region_id) AS region_id,
  sp.category_id,
  LOG(COUNT(*) + 1) AS snap_score
FROM snap_products sp
LEFT JOIN v_region_alias ra
  ON TRIM(LOWER(sp.region)) LIKE CONCAT('%', ra.alias_norm, '%')
WHERE sp.category_id IS NOT NULL
GROUP BY COALESCE(sp.region_id, ra.region_id), sp.category_id;

CREATE OR REPLACE VIEW v_snap_all AS
SELECT category_id, LOG(COUNT(*) + 1) AS snap_score_all
FROM snap_products
WHERE category_id IS NOT NULL
GROUP BY category_id;

/* ───────────────────────────────────────────────────────────────────
   [5] BLOG 점수
   ─────────────────────────────────────────────────────────────────── */
CREATE OR REPLACE VIEW v_blog_item_norm AS
SELECT
  COALESCE(bi.region_id,
           (SELECT ra.region_id
              FROM v_region_alias ra
             WHERE TRIM(LOWER(bi.region)) LIKE CONCAT('%', ra.alias_norm, '%')
             LIMIT 1)) AS region_id,
  CASE
    WHEN bi.month IS NULL THEN NULL
    WHEN bi.month REGEXP '^[0-9]{4}-[0-9]{2}$' THEN bi.month
    ELSE DATE_FORMAT(bi.month, '%Y-%m')
  END AS month,
  bi.category_id,
  bi.count_in_posts
FROM blog_item bi
WHERE bi.category_id IS NOT NULL AND bi.category_id <> 0;

CREATE OR REPLACE VIEW v_blog_region_month AS
SELECT region_id, month, category_id, SUM(count_in_posts) AS blog_score_m
FROM v_blog_item_norm
GROUP BY region_id, month, category_id;

CREATE OR REPLACE VIEW v_blog_region_all AS
SELECT region_id, category_id, SUM(count_in_posts) AS blog_score_r
FROM v_blog_item_norm
GROUP BY region_id, category_id;

CREATE OR REPLACE VIEW v_blog_all AS
SELECT category_id, SUM(count_in_posts) AS blog_score_all
FROM v_blog_item_norm
GROUP BY category_id;

/* ───────────────────────────────────────────────────────────────────
   [6] CLIMATE (정규화)
   ─────────────────────────────────────────────────────────────────── */
CREATE OR REPLACE VIEW v_region_climate_monthfix AS
SELECT
  rc.region_id,
  CASE
    WHEN rc.month REGEXP '^[0-9]{4}-[0-9]{2}$' THEN rc.month
    ELSE DATE_FORMAT(rc.month, '%Y-%m')
  END AS month,
  rc.temperature_2m_max,
  rc.relative_humidity_2m_mean,
  rc.uv_index_max
FROM region_climate rc;

CREATE OR REPLACE VIEW v_region_climate_buckets AS
SELECT
  m.region_id, m.month,
  CASE
    WHEN m.temperature_2m_max >= 30 THEN 'hot humid'
    WHEN m.temperature_2m_max BETWEEN 20 AND 29 THEN 'warm humid'
    WHEN m.temperature_2m_max BETWEEN 10 AND 19 THEN 'mild humid'
    ELSE 'cold humid'
  END AS bucket_norm
FROM v_region_climate_monthfix m;

CREATE OR REPLACE VIEW v_region_climate_buckets_norm AS
SELECT region_id, month, bucket_norm
FROM (
  SELECT region_id, month, bucket_norm,
         ROW_NUMBER() OVER (PARTITION BY region_id, month ORDER BY COUNT(*) DESC) AS rn
  FROM v_region_climate_buckets
  GROUP BY region_id, month, bucket_norm
) t WHERE rn=1;

CREATE OR REPLACE VIEW v_region_climate_bucket_mode_norm AS
SELECT region_id, bucket_norm
FROM (
  SELECT region_id, bucket_norm,
         ROW_NUMBER() OVER (PARTITION BY region_id ORDER BY COUNT(*) DESC) AS rn
  FROM v_region_climate_buckets
  GROUP BY region_id, bucket_norm
) t WHERE rn=1;

CREATE OR REPLACE VIEW v_climate_cat_equalweight AS
SELECT
  TRIM(REPLACE(LOWER(m.climate_bucket), '_', ' ')) AS climate_bucket_norm,
  m.category_id,
  1.0 / NULLIF(cnt.cnt, 0) AS w_eq
FROM climate_category_map m
JOIN (
  SELECT TRIM(REPLACE(LOWER(climate_bucket), '_', ' ')) AS climate_bucket_norm,
         COUNT(*) AS cnt
  FROM climate_category_map
  GROUP BY TRIM(REPLACE(LOWER(climate_bucket), '_', ' '))
) cnt
  ON cnt.climate_bucket_norm = TRIM(REPLACE(LOWER(m.climate_bucket), '_', ' '));

CREATE OR REPLACE VIEW v_user_climate_cat AS
SELECT 
  rc.region_id, rc.month, ce.category_id, AVG(ce.w_eq) AS climate_cat_w
FROM v_region_climate_buckets_norm rc
JOIN v_climate_cat_equalweight ce
  ON ce.climate_bucket_norm = TRIM(REPLACE(LOWER(rc.bucket_norm),'_',' '))
GROUP BY rc.region_id, rc.month, ce.category_id;

/* ───────────────────────────────────────────────────────────────────
   [7] 카테고리 집합 & 콘텐츠 결합
   ─────────────────────────────────────────────────────────────────── */
CREATE OR REPLACE VIEW v_user_region_month_categories AS
SELECT utk.user_id, utk.region_id, utk.month, c.category_id
FROM v_user_trip_key utk
JOIN (
  SELECT DISTINCT category_id FROM activity_category_map
  UNION
  SELECT DISTINCT category_id FROM climate_category_map
  UNION
  SELECT DISTINCT category_id FROM v_blog_item_norm
  UNION
  SELECT DISTINCT category_id FROM snap_products
) c
WHERE c.category_id IS NOT NULL;

CREATE OR REPLACE VIEW v_region_content_cat AS
SELECT
  u.region_id, u.month, u.category_id,
  COALESCE(bm.blog_score_m, br.blog_score_r, ba.blog_score_all, 0) AS blog_score,
  COALESCE(s.snap_score, sa.snap_score_all, 0) AS snap_score
FROM v_user_region_month_categories u
LEFT JOIN v_blog_region_month bm
  ON bm.region_id=u.region_id AND bm.month=u.month AND bm.category_id=u.category_id
LEFT JOIN v_blog_region_all br
  ON br.region_id=u.region_id AND br.category_id=u.category_id
LEFT JOIN v_blog_all ba
  ON ba.category_id=u.category_id
LEFT JOIN snap_category_stats s
  ON s.region_id=u.region_id AND s.category_id=u.category_id
LEFT JOIN v_snap_all sa
  ON sa.category_id=u.category_id;

/* ───────────────────────────────────────────────────────────────────
   [8] 신호 통합 (수정안2: GROUP BY + MAX로 단일화)
   ─────────────────────────────────────────────────────────────────── */
CREATE OR REPLACE VIEW v_user_category_signal AS
SELECT
  u.user_id,
  u.region_id,
  u.month,
  u.category_id,
  COALESCE(MAX(ac.activity_cat_w), MAX(afb.activity_cat_w_fb), 0) AS activity_cat_w,
  COALESCE(MAX(cc.climate_cat_w), 0)                              AS climate_cat_w,
  COALESCE(MAX(rc.blog_score), 0)                                 AS blog_score,
  COALESCE(MAX(rc.snap_score), 0)                                 AS snap_score
FROM v_user_region_month_categories u
LEFT JOIN v_user_activity_cat ac
  ON ac.user_id=u.user_id AND ac.category_id=u.category_id
LEFT JOIN v_user_activity_cat_fallback afb
  ON afb.user_id=u.user_id AND afb.category_id=u.category_id
LEFT JOIN v_user_climate_cat cc
  ON cc.region_id=u.region_id AND cc.month=u.month AND cc.category_id=u.category_id
LEFT JOIN v_region_content_cat rc
  ON rc.region_id=u.region_id AND rc.category_id=u.category_id
GROUP BY u.user_id, u.region_id, u.month, u.category_id;

/* ───────────────────────────────────────────────────────────────────
   [9] 최종 카테고리 점수 (수정안3: 중복 안전 서브쿼리)
   ─────────────────────────────────────────────────────────────────── */
CREATE OR REPLACE VIEW v_user_category_score AS
SELECT
  s.user_id,
  s.category_id,
  CASE
    WHEN (COALESCE(s.climate_cat_w,0)+COALESCE(s.activity_cat_w,0)+COALESCE(s.blog_score,0)+COALESCE(s.snap_score,0))=0
    THEN 0.05
    ELSE (0.9*s.climate_cat_w)+(0.1*s.activity_cat_w)+(0.0*s.blog_score)+(0.0*s.snap_score)
  END AS final_cat_score
FROM (
  SELECT
    user_id, category_id,
    MAX(activity_cat_w) AS activity_cat_w,
    MAX(climate_cat_w)  AS climate_cat_w,
    MAX(blog_score)     AS blog_score,
    MAX(snap_score)     AS snap_score
  FROM v_user_category_signal
  GROUP BY user_id, category_id
) s;

/* ───────────────────────────────────────────────────────────────────
   [10] 제품 정규화·버킷·후보 (수정안1: URL 기준 dedup)
   ─────────────────────────────────────────────────────────────────── */
CREATE OR REPLACE VIEW v_user_primary_bucket AS
SELECT utk.user_id,
       COALESCE(rb.bucket_norm, rbm.bucket_norm) AS bucket_norm
FROM v_user_trip_key utk
LEFT JOIN v_region_climate_buckets_norm rb
  ON rb.region_id=utk.region_id AND rb.month=utk.month
LEFT JOIN v_region_climate_bucket_mode_norm rbm
  ON rbm.region_id=utk.region_id;

CREATE OR REPLACE VIEW v_products_norm AS
SELECT
  MIN(product_name) AS product_name,
  product_url,
  MIN(category) AS category,
  REGEXP_REPLACE(REGEXP_REPLACE(LOWER(TRIM(MIN(category))),'\\s+',' '),'[-_/]',' ') AS category_norm
FROM products
WHERE product_url IS NOT NULL
GROUP BY product_url;

CREATE OR REPLACE VIEW v_category_norm AS
SELECT category_id, category,
       REGEXP_REPLACE(REGEXP_REPLACE(LOWER(TRIM(category)),'\\s+',' '),'[-_/]',' ') AS category_norm
FROM category;

CREATE OR REPLACE VIEW v_user_product_candidates AS
SELECT
  ucs.user_id,
  c.category_id,
  p.product_name, p.product_url, p.category,
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

/* ───────────────────────────────────────────────────────────────────
   [11] Top5 × 4개 (수정안4 + 보강: strict + relaxed)
   ─────────────────────────────────────────────────────────────────── */
CREATE OR REPLACE VIEW v_user_top5cat_4item AS
WITH ranked_cats AS (
  SELECT
    user_id,
    category_id,
    final_cat_score,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY final_cat_score DESC) AS cat_rank
  FROM v_user_category_score
),
top_cats AS (
  SELECT DISTINCT user_id, category_id
  FROM ranked_cats
  WHERE cat_rank <= 5
),
strict AS (  -- 기존 후보
  SELECT
    upc.user_id,
    upc.category_id,
    upc.product_name,
    upc.product_url,
    upc.category,
    upc.base_score AS score,
    2 AS src_priority
  FROM v_user_product_candidates upc
  JOIN top_cats t ON t.user_id=upc.user_id AND t.category_id=upc.category_id
),
relaxed AS (  -- 부족분 보강(기후 필터 제거), URL 중복 방지
  SELECT
    ucs.user_id,
    ucs.category_id,
    p.product_name,
    p.product_url,
    p.category,
    (ucs.final_cat_score * 0.90) AS score,  -- 완화 패널티
    1 AS src_priority
  FROM v_user_category_score ucs
  JOIN top_cats t
    ON t.user_id=ucs.user_id AND t.category_id=ucs.category_id
  JOIN v_category_norm c
    ON c.category_id = ucs.category_id
  JOIN v_products_norm p
    ON p.category_norm = c.category_norm
  WHERE NOT EXISTS (
    SELECT 1 FROM v_user_product_candidates s
    WHERE s.user_id=ucs.user_id
      AND s.category_id=ucs.category_id
      AND s.product_url = p.product_url
  )
),
ranked_products AS (
  SELECT
    x.user_id,
    x.category_id,
    x.product_name,
    x.product_url,
    x.category,
    x.score,
    ROW_NUMBER() OVER (
      PARTITION BY x.user_id, x.category_id
      ORDER BY x.src_priority DESC, x.score DESC, x.product_name, x.product_url
    ) AS prod_rank
  FROM (
    SELECT * FROM strict
    UNION ALL
    SELECT * FROM relaxed
  ) x
)
SELECT
  r.user_id, r.category_id, r.product_name, r.product_url, r.category, r.score AS base_score
FROM ranked_products r
WHERE r.prod_rank <= 4;

/* ───────────────────────────────────────────────────────────────────
   [12] Top20 (strict + relaxed)
   ─────────────────────────────────────────────────────────────────── */
CREATE OR REPLACE VIEW v_user_top20_products AS
WITH strict AS (
  SELECT
    upc.user_id,
    upc.category_id,
    upc.product_name,
    upc.product_url,
    upc.category,
    upc.base_score AS score,
    2 AS src_priority
  FROM v_user_product_candidates upc
),
relaxed AS (
  SELECT
    ucs.user_id,
    ucs.category_id,
    p.product_name,
    p.product_url,
    p.category,
    (ucs.final_cat_score * 0.90) AS score,
    1 AS src_priority
  FROM v_user_category_score ucs
  JOIN v_category_norm c ON c.category_id=ucs.category_id
  JOIN v_products_norm p ON p.category_norm=c.category_norm
  WHERE NOT EXISTS (
    SELECT 1 FROM v_user_product_candidates s
    WHERE s.user_id=ucs.user_id
      AND s.category_id=ucs.category_id
      AND s.product_url = p.product_url
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
  user_id, product_name, category, product_url, score AS base_score
FROM ranked
WHERE rn <= 20;

/* ───────────────────────────────────────────────────────────────────
   [13] 실행 예시
   ─────────────────────────────────────────────────────────────────── */
SET @uid = 2001;
SELECT * FROM v_user_top5cat_4item  WHERE user_id=@uid;
SELECT * FROM v_user_top20_products WHERE user_id=@uid;
