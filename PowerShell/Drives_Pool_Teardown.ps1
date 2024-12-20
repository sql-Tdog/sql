####################Teardown Storage Pool on a clustered node################

<#do not remove server from the cluster and do not pause cluster node, the new drives will appear on the Clustered Windows Storage 
because the VM is part of a cluster that is fine...to differentiate between drives, just add the new drives on one node at a time 
and create the storage space, then add the drives on the second node
#>
Get-ClusterResource
Get-StorageJob

$DriveLetter = "F"
$VM = $env:COMPUTERNAME

#check if Automatic Clustering for the storage subsystem is enabled, we want to disable it to prevent the pool from getting clustered
Get-StorageSubSystem | Fl AutomaticCl*
Get-StorageSubSystem | Where AutomaticClusteringEnabled -eq $true | Set-StorageSubSystem -AutomaticClusteringEnabled $false

Get-StoragePool | Where-Object {$_.FriendlyName -ne "Primordial"}

#remove old pool:
$Vdisk=Get-VirtualDisk
Remove-VirtualDisk -FriendlyName  $Vdisk.FriendlyName
$pool=Get-StoragePool | Where-Object {$_.FriendlyName -ne "Primordial"}
Remove-StoragePool -FriendlyName $pool.FriendlyName

#if disks are cleared, partitionstyle will be Raw, clear them:
clear-disk -number 3 -RemoveData
clear-disk -number 4 -RemoveData

