-- CREATE DATABASE Dave;

-- CREATE TABLE Mytable (
--     id INT UNSIGNED NOT NULL AUTO_INCREMENT,
--     name VARCHAR(50)  NOT NULL,
--     modelnumber VARCHAR(15) NOT NULL,
--     series VARCHAR(30) NOT NULL,
--     PRIMARY KEY(id)
-- );

-- DROP TABLE IF EXISTS Mytable;
-- DESC mytable ;
-- ALTER TABLE mytable MODIFY COLUMN name VARCHAR(20) NOT NULL;
-- ALTER TABLE Mytable MODIFY COLUMN model_number VARCHAR(10) NOT NULL;
-- ALTER TABLE Mytable CHANGE COLUMN series model_type VARCHAR(10) NOT NULL; 

-- DROP TABLE model_info ;
-- CREATE TABLE model_info (
-- 	id INT UNSIGNED NOT NULL AUTO_INCREMENT,
--     name VARCHAR(20) NOT NULL ,
--     model_num VARCHAR(10) NOT NULL, 
--     model_type varchar(10) NOT NULL,
--     PRIMARY KEY (id)
-- );