<####
This script is for copying files to the Azure Storage Container using the AZ Copy tool
and an SAS token

####>


#first, install AZ Copy on the VM

#then use the SAS token to copy files
$sourceFile="xxxxx.bak"
$AzContainer="xxxx"
$SASToken="xxxxx"
$AzBlobContainer=""

C:\Temp\azcopy\azcopy.exe copy $sourceFile "https://$AzContainer.blob.core.windows.net/$AzBlobContainer?$SASToken"
