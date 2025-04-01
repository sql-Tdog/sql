Add-WindowsFeature RSAT-Clustering-PowerShell

#Windows Failover Cluster uses port 3343, it needs to be open 
$inst1=""
$inst2=""
$primary_nic1=""
$primary_nic2=""
$clust1=""

#check IP address of each node:
nslookup $inst1
nslookup $inst2

#install the Failover Clustering feature
Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools -ComputerName $inst1
Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools -ComputerName $inst2

#Check the nodes are good to cluster
Test-Cluster -Node $inst1, $inst2 -Ignore Storage
#check the validation report for any warnings

#create cluster, specify no storage so that the storage doesn't get clustered
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

#lookup cluster IP addresses:
$fqdn=$env:userdnsdomain
nslookup "$clust1.$fqdn"

#start cluster nodes (if syncing is needed)
Start-ClusterNode -Name $inst1