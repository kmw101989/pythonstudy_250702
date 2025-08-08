create database if not exists test01 ;

CREATE table test (
	id INT NOT NULL auto_increment,
    name VARCHAR(20) NOT NULL,
    email VARCHAR(50) NOT NULL,
    birthday VARCHAR(30) NOT NULL,
    signdate VARCHAR(30) NOT NULL,
    point int unsigned  null, 
    gender VARCHAR(10),
	primary key(id)
);

SELECT * FROM test;

INSERT INTO test (id,name,email,birthday,signdate,point,gender)
value(1,"kim","kim@naver.com","901010","250101",700,"male");

INSERT INTO test (name,email,birthday,signdate,point,gender)
value("lee","lee@google.com","950401","250310",1200,"female"),
("park","park@hotmail.com","890612","250712",200,"male"),
("choi","choi@google.com","011019","240926",2200,"female");

SELECT * FROM test WHERE point > 1000;
SELECT * FROM test WHERE email LIKE "%@google.com";