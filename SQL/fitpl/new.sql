USE fitpl;

-- ✅ guests.xlsx 기반 게스트 유저 삽입 (1~20)
INSERT INTO users
(user_id, email, name, interest_region_id_1, interest_region_id_2, interest_region_id_3,
 trip_start_date, trip_end_date, trip_region_id, indoor_outdoor,
 activity_tag_1, activity_tag_2, activity_tag_3, created_at, updated_at)
VALUES
(1, 'guest1@example.com', 'guest1', NULL, NULL, NULL, '2025-09-23', '2025-10-22', 1, 'both', 'city_tour', 'observation_deck', 'museum', '2025-10-28 12:00', '2025-10-28 12:00'),
(2, 'guest2@example.com', 'guest2', NULL, NULL, NULL, '2025-09-23', '2025-10-22', 2, 'both', 'theme_park', 'city_tour', 'market_night', '2025-10-28 12:00', '2025-10-28 12:00'),
(3, 'guest3@example.com', 'guest3', NULL, NULL, NULL, '2025-09-23', '2025-10-22', 3, 'both', 'city_tour', 'market_night', 'observation_deck', '2025-10-28 12:00', '2025-10-28 12:00'),
(4, 'guest4@example.com', 'guest4', NULL, NULL, NULL, '2025-09-23', '2025-10-22', 4, 'both', 'observation_deck', 'zoo', 'city_tour', '2025-10-28 12:00', '2025-10-28 12:00'),
(5, 'guest5@example.com', 'guest5', NULL, NULL, NULL, '2025-09-23', '2025-10-22', 5, 'both', 'museum', 'city_tour', 'observation_deck', '2025-10-28 12:00', '2025-10-28 12:00'),
(6, 'guest6@example.com', 'guest6', NULL, NULL, NULL, '2025-09-23', '2025-10-22', 6, 'both', 'city_tour', 'museum', 'hiking', '2025-10-28 12:00', '2025-10-28 12:00'),
(7, 'guest7@example.com', 'guest7', NULL, NULL, NULL, '2025-09-23', '2025-10-22', 7, 'both', 'temple_shrine', 'market_night', 'city_tour', '2025-10-28 12:00', '2025-10-28 12:00'),
(8, 'guest8@example.com', 'guest8', NULL, NULL, NULL, '2025-09-23', '2025-10-22', 8, 'both', 'market_night', 'city_tour', 'temple_shrine', '2025-10-28 12:00', '2025-10-28 12:00'),
(9, 'guest9@example.com', 'guest9', NULL, NULL, NULL, '2025-09-23', '2025-10-22', 9, 'both', 'city_tour', 'beach', 'museum', '2025-10-28 12:00', '2025-10-28 12:00'),
(10, 'guest10@example.com', 'guest10', NULL, NULL, NULL, '2025-09-23', '2025-10-22', 10, 'both', 'city_tour', 'museum', 'cathedral_church', '2025-10-28 12:00', '2025-10-28 12:00'),
(11, 'guest11@example.com', 'guest11', NULL, NULL, NULL, '2025-09-23', '2025-10-22', 11, 'both', 'city_tour', 'cathedral_church', 'market_night', '2025-10-28 12:00', '2025-10-28 12:00'),
(12, 'guest12@example.com', 'guest12', NULL, NULL, NULL, '2025-09-23', '2025-10-22', 12, 'both', 'city_tour', 'temple_shrine', 'museum', '2025-10-28 12:00', '2025-10-28 12:00'),
(13, 'guest13@example.com', 'guest13', NULL, NULL, NULL, '2025-09-23', '2025-10-22', 13, 'both', 'theme_park', 'observation_deck', 'city_tour', '2025-10-28 12:00', '2025-10-28 12:00'),
(14, 'guest14@example.com', 'guest14', NULL, NULL, NULL, '2025-09-23', '2025-10-22', 14, 'both', 'city_tour', 'cathedral_church', 'observation_deck', '2025-10-28 12:00', '2025-10-28 12:00'),
(15, 'guest15@example.com', 'guest15', NULL, NULL, NULL, '2025-09-23', '2025-10-22', 15, 'both', 'city_tour', 'beach', 'temple_shrine', '2025-10-28 12:00', '2025-10-28 12:00'),
(16, 'guest16@example.com', 'guest16', NULL, NULL, NULL, '2025-09-23', '2025-10-22', 16, 'both', 'outlet_mall', 'aquarium', 'temple_shrine', '2025-10-28 12:00', '2025-10-28 12:00'),
(17, 'guest17@example.com', 'guest17', NULL, NULL, NULL, '2025-09-23', '2025-10-22', 17, 'both', 'beach', 'city_tour', 'outlet_mall', '2025-10-28 12:00', '2025-10-28 12:00'),
(18, 'guest18@example.com', 'guest18', NULL, NULL, NULL, '2025-09-23', '2025-10-22', 18, 'both', 'city_tour', 'beach', 'national_park', '2025-10-28 12:00', '2025-10-28 12:00'),
(19, 'guest19@example.com', 'guest19', NULL, NULL, NULL, '2025-09-23', '2025-10-22', 19, 'both', 'city_tour', 'theme_park', 'zoo', '2025-10-28 12:00', '2025-10-28 12:00'),
(20, 'guest20@example.com', 'guest20', NULL, NULL, NULL, '2025-09-23', '2025-10-22', 20, 'both', 'city_tour', 'beach', 'city_tour', '2025-10-28 12:00', '2025-10-28 12:00');


SELECT * FROM users;

CREATE TABLE IF NOT EXISTS product_ranking (
  run_id VARCHAR(32) NOT NULL,
  rank_date DATE NOT NULL,
  rank_pos INT NOT NULL,
  score DECIMAL(9,6) NOT NULL,
  
  -- products 컬럼 동일 구조 (user_id, base_score 제외)
  product_id BIGINT NOT NULL,
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
  product_name VARCHAR(128),
  product_name_detail VARCHAR(255),
  product_url VARCHAR(255),
  rating DOUBLE,
  review_count INT,
  sales INT,
  season VARCHAR(255),
  style_tag VARCHAR(255),
  category VARCHAR(255),

  PRIMARY KEY (run_id, product_id),
  KEY idx_rank (rank_pos),
  KEY idx_date_rank (rank_date, rank_pos)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SELECT * FROM product_ranking;

LOAD DATA LOCAL INFILE 'C:\\Users\\user\\python_basic\\TP2\\tables2\\product_ranking_top100_20251028.csv'
INTO TABLE product_ranking
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@product_id, @product_name, @sales, @review_count, @rating, @discount_rate, @price, @monthly_views, @score, @rank_pos)
SET
  run_id        = '20251028',
  rank_date     = CURDATE(),
  product_id    = NULLIF(@product_id,''),
  product_name  = NULLIF(@product_name,''),
  sales         = NULLIF(@sales,''),
  review_count  = NULLIF(@review_count,''),
  rating        = NULLIF(@rating,''),
  discount_rate = NULLIF(@discount_rate,''),
  price         = NULLIF(@price,''),
  monthly_views = NULLIF(@monthly_views,''),
  score         = NULLIF(@score,''),
  rank_pos      = NULLIF(@rank_pos,'');

SELECT * FROM product_ranking;

SET run_id = '20251028',
    rank_date = CURDATE();
    
-- 2) products로부터 나머지 컬럼 일괄 채우기
UPDATE product_ranking pr
JOIN products p ON p.product_id = pr.product_id
SET pr.brand              = p.brand,
    pr.main_category      = p.main_category,
    pr.color              = p.color,
    pr.gender_en          = p.gender_en,
    pr.img_url            = p.img_url,
    pr.material           = p.material,
    pr.product_serial     = p.product_serial,
    pr.product_name       = p.product_name,        -- CSV와 불일치 시 products 기준으로 덮어쓰기 원치 않으면 이 줄 제거
    pr.product_name_detail= p.product_name_detail,
    pr.product_url        = p.product_url,
    pr.rating             = COALESCE(pr.rating, p.rating),
    pr.review_count       = COALESCE(pr.review_count, p.review_count),
    pr.sales              = COALESCE(pr.sales, p.sales),
    pr.season             = p.season,
    pr.style_tag          = p.style_tag,
    pr.category           = p.category,
    pr.price              = COALESCE(pr.price, p.price),
    pr.monthly_views      = COALESCE(pr.monthly_views, p.monthly_views)
WHERE pr.run_id = '20251028';

ALTER TABLE products
  MODIFY product_id VARCHAR(128) NOT NULL;


DELETE FROM product_ranking
WHERE run_id = '20251028';


-- 콜레이션 충돌 예방용으로 COLLATE를 양쪽에 명시
UPDATE product_ranking pr
JOIN products p
  ON p.product_serial COLLATE utf8mb4_unicode_ci
   = pr.product_id    COLLATE utf8mb4_unicode_ci
SET pr.brand               = p.brand,
    pr.main_category       = p.main_category,
    pr.color               = p.color,
    pr.gender_en           = p.gender_en,
    pr.img_url             = p.img_url,
    pr.material            = p.material,
    pr.product_serial      = p.product_serial,
    pr.product_name        = COALESCE(pr.product_name, p.product_name),
    pr.product_name_detail = p.product_name_detail,
    pr.product_url         = p.product_url,
    pr.rating              = COALESCE(pr.rating, p.rating),
    pr.review_count        = COALESCE(pr.review_count, p.review_count),
    pr.sales               = COALESCE(pr.sales, p.sales),
    pr.season              = p.season,
    pr.style_tag           = p.style_tag,
    pr.category            = p.category,
    pr.price               = COALESCE(pr.price, p.price),
    pr.monthly_views       = COALESCE(pr.monthly_views, p.monthly_views)
WHERE pr.run_id = '20251028';


UPDATE product_ranking pr
JOIN products p
  ON p.product_serial COLLATE utf8mb4_unicode_ci = pr.product_id COLLATE utf8mb4_unicode_ci
SET pr.product_id = CAST(
        REGEXP_SUBSTR(p.product_url, '[0-9]+$') AS UNSIGNED
    )
WHERE pr.run_id = '20251028'
  AND p.product_url IS NOT NULL;

