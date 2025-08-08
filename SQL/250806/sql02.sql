#Netflix Data 분석 마케터
#특정 데이터 존재 = 사용자별 하루 시청 시간 
# A 사용자 10일 5시간 30분 시청
# B 사용자가 15일 3시간 시청
# ... 

#STP => Segment => Target => Positioning => Persona 
# 필요 정보 : ID,나이, 사용 빈도(등급 ex.1~3일마다 : 1급/ 4~7일 :2급 /7~14일:3급 /15~30일 :4급,31일~:5급),연속 사용 시간, 주요 시청 장르, 시청한 작품의 주요 배우 , 최근 사용날짜, 최근 시청 작풉 ID 
# 사용 빈도가 높은 사람을 대상으로 최근 시청작과 비슷한 장르, 배우의 작품 추천 

CREATE DATABASE netflix ;

-- CREATE TABLE netflix (
-- 	ID INT AUTO_INCREMENT PRIMARY KEY,
--     AGE INT NOT NULL,
--     PREQUENCY TINYINT NOT NULL,
--     CONTINUOUS INT NOT NULL,
--     GENRE VARCHAR(20) NOT NULL,
--     ACTOR VARCHAR(50) NOT NULL,
--     RECENT DATE NOT NULL,
--     RECENT_CONTENT_ID INT NOT NULL

-- );

CREATE TABLE users (
	user_id INT PRIMARY KEY,
    user_name VARCHAR(50)

);

INSERT INTO users (user_id, user_name)
VALUES (1,"Alice") ,(2,"David") , (3,"Cathy");

SELECT * FROM users;

CREATE TABLE watch_history(
	watch_id INT primary KEY,
    user_id INT,
    date_time DATE, 
    hours_watched DECIMAL(4,1),
    FOREIGN KEY(user_id) REFERENCES users(user_id)
);

DROP TABLE netflix;


DESC watch_history ; 

INSERT INTO watch_history (watch_id , user_id , date_time, hours_watched)
VALUES 
(101, 1 , "2025-07-11", 5.5),
(102, 1 , "2025-07-15", 3.0),
(103, 2 , "2025-07-20", 7.0),
(104, 3 , "2025-06-30", 2.5),
(105, 2 , "2025-07-05", 4.0),
(106, 3 , "2025-07-12", 6.5),
(107, 1 , "2025-06-25", 1.0),
(108, 2 , "2025-07-30", 2.0);

select * from watch_history;

# 특정 사용자의 영상 시청시간 기준, 내림차순 
SELECT u.user_id, u.user_name , SUM(w.hours_watched) AS total_hours
FROM users u 
JOIN watch_history w ON u.user_id = w.user_id 
WHERE w.date_time >= CURDATE() - INTERVAL 1 MONTH
group by u.user_id, u.user_name
ORDER BY total_hours DESC
LIMIT 10;

