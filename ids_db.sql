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
    "contact" VARCHAR2(100) CONSTRAINT "Person_contact_check" CHECK (REGEXP_LIKE("contact", '^+[0-9]{12}$')),
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
