$sourceVM="xx"
$targetVM1="xx"
$CertPath="\\xx\SQL\BackupCert\BackupCert.cert"
$KeyPath="\\xx\SQL\BackupCert\BackupCert.key"
$Pass="xxx"
$DMKPass="xxx"

$Query="BACKUP CERTIFICATE BackupCert TO FILE = '$CertPath' WITH PRIVATE KEY (file='$KeyPath',ENCRYPTION BY PASSWORD='$Pass');"
#give read/write permission on destination folder to sourceVM's SQL Service account first
Invoke-Sqlcmd -ServerInstance $sourceVM -Query $Query -TrustServerCertificate

#copy files to target VMs E:\MSSQL\Backup
$b = New-PSSession $targetVM1
Copy-Item -ToSession $b $CertPath -Destination E:\MSSQL\Backup\BackupCert.cert
Copy-Item -ToSession $b $KeyPath -Destination E:\MSSQL\Backup\BackupCert.key


#create Database Master Key (DMK), if one does not already exist:
$Query="IF NOT EXISTS 
   (SELECT * FROM sys.symmetric_keys WHERE symmetric_key_id = 101)
   CREATE MASTER KEY ENCRYPTION BY PASSWORD = '$DMKPass' 
GO"
Invoke-Sqlcmd -ServerInstance $targetVM1 -Query $Query 

#create backup certificate
$Query="CREATE CERTIFICATE BackupCert FROM FILE = 'E:\MSSQL\Backup\BackupCert.cert' WITH PRIVATE KEY (file='E:\MSSQL\Backup\BackupCert.key', DECRYPTION BY PASSWORD='$Pass');"
Invoke-Sqlcmd -ServerInstance $targetVM1 -Query $Query -TrustServerCertificate