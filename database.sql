SET SERVEROUTPUT ON;

------------------
-- DROP OBJECTS --
------------------
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE "InvoiceContains" CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE "Invoice" CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE "StockContains" CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE "StoreContains" CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE "Operates" CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE "OperationLog" CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE "CashRegister" CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE "Person" CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE "Store" CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE "Stock" CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE "Product" CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE "product_seq"';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE "stock_seq"';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE "store_seq"';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE "cash_reg_seq"';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE "invoice_seq"';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE "person_seq"';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE "operation_log_seq"';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-------------------
-- CREATE TABLES --
-------------------

-- Product
CREATE TABLE "Product" (
    "id" NUMBER CONSTRAINT "PK_Product" PRIMARY KEY,
    "name" VARCHAR2(100) CONSTRAINT "Product_name_nn" NOT NULL,
    "price" NUMBER(10,2) CONSTRAINT "Product_price_check" CHECK ("price" >= 0),
    "weight" NUMBER(10,2) CONSTRAINT "Product_weight_check" CHECK ("weight" >= 0),
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

-- Person 
CREATE TABLE "Person" (
    "id" NUMBER CONSTRAINT "PK_Person" PRIMARY KEY,
    "name" VARCHAR2(100) CONSTRAINT "Person_name_nn" NOT NULL,
    "contact" VARCHAR2(100) CONSTRAINT "Person_contact_check" CHECK (REGEXP_LIKE("contact", '^\+[0-9]{12}$')),
    "type" VARCHAR2(100) CONSTRAINT "Person_type_nn" NOT NULL,
    "email" VARCHAR2(100) CONSTRAINT "Person_email_check" CHECK (REGEXP_LIKE("email", '^[A-Za-z0-9._%+-]+@gmail.com$')),
    "password" VARCHAR2(100),
    "role" VARCHAR2(100),
    "salary" VARCHAR2(100) CONSTRAINT "Person_salary_check" CHECK (REGEXP_LIKE("salary", '^[0-9]+\.[0-9]{2}€$')),
    CONSTRAINT "Person_type_check" CHECK ("type" IN ('customer', 'employee')),
    CONSTRAINT "Person_customer_check" CHECK (
        ("type" = 'customer' AND "email" IS NOT NULL AND "password" IS NOT NULL) OR 
        ("type" = 'employee' AND "email" IS NULL AND "password" IS NULL)
    ),
    CONSTRAINT "Person_employee_check" CHECK (
        ("type" = 'employee' AND "role" IS NOT NULL AND "salary" IS NOT NULL) OR 
        ("type" = 'customer' AND "role" IS NULL AND "salary" IS NULL)
    )
);

-- Invoice 
CREATE TABLE "Invoice" (
    "id" NUMBER CONSTRAINT "PK_Invoice" PRIMARY KEY,
    "time" VARCHAR2(100) CONSTRAINT "Invoice_time_nn" NOT NULL,
    "date" VARCHAR2(100) CONSTRAINT "Invoice_date_nn" NOT NULL,
    "type" VARCHAR2(100) CONSTRAINT "Invoice_type_nn" NOT NULL,
    "person_id" NUMBER,
    "status" VARCHAR2(100),
    "address" VARCHAR2(100),
    "cash_register_id" NUMBER,
    CONSTRAINT "FK_Invoice_Person" FOREIGN KEY ("person_id") REFERENCES "Person" ("id") ON DELETE SET NULL,
    CONSTRAINT "FK_Invoice_CashRegister" FOREIGN KEY ("cash_register_id") REFERENCES "CashRegister" ("id") ON DELETE SET NULL,
    CONSTRAINT "Invoice_type_check" CHECK ("type" IN ('order', 'sale')),
    CONSTRAINT "Invoice_order_check" CHECK (
        ("type" = 'order' AND "person_id" IS NOT NULL AND "status" IS NOT NULL AND "address" IS NOT NULL) OR 
        ("type" = 'sale' AND "person_id" IS NULL AND "status" IS NULL AND "address" IS NULL)
    ),
    CONSTRAINT "Invoice_sale_check" CHECK (
        ("type" = 'sale' AND "cash_register_id" IS NOT NULL) OR 
        ("type" = 'order' AND "cash_register_id" IS NULL)
    )
);

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

-- InvoiceContains
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
    "start_time" VARCHAR2(100) CONSTRAINT "Operates_start_time_check" CHECK (REGEXP_LIKE("start_time", '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$')),
    "finish_time" VARCHAR2(100) CONSTRAINT "Operates_finish_time_check" CHECK (REGEXP_LIKE("finish_time", '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$')),
    CONSTRAINT "PK_Operates" PRIMARY KEY ("person_id", "cash_register_id", "start_time"),
    CONSTRAINT "FK_Operates_Person" FOREIGN KEY ("person_id") REFERENCES "Person" ("id") ON DELETE CASCADE,
    CONSTRAINT "FK_Operates_CashRegister" FOREIGN KEY ("cash_register_id") REFERENCES "CashRegister" ("id") ON DELETE CASCADE
);

-- OperationLog
CREATE TABLE "OperationLog" (
    "log_id" NUMBER CONSTRAINT "PK_OperationLog" PRIMARY KEY,
    "person_id" NUMBER,
    "cash_register_id" NUMBER,
    "action" VARCHAR2(200),
    "log_time" TIMESTAMP,
    CONSTRAINT "FK_OperationLog_Person" FOREIGN KEY ("person_id") REFERENCES "Person" ("id") ON DELETE SET NULL,
    CONSTRAINT "FK_OperationLog_CashRegister" FOREIGN KEY ("cash_register_id") REFERENCES "CashRegister" ("id") ON DELETE SET NULL
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
CREATE SEQUENCE "operation_log_seq" START WITH 1 INCREMENT BY 1 NOCACHE;

-----------------------------
-- Insert Data into Tables --
-----------------------------

-- Product
INSERT INTO "Product" ("id", "name", "price", "weight", "size") 
VALUES ("product_seq".NEXTVAL, 'Laptop', 999.99, 2.50, '35x25x3cm');
INSERT INTO "Product" ("id", "name", "price", "weight", "size") 
VALUES ("product_seq".NEXTVAL, 'Smartphone', 499.99, 0.20, '15x8x8cm');
INSERT INTO "Product" ("id", "name", "price", "weight", "size") 
VALUES ("product_seq".NEXTVAL, 'Tablet', 299.99, 0.50, '24x16x7cm');

-- Stock
INSERT INTO "Stock" ("id", "location") VALUES ("stock_seq".NEXTVAL, 'Warehouse A');
INSERT INTO "Stock" ("id", "location") VALUES ("stock_seq".NEXTVAL, 'Warehouse B');

-- Store
INSERT INTO "Store" ("id", "location") VALUES ("store_seq".NEXTVAL, 'Store A, Downtown');
INSERT INTO "Store" ("id", "location") VALUES ("store_seq".NEXTVAL, 'Store B, Uptown');

-- CashRegister
INSERT INTO "CashRegister" ("id", "store_id") VALUES ("cash_reg_seq".NEXTVAL, 1);
INSERT INTO "CashRegister" ("id", "store_id") VALUES ("cash_reg_seq".NEXTVAL, 2);

-- Person
INSERT INTO "Person" ("id", "name", "contact", "type", "email", "password") 
VALUES ("person_seq".NEXTVAL, 'John Doe', '+123456789012', 'customer', 'john.doe@gmail.com', 'password123');
INSERT INTO "Person" ("id", "name", "contact", "type", "email", "password") 
VALUES ("person_seq".NEXTVAL, 'Jane Smith', '+987654321098', 'customer', 'jane.smith@gmail.com', 'password456');
INSERT INTO "Person" ("id", "name", "contact", "type", "role", "salary") 
VALUES ("person_seq".NEXTVAL, 'Alice Johnson', '+555123456789', 'employee', 'Cashier', '15.00€');
INSERT INTO "Person" ("id", "name", "contact", "type", "role", "salary") 
VALUES ("person_seq".NEXTVAL, 'Bob Brown', '+555987654321', 'employee', 'Manager', '25.00€');

-- Invoice
INSERT INTO "Invoice" ("id", "time", "date", "type", "person_id", "status", "address", "cash_register_id") 
VALUES ("invoice_seq".NEXTVAL, '2025-03-28T12:30:00Z', '2025-03-28', 'sale', NULL, NULL, NULL, 1);
INSERT INTO "Invoice" ("id", "time", "date", "type", "person_id", "status", "address", "cash_register_id") 
VALUES ("invoice_seq".NEXTVAL, '2025-03-28T14:00:00Z', '2025-03-28', 'order', 1, 'Pending', '456 Oak St', NULL);

-- StockContains
INSERT INTO "StockContains" ("stock_id", "product_id", "quantity") 
VALUES (1, (SELECT "id" FROM "Product" WHERE "name" = 'Laptop'), 100);
INSERT INTO "StockContains" ("stock_id", "product_id", "quantity") 
VALUES (1, (SELECT "id" FROM "Product" WHERE "name" = 'Smartphone'), 150);
INSERT INTO "StockContains" ("stock_id", "product_id", "quantity") 
VALUES (2, (SELECT "id" FROM "Product" WHERE "name" = 'Tablet'), 200);

-- StoreContains
INSERT INTO "StoreContains" ("store_id", "product_id", "quantity") VALUES (1, 1, 50);
INSERT INTO "StoreContains" ("store_id", "product_id", "quantity") VALUES (1, 2, 75);
INSERT INTO "StoreContains" ("store_id", "product_id", "quantity") VALUES (2, 3, 100);

-- InvoiceContains
INSERT INTO "InvoiceContains" ("invoice_id", "product_id", "quantity") VALUES (1, 1, 1);
INSERT INTO "InvoiceContains" ("invoice_id", "product_id", "quantity") VALUES (1, 2, 2);
INSERT INTO "InvoiceContains" ("invoice_id", "product_id", "quantity") VALUES (2, 3, 1);

-- Operates
INSERT INTO "Operates" ("person_id", "cash_register_id", "start_time", "finish_time") 
VALUES (3, 1, '2025-03-28T08:00:00Z', '2025-03-28T16:00:00Z');
INSERT INTO "Operates" ("person_id", "cash_register_id", "start_time", "finish_time") 
VALUES (4, 2, '2025-03-28T09:00:00Z', '2025-03-28T17:00:00Z');

--------------------------
-- Database Triggers --
--------------------------

-- Trigger 1: Update stock quantity when an invoice is created (for sales)
CREATE OR REPLACE TRIGGER "UpdateStockOnSale"
AFTER INSERT ON "InvoiceContains"
FOR EACH ROW
DECLARE
    v_store_id NUMBER;
    v_quantity NUMBER;
BEGIN
    SELECT cr."store_id" INTO v_store_id
    FROM "Invoice" i
    JOIN "CashRegister" cr ON i."cash_register_id" = cr."id"
    WHERE i."id" = :NEW."invoice_id" AND i."type" = 'sale';

    SELECT "quantity" INTO v_quantity
    FROM "StoreContains"
    WHERE "store_id" = v_store_id AND "product_id" = :NEW."product_id"
    FOR UPDATE;

    IF v_quantity < :NEW."quantity" THEN
        RAISE_APPLICATION_ERROR(-20001, 'Insufficient stock for product ID ' || :NEW."product_id" || ' in store ID ' || v_store_id);
    END IF;

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
        "log_id", "person_id", "cash_register_id", "action", "log_time"
    ) VALUES (
        "operation_log_seq".NEXTVAL, :NEW."person_id", :NEW."cash_register_id",
        v_action || ' at ' || :NEW."start_time", SYSTIMESTAMP
    );

    DBMS_OUTPUT.PUT_LINE('Logged operation for person ID ' || :NEW."person_id" || ' on cash register ID ' || :NEW."cash_register_id");
END;
/

--------------------------
-- Stored Procedures --
--------------------------

-- Procedure 1: Process a new sale
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
    SAVEPOINT start_sale;

    INSERT INTO "Invoice" (
        "id", "time", "date", "type", "cash_register_id"
    ) VALUES (
        "invoice_seq".NEXTVAL,
        TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
        TO_CHAR(SYSDATE, 'YYYY-MM-DD'),
        'sale',
        p_cash_register_id
    ) RETURNING "id" INTO v_invoice_id;

    FOR product_rec IN product_cursor LOOP
        v_total_price := v_total_price + product_rec."price";
        INSERT INTO "InvoiceContains" (
            "invoice_id", "product_id", "quantity"
        ) VALUES (
            v_invoice_id, product_rec."id", 1
        );
    END LOOP;

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

-- Procedure 2: Generate stock report
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
-- Index Creation and EXPLAIN PLAN --
----------------------------------------

-- Index to optimize product searches by name
CREATE INDEX "IDX_Product_Name" ON "Product" ("name");

-- EXPLAIN PLAN before index optimization
EXPLAIN PLAN FOR
SELECT s."location", SUM(sc."quantity") AS "total_quantity", COUNT(DISTINCT sc."product_id") AS "product_types"
FROM "Store" s
JOIN "StoreContains" sc ON s."id" = sc."store_id"
JOIN "Product" p ON sc."product_id" = p."id"
WHERE p."name" LIKE 'Laptop%'
GROUP BY s."location";
SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY());

-- Index to optimize the query
CREATE INDEX "IDX_StoreContains_Product" ON "StoreContains" ("product_id", "store_id");

-- EXPLAIN PLAN after index
EXPLAIN PLAN FOR
SELECT s."location", SUM(sc."quantity") AS "total_quantity", COUNT(DISTINCT sc."product_id") AS "product_types"
FROM "Store" s
JOIN "StoreContains" sc ON s."id" = sc."store_id"
JOIN "Product" p ON sc."product_id" = p."id"
WHERE p."name" LIKE 'Laptop%'
GROUP BY s."location";
SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY());

--------------------------
-- Materialized View Logs --
--------------------------
-- Execute as xrepcim00
CREATE MATERIALIZED VIEW LOG ON "Store" WITH PRIMARY KEY, ROWID ("location");
CREATE MATERIALIZED VIEW LOG ON "StoreContains" WITH PRIMARY KEY, ROWID ("quantity");
CREATE MATERIALIZED VIEW LOG ON "Product" WITH PRIMARY KEY, ROWID ("name");

--------------------------
-- Access Rights --
--------------------------

-- Grants for xrepcim00
GRANT SELECT, INSERT, UPDATE ON "Product" TO xrepcim00;
GRANT SELECT, INSERT, UPDATE ON "Store" TO xrepcim00;
GRANT SELECT, INSERT, UPDATE ON "StoreContains" TO xrepcim00;
GRANT SELECT ON "Invoice" TO xrepcim00;
GRANT SELECT ON "InvoiceContains" TO xrepcim00;
GRANT EXECUTE ON "ProcessSale" TO xrepcim00;
GRANT EXECUTE ON "GenerateStockReport" TO xrepcim00;

-- Grants for xvesela00 (execute as xrepcim00)
GRANT ALL ON "Product" TO xvesela00;
GRANT ALL ON "Stock" TO xvesela00;
GRANT ALL ON "Store" TO xvesela00;
GRANT ALL ON "CashRegister" TO xvesela00;
GRANT ALL ON "Person" TO xvesela00;
GRANT ALL ON "Invoice" TO xvesela00;
GRANT ALL ON "StockContains" TO xvesela00;
GRANT ALL ON "StoreContains" TO xvesela00;
GRANT ALL ON "InvoiceContains" TO xvesela00;
GRANT ALL ON "Operates" TO xvesela00;
GRANT ALL ON "OperationLog" TO xvesela00;
GRANT ALL ON "product_seq" TO xvesela00;
GRANT ALL ON "stock_seq" TO xvesela00;
GRANT ALL ON "store_seq" TO xvesela00;
GRANT ALL ON "cash_reg_seq" TO xvesela00;
GRANT ALL ON "invoice_seq" TO xvesela00;
GRANT ALL ON "person_seq" TO xvesela00;
GRANT ALL ON "operation_log_seq" TO xvesela00;
GRANT EXECUTE ON "ProcessSale" TO xvesela00;
GRANT EXECUTE ON "GenerateStockReport" TO xvesela00;