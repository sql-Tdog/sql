$managedIdentity="xxx"
$resourceGroup="xxx"
$managedIdClientId = "xxx"
$UMIClientId = "" #needed only if using the old method to connect to Azure with UMI
$storageAccountName = "xxx"
$fileShareURL = $storageAccountName+".file.core.windows.net"
$fileShare = "xxx"
$subscription = "xxx"

#connect to Azure with the user-managed-assigned Managed Identity
#new method:
Az login --identity --allow-no-subscriptions
Set-AzContext -SubscriptionName $subscription

#old method:
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





