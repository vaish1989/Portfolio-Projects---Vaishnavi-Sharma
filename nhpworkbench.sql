-- Find data set in the repository 'Nashville Housing Data for Data Cleaning.xlsx' or through this URL: https://www.kaggle.com/tmthyjames/nashville-housing-data
use vaishnavi1;
CREATE TABLE `vaishnavi1`.`nashvillehousingdata` (
  `UniqueID` INT NOT NULL,
  `ParcelID` VARCHAR(45) NULL,
  `LandUse` VARCHAR(45) NULL,
  `PropertyAddress` VARCHAR(255) NULL,
  `SaleDate` datetime NULL,
  `SalePrice` DOUBLE NULL,
  `LegalReference` VARCHAR(50) NULL,
  `SoldAsVacant` VARCHAR(10) NULL,
  `OwnerName` VARCHAR(150) NULL,
  `OwnerAddress` VARCHAR(255) NULL,
  `Acreage` FLOAT NULL,
  `TaxDistrict` VARCHAR(45) NULL,
  `LandValue` INT NULL,
  `BuildingValue` DOUBLE NULL,
  `TotalValue` DOUBLE NULL,
  `YearBuilt` INT NULL,
  `Bedrooms` VARCHAR(45) NULL,
  `FullBath` INT NULL,
  `HalfBath` INT NULL,
  PRIMARY KEY (`UniqueID`));

-- Import Data using Table Data Import Wizard.
SHOW tables;
DESC nashvillehousingdata;
SELECT count(*) from nashvillehousingdata;
SELECT * FROM nashvillehousingdata limit 10;
-- DROP table nashvillehousingdata;

-- || DATA CLEANING ||

-- creating a stored procedure to print sample of desired size.
DELIMITER && 
CREATE PROCEDURE printsample (smplsize int)
BEGIN 
	SELECT * FROM nashvillehousingdata
	ORDER BY RAND()
	LIMIT smplsize; 
END &&
DELIMITER ;

CALL printsample(3);

-- we see 'SaleDate' column is of datetime datatype. The time part is useless as there is no time data. 
-- we will convert Saledate datatype to date
SELECT SaleDate, CAST(SaleDate AS date) FROM nashvillehousingdata
ORDER BY RAND()
LIMIT 5;

-- creating new column 'SaleDateconverted'
ALTER table nashvillehousingdata
ADD SaleDateconverted Date;

-- updating Saledateconverted
SET SQL_SAFE_UPDATES = 0;
UPDATE nashvillehousingdata
SET SaleDateconverted = CAST(SaleDate AS date);
CALL printsample (5);

-- counting null values per column.
SELECT 
	SUM(CASE WHEN UniqueID IS NULL OR UniqueID = 'NULL' THEN 1 ELSE 0 END) null_count_UniqueID,
    SUM(CASE WHEN ParcelID IS NULL THEN 1 ELSE 0 END) null_count_ParcelID,
    SUM(CASE WHEN PropertyAddress IS NULL OR PropertyAddress = 'NULL' THEN 1 ELSE 0 END) null_count_PropertyAddress,
    SUM(CASE WHEN SaleDateconverted IS NULL THEN 1 ELSE 0 END) null_count_SaleDateconverted,
    SUM(CASE WHEN SalePrice IS NULL THEN 1 ELSE 0 END) null_count_SalePrice
FROM nashvillehousingdata;

-- PropertyAddress has a number of NULL values.  
SELECT * FROM nashvillehousingdata
WHERE PropertyAddress IS NULL or PropertyAddress LIKE '%NULL%';

-- One way to clean these NULL values from PropertyAddress is using 'SELF JOIN'. We see that there are many rows that do not 
-- have Property Address, but they have a matching ParcelID. Since same Parcel cannot be given at different locations, both the rows have to 
-- have the same property address.  
SELECT * FROM nashvillehousingdata
ORDER BY ParcelID;

-- self joining the table to itself.

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM nashvillehousingdata a JOIN nashvillehousingdata b
ON a.ParcelID = b.ParcelID 
AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, IFNULL(a.PropertyAddress, b.PropertyAddress)
FROM nashvillehousingdata a JOIN nashvillehousingdata b
ON a.ParcelID = b.ParcelID 
AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;

UPDATE nashvillehousingdata a JOIN nashvillehousingdata b
ON a.ParcelID = b.ParcelID 
AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = IFNULL(a.PropertyAddress, b.PropertyAddress)
WHERE a.PropertyAddress IS NULL;

-- Checking if all NULLS from PropertyAddress are cleaned. 
SELECT 
    SUM(CASE WHEN PropertyAddress IS NULL OR PropertyAddress = 'NULL' THEN 1 ELSE 0 END) null_count_PropertyAddress
FROM nashvillehousingdata;

-- Breaking down PropertyAddress into different columns.

SELECT PropertyAddress
FROM nashvillehousingdata;

SELECT
SUBSTRING(PropertyAddress, 1, POSITION(',' IN PropertyAddress)-1) AS PropertyAddressline1,
SUBSTRING(PropertyAddress, POSITION(',' IN PropertyAddress)+1, length(PropertyAddress)) AS PropertyAddressCity
FROM nashvillehousingdata;

-- Adding two new columns and storing PropertyAddressline1 and PropertyAddressCity in them.
ALTER table nashvillehousingdata
ADD PropertyAddressline1 nvarchar(150);

UPDATE nashvillehousingdata
SET PropertyAddressline1 = SUBSTRING(PropertyAddress, 1, POSITION(',' IN PropertyAddress)-1);

ALTER table nashvillehousingdata
ADD PropertyAddressCity nvarchar(100);

UPDATE nashvillehousingdata
SET PropertyAddressCity = SUBSTRING(PropertyAddress, POSITION(',' IN PropertyAddress)+1, length(PropertyAddress));

CALL printsample(5);

--  Breaking down OwnerAddress into different columns the function SUBSTRING_INDEX().
SELECT substring_index(OwnerAddress, ',', 1) AS OwnerAddressline1,
SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2),',', -1) AS OwnerAddressCity,
substring_index(OwnerAddress, ',', -1) AS OwnerAddressState
FROM nashvillehousingdata;

-- Adding three new columns and storing OwnerAddressline1, OwnerAddressCity and OwnerAddressState in them.
ALTER table nashvillehousingdata
ADD OwnerAddressline1 nvarchar(150);

SET SQL_SAFE_UPDATES = 0;
UPDATE nashvillehousingdata
SET OwnerAddressline1 = substring_index(OwnerAddress, ',', 1);

ALTER table nashvillehousingdata
ADD OwnerAddressCity nvarchar(150);

UPDATE nashvillehousingdata
SET OwnerAddressCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2),',', -1);

ALTER table nashvillehousingdata
ADD OwnerAddressState nvarchar(150);

UPDATE nashvillehousingdata
SET OwnerAddressState = substring_index(OwnerAddress, ',', -1);

CALL printsample(10);

-- Cleaning the 'SoldAsVacant' column.
SELECT SoldAsVacant, COUNT(SoldAsVacant) 
FROM nashvillehousingdata
GROUP BY SoldAsVacant;

-- There are many 'Y' and 'N' that can be replaced with 'Yes' and 'No' respectively.
SELECT SoldAsVacant, (CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						   WHEN SoldAsVacant = 'N' THEN 'No'
                           ELSE SoldAsVacant
                           END) AS SoldAsVacantCleaned
FROM nashvillehousingdata;

UPDATE nashvillehousingdata
SET SoldAsVacant = (CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						 WHEN SoldAsVacant = 'N' THEN 'No'
						 ELSE SoldAsVacant
						 END);

SELECT SoldAsVacant, COUNT(SoldAsVacant) 
FROM nashvillehousingdata
GROUP BY SoldAsVacant;

-- Removing Duplicates
-- Looking for duplicated data (i.e., data with different UniqueID but exact same ParcelID, LandUse, PropertyAddress, SaleDate, etc...) using CTEs.
WITH Duplicates AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) duplicate_cnt

From nashvillehousingdata
)
Select *
From Duplicates
WHERE duplicate_cnt > 1;                  

-- Deleting dupplicated data.
DELETE 
FROM nashvillehousingdata
WHERE UniqueID IN (
WITH Duplicates AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) duplicate_cnt

From nashvillehousingdata
)
SELECT UniqueID
From Duplicates
WHERE duplicate_cnt > 1);
-- All duplicate rows are deleted.

-- Deleting unnecessary columns.
-- List of unwanted columns: PropertyAddress, SaleDate, OwnerAddress, TaxDistrict.
ALTER table nashvillehousingdata
DROP COLUMN PropertyAddress;

CALL printsample(1);

ALTER table nashvillehousingdata
DROP COLUMN SaleDate;
ALTER table nashvillehousingdata
DROP COLUMN OwnerAddress;
ALTER table nashvillehousingdata
DROP COLUMN TaxDistrict;

-- Renaming SaleDateconverted to SaleDate. 
ALTER TABLE nashvillehousingdata RENAME COLUMN SaleDateconverted TO SaleDate;

-- THE END -- 
