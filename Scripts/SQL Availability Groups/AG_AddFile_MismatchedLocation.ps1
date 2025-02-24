<####
When creating a file on a primary replica on a drive that doesn't exist on the secondary replica,
we need to tell SQL Server to use a different location on this secondary.  


Once the file is added on the primary, the secondary database will go into suspended mode 
immediately.  
####>

#check if file exists on all nodes:
#Change category names as needed and path in Test-Path
$servers = ""  
ForEach($server in $servers) {  
  $server
  Invoke-Command -ComputerName $server.ComputerName -ScriptBlock { Test-Path "S:\MSSQL\Data" }
}

$AG=""
$db=""
$inst=""            #secondary replica that needs to have the file in a different location
$fileName=""        #the logical name of the new database file
$newFilePath=""     #the complate path of this file, ex:  F:\SQLData\Databasefile.ndf

$Query = " 
    USE master
    GO
    ALTER DATABASE $db MODIFY FILE (NAME='$fileName', FILENAME = N'$newFilePath');
    GO
    ALTER DATABASE $db SET HADR resume;
" 
$Query
Invoke-Sqlcmd -ServerInstance $inst -Query $Query 


<#
In case of this error message:  
Database 'xx' cannot be opened due to inaccessible files or insufficient memory or disk space. 
Check permissions on the new location, verify that the SQL Server Service account has access,
restart SQL Services again

#>