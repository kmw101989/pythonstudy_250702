CREATE DATABASE uqlDB_v1 ;

CREATE TABLE userTbl (
	userID CHAR(8) NOT NULL PRIMARY KEY,
    name VARCHAR(10) UNIQUE NOT NULL,
    birthYear INT NOT NULL,
    addr CHAR(2) NOT NULL,
    mobile1 CHAR(3),
    mobile2 CHAR(8),
    height SMALLINT,
    mDate DATE
);


CREATE TABLE buyTbl (
	num INT AUTO_INCREMENT NOT NULL PRIMARY KEY,
    userID CHAR(8) NOT NULL,
    prodName CHAR(4),
    groupName CHAR(4),
    price INT NOT NULL,
    amount SMALLINT NOT NULL,
    FOREIGN KEY (userID) REFERENCES userTbl(userID)
);

DESC userTbl;

DESC buyTbl;

 SHOW INDEX FROM buyTbl;
 
 SHOW INDEX FROM userTbl;
 
 ALTER TABLE userTbl ADD CONSTRAINT TESTdate UNIQUE(mDATE);
 
 CREATE INDEX idx_birth ON userTbl(birthYear)