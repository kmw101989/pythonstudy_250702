USE fitpl;

DROP TABLE IF EXISTS guest_reco_climate;
CREATE TABLE guest_reco_climate (
  user_id INT,
  product_id BIGINT,
  brand VARCHAR(255),
  main_category VARCHAR(255),
  color TEXT,
  discount_rate DOUBLE,
  gender_en VARCHAR(255),
  img_url VARCHAR(255),
  material TEXT,
  monthly_views INT,
  price INT,
  product_serial VARCHAR(128),
  product_name VARCHAR(255),
  product_name_detail VARCHAR(255),
  product_url VARCHAR(255),
  rating DOUBLE,
  review_count INT,
  sales INT,
  season VARCHAR(255),
  style_tag VARCHAR(255),
  category VARCHAR(255),
  base_score DOUBLE DEFAULT 0
);

DROP TABLE IF EXISTS guest_reco_activity;
CREATE TABLE guest_reco_activity (
  user_id INT,
  product_id BIGINT,
  brand VARCHAR(255),
  main_category VARCHAR(255),
  color TEXT,
  discount_rate DOUBLE,
  gender_en VARCHAR(255),
  img_url VARCHAR(255),
  material TEXT,
  monthly_views INT,
  price INT,
  product_serial VARCHAR(128),
  product_name VARCHAR(255),
  product_name_detail VARCHAR(255),
  product_url VARCHAR(255),
  rating DOUBLE,
  review_count INT,
  sales INT,
  season VARCHAR(255),
  style_tag VARCHAR(255),
  category VARCHAR(255),
  base_score DOUBLE DEFAULT 0
);


/* --------------------------------- */
INSERT INTO guest_reco_climate (
  user_id, product_id, brand, main_category, color, discount_rate, gender_en,
  img_url, material, monthly_views, price, product_serial,
  product_name, product_name_detail, product_url, rating, review_count,
  sales, season, style_tag, category, base_score
)
SELECT
  NULL AS user_id,
  p.product_id, p.brand, p.main_category, p.color, p.discount_rate, p.gender_en,
  p.img_url, p.material, p.monthly_views, p.price, p.product_serial,
  p.product_name, p.product_name_detail, p.product_url, p.rating, p.review_count,
  p.sales, p.season, p.style_tag, p.category, p.base_score
FROM products p
JOIN (
  SELECT DISTINCT product_id
  FROM (
    SELECT v.product_id, v.region_name,
           ROW_NUMBER() OVER (
             PARTITION BY v.region_name
             ORDER BY v.base_score DESC, v.product_id
           ) AS rn
    FROM v_user_top20_products v
    WHERE v.source = 'climate'
      AND v.region_name COLLATE utf8mb4_unicode_ci IN ('도쿄','오사카')
  ) x
  WHERE x.rn <= 10
  LIMIT 20
) d ON d.product_id = p.product_id;


-- 선택: 한 세션에서 전역으로도 맞출 수 있음
-- SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
-- (선택) 세션 정렬 통일: SET collation_connection = 'utf8mb4_unicode_ci';

-- (선택) 세션 기본도 맞춰두면 좋습니다
SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;
SET collation_connection = 'utf8mb4_0900_ai_ci';

INSERT INTO guest_reco_climate (
  user_id, product_id, brand, main_category, color, discount_rate, gender_en,
  img_url, material, monthly_views, price, product_serial,
  product_name, product_name_detail, product_url, rating, review_count,
  sales, season, style_tag, category, base_score
)
SELECT
  NULL,
  p.product_id, p.brand, p.main_category, p.color, p.discount_rate, p.gender_en,
  p.img_url, p.material, p.monthly_views, p.price, p.product_serial,
  p.product_name, p.product_name_detail, p.product_url, p.rating, p.review_count,
  p.sales, p.season, p.style_tag, p.category, p.base_score
FROM products p
JOIN (
  SELECT DISTINCT product_id
  FROM (
    SELECT v.product_id,
           ROW_NUMBER() OVER (
             PARTITION BY v.region_name
             ORDER BY v.base_score DESC, v.product_id
           ) AS rn
    FROM v_user_top20_products v
    WHERE v.source      COLLATE utf8mb4_0900_ai_ci = 'climate' COLLATE utf8mb4_0900_ai_ci
      AND v.region_name COLLATE utf8mb4_0900_ai_ci IN (
            '도쿄'   COLLATE utf8mb4_0900_ai_ci,
            '오사카' COLLATE utf8mb4_0900_ai_ci
          )
  ) x
  WHERE x.rn <= 10
  LIMIT 20
) d ON d.product_id = p.product_id;


SHOW columns FROM v_country_climate_top20_products;