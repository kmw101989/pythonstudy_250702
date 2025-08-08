CREATE DATABASE IF NOT EXISTS bestproducts;
USE bestproducts;

DESC items ;
SELECT COUNT(*) FROM items;

SELECT * FROM items
LIMIT 1;

SElECT provider FROM items
GROUP BY provider ; 

-- 가설:베스트 랭킹에 등록되어있는 약 1만개 이상의 업체들가운데 진짜 베스트 오브 베스트  접체라고 한다면 배스트 랭킼ㅇ 안에 약 100개 정도의 자사 혹은 위탁 상품을 가지고 있지 않을까

SELECT provider FROM items 
GROUP By provider HAVING count(*) >=  100;

SELECT provider m COun(*) FRom itmes 
WHERE 
	provider != "스마일배송" AND 
	provider !=
GROUP By provider 
HAVING COUNT(*) >=0
ORDER By count(*) deSC;                                                                                                                                     