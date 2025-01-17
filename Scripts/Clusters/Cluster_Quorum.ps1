#1 WSFC cluster per AG group
#cloud witness is not compatible with Blob storage or Azure Premium Storage, only Standard Azure storage
Update-Module Az.Storage

$clust=""
$storageAccountName=""
$managedIdClientId = ""
$resourceGroup=""

# Connect to Azure with user-managed-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity -AccountId $managedIdClientId).context

# set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription  
$AzureContext


#get storage account key, needed to access storage containers:  
$StAccountKey=Get-AzStorageAccountKey -ResourceGroupName $resourceGroup -Name $storageAccountName 

Get-ClusterNode -Cluster $clust

Set-ClusterQuorum -Cluster $clust -CloudWitness -AccountName $storageAccountName -AccessKey $StAccountKey[0].value 

Get-ClusterQuorum -Cluster $clust
