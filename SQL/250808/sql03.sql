CREATE DATABASE IF NOT EXISTS index_demo_v1 ; 
USE index_demo_v1;

CREATE TABLE customers(
	id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    age INT ,
    city VARCHAR(100)
) ENGINE=InnoDB; 

#클러스터형 인덱스, 보조형 인덱스가 다른 필드값에 있는 요소들을 사용할때보다 연산처리 속도가 빠르다는 것을 확인 
#우선 MySQL 안에 설정 및 설치되어있는 스토리지 엔진 
#ENGINE = InnoDB
# MySQL 8.0 이상 버전부터는 기본값으로 설정되어있음
# MyISAM 버전 

SHOW VARIABLES LIKE 'default_storage_engine';

-- INSERT INTO customers (name ,email,age,city) VAULES() ; 

INSERT INTO customers (name ,email,age,city) 
SELECT 
	CONCAT('USER', LPAD(FLOOR(RAND() * 100000),5,'0')) ,
    CONCAT('user', LPAD(FLOOR(RAND() * 100000),5,'0'), '@test.com'),
    FLOOR(18+(RAND() * 50)), 
    ELT(FLOOR(RAND() * 5),'Seoul' , 'Busan','Incheon','Daegu','Daejeon')
FROM information_schema.tables LIMIT 1000;

#information_schema .tables 
#현재 내가 사용하고 있는 mySQL 워크벤치 안에 있는 전체 테이블 정보 값을 가지고 있는 시스템 테이블 = 메타테이블 

SELECT COUNT(*) FROM customers;
SELECT * FROM customers;

SHOW INDEX FROM customers;
desc customers;

CREATE INDEX idx_email ON customers(email);
SELECT * FROM customers ; 
EXPLAIN SELECT * FROM customers ; #ALL 372 

EXPLAIN SELECT * FROM customers WHERE id = 372; #const 1 
EXPLAIN SELECT * FROM customers WHERE email = 'user95976@test.com'; #Const 1
EXPLAIN SELECT * FROM customers WHERE city = 'Busan'; #All 394