#1 WSFC cluster per AG group
#2 Nodes in West US AG and 2 nodes in East US & DAG to connect them
$inst1=""
$inst2=""
$primary_nic1=""
$primary_nic2=""
$clust1=""

Install-WindowsFeature –Name Failover-Clustering –IncludeManagementTools -ComputerName $inst1
Install-WindowsFeature –Name Failover-Clustering –IncludeManagementTools -ComputerName $inst2

#Check the nodes are good to cluster
Test-Cluster -Node $inst1, $inst2 -Ignore Storage
#create cluster
New-Cluster -Name $clust1 –Node $inst1, $inst2 –StaticAddress $primary_nic1, $primary_nic2 -NoStorage



#swap nodes:
Remove-ClusterNode -Cluster $clust1 -Name $inst2 -Force
Add-ClusterNode -Cluster $clust1 -Name $inst1 



#view cluster objects:
Get-Cluster $clust1
Get-ClusterNode -Cluster $clust1
Get-ClusterNode -Cluster $clust1 | select name, nodeweight
Get-ClusterGroup -Cluster $clust1
Get-ClusterResource -Cluster $clust1

#destroy cluster:
Get-Cluster -Name $clust1 | Remove-Cluster -Force -CleanupAD