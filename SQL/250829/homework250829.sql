-- 고객별 결제 내역을 날짜순으로 정렬하여 누적 결제 금액을 계산하고, 각 결제 건마다 이전 결제 금액 차이와 다음 결제 금액 차이를 구하세요. 
-- 고객별 첫 번째 결제일과 마지막 결제일을 찾으며, 전체 고객의 총 결제 금액을 기준으로 5개의 그룹으로 나누어 각 결제가 속한 그룹을 표시하세요.
--  또한 고객별 총 결제 금액을 기준으로 내림차순 순위를 매기되, 동일 금액은 같은 순위를 부여하고 이후 순위는 연속되게 이어지도록 하세요. 고
--  객별 총 결제 금액에 대해 백분위 순위와 누적 분포를 계산하고, 마지막으로 고객별 결제 내역을 날짜순으로 정렬했을 때 각 결제가 몇 번째 결제인지 순서를 부여하세요.
-- 위 내용들을 다음 항목으로 출력해주세요. customer_id, payment_date, cumulative_amount, prev_payment_diff, next_payment_diff, 
-- first_payment_date, last_payment_date, total_amount_rank, payment_amount_pct_rank, payment_amount_cume_dist, total_amount_group, group_row_number
WITH customer_totals AS (
  SELECT
    p.customer_id,
    SUM(p.amount) AS total_amount
  FROM payment AS p
  GROUP BY p.customer_id
),
customer_ranks AS (
  SELECT
    ct.customer_id,
    ct.total_amount,
    DENSE_RANK()  OVER (ORDER BY ct.total_amount DESC) AS total_amount_rank,
    PERCENT_RANK() OVER (ORDER BY ct.total_amount DESC) AS payment_amount_pct_rank,
    CUME_DIST()    OVER (ORDER BY ct.total_amount DESC) AS payment_amount_cume_dist,
    NTILE(5)       OVER (ORDER BY ct.total_amount DESC) AS total_amount_group
  FROM customer_totals AS ct
)
SELECT 
	customer_id,payment_date,
    SUM(amount) OVER (PARTITION BY customer_id ORDER BY date(payment_date), payment_id
 						ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_amount,
	amount - LAG(amount) OVER (PARTITION BY customer_id ORDER BY payment_date) AS prev_payment_diff,
    LEAD(amount) OVER(PARTITION BY customer_id ORDER BY payment_date) - amount AS next_payment_diff,
	FIRST_VALUE(payment_date) OVER(PARTITION BY customer_id ORDER BY payment_date) AS first_payment_date,
	LAST_VALUE(payment_date) OVER(PARTITION BY customer_id ) AS LAST_payment_date,
    total_amount_rank,payment_amount_pct_rank,payment_amount_cume_dist,total_amount_group,
    ROW_NUMBER() OVER(PARTITION BY total_amount_group ORDER BY payment_id) AS group_row_number
FROM payment 
JOIN customer_ranks AS CR USING(customer_id)
GROUP BY payment_id,customer_id;

