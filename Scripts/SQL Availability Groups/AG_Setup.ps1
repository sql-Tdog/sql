#nothing should be created in AD for AG, only for listener and cluster (no DNS records for AG)
#there should be 2 NICs on each server: a primary NIC and a listener NIC
#for listener, records should have listener_nic addresses 
#for cluster, remove DNS records, there should be no records containing DNS


$inst1=""
$inst2=""
$list_ip1=""
$list_ip2=""
$clust1=""
$AGname1=""
$listener1=""
$gmsaSQL1="$"

#to get subnet mask, run ipconfig and look at Subnet Mask:
ipconfig
$list_ip_full1=("$list_ip1/255.255.255.240", "$list_ip2/255.255.255.240")
$AD=$Env:userdomain
$fqdn=$env:userdnsdomain

#Enable AlwaysOn so that we can use AGs
enable-SQLAlwaysOn -ServerInstance $inst1 -force
enable-SQLAlwaysOn -ServerInstance $inst2 -force

get-service -name MSSQLSERVER -Computername $inst1 | Restart-Service -Force
get-service -name MSSQLSERVER -Computername $inst2 | Restart-Service -Force

get-service -name SQLServerAgent -Computername $inst1 | Set-Service -Status Running 
get-service -name SQLServerAgent -Computername $inst2 | Set-Service -Status Running 

#if the above fails with "SQL Server WMI provider not available", it is most likely a firewall block
 
get-service -name SQLServerAgent, MSSQLSERVER -ComputerName $inst1
get-service -name SQLServerAgent, MSSQLSERVER -ComputerName $inst2


#setup endpoints
New-SqlHADREndpoint -Path "SQLSERVER:\SQL\$inst1\Default" -Name "Hadr_endpoint"
Set-SqlHADREndpoint -Path "SQLSERVER:\Sql\$inst1\Default\Endpoints\Hadr_endpoint" -State Started
New-SqlHADREndpoint -Path "SQLSERVER:\SQL\$inst2\Default" -Name "Hadr_endpoint"
Set-SqlHADREndpoint -Path "SQLSERVER:\Sql\$inst2\Default\Endpoints\Hadr_endpoint" -State Started



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


Invoke-Sqlcmd -ServerInstance $inst1 -Query $Query 
Invoke-Sqlcmd -ServerInstance $inst2 -Query $Query 


#define replicas
#use primary nic for database mirroring endpoints to separate application users traffic from database mirroring
$endpoint1="TCP://$inst1.$fqdn`:5022"
$endpoint2="TCP://$inst2.$fqdn`:5022"
$primaryReplica = New-SqlAvailabilityReplica -Name $inst1 -EndpointURL $endpoint1 -AvailabilityMode "SynchronousCommit"  -FailoverMode  "Automatic"  -Version 16 -AsTemplate 
$secondaryReplica = New-SqlAvailabilityReplica -Name $inst2 -EndpointURL $endpoint2 -AvailabilityMode "SynchronousCommit"  -FailoverMode "Automatic" -Version 16 -AsTemplate  

$primaryServer = get-item "SQLSERVER:\SQL\$inst1\DEFAULT" 

#create the AG:
New-SqlAvailabilityGroup -Name $AGname1 -InputObject $primaryServer -AvailabilityReplica @($primaryReplica,$secondaryReplica)  

#if New-SqlAvailabilityGroup fails with replica manager is waiting for the computer to start the WSFC:
Start-ClusterNode -NodeName $inst1


#set permissions for the AG:
$Query="ALTER AUTHORIZATION ON AVAILABILITY GROUP::$AGname1 TO [$AD\$gmsaSQL1];
GO
ALTER AVAILABILITY GROUP $AGname1 GRANT CREATE ANY DATABASE;
"
Invoke-Sqlcmd -ServerInstance $inst1 -Query $Query 


# Join the secondary replica to the availability group.  
Join-SqlAvailabilityGroup -Path "SQLSERVER:\SQL\$inst2\Default" -Name $AGname1  
Invoke-Sqlcmd -ServerInstance $inst2 -Query $Query 

#Create listener
$AG_Path="SQLSERVER:\Sql\$inst1\DEFAULT\AvailabilityGroups\$AGname1"
New-SqlAvailabilityGroupListener -Name $listener1 -StaticIp $list_ip_full1 -Path $AG_Path -Port 1433


#After the AG is setup set the clustered params and restart the resources
$AGName_Listener1="$AGname1`_$listener1"
get-ClusterResource -Cluster $clust1 -Name $AGName_Listener1 | set-ClusterParameter RegisterAllProvidersIP 1
get-ClusterResource -Cluster $clust1 -Name $AGName_Listener1 | set-ClusterParameter HostRecordTTL 300
stop-clusterresource -Cluster $clust1 -Name $AGName_Listener1
start-clusterresource -Cluster $clust1 -Name $AGName_Listener1
Start-ClusterResource  -Cluster $clust1 -Name $AGname1


