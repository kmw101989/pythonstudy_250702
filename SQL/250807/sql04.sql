-- CREATE DATABASE IF NOT EXISTS musinsa2 ; 

CREATE TABLE IF NOT EXISTS customers (
	customer_id INT PRIMARY KEY ,
    name VARCHAR(40),
    age INT ,
    gender VARCHAR(20),
    address TEXT, 
    phone VARCHAR(20),
    email VARCHAR(50),
    grade VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS products ( 
	product_id INT PRIMARY KEY ,
    product_name VARCHAR(100),
    stock INT ,
    main_category VARCHAR(50),
    sub_category VARCHAR(50),
    price INT ,
    discount_price INT,
    discount_rate INT
);

CREATE TABLE IF NOT EXISTS orders(
	order_id INT PRIMARY KEY,
    customer_id INT,
    product_id INT,
    quantity int,
    order_date DATE ,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE IF NOT EXISTS reviews (
	review_id INT PRIMARY KEY,
    customer_id INT,
    product_id INT,
    rating INT,
    review_text TEXT,
    review_date DATE,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)    
);

-- ALTER TABLE customers MODIFY COLUMN name varchar(100);
-- ALTER TABLE customers MODIFY COLUMN email VARCHAR(100);

