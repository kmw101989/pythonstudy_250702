SHOW tables;

SELECT * FROM payment limit 3;

SELECT 
	*
FROM customer 
LIMIT 3;

SELECT 	
	first_name,
	last_name
FROM customer 
WHERE customer_id IN (
	SELECT customer_id
    FROM payment
    WHERE amount >(SELECT AVG(amount) FROM payment) 
); 