DESC students ;
SELECT * FROM students ; 

-- UPDATE students SET name = 'DAVID';

UPDATE students SET name = '윤대협'
WHERE id = 1;

UPDATE students SET age ='16세', grade = '9학년' 
WHERE id = 1;

UPDATE students SET age = '16세' , grade = '9학년' 
where name = '서태웅';

DELETE FROM students 
WHERE id = 2;

INSERT INTO students (name,age,grade)
value("서태웅","15세","8학년");

-- 만약 ID값을 새롭게 재정렬을 하고 싶다면? 
ALTER TABLE students AUTO INCREMENT 