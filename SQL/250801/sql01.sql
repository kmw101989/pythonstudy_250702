-- USE school;
desc students;
SELECT * FROM students ; 

UPDATE students SET age = "15세" WHERE id = 1; 

ALTER TABLE students MODIFY COLUMN age VARCHAR(20) ;

UPDATE students SET age = "15세" WHERE id = 2;
UPDATE students SET age = "17세" WHERE id = 3; 
UPDATE students SET age = "16세" WHERE id = 4;  
UPDATE students SET age = "15세" WHERE id = 5; 

SELECT name FROM students; 
SELECT name , age FROM students ;
SELECT * FROM students WHERE age = "16세";
SELECT * FROM students WHERE age != "16세";
SELECT * FROM students WHERE age <> "16세";
SELECT * FROM students WHERE age > "16세";

SELECT * FROM students WHERE grade != "10학년";
SELECT * FROM students WHERE age >= "15세" AND grade = "10학년" ;
SELECT * FROM students 
WHERE age <= "16세" OR grade = "8학년" ;

SELECT * FROM students 
WHERE name LIKE "%태%";

SELECT * FROM reviews