USE mysql;
SELECT host, user FROM user;

# localhost => 127.0.0.1 => DNS

CREATE USER 'mike7'@'localhost' -- 사용자 추가 / 위치  
IDENTIFIED BY 'mike1234';     --  비밀번호 지정 

CREATE USER 'mike8'@'%'
IDENTIFIED BY 'mike1234';

SET PASSWORD FOR 'mike7'@'localhost' = 'mike5678'; -- 비밀번호 변경 

DROP USER 'mike7'@'localhost';   -- 유저 제거

DROP USER 'mike8'@'%';

SHOW GRANTS FOR 'root'@'localhost';  -- 권한 확인 

SHOW GRANTS FOR 'mike7'@'localhost';

GRANT SELECT ON school.students TO 'mike7'@'localhost'; -- 권한 부여 

GRANT ALL ON school.* TO 'mike7'@'localhost'; -- 전체 권한 
