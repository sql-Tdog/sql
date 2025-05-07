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


#generate a storage context object for the fileshare container using the SAS token with delete permissions:
$sas = New-AzStorageShareSASToken -Context $AzStorageContext -Name $fileShare -Permission rwld  -ExpiryTime $(Get-Date).ToUniversalTime().AddMonths(3)
$sas
$sastoken = "https://$fileShareURL/$fileShare/?$sas"
$sastoken
$AzStorage = New-AzStorageContext -StorageAccountName $storageAccountName -SasToken $sas
$AzStorage
$files=Get-AzStorageFile -Context $AzStorage -ShareName $fileShare -Path $path | Get-AzStorageFile 
$files
$Path = "SenClustS01-AGSenS01\Deeb\FULL_COPY_ONLY"




foreach ($file in $files) {
    if ($file.LastModified.DateTime -lt (Get-Date).AddDays(-14)) {
        $filename=$file.Name
        Write-Host "Deleting $Path\$filename"
        Get-AzStorageFile -Context $AzStorage -ShareName $fileShare -Path $path | Remove-AzStorageFile -Path $filename 

    }
}



