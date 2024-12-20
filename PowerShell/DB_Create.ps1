#create a dummy database & back it up for the first time:

Invoke-Sqlcmd -ServerInstance $inst1 -Query "CREATE DATABASE dummy_db" 
Backup-SqlDatabase -Database "dummy_db"  -ServerInstance "$inst1" 
Backup-SqlDatabase -Database "dummy_db" -ServerInstance "$inst1" -BackupAction Log
