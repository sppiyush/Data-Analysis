/* Cleaning Data in SQL Queries */

Select*
FROM SQLPractise.dbo.NashvilleHousing

-----------------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format 

Select SaleDate, CONVERT(Date,SaleDate)
FROM SQLPractise.dbo.NashvilleHousing 

--Select SaleDateConverted     -- You run this query when all the data have been altered and updated , don't just run it right now 
--FROM SQLPractise.dbo.NashvilleHousing 

-- Converting the date into SQL date format (Part of Cleaning the data) 
Update SQLPractise.dbo.NashvilleHousing 
SET SaleDate = CONVERT(Date,SaleDate)

-- We will create a new column in the table having date datatype 
ALTER TABLE NashvilleHousing  
Add SaleDateConverted Date;

-- Now putting the updated data in the new column 
Update NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)


----------------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address Data 

Select * 
FROM SQLPractise.dbo.NashvilleHousing 
--WHERE PropertyAddress is null
ORDER BY ParcelID

--This is the use of ISNULL() ,  if the value of a.PropertyAddress is Null then it will popualate that with b.Propertyaddress value
Select a.ParcelID,a.PropertyAddress,b.ParcelID,b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress) 
FROM SQLPractise.dbo.NashvilleHousing a  --we have to join the table by itself 
JOIN SQLPractise.dbo.NashvilleHousing b
    ON a.ParcelID = b.ParcelID
    AND a.[UniqueID] <> b.[UniqueID] -- Where the unique must not be same in order to stop the duplicacy of rows 
WHERE a.PropertyAddress is null

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)  
FROM SQLPractise.dbo.NashvilleHousing a
JOIN SQLPractise.dbo.NashvilleHousing b
    ON a.ParcelID = b.ParcelID
    AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress is null 

-------------------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into individual Columns (Address,City,State)

Select PropertyAddress
FROM SQLPractise.dbo.NashvilleHousing 

Select 
SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) AS Address,  -- Use of '-1' is we are going to the comma and we are going on back to comma because this substring gives numbers (x-1)
--CHARINDEX(',',PropertyAddress)
SUBSTRING(PropertyAddress,CHARINDEX(',', PropertyAddress ) +1 , LEN(PropertyAddress)) AS Address 
FROM SQLPractise.dbo.NashvilleHousing 

ALTER TABLE NashvilleHousing 
Add PropertySplitAddress Nvarchar(255);

Update NashvilleHousing 
SET PropertySplitAddress = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress) -1) 

ALTER TABLE NashvilleHousing 
Add PropertySplitCity Nvarchar(255);

Update NashvilleHousing 
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) +1 , LEN(PropertyAddress))

Select * 
FROM SQLPractise.dbo.NashvilleHousing 

Select OwnerAddress
FROM SQLPractise.dbo.NashvilleHousing 

-- Using ParseName is super easy compared to using SUSBTRING for splitting the values

SELECT 
PARSENAME(REPLACE(OwnerAddress, ',' , '.') , 3),  --It goes backwards so we are using 3,2,1
PARSENAME(REPLACE(OwnerAddress, ',','.'),2),
PARSENAME(REPLACE(OwnerAddress, ',','.'),1)
FROM SQLPractise.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing 
Add OwnerSplitAddress Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3)

ALTER TABLE NashvilleHousing 
Add OwnerSplitCity Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)

ALTER TABLE NashvilleHousing 
Add OwnerSplitState Nvarchar(255);

UPDATE NashvilleHousing 
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

Select * 
FROM SQLPractise.dbo.NashvilleHousing 

-----------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field

Select DISTINCT (SoldAsVacant), COUNT(SoldAsVacant)
From SQLPractise.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2


SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
  WHEN SoldAsVacant = 'N' THEN 'No'
  ELSE SoldAsVacant
  END
FROM SQLPractise.dbo.NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END 

Select * 
FROM SQLPractise.dbo.NashvilleHousing

-------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

-- It's not a standard practise to delete data from the database so we will use CTEs

WITH RowNumCTE AS(
Select *,
    ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
	             PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
				     UniqueID
					 ) row_num

FROM SQLPractise.dbo.NashvilleHousing 
--Order By ParcelID
)
Select *
FROM RowNumCTE
WHERE row_num > 1
Order by PropertyAddress


-- If you have to delete these , you can use the following queries and copy the whole CTE query 
DELETE 
FROM RowNumCTE
WHERE row_num > 1

--------------------------------------------------------------------------------------------------------------

-- Delete Unused Columns 

Select *
FROM SQLPractise.dbo.NashvilleHousing


 ALTER TABLE SQLPractise.dbo.NashvilleHousing 
 DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress 


 ALTER TABLE SQLPractise.dbo.NashvilleHousing 
 DROP COLUMN SaleDate







 -----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

--- Importing Data using OPENROWSET and BULK INSERT	

--  More advanced and looks cooler, but have to configure server appropriately to do correctly


--sp_configure 'show advanced options', 1;
--RECONFIGURE;
--GO
--sp_configure 'Ad Hoc Distributed Queries', 1;
--RECONFIGURE;
--GO


--USE SQLPractise 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1 

--GO 


---- Using BULK INSERT

--USE SQLPractise;
--GO
--BULK INSERT nashvilleHousing FROM 'C:\Temp\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv'
--   WITH (
--      FIELDTERMINATOR = ',',
--      ROWTERMINATOR = '\n'
--);
--GO


---- Using OPENROWSET
--USE SQLPractise;
--GO
--SELECT * INTO nashvilleHousing
--FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
--    'Excel 12.0; Database=C:\Users\alexf\OneDrive\Documents\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv', [Sheet1$]);
--GO












