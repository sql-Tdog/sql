
$db="databasename"

$Query="SELECT Location FROM BackupLocation WHERE BackupGroupName='$AG1'"
$OnPremBackupLocation=New-DbConnection $List1 -DatabaseName "master" | New-DbCommand $Query | Get-DbData
$OnPremBackupLocation="{0}\NA2Cluster02-$AG1\$db\LOG\" -f $OnPremBackupLocation.Location
$OnPremBackupLocation

#View last t-log restored on the destination instance:
$Query="
SELECT TOP 1
   [rs].[destination_database_name], 
   [rs].[restore_date], 
   [bs].[backup_start_date], 
   [bs].[backup_finish_date], 
   [bs].[database_name] as [source_database_name], 
   [bmf].[physical_device_name] as [backup_file_used_for_restore]
FROM msdb..restorehistory rs
INNER JOIN msdb..backupset bs ON [rs].[backup_set_id] = [bs].[backup_set_id]
INNER JOIN msdb..backupmediafamily bmf ON [bs].[media_set_id] = [bmf].[media_set_id] 
ORDER BY [rs].[restore_date] DESC"
New-DbConnection $inst3 -DatabaseName "master" | New-DbCommand $Query | Get-DbData

Get-ChildItem -Path $OnPremBackupLocation | Sort-Object LastWriteTime | Select-Object -first 3


$Query="ALTER DATABASE $db SET HADR AVAILABILITY GROUP = $AG2;"
Invoke-Sqlcmd -ServerInstance $inst3 -Query $Query 
Invoke-Sqlcmd -ServerInstance $inst4 -Query $Query 
$Query="ALTER DATABASE $db SET HADR AVAILABILITY GROUP = $AG3;"
Invoke-Sqlcmd -ServerInstance $inst5 -Query $Query 
Invoke-Sqlcmd -ServerInstance $inst6 -Query $Query 
