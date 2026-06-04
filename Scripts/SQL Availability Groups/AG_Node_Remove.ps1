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
Remove-ClusterNode -Cluster $clusterName -Name $nodeToRemove

#view cluster resources:
$clusterResources = Get-ClusterResource -Cluster $clusterName
$clusterResources


#verify IP to delete:
$IPtoDelete = ""  #node's listener IP
$AG_IP = "$AGname`_$IPtoDelete"
$cluterResourceToDelete = $clusterResources | select-object Name, State, OwnerGroup, ResourceType |  Where-Object { $_.ResourceType -eq "IP Address" -and $_.Name -like "$IPtoDelete" }
$cluterResourceToDelete | ft -autosize

#remove old node IP from cluster:
Get-ClusterResource -Cluster $clusterName -Name $AG_IP | Remove-ClusterResource

Get-ClusterResource -Cluster $clusterName

#verify health of listener:
nslookup $AGListener 
$tsql = "select name from sys.databases"
Invoke-Sqlcmd -ServerInstance $AGListener -Query $tsql 

#another way to remove the IP:
Get-ClusterResource -Cluster $clusterName -Name "IP Address 10.xxx.xxx.91" | Remove-ClusterResource
