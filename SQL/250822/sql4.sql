USE wconcept_db_v1;

CREATE TABLE IF NOT EXISTS reviews (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  product_id   BIGINT UNSIGNED NOT NULL,        -- top100_products.id 참조
  review_text  MEDIUMTEXT NOT NULL,             -- 리뷰 본문(길이 고려)
  review_md5   CHAR(32) NOT NULL,               -- (product_id + review_text) 해시로 중복 방지
  -- 편의 조회용(옵션): 원하신 컬럼 3종도 같이 보관
  product_name VARCHAR(255) NULL,
  category     VARCHAR(50)  NULL,

  created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_reviews_product
    FOREIGN KEY (product_id) REFERENCES top100_products(id)
    ON DELETE CASCADE,

  UNIQUE KEY uniq_product_review (product_id, review_md5),
  KEY idx_reviews_product (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
