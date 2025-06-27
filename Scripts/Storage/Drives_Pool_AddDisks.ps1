<#do not remove server from the cluster and do not pause cluster node, the new drives will appear on
the Clustered Windows Storage because the VM is part of a cluster that is fine...
To differentiate between drives, just add the new drives on one node at a time 
and create the storage space, then add the drives on the second node.
If that's not possible, then shut down the other nodes to make sure their disks are not visible.

To maximize the storage pool size, add disks that are of equal size, 
the number of disks has to be a minimum of NumberOfColumns on the Pool:
#>
Get-VirtualDisk | Select-Object FriendlyName, NumberOfColumns

#pool to increase in size:
$pool="ServerName SQL Data Disk Pool (F)"  
$stpool = Get-StoragePool -FriendlyName $pool
$vdisk = Get-VirtualDisk -StoragePool $stpool

Get-PhysicalDisk
#check to make sure a storage job is not running:
Get-StorageJob

#select disks to pool (we can filter on RAW PartitionStyle because the newly added disks should be uninitialized:
$Tempdisks = Get-Disk | Where-Object PartitionStyle -eq "RAW" | Get-PhysicalDisk -CanPool $true 
$Tempdisks
#get the LUN numbers of the disks that should be pooled:
Get-Disk | Where-Object PartitionStyle -eq "RAW" | Get-PhysicalDisk | Where-Object CanPool -eq True | Sort -Property Size | Format-Table Size, PhysicalLocation

#make sure disks don't get automatically clustered
Get-StorageSubSystem | Fl AutomaticCl*
Get-StorageSubSystem | Where AutomaticClusteringEnabled -eq $true | Set-StorageSubSystem -AutomaticClusteringEnabled $false

$PhysicalDisksForPool = Get-PhysicalDisk -CanPool $True | Where-Object {$_.PhysicalLocation -match "LUN 12" -or $_.PhysicalLocation -match "LUN 11" -or $_.PhysicalLocation -match"LUN 14"}
$PhysicalDisksForPool

#add disks to the pool:
Add-PhysicalDisk -StoragePoolFriendlyName $pool -PhysicalDisks $PhysicalDisksForPool

#increase the size of the virtual disk:
$addBytes = get-virtualDiskSupportedSize -storagePoolFriendlyName $pool | Select-Object -Property VirtualDiskSizeMax
$Virtualdiskresize = $addBytes.VirtualDiskSizeMax  + $vdisk.Size
Resize-VirtualDisk -FriendlyName $vdisk.FriendlyName -Size ($Virtualdiskresize)

#increase the size of the pool:
$Partition = $vdisk | Get-Disk | Get-Partition | Where PartitionNumber -Eq 2
$Partition | Resize-Partition -Size ($Partition | Get-PartitionSupportedSize).SizeMax


#to rebalance data across all disks in the pool:  (may take a very long time)
Get-StoragePool -FriendlyName $pool | Optimize-StoragePool

Optimize-Volume -DriveLetter F: -ReTrim -SlabConsolidate -Verbose
