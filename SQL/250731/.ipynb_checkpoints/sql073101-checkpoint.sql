/*
현재 이 공간을 통해서 SQL 언어를 작성할 예정 
해당 공간에 한 줄씩 코드를 작성 -> 쿼리(문)
하나의 쿼리가 종료되었다는 것을 정의 -> ; 
*/

#1. db생성 : CREATE DATABASE dbname; 
#2. DB 목록확인 : SHOW DATABASES; 
#3. DB 접속 : USE dbname;
#4. Table생성 : CREATE TABLE mytable (
#	id INT PRIMARY KEY,
#    name VARCHAR(50) 
#);
#5. Data삽입 
#6. DB 삭제 : DROP DATABASE if EXISTS dbname; 

-- CREATE TABLE mytable (
-- 	id FLOAT, 
--     name VARCHAR(50),
--     PRIMARY KEY(id)
-- );

-- CREATE TABLE mytable (
-- 	id INT UNSIGNED, 
--     name VARCHAR(50),
--     PRIMARY KEY(id)
-- );

-- CREATE TABLE mytable (
-- 	id INT NOT NULL AUTO_INCREMENT, #자동으로 1씩 늘어남
--     name VARCHAR(50),
--     PRIMARY KEY(id)
-- );

-- CREATE TABLE mytable (
-- 	id INT NOT NULL AUTO_INCREMENT, 
--     name CHAR(50), #50개의 문자열 고정
--     city VARCHAR(50), #50개까지 가변형 
--     PRIMARY KEY(id)
-- );

-- CREATE TABLE mytable (
-- 	id INT NOT NULL AUTO_INCREMENT, 
--     name VARCHAR(50),
--     PRIMARY KEY(id, name) #하나의 레코드 안에 프라이머리 키 복수 가능 
-- );

-- CREATE TABLE mytable (
-- 	id INT NOT NULL AUTO_INCREMENT, 
--     name VARCHAR(50) NOT NULL,
--     modelnumber VARCHAR(15) NOT NULL,
--     series VARCHAR(30) NOT NULL,
--     PRIMARY KEY(id) 
-- );




