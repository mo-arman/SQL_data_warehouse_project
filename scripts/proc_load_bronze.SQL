/* ===================================================================================================
   Script Purpose:
   -----------------------------------------------------------------------------------
   This stored procedure loads the BRONZE layer in a Data Warehouse environment by:
   - Truncating staging tables in the 'bronze' schema
   - Inserting data into them via BULK INSERT from local CSV source files
   - Tracking time taken for each table load and total batch duration

   Usage:
   -----------------------------------------------------------------------------------
   EXEC bronze.load_bronze;

   ⚠️ WARNING:
   -----------------------------------------------------------------------------------
   - This procedure uses TRUNCATE, so all existing data in 'bronze' tables will be permanently deleted.
   - The source CSV file paths must be accessible by the SQL Server service.
   - Make sure file formats and delimiters match the expected schema.
================================================================================================== */

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;

    BEGIN TRY
        SET @batch_start_time = GETDATE();

        PRINT '=================================================================================';
        PRINT 'LOADING BRONZE LAYER';
        PRINT '=================================================================================';

        PRINT '-----------------------------------------------------------------------------------';
        PRINT 'LOADING CRM TABLES';
        PRINT '-----------------------------------------------------------------------------------';

        -- CRM Customer Info
        SET @start_time = GETDATE();
        PRINT '>> TRUNCATING TABLE: bronze.crm_cust_info';
        TRUNCATE TABLE bronze.crm_cust_info;

        PRINT '>> INSERTING TABLE : bronze.crm_cust_info';
        BULK INSERT bronze.crm_cust_info
        FROM 'C:\Users\91884\OneDrive\Documents\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            -- ROWTERMINATOR = '\n',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> LOAD DURATION: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '---------------------------------------------------------------------------------------';

        -- CRM Product Info
        SET @start_time = GETDATE();
        PRINT '>> TRUNCATING TABLE: bronze.crm_prd_info';
        TRUNCATE TABLE bronze.crm_prd_info;

        PRINT '>> INSERTING TABLE : bronze.crm_prd_info';
        BULK INSERT bronze.crm_prd_info
        FROM 'C:\Users\91884\OneDrive\Documents\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> LOAD DURATION: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '---------------------------------------------------------------------------------------';

        -- CRM Sales Details
        SET @start_time = GETDATE();
        PRINT '>> TRUNCATING TABLE : bronze.crm_sales_deatils';
        TRUNCATE TABLE bronze.crm_sales_details;

        PRINT '>> INSERTING TABLE : bronze.crm_sales_details';
        BULK INSERT bronze.crm_sales_details
        FROM 'C:\Users\91884\OneDrive\Documents\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> LOAD DURATION: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '---------------------------------------------------------------------------------------';

        PRINT '-----------------------------------------------------------------------------------';
        PRINT 'LOADING ERP TABLES';
        PRINT '-----------------------------------------------------------------------------------';

        -- ERP Customer Table
        SET @start_time = GETDATE();
        PRINT '>> TRUNCATING TABLE : bronze.erp_cust_az12';
        TRUNCATE TABLE bronze.erp_cust_az12;

        PRINT '>> INSERTING TABLE : bronze.erp_cust_az12';
        BULK INSERT bronze.erp_cust_az12
        FROM 'C:\Users\91884\OneDrive\Documents\sql-data-warehouse-project\datasets\source_erp\cust_az12.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> LOAD DURATION: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '---------------------------------------------------------------------------------------';

        -- ERP Location Table
        SET @start_time = GETDATE();
        PRINT '>> TRUNCATING TABLE : bronze.erp_loc_a101';
        TRUNCATE TABLE bronze.erp_loc_a101;

        PRINT '>> INSERTING TABLE : bronze.erp_loc_a101';
        BULK INSERT bronze.erp_loc_a101
        FROM 'C:\Users\91884\OneDrive\Documents\sql-data-warehouse-project\datasets\source_erp\loc_a101.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> LOAD DURATION: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '---------------------------------------------------------------------------------------';

        -- ERP Product Category Table
        SET @start_time = GETDATE();
        PRINT '>> TRUNCATING TABLE : bronze.erp_px_cat_g1v2';
        TRUNCATE TABLE bronze.erp_px_cat_g1v2;

        PRINT '>> INSERTING TABLE : bronze.erp_px_cat_g1v2';
        BULK INSERT bronze.erp_px_cat_g1v2
        FROM 'C:\Users\91884\OneDrive\Documents\sql-data-warehouse-project\datasets\source_erp\px_cat_g1v2.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> LOAD DURATION: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '---------------------------------------------------------------------------------------';

        -- Total Duration
        SET @batch_end_time = GETDATE();
        PRINT '=================================================';
        PRINT 'LOADING BRONZE LAYER IS COMPLETED';
        PRINT '   - TOTAL LOAD DURATION: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
        PRINT '=================================================';

    END TRY
    BEGIN CATCH
        PRINT '=================================================';
        PRINT 'ERROR OCCURRED DURING LOADING BRONZE LAYER';
        PRINT 'ERROR MESSAGE: ' + CAST(ERROR_MESSAGE() AS NVARCHAR);
        PRINT 'ERROR NUMBER : ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'ERROR STATE  : ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '=================================================';
    END CATCH
END
