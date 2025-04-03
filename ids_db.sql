------------------
-- DROP TABLES --
------------------
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE "InvoiceContains" CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE "Invoice" CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE "Product" CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE "Stock" CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE "Store" CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE "CashRegister" CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE "Person" CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE "StockContains" CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE "StoreContains" CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE "Operates" CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

DROP SEQUENCE "product_seq";
DROP SEQUENCE "stock_seq";
DROP SEQUENCE "store_seq";
DROP SEQUENCE "cash_reg_seq";
DROP SEQUENCE "invoice_seq";
DROP SEQUENCE "person_seq";

-------------------
-- CREATE TABLES --
-------------------

-- Product
CREATE TABLE "Product" (
    "id" NUMBER CONSTRAINT "PK_Product" PRIMARY KEY,
    "name" VARCHAR2(100) CONSTRAINT "Product_name_nn" NOT NULL,
    "price" NUMBER(10,2) CONSTRAINT "Product_price_check" CHECK ("price" >= 0),
    "weight" NUMBER(10,2) CONSTRAINT "Product_weight_check" CHECK ("weight" >= 0),
    -- e.g 40x40x20cm
    "size" VARCHAR2(50) CONSTRAINT "Product_size_check" CHECK (REGEXP_LIKE("size", '^\d{1,10}x\d{1,10}x\d{1,10}(mm|cm|dm|m)$'))
);

-- Stock
CREATE TABLE "Stock" (
    "id" NUMBER CONSTRAINT "PK_Stock" PRIMARY KEY,
    "location" VARCHAR2(100) CONSTRAINT "Stock_location_nn" NOT NULL
);

-- Store
CREATE TABLE "Store" (
    "id" NUMBER CONSTRAINT "PK_Store" PRIMARY KEY,
    "location" VARCHAR2(100) CONSTRAINT "Store_location_nn" NOT NULL
);

-- CashRegister
CREATE TABLE "CashRegister" (
    "id" NUMBER CONSTRAINT "PK_CashRegister" PRIMARY KEY,
    "store_id" NUMBER CONSTRAINT "CashRegister_store_nn" NOT NULL,
    CONSTRAINT "FK_CashRegister_Store" FOREIGN KEY ("store_id") REFERENCES "Store" ("id") ON DELETE CASCADE
);

-- Person (merged customer and employee entities due to generalization)
CREATE TABLE "Person" (
    -- shared attributes
    "id" NUMBER CONSTRAINT "PK_Person" PRIMARY KEY,
    "name" VARCHAR2(100) CONSTRAINT "Person_name_nn" NOT NULL,
    "contact" VARCHAR2(100) CONSTRAINT "Person_contact_check" CHECK (REGEXP_LIKE("contact", '^\+[0-9]{12}$')),
    -- Determines type of Person (customer | employee)
    "type" VARCHAR2(100) CONSTRAINT "Person_type_nn" NOT NULL,
    -- customer attributes
    "email" VARCHAR2(100) CONSTRAINT "Person_email_check" CHECK (REGEXP_LIKE("email", '^[A-Za-z0-9._%+-]+@gmail.com$')),
    "password" VARCHAR2(100),
    -- employee attributes
    "role" VARCHAR2(100),
    "salary" VARCHAR2(100) CONSTRAINT "Person_salary_check" CHECK (REGEXP_LIKE("salary", '^[0-9]+\.[0-9]{2}€$')),
    CONSTRAINT "Person_type_check" CHECK ("type" IN ('customer', 'employee')),

     -- Constraints for Customer (email and password must be filled)
     CONSTRAINT "Person_customer_check" CHECK (
        ("type" = 'customer' AND "email" IS NOT NULL AND "password" IS NOT NULL) OR 
        ("type" = 'employee' AND "email" IS NULL AND "password" IS NULL)
    ),
    -- Constraints for Employee (role and salary must be filled)
    CONSTRAINT "Person_employee_check" CHECK (
        ("type" = 'employee' AND "role" IS NOT NULL AND "salary" IS NOT NULL) OR 
        ("type" = 'customer' AND "role" IS NULL AND "salary" IS NULL)
    )
);

-- Invoice (Now after Person & CashRegister exist) (merged sale and order entities due to generalization)
CREATE TABLE "Invoice" (
    -- shared attributes
    "id" NUMBER CONSTRAINT "PK_Invoice" PRIMARY KEY,
    "time" VARCHAR2(100) CONSTRAINT "Invoice_time_nn" NOT NULL,
    "date" VARCHAR2(100) CONSTRAINT "Invoice_date_nn" NOT NULL,
    "type" VARCHAR2(100) CONSTRAINT "Invoice_type_nn" NOT NULL,
    -- order attributes
    "person_id" NUMBER,
    "status" VARCHAR2(100),
    "address" VARCHAR2(100),
    -- sale attribute
    "cash_register_id" NUMBER,
    CONSTRAINT "FK_Invoice_Person" FOREIGN KEY ("person_id") REFERENCES "Person" ("id") ON DELETE SET NULL,
    CONSTRAINT "FK_Invoice_CashRegister" FOREIGN KEY ("cash_register_id") REFERENCES "CashRegister" ("id") ON DELETE SET NULL,
    CONSTRAINT "Invoice_type_check" CHECK ("type" IN ('order', 'sale')),
    
    --Constraints for Order (person_id, status and address must be filled)
    CONSTRAINT "Invoice_order_check" CHECK (
        ("type" = 'order' AND "person_id" IS NOT NULL AND "status" IS NOT NULL AND "address" IS NOT NULL) OR 
        ("type" = 'sale' AND "person_id" IS NULL AND "status" IS NULL AND "address" IS NULL)
    ),
    --Constraints for Sale (cash_register_id must be filled)
    CONSTRAINT "Invoice_sale_check" CHECK (
        ("type" = 'sale' AND "cash_register_id" IS NOT NULL) OR 
        ("type" = 'order' AND "cash_register_id" IS NULL)
    )
);

-- Junction Tables

-- StockContains
CREATE TABLE "StockContains" (
    "stock_id" NUMBER,
    "product_id" NUMBER,
    "quantity" NUMBER CONSTRAINT "StockContains_quantity_nn" NOT NULL,
    CONSTRAINT "PK_StockContains" PRIMARY KEY ("stock_id", "product_id"),
    CONSTRAINT "FK_StockContains_Stock" FOREIGN KEY ("stock_id") REFERENCES "Stock" ("id") ON DELETE CASCADE,
    CONSTRAINT "FK_StockContains_Product" FOREIGN KEY ("product_id") REFERENCES "Product" ("id") ON DELETE CASCADE
);

-- StoreContains
CREATE TABLE "StoreContains" (
    "store_id" NUMBER,
    "product_id" NUMBER,
    "quantity" NUMBER CONSTRAINT "StoreContains_quantity_nn" NOT NULL,
    CONSTRAINT "PK_StoreContains" PRIMARY KEY ("store_id", "product_id"),
    CONSTRAINT "FK_StoreContains_Store" FOREIGN KEY ("store_id") REFERENCES "Store" ("id") ON DELETE CASCADE,
    CONSTRAINT "FK_StoreContains_Product" FOREIGN KEY ("product_id") REFERENCES "Product" ("id") ON DELETE CASCADE
);

-- InvoiceContains (after Invoice exists)
CREATE TABLE "InvoiceContains" (
    "invoice_id" NUMBER,
    "product_id" NUMBER,
    "quantity" NUMBER CONSTRAINT "InvoiceContains_quantity_nn" NOT NULL,
    CONSTRAINT "PK_InvoiceContains" PRIMARY KEY ("invoice_id", "product_id"),
    CONSTRAINT "FK_InvoiceContains_Invoice" FOREIGN KEY ("invoice_id") REFERENCES "Invoice" ("id") ON DELETE CASCADE,
    CONSTRAINT "FK_InvoiceContains_Product" FOREIGN KEY ("product_id") REFERENCES "Product" ("id") ON DELETE CASCADE
);

-- Operates
CREATE TABLE "Operates" (
    "person_id" NUMBER,
    "cash_register_id" NUMBER,
    -- Time format: "YYYY-MM-DDTHH:mm:ssZ" -> T as a seperator between date and time. Z as "Zulu" (UTC+0)
    "start_time" VARCHAR2(100) CONSTRAINT "Operates_start_time_check" CHECK (REGEXP_LIKE("start_time", '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$')),
    "finish_time" VARCHAR2(100) CONSTRAINT "Operates_finish_time_check" CHECK (REGEXP_LIKE("finish_time", '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$')),
    CONSTRAINT "PK_Operates" PRIMARY KEY ("person_id", "cash_register_id"),
    CONSTRAINT "FK_Operates_Person" FOREIGN KEY ("person_id") REFERENCES "Person" ("id") ON DELETE CASCADE,
    CONSTRAINT "FK_Operates_CashRegister" FOREIGN KEY ("cash_register_id") REFERENCES "CashRegister" ("id") ON DELETE CASCADE
);

---------------------------
-- Auto-incrementing PKs --
---------------------------
CREATE SEQUENCE "product_seq" START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE "stock_seq" START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE "store_seq" START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE "cash_reg_seq" START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE "invoice_seq" START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE "person_seq" START WITH 1 INCREMENT BY 1 NOCACHE;

-----------------------------
-- Insert Data into Tables --
-----------------------------

-- Insert Data into Product
INSERT INTO "Product" ("id", "name", "price", "weight", "size") 
    VALUES ("product_seq".NEXTVAL, 'Laptop', 999.99, 2.50, '35x25x3cm');
INSERT INTO "Product" ("id", "name", "price", "weight", "size") 
    VALUES ("product_seq".NEXTVAL, 'Smartphone', 499.99, 0.20, '15x8x8cm');
INSERT INTO "Product" ("id", "name", "price", "weight", "size") 
    VALUES ("product_seq".NEXTVAL, 'Tablet', 299.99, 0.50, '24x16x7cm');

-- Insert Data into Stock
INSERT INTO "Stock" ("id", "location") VALUES ("stock_seq".NEXTVAL, 'Warehouse A');
INSERT INTO "Stock" ("id", "location") VALUES ("stock_seq".NEXTVAL, 'Warehouse B');

-- Insert Data into Store
INSERT INTO "Store" ("id", "location") VALUES ("store_seq".NEXTVAL, 'Store A, Downtown');
INSERT INTO "Store" ("id", "location") VALUES ("store_seq".NEXTVAL, 'Store B, Uptown');

-- Insert Data into CashRegister
INSERT INTO "CashRegister" ("id", "store_id") VALUES ("cash_reg_seq".NEXTVAL, 1);
INSERT INTO "CashRegister" ("id", "store_id") VALUES ("cash_reg_seq".NEXTVAL, 2);

-- Insert Data into Person (Customer and Employee)
-- Customer
INSERT INTO "Person" ("id", "name", "contact", "type", "email", "password") 
    VALUES ("person_seq".NEXTVAL, 'John Doe', '+123456789012', 'customer', 'john.doe@gmail.com', 'password123');
INSERT INTO "Person" ("id", "name", "contact", "type", "email", "password") 
    VALUES ("person_seq".NEXTVAL, 'Jane Smith', '+987654321098', 'customer', 'jane.smith@gmail.com', 'password456');

-- Employee
INSERT INTO "Person" ("id", "name", "contact", "type", "role", "salary") 
    VALUES ("person_seq".NEXTVAL, 'Alice Johnson', '+555123456789', 'employee', 'Cashier', '15.00€');
INSERT INTO "Person" ("id", "name", "contact", "type", "role", "salary") 
    VALUES ("person_seq".NEXTVAL, 'Bob Brown', '+555987654321', 'employee', 'Manager', '25.00€');

-- Insert Data into Invoice
INSERT INTO "Invoice" ("id", "time", "date", "type", "person_id", "status", "address", "cash_register_id") 
    VALUES ("invoice_seq".NEXTVAL, '2025-03-28T12:30:00Z', '2025-03-28', 'sale', NULL, NULL, NULL, 1);
INSERT INTO "Invoice" ("id", "time", "date", "type", "person_id", "status", "address", "cash_register_id") 
    VALUES ("invoice_seq".NEXTVAL, '2025-03-28T14:00:00Z', '2025-03-28', 'order', 1, 'Pending', '456 Oak St', NULL);

-- For StockContains
INSERT INTO "StockContains" ("stock_id", "product_id", "quantity") 
    VALUES (1, (SELECT "id" FROM "Product" WHERE "name" = 'Laptop'), 100);
INSERT INTO "StockContains" ("stock_id", "product_id", "quantity") 
    VALUES (1, (SELECT "id" FROM "Product" WHERE "name" = 'Smartphone'), 150);
INSERT INTO "StockContains" ("stock_id", "product_id", "quantity") 
    VALUES (2, (SELECT "id" FROM "Product" WHERE "name" = 'Tablet'), 200);

-- Insert Data into StoreContains
INSERT INTO "StoreContains" ("store_id", "product_id", "quantity") VALUES (1, 1, 50);
INSERT INTO "StoreContains" ("store_id", "product_id", "quantity") VALUES (1, 2, 75);
INSERT INTO "StoreContains" ("store_id", "product_id", "quantity") VALUES (2, 3, 100);

-- Insert Data into InvoiceContains
INSERT INTO "InvoiceContains" ("invoice_id", "product_id", "quantity") VALUES (1, 1, 1);
INSERT INTO "InvoiceContains" ("invoice_id", "product_id", "quantity") VALUES (1, 2, 2);
INSERT INTO "InvoiceContains" ("invoice_id", "product_id", "quantity") VALUES (2, 3, 1);

-- Insert Data into Operates (Employee operates Cash Register)
INSERT INTO "Operates" ("person_id", "cash_register_id", "start_time", "finish_time") 
    VALUES (3, 1, '2025-03-28T08:00:00Z', '2025-03-28T16:00:00Z');
INSERT INTO "Operates" ("person_id", "cash_register_id", "start_time", "finish_time") 
    VALUES (4, 2, '2025-03-28T09:00:00Z', '2025-03-28T17:00:00Z');

    ---------------------
-- SELECT Queries --
---------------------

-- 1. Display products and their quantity in stock
SELECT p."name", sc."quantity"
FROM "Product" p
JOIN "StockContains" sc ON p."id" = sc."product_id"
WHERE sc."stock_id" = 1;

-- Display employees and cash registers they operate
SELECT p."name", cr."id" AS "cash_register_id"
FROM "Person" p
JOIN "Operates" o ON p."id" = o."person_id"
JOIN "CashRegister" cr ON o."cash_register_id" = cr."id"
WHERE p."type" = 'employee';

-- Display invoices and cash registers with store locations where they were created
SELECT i."id" AS "invoice_id", cr."id" AS "cash_register_id", s."location" AS "store_location"
FROM "Invoice" i
JOIN "CashRegister" cr ON i."cash_register_id" = cr."id"
JOIN "Store" s ON cr."store_id" = s."id"
WHERE i."type" = 'sale';

-- Display all store locations and total quantity of products they contain
SELECT s."location", SUM(sc."quantity") AS "total_quantity"
FROM "Store" s
JOIN "StoreContains" sc ON s."id" = sc."store_id"
GROUP BY s."location";

-- Display total numbers of products on each invoice
SELECT ic."invoice_id", COUNT(ic."product_id") AS "item_count"
FROM "InvoiceContains" ic
GROUP BY ic."invoice_id";

-- Find and display names and emails of all customers that have order
SELECT p."name", p."email"
FROM "Person" p
WHERE p."type" = 'customer'
AND EXISTS (
    SELECT 1
    FROM "Invoice" i
    WHERE i."person_id" = p."id" AND i."type" = 'order'
);

-- Find and display all products and their price that are in stores containing registers
SELECT p."name", p."price"
FROM "Product" p
WHERE p."id" IN (
    SELECT sc."product_id"
    FROM "StoreContains" sc
    JOIN "Store" s ON sc."store_id" = s."id"
    JOIN "CashRegister" cr ON s."id" = cr."store_id"
);
