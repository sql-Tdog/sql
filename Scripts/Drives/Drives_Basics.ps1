#reset drives to uninitialized status:
clear-disk -number 6 -RemoveData -Confirm:$False
clear-disk -number 3 -RemoveData -Confirm:$False
clear-disk -number 4 -RemoveData -Confirm:$False
clear-disk -number 5 -RemoveData -Confirm:$False

#to delete storage pool, first delete virtual disks
#get a list of all virtual disks:
Get-VirtualDisk
Remove-VirtualDisk -FriendlyName "SQL Data Disk (F)"
Remove-VirtualDisk -FriendlyName "SQL System Disk (E)"
Remove-VirtualDisk -FriendlyName "SQL TempDB Disk (T)"
Remove-VirtualDisk -FriendlyName "SQL Log Disk (L)"

Get-StoragePool
Remove-StoragePool -FriendlyName "SQL System Disk Pool (E)"
Remove-StoragePool -FriendlyName "SQL Log Disk Pool (L)"
Remove-StoragePool -FriendlyName "SQL TempDB Disk Pool (T)"
Remove-StoragePool -FriendlyName "SQL Data Disk Pool (F)"

#reassign drive letter for DVD drive 
$Drive = Get-CimInstance -ClassName Win32_Volume -Filter "DriveLetter = 'E:'"
$Drive | Set-CimInstance -Property @{DriveLetter ='X:'}
#format 4 disks 
Get-Disk -Number 2 | New-Volume -FileSystem NTFS -DriveLetter E -FriendlyName 'Data' -AllocationUnitSize 65536
Get-Disk -Number 3 | New-Volume -FileSystem NTFS -DriveLetter F -FriendlyName 'Data' -AllocationUnitSize 65536
Get-Disk -Number 4 | New-Volume -FileSystem NTFS -DriveLetter T -FriendlyName 'TempDb' -AllocationUnitSize 65536
Get-Disk -Number 5 | New-Volume -FileSystem NTFS -DriveLetter L -FriendlyName 'Log' -AllocationUnitSize 65536

##Get Uninitialized Disks and Format them
Get-Disk | where partitionstyle -eq ‘raw’ 
#this will return disk number, use it to format disk and assign letter:
Get-Disk -Number 5 | New-Volume -FileSystem NTFS -DriveLetter H -FriendlyName 'SQL Data (H)' -AllocationUnitSize 65536

#Create folders
mkdir "H:\MSSQL\Data" | Out-Null;
mkdir "H:\MSSQL\Log" | Out-Null;


### CREATE STORAGE POOL
#create one for data drive with read-only cache and another one for log drive with no caching
$StripeSize = 65536
$allocationUnit = 65536
  
[array]$PhysicalDisks = Get-StorageSubSystem -FriendlyName "Windows Storage*" | Get-PhysicalDisk -CanPool $True
  
$DiskCount = $PhysicalDisks.count
  
New-StoragePool -FriendlyName "SQLDATAPOOL" -StorageSubsystemFriendlyName "Windows Storage*" -PhysicalDisks $PhysicalDisks | New-VirtualDisk -FriendlyName "SQLDATA01" -Interleave $StripeSize -NumberOfColumns $DiskCount -ResiliencySettingName simple –UseMaximumSize |Initialize-Disk -PartitionStyle GPT -PassThru | New-Partition -DriveLetter "G" -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel "SQLDATA01" -AllocationUnitSize $allocationUnit -Confirm:$false -UseLargeFRS


#Export data of all drives on server:
@{
    StoragePools=Get-StoragePool    
    PhysicalDisks=Get-PhysicalDisk
    VirtualDisks=Get-VirtualDisk   
    StorageTiers=Get-StorageTier    
    StorageJobs=Get-StorageJob    
    Disks=Get-Disk    
    Partitions=Get-Partition    
    Volumes=Get-Volume    
    ClusterResource=Get-ClusterResource    
    CSV=Get-ClusterSharedVolume    
    SNV=Get-PhysicalDiskSNV    
    ClusterNetwork =Get-ClusterNetwork
    CluterNode=Get-ClusterNode
    }|Export-Clixml-Path$HOME\cluster_diag_$env:computername.xml