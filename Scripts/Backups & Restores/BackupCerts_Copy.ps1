$sourceVM="AGLNA4BMD01" 
#target VMs:
$inst1="cusqlbmna4s1p01"
$inst2="cusqlbmna4s2p01"
$inst3="e2sqlbmna4s1p01"
$inst4="e2sqlbmna4s2p01"
$CertPath="\\cusqlbmna4s1p01\Temp\BackupCert.cert"
$KeyPath="\\cusqlbmna4s1p01\Temp\BackupCert.key"
$Pass="xxx"
$DMKPass="xxx"

$Query="BACKUP CERTIFICATE BackupCert TO FILE = '$CertPath' WITH PRIVATE KEY (file='$KeyPath',ENCRYPTION BY PASSWORD='$Pass');"
#give read/write permission on destination folder to sourceVM's SQL Service account first
Invoke-Sqlcmd -ServerInstance $sourceVM -Query $Query -TrustServerCertificate

#copy files to target VMs C:\Temp folder
$b = New-PSSession $inst2
Copy-Item -ToSession $b $CertPath -Destination C:\Temp\BackupCert.cert
Copy-Item -ToSession $b $KeyPath -Destination C:\Temp\BackupCert.key
$b = New-PSSession $inst3
Copy-Item -ToSession $b $CertPath -Destination C:\Temp\BackupCert.cert
Copy-Item -ToSession $b $KeyPath -Destination C:\Temp\BackupCert.key
$b = New-PSSession $inst4
Copy-Item -ToSession $b $CertPath -Destination C:\Temp\BackupCert.cert
Copy-Item -ToSession $b $KeyPath -Destination C:\Temp\BackupCert.key


#create Database Master Key (SMK), if one does not already exist:
$Query="IF NOT EXISTS 
   (SELECT * FROM sys.symmetric_keys WHERE symmetric_key_id = 101)
   CREATE MASTER KEY ENCRYPTION BY PASSWORD = '$DMKPass' 
GO"
Invoke-Sqlcmd -ServerInstance $inst1 -Query $Query 
Invoke-Sqlcmd -ServerInstance $inst2 -Query $Query 
Invoke-Sqlcmd -ServerInstance $inst3 -Query $Query 
Invoke-Sqlcmd -ServerInstance $inst4 -Query $Query 

#create backup certificate
$Query="CREATE CERTIFICATE BackupCert FROM FILE = 'C:\Temp\BackupCert.cert' WITH PRIVATE KEY (file='C:\Temp\BackupCert.key', DECRYPTION BY PASSWORD='$Pass');"
Invoke-Sqlcmd -ServerInstance $inst1 -Query $Query 
Invoke-Sqlcmd -ServerInstance $inst2 -Query $Query 
Invoke-Sqlcmd -ServerInstance $inst3 -Query $Query 
Invoke-Sqlcmd -ServerInstance $inst4 -Query $Query 