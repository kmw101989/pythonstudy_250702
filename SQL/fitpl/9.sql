CREATE database fitpl ;

SELECT * FROM users;

-- 데모 유저 레코드 upsert (MySQL 8.0 가정)
START TRANSACTION;

-- 중복 방지용 유니크 키가 email에 없다면, 먼저 추가(한 번만 실행)
-- ALTER TABLE users ADD UNIQUE KEY uq_users_email (email);

INSERT INTO users
  (user_id, email, name,
   interest_region_id_1, interest_region_id_2, interest_region_id_3,
   trip_start_date, trip_end_date, trip_region_id,
   indoor_outdoor, activity_tag_1, activity_tag_2, activity_tag_3,
   created_at, updated_at)
VALUES
  (1               ,          -- AUTO_INCREMENT 컬럼이면 NULL
   'demo@fitpl.local',            -- 데모 이메일(유니크)
   '데모유저',                     -- 표시 이름
   2, 3, 5,                       -- 관심 지역 3개(예시)
   DATE '2025-11-10',             -- 여행 시작일(예시)
   DATE '2025-11-15',             -- 여행 종료일(예시)
   5,                             -- 여행 대상 region_id (예: 5)
   'indoor',                       -- indoor_outdoor: 'indoor' | 'outdoor' | 'mixed' 중 하나
   'city-tour', 'food', 'shopping', -- 활동 태그 3개(예시)
   CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON DUPLICATE KEY UPDATE
   name                = VALUES(name),
   interest_region_id_1= VALUES(interest_region_id_1),
   interest_region_id_2= VALUES(interest_region_id_2),
   interest_region_id_3= VALUES(interest_region_id_3),
   trip_start_date     = VALUES(trip_start_date),
   trip_end_date       = VALUES(trip_end_date),
   trip_region_id      = VALUES(trip_region_id),
   indoor_outdoor      = VALUES(indoor_outdoor),
   activity_tag_1      = VALUES(activity_tag_1),
   activity_tag_2      = VALUES(activity_tag_2),
   activity_tag_3      = VALUES(activity_tag_3),
   updated_at          = CURRENT_TIMESTAMP;

COMMIT;

SELECT * FROM users;

SET SQL_SAFE_UPDATES = 0;

DELETE FROM users WHERE email = "demo@fitpl.local" ;

SET SQL_SAFE_UPDATES = 1;  -- (다시 켜고 싶으면)

SELECT * FROM region;
SELECT distinct(region_name_en)  FROM region;
SELECT * FROM product_ranking;

SHOW Columns FROM users;

SELECT * FROM region;

DELETE FROM users
WHERE email = "demo@fitpl.local";

SET SQL_SAFE_UPDATES = 1;
SELECT * FROM v_country_photo_top20_products
WHERE user_id = 1;