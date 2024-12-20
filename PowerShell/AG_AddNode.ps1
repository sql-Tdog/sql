$newNode=""
$AGListener=""
$AGname=""

$AD=$Env:userdomain
$fqdn=$env:userdnsdomain

#Service account of the nodes in the AG:
$gmsaSQL1="$"

#if AG is part of a DAG, service accounts of the other AGs:
$gmsaSQL2="$"
$gmsaSQL3="$"

#Enable AlwaysOn so that we can use AGs
enable-SQLAlwaysOn -ServerInstance $newNode -force

get-service -name SQLServerAgent -Computername $newNode | Set-Service -Status Running
get-service -name SQLServerAgent, MSSQLSERVER -ComputerName $newNode


#setup endpoints
New-SqlHADREndpoint -Path "SQLSERVER:\SQL\$newNode\Default" -Name "Hadr_endpoint"
Set-SqlHADREndpoint -Path "SQLSERVER:\Sql\$newNode\Default\Endpoints\Hadr_endpoint" -State Started


#set permissions
$Query="USE [master]
CREATE LOGIN [$AD\$gmsaSQL1] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
GO
GRANT ALTER ANY AVAILABILITY GROUP TO [$AD\$gmsaSQL1];
GRANT CONNECT SQL TO [$AD\$gmsaSQL1];
GRANT VIEW SERVER STATE TO [$AD\$gmsaSQL1];
GO
ALTER EVENT SESSION [AlwaysOn_health] ON SERVER WITH (STARTUP_STATE=ON);
GO
GRANT CONNECT ON ENDPOINT::Hadr_endpoint TO [$AD\$gmsaSQL1]
GO
ALTER AUTHORIZATION ON ENDPOINT::Hadr_endpoint TO [$AD\$gmsaSQL1];
GO
IF (SELECT state FROM sys.endpoints WHERE name='Hadr_endpoint')<>0
BEGIN
	ALTER ENDPOINT [Hadr_endpoint] STATE=STARTED
END"


Invoke-Sqlcmd -ServerInstance $newNode -Query $Query 

#add to the AG:
$tsql="
ALTER AVAILABILITY GROUP $AGname ADD REPLICA ON '$newNode' WITH 
(ENDPOINT_URL = `'TCP://$newNode.CORP.DOCUSIGN.NET:5022`', FAILOVER_MODE = MANUAL, AVAILABILITY_MODE = SYNCHRONOUS_COMMIT, BACKUP_PRIORITY = 50, 
SEEDING_MODE=MANUAL, SECONDARY_ROLE(ALLOW_CONNECTIONS = ALL));
"
Invoke-Sqlcmd -ServerInstance $AGListener -Query $tsql 


#set permissions for the AG:
$Query="ALTER AUTHORIZATION ON AVAILABILITY GROUP::$AGname TO [$AD\$gmsaSQL1];
GO
ALTER AVAILABILITY GROUP $AGname GRANT CREATE ANY DATABASE;
"
Invoke-Sqlcmd -ServerInstance $newNode -Query $Query 


# Join the secondary replica to the availability group.  
$tsql="ALTER AVAILABILITY GROUP $AGname JOIN; "
Invoke-Sqlcmd -ServerInstance $newNode -Query $tsql 

#set read-only routing next