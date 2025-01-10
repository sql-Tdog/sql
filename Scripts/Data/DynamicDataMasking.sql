/*Applies to SQL Azure and SQL 2016+*************************************************************************************
Permissions
You do not need any special permission to create a table with a dynamic data mask, only the standard CREATE TABLE and ALTER on schema permissions.
Adding, replacing, or removing the mask of a column, requires the ALTER ANY MASK permission and ALTER permission on the table. 
It is appropriate to grant ALTER ANY MASK to a security officer.
Users with SELECT permission on a table can view the table data. Columns that are defined as masked, will display the masked data. 
Grant the UNMASK permission to a user to enable them to retrieve unmasked data from the columns for which masking is defined.
The CONTROL permission on the database includes both the ALTER ANY MASK and UNMASK permission.

Best Practices and Common Use Cases
Creating a mask on a column does not prevent updates to that column. So although users receive masked data when querying the masked column, the same users can update 
the data if they have write permissions. A proper access control policy should still be used to limit update permissions.
Using SELECT INTO or INSERT INTO to copy data from a masked column into another table results in masked data in the target table.
Dynamic Data Masking is applied when running SQL Server Import and Export. A database containing masked columns will result in a backup file with masked data 
(assuming it is exported by a user without UNMASK privileges), and the imported database will contain statically masked data.

Querying for Masked Columns
Use the sys.masked_columns view to query for table-columns that have a masking function applied to them. This view inherits from the sys.columns view. 
It returns all columns in the sys.columns view, plus the is_masked and masking_function columns, indicating if the column is masked, and if so, what masking function is defined. 
This view only shows the columns on which there is a masking function applied.

*/

SELECT c.name, tbl.name as table_name, c.is_masked, c.masking_function 
FROM sys.masked_columns AS c 
JOIN sys.tables AS tbl  
  ON c.[object_id] = tbl.[object_id] 
WHERE is_masked = 1; 

/*
A masking rule cannot be defined for the following column types:
    Encrypted columns (Always Encrypted)
    FILESTREAM
    COLUMN_SET or a sparse column that is part of a column set.
    A mask cannot be configured on a computed column, but if the computed column depends on a column 
    with a MASK, then the computed column will return masked data.
    A column with data masking cannot be a key for a FULLTEXT index.

USE test
GO
ALTER TABLE DDM ALTER COLUMN email ADD MASKED WITH (FUNCTION='email()')

ALTER TABLE DDM ADD Phone varchar(12) MASKED WITH (FUNCTION='default()') NULL

select * FROM DDM;


*/