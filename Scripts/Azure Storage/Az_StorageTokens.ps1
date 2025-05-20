<####
this script uses the VMs User Assigned Managed Identity to generate a Storage Access Token


####>
Install-Module -Name Az -AllowClobber
Import-Module -Name Az
Update-Module -Name Az

$managedIdentity='xx'
$managedIdClientId = 'xxx'
$resourceGroup=''
$storageAccountName=""
$containerName = ""
$policyName='DBBackup'

# Connect to Azure with user-managed-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity -AccountId $managedIdClientId).context 
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription  
$AzureContext


#get storage account key, needed to access storage containers:  
$StAccountKey=Get-AzStorageAccountKey -ResourceGroupName $resourceGroup -Name $storageAccountName
$AzStorageContext=New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $StAccountKey[0].value 

#get container:
$Azcontainer = Get-AzStorageContainer -Name $containerName -Context $AzStorageContext
$Azcontainer.CloudBlobContainer

#for the first time: Set up a Stored Access Policy and a Shared Access Signature Token for the container  
$policy = New-AzStorageContainerStoredAccessPolicy -Container $containerName -Context $AzStorageContext -Policy $policyName  -ExpiryTime $(Get-Date).ToUniversalTime().AddMonths(3) -Permission "rwld"

#if the access policy has already been created:
$policy = Get-AzStorageContainerStoredAccessPolicy -Container $containerName -Context $AzStorageContext -Policy $policyName
$policy

#create the SAS token:
$sas = New-AzStorageContainerSASToken -Policy $policyName -Context $AzStorageContext -Container $containerName
$sas