-- ====================================================================================================
-- Script Name     : silver_layer_loader.sql
-- Layer           : Silver Layer (Cleaned & Deduplicated Data)
-- Author          : Mohammad Arman
-- Purpose         : 
--     This stored procedure (silver.load_silver) is responsible for loading, cleaning, and transforming
--     raw data from the Bronze Layer into well-structured, analytics-ready Silver Layer tables. 
--     It ensures data quality through trimming, deduplication, standardization, and field normalization.
--
--     ✅ Key Transformations:
--       - Deduplicates customer records based on latest create date
--       - Cleans product keys and categorizes product lines
--       - Validates and reconstructs sales values and dates
--       - Normalizes gender and country fields
--       - Tracks batch load execution time for monitoring
--
--     📦 Target Silver Tables:
--       - silver.crm_cust_info
--       - silver.crm_prd_info
--       - silver.crm_sales_details
--       - silver.erp_cust_az12
--       - silver.erp_loc_a101
--       - silver.erp_px_cat_g1v2
--
--     🔁 Execution Logging:
--       - Logs batch start and end time
--       - Calculates total execution duration (in seconds)
--       - Fully automated procedure for pipeline scheduling or manual execution
--
-- Usage:
--     EXEC silver.load_silver;
--
-- Version         : 1.0
-- Last Updated    : 2025-07-03
-- ====================================================================================================


-- ====================================================================================================
-- Initial Trigger to Execute Procedure
-- ====================================================================================================
EXEC silver.load_silver


-- ====================================================================================================
-- Silver Layer Load Procedure Definition
-- ====================================================================================================
CREATE OR ALTER PROCEDURE silver.load_silver
AS
BEGIN
    DECLARE @batch_start_time DATETIME2 = SYSDATETIME();
    PRINT '🌟 Batch Load Started: ' + CAST(@batch_start_time AS NVARCHAR);

    -- ========================================================================================
    -- Load Customer Master Data to silver.crm_cust_info
    -- ========================================================================================
    PRINT '>> Truncating Table: silver.crm_cust_info';
    TRUNCATE TABLE silver.crm_cust_info;

    PRINT '>> Inserting Data Into: silver.crm_cust_info';
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

    -- ========================================================================================
    -- Load Product Master Data to silver.crm_prd_info
    -- ========================================================================================
    PRINT '>> Dropping Table If Exists: silver.crm_prd_info';
    IF OBJECT_ID('silver.crm_prd_info', 'U') IS NOT NULL
        DROP TABLE silver.crm_prd_info;

    PRINT '>> Creating Table: silver.crm_prd_info';
    CREATE TABLE silver.crm_prd_info (
        prd_id INT,
        cat_id NVARCHAR(50),
        prd_key NVARCHAR(50),
        prd_nm NVARCHAR(50),
        prd_cost INT,
        prd_line NVARCHAR(50),
        prd_start_dt DATE,
        prd_end_dt DATE,
        dwh_create_date DATETIME2 DEFAULT GETDATE()
    );

    PRINT '>> Truncating Table: silver.crm_prd_info';
    TRUNCATE TABLE silver.crm_prd_info;

    PRINT '>> Inserting Data Into: silver.crm_prd_info';
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

    -- ========================================================================================
    -- Load CRM Sales Data to silver.crm_sales_details
    -- ========================================================================================
    PRINT '>> Dropping Table If Exists: silver.crm_sales_details';
    IF OBJECT_ID('silver.crm_sales_details', 'U') IS NOT NULL
        DROP TABLE silver.crm_sales_details;

    PRINT '>> Creating Table: silver.crm_sales_details';
    CREATE TABLE silver.crm_sales_details (
        sls_ord_num NVARCHAR(50),
        sls_prd_key NVARCHAR(50),
        sls_cust_id INT,
        sls_order_dt DATE,
        sls_ship_dt DATE,
        sls_due_dt DATE,
        sls_sales INT,
        sls_quantity INT,
        sls_price INT,
        dwh_create_date DATETIME2 DEFAULT GETDATE()
    );

    PRINT '>> Truncating Table: silver.crm_sales_details';
    TRUNCATE TABLE silver.crm_sales_details;

    PRINT '>> Inserting Data Into: silver.crm_sales_details';
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

    -- ========================================================================================
    -- Load ERP Customer Info to silver.erp_cust_az12
    -- ========================================================================================
    PRINT '>> Truncating Table: silver.erp_cust_az12';
    TRUNCATE TABLE silver.erp_cust_az12;

    PRINT '>> Inserting Data Into: silver.erp_cust_az12';
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

    -- ========================================================================================
    -- Load ERP Location Info to silver.erp_loc_a101
    -- ========================================================================================
    PRINT '>> Truncating Table: silver.erp_loc_a101';
    TRUNCATE TABLE silver.erp_loc_a101;

    PRINT '>> Inserting Data Into: silver.erp_loc_a101';
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

    -- ========================================================================================
    -- Load ERP Product Category Info to silver.erp_px_cat_g1v2
    -- ========================================================================================
    PRINT '>> Truncating Table: silver.erp_px_cat_g1v2';
    TRUNCATE TABLE silver.erp_px_cat_g1v2;

    PRINT '>> Inserting Data Into: silver.erp_px_cat_g1v2';
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

    -- ========================================================================================
    -- Batch Completion
    -- ========================================================================================
    DECLARE @batch_end_time DATETIME2 = SYSDATETIME();
    PRINT '✅ Batch Load Completed Successfully: ' + CAST(@batch_end_time AS NVARCHAR);
    PRINT '🕒 Total Execution Time: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
END
