USE fitpl;

-- Recommended: avoid ONLY_FULL_GROUP_BY surprises
SET SESSION sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));

/* ===========================================================
DROP (in dependency order)
=========================================================== */
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

DROP VIEW IF EXISTS v_region_climate_bucket_mode_norm;
DROP VIEW IF EXISTS v_region_climate_buckets_norm;
DROP VIEW IF EXISTS v_region_climate_buckets;
DROP VIEW IF EXISTS v_region_climate_monthfix;

DROP VIEW IF EXISTS v_region_alias;
DROP VIEW IF EXISTS v_user_climate_cat;
DROP VIEW IF EXISTS v_user_trip_key;

/* ===========================================================
[1] USER TRIP KEY (fixed to user_id = 1001)
=========================================================== */
CREATE OR REPLACE VIEW v_user_trip_key AS
SELECT
  u.user_id,
  u.trip_region_id AS region_id,
  DATE_FORMAT(u.trip_start_date, '%Y-%m') AS month
FROM users u
WHERE u.user_id = 1001
  AND u.trip_region_id IS NOT NULL
  AND u.trip_start_date IS NOT NULL;

/* ===========================================================
[2] ACTIVITY WEIGHTS (tags → categories)
  - strong normalization: lower, trim, remove spaces/hyphen/underscore
  - English-only alias map
=========================================================== */
CREATE OR REPLACE VIEW v_users_activity_tags AS
SELECT user_id,
       REGEXP_REPLACE(REGEXP_REPLACE(LOWER(TRIM(activity_tag_1)),'\\s+',''), '[-_]', '') AS tag_norm
FROM users WHERE user_id=1001 AND activity_tag_1 IS NOT NULL AND TRIM(activity_tag_1) <> ''
UNION ALL
SELECT user_id,
       REGEXP_REPLACE(REGEXP_REPLACE(LOWER(TRIM(activity_tag_2)),'\\s+',''), '[-_]', '')
FROM users WHERE user_id=1001 AND activity_tag_2 IS NOT NULL AND TRIM(activity_tag_2) <> ''
UNION ALL
SELECT user_id,
       REGEXP_REPLACE(REGEXP_REPLACE(LOWER(TRIM(activity_tag_3)),'\\s+',''), '[-_]', '')
FROM users WHERE user_id=1001 AND activity_tag_3 IS NOT NULL AND TRIM(activity_tag_3) <> '';

CREATE OR REPLACE VIEW v_activity_map_norm AS
SELECT REGEXP_REPLACE(REGEXP_REPLACE(LOWER(TRIM(activity_tag)),'\\s+',''), '[-_]', '') AS tag_norm,
       category_id
FROM activity_category_map;

-- English canonical aliases → map common synonyms to canonical tag keys used in activity_category_map
CREATE OR REPLACE VIEW v_activity_alias_map AS
SELECT 'citytour'   AS tag_norm, 'citytour'   AS tag_origin
UNION ALL SELECT 'urban'      , 'citytour'
UNION ALL SELECT 'shopping'   , 'shopping'
UNION ALL SELECT 'food'       , 'food'
UNION ALL SELECT 'restaurant' , 'food'
UNION ALL SELECT 'gourmet'    , 'food'
UNION ALL SELECT 'surfing'    , 'water'
UNION ALL SELECT 'snorkeling' , 'water'
UNION ALL SELECT 'diving'     , 'water'
UNION ALL SELECT 'museum'     , 'culture'
UNION ALL SELECT 'art'        , 'culture'
UNION ALL SELECT 'hiking'     , 'nature'
UNION ALL SELECT 'trekking'   , 'nature'
UNION ALL SELECT 'walking'    , 'nature'
UNION ALL SELECT 'themepark'  , 'leisure'
UNION ALL SELECT 'amusement'  , 'leisure'
UNION ALL SELECT 'indoor'     , 'indoor'
UNION ALL SELECT 'outdoor'    , 'outdoor';

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
FROM (SELECT 1001 AS user_id) u CROSS JOIN category c;

/* ===========================================================
[3] REGION ALIAS (English first; no Korean literals)
=========================================================== */
CREATE OR REPLACE VIEW v_region_alias AS
SELECT region_id,
       LOWER(TRIM(region_name_en)) AS en_norm
FROM region
UNION ALL
-- optional manual aliases (add more as needed)
SELECT region_id, 'osaka' FROM region WHERE LOWER(TRIM(region_name_en))='osaka'
UNION ALL
SELECT region_id, 'tokyo' FROM region WHERE LOWER(TRIM(region_name_en))='tokyo'
UNION ALL
SELECT region_id, 'kaohsiung' FROM region WHERE LOWER(TRIM(region_name_en))='kaohsiung';

/* ===========================================================
[4] SNAP SIGNAL (region text → region_id, then aggregate)
=========================================================== */
CREATE OR REPLACE VIEW snap_category_stats AS
SELECT
  COALESCE(sp.region_id, ra.region_id) AS region_id,
  sp.category_id,
  LOG(COUNT(*) + 1) AS snap_score
FROM snap_products sp
LEFT JOIN v_region_alias ra
  ON LOWER(TRIM(sp.region)) LIKE CONCAT('%', ra.en_norm, '%')
WHERE sp.category_id IS NOT NULL
GROUP BY COALESCE(sp.region_id, ra.region_id), sp.category_id;

CREATE OR REPLACE VIEW v_snap_all AS
SELECT category_id, LOG(COUNT(*) + 1) AS snap_score_all
FROM snap_products
WHERE category_id IS NOT NULL
GROUP BY category_id;

/* ===========================================================
[5] BLOG SIGNAL (normalize region → aggregate)
=========================================================== */
CREATE OR REPLACE VIEW v_blog_item_norm AS
SELECT
  COALESCE(bi.region_id,
           (SELECT ra.region_id FROM v_region_alias ra
            WHERE LOWER(TRIM(bi.region)) LIKE CONCAT('%', ra.en_norm, '%')
            LIMIT 1)) AS region_id,
  bi.month,
  bi.category_id,
  bi.count_in_posts
FROM blog_item bi;

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

/* ===========================================================
[6] CLIMATE SIGNAL (build full stack + user climate cat)
=========================================================== */
CREATE OR REPLACE VIEW v_region_climate_monthfix AS
SELECT
  rc.region_id,
  CASE
    WHEN rc.month IS NULL THEN NULL
    WHEN rc.month REGEXP '^[0-9]{4}-[0-9]{2}$' THEN rc.month
    ELSE DATE_FORMAT(CAST(rc.month AS DATETIME), '%Y-%m')
  END AS month,
  rc.temperature_2m_max,
  rc.relative_humidity_2m_mean,
  rc.uv_index_max
FROM region_climate rc;

CREATE OR REPLACE VIEW v_region_climate_buckets AS
SELECT
  m.region_id,
  m.month,
  CASE
    WHEN m.temperature_2m_max >= 30 THEN
      CASE WHEN m.relative_humidity_2m_mean >= 70 OR m.uv_index_max >= 7
           THEN 'hot humid'
           ELSE 'hot'
      END
    WHEN m.temperature_2m_max BETWEEN 20 AND 29 THEN
      CASE WHEN m.relative_humidity_2m_mean >= 70
           THEN 'warm humid'
           ELSE 'warm'
      END
    WHEN m.temperature_2m_max BETWEEN 10 AND 19 THEN
      CASE WHEN m.relative_humidity_2m_mean >= 70
           THEN 'mild humid'
           ELSE 'mild'
      END
    ELSE
      CASE WHEN m.relative_humidity_2m_mean >= 70
           THEN 'cold humid'
           ELSE 'cold'
      END
  END AS bucket_norm
FROM v_region_climate_monthfix m
WHERE m.month IS NOT NULL;

CREATE OR REPLACE VIEW v_region_climate_buckets_norm AS
SELECT x.region_id, x.month, x.bucket_norm
FROM (
  SELECT
    region_id, month, bucket_norm,
    ROW_NUMBER() OVER (
      PARTITION BY region_id, month
      ORDER BY COUNT(*) DESC, bucket_norm
    ) AS rn
  FROM v_region_climate_buckets
  GROUP BY region_id, month, bucket_norm
) x
WHERE x.rn = 1;

CREATE OR REPLACE VIEW v_region_climate_bucket_mode_norm AS
SELECT y.region_id, y.bucket_norm
FROM (
  SELECT
    region_id, bucket_norm,
    ROW_NUMBER() OVER (
      PARTITION BY region_id
      ORDER BY COUNT(*) DESC, bucket_norm
    ) AS rn
  FROM v_region_climate_buckets
  GROUP BY region_id, bucket_norm
) y
WHERE y.rn = 1;

-- user-level climate weights for 1001 (month match → fallback to region mode)
CREATE OR REPLACE VIEW v_user_climate_cat AS
SELECT 
  utk.user_id,
  m1.category_id,
  AVG(m1.climate_cat_w) AS climate_cat_w
FROM v_user_trip_key utk
JOIN v_region_climate_buckets_norm rb
  ON rb.region_id = utk.region_id
 AND rb.month     = utk.month
JOIN climate_category_map m1
  ON m1.climate_bucket = rb.bucket_norm
GROUP BY utk.user_id, m1.category_id

UNION ALL

SELECT 
  utk.user_id,
  m2.category_id,
  AVG(m2.climate_cat_w) AS climate_cat_w
FROM v_user_trip_key utk
JOIN v_region_climate_bucket_mode_norm rbm
  ON rbm.region_id = utk.region_id
JOIN climate_category_map m2
  ON m2.climate_bucket = rbm.bucket_norm
WHERE NOT EXISTS (
  SELECT 1
  FROM v_region_climate_buckets_norm rb2
  WHERE rb2.region_id = utk.region_id
    AND rb2.month     = utk.month
)
GROUP BY utk.user_id, m2.category_id;

/* ===========================================================
[7] CONTENT MERGE for the user (1001)
=========================================================== */
CREATE OR REPLACE VIEW v_user_region_month_categories AS
SELECT utk.user_id, utk.region_id, utk.month, c.category_id
FROM v_user_trip_key utk
JOIN (
  SELECT DISTINCT category_id FROM activity_category_map
  UNION SELECT DISTINCT category_id FROM climate_category_map
  UNION SELECT DISTINCT category_id FROM v_blog_item_norm
  UNION SELECT DISTINCT category_id FROM snap_products
) c;

CREATE OR REPLACE VIEW v_region_content_cat AS
SELECT
  u.user_id, u.region_id, u.month, u.category_id,
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

/* ===========================================================
[8] FINAL SIGNAL & SCORE (activity + climate + content)
=========================================================== */
CREATE OR REPLACE VIEW v_user_category_signal AS
SELECT
  u.user_id, u.region_id, u.month, u.category_id,
  COALESCE(ac.activity_cat_w, afb.activity_cat_w_fb, 0) AS activity_cat_w,
  COALESCE(cc.climate_cat_w, 0) AS climate_cat_w,
  COALESCE(rc.blog_score, 0) AS blog_score,
  COALESCE(rc.snap_score, 0) AS snap_score
FROM v_user_region_month_categories u
LEFT JOIN v_user_activity_cat ac
  ON ac.user_id=u.user_id AND ac.category_id=u.category_id
LEFT JOIN v_user_activity_cat_fallback afb
  ON afb.user_id=u.user_id AND afb.category_id=u.category_id
LEFT JOIN v_user_climate_cat cc
  ON cc.user_id=u.user_id AND cc.category_id=u.category_id
LEFT JOIN v_region_content_cat rc
  ON rc.user_id=u.user_id AND rc.category_id=u.category_id;

CREATE OR REPLACE VIEW v_user_category_score AS
SELECT
  s.user_id, s.category_id,
  CASE
    WHEN (COALESCE(s.climate_cat_w,0)+COALESCE(s.activity_cat_w,0)+COALESCE(s.blog_score,0)+COALESCE(s.snap_score,0))=0
    THEN 0.05
    ELSE (0.90*s.climate_cat_w)+(0.10*s.activity_cat_w)+(0.0*s.blog_score)+(0.0*s.snap_score)
  END AS final_cat_score
FROM v_user_category_signal s;

/* ===========================================================
[9] PRODUCTS: normalize + candidate filtering (hot/warm -> exclude winter items)
=========================================================== */
CREATE OR REPLACE VIEW v_user_primary_bucket AS
SELECT utk.user_id,
       COALESCE(rb.bucket_norm, rbm.bucket_norm) AS bucket_norm
FROM v_user_trip_key utk
LEFT JOIN v_region_climate_buckets_norm rb
  ON rb.region_id=utk.region_id AND rb.month=utk.month
LEFT JOIN v_region_climate_bucket_mode_norm rbm
  ON rbm.region_id=utk.region_id;

CREATE OR REPLACE VIEW v_products_norm AS
SELECT product_name, product_url, category,
       REGEXP_REPLACE(REGEXP_REPLACE(LOWER(TRIM(category)),'\\s+',' '),'[-_/]',' ') AS category_norm
FROM products
WHERE product_url IS NOT NULL;

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
    AND (
      LOWER(p.category) REGEXP 'coat|jacket|padding|down|sweater|cardigan|hood|long sleeve|knit|pique|collar'
    )
  );

/* ===========================================================
[10] TOP-K RESULTS
=========================================================== */
CREATE OR REPLACE VIEW v_user_top5cat_4item AS
WITH ranked_cats AS (
  SELECT user_id, category_id, final_cat_score,
         ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY final_cat_score DESC) AS cat_rank
  FROM v_user_category_score
),
top_cats AS ( SELECT user_id, category_id FROM ranked_cats WHERE cat_rank <= 5 ),
ranked_products AS (
  SELECT upc.user_id, upc.category_id, upc.product_name, upc.product_url, upc.category, upc.base_score,
         ROW_NUMBER() OVER (PARTITION BY upc.user_id, upc.category_id ORDER BY upc.base_score DESC, upc.product_name) AS prod_rank
  FROM v_user_product_candidates upc
)
SELECT r.user_id, r.category_id, r.product_name, r.product_url, r.category, r.base_score
FROM ranked_products r
JOIN top_cats t ON r.user_id=t.user_id AND r.category_id=t.category_id
WHERE r.prod_rank <= 4;

CREATE OR REPLACE VIEW v_user_top20_products AS
SELECT user_id, product_name, category, product_url, base_score
FROM (
  SELECT upc.*, ROW_NUMBER() OVER (PARTITION BY upc.user_id ORDER BY upc.base_score DESC, upc.product_name) AS rn
  FROM v_user_product_candidates upc
) t WHERE t.rn <= 20;
