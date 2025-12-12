/* ╔══════════════════════════════════════════════════════════════════╗
   ║  FitPl 알고리즘 DDL (최종 / MySQL 8.0.43 호환)                  ║
   ║  - 생성컬럼+인덱스 최적화, 후보축소                             ║
   ║  - v_country_* Top20 + *ALL(무제한)                              ║
   ║  - 기후버킷: 온도×습도(+우기) 세분화 + 4버킷 호환조인            ║
   ║  - Photo 뷰: 카테고리 다양성 쿼터 + 보조랭킹 + 디듀프            ║
   ║  - 게스트용 테이블: 이미 생성된 값 고정(DDL 전부 주석처리)       ║
   ╚══════════════════════════════════════════════════════════════════╝ */

USE fitpl;
SET SESSION sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));
SET SQL_SAFE_UPDATES = 0;

/* ────────────────────────────────────────────────────────────────
   0) product_id 보정 (URL 끝 숫자)
   ──────────────────────────────────────────────────────────────── */
UPDATE products
SET product_id = CAST(REGEXP_SUBSTR(product_url, '[0-9]+$') AS UNSIGNED)
WHERE product_id IS NULL
  AND product_url REGEXP '[0-9]+$';

/* ────────────────────────────────────────────────────────────────
   0-1) 생성컬럼(category_norm) — 없을 때만 추가
   ──────────────────────────────────────────────────────────────── */
-- products.category_norm
SET @col_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME='products' AND COLUMN_NAME='category_norm'
);
SET @sql := IF(@col_exists=0,
  'ALTER TABLE products ADD COLUMN category_norm VARCHAR(255)
     GENERATED ALWAYS AS (
       REGEXP_REPLACE(REGEXP_REPLACE(LOWER(TRIM(category)), ''\\s+'','' ''), ''[-_/]'','' '')
     ) STORED;',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- category.category_norm
SET @col_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME='category' AND COLUMN_NAME='category_norm'
);
SET @sql := IF(@col_exists=0,
  'ALTER TABLE category ADD COLUMN category_norm VARCHAR(255)
     GENERATED ALWAYS AS (
       REGEXP_REPLACE(REGEXP_REPLACE(LOWER(TRIM(category)), ''\\s+'','' ''), ''[-_/]'','' '')
     ) STORED;',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

/* ────────────────────────────────────────────────────────────────
   DROP (의존 순서)
   ──────────────────────────────────────────────────────────────── */
DROP VIEW IF EXISTS v_country_photo_products_all;
DROP VIEW IF EXISTS v_country_activity_products_all;
DROP VIEW IF EXISTS v_country_climate_products_all;

DROP VIEW IF EXISTS v_country_photo_top20_products;
DROP VIEW IF EXISTS v_country_activity_top20_products;
DROP VIEW IF EXISTS v_country_climate_top20_products;

DROP VIEW IF EXISTS v_user_top20_products;
DROP VIEW IF EXISTS v_user_top5cat_4item;
DROP VIEW IF EXISTS v_user_product_candidates;
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
DROP VIEW IF EXISTS v_climate_bucket_alias;
DROP VIEW IF EXISTS v_region_climate_bucket_mode_norm;
DROP VIEW IF EXISTS v_region_climate_buckets_norm;
DROP VIEW IF EXISTS v_region_climate_buckets;
DROP VIEW IF EXISTS v_region_climate_monthfix;

DROP VIEW IF EXISTS v_region_alias;
DROP VIEW IF EXISTS v_user_trip_key;

/* ────────────────────────────────────────────────────────────────
   1) 여행키
   ──────────────────────────────────────────────────────────────── */
CREATE OR REPLACE VIEW v_user_trip_key AS
SELECT
  u.user_id,
  u.trip_region_id AS region_id,
  DATE_FORMAT(u.trip_start_date, '%Y-%m') AS month
FROM users u
WHERE u.trip_region_id IS NOT NULL
  AND u.trip_start_date IS NOT NULL;

/* ────────────────────────────────────────────────────────────────
   2) 활동 파이프라인 (게스트 태그 alias 보강)
   ──────────────────────────────────────────────────────────────── */
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
SELECT 'citytour'        AS tag_norm, 'citytour' AS tag_origin
UNION ALL SELECT 'urban'         , 'citytour'
UNION ALL SELECT 'shopping'      , 'shopping'
UNION ALL SELECT 'outletmall'    , 'shopping'
UNION ALL SELECT 'food'          , 'food'
UNION ALL SELECT 'restaurant'    , 'food'
UNION ALL SELECT 'gourmet'       , 'food'
UNION ALL SELECT 'surfing'       , 'water'
UNION ALL SELECT 'snorkeling'    , 'water'
UNION ALL SELECT 'diving'        , 'water'
UNION ALL SELECT 'museum'        , 'culture'
UNION ALL SELECT 'art'           , 'culture'
UNION ALL SELECT 'hiking'        , 'nature'
UNION ALL SELECT 'trekking'      , 'nature'
UNION ALL SELECT 'walking'       , 'nature'
UNION ALL SELECT 'themepark'     , 'leisure'
UNION ALL SELECT 'amusement'     , 'leisure'
UNION ALL SELECT 'indoor'        , 'indoor'
UNION ALL SELECT 'outdoor'       , 'outdoor'
UNION ALL SELECT 'observationdeck','culture'
UNION ALL SELECT 'marketnight'   , 'shopping'
UNION ALL SELECT 'zoo'           , 'leisure'
UNION ALL SELECT 'cathedralchurch','culture'
UNION ALL SELECT 'templeshrine'  , 'culture'
UNION ALL SELECT 'nationalpark'  , 'nature'
UNION ALL SELECT 'aquarium'      , 'leisure'
UNION ALL SELECT 'beach'         , 'water';

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

/* ────────────────────────────────────────────────────────────────
   3) 지역 별칭
   ──────────────────────────────────────────────────────────────── */
CREATE OR REPLACE VIEW v_region_alias AS
SELECT region_id, TRIM(LOWER(region_name_en)) AS alias_norm FROM region
UNION ALL
SELECT region_id, TRIM(LOWER(region_name_ko)) FROM region;

/* ────────────────────────────────────────────────────────────────
   4) SNAP 점수
   ──────────────────────────────────────────────────────────────── */
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

/* ────────────────────────────────────────────────────────────────
   5) BLOG 점수
   ──────────────────────────────────────────────────────────────── */
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

/* ────────────────────────────────────────────────────────────────
   6) CLIMATE  ✅ (세분화 버킷 + 4버킷 호환조인)
   ──────────────────────────────────────────────────────────────── */
CREATE OR REPLACE VIEW v_region_climate_monthfix AS
SELECT
  rc.region_id,
  CASE
    WHEN rc.month REGEXP '^[0-9]{4}-[0-9]{2}$' THEN rc.month
    ELSE DATE_FORMAT(rc.month, '%Y-%m')
  END AS month,
  rc.temperature_2m_max,
  rc.apparent_temperature_mean,
  rc.relative_humidity_2m_mean,
  rc.precip_days,
  rc.uv_index_max
FROM region_climate rc;

CREATE OR REPLACE VIEW v_region_climate_buckets AS
SELECT
  m.region_id,
  m.month,
  /* 온도 밴드: 체감온도 우선, 없으면 tmax */
  CASE
    WHEN COALESCE(m.apparent_temperature_mean, m.temperature_2m_max) >= 32 THEN 'very hot'
    WHEN COALESCE(m.apparent_temperature_mean, m.temperature_2m_max) BETWEEN 28 AND 31 THEN 'hot'
    WHEN COALESCE(m.apparent_temperature_mean, m.temperature_2m_max) BETWEEN 24 AND 27 THEN 'warm'
    WHEN COALESCE(m.apparent_temperature_mean, m.temperature_2m_max) BETWEEN 18 AND 23 THEN 'mild'
    WHEN COALESCE(m.apparent_temperature_mean, m.temperature_2m_max) BETWEEN 12 AND 17 THEN 'cool'
    WHEN COALESCE(m.apparent_temperature_mean, m.temperature_2m_max) BETWEEN 6 AND 11 THEN 'cold'
    ELSE 'very cold'
  END AS temp_band,
  CASE WHEN m.relative_humidity_2m_mean >= 70 THEN 'humid' ELSE 'dry' END AS humidity_band,
  CASE WHEN COALESCE(m.precip_days,0) >= 10 THEN 1 ELSE 0 END AS is_rainy,
  CONCAT(
    CASE
      WHEN COALESCE(m.apparent_temperature_mean, m.temperature_2m_max) >= 32 THEN 'very hot'
      WHEN COALESCE(m.apparent_temperature_mean, m.temperature_2m_max) BETWEEN 28 AND 31 THEN 'hot'
      WHEN COALESCE(m.apparent_temperature_mean, m.temperature_2m_max) BETWEEN 24 AND 27 THEN 'warm'
      WHEN COALESCE(m.apparent_temperature_mean, m.temperature_2m_max) BETWEEN 18 AND 23 THEN 'mild'
      WHEN COALESCE(m.apparent_temperature_mean, m.temperature_2m_max) BETWEEN 12 AND 17 THEN 'cool'
      WHEN COALESCE(m.apparent_temperature_mean, m.temperature_2m_max) BETWEEN 6 AND 11 THEN 'cold'
      ELSE 'very cold'
    END,
    ' ',
    CASE WHEN m.relative_humidity_2m_mean >= 70 THEN 'humid' ELSE 'dry' END,
    CASE WHEN COALESCE(m.precip_days,0) >= 10 THEN '-rainy' ELSE '' END
  ) AS bucket_norm_granular
FROM v_region_climate_monthfix m;

CREATE OR REPLACE VIEW v_region_climate_buckets_norm AS
SELECT region_id, month, bucket_norm_granular AS bucket_norm
FROM (
  SELECT region_id, month, bucket_norm_granular,
         ROW_NUMBER() OVER (PARTITION BY region_id, month ORDER BY COUNT(*) DESC) AS rn
  FROM v_region_climate_buckets
  GROUP BY region_id, month, bucket_norm_granular
) t WHERE rn=1;

CREATE OR REPLACE VIEW v_region_climate_bucket_mode_norm AS
SELECT region_id, bucket_norm
FROM (
  SELECT region_id, bucket_norm_granular AS bucket_norm,
         ROW_NUMBER() OVER (PARTITION BY region_id ORDER BY COUNT(*) DESC) AS rn
  FROM v_region_climate_buckets
  GROUP BY region_id, bucket_norm_granular
) t WHERE rn=1;

CREATE OR REPLACE VIEW v_climate_bucket_alias AS
SELECT
  b.bucket_norm AS granular_bucket,
  CASE
    WHEN b.temp_band IN ('very hot','hot')  AND b.humidity_band='humid' THEN 'hot humid'
    WHEN b.temp_band IN ('warm')            AND b.humidity_band='humid' THEN 'warm humid'
    WHEN b.temp_band IN ('mild')            AND b.humidity_band='humid' THEN 'mild humid'
    WHEN b.temp_band IN ('cool','cold','very cold') THEN 'cold humid'
    WHEN b.temp_band IN ('very hot','hot')  AND b.humidity_band='dry'   THEN 'hot humid'
    WHEN b.temp_band IN ('warm')            AND b.humidity_band='dry'   THEN 'warm humid'
    WHEN b.temp_band IN ('mild')            AND b.humidity_band='dry'   THEN 'mild humid'
    ELSE 'cold humid'
  END AS base_bucket_4
FROM (
  SELECT region_id, month, temp_band, humidity_band, is_rainy,
         CONCAT(temp_band,' ',humidity_band,CASE WHEN is_rainy=1 THEN '-rainy' ELSE '' END) AS bucket_norm
  FROM v_region_climate_buckets
) b;

CREATE OR REPLACE VIEW v_climate_cat_equalweight AS
SELECT
  t.granular_bucket AS climate_bucket_norm,
  m.category_id,
  1.0 / NULLIF(cnt.cnt, 0) AS w_eq
FROM (
  SELECT DISTINCT a.granular_bucket, a.base_bucket_4
  FROM v_climate_bucket_alias a
) t
JOIN (
  SELECT TRIM(REPLACE(LOWER(climate_bucket),'_',' ')) AS base_bucket_4,
         category_id
  FROM climate_category_map
) m
  ON TRIM(REPLACE(LOWER(t.base_bucket_4),'_',' ')) = m.base_bucket_4
JOIN (
  SELECT TRIM(REPLACE(LOWER(climate_bucket),'_',' ')) AS base_bucket_4,
         COUNT(*) AS cnt
  FROM climate_category_map
  GROUP BY TRIM(REPLACE(LOWER(climate_bucket),'_',' '))
) cnt
  ON cnt.base_bucket_4 = m.base_bucket_4;

CREATE OR REPLACE VIEW v_user_climate_cat AS
SELECT 
  rc.region_id, rc.month, ce.category_id, AVG(ce.w_eq) AS climate_cat_w
FROM v_region_climate_buckets_norm rc
JOIN v_climate_cat_equalweight ce
  ON TRIM(LOWER(rc.bucket_norm)) = TRIM(LOWER(ce.climate_bucket_norm))
GROUP BY rc.region_id, rc.month, ce.category_id;

/* ────────────────────────────────────────────────────────────────
   7) 카테고리 집합 & 콘텐츠 결합
   ──────────────────────────────────────────────────────────────── */
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

/* ────────────────────────────────────────────────────────────────
   8) 신호 통합
   ──────────────────────────────────────────────────────────────── */
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

/* ────────────────────────────────────────────────────────────────
   9) 최종 카테고리 점수 (기본: 기후 0.9, 활동 0.1)
   ──────────────────────────────────────────────────────────────── */
CREATE OR REPLACE VIEW v_user_category_score AS
SELECT
  s.user_id,
  s.category_id,
  CASE
    WHEN (COALESCE(s.climate_cat_w,0)+COALESCE(s.activity_cat_w,0)+COALESCE(s.blog_score,0)+COALESCE(s.snap_score,0))=0
    THEN 0.05
    ELSE (0.9*s.climate_cat_w)+(0.1*s.activity_cat_w)
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

/* ────────────────────────────────────────────────────────────────
   10) 사용자 기본 버킷 (그라뉼 라벨 유지)
   ──────────────────────────────────────────────────────────────── */
CREATE OR REPLACE VIEW v_user_primary_bucket AS
SELECT utk.user_id,
       COALESCE(rb.bucket_norm, rbm.bucket_norm) AS bucket_norm
FROM v_user_trip_key utk
LEFT JOIN v_region_climate_buckets_norm rb
  ON rb.region_id=utk.region_id AND rb.month=utk.month
LEFT JOIN v_region_climate_bucket_mode_norm rbm
  ON rbm.region_id=utk.region_id;

/* ────────────────────────────────────────────────────────────────
   11) 제품 후보 (시즌/잡화 제외 규칙 포함)
   ──────────────────────────────────────────────────────────────── */
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
JOIN category c   ON c.category_id = ucs.category_id
JOIN products p   ON p.category_norm = c.category_norm
LEFT JOIN v_user_primary_bucket ub ON ub.user_id = ucs.user_id
WHERE ucs.final_cat_score > 0
  /* 더운 지역(very hot/hot/warm …)에서의 보온/긴팔류 제외 — 그라뉼 라벨 대응 */
  AND NOT (
    (ub.bucket_norm REGEXP '^(very hot|hot|warm)( |-|$)')
    AND (LOWER(p.category) REGEXP 'coat|jacket|padding|down|sweater|cardigan|hood|long\\s*sleeve|knit|pique|collar')
  )
  /* 잡화/비의류성 카테고리 제외 */
  AND NOT (
    LOWER(p.category) REGEXP 'organiz(e|ation)|suppl(y|ies)|equipment|stationer(y|ies)|office|tool(s)?'
    OR LOWER(c.category) REGEXP 'organiz(e|ation)|suppl(y|ies)|equipment|stationer(y|ies)|office|tool(s)?'
  );

/* ────────────────────────────────────────────────────────────────
   12) 메인 출력 — Top5×4, Top20
   ──────────────────────────────────────────────────────────────── */
CREATE OR REPLACE VIEW v_user_top5cat_4item AS
WITH ranked_cats AS (
  SELECT user_id, category_id, final_cat_score,
         ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY final_cat_score DESC) AS cat_rank
  FROM v_user_category_score
),
top_cats AS ( SELECT DISTINCT user_id, category_id FROM ranked_cats WHERE cat_rank <= 5 ),
strict AS (
  SELECT upc.user_id, upc.category_id, upc.product_id,
         upc.brand, upc.main_category, upc.color, upc.discount_rate, upc.gender_en, upc.img_url,
         upc.material, upc.monthly_views, upc.price, upc.product_serial,
         upc.product_name, upc.product_name_detail,
         upc.product_url, upc.rating, upc.review_count, upc.sales, upc.season, upc.style_tag, upc.category,
         upc.base_score AS score, 2 AS src_priority
  FROM v_user_product_candidates upc
  JOIN top_cats t ON t.user_id=upc.user_id AND t.category_id=upc.category_id
),
relaxed AS (
  SELECT ucs.user_id, ucs.category_id, p.product_id,
         p.brand, p.main_category, p.color, p.discount_rate, p.gender_en, p.img_url,
         p.material, p.monthly_views, p.price, p.product_serial,
         p.product_name, p.product_name_detail,
         p.product_url, p.rating, p.review_count, p.sales, p.season, p.style_tag, p.category,
         (ucs.final_cat_score * 0.90) AS score, 1 AS src_priority
  FROM v_user_category_score ucs
  JOIN category c ON c.category_id=ucs.category_id
  JOIN products p ON p.category_norm=c.category_norm
  JOIN top_cats t ON t.user_id=ucs.user_id AND t.category_id=ucs.category_id
  WHERE NOT EXISTS (
    SELECT 1 FROM v_user_product_candidates s
    WHERE s.user_id=ucs.user_id AND s.category_id=ucs.category_id AND s.product_id=p.product_id
  )
),
ranked_products AS (
  SELECT x.*,
         ROW_NUMBER() OVER (
           PARTITION BY x.user_id, x.category_id
           ORDER BY x.src_priority DESC, x.score DESC, x.product_name, x.product_url
         ) AS prod_rank
  FROM (SELECT * FROM strict UNION ALL SELECT * FROM relaxed) x
)
SELECT
  r.user_id, r.product_id,
  r.brand, r.main_category, r.color, r.discount_rate, r.gender_en, r.img_url,
  r.material, r.monthly_views, r.price, r.product_serial,
  r.product_name, r.product_name_detail,
  r.product_url, r.rating, r.review_count, r.sales, r.season, r.style_tag, r.category,
  r.score AS base_score
FROM ranked_products r
WHERE r.prod_rank <= 4;

CREATE OR REPLACE VIEW v_user_top20_products AS
WITH strict AS (
  SELECT upc.user_id, upc.product_id,
         upc.brand, upc.main_category, upc.color, upc.discount_rate, upc.gender_en, upc.img_url,
         upc.material, upc.monthly_views, upc.price, upc.product_serial,
         upc.product_name, upc.product_name_detail,
         upc.product_url, upc.rating, upc.review_count, upc.sales, upc.season, upc.style_tag, upc.category,
         upc.base_score AS score, 2 AS src_priority
  FROM v_user_product_candidates upc
),
relaxed AS (
  SELECT ucs.user_id, p.product_id,
         p.brand, p.main_category, p.color, p.discount_rate, p.gender_en, p.img_url,
         p.material, p.monthly_views, p.price, p.product_serial,
         p.product_name, p.product_name_detail,
         p.product_url, p.rating, p.review_count, p.sales, p.season, p.style_tag, p.category,
         (ucs.final_cat_score * 0.90) AS score, 1 AS src_priority
  FROM v_user_category_score ucs
  JOIN category c ON c.category_id=ucs.category_id
  JOIN products p ON p.category_norm=c.category_norm
  WHERE NOT EXISTS (
    SELECT 1
    FROM v_user_product_candidates s
    WHERE s.user_id     = ucs.user_id
      AND s.category_id = ucs.category_id
      AND s.product_id  = p.product_id
  )
),
pool AS (SELECT * FROM strict UNION ALL SELECT * FROM relaxed),
ranked AS (
  SELECT p.*,
         ROW_NUMBER() OVER (
           PARTITION BY p.user_id
           ORDER BY p.src_priority DESC, p.score DESC, p.product_name, p.product_url
         ) AS rn
  FROM pool p
)
SELECT
  user_id, product_id,
  brand, main_category, color, discount_rate, gender_en, img_url,
  material, monthly_views, price, product_serial,
  product_name, product_name_detail,
  product_url, rating, review_count, sales, season, style_tag, category,
  score AS base_score
FROM ranked
WHERE rn <= 20;

/* ────────────────────────────────────────────────────────────────
   13) 국가 상세 — Climate/Activity/Photo (Top20 & ALL)
   ──────────────────────────────────────────────────────────────── */

-- Climate ALL (중복 억제 없음: 기존 유지)
CREATE OR REPLACE VIEW v_country_climate_products_all AS
WITH score AS (
  SELECT s.user_id, s.category_id,
         (0.90*MAX(s.climate_cat_w)) + (0.10*MAX(s.activity_cat_w)) AS w
  FROM v_user_category_signal s
  GROUP BY s.user_id, s.category_id
),
candidates AS ( SELECT sc.user_id, sc.category_id, sc.w AS final_cat_score FROM score sc WHERE sc.w > 0 ),
pool AS (
  SELECT c.user_id, p.product_id,
         p.brand, p.main_category, p.color, p.discount_rate, p.gender_en, p.img_url,
         p.material, p.monthly_views, p.price, p.product_serial,
         p.product_name, p.product_name_detail,
         p.product_url, p.rating, p.review_count, p.sales, p.season, p.style_tag, p.category,
         c.final_cat_score AS score, 2 AS src_priority
  FROM candidates c
  JOIN category  cn ON cn.category_id=c.category_id
  JOIN products  p  ON p.category_norm=cn.category_norm
),
ranked AS (
  SELECT x.*,
         ROW_NUMBER() OVER (
           PARTITION BY x.user_id
           ORDER BY x.src_priority DESC, x.score DESC, x.product_name, x.product_url
         ) AS rn
  FROM pool x
)
SELECT * FROM ranked;

CREATE OR REPLACE VIEW v_country_climate_top20_products AS
SELECT * FROM v_country_climate_products_all WHERE rn <= 20;

-- Activity ALL (기존 방어로직 유지)
CREATE OR REPLACE VIEW v_country_activity_products_all AS
WITH score AS (
  SELECT s.user_id, s.category_id,
         (0.10*MAX(s.climate_cat_w)) + (0.90*MAX(s.activity_cat_w)) AS w
  FROM v_user_category_signal s
  GROUP BY s.user_id, s.category_id
),
activity_topK AS (
  SELECT user_id, category_id
  FROM (
    SELECT user_id, category_id,
           ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY w DESC, category_id) AS rnk
    FROM score
  ) t WHERE rnk <= 12
),
p_ranked AS (
  SELECT p.*,
         ROW_NUMBER() OVER (
           PARTITION BY p.category_norm
           ORDER BY COALESCE(p.monthly_views,0) DESC,
                    COALESCE(p.rating,0)        DESC,
                    COALESCE(p.review_count,0)   DESC,
                    p.product_id
         ) AS pr
  FROM products p
),
pool AS (
  SELECT a.user_id, pr.product_id,
         pr.brand, pr.main_category, pr.color, pr.discount_rate, pr.gender_en, pr.img_url,
         pr.material, pr.monthly_views, pr.price, pr.product_serial,
         pr.product_name, pr.product_name_detail,
         pr.product_url, pr.rating, pr.review_count, pr.sales, pr.season, pr.style_tag, pr.category,
         1.0 AS score, 2 AS src_priority
  FROM activity_topK a
  JOIN category  c  ON c.category_id=a.category_id
  JOIN p_ranked  pr ON pr.category_norm=c.category_norm
  WHERE pr.pr <= 200
),
pool_dedup AS (
  SELECT *
  FROM (
    SELECT x.*,
           ROW_NUMBER() OVER (
             PARTITION BY x.user_id, x.product_id
             ORDER BY x.src_priority DESC, x.score DESC, x.product_name, x.product_url
           ) AS rk
    FROM pool x
  ) q WHERE q.rk = 1
),
ranked AS (
  SELECT d.*,
         ROW_NUMBER() OVER (
           PARTITION BY d.user_id
           ORDER BY d.src_priority DESC, d.score DESC, d.product_name, d.product_url
         ) AS rn
  FROM pool_dedup d
)
SELECT * FROM ranked;

CREATE OR REPLACE VIEW v_country_activity_top20_products AS
SELECT * FROM v_country_activity_products_all WHERE rn <= 20;

-- Photo ALL ✅ (다양성/보조랭킹/디듀프 적용)
CREATE OR REPLACE VIEW v_country_photo_products_all AS
WITH score AS (
  SELECT s.user_id, s.category_id,
         (0.30*MAX(s.blog_score)) + (0.70*MAX(s.snap_score)) AS w
  FROM v_user_category_signal s
  GROUP BY s.user_id, s.category_id
),
candidates AS (
  SELECT sc.user_id, sc.category_id, sc.w AS final_cat_score
  FROM score sc
  WHERE sc.w > 0
),
p_ranked AS (
  SELECT p.*,
         ROW_NUMBER() OVER (
           PARTITION BY p.category_norm
           ORDER BY
             COALESCE(p.monthly_views,0) DESC,
             COALESCE(p.rating,0)        DESC,
             COALESCE(p.review_count,0)  DESC,
             p.product_id
         ) AS pr
  FROM products p
),
pool AS (
  SELECT c.user_id, pr.product_id,
         pr.brand, pr.main_category, pr.color, pr.discount_rate, pr.gender_en, pr.img_url,
         pr.material, pr.monthly_views, pr.price, pr.product_serial,
         pr.product_name, pr.product_name_detail,
         pr.product_url, pr.rating, pr.review_count, pr.sales, pr.season, pr.style_tag, pr.category,
         c.final_cat_score AS score,
         2 AS src_priority,
         pr.category_norm
  FROM candidates c
  JOIN category  cn ON cn.category_id = c.category_id
  JOIN p_ranked  pr ON pr.category_norm = cn.category_norm
  WHERE pr.pr <= 200
),
pool_scored AS (
  SELECT p.*,
         p.score
         * CASE
             WHEN p.category_norm REGEXP 'shoe|sneaker|sandals?' THEN 0.90
             ELSE 1.0
           END AS score_adj
  FROM pool p
),
pool_cat_cap AS (
  SELECT x.*,
         ROW_NUMBER() OVER (
           PARTITION BY x.user_id, x.category_norm
           ORDER BY x.src_priority DESC, x.score_adj DESC, x.product_name, x.product_url
         ) AS cat_rn
  FROM pool_scored x
),
pool_dedup AS (
  SELECT *
  FROM (
    SELECT y.*,
           ROW_NUMBER() OVER (
             PARTITION BY y.user_id, y.product_id
             ORDER BY y.src_priority DESC, y.score_adj DESC, y.product_name, y.product_url
           ) AS rk
    FROM pool_cat_cap y
    WHERE y.cat_rn <= 3  /* 카테고리당 최대 N개 */
  ) q
  WHERE q.rk = 1
),
ranked AS (
  SELECT d.*,
         ROW_NUMBER() OVER (
           PARTITION BY d.user_id
           ORDER BY d.src_priority DESC, d.score_adj DESC, d.product_name, d.product_url
         ) AS rn
  FROM pool_dedup d
)
SELECT * FROM ranked;

CREATE OR REPLACE VIEW v_country_photo_top20_products AS
SELECT * FROM v_country_photo_products_all WHERE rn <= 20;

/* ────────────────────────────────────────────────────────────────
   14) 인덱스 체크리스트 (MySQL 8.0.43 호환)
   ──────────────────────────────────────────────────────────────── */
DROP PROCEDURE IF EXISTS add_index_if_missing;
DELIMITER //
CREATE PROCEDURE add_index_if_missing()
BEGIN
  DECLARE idx_cnt INT DEFAULT 0;
  SELECT COUNT(*) INTO idx_cnt
  FROM INFORMATION_SCHEMA.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = @tbl
    AND INDEX_NAME   = @idx;
  IF idx_cnt = 0 THEN
    SET @sql := @ddl;
    PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
  END IF;
END//
DELIMITER ;

SET @tbl='region_climate', @idx='idx_rc_region_month',
    @ddl='ALTER TABLE region_climate ADD INDEX idx_rc_region_month (region_id, month)';
CALL add_index_if_missing();

SET @tbl='climate_category_map', @idx='idx_ccm_bucket_cat',
    @ddl='ALTER TABLE climate_category_map ADD INDEX idx_ccm_bucket_cat (climate_bucket, category_id)';
CALL add_index_if_missing();

SET @tbl='activity_category_map', @idx='idx_acm_tag_cat',
    @ddl='ALTER TABLE activity_category_map ADD INDEX idx_acm_tag_cat (activity_tag, category_id)';
CALL add_index_if_missing();

SET @tbl='blog_item', @idx='idx_bi_cat',
    @ddl='ALTER TABLE blog_item ADD INDEX idx_bi_cat (category_id)';
CALL add_index_if_missing();

SET @tbl='blog_item', @idx='idx_bi_rmcat',
    @ddl=IF(
      (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
         WHERE TABLE_SCHEMA=DATABASE()
           AND TABLE_NAME='blog_item'
           AND COLUMN_NAME IN ('region_id','month'))=2,
      'ALTER TABLE blog_item ADD INDEX idx_bi_rmcat (region_id, month, category_id)',
      'SELECT 1'
    );
CALL add_index_if_missing();

SET @tbl='snap_products', @idx='idx_spp_region_cat',
    @ddl='ALTER TABLE snap_products ADD INDEX idx_spp_region_cat (region_id, category_id)';
CALL add_index_if_missing();

SET @tbl='products', @idx='idx_products_category_norm',
    @ddl='ALTER TABLE products ADD INDEX idx_products_category_norm (category_norm)';
CALL add_index_if_missing();

SET @tbl='products', @idx='idx_products_catnorm_views',
    @ddl='ALTER TABLE products ADD INDEX idx_products_catnorm_views (category_norm, monthly_views, rating, review_count, product_id)';
CALL add_index_if_missing();

SET @tbl='category', @idx='idx_category_norm',
    @ddl='ALTER TABLE category ADD INDEX idx_category_norm (category_norm)';
CALL add_index_if_missing();

ANALYZE TABLE region_climate, climate_category_map, activity_category_map, blog_item, snap_products, products, category;

/* ────────────────────────────────────────────────────────────────
   15) 게스트용 테이블 (Tokyo=1, Osaka=2) — 지역별 20개 (고정)
   ────────────────────────────────────────────────────────────────
   ⛔ 이미 생성된 guest_reco_climate / guest_reco_activity를 건드리지 않기 위해
      아래 Drop/Create/Alter 전부 주석 처리함. 필요 시 확인용 SELECT만 별도 실행.
--------------------------------------------------------------------
SET @GUEST_LIMIT := 20;

-- DROP TABLE IF EXISTS guest_reco_climate;
-- CREATE TABLE guest_reco_climate AS
-- WITH joined AS (...),
--      dedup  AS (...),
--      rerank AS (...)
-- SELECT ... FROM rerank WHERE region_rank <= @GUEST_LIMIT;
-- ALTER TABLE guest_reco_climate ...;

-- DROP TABLE IF EXISTS guest_reco_activity;
-- CREATE TABLE guest_reco_activity AS
-- WITH joined AS (...),
--      dedup  AS (...),
--      rerank AS (...)
-- SELECT ... FROM rerank WHERE region_rank <= @GUEST_LIMIT;
-- ALTER TABLE guest_reco_activity ...;

-- (선택) 확인용 집계:
-- SELECT region_id, COUNT(*) AS cnt_c FROM guest_reco_climate  GROUP BY region_id;
-- SELECT region_id, COUNT(*) AS cnt_a FROM guest_reco_activity GROUP BY region_id;
--------------------------------------------------------------------*/

/* ────────────────────────────────────────────────────────────────
   16) 확인 (읽기 전용 예시)
   ──────────────────────────────────────────────────────────────── */
SET @uid := 11;
SELECT COUNT(*) AS cnt_user_top20   FROM v_user_top20_products WHERE user_id=@uid;
SELECT * FROM v_country_activity_top20_products WHERE user_id=@uid;
SELECT * FROM v_country_climate_top20_products  WHERE user_id=@uid;
SELECT * FROM v_country_photo_top20_products    WHERE user_id=@uid;
