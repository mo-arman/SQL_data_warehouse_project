/*==================================================================
  SCRIPT NAME  : Silver Layer ETL Scripts
  PURPOSE      : Inserts cleaned and standardized data from Bronze layer 
                 to Silver layer tables using best practices.

                 Includes:
                 - Data cleansing (trimming, type casting, validation)
                 - Transformation (standardization, derived columns)
                 - Deduplication

  TARGET TABLES: 
                 1. silver.crm_cust_info
                 2. silver.crm_prd_info
                 3. silver.crm_sales_details
                 4. silver.erp_cust_az12
                 5. silver.erp_loc_a101
                 6. silver.erp_px_cat_g1v2
  AUTHOR       : Mohammad Arman
  WARNING      : Ensure Bronze tables are loaded and validated before execution
===================================================================*/

-- === Table: silver.crm_cust_info ===
-- ✅ Deduplicated on cst_id using ROW_NUMBER
-- ✅ Trimmed names and standardized gender/material status
-- ✅ Ensured no NULL cst_id rows entered

INSERT INTO silver.crm_cust_info (
  cst_id,
  cst_key,
  cst_firstname,
  cst_lastname,
  cst_material_status,
  cst_gndr,
  cst_create_date
)
SELECT
  cst_id,
  cst_key,
  TRIM(cst_firstname),
  TRIM(cst_lastname),
  CASE 
    WHEN UPPER(TRIM(cst_material_status)) = 'S' THEN 'Single'
    WHEN UPPER(TRIM(cst_material_status)) = 'M' THEN 'Married'
    ELSE 'N/A'
  END,
  CASE 
    WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
    WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
    ELSE 'N/A'
  END,
  cst_create_date
FROM (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
  FROM bronze.crm_cust_info
  WHERE cst_id IS NOT NULL
) t
WHERE flag_last = 1;

-- === Table: silver.crm_prd_info ===
-- ✅ Category ID derived from prd_key
-- ✅ Cleaned product lines into named values
-- ✅ Used LEAD() to compute prd_end_dt

INSERT INTO silver.crm_prd_info (
  prd_id,
  cat_id,
  prd_key,
  prd_nm,
  prd_cost,
  prd_line,
  prd_start_dt,
  prd_end_dt
)
SELECT 
  prd_id,
  REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_'),
  SUBSTRING(prd_key, 7, LEN(prd_key)),
  prd_nm,
  ISNULL(prd_cost, 0),
  CASE UPPER(TRIM(prd_line)) 
    WHEN 'R' THEN 'Road'
    WHEN 'M' THEN 'Mountain'
    WHEN 'S' THEN 'Other Sales'
    WHEN 'T' THEN 'Touring'
    ELSE 'N/A'
  END,
  CAST(prd_start_dt AS DATE),
  CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS DATE)
FROM bronze.crm_prd_info;

-- === Table: silver.crm_sales_details ===
-- ✅ Cleaned date fields with safe parsing
-- ✅ Auto-corrected sls_sales and sls_price
-- ✅ Avoided divide-by-zero using NULLIF

INSERT INTO silver.crm_sales_details (
  sls_ord_num,
  sls_prd_key,
  sls_cust_id,
  sls_order_dt,
  sls_ship_dt,
  sls_due_dt,
  sls_sales,
  sls_quantity,
  sls_price
)
SELECT 
  sls_ord_num,
  sls_prd_key,
  sls_cust_id,
  CASE 
    WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
    ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
  END,
  CASE 
    WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
    ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
  END,
  CASE 
    WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
    ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
  END,
  CASE 
    WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
      THEN sls_quantity * ABS(sls_price)
    ELSE sls_sales
  END,
  sls_quantity,
  CASE 
    WHEN sls_price IS NULL OR sls_price <= 0 
      THEN sls_sales / NULLIF(sls_quantity, 0)
    ELSE sls_price
  END
FROM bronze.crm_sales_details;

-- === Table: silver.erp_cust_az12 ===
-- ✅ Removed 'NAS' prefix
-- ✅ Replaced invalid bdate (future dates) with NULL
-- ✅ Normalized gender values

INSERT INTO silver.erp_cust_az12 (
  cid,
  bdate,
  gen
)
SELECT
  CASE 
    WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
    ELSE cid
  END,
  CASE 
    WHEN bdate > GETDATE() THEN NULL
    ELSE bdate
  END,
  CASE 
    WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
    WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
    ELSE 'N/A'
  END
FROM bronze.erp_cust_az12;

-- === Table: silver.erp_loc_a101 ===
-- ✅ Removed dashes from cid
-- ✅ Standardized country values

INSERT INTO silver.erp_loc_a101 (
  cid,
  cntry
)
SELECT
  REPLACE(cid, '-', ''),
  CASE 
    WHEN TRIM(cntry) = 'DE' THEN 'Germany'
    WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
    WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'N/A'
    ELSE TRIM(cntry)
  END
FROM bronze.erp_loc_a101;

-- === Table: silver.erp_px_cat_g1v2 ===
-- ⚠️ No transformation applied
-- ✅ Checked for trailing spaces and inconsistent values manually

INSERT INTO silver.erp_px_cat_g1v2 (
  id,
  cat,
  subcat,
  maintenance
)
SELECT 
  id,
  cat,
  subcat,
  maintenance
FROM bronze.erp_px_cat_g1v2;
