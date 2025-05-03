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