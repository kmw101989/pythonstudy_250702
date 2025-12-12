CREATE OR REPLACE VIEW v_user_trip_key AS
SELECT
  u.user_id,
  u.trip_region_id AS region_id,
  DATE_FORMAT(u.trip_start_date, '%Y-%m') AS month
FROM users u;


CREATE OR REPLACE VIEW v_user_trip_key AS
SELECT
  u.user_id,
  u.trip_region_id AS region_id,
  DATE_FORMAT(u.trip_start_date, '%Y-%m') AS month
FROM users u;


CREATE OR REPLACE VIEW v_user_climate_cat AS
SELECT
  utk.user_id,
  ccm.category_id,
  ccm.weight AS climate_cat_w
FROM v_user_trip_key utk
JOIN region_climate rc
  ON rc.region_id = utk.region_id
 AND rc.month     = utk.month
JOIN climate_category_map ccm
  ON ccm.climate_bucket = rc.climate_bucket;


CREATE OR REPLACE VIEW v_region_content_cat AS
SELECT
  x.region_id,
  x.month,
  x.category_id,
  COALESCE(b.blog_score, 0) AS blog_score,
  COALESCE(s.snap_score, 0) AS snap_score
FROM (
  SELECT region_id, month, category_id FROM blog_item
  UNION
  SELECT region_id, month, category_id FROM snap_category_stats
) x
LEFT JOIN blog_item b
  ON b.region_id=x.region_id AND b.month=x.month AND b.category_id=x.category_id
LEFT JOIN snap_category_stats s
  ON s.region_id=x.region_id AND s.month=x.month AND s.category_id=x.category_id;
