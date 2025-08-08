USE interpark ;

SELECT * FROM performances;

SELECT COUNT(*) FROM performances;
# 1. 크롤링한 전체 데이터 개수
SELECT COUNT(*) AS Total_performances FROM performances;

SELECT place, COUNT(*) AS 개수
FROM performances 
group by place 
ORDER BY 개수 DESC; 

SELECT * FROM performances 
WHERE place LIKE "%전국 각 지역%";

SELECT title, place, SUBSTRING_INDEX(date_range, ' - ' , 1) AS start_date
FROM performances
order by start_date DESC;