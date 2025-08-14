CREATE DATABASE ecommerce_v1;
USE ecommerce_v1;
DESC product;

SELECT *  FROM product;

CREATE DATABASE ecommerce_v2;
drop database ecomerce_v2;

USE ecommerce_v2;

CREATE TABLE teddyproducts (
	ID INT UNSIGNED NOT NULL AUTO_INCREMENT ,
    TITLE VARCHAR(200) NOT NULL,
	CATEGORY VARCHAR(20) NOT NULL,
    PRIMARY KEY(ID)
);
DESC teddyproducts;

SELECT * from teddyproducts;