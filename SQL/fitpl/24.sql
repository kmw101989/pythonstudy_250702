USE fitpl;
SET SQL_SAFE_UPDATES = 1;

UPDATE activity
SET region_id = 6
WHERE region_id IS NULL
  AND (
       LOWER(TRIM(region_kor)) = '타이페이'
    OR LOWER(TRIM(region_en))  = 'taipei'
  );

-- 확인
SELECT COUNT(*) AS remaining_nulls
FROM activity
WHERE region_id IS NULL
  AND (LOWER(TRIM(region_kor))='타이페이' OR LOWER(TRIM(region_en))='taipei');


SELECT * FROM activity 
WHERE region_id = 6;

USE fitpl;

-- 1) 타이베이인데 region_id가 비어있는 행이 남았는지
SELECT COUNT(*) AS taipei_nulls
FROM activity
WHERE region_id IS NULL
  AND (LOWER(TRIM(region_kor))='타이베이' OR LOWER(TRIM(region_en))='taipei');

-- 2) 타이베이인데 6이 아닌 다른 region_id가 들어간 건 없는지
SELECT region_id, COUNT(*) AS cnt
FROM activity
WHERE (LOWER(TRIM(region_kor))='타이베이' OR LOWER(TRIM(region_en))='taipei')
GROUP BY region_id;

-- 3) 전체적으로 region_id가 NULL인 행이 아직 남았는지
SELECT COUNT(*) AS remaining_nulls
FROM activity
WHERE region_id IS NULL;

-- 4) 샘플로 타이베이 10건 확인
SELECT region_id, region_kor, region_en, poi_name
FROM activity
WHERE (LOWER(TRIM(region_kor))='타이페이' OR LOWER(TRIM(region_en))='taipei')
LIMIT 10;

-- 5) (선택) region 테이블과의 정합성 체크
SELECT a.region_id, r.region_name_ko, r.region_name_en, COUNT(*) AS cnt
FROM activity a
LEFT JOIN region r ON r.region_id = a.region_id
GROUP BY a.region_id, r.region_name_ko, r.region_name_en
ORDER BY cnt DESC;

USE fitpl;
SET SQL_SAFE_UPDATES = 1;

UPDATE activity
SET region_en = 'Taipei'
WHERE LOWER(TRIM(region_en)) IN ('타이페이', 'taipei', 'tai pei');
