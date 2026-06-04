<#Can we extend individual disks in a pool?
Test it out....
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

# add disks to the pool:
Add-PhysicalDisk -StoragePoolFriendlyName $pool -PhysicalDisks $PhysicalDisksForPool

#view the column size of the virtual disk of the pool:
Get-VirtualDisk
$vdisk = Get-VirtualDisk -FriendlyName "xxx"
$vdisk | Select-Object FriendlyName, NumberOfColumns

#rebalance data across all disks in the pool so that we can expand the virtual disk
#this is needed if the number of disks added does not match the number of columns
#if ran with -AsJob parameter: it is a lightweight background process 
#may take a very long time depending on size of disk
Get-StoragePool -FriendlyName $pool | Optimize-StoragePool
Optimize-Volume -DriveLetter F: -ReTrim -SlabConsolidate -Verbose


#increase the size of the virtual disk:
$addBytes = get-virtualDiskSupportedSize -storagePoolFriendlyName $pool | Select-Object -Property VirtualDiskSizeMax
$Virtualdiskresize = $addBytes.VirtualDiskSizeMax  + $vdisk.Size
Resize-VirtualDisk -FriendlyName $vdisk.FriendlyName -Size ($Virtualdiskresize)

#increase the size of the disk presented to the OS:
$Partition = $vdisk | Get-Disk | Get-Partition | Where-Object PartitionNumber -Eq 2
$Partition | Resize-Partition -Size ($Partition | Get-PartitionSupportedSize).SizeMax


<#####this can be accomplished via Server Manager GUI######
1. after new disks are created, open Server Manager > File and Storage Services on left tab menu
2. click on Storage Pools on the left hand side and wait for all disk data to be populated in center
3. select storage pool to be upsized and clicks on TASKS drop down menu in PHYSICAL DISKS tile
4. in the pop-up, expand Name column to see the full name of disk and select disks that match the 
server storage pool to be upsized, click OK; the TASK PROGRESS may not match selected 
5. if the number of disks matches the column size of the virtual disk, right click on Virtual Disk
and "Extend Virtual Disk"; select Maximum size
6.  if this is not possible, then the storage pool needs to be optimized: (could take days)
Get-StoragePool -FriendlyName "SQL Data Pool (F)" | Optimize-StoragePool -AsJob
7.  Once VD is extended, expand the drive:
Get-VirtualDisk 
$vdisk = Get-VirtualDisk -FriendlyName "SQL Data Disk (F)"

#if the virtual disks are all named the same, try different ways of selecting the rigth one
$vdisk = Get-VirtualDisk -FriendlyName "SQL Data Disk (F)" | Where-Object FootprintOnPool -EQ 6588479832064
$vdisk = Get-VirtualDisk -FriendlyName "SQL Data Disk (F)" | Where-Object FootprintOnPool -EQ 6588479832064 | Select-Object -Skip 2 -First 1

#check size of partition to verify that the right one is selected, it should not be the new size
$Partition = $vdisk | Get-Disk | Get-Partition | Where PartitionNumber -Eq 2
$Partition | Resize-Partition -Size ($Partition | Get-PartitionSupportedSize).SizeMax

#verify size of drive:
Get-WmiObject -Class Win32_volume -Filter "Filesystem='NTFS'" -ComputerName 'servername' | Where-Object Name -EQ "F:\" | Select-Object Name, Label, Capacity 

#>