$resourceGroup="xxx"
$UMIClientId = "xxx"
$storageAccountName = "xxx"
$fileShareURL = $storageAccountName+".file.core.windows.net"
$fileShare = "xxx"
$policyName="xxx"

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
$path = "ServerName/FULL_COPY_ONLY"
Get-AzStorageFile -Context $ctx -ShareName $fileShare -Path $path | Get-AzStorageFile

#view file sizes 
Get-AzStorageFile -Context $ctx -ShareName $fileShare -Path $path | Get-AzStorageFile | Select-Object Name, Length

#upload a file to the share:
$fileToUpload="C:\Temp\test.bak"
Set-AzStorageFileContent  -File $fileToUpload -ShareName $fileShare -Context $ctx -Force
