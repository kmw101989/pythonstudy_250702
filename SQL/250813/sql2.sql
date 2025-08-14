
SELECT 
	title, LENGTH(title) title_length
FROM film LIMIT 10 ;

SELECT 
	title, 
    LOWER(title) as lowercased_title,
    LENGTH(LOWER(UPPER(title))) as special_title,
    UPPER(title) as uppercased_title,
    LENGTH(title) as title_length
FROM film LIMIT 10 ;

SELECT * FROM actor ;

SELECT 
	first_name ,
    last_name,
    CONCAT(first_name," ", last_name) as full_name
FROM actor limit 10 ;

SELECT
	description ,
    SUBSTRING(description, 1 , 10) as sub
FROM film LIMIT 10;


# film 테이블에서 영화 제목이 15자 이상인 영화 출력 
SELECT 
	title,
    length(title) as length
from film
where length(title) >= 15
order by length desc;


# actor 테이블에서 첫번째 이름이 john인 배우들의 전체 이름을 대문자로 찾아서 출력 
SELECT 
	UPPER(CONCAT(first_name," ",last_name)) as full_name 
FROM actor 
WHERE lower(first_name) = "john";

SELECT * FROM actor
WHERE first_name = "john";

# film 테이블에서 description 의 3번째 글자부터 6글자가 "action" 인 영화의 제목 찾아서 출력 

SELECT
    title,
    description
FROM film
WHERE SUBSTRING(description, 3,6) = "Action" ;

SELECT NOW();
SELECT CURDATE();
SELECT CURTIME();

SELECT * FROM rental;
SELECT 
	rental_date,
    DATE_ADD(rental_date, INTERVAL 7 DAY)
FROM rental;


SELECT 
	rental_date,
    DATE_sub(rental_date, INTERVAL 7 SECOND)
FROM rental;

SELECT * FROM payment LIMIT 5 ;

SELECT 
	payment_date,
    EXTRACT(YEAR FROM payment_date)
FROM payment;

# 구제적으로 특정 년도에 해당되는 값만 추출해서 찾아오고자 할 때 유용함 
SELECT 
	payment_date 
FROM payment
WHERE EXTRACT(YEAR FROM payment_date) = 2006;

SELECT 
	payment_date
FROM payment
WHERE EXTRACT(DAY FROM payment_date) = 27;

#렌탈되고 있는 각 월 마다의 인기 지표 
SELECT 
	COUNT(*),
    EXTRACT(MONTH FROM payment_date) as paymonth
FROM payment
GROUP BY paymonth
ORDER BY paymonth desc;

SELECT 
	COUNT(*),
    YEAR(payment_date) as payyear,
	MONTH(payment_date) as paymonth,
    DAY(payment_date) as payday
FROM payment
GROUP BY payyear, paymonth, payday;

SELECT 
	dayofweek(payment_date) as payment_dayofweek,
    count(*)
FROM payment
group by payment_dayofweek ;

SELECT 
	-- DATE_FORMAT(payment_date, '%W') as payment_dayname,
    DATE_FORMAT(payment_date, '%a') as payment_dayname,
    COUNT(*) as total_count
FROM payment
GROUP BY payment_dayname;

SELECT 
	CASE DAYOFWEEK(payment_date)
		WHEN 1 THEN '일요일'
        WHEN 2 THEN '월요일'
        WHEN 3 THEN '화요일'
        WHEN 4 THEN '수요일'
        WHEN 5 THEN '목요일'
        WHEN 6 THEN '금요일'
        WHEN 7 THEN '토요일'
	END AS payment_dayname,
    COUNT(*) AS total_count
FROM payment
GROUP BY payment_dayname
ORDER BY total_count DESC;

SELECT 
	rental_date,
    return_date,
	TIMESTAMPDIFF(DAY, rental_date, return_date) AS rental_days
FROM rental
LIMIT 5;


Select 
	rental_id,
    rental_date,
    DATE_FORMAT(rental_date, "%Y-%M-%D") as formatted_date
from rental 
limit 5;

# rental 테이블에서 대여 시작 날짜 2006-01-01 이후인 모든 대여에 대해 예상 반납 날짜를 대여 날짜로부터 5일 뒤로 설정하여 설정
SELECT 
	DATE_ADD(rental_date, INTERVAL 5 DAY) as expected_date,
	rental_id
FROM rental
WHERE rental_date >= "2006-01-01"
-- WHERE YEAR(rental_date) >= 2006 
-- WHERE EXTRACT(YEAR FROM rental_date) >= 2006
 ;
 
 
Select 
	-amount,
    ABS(-amount) as abs_amount,
    CEIL(amount) as ceiling_amount,
    FLOOR(amount) as floor_amount,
    ROUND(amount,1)
FROM payment;


SELECT SQRT(5);

#payment 테이블에서 결제금액이(amount) 이 5 이하인 모든 결제에 대해 절대값을 계산하여 출력
SELECT 
	ABS(amount)
FROM payment
WHERE amount <= 5;

#film 테이블에서 영화 길이가 120분 이상인 모든 영화에 대해 영화 길이의 제곱근
SELECT 
	title,
	SQRT(length),
    length
FROM film 
WHERE length >= 120
ORDER by sqrt(length) desc ;

#payment 테이블에서 결제금액을 소수점 첫번째 자리에서 반올림하여 출력 
SELECT 
	amount,
	round(amount,1)
FROM payment;