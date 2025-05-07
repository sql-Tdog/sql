New-Item "C:\SQLBackups" -ItemType Directory
New-SmbShare -Path C:\SQLBackups -Name "SQLBackups$"
 
New-Item "C:\SQLBackupsKeep" -ItemType Directory
New-SmbShare -Path C:\SQLBackupsKeep -Name "SQLBackupsKeep$"
 
New-Item "C:\SQLBackupsScratch" -ItemType Directory
New-SmbShare -Path C:\SQLBackupsScratch -Name "SQLBackupsScratch$"