# 영화 길이에 대한 백분위 순위와 누적분포 계산 
# 백분위 순위 : 전체를 100% 로 -> 0~1 => PERCENT_Rank()
# 누적분포:전체를 기준으로 각 그룹의 비율이 몇프로대까지인지를 누적해서 보는 것 =>CUME_DIST()

SELECT
	title,length, 
    PERCENT_RANK() OVER (ORDER BY length) as percent,;
    CUME_dist() OVER (order by length) as cume
    from film;
    
    SELECT 
		customer_id,
        CONCAT(first_name, ' ',last_name) AS customer_name, 
        NTILE(4) OVER (ORDER BY customer_id) AS customer_group 
	FROM customer;
    
    #payment 테이블에서 각 고객들의 ㄹ제 금액을 출력 
    # 고객 id , 고객 결제금액 , 해당 행의 결제 금액의 이전 결제금액, 해당 행의 결제 금액의 다음 결제금액 
    SELECT 
		customer_id,
		amount, 
        LAG(amount) OVER (PARTITION BY customer_id ORDER BY payment_date) AS previous_amount,
        LEAD(amount) OVER (PARTITION BY customer_id ORDER BY payment)date
	FROM payment ;
    
    #rental  테이블에서 각 고객별로 첫번째 대여일짜와 마지막 대뎌일자를 구하십시오 
    
    SELECT customer_id , MAX(rental_date), MIN(RENTAL_DATE) 
    FROM customer C 
    JOIN rental R USING(customer_id) 
    GROUP BY customer_id ;
    
    
    SELECT 
		distinct customer_id, 
        first_value(rental_date) OVER 
        (PARTITION BY customer_id ORDER BY rental_date) AS first_rental_date ,
	LAST_VALUE(rental_date) OVER 
		(PARTITION BY customer_id ORDER BY rental_date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING  ) AS last_rental_date
    FROM rental; 
    
    
    #payment 테이블에서 각 직원이 처리한 첫번째 결제와 마지막 결제와 마지막 결제 금액 출력 alter
    #직원 , 첫 결제금액, 마지막 : 
    
    SELECT
		DISTINCT staff_id ,
        FIRST_VALUE(amount) OVER
		(partition By staff_id order by payment_date) AS first_payment_amount
        FROM payment;
        
        
#film 테이블에서 각 영화의 대여기간에 대힌 벡븐위 순위, 누적분ㅂ포 계산 
#제목 , 기간, 백분위 순위, 누적분포
    SELECT 
		title,rental_duration ,
        PERCENT_RANK() OVER (ORDER BY rental_duration) AS percentile_rank,
        CUME_DIST() OVER (ORDER BY rental_duration) AS cumulative_distribution 
	FROM film ;
    
    
    #customer 테이블에서 각 고객의 결제 금액에 대한 백분위 순위와 누적분포를 계산해주세요 
    #고객 id, 총 결제금액, 백분위 순위, 누적분포 
    SELECT 
		c.customer_id,
        sum(p.amount) as total_amount,
        PERCENT_RANK() OVER (ORDER BY sum(p.amount)) AS percent_r,
        CUME_DIST() OVER (ORDER BY sum(p.amount)) AS cumulative_dis
	FROM customer C 
    JOIN payment P USING(customer_id)
    GROUP BY c.customer_id;
    
    
    #rental 테이블에서 각 고객별로 대여순서에 따른 누적 대여 횟수 출력 
    #rental_id , customer_id , 대여 날짜, 누적 대여 횟수 
    
    SELECT 
		customer_id,
		rental_id,
        rental_date,
        count(*) OVER (partition by customer_id ORDER BY rental_date
						ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
	FROM rental 
    GROUP BY customer_id,rental_id
    ;
    select * FROM payment;
    #payment 테이블에서 각 고객별로 결제 일자에 따른 누적 결제 금액을 출력 
    SELECT 
		customer_id ,
        payment_date,
        sum(amount) OVER (partition by customer_id ORDER by payment_date
							ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) 
	FROM payment ;
SELECT * FROM rental;
    #rental 테이블에서 각 직원들의 대여 날짜에 따른 대여횟수와 누적 대여 횟수 줄력
SELECT
	rental_id,staff_id,rental_date,
    count(*) OVER (partition by staff_id,DATE(rental_date)ORDER BY DATE(rental_date) ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)    AS rental_count,
    COUNT(*) OVER (partition By staff_id order by date(rental_date)
				ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW ) As cumulateive_count
FROM rental

    
