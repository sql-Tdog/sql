Install-Module -Name Az.Accounts  
Install-Module -Name Az.Storage

Update-Module -Name Az.Accounts
Update-Module -Name Az.Storage

Import-Module -Name Az.Accounts 
Import-Module -Name Az.Storage

#using the same managed identity assigned to the storage container and the VM 
$managedIdClientId = "xxxxx"

$AzureContext = (Connect-AzAccount -Identity -AccountId $managedIdClientId).context 
$AzureContext

#storage container kind should be StorageV2 (general purpose) and container type: blob
$storageAccountRG = "xxxx"
$storageAccountName = "xxxx"
$containerName = "backups"

$StAccountKey = Get-AzStorageAccountKey -ResourceGroupName $storageAccountRG -Name $storageAccountName 
$AzStorageContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $StAccountKey[0].value 
$Azcontainer = Get-AzStorageContainer -Name $containerName -Context $AzStorageContext
$cbc = $Azcontainer.CloudBlobContainer
$policyName = 'backup_policy'

#for the first time: Set up a Stored Access Policy and a Shared Access Signature Token for the container  
$policy = New-AzStorageContainerStoredAccessPolicy -Container $containerName -Context $AzStorageContext -Policy $policyName  -ExpiryTime $(Get-Date).ToUniversalTime().AddYears(2) -Permission "rwld"

#if the access policy has already been created:
$policy = Get-AzStorageContainerStoredAccessPolicy -Container $containerName -Context $AzStorageContext -Policy $policyName

#create a new container:
$Azcontainer = New-AzStorageContainer -Name $containerName -Context $AzStorageContext

$sas = New-AzStorageContainerSASToken -Policy $policyName -Context $AzStorageContext -Container $containerName
#Create the credential in SQL server using the SAS token:
$tSql = "CREATE CREDENTIAL [{0}] WITH IDENTITY='Shared Access Signature', SECRET='{1}'" -f $cbc.Uri,$sas.TrimStart('?')   
#for SQL MI: copy and paste the $tSql output into an SSMS Query window and execute
$tSql
Invoke-Sqlcmd -ServerInstance  -Query $tSql -Username xxx -Password xxx

#In the future, try using the Managed Identity instead of SAS token:
$tSql = "CREATE CREDENTIAL [{0}] WITH IDENTITY='$managedIdentity'" -f $cbc.Uri,$sas.TrimStart('?')   

#view files in the container:
Get-AzStorageBlob -Container $containerName -Context $AzStorageContext 
 
# upload a file to the default account (inferred) access tier
$Blob1HT = @{
  File             = 'C:\Temp\Sample.bak'
  Container        = $ContainerName
  Context          = $AzStorageContext
}
Set-AzStorageBlobContent @Blob1HT 

#upload files to restore:
Get-ChildItem -Path 'C:\Temp\TestUpload' -File -Recurse | Set-AzStorageBlobContent -Container $containerName -Context $AzStorageContext

#restore filelistonly:
$storageUri=$cbc.Uri.AbsoluteUri
$backupURL="$storageUri/sample.bak"
$tsql = "RESTORE FILELISTONLY FROM URL ='$backupURL'; "
$tsql

#in case of access denied, test the connection on SQL MI by creating a job to run below script:
$SAURL = $storageAccountName + ".blob.core.windows.net"
Test-NetConnection  $SAURL -port 443

#upload TDE certs:
#find the location of pvk2pfx and then cd to its folder:
cd "C:\Program Files\Azure Data Studio\resources\app\extensions\mssql\sqltoolsservice\Windows\4.7.1.4\"
.\pvk2pfx -pvk C:\Temp\TDE\TDECERT.crtpvtkey -pi "password" -spc C:\Temp\TDE\TDECERT.crt -pfx C:/Temp/TDE_Cert.pfx

$fileContentBytes = Get-Content 'C:\Temp\TDE\TDE_Cert.pfx' -AsByteStream
$base64EncodedCert = [System.Convert]::ToBase64String($fileContentBytes)
$securePrivateBlob = $base64EncodedCert  | ConvertTo-SecureString -AsPlainText -Force
$password = "<password>"
$securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
$MIresourceGroupName = ""
$MIname = ""
Add-AzSqlManagedInstanceTransparentDataEncryptionCertificate -ResourceGroupName $MIresourceGroupName -ManagedInstanceName $MIname -PrivateBlob $securePrivateBlob -Password $securePassword


#to turn off TDE so that a copy_only backup can be taken:
$tsql = "ALTER DATABASE database SET ENCRYPTION OFF;"
Invoke-Sqlcmd -ServerInstance $server -Query $tSql 

#Microsoft recommends restarting the instance after removing encryption
#this will also remove encryption from tempdb
$sqlMI="xxx1"
$MIRG="xxx2"
Stop-AzSqlInstance -Name $sqlMI  -ResourceGroupName $MIRG

Start-AzSqlInstance -Name $sqlMI  -ResourceGroupName $MIRG

#backup a database:
$storageUri=$cbc.Uri.AbsoluteUri
$backupURL="$storageUri/$sourcedb.bak"
$tsql = "BACKUP DATABASE $sourcedb TO URL ='$backupURL' WITH COPY_ONLY; "
$tsql




(Get-AzStorageAccount -ResourceGroupName $storageAccountRG -Name $storageAccountName).Id