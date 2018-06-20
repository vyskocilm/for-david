--#
-- how to initialize things
-- sudo -u postgres psql
-- CREATE USER mvyskocil WITH CREATEDB;
-- CREATE DATABASE mvyskocil WITH OWNER mvyskocil ENCODING UNICODE;
--

DROP SEQUENCE customer_inventory_id;
DROP TABLE customer_inventory;
DROP SEQUENCE customers_id;
DROP TABLE customers;

CREATE TABLE customers (
    cust_id INT PRIMARY KEY,
    cust_num INT NOT NULL,             --CustNmbr
    cust_name VARCHAR (100) NOT NULL); --CustomerName;

CREATE SEQUENCE customers_id OWNED BY customers.cust_id;

CREATE TABLE customer_inventory (
    inventory_id INT PRIMARY KEY,
    cust_id INT REFERENCES customers(cust_id),  --CustNmbr
    filename VARCHAR(100) NOT NULL,             --"example-products.csv"
    part_code INT,                              --PartNmbr
    description VARCHAR(200),                   --Description
    delivery_date TIMESTAMP,                    --Deldate
    order_reference VARCHAR(50));               --Orderref

CREATE SEQUENCE customer_inventory_id OWNED BY customer_inventory.inventory_id;
