<####
This script is for accessing Azure Storage Containers using two methods:
1.  User Assigned Identity
2.  Shared Access Signature Token

####>


######use VM User Assigned Identity to access storage container###############################################
Install-Module -Name Az -AllowClobber
Import-Module -Name Az
Update-Module -Name Az


$resourceGroup=""
$storageAccountName1=""
$containerName=""
$managedIdentity=""
$managedIdClientId = ""
$policyName='DBBackup'

# Connect to Azure with user-managed-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity -AccountId $managedIdClientId).context 


# set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription  
$AzureContext

#get storage account key, needed to access storage containers:  
$StAccountKey=Get-AzStorageAccountKey -ResourceGroupName $resourceGroup -Name $storageAccountName1 
$AzStorageContext=New-AzStorageContext -StorageAccountName $storageAccountName1 -StorageAccountKey $StAccountKey[0].value 




######use Shared Access Signature Token to access storage container###############################################
$sasToken=""
$storageAccountName=""
$containerName=""
$fileToUpload="C:\Temp\test.bak"


$storageContext = New-AzStorageContext -StorageAccountName $storageAccountName -SasToken $sasToken
Set-AzStorageBlobContent -File $fileToUpload -Container $containerName -Context $storageContext -Force





#list blobls in a container:
Get-AzStorageBlob -Container $containerName -Context $AzStorageContext 
#view names only:
Get-AzStorageBlob -Container $containerName -Context $storageContext | Select Name

#upload a file to the container:
$AzStorageContext
# upload a file to the default account (inferred) access tier
$Blob1HT = @{
  File             = 'C:\Temp\import.csv'
  Container        = $ContainerName
  Blob             = "Sample"
  Context          = $AzStorageContext
  StandardBlobTier = 'Archive'
}
Set-AzStorageBlobContent @Blob1HT -Debug



#delete a file from the container:
$blobName = ""
Remove-AzStorageBlob -Container $containerName -Context $storageContext -Blob $blobName 