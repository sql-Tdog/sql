Install-Module -Name Az.Accounts  
Install-Module -Name Az.Storage
Install-Module -Name Az.Sql

Update-Module -Name Az.Accounts
Update-Module -Name Az.Storage

Import-Module -Name Az.Accounts 
Import-Module -Name Az.Storage
Import-Module -Name Az.Sql

#to restore a backup file on the MI that is encrypted with TDE, upload TDE certs to the container:
#backup certs first:
$sourceVM = "xxx" 
$CertPath = "C:\Temp\BackupCert1.cert"
$KeyPath = "C:\Temp\BackupCert1.key"
$Pass = "xxx"

$Query="BACKUP CERTIFICATE BackupCert TO FILE = '$CertPath' WITH PRIVATE KEY (file='$KeyPath',ENCRYPTION BY PASSWORD='$Pass');"
#give read/write permission on destination folder to sourceVM's SQL Service account first
Invoke-Sqlcmd -ServerInstance $sourceVM -Query $Query 

#using the user managed identity assigned to the VM that has access to the MI, connect to Azure: 
$managedIdClientId = "xxxxx"
$MIsubscription = "xxx"
$AzureContext = (Connect-AzAccount -Identity -AccountId $managedIdClientId -Subscription $MIsubscription).context 
$AzureContext

#find the location of pvk2pfx and then cd to its folder:
cd "C:\Program Files\Azure Data Studio\resources\app\extensions\mssql\sqltoolsservice\Windows\4.7.1.4\"
#combine TDE files and use it to add TDE cert to the MI  (this will not mess up current keys on the MI)
#make sure the files are copied from the SQL VM to the tools VM first:
$pfxPath = "C:/Temp/TDE_Cert.pfx"
.\pvk2pfx -pvk $KeyPath -pi $Pass -spc $CertPath -pfx $pfxPath
#in PowerShell 6.0+
$fileContentBytes = Get-Content $pfxPath -AsByteStream
#in Powershell 5.0+
$fileContentBytes = Get-Content $pfxPath -Encoding Byte
$base64EncodedCert = [System.Convert]::ToBase64String($fileContentBytes)
$securePrivateBlob = $base64EncodedCert  | ConvertTo-SecureString -AsPlainText -Force
$securePassword = $Pass | ConvertTo-SecureString -AsPlainText -Force
$MIresourceGroupName = ""
$MIname = ""
Add-AzSqlManagedInstanceTransparentDataEncryptionCertificate -ResourceGroupName $MIresourceGroupName -ManagedInstanceName $MIname -PrivateBlob $securePrivateBlob -Password $securePassword


#now, get access to the storage account to create SQL token & upload files:
#storage container kind should be StorageV2 (general purpose) and container type: blob
$storageAccountRG = "xxxx"
$storageAccountName = "xxxx"
$containerName = "backups"
$containerSubscription = "xxx"
$managedIdClientId ="xxx" #use the MI assigned to the VM and container for access
$AzureContext = (Connect-AzAccount -Identity -AccountId $managedIdClientId -Subscription $containerSubscription).context 
$AzureContext

$StAccountKey = Get-AzStorageAccountKey -ResourceGroupName $storageAccountRG -Name $storageAccountName 
$AzStorageContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $StAccountKey[0].value 
$Azcontainer = Get-AzStorageContainer -Name $containerName -Context $AzStorageContext
$cbc = $Azcontainer.CloudBlobContainer
$policyName = 'DBBackup'
$AzStorageContext.context

#for the first time: Set up a Stored Access Policy and a Shared Access Signature Token for the container  
$policy = New-AzStorageContainerStoredAccessPolicy -Container $containerName -Context $AzStorageContext -Policy $policyName  -ExpiryTime $(Get-Date).ToUniversalTime().AddYears(2) -Permission rwld

#if the access policy has already been created:
$policy = Get-AzStorageContainerStoredAccessPolicy -Container $containerName -Context $AzStorageContext -Policy $policyName

$sas = New-AzStorageContainerSASToken -Policy $policyName -Context $AzStorageContext -Name $containerName 

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
$storageUri = $cbc.Uri.AbsoluteUri
$backupURL = "$storageUri/sample.bak"
$tsql = "RESTORE FILELISTONLY FROM URL ='$backupURL'; "
$tsql

#in case of access denied, test the connection on SQL MI by creating a job to run below script:
$SAURL = $storageAccountName + ".blob.core.windows.net"
Test-NetConnection  $SAURL -port 443

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