<####
This script is for copying files to the Azure Storage Container using the AZ Copy tool
and an SAS token

####>


#first, copy AZCopy files to the VM

#then use the SAS token to copy files
$sourceFile="xxxxx.bak"
$AzContainer="xxxx"  #name of the StorageV2 container
$SASToken="xxxxx"    #SAS token
$AzBlobContainer=""  #name of blob container in the storage container

C:\Temp\azcopy\azcopy.exe copy $sourceFile "https://$AzContainer.blob.core.windows.net/$AzBlobContainer`?$SASToken"


#to copy to a fileshare:

#then use the SAS token to copy files
$sourceFile="\\DASQLNAS008\SQLBackups$\DAASCluster01-AGDAAS01\DocusignCentral\FULL_COPY_ONLY\DAASCluster01-AGDAAS01_DocusignCentral_FULL_COPY_ONLY_20260201_060055_1.bak"
$AzContainer="dsna1bkup2cuspsto"
$SASToken="sv=2025-05-05&se=2026-05-04T23%3A52%3A48Z&sr=s&sp=rwdl&sig=rXYMkLeeiNN%2Fc1pEetzt%2BPQU%2BMyUFaBjuc%2BR1e1QZMo%3D"
$AzBlobContainer="backups"

C:\Temp\azcopy\azcopy.exe copy $sourceFile "https://$AzContainer.file.core.windows.net/$AzBlobContainer`?$SASToken"
