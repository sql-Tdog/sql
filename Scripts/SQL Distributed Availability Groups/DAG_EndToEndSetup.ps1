<#
Set up a Distributed Availability Group for an existing AG and a new AG 

Process
Prepare the setup
Select appropriate SKU for the new AG setup.  
For SQL VMs, use Intel processors.  Memory is determined by the SKU.
Review disk setup on existing AG and select disk type and sizes for new AG
Use Ultra Disks and NVME controllers for data drives on very busy AGs that require the best 
performance (lowest latency).

Prepare the TerraForm code to spin up the VMs 
Each new VM must be in a unique subnet 
Double check disk configuration:
Tempdb on simple disk
System - 128GB, simple disk
Logs - 1 TB, simple disk
Data - a 3 disk configuration
Spread out the VMs across the 3 zones.  

Create new GMSAs, pre-stage SQL AD objects and A records

Install SQL on new VMs
Configure service accounts
#>
$gmsaSQL="gmSQLDSNA1P01$"
$gmsaAgent="gmSQLDSNA1PA01$"

#install them on local SQL Server:
Install-AdServiceAccount $gmsaSQL -ErrorAction Stop
Install-AdServiceAccount $gmsaAgent -ErrorAction Stop

#test on local server:
Test-ADServiceAccount -Identity $gmsaSQL
Test-ADServiceAccount -Identity $gmsaAgent

<#
Set the GMSA accounts as SQL Service accounts 
Verify connectivity to each server with SSMS.  
If this error is encountered:  The target principal name is incorrect.  
Cannot generate SSPI context. 

1. Remove the GMSA account from the server by setting the service account to a built in Network Service account
2. Reboot server
3. Test connectivity and if it works continue to the next step.
4. Add the GMSA account back as the SQL service account.
5. Restart services.
6. Try connecting again. 

Deploy standard objects to new VM.s
Run tests, repair failures.
#>

#create cluster and new AG:
#new servers and their IPs:
$inst1="xxx"
$inst2="xxx"
$primary_nic1="xxx"
$primary_nic2="xxx"
$list_ip1="xxx"
$list_ip2="xxx"

#new cluster to create:
$clust1="xxx"

#check IP address of each node:
nslookup $inst1
nslookup $inst2

#install the Failover Clustering feature
Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools -ComputerName $inst1
Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools -ComputerName $inst2

#Check the nodes are good to cluster
Test-Cluster -Node $inst1, $inst2 -Ignore Storage
#create cluster
New-Cluster -Name $clust1 -Node $inst1, $inst2 -StaticAddress $primary_nic1, $primary_nic2 -NoStorage


#Set the cluster settings to standard
(get-cluster).CrossSubnetThreshold = 10;
(get-cluster).CrossSubnetDelay = 4000;
(get-cluster).RouteHistoryLength = 20;

#view cluster objects:
Get-Cluster $clust1
Get-ClusterNode -Cluster $clust1
Get-ClusterNode -Cluster $clust1 | select name, nodeweight
Get-ClusterGroup -Cluster $clust1
Get-ClusterResource -Cluster $clust1
Get-ClusterResource -Name "Cluster Name" | Get-ClusterParameter

#new AG details:
$AGname1="xxx"
$listener1="xxx"
$list_ip_full1=("$list_ip1/255.255.255.240", "$list_ip2/255.255.255.240")
$AD=$Env:userdomain
$fqdn=$env:userdnsdomain
$gmsaSQL1="xxx$"

#Enable AlwaysOn so that we can use AGs
enable-SQLAlwaysOn -ServerInstance $inst1 -force
enable-SQLAlwaysOn -ServerInstance $inst2 -force

get-service -name SQLServerAgent -Computername $inst1 | Set-Service -Status Running
get-service -name SQLServerAgent -Computername $inst2 | Set-Service -Status Running 
 
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


$endpoint1="TCP://$inst1.$fqdn`:5022"
$endpoint2="TCP://$inst2.$fqdn`:5022"
$readrouting1 = "TCP://$inst1.$fqdn`:1433"
$readrouting2 = "TCP://$inst1.$fqdn`:1433"
$primaryReplica = New-SqlAvailabilityReplica -Name $inst1 -EndpointURL $endpoint1 -ReadonlyRoutingConnectionUrl $readrouting1 -AvailabilityMode "SynchronousCommit"  -FailoverMode  "Automatic"  -Version 16 -AsTemplate 
$secondaryReplica = New-SqlAvailabilityReplica -Name $inst2 -EndpointURL $endpoint2 -ReadonlyRoutingConnectionUrl $readrouting2 AvailabilityMode "SynchronousCommit"  -FailoverMode "Automatic" -Version 16 -AsTemplate  
 

$primaryServer = get-item "SQLSERVER:\SQL\$inst1\DEFAULT" 


#create the AG:
New-SqlAvailabilityGroup -Name $AGname1 -InputObject $primaryServer -AvailabilityReplica @($primaryReplica,$secondaryReplica)

#if New-SqlAvailabilityGroup fails with replica manager is waiting for the computer to start the WSFC:
Start-ClusterNode -NodeName $inst1


#set permissions for the AG:
$Query="ALTER AUTHORIZATION ON AVAILABILITY GROUP::$AGname TO [$AD\$gmsaSQL];
GO
ALTER AVAILABILITY GROUP $AGname GRANT CREATE ANY DATABASE;"
Invoke-Sqlcmd -ServerInstance $inst1 -Query $Query 

# Join the secondary replica to the availability group.  
Join-SqlAvailabilityGroup -Path "SQLSERVER:\SQL\$inst2\Default" -Name $AGname1  
Invoke-Sqlcmd -ServerInstance $inst2 -Query $Query 

#Create listener
$AG_Path="SQLSERVER:\Sql\$inst1\DEFAULT\AvailabilityGroups\$AGname1"
New-SqlAvailabilityGroupListener -Name $listener1 -StaticIp $list_ip_full1 -Path $AG_Path -Port 1433


#After the AG is setup set the clustered params and restart the resources
$AGName_Listener1="$AGname1`_$listener1"
get-ClusterResource -Name $AGName_Listener1 | set-ClusterParameter RegisterAllProvidersIP 1
get-ClusterResource $AGName_Listener1 | set-ClusterParameter HostRecordTTL 300
stop-clusterresource $AGName_Listener1
start-clusterresource $AGName_Listener1
Start-ClusterResource $AGname1

#Create storage witness account & configure cluster quorum
#storage account for DSDB cluster Cloud Witness for northeurope
  "sqleuwitness1" : {
    "account_tier" : "Standard",
    "account_kind" : "StorageV2",
    "account_replication_type" : "ZRS",
    "location" : "northeurope",
    "min_tls_version" : "TLS1_2",
    "key_operator_service_role_enabled" : "true"
  }

#set quoru:
$clust="xxx"
$storageAccountName="xxx"
$managedIdClientId = "xxx"
$AD="$Env:userdomain\$Env:username"
$resourceGroup="xxx"
# Connect to Azure with user-managed-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity -AccountId $managedIdClientId).context
# set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription  
$AzureContext
#get storage account key, needed to access storage containers:  
$StAccountKey=Get-AzStorageAccountKey -ResourceGroupName $resourceGroup -Name $storageAccountName 
Set-ClusterQuorum -Cluster $clust1 -CloudWitness -AccountName $storageAccountName -AccessKey $StAccountKey[0].value 
Get-ClusterQuorum -Cluster $clust1


#Copy backup certificates and backup container keys to the new nodes
#Restore full database backups to the new nodes with NORECOVERY
#Start restoring t-log backups for these databases on the new nodes.  
#Leave databases in restoring mode.

#Copy over logins 
#Create the DAG

$AG1="xxx"             #existing AG
$AG2="xxx"           #new AG
$DAGName="xxx"
$List1="xxx"          #existing AG's listener
$List2="xxx"        #new AG's listener
$AG1acct="xxx$"      #existing AG's service account
$AG2acct="xxx$"   #new AG's service account

#existing AG's nodes:
$inst1="xxx"
$inst2="xxx"
$inst2b="xxx"

#new AG's nodes:
$inst3="xxx"
$inst4="xxx"

$FQDN=$env:userdnsdomain
$AD="$Env:userdomain"


#service account from AG 1 to AG 2:
$Query="CREATE LOGIN [$AD\$AG1acct] FROM WINDOWS WITH DEFAULT_DATABASE=[master]
GO
GRANT ALTER ANY AVAILABILITY GROUP TO [$AD\$AG1acct];
GRANT CONNECT SQL TO [$AD\$AG1acct];
GRANT VIEW SERVER STATE TO [$AD\$AG1acct];
GO
GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [$AD\$AG1acct]"
Invoke-Sqlcmd -ServerInstance $inst3 -Query $Query 
Invoke-Sqlcmd -ServerInstance $inst4 -Query $Query 


#service account from AG 2 to AG 1:
$Query="CREATE LOGIN [$AD\$AG2acct] FROM WINDOWS WITH DEFAULT_DATABASE=[master]
GO
GRANT ALTER ANY AVAILABILITY GROUP TO [$AD\$AG2acct];
GRANT CONNECT SQL TO [$AD\$AG2acct];
GRANT VIEW SERVER STATE TO [$AD\$AG2acct];
GO
GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [$AD\$AG2acct]"
Invoke-Sqlcmd -ServerInstance $inst1 -Query $Query 
Invoke-Sqlcmd -ServerInstance $inst2 -Query $Query

#create the DAG on global primary:
$Query="CREATE AVAILABILITY GROUP [$DAGName]  
   WITH (DISTRIBUTED)  
   AVAILABILITY GROUP ON  
      '$AG1' WITH    
      (  
         LISTENER_URL = 'tcp://$List1.$FQDN`:5022',    
         AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,  
         FAILOVER_MODE = MANUAL,  
         SEEDING_MODE = MANUAL 
      ),  
      '$AG2' WITH    
      ( 
         LISTENER_URL = 'tcp://$List2.$FQDN`:5022',  
         AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,  
         FAILOVER_MODE = MANUAL,  
         SEEDING_MODE = MANUAL 
      );    
GO  
"
Invoke-Sqlcmd -ServerInstance $List1 -Query $Query 

#join the secondary AG to the DAG
$Query="ALTER AVAILABILITY GROUP [$DAGName]  
   JOIN  
   AVAILABILITY GROUP ON    
      '$AG1' WITH    
      (  
         LISTENER_URL = 'tcp://$List1.$FQDN`:5022',    
         AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,  
         FAILOVER_MODE = MANUAL,  
         SEEDING_MODE = MANUAL 
      ),  
      '$AG2' WITH    
      ( 
         LISTENER_URL = 'tcp://$List2.$FQDN`:5022',  
         AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,  
         FAILOVER_MODE = MANUAL,  
         SEEDING_MODE = MANUAL 
      );    
GO"
Invoke-Sqlcmd -ServerInstance $List2 -Query $Query 

#When all t-log have been restored, add the database to the DAG .  
$db1="xxx"


$Query="ALTER DATABASE $db1 SET HADR AVAILABILITY GROUP = $AG2;"
Invoke-Sqlcmd -ServerInstance $inst3 -Query $Query 
Invoke-Sqlcmd -ServerInstance $inst4 -Query $Query 

<#
#Configure new AG settings
#Backup preference:
#Backup preference can be set on the secondary AG of the DAG but there are some nuances on 
how the t-log backups work 

Read-only routing does not work on secondary AG of the DAG.  All reads will go to the primary node.

#>

