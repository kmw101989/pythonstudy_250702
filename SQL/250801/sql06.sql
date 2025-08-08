CREATE DATABASE IF NOT EXISTS interpark;
CREATE TABLE IF NOT EXISTS performances(
	id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(100),
    date_range VARCHAR(100),
    place VARCHAR(100)
);

select * FROM performances ;
desc performances ;

