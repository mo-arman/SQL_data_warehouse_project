# 📊 Data Catalog for Gold Layer
# Overview
The Gold Layer is the business-level data representation, structured to support analytical and reporting use cases. It consists of dimension tables and fact tables that represent business metrics with clarity and precision.
# 🧍 gold.dim_customers
Purpose: Stores customer details enriched with demographic and geographic data.
| Column Name       | Data Type    | Description                                                                           |
| ----------------- | ------------ | ------------------------------------------------------------------------------------- |
| `customer_key`    | INT          | Surrogate key uniquely identifying each customer record in the dimension table.       |
| `customer_id`     | INT          | Unique numerical identifier assigned to each customer.                                |
| `customer_number` | NVARCHAR(50) | Alphanumeric identifier representing the customer, used for tracking and referencing. |
| `first_name`      | NVARCHAR(50) | The customer's first name, as recorded in the system.                                 |
| `last_name`       | NVARCHAR(50) | The customer's last name or family name.                                              |
| `country`         | NVARCHAR(50) | Country of residence for the customer (e.g., 'Australia').                            |
| `marital_status`  | NVARCHAR(50) | Marital status of the customer (e.g., 'Married', 'Single').                           |
| `gender`          | NVARCHAR(50) | Gender of the customer (e.g., 'Male', 'Female', 'n/a').                               |
| `birthdate`       | DATE         | Date of birth (e.g., 1971-10-06).                                                     |
| `create_date`     | DATE         | Date and time when the customer record was created in the system.                     |

# 📦 gold.dim_products
Purpose: Provides information about the products and their attributes.

| Column Name            | Data Type    | Description                                                  |
| ---------------------- | ------------ | ------------------------------------------------------------ |
| `product_key`          | INT          | Surrogate key uniquely identifying each product record.      |
| `product_id`           | INT          | Unique identifier assigned to the product for tracking.      |
| `product_number`       | NVARCHAR(50) | Alphanumeric product code (e.g., model or SKU).              |
| `product_name`         | NVARCHAR(50) | Name of the product (e.g., type, color, size).               |
| `category_id`          | NVARCHAR(50) | Identifier for the product's category.                       |
| `category`             | NVARCHAR(50) | High-level product classification (e.g., Bikes, Components). |
| `subcategory`          | NVARCHAR(50) | Detailed classification within the category.                 |
| `maintenance_required` | NVARCHAR(50) | Indicates if the product needs maintenance (Yes/No).         |
| `cost`                 | INT          | Cost or base price of the product.                           |
| `product_line`         | NVARCHAR(50) | Specific product series (e.g., Road, Mountain).              |
| `start_date`           | DATE         | Date when the product became available for sale.             |

# 💰 gold.fact_sales
Purpose: Stores transactional sales data for analytical purposes.

| Column Name     | Data Type    | Description                                               |
| --------------- | ------------ | --------------------------------------------------------- |
| `order_number`  | NVARCHAR(50) | Unique identifier for each sales order (e.g., 'SO54496'). |
| `product_key`   | INT          | Foreign key linking to `dim_products`.                    |
| `customer_key`  | INT          | Foreign key linking to `dim_customers`.                   |
| `order_date`    | DATE         | Date when the order was placed.                           |
| `shipping_date` | DATE         | Date when the order was shipped.                          |
| `due_date`      | DATE         | Date when the order payment was due.                      |
| `sales_amount`  | INT          | Total monetary value of the sale.                         |
| `quantity`      | INT          | Number of product units sold.                             |
| `price`         | INT          | Price per unit of the product.                            |
