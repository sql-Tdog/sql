<####
This script is to move newly added secondary database files to the AG primary replica
to a different location on the secondary replicas


Since we will be stopping SQL Services, stop t-log backups or we will have to restore any 
backups taken during the work
####>

#update variables on lines 7-10 and 32-33 because variables do not pass through to a new PS session
$AG=""
$db=""
$inst=""
$fileName=""
$newFilePath="G:\MSSQL\Data\$filename.ndf"

$Query="ALTER DATABASE $db SET HADR SUSPEND;
ALTER DATABASE $db SET HADR OFF;
" 
$Query
Invoke-Sqlcmd -ServerInstance $inst -Query $Query 

$Query="ALTER DATABASE $db MODIFY FILE ( NAME = $fileName,   
              FILENAME = `'$newFilePath`');  
GO
"
$Query
Invoke-Sqlcmd -ServerInstance $inst -Query $Query 


#move the files
Enter-PSSession -ComputerName $inst
    Net Stop SQLSERVERAGENT
    Net Stop MSSQLSERVER

    $oldFilePath="H:\MSSQL\Log\AccountServer-00000-007_1.ldf"
    $newFilePath="L:\MSSQL\Log\AccountServer-00000-007_1.ldf"

    Move-Item -Path $oldFilePath -Destination $newFilePath

    Net Start MSSQLSERVER
    Net Start SQLSERVERAGENT
Exit

$Query="ALTER  DATABASE $db SET HADR AVAILABILITY GROUP = $AG
"
$Query
Invoke-Sqlcmd -ServerInstance $inst -Query $Query 

#in case of this error message:  Database 'xx' cannot be opened due to inaccessible files or insufficient memory or disk space. 
#check permissions on the new location, verify that the SQL Server Service account has access 
#restart SQL Services again