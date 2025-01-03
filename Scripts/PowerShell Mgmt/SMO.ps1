#first, load the SMO libraries, they will be available for the rest of the session:
$assemblies = 
    "Microsoft.SqlServer.ConnectionInfo", 
    "Microsoft.SqlServer.ConnectionInfoExtended", 
    "Microsoft.SqlServer.Dmf", 
    "Microsoft.SqlServer.Management.Collector", 
    "Microsoft.SqlServer.Management.CollectorEnum", 
    "Microsoft.SqlServer.Management.RegisteredServers", 
    "Microsoft.SqlServer.Management.Sdk.Sfc", 
    "Microsoft.SqlServer.RegSvrEnum", 
    "Microsoft.SqlServer.ServiceBrokerEnum", 
    "Microsoft.SqlServer.Smo", 
    "Microsoft.SqlServer.SmoExtended", 
    "Microsoft.SqlServer.SqlEnum", 
    "Microsoft.SqlServer.SqlWmiManagement", 
    "Microsoft.SqlServer.WmiEnum"

foreach ($assembly in $assemblies) 
{
    [void][Reflection.Assembly]::LoadWithPartialName($assembly)
}


$machine = "$env:COMPUTERNAME"
$server  = New-Object Microsoft.Sqlserver.Management.Smo.Server("$machine")
$server.ConnectionContext.LoginSecure=$true;

$database  = $server.Databases["master"]
$command   = "SELECT name FROM master.dbo.sysdatabases WHERE name NOT IN ('master', 'tempdb', 'model', 'msdb');"
$dataSet   = $database.ExecuteWithResults($command)
$dataTable = $dataSet.Tables[0]

$dataTable


#*********Backing up user databases************************************
#create the backup directory
$datedBackupFolder = "C:\DatabaseBackups\$((Get-Date).ToString('dd-MM-yyyy'))\"
New-Item -ItemType Directory -Path $datedBackupFolder

#iterate through each database row in the Data Table which was generated earlier & take a full backup

foreach ($row in $dataTable)
{
    # Set up backup properties.
    $databaseName    = $row.name
    $backup          = New-Object Microsoft.SQLserver.Management.Smo.Backup
    $backup.Database = $databaseName
    
    # Configure the backup filename.
    $dateAndTime = $((Get-Date).ToString('yyyy-MM-dd_HH-mm-ss'))
    $backupFile  = $datedBackupFolder + $databaseName + "_" + "$dateAndTime.bak"
    
    # Backup the database.
    $backup.Devices.AddDevice($backupFile, [Microsoft.Sqlserver.Management.Smo.DeviceType]::File) 
    $backup.Action = [Microsoft.Sqlserver.Management.Smo.BackupActionType]::Database
    $backup.SqlBackup($server)
}


Import-Module SQLPS

Get-Location
Set-Location sqlserver:\SQL\localhost

#traverse to database directory
cd \sql\localhost\default\databases\
cd \sql\localhost\


# set instance name variables
$inst = get-item default
$dbname = "MyDatabase"  
 
# change to SQL Server instance directory  
Set-Location SQLSERVER:\SQL\$inst        
 
# create object and database  using SMO
$db = New-Object -TypeName Microsoft.SqlServer.Management.SMO.Database -Argumentlist $inst, $dbname  
$db.Create()  
 
# set recovery model
$db.RecoveryModel = "simple"
$db.Alter()
 
# change owner
$db.SetOwner('sa')
 
# change data file size and autogrowth amount
foreach($datafile in $db.filegroups.files) 
{
 $datafile.size= 1048576
 $datafile.growth = 262144
 $datafile.growthtype = "kb"
 $datafile.alter()
}
 
# change log file size and autogrowth
foreach($logfile in $db.logfiles)
{
 $logfile.size= 524288
 $logfile.growth = 131072
 $logfile.growthtype = "kb"
 $logfile.alter()
 }

 $db.drop()