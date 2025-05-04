# Overview
SQL script for a retail management database.

# Entity Releationship Diargram
![erd-db](docs/ids_erd.jpg)

# Use Case Diagram
![use-case](docs/use_case.png)

# Select Queries and Corresponding Tables
![select_1](docs/select_1.png)
![table_1](docs/table_1.png)
- displays `names` of the products and their `quantity` in stock with `stock id` = 1
---
![select_2](docs/select_2.png)
![table_2](docs/table_2.png)
- displays `name` of each `employee` and `cash register id` that they are operating
---
![select_3](docs/select_3.png)
![table_3](docs/table_3.png)
- displays `invoice id`, `cash register id` and corresponding `store location` for invoices with `type` = `sale`
---
![select_4](docs/select_4.png)
![table_4](docs/table_4.png)
- displays `store location` and `quantity` of all items in that store
---
![select_5](docs/select_5.png)
![table_5](docs/table_5.png)
- displays `invoice id` and `item count` for each product in the invoice
---
![select_6](docs/select_6.png)
![table_6](docs/table_6.png)
- displays `name` and `email` of all `customers` that have invoice with `type` = order
---
![select_7](docs/select_7.png)
![table_7](docs/table_7.png)
- displays `name` and `price` of products in all stores that contain `cash register`
---

# Triggers
![trigger_1](docs/trigger_1.png)
- Reduces the product quantity in a store’s inventory (`StoreContains`) when a sale invoice is created (when products are added to `InvoiceContains` for sale)
- **How it works:**
    - Retrieves the `store_id` from the `CashRegister` linked to the invoice of `type` = 'sale'
    - Checks the current `quantity` in `StoreContains` for the product and store
    - If the requested quantity exceeds available stock, raise a custom error (-20001)
    - Updates `StoreContains.quantity` by subtracting the sold quantity
---
![trigger_2](docs/trigger_2.png)
- Logs employee interactions with cash registers (start or update of operation) in the `OperationLog` table
- **How it works:**
    - Determines the action (Started operating for inserts, Updated operation for updates)
    - Inserts a log entry into `OperationLog`

> [!Note]
> Added `OperationLog` table for possible future updates (logging breaks, sales times, etc.)

# Procedures
Encapsulates bussines logic into reuseable "functions"
![procedure_1](docs/procedure_1.png)
- Processes a new sale by creating an `invoice`, adding `products`, and updating the employee’s `operation record`
- **Parameters:**
    - Cash register ID
    - Employee ID
    - Array of product IDs
- **How it works:**
    - Sets a `SAVEPOINT` for transaction control.
    - Inserts a sale invoice into `Invoice` with current `date`/`time` and `cash_register_id`
    - Uses a cursor to fetch product details, calculates total price, and inserts products into `InvoiceContains`
    - Updates `Operates.finish_time` for the employee and cash register
---
![procedure_2](docs/procedure_2.png)
Generates a report of products in a specified stock, showing quantities and total value
- **Parameters:**
    - Stock ID
- **How it works:**
    - Uses a cursor to fetch product names, quantities, and prices from `StockContains` and `Product`
    - Iterates to print product details and accumulate total value (quantity * price).

# Indexes and EXPLAIN PLAN
Optimize query performance and analyze execution plans
## Indexes
- `IDX_Product_Name` on `Product.name`:
    - Optimizes searches by product name (WHERE name LIKE 'Laptop%').
    - Improves performance for queries filtering products.
- `IDX_StoreContains_Product` on `StoreContains(product_id, store_id)`:
    - Optimizes joins and filters involving `product_id` and `store_id`
    - Targets the `EXPLAIN PLAN` query.

`IDX_StoreContains_Product` before and after compraison:
<div style="display: flex; justify-content: space-around;">
  <img src="/docs/explain_before.png" alt="explain_before" width="49%">
  <img src="/docs/explain_after.png" alt="explain_after" width="49%">
</div>