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
(ENDPOINT_URL = `'TCP://$newNode.$fqdn`:5022`', FAILOVER_MODE = MANUAL, AVAILABILITY_MODE = SYNCHRONOUS_COMMIT, BACKUP_PRIORITY = 50, 
SEEDING_MODE=MANUAL, SECONDARY_ROLE(READ_ONLY_ROUTING_URL = `'TCP://$newNode.$fqdn`:1433`', ALLOW_CONNECTIONS = ALL));
"
Invoke-Sqlcmd -ServerInstance $AGListener -Query $tsql 

#Open AG listener settings in SSMS and Add the new IP Address
#Otherwise, this error would be thrown:   None of the IP addresses configured for the availability 
#group listener can be hosted by the server 'xxx'. Either configure a public cluster network on which 
#one of the specified IP addresses can be hosted, or add another listener IP address which can be hosted 
#on a public cluster network for this server.  Failed to join local availability replica to availability 
#group 'xxx'.  The operation encountered SQL Server error 19456 and has been rolled back


# Now, join the secondary replica to the availability group.  
$tsql="ALTER AVAILABILITY GROUP $AGname JOIN; "
Invoke-Sqlcmd -ServerInstance $newNode -Query $tsql 



#set permissions for the AG:
$Query="ALTER AUTHORIZATION ON AVAILABILITY GROUP::$AGname TO [$AD\$gmsaSQL1];
GO
ALTER AVAILABILITY GROUP $AGname GRANT CREATE ANY DATABASE;
"
Invoke-Sqlcmd -ServerInstance $newNode -Query $Query 



#set read-only routing next
nslookup $AGListener

#AGListener should return all IP addresses of the nodes in the group, it will update after a failover
#fail over to the new node and verify that you can connect to the listener


#Stop then start the cluster resource to persist the newly added listener IP to the AGL listener.
#After the AG is setup set the clustered params and restart the resources
$clust1 = ""
$listener1 = ""
$AGname1 = ""
$AGName_Listener1="$AGname1`_$listener1"
get-ClusterResource -Cluster $clust1 -Name $AGName_Listener1 | Get-ClusterParameter  
get-ClusterResource -Cluster $clust1 -Name $AGName_Listener1 | set-ClusterParameter RegisterAllProvidersIP 1
get-ClusterResource -Cluster $clust1 -Name $AGName_Listener1 | set-ClusterParameter HostRecordTTL 300
stop-clusterresource -Cluster $clust1 -Name $AGName_Listener1
start-clusterresource -Cluster $clust1 -Name $AGName_Listener1
Start-ClusterResource  -Cluster $clust1 -Name $AGname1


