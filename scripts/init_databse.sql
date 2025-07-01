/* ====================================================================================
    Script Name     : Reset_And_Create_DataWarehouse.sql
    Script Purpose  : To reset the 'DataWarehouse' database (if it exists) and 
                      recreate it along with the standard Medallion Architecture schemas:
                      Bronze, Silver, and Gold.

    Author          : Mohammad Arman
    Created Date    : 2025-07-01

    Description     :
        This script performs the following actions:
        1. Checks if a database named 'DataWarehouse' already exists.
        2. If it exists:
            - Forces it into SINGLE_USER mode.
            - Rolls back all open transactions.
            - Drops the database.
        3. Creates a fresh 'DataWarehouse' database.
        4. Defines three schemas inside the database:
            - bronze: Raw data layer
            - silver: Cleaned/transformed data layer
            - gold  : Curated business layer

    ⚠️ WARNING:
        - This script will **permanently delete** the existing 'DataWarehouse' database 
          and all its data.
        - Do NOT run this script in a production environment unless you're absolutely 
          sure about the consequences.
        - Use with caution. Always take a full backup before running this script.

    Suitable For:
        - Dev/Test environments
        - Fresh setup of a data warehouse project
        - Learning/Practice purpose

==================================================================================== */


-- Step 1: Switch to the master database (default system database)
USE master;
GO

IF EXISTS (SELECT 1 FROM sys.databses WHERE name = 'DataWarehouse')
  BEGIN
  ALTER DATABASE DataWarehouse SET SINGLE USER WITH ROLLBACK IMMEDIATE;
DROP DATABSE DataWarehouse;
END;
GO
  
  Step 2: Create a new database named 'DataWarehouse'
CREATE DATABASE DataWarehouse;

-- Step 3: Switch context to the newly created 'DataWarehouse' database
USE DataWarehouse;

-- Step 4: Create a schema named 'bronze'
-- This will store raw or minimally processed data
CREATE SCHEMA bronze;
GO 

-- Step 5: Create a schema named 'silver'
-- This will store cleaned and transformed data
CREATE SCHEMA silver;
GO

-- Step 6: Create a schema named 'gold'
-- This will store business-ready, aggregated, and curated data
CREATE SCHEMA gold;
