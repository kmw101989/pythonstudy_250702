create database if not exists membership ;
desc members ;
CREATE table members(
	id INT NOT NULL auto_increment primary key,
    name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    birthday_date date ,# '0000-00-00' ,
    signup_date DATETIME default current_timestamp, # 'yyyy-mm-dd hh:mm:ss ,
    point DECIMAL(10,2), 
    gender ENUM('남', '여') NOT NULL
);

SELECT * FROM members;

INSERT INTO members (name,email,birthday_date,point ,gender)
value("kim","kim@naver.com","1901-01-10",700,"남");

INSERT INTO members (name,email,birthday_date,point,gender)
values
("lee","lee@google.com","1990-01-01",1200.5,"여"),
("park","park@hotmail.com","1989-06-12",200,"남"),
("choi","choi@google.com","2001-10-19",2200.5,"남");

SELECT * FROM members WHERE point > 1000;
SELECT * FROM members WHERE email LIKE "%@google.com";
SELECT name ,email FROM members 
WHERE email LIKE "%@google.com";

SELECT name, birthday_date FROM members
ORDER BY birthday_date DESC; 