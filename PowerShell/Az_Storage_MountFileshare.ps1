Update-Module -Name Az

<#
This script uses UMI to connect to the storage account, gets a key to access it and mounts
the fileshare on the SQL VM

we are not using MultiChannel because it is not compatible with geo-redundant storage 
and we need geo-redundancy
#>

$managedIdentity="xx"
$resourceGroup="xxx"
$managedIdClientId = 'xx'
$storageAccountName = ""
$fileShareURL = $storageAccountName+".file.core.windows.net"
$fileShare = ""
$policyName="DBBackup"

$inst1=""
$inst2=""

#connect to Azure with the user-managed-assigned Managed Identity
$AzureContext = (Connect-AzAccount -Identity -AccountId $managedIdClientId).context 
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription  
$AzureContext

#test the connection, do not continue if it doesn't work:
Test-NetConnection -ComputerName $fileshareURL -Port 445

#get storage account key, needed to access the storage account:  
$StAccountKey=Get-AzStorageAccountKey -ResourceGroupName $resourceGroup -Name $storageAccountName 
$key=$StAccountKey[1].Value

#enable xp_cmdshell:
$query="
EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
EXEC sp_configure 'xp_cmdshell',1;
GO
reconfigure;
"
Invoke-Sqlcmd -ServerInstance $inst1 -Query $query
Invoke-Sqlcmd -ServerInstance $inst2 -Query $query

#use the key to mount the drive in SQL:
$query = "EXEC xp_cmdshell 'net use Z: \\$fileShareURL\$fileShare /u:localhost\$storageAccountName $key'"
Invoke-Sqlcmd -ServerInstance $inst1 -Query $query
Invoke-Sqlcmd -ServerInstance $inst2 -Query $query

#drop the mounted drive:
$query="EXEC xp_cmdshell 'NET USE Z: /delete'"
Invoke-Sqlcmd -ServerInstance $inst1 -Query $query
Invoke-Sqlcmd -ServerInstance $inst2 -Query $query

#backup a database:
$backupURL="https://$storageAccountName.blob.core.windows.net/$containerName/dummydb20240105.bak"
$storageUri=$cbc.Uri.AbsoluteUri

$tsql = "BACKUP DATABASE dummydb TO URL ='$backupURL'; "
Invoke-Sqlcmd -ServerInstance $inst1 -Query $tSql -TrustServerCertificate

