/**
--enable xp_cmdshell:
EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
EXEC sp_configure 'xp_cmdshell',1;
GO
reconfigure;


--mount net share to Z drive:
EXEC xp_cmdshell 'NET USE Z: \\corp\share\dbabackup e6zRXYCjmrkFn5vc87ho /USER:CORP\OneCMSNProdDBRestore'
go
RESTORE FILELISTONLY FROM  DISK = N'Z:\CMS_Prod_App_FULL.bak' ;

RESTORE DATABASE CMS_QA7_App FROM  DISK = N'Z:\CMS_Prod_App_FULL.bak' 
WITH  FILE = 1,   MOVE N'CMS_Prod_App' TO N'D:\Data\CMS_QA7_App.mdf',  MOVE N'CMS_Prod_App_log' TO N'L:\Logs\CMS_QA7_App_log.ldf', 
 NEW_BROKER, RECOVERY, REPLACE;
go


--view files in a directory:
--xp_dirtree returns depth and bit for if it's a file or not
EXEC xp_dirtree '\\w3sqldbawu3i01\share\', 1,1

EXEC xp_cmdshell 'dir *.exe';
GO


USE [master]
EXEC xp_cmdshell 'NET USE Z: /delete'
go

--write to a batch file:
DECLARE @Date date, @Time int, @stmt varchar(500);

select TOP 1 @Date=cast(ExecStartDT as date), @Time= datediff(mi,ExecStartDT,ExecStopDT) from [p-biods1].datamart.dbo.DimAudit
where cast(ExecStartDT as date)=cast(getdate() as date) and tablename like 'Master Package%';
--escape & with a ^ to write to a batch file, escape again for batch file to actually work
SET @stmt='http://stlvdussdev070/datacap/save_data.asp?updatekey=addetltime^^^&updatevalue='+convert(varchar(4),@Time);
SELECT @stmt;
	


SET @stmt='EXEC master..xp_cmdshell ''echo start '+@stmt +' > C:\etl_batch.bat''';
SELECT @stmt;

execute(@stmt);

EXEC xp_fixeddrives

**/
