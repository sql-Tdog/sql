#building on Az_StorageTokens.ps1
#create a credential in SQL server using the Shared Access Signature  
$SQLserver = ""
$tSql = "CREATE CREDENTIAL [https://$storageAccountName.blob.core.windows.net/dsdb] WITH IDENTITY='Shared Access Signature', SECRET='$sas'"
$tSql
Invoke-Sqlcmd -ServerInstance $SQLserver -Query $tSql 

#Restore database from Azure storage container backup:
$fileName = ""
$tSql = "RESTORE FILELISTONLY FROM URL = N'https://$AzContainer.blob.core.windows.net/dsdb/$fileName';"
Invoke-Sqlcmd -ServerInstance $SQLserver -Query $tSql 
