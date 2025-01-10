/**
----***Enable Ad Hoc Distributed Queries***********
1.  Install AccessDatabaseEngine_x64.exe on the server first

2.  Change configurations:

    sp_configure 'show advanced options',1  
    reconfigure  
	go
    sp_configure 'Ad Hoc Distributed Queries',1
	reconfigure

	USE [master]
	GO

	EXEC master . dbo. sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0' , N'AllowInProcess' , 1
	GO

	EXEC master . dbo. sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0' , N'DynamicParameters' , 1
	GO

3.  Create an entry in the Registry for DisallowAdhocAccess and explicitly set it to 0
	(see DBA Notes OneNote notebook)


--*******Exporting*************************************
--parameter s is for defning the delimeter and h -1 is for excluding the header row
--first allow xp_cmdshell:

sp_configure 'show advanced options', 1
reconfigure
go
sp_configure 'xp_cmdshell',1
reconfigure with override GO

--to give users access to run xp_cmdshell, create a proxy first and run  (see proxy.sql file)
EXECUTE AS LOGIN='domain\user';

EXEC xp_cmdshell 'SQLCMD -S . -d USRGRP_REPORTING -Q "SET NOCOUNT ON; SELECT TOP 100 * FROM TableName" -h -1 -s "	" -o "\\p-biodswin02\Exports\test.csv"';

REVERT;


--*******Importing************************************************************

SELECT *  
FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0','Excel 8.0; Database=D:\CompressionTest.xlsx','SELECT * FROM [dbiods1$]')

--to import a CSV file:
SELECT *  FROM OPENROWSET('MSDASQL','Driver={Microsoft Text Driver (*.txt; *.csv)}; DefaultDir={D:\}; Extensions=csv;', 
	'SELECT * FROM CVS_PMT01_Part.csv') Test;

BULK INSERT Staging.dbo.CVS_PMT FROM 'D:\CVS_PMT06.csv' WITH
      (  
         FIELDTERMINATOR ='|',
		 ROWTERMINATOR = '\n'  --{CR}{LF}, use CHAR(10) for line feed
      );

SELECT count(*) FROM Staging.dbo.CVS_PMT;

SELECT top 10 * FROM Staging.dbo.CVS_PMT;


SELECT * 
FROM OPENDATASOURCE ('Microsoft.Jet.OLEDB.4.0','Data Source=C:\OneD\import.xlsx; Extended Properties=Excel 8.0')...[Promos$];


**/
/**
REQUIRED PERMISSIONS:
The only required permission is to be in the public role.  



--****************ERRORS*******************************
Error:
Msg 7415, Level 16, State 1, Line 1
Ad hoc access to OLE DB provider 'Microsoft.ACE.OLEDB.12.0' has been denied. You must access this provider through a linked server.

Reason: 
Permission Issue

Error:
OLE DB provider "MSDASQL" for linked server "(null)" returned message "[Microsoft][ODBC Driver Manager] Data source name not found and no default driver specified".
Msg 7303, Level 16, State 1, Line 7
Cannot initialize the data source object of OLE DB provider "MSDASQL" for linked server "(null)".

Solution:
Check ODBC Data Source Drivers for "ODBC Driver 11 for SQL Server", it is most likely not installed


Error:
Msg 7399, Level 16, State 1, Line 22
The OLE DB provider "Microsoft.ACE.OLEDB.12.0" for linked server "(null)" reported an error. The provider did not give any information about the error.
Msg 7303, Level 16, State 1, Line 22
Cannot initialize the data source object of OLE DB provider "Microsoft.ACE.OLEDB.12.0" for linked server "(null)".

Solution:
Now, the simple explanation is this, when using a linked server (and the OPENROWSET is a sort of linked server) then a temporary DSN (Data Source Name) is created
in the TEMP directory for the account that started the SQL Server service. This is typically an account that is an administrator on the machine.
However, the OLEDB provider will execute under the account that called it.  This user can even be sysadmin on the SQL Server, but as long as this user is not an administrator
on the machine, it will not have Write access to the TEMP directory for the SQL Server service account.
There are 2 ways to resolve this, set the security of the temp folder with minimal restrictions or change the TEMP and TMP variables to another folder such as C:\Temp, to move this 
out of the Documents and Settings folder.

C:\Users\<SQL Server Service Account Name>\AppData\Local\Temp

Right-click My Computer and select Properties.
Select the Advanced tab.
Click the Environment Variables button.
In the System variables area, select TEMP and click the Edit button.
In the Variable value field, enter the new path for the TEMP environment variable and click OK.
In the System variables area, select TMP and click the Edit button.
In the Variable value field, enter the new path for the TMP environment variable and click OK.




Error:
Msg 7399, Level 16, State 1, Line 1
The OLE DB provider "Microsoft.ACE.OLEDB.12.0" for linked server "(null)" reported an error. Access denied.
Msg 7350, Level 16, State 2, Line 1
Cannot get the column information from OLE DB provider "Microsoft.ACE.OLEDB.12.0" for linked server "(null)".

Solution:
USE [master]
GO
EXEC master . dbo. sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0' , N'AllowInProcess' , 1
GO
EXEC master . dbo. sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0' , N'DynamicParameters' , 1
GO




Error:
Msg 7399, Level 16, State 1, Line 1
The OLE DB provider "Microsoft.ACE.OLEDB.12.0" for linked server "(null)" reported an error. The provider did not give any information about the error.
Msg 7303, Level 16, State 1, Line 1
Cannot initialize the data source object of OLE DB provider "Microsoft.ACE.OLEDB.12.0" for linked server "(null)".

Solution: 
File may be open 
OR
RESTART MSSQLSERVER
OR
MemToLeave area might be to blame, determine the amount of total available memory and largest free size

With VAS_Summary As (
     Select Size = VAS_Dump.Size,
            Reserved = SUM( Case(Convert(int, VAS_Dump.Base) ^ 0)
                                When 0
                                Then 1
                                Else 0
                            End),
            Free = Sum( Case(Convert(int, VAS_Dump.Base) ^ 0)
                            When 0
                            Then 1
                            Else 0
                        End)
     From (Select   Convert(varbinary, Sum(region_size_in_bytes)) [Size],
                    region_allocation_base_address [Base]
           From     sys.dm_os_virtual_address_dump
           Where    region_allocation_base_address <> 0x0
           Group By region_allocation_base_address
           Union
           Select   CONVERT(varbinary, region_size_in_bytes) [Size],
                    region_allocation_base_address [Base]
           From     sys.dm_os_virtual_address_dump
           Where    region_allocation_base_address = 0x0) As VAS_Dump
           Group By Size)
Select     SUM(convert(bigint, Size)*Free)/1024 As [Memory: Total Avail (KB)],
           CAST(max(size) as bigint)/1024 As [Memory: Max Free (KB)]
From       VAS_Summary
Where      Free <> 0


*/


