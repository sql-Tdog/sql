$managedIdentity="msfsqlfabricuserassignedidentitystageus"
$resourceGroup="MsfSqlfabricStorageStageUs"
$managedIdClientId = "94bf2c40-7767-4bea-8e77-1d8d622b1401"
$storageAccountName = "sqlbackupdreusssto"
$fileShareURL = $storageAccountName+".file.core.windows.net"
$fileShare = "backups"

#connect to Azure with the user-managed-assigned Managed Identity
$AzureContext = (Connect-AzAccount -Identity -AccountId $managedIdClientId).context 
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription  
$AzureContext

#get storage account key, needed to access storage containers:  
$StAccountKey=Get-AzStorageAccountKey -ResourceGroupName $resourceGroup -Name $storageAccountName
$AzStorageContext=New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $StAccountKey[0].value 

#generate the SAS URL with delete permissions:
$sas = New-AzStorageShareSASToken -Context $AzStorageContext -Name $fileShare -Permission rwld  -ExpiryTime $(Get-Date).ToUniversalTime().AddMonths(3)
$sas
$sasURL = "https://$fileShareURL/$fileShare/?$sas"
$sasURL





