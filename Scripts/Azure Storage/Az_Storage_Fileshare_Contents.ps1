$resourceGroup="MsfSqlfabricStorageDevUs"
$UMIClientId = "9bf00545-75f4-4f0e-9b8e-7c771fb28edc"
$storageAccountName = "sqlbackupeastuseuslsto"
$fileShareURL = $storageAccountName+".file.core.windows.net"
$fileShare = "dsdb"
$policyName="DBBackup"

# Connect to Azure with user-managed-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity -AccountId $UMIClientId).context 
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription  
$AzureContext
#Set Context:
$ctx = (Get-AzStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccountName).Context

#make sure connectivity is there:
Test-NetConnection -ComputerName $fileshareURL -Port 445


#view directories of the fileshare container:
Get-AzStorageFile -Context $ctx -ShareName $fileShare

#view files in a directory:
$path = "SenClustD01-AGSenD01/SQLSentry/FULL_COPY_ONLY"
Get-AzStorageFile -Context $ctx -ShareName $fileShare -Path $path | Get-AzStorageFile

#view file sizes 
Get-AzStorageFile -Context $ctx -ShareName $fileShare -Path $path | Get-AzStorageFile | Select-Object Name, Length

