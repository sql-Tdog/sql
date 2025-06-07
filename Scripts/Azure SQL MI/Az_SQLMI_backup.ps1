<#
for SQL MI: If Service-Managed Key is used for Transparent Data Encryption, 
an on-demand backup cannot be performed
#>

Install-Module -Name Az.Sql  
Install-Module -Name Az.Accounts  
Install-Module -Name Az.Storage

Import-Module -Name Az.Accounts -RequiredVersion 3.0.0
Import-Module -Name Az.Storage

#managed identity details:
$managedIdentity="xxxx"
$managedIdClientId ="xxxxx"
$subscription="xxxx"

$AzureContext = (Connect-AzAccount -Identity -AccountId $managedIdClientId -Subscription $subscription).context
$AzureContext

$storageAccountRG="xxxx"
$storageAccountName="xxxx"
$containerName="xxx"

$StAccountKey=Get-AzStorageAccountKey -ResourceGroupName $storageAccountRG -Name $storageAccountName 
$AzStorageContext=New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $StAccountKey[0].value 
$Azcontainer=Get-AzStorageContainer -Name $containerName -Context $AzStorageContext
$cbc=$Azcontainer.CloudBlobContainer
$policyName='DBBackup'
$sourcedb="database"
$server="xxxx.database.windows.net"

#for the first time: Set up a Stored Access Policy and a Shared Access Signature Token for the container  
$policy = New-AzStorageContainerStoredAccessPolicy -Container $containerName -Context $AzStorageContext -Policy $policyName  -ExpiryTime $(Get-Date).ToUniversalTime().AddYears(2) -Permission "rwld"

#if the access policy has already been created:
$policy = Get-AzStorageContainerStoredAccessPolicy -Container $containerName -Context $AzStorageContext -Policy $policyName

$sas = New-AzStorageContainerSASToken -Policy $policyName -Context $AzStorageContext -Container $containerName
#Create the credential in SQL server using the SAS token:
$tSql = "CREATE CREDENTIAL [{0}] WITH IDENTITY='Shared Access Signature', SECRET='{1}'" -f $cbc.Uri,$sas.TrimStart('?')   
#for SQL MI: copy and paste the $tSql output into an SSMS Query window and execute
$tSql
Invoke-Sqlcmd -ServerInstance  -Query $tSql  

#In the future, try using the Managed Identity instead of SAS token:
$tSql = "CREATE CREDENTIAL [{0}] WITH IDENTITY='$managedIdentity'" -f $cbc.Uri,$sas.TrimStart('?')   

#to turn off TDE so that a copy_only backup can be taken:
$tsql = "ALTER DATABASE database SET ENCRYPTION OFF;"
Invoke-Sqlcmd -ServerInstance $server -Query $tSql 

#Microsoft recommends restarting the instance after removing encryption
#this will also remove encryption from tempdb
$sqlMI="xxx1"
$MIRG="xxx2"
Stop-AzSqlInstance -Name $sqlMI  -ResourceGroupName $MIRG

Start-AzSqlInstance -Name $sqlMI  -ResourceGroupName $MIRG

#backup a database:
$storageUri=$cbc.Uri.AbsoluteUri
$backupURL="$storageUri/$sourcedb.bak"
$tsql = "BACKUP DATABASE $sourcedb TO URL ='$backupURL' WITH COPY_ONLY; "
$tsql


Get-AzStorageBlob -Container $containerName -Context $AzStorageContext 
$AzStorageContext
# upload a file to the default account (inferred) access tier
$Blob1HT = @{
  File             = 'C:\Temp\import.csv'
  Container        = $ContainerName
  Blob             = "Sample"
  Context          = $AzStorageContext
}
Set-AzStorageBlobContent @Blob1HT 

(Get-AzStorageAccount -ResourceGroupName $storageAccountRG -Name $storageAccountName).Id