#Install-Module -name AzureRM
Install-Module -Name Az -AllowClobber 
Update-Module -Name Az


$resourceGroup = ""
$storageAccountName = ""
$containerName = ""
$managedIdClientId = ""
$policyName = "DBBackup"

#instances where we will be creating the SAS tokens:
$inst1=""
$inst2=""
$inst3=""
$inst4=""

# Connect to Azure with user-managed-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity -AccountId $managedIdClientId).context 

# set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription  
$AzureContext

#get storage account key, needed to access storage containers:  
$StAccountKey=Get-AzStorageAccountKey -ResourceGroupName $resourceGroup -Name $storageAccountName 
$AzStorageContext=New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $StAccountKey[0].value 

#get container:
$Azcontainer=Get-AzStorageContainer -Name $containerName -Context $AzStorageContext
$cbc=$Azcontainer.CloudBlobContainer

#for the first time: Set up a Stored Access Policy and a Shared Access Signature Token for the container  
$policy = New-AzStorageContainerStoredAccessPolicy -Container $containerName -Context $AzStorageContext -Policy $policyName  -ExpiryTime $(Get-Date).ToUniversalTime().AddYears(2) -Permission "rwld"

#if the access policy has already been created:
$policy = Get-AzStorageContainerStoredAccessPolicy -Container $containerName -Context $AzStorageContext -Policy $policyName

#create a credential in SQL server using the Shared Access Signature  
$sas = New-AzStorageContainerSASToken -Policy $policyName -Context $AzStorageContext -Container $containerName

#Create the credential in SQL server using the SAS token:
$tSql = "CREATE CREDENTIAL [{0}] WITH IDENTITY='Shared Access Signature', SECRET='{1}'" -f $cbc.Uri,$sas.TrimStart('?')   
#$tSql = "DROP CREDENTIAL [{0}]"  -f $cbc.Uri
Invoke-Sqlcmd -ServerInstance $inst1 -Query $tSql 
Invoke-Sqlcmd -ServerInstance $inst2 -Query $tSql 
Invoke-Sqlcmd -ServerInstance $inst3 -Query $tSql 
Invoke-Sqlcmd -ServerInstance $inst4 -Query $tSql 

#backup a database:
$storageUri=$cbc.Uri.AbsoluteUri
$backupURL="$storageUri/$sourcedb.bak"
$tsql = "BACKUP DATABASE $sourcedb TO URL ='$backupURL' WITH COPY_ONLY; "
Invoke-Sqlcmd -ServerInstance $inst1 -Query $tSql -TrustServerCertificate

#to drop the credential:
$Query="drop credential [{0}]" -f $cbc.Uri,$sas.TrimStart('?')   

#list blobls in a container:
Get-AzStorageBlob -Container $containerName -Context $AzStorageContext 


#manually test uploading to the container:
$AzStorageContext
# upload a file to a StorageV2 account type, Premium tier:
$Blob1HT = @{
  File             = 'C:\SQL\SQL_Build_Tanya\BuildManifest.json'
  Container        = $ContainerName
  Blob             = "Sample"
  Context          = $AzStorageContext
  StandardBlobTier = 'Archive'
}
Set-AzStorageBlobContent @Blob1HT 

#to upload to a BlockBlobStorage account type:
$Blob1HT = @{
  File             = 'C:\SQL\SQL_Build_Tanya\BuildManifest.json'
  Container        = $ContainerName
  Blob             = "Sample"
  Context          = $AzStorageContext
}
Set-AzStorageBlobContent @Blob1HT 
