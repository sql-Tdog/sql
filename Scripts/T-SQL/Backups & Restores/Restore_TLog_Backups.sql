/*

USE Master; 
GO  
SET NOCOUNT ON 
EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
EXEC sp_configure 'xp_cmdshell',1;
GO
reconfigure;

--get datetime of when full backup finished:
:CONNECT TATK1R1S1DB1A
SELECT TOP 1 backup_finish_date FROM msdb.dbo.backupset AS B INNER JOIN msdb.dbo.backupmediafamily AS F ON F.media_set_id = B.media_set_id
WHERE database_name='docusign' and type='D' ORDER BY backup_start_date DESC

--delete all files from the log folder:
EXEC master.sys.xp_delete_files 'F:\share\DSLogs\*'

--copy t-log backups that were created within the past 24 hours:
xp_cmdshell 'powershell.exe -File F:\share\GetTLogBackups.ps1'

*/


DROP TABLE IF EXISTS #fileList
DECLARE @AG nvarchar(100)='AGDSNA4P01'
DECLARE @dbName sysname 
DECLARE @lastFullBackup NVARCHAR(500) 
DECLARE @lastDiffBackup NVARCHAR(500) 
DECLARE @cmd NVARCHAR(500) 
DECLARE @backupPath NVARCHAR(500) 
DECLARE @backupFile NVARCHAR(500) 
CREATE TABLE #fileList  (backupFile NVARCHAR(255), depth int, isfile bit) 

SET @dbName = 'DocusignAPILog' 
SET @backupPath  ='D:\Temp\DocusignAPILog\' 

INSERT INTO #fileList(backupFile, depth, isfile) 
EXEC master.sys.xp_dirtree 'D:\Temp\DocusignAPILog\', 1,1


DECLARE backupFiles CURSOR FOR  
   SELECT backupFile  
   FROM #fileList 
   
OPEN backupFiles  

-- Loop through all the files for the database and restore
FETCH NEXT FROM backupFiles INTO @backupFile  

WHILE @@FETCH_STATUS = 0  
BEGIN  
   SET @cmd = 'RESTORE LOG [' + @dbName + '] FROM DISK = '''  
       + @backupPath + @backupFile + ''' WITH NORECOVERY' 
   print @cmd 
   FETCH NEXT FROM backupFiles INTO @backupFile  
END 

CLOSE backupFiles  
DEALLOCATE backupFiles  


 SET @cmd = 'ALTER DATABASE '+ @dbName+' SET HADR AVAILABILITY GROUP ='+ @AG
 print @cmd