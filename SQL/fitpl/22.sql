-- ======================================
-- DEMO USER INSERT DDL (user_id 2001~2020)
-- 여행기간: 2025-09-22 ~ 2025-10-22
-- ======================================

INSERT INTO users (
  user_id, email, name,
  interest_region_id_1, interest_region_id_2, interest_region_id_3,
  trip_start_date, trip_end_date, trip_region_id, indoor_outdoor,
  activity_tag_1, activity_tag_2, activity_tag_3,
  created_at, updated_at
) VALUES
(2001,'demo2001@example.com','Demo2001',7,11,NULL,'2025-10-02','2025-10-08',4,'indoor','restaurant','outlet_mall','gourmet','2025-10-25 16:14:15','2025-10-27 15:00:00'),
(2002,'demo2002@example.com','Demo2002',16,NULL,2,'2025-09-28','2025-10-06',13,'both','cycling','art','restaurant','2025-10-25 16:14:15','2025-10-27 15:00:00'),
(2003,'demo2003@example.com','Demo2003',14,9,3,'2025-09-27','2025-10-04',6,'outdoor','museum','surfing','restaurant','2025-10-25 16:14:15','2025-10-27 15:00:00'),
(2004,'demo2004@example.com','Demo2004',10,20,15,'2025-09-22','2025-09-28',8,'outdoor','art','onsen','gourmet','2025-10-25 16:14:15','2025-10-27 15:00:00'),
(2005,'demo2005@example.com','Demo2005',5,19,8,'2025-09-30','2025-10-07',15,'indoor','diving','art','gourmet','2025-10-25 16:14:15','2025-10-27 15:00:00'),
(2006,'demo2006@example.com','Demo2006',NULL,7,10,'2025-09-25','2025-09-30',12,'both','onsen','gallery','restaurant','2025-10-25 16:14:15','2025-10-27 15:00:00'),
(2007,'demo2007@example.com','Demo2007',2,15,12,'2025-10-04','2025-10-11',2,'outdoor','surfing','cycling','walking_city','2025-10-25 16:14:15','2025-10-27 15:00:00'),
(2008,'demo2008@example.com','Demo2008',NULL,18,6,'2025-10-14','2025-10-21',9,'both','museum','themepark','gourmet','2025-10-25 16:14:15','2025-10-27 15:00:00'),
(2009,'demo2009@example.com','Demo2009',18,1,20,'2025-09-23','2025-09-29',17,'indoor','gourmet','cycling','surfing','2025-10-25 16:14:15','2025-10-27 15:00:00'),
(2010,'demo2010@example.com','Demo2010',3,13,NULL,'2025-10-01','2025-10-08',5,'both','citytour','museum','onsen','2025-10-25 16:14:15','2025-10-27 15:00:00'),
(2011,'demo2011@example.com','Demo2011',19,16,NULL,'2025-09-26','2025-10-03',14,'indoor','art','gourmet','surfing','2025-10-25 16:14:15','2025-10-27 15:00:00'),
(2012,'demo2012@example.com','Demo2012',8,11,NULL,'2025-10-10','2025-10-18',11,'both','cycling','walking_city','museum','2025-10-25 16:14:15','2025-10-27 15:00:00'),
(2013,'demo2013@example.com','Demo2013',20,6,9,'2025-10-06','2025-10-12',18,'outdoor','theater','citytour','surfing','2025-10-25 16:14:15','2025-10-27 15:00:00'),
(2014,'demo2014@example.com','Demo2014',11,2,NULL,'2025-09-22','2025-09-30',1,'both','shopping','surfing','onsen','2025-10-25 16:14:15','2025-10-27 15:00:00'),
(2015,'demo2015@example.com','Demo2015',3,NULL,5,'2025-10-03','2025-10-10',10,'indoor','museum','gourmet','outlet_mall','2025-10-25 16:14:15','2025-10-27 15:00:00'),
(2016,'demo2016@example.com','Demo2016',NULL,14,19,'2025-10-02','2025-10-09',7,'outdoor','surfing','shopping','art','2025-10-25 16:14:15','2025-10-27 15:00:00'),
(2017,'demo2017@example.com','Demo2017',8,13,4,'2025-09-30','2025-10-06',16,'both','gourmet','surfing','cycling','2025-10-25 16:14:15','2025-10-27 15:00:00'),
(2018,'demo2018@example.com','Demo2018',6,9,NULL,'2025-09-25','2025-10-02',19,'indoor','restaurant','art','surfing','2025-10-25 16:14:15','2025-10-27 15:00:00'),
(2019,'demo2019@example.com','Demo2019',NULL,5,2,'2025-10-08','2025-10-15',3,'both','surfing','onsen','restaurant','2025-10-25 16:14:15','2025-10-27 15:00:00'),
(2020,'demo2020@example.com','Demo2020',12,NULL,1,'2025-10-12','2025-10-19',20,'outdoor','museum','citytour','gourmet','2025-10-25 16:14:15','2025-10-27 15:00:00');


select * FROM snap_posts;
SHOW COLUMNS FROM products;

USE fitpl;

ALTER TABLE products
CHANGE COLUMN product_id product_serial VARCHAR(128) NULL;

ALTER TABLE category
MODIFY COLUMN category_id INT FIRST,
MODIFY COLUMN main_category VARCHAR(255) AFTER category_id,
MODIFY COLUMN category VARCHAR(255) AFTER main_category;

ALTER TABLE activity
MODIFY COLUMN region_id INT FIRST,
MODIFY COLUMN region_kor VARCHAR(255) AFTER region_id,
MODIFY COLUMN region_en VARCHAR(255) AFTER region_kor,
MODIFY COLUMN poi_name VARCHAR(255) AFTER region_en,
MODIFY COLUMN category VARCHAR(255) AFTER poi_name,
MODIFY COLUMN rating DOUBLE AFTER category,
MODIFY COLUMN review_count INT AFTER rating,
MODIFY COLUMN activity_tag VARCHAR(255) AFTER review_count,
MODIFY COLUMN osm_tag VARCHAR(255) AFTER activity_tag,
MODIFY COLUMN io_type VARCHAR(255) AFTER osm_tag,
MODIFY COLUMN updated_at DATE AFTER io_type;

ALTER TABLE blog_item
MODIFY COLUMN region_id INT FIRST,
MODIFY COLUMN region VARCHAR(255) AFTER region_id,
MODIFY COLUMN month DATE AFTER region,
MODIFY COLUMN item_norm VARCHAR(255) AFTER month,
MODIFY COLUMN matched_category VARCHAR(255) AFTER item_norm,
MODIFY COLUMN category_id INT AFTER matched_category,
MODIFY COLUMN count_in_posts INT AFTER category_id,
MODIFY COLUMN month_inferred INT AFTER count_in_posts;

ALTER TABLE products
ADD COLUMN product_id BIGINT NULL FIRST;

UPDATE products
SET product_id = CAST(REGEXP_SUBSTR(product_url, '[0-9]+$') AS UNSIGNED)
WHERE product_url REGEXP '[0-9]+$';

SET SQL_SAFE_UPDATES = 0;


