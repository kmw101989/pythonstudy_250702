SET SQL_SAFE_UPDATES = 0; 

START TRANSACTION ;

UPDATE customer 
SET first_name = "david" ; 
SELECT * FROM customer limit 1;


ROLLBACK ;