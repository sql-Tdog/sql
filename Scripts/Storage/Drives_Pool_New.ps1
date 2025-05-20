<#do not remove server from the cluster and do not pause cluster node, the new drives will appear on the Clustered Windows Storage 
because the VM is part of a cluster that is fine...to differentiate between drives, just add the new drives on one node at a time 
and create the storage space, then add the drives on the second node
#>
Get-ClusterResource
Get-StorageJob

$DriveLetter = "I"
$VM = $env:COMPUTERNAME

#check if Automatic Clustering for the storage subsystem is enabled, we want to disable it to prevent the pool from getting clustered
Get-StorageSubSystem | Fl AutomaticCl*
Get-StorageSubSystem | Where AutomaticClusteringEnabled -eq $true | Set-StorageSubSystem -AutomaticClusteringEnabled $false

#to make sure the right disks are selected, we can compare what we see on the VM to what's in the portal
#first, check where the new disks are showing up...they should be in the Clustered Windows Storage if the VM is in a cluster:
Get-StorageSubSystem -FriendlyName "Clustered Windows Storage*" | Get-PhysicalDisk -CanPool $True
Get-StorageSubSystem -FriendlyName "Windows Storage*" | Get-PhysicalDisk -CanPool $True

#get the LUN numbers of the disks that should be pooled:
Get-PhysicalDisk | Where-Object CanPool -eq True | Sort -Property Size | Format-Table Size, PhysicalLocation
Get-PhysicalDisk | Where-Object CanPool -eq True | Sort -Property Size | Format-Table Size, PhysicalLocation, SerialNumber

$PhysicalDisksForPool = Get-PhysicalDisk -CanPool $True | Where-Object {$_.PhysicalLocation -match "LUN [678]"}
$DiskCountForNumberOfColumns = $PhysicalDisksForPool.Count

$PoolParams = @{
                "FriendlyName"                 = "$VM SQL Data Pool ($($DriveLetter))"
                "StorageSubSystemFriendlyName" = "Clustered Windows Storage*"
                "PhysicalDisks"                = $PhysicalDisksForPool
                "ResiliencySettingNameDefault" = "Simple"
                "ProvisioningTypeDefault"      = "Fixed"
            }
$VirtualDiskParams = @{
                "FriendlyName"          = "SQL Data Disk ($($DriveLetter))"
                "Interleave"            = 65536
                "NumberOfColumns"       = $DiskCountForNumberOfColumns
                "ResiliencySettingName" = "Simple"
                "UseMaximumSize"        = $true
            }
$ParitionParams = @{
    "DriveLetter"    = $DriveLetter
    "UseMaximumSize" = $true
}

$VolumeParams = @{
    "FileSystem"         = "NTFS"
    "NewFileSystemLabel" = "SQL Data ($($DriveLetter))"
    "AllocationUnitSize" = 65536
    "Confirm"            = $false
    "UseLargeFRS"        = $true
}


$CreatePool = New-StoragePool @PoolParams | New-VirtualDisk @VirtualDiskParams | Initialize-Disk -PartitionStyle GPT -PassThru | New-Partition @ParitionParams | Format-Volume @VolumeParams

Set-Location $DriveLetter`:\
mkdir $DriveLetter`:\MSSQL\Data
mkdir $DriveLetter`:\MSSQL\Log


#clean up in case something goes wrong:
Get-VirtualDisk
Remove-VirtualDisk -FriendlyName "SQL Data Disk ()"
Get-StoragePool
Remove-StoragePool -FriendlyName "SQL Data Disk Pool ()"
