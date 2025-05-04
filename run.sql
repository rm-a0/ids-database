SET SERVEROUTPUT ON;

--------------------------
-- Materialized View --
--------------------------

-- Drop the materialized view before testing
DROP MATERIALIZED VIEW "StoreInventory_MV";

-- Create materialized view as xvesela00
-- Execute as xvesela00
CREATE MATERIALIZED VIEW "StoreInventory_MV"
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
AS
SELECT s."id" AS "store_id", s."location", p."id" AS "product_id", p."name", sc."quantity"
FROM xrepcim00."Store" s
JOIN xrepcim00."StoreContains" sc ON s."id" = sc."store_id"
JOIN xrepcim00."Product" p ON sc."product_id" = p."id";

-- Grant permissions on materialized view (execute as xvesela00)
GRANT SELECT ON "StoreInventory_MV" TO xrepcim00;

------------------------------------------
-- Complex SELECT with WITH and CASE --
------------------------------------------

-- Analyzes sales performance by store
-- Returns total sales value per store, categorized as High, Medium, or Low
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
-- Demonstration of Triggers and Procedures --
-------------------------------------------------

-- Trigger 1: UpdateStockOnSale
DECLARE
    v_invoice_id NUMBER;
BEGIN
    INSERT INTO "Invoice" (
        "id", "time", "date", "type", "cash_register_id"
    ) VALUES (
        "invoice_seq".NEXTVAL, '2025-03-29T10:00:00Z', '2025-03-29', 'sale', 1
    ) RETURNING "id" INTO v_invoice_id;

    INSERT INTO "InvoiceContains" (
        "invoice_id", "product_id", "quantity"
    ) VALUES (
        v_invoice_id, (SELECT "id" FROM "Product" WHERE "name" = 'Laptop'), 5
    );

    DBMS_OUTPUT.PUT_LINE('Inserted invoice ID: ' || v_invoice_id);
END;
/

-- Check stock reduction
SELECT "quantity"
FROM "StoreContains"
WHERE "store_id" = 1 AND "product_id" = (SELECT "id" FROM "Product" WHERE "name" = 'Laptop');

-- Trigger 2: LogCashRegisterOperation
INSERT INTO "Operates" (
    "person_id", "cash_register_id", "start_time", "finish_time"
) VALUES (
    3, 1, '2025-03-29T08:00:00Z', '2025-03-29T16:00:00Z'
);

-- Check log
SELECT * FROM "OperationLog";

-- Procedure 1: ProcessSale
BEGIN
    "ProcessSale"(p_cash_register_id => 1, p_employee_id => 3, p_products => SYS.ODCINUMBERLIST(1, 2));
END;
/

-- Procedure 2: GenerateStockReport
BEGIN
    "GenerateStockReport"(p_stock_id => 1);
END;
/

---------------------------------
-- Transactional Processing --
---------------------------------

-- Demonstrate atomicity with concurrent stock updates
DECLARE
    v_product_id "Product"."id"%TYPE;
BEGIN
    SELECT "id" INTO v_product_id
    FROM "Product"
    WHERE "name" = 'Laptop';

    SAVEPOINT start_transaction;

    UPDATE "StoreContains"
    SET "quantity" = "quantity" - 10
    WHERE "store_id" = 1 AND "product_id" = v_product_id;

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

-- Refresh materialized view manually
-- BEGIN
--     DBMS_MVIEW.REFRESH('StoreInventory_MV');
-- END;
-- /

-- Test Materialized View (execute as xvesela00)
SELECT * FROM "StoreInventory_MV" WHERE "quantity" > 50;
SELECT * FROM "Operates";

-- Test Procedures (execute as xvesela00)
-- Note: Run the procedures alone for it to work correctly, otherwise it lock up
-- CALL xrepcim00."ProcessSale"(1, 3, SYS.ODCINUMBERLIST(1, 2));
-- CALL xrepcim00."GenerateStockReport"(1);