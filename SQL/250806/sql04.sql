use sakila ;
SELECT count(*) FROM film ;
select * from film
limit 10;

SHOW tables ;

SELECT DISTINCT rating FROM film;

#film table 에 존재하는 영화 년도 
SELECT DISTINCT release_year FROM film;

SELECT * FROM rental
limit 10;

#rental 테이블에서 인벤토리 아이디 값이 367인 값만 출력 
SELECT * FROM rental
where inventory_id = 367;

#고객 관련 데이터를 찾아보고 싶다 
SELECT * FROM customer ;
DESC customer;
SELECT count(*) FROM customer;