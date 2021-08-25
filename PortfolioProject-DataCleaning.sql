create table Nashville_housing(
	UniqueID 	int,
	ParcelID	varchar(255),
	LandUse	varchar(255),
	PropertyAddress	varchar(255),
	SaleDate	timestamp,
	SalePrice	int,
	LegalReference	varchar(255),
	SoldAsVacant varchar(255),	
	OwnerName	varchar(255),
	OwnerAddress	varchar(255),
	Acreage	float,
	TaxDistrict	varchar(255),
	LandValue	int,
	BuildingValue	int,
	TotalValue	int,
	YearBuilt	int,
	Bedrooms	int,
	FullBath	int,
	HalfBath int
)
COPY Nashville_housing from 'C:\Users\Sunil\Downloads\Data_Cleaning.csv' delimiter ',' csv header;


--Cleaning Data in SQL
select * from Nashville_housing


--Standardize Date Format
alter table Nashville_housing
add saledateconverted date;

update Nashville_housing
set saledateconverted = cast(saledate as date)

select saledate, saledateconverted
from Nashville_housing


--Populate Property and Address Data
select *
from Nashville_housing
where propertyaddress is null
order by parcelid
  /*Same ParcelIDs will have the same address. So we can populate the values of the address 
    if the the corresponding ParcelID has been repeated before and that ParcelID has an address */
 
 --Run after running the query below
select a.parcelid, a.propertyaddress, b.parcelid, b.propertyaddress, coalesce(a.propertyaddress, b.propertyaddress)
from Nashville_housing a
join Nashville_housing b
on a.parcelid= b.parcelid
and a.uniqueid <> b.uniqueid --The rows must have different unique IDs
where a.propertyaddress is null --We get rows where parcelid is repeated, and the address is present in one row but not the other, so we can just copy the address and paste it in the row where its missing
 --Returns empty table because there are no null values. If you remove the last condition, all values are displayed.

 --Run this first
update Nashville_housing
set propertyaddress = coalesce(a.propertyaddress, b.propertyaddress) --as 'PopulatedPropertyAddress'
from Nashville_housing a
join Nashville_housing b
on a.parcelid= b.parcelid
and a.uniqueid <> b.uniqueid 
where a.propertyaddress is null


--Splitting the Address column into different columns

 --How to split the columns?
 
 /*
select 
substring(propertyaddress, 1, position(',' in propertyaddress)-1) as Address  --We are taking the 1st position when separated by delimiter which is ','
  --We do -1 to remove the comma from the final output
,substring(propertyaddress, position(',' in propertyaddress)+1, length(propertyaddress)) as City
from Nashville_housing
 --Syntax of substring- substring(column, starting pos from where we want the substring , ending pos)
*/

  --Lets add the columns
alter table Nashville_housing
add Address varchar(255);

update Nashville_housing
set Address = substring(propertyaddress, 1, position(',' in propertyaddress)-1)

alter table Nashville_housing
add City varchar(255);

update Nashville_housing
set City = substring(propertyaddress, position(',' in propertyaddress)+1, length(propertyaddress))


--Lets split the owner address details now.

 /*Split using split_part
select
SPLIT_PART(owneraddress,',', 1), --Splits on ',' and returns the 1st pos
SPLIT_PART(owneraddress,',', 2),
SPLIT_PART(owneraddress,',', 3)
from Nashville_housing
*/
 --Now lets add these 3 columns
alter table Nashville_housing
add OwnerAddressSplit varchar(255);

update Nashville_housing
set OwnerAddressSplit = SPLIT_PART(owneraddress,',', 1)

alter table Nashville_housing
add OwnerCity varchar(255);

update Nashville_housing
set OwnerCity = SPLIT_PART(owneraddress,',', 2)

alter table Nashville_housing
add OwnerState varchar(255);

update Nashville_housing
set OwnerState = SPLIT_PART(owneraddress,',', 3)


--Change Y and N to Yes and No in "Sold as Vacant" field
Select distinct soldasvacant
from Nashville_housing

/*
select soldasvacant,
case when soldasvacant ='Y' then 'Yes'
     when soldasvacant ='N' then 'No'
	 else soldasvacant
	 end
from Nashville_housing
*/
 --Lets Update it
update Nashville_housing
set soldasvacant = case when soldasvacant ='Y' then 'Yes'
     when soldasvacant ='N' then 'No'
	 else soldasvacant
	 end
	 
	 
--Remove Duplicates

with RowNumCTE as(
select *,
 row_number() over( partition by parcelid, propertyaddress, saleprice, saledate, legalreference
				   order by uniqueid) rownum
from Nashville_housing
)
delete
from RowNumCTE
where rownum > 1  --Gives a count of ones repeated more than once, i.e duplicates


--Delete unused columns
 --Lets delete the property address, owner address and tax district
alter table Nashville_housing
drop column owneraddress, 
drop column taxdistrict, 
drop column propertyaddress
