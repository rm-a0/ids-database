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

-- 2. Display employees and cash registers they operate
SELECT p."name", cr."id" AS "cash_register_id"
FROM "Person" p
JOIN "Operates" o ON p."id" = o."person_id"
JOIN "CashRegister" cr ON o."cash_register_id" = cr."id"
WHERE p."type" = 'employee';

-- 3. Display invoices and cash registers with store locations where they were created
SELECT i."id" AS "invoice_id", cr."id" AS "cash_register_id", s."location" AS "store_location"
FROM "Invoice" i
JOIN "CashRegister" cr ON i."cash_register_id" = cr."id"
JOIN "Store" s ON cr."store_id" = s."id"
WHERE i."type" = 'sale';

-- 4. Display all store locations and total quantity of products they contain
SELECT s."location", SUM(sc."quantity") AS "total_quantity"
FROM "Store" s
JOIN "StoreContains" sc ON s."id" = sc."store_id"
GROUP BY s."location";

-- 5. Display total numbers of products on each invoice
SELECT ic."invoice_id", COUNT(ic."product_id") AS "item_count"
FROM "InvoiceContains" ic
GROUP BY ic."invoice_id";

-- 6. Find and display names and emails of all customers that have order
SELECT p."name", p."email"
FROM "Person" p
WHERE p."type" = 'customer'
AND EXISTS (
    SELECT 1
    FROM "Invoice" i
    WHERE i."person_id" = p."id" AND i."type" = 'order'
);

-- 7. Find and display all products and their price that are in stores containing registers
SELECT p."name", p."price"
FROM "Product" p
WHERE p."id" IN (
    SELECT sc."product_id"
    FROM "StoreContains" sc
    JOIN "Store" s ON sc."store_id" = s."id"
    JOIN "CashRegister" cr ON s."id" = cr."store_id"
);

------------------------------------
-- SQL Script for Retail Database --
------------------------------------

SET SERVEROUTPUT ON;

--------------------------
-- 1. Database Triggers --
--------------------------

-- Trigger 1: Update stock quantity when an invoice is created (for sales)
CREATE OR REPLACE TRIGGER "UpdateStockOnSale"
AFTER INSERT ON "InvoiceContains"
FOR EACH ROW
DECLARE
    v_store_id NUMBER;
    v_quantity NUMBER;
BEGIN
    -- Find the store associated with the invoice's cash register
    SELECT cr."store_id"
    INTO v_store_id
    FROM "Invoice" i
    JOIN "CashRegister" cr ON i."cash_register_id" = cr."id"
    WHERE i."id" = :NEW."invoice_id" AND i."type" = 'sale';

    -- Check if enough stock exists in the store
    SELECT "quantity"
    INTO v_quantity
    FROM "StoreContains"
    WHERE "store_id" = v_store_id AND "product_id" = :NEW."product_id"
    FOR UPDATE;

    IF v_quantity < :NEW."quantity" THEN
        RAISE_APPLICATION_ERROR(-20001, 'Insufficient stock for product ID ' || :NEW."product_id" || ' in store ID ' || v_store_id);
    END IF;

    -- Update store stock
    UPDATE "StoreContains"
    SET "quantity" = "quantity" - :NEW."quantity"
    WHERE "store_id" = v_store_id AND "product_id" = :NEW."product_id";

    DBMS_OUTPUT.PUT_LINE('Stock updated for product ID ' || :NEW."product_id" || ' in store ID ' || v_store_id);
END;
/

-- Trigger 2: Log employee operations on cash registers
CREATE OR REPLACE TRIGGER "LogCashRegisterOperation"
AFTER INSERT OR UPDATE ON "Operates"
FOR EACH ROW
DECLARE
    v_action VARCHAR2(50);
BEGIN
    IF INSERTING THEN
        v_action := 'Started operating';
    ELSIF UPDATING THEN
        v_action := 'Updated operation';
    END IF;

    INSERT INTO "OperationLog" (
        "log_id",
        "person_id",
        "cash_register_id",
        "action",
        "log_time"
    ) VALUES (
        "operation_log_seq".NEXTVAL,
        :NEW."person_id",
        :NEW."cash_register_id",
        v_action || ' at ' || :NEW."start_time",
        SYSTIMESTAMP
    );

    DBMS_OUTPUT.PUT_LINE('Logged operation for person ID ' || :NEW."person_id" || ' on cash register ID ' || :NEW."cash_register_id");
END;
/

-- Create OperationLog table and sequence for the trigger
CREATE SEQUENCE "operation_log_seq" START WITH 1 INCREMENT BY 1 NOCACHE;

CREATE TABLE "OperationLog" (
    "log_id" NUMBER CONSTRAINT "PK_OperationLog" PRIMARY KEY,
    "person_id" NUMBER,
    "cash_register_id" NUMBER,
    "action" VARCHAR2(200),
    "log_time" TIMESTAMP,
    CONSTRAINT "FK_OperationLog_Person" FOREIGN KEY ("person_id") REFERENCES "Person" ("id") ON DELETE SET NULL,
    CONSTRAINT "FK_OperationLog_CashRegister" FOREIGN KEY ("cash_register_id") REFERENCES "CashRegister" ("id") ON DELETE SET NULL
);

--------------------------
-- 2. Stored Procedures --
--------------------------

-- Procedure 1: Process a new sale with cursor and exception handling
CREATE OR REPLACE PROCEDURE "ProcessSale" (
    p_cash_register_id IN "CashRegister"."id"%TYPE,
    p_employee_id IN "Person"."id"%TYPE,
    p_products IN SYS.ODCINUMBERLIST
) AS
    CURSOR product_cursor IS
        SELECT "id", "price"
        FROM "Product"
        WHERE "id" IN (SELECT COLUMN_VALUE FROM TABLE(p_products));
    
    v_invoice_id "Invoice"."id"%TYPE;
    v_total_price NUMBER(10,2) := 0;
    v_product_row "Product"%ROWTYPE;
BEGIN
    -- Start transaction
    SAVEPOINT start_sale;

    -- Create new invoice
    INSERT INTO "Invoice" (
        "id", "time", "date", "type", "cash_register_id"
    ) VALUES (
        "invoice_seq".NEXTVAL,
        TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
        TO_CHAR(SYSDATE, 'YYYY-MM-DD'),
        'sale',
        p_cash_register_id
    ) RETURNING "id" INTO v_invoice_id;

    -- Process products using cursor
    FOR product_rec IN product_cursor LOOP
        v_total_price := v_total_price + product_rec."price";
        
        INSERT INTO "InvoiceContains" (
            "invoice_id", "product_id", "quantity"
        ) VALUES (
            v_invoice_id, product_rec."id", 1
        );
    END LOOP;

    -- Log operation
    UPDATE "Operates"
    SET "finish_time" = TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
    WHERE "person_id" = p_employee_id 
    AND "cash_register_id" = p_cash_register_id;

    DBMS_OUTPUT.PUT_LINE('Sale processed. Invoice ID: ' || v_invoice_id || ', Total: ' || v_total_price);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK TO start_sale;
        DBMS_OUTPUT.PUT_LINE('Error: Invalid product or cash register ID');
        RAISE_APPLICATION_ERROR(-20002, 'Invalid product or cash register ID');
    WHEN OTHERS THEN
        ROLLBACK TO start_sale;
        DBMS_OUTPUT.PUT_LINE('Error in ProcessSale: ' || SQLERRM);
        RAISE;
END;
/

-- Procedure 2: Generate stock report with %TYPE and exception handling
CREATE OR REPLACE PROCEDURE "GenerateStockReport" (
    p_stock_id IN "Stock"."id"%TYPE
) AS
    v_product_name "Product"."name"%TYPE;
    v_quantity "StockContains"."quantity"%TYPE;
    v_total_value NUMBER(10,2) := 0;
    
    CURSOR stock_cursor IS
        SELECT p."name", sc."quantity", p."price"
        FROM "StockContains" sc
        JOIN "Product" p ON sc."product_id" = p."id"
        WHERE sc."stock_id" = p_stock_id;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Stock Report for Stock ID: ' || p_stock_id);
    DBMS_OUTPUT.PUT_LINE('----------------------------------');

    -- Open cursor and process stock
    FOR stock_rec IN stock_cursor LOOP
        v_product_name := stock_rec."name";
        v_quantity := stock_rec."quantity";
        v_total_value := v_total_value + (stock_rec."quantity" * stock_rec."price");

        DBMS_OUTPUT.PUT_LINE('Product: ' || v_product_name || 
                            ', Quantity: ' || v_quantity || 
                            ', Value: ' || (v_quantity * stock_rec."price"));
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('----------------------------------');
    DBMS_OUTPUT.PUT_LINE('Total Value: ' || v_total_value);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No products found in stock ID ' || p_stock_id);
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error in GenerateStockReport: ' || SQLERRM);
        RAISE;
END;
/

----------------------------------------
-- 3. Index Creation and EXPLAIN PLAN --
----------------------------------------

-- Create index to optimize product searches by name
CREATE INDEX "IDX_Product_Name" ON "Product" ("name");

-- EXPLAIN PLAN for query without index optimization
EXPLAIN PLAN FOR
SELECT s."location", SUM(sc."quantity") AS "total_quantity", COUNT(DISTINCT sc."product_id") AS "product_types"
FROM "Store" s
JOIN "StoreContains" sc ON s."id" = sc."store_id"
JOIN "Product" p ON sc."product_id" = p."id"
WHERE p."name" LIKE 'Laptop%'
GROUP BY s."location";

-- Display plan
SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY());

-- Create index to optimize the above query
CREATE INDEX "IDX_StoreContains_Product" ON "StoreContains" ("product_id", "store_id");

-- Re-run EXPLAIN PLAN after index creation
EXPLAIN PLAN FOR
SELECT s."location", SUM(sc."quantity") AS "total_quantity", COUNT(DISTINCT sc."product_id") AS "product_types"
FROM "Store" s
JOIN "StoreContains" sc ON s."id" = sc."store_id"
JOIN "Product" p ON sc."product_id" = p."id"
WHERE p."name" LIKE 'Laptop%'
GROUP BY s."location";

-- Display plan
SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY());

----------------------
-- 4. Access Rights --
----------------------

-- Grant permissions to second team member (user 'xrepcim00')
GRANT SELECT, INSERT, UPDATE ON "Product" TO xrepcim00;
GRANT SELECT, INSERT, UPDATE ON "Store" TO xrepcim00;
GRANT SELECT, INSERT, UPDATE ON "StoreContains" TO xrepcim00;
GRANT SELECT ON "Invoice" TO xrepcim00;
GRANT SELECT ON "InvoiceContains" TO xrepcim00;
GRANT EXECUTE ON "ProcessSale" TO xrepcim00;
GRANT EXECUTE ON "GenerateStockReport" TO xrepcim00;

--------------------------
-- 5. Materialized View --
--------------------------

-- Create materialized view for xrepcim00 to track store inventory
CREATE MATERIALIZED VIEW "StoreInventory_MV"
BUILD IMMEDIATE
REFRESH FAST ON COMMIT
AS
SELECT s."id" AS "store_id", s."location", p."id" AS "product_id", p."name", sc."quantity"
FROM "Store" s
JOIN "StoreContains" sc ON s."id" = sc."store_id"
JOIN "Product" p ON sc."product_id" = p."id";

-- Grant permissions to xrepcim00
GRANT SELECT, INSERT, ALTER, DELETE ON "StoreInventory_MV" TO xrepcim00;

------------------------------------------
-- 6. Complex SELECT with WITH and CASE --
------------------------------------------

-- Query to analyze sales performance by store
-- Description: Retrieves total sales value per store, categorizing stores as 'High', 'Medium', or 'Low' performing based on sales value
SELECT 
    store_sales."store_id",
    store_sales."location",
    store_sales."total_sales",
    CASE 
        WHEN store_sales."total_sales" > 1000 THEN 'High'
        WHEN store_sales."total_sales" BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS "performance_category"
FROM (
    WITH SalesData AS (
        SELECT 
            s."id" AS "store_id",
            s."location",
            SUM(p."price" * ic."quantity") AS "total_sales"
        FROM "Store" s
        JOIN "CashRegister" cr ON s."id" = cr."store_id"
        JOIN "Invoice" i ON cr."id" = i."cash_register_id"
        JOIN "InvoiceContains" ic ON i."id" = ic."invoice_id"
        JOIN "Product" p ON ic."product_id" = p."id"
        WHERE i."type" = 'sale'
        GROUP BY s."id", s."location"
    )
    SELECT * FROM SalesData
) store_sales
ORDER BY store_sales."total_sales" DESC;

-------------------------------------------------
-- 7. Demonstration of Triggers and Procedures --
-------------------------------------------------

-- Demonstrate Trigger 1: UpdateStockOnSale
INSERT INTO "Invoice" (
    "id", "time", "date", "type", "cash_register_id"
) VALUES (
    "invoice_seq".NEXTVAL,
    '2025-03-29T10:00:00Z',
    '2025-03-29',
    'sale',
    1
) RETURNING "id" INTO v_invoice_id;

INSERT INTO "InvoiceContains" (
    "invoice_id", "product_id", "quantity"
) VALUES (
    v_invoice_id,
    (SELECT "id" FROM "Product" WHERE "name" = 'Laptop'),
    5
);

-- Check stock reduction
SELECT "quantity"
FROM "StoreContains"
WHERE "store_id" = 1 AND "product_id" = (SELECT "id" FROM "Product" WHERE "name" = 'Laptop');

-- Demonstrate Trigger 2: LogCashRegisterOperation
INSERT INTO "Operates" (
    "person_id", "cash_register_id", "start_time", "finish_time"
) VALUES (
    3,
    1,
    '2025-03-29T08:00:00Z',
    '2025-03-29T16:00:00Z'
);

-- Check log
SELECT * FROM "OperationLog";

-- Demonstrate Procedure 1: ProcessSale
BEGIN
    "ProcessSale"(
        p_cash_register_id => 1,
        p_employee_id => 3,
        p_products => SYS.ODCINUMBERLIST(1, 2)
    );
END;
/

-- Demonstrate Procedure 2: GenerateStockReport
BEGIN
    "GenerateStockReport"(p_stock_id => 1);
END;
/

---------------------------------
-- 8. Transactional Processing --
---------------------------------

-- Demonstrate atomicity with concurrent stock updates
DECLARE
    v_product_id "Product"."id"%TYPE;
BEGIN
    -- Select product ID for Laptop
    SELECT "id" INTO v_product_id
    FROM "Product"
    WHERE "name" = 'Laptop';

    -- Start transaction
    SAVEPOINT start_transaction;

    -- Lock store contains for update
    UPDATE "StoreContains"
    SET "quantity" = "quantity" - 10
    WHERE "store_id" = 1 AND "product_id" = v_product_id;

    -- Simulate delay to show locking
    DBMS_LOCK.SLEEP(5);

    -- Update stock
    UPDATE "StockContains"
    SET "quantity" = "quantity" - 10
    WHERE "stock_id" = 1 AND "product_id" = v_product_id;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Transaction completed successfully');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO start_transaction;
        DBMS_OUTPUT.PUT_LINE('Transaction failed: ' || SQLERRM);
END;
/

-- Query to verify materialized view
SELECT * FROM "StoreInventory_MV" WHERE "quantity" > 50;