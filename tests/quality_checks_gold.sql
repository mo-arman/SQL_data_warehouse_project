-- =====================================================================================
-- SCRIPT PURPOSE & USAGE
-- =====================================================================================
-- 📌 PURPOSE:
-- This script creates core views in the Gold Layer of the Data Warehouse.
-- These views convert Silver Layer data into analytics-ready dimensions and facts.
--
-- 🧠 USAGE:
-- - Execute in SQL Server to materialize business-level datasets.
-- - Automatically handles existing views with safe DROP operations.
-- - Applies data quality checks and filters for reliable reporting.
--
-- 🎯 TABLES CREATED:
-- 1. gold.dim_customers
-- 2. gold.dim_products
-- 3. gold.fact_sales
--
-- =====================================================================================
-- ✅ DATA QUALITY, CONSISTENCY & STANDARDIZATION CHECKS
-- =====================================================================================
-- 🔍 dim_customers
-- - Used `ROW_NUMBER()` to generate a consistent surrogate key (customer_key).
-- - Gender fallback logic: If CRM gender is 'N/A', fallback to ERP's gender field.
-- - LEFT JOINs used to preserve all CRM records even if ERP values are missing.
--
-- 🔍 dim_products
-- - `prd_end_dt IS NULL` filters out inactive/historical products to ensure only current data is exposed.
-- - Uses `ROW_NUMBER()` for surrogate key generation based on product start date and key.
-- - Joins category and subcategory details from reference table with `LEFT JOIN`.
--
-- 🔍 fact_sales
-- - Foreign keys (`product_key`, `customer_key`) ensured via JOINs with Gold Dimensions.
-- - LEFT JOINs used so that missing references don’t exclude valid sales records.
-- - Price, quantity, and sales_amount directly mapped from transactional Silver data.
--
-- All views are business-trusted and model-ready for BI tools, dashboards, or advanced analytics.
-- =====================================================================================



-- =====================================================================================
-- 1️⃣ gold.dim_customers
-- Purpose: Customer Dimension enriched with demographic and geographic data
-- =====================================================================================
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key,
    ci.cst_id AS customer_id,
    ci.cst_key AS customer_number,
    ci.cst_firstname AS first_name,
    ci.cst_lastname AS last_name,
    la.cntry AS country,
    ci.cst_material_status AS marital_status,
    CASE 
        WHEN ci.cst_gndr != 'N/A' THEN ci.cst_gndr
        ELSE COALESCE(ca.gen, 'N/A') -- CRM is master, fallback on ERP
    END AS gender,
    ca.bdate AS birthdate,
    ci.cst_create_date AS create_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la ON ci.cst_key = la.cid;
GO



-- =====================================================================================
-- 2️⃣ gold.dim_products
-- Purpose: Product Dimension with category, pricing, and availability metadata
-- =====================================================================================
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products AS
SELECT
    ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key,
    pn.prd_id AS product_id,
    pn.prd_key AS product_number,
    pn.prd_nm AS product_name,
    pn.cat_id AS category_id,
    pc.cat AS category,
    pc.subcat AS subcategory,
    pc.maintenance AS maintenance_required,
    pn.prd_cost AS cost,
    pn.prd_line AS product_line,
    pn.prd_start_dt AS start_date
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc ON pn.cat_id = pc.id
WHERE pn.prd_end_dt IS NULL; -- ✅ Only active products (quality check)
GO



-- =====================================================================================
-- 3️⃣ gold.fact_sales
-- Purpose: Transactional sales fact table for analytics and reporting
-- =====================================================================================
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO

CREATE VIEW gold.fact_sales AS
SELECT
    sd.sls_ord_num AS order_number,
    pr.product_key,
    cu.customer_key,
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt AS shipping_date,
    sd.sls_due_dt AS due_date,
    sd.sls_sales AS sales_amount,
    sd.sls_quantity AS quantity,
    sd.sls_price AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cu ON sd.sls_cust_id = cu.customer_id;
GO
