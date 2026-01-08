#After removing a node from the AG permanently, remove its IP Address from the listener role
#Go to Failover Cluster Manager>Roles>Listener>Resources tab>Expand Listener under Server Name>View IP addresses
#Remove the one that is no longer in service
#View the properties of the listener in SSMS, the removed IPs should be gone

#Remove node from AG:
$AGname = ""
$AGListener = ""
$nodeToRemove = ""
$tsql="ALTER AVAILABILITY GROUP $AGname REMOVE REPLICA ON '$nodeToRemove'"
Invoke-Sqlcmd -ServerInstance $AGListener -Query $tsql 

#remove node from cluster:
$clusterName = ""
$listener = ""
Remove-ClusterNode -Cluster $clusterName = "" -Name $nodeToRemove

#remove resources from cluster:
$clusterResources = Get-ClusterResource -Cluster $clusterName
$clusterResources
$IPtoDelete = ""
$AG_IP = "$AGname`_$IPtoDelete"
$cluterResourceToDelete = $clusterResources | select Name, State, OwnerGroup, ResourceType |  where { $_.ResourceType -eq "IP Address" -and $_.Name -like "$IPtoDelete" }
$cluterResourceToDelete | ft -autosize

#verify these lines by testing them:
Get-ClusterResource -Cluster $clusterName -Name $AG_IP | Remove-ClusterResource
Get-ClusterResource -Cluster $clusterName -Name "IP Address 10.xxx.xxx.91" | Remove-ClusterResource
Get-ClusterResource -Cluster $clusterName
nslookup $listener 