function Get-DiskLunMapping {

    process {
        $Luns = Get-PhysicalDisk | Where-Object {$_.PhysicalLocation -notmatch "Adapter 1"}  |  Sort -Property PhysicalLocation |  Where-Object {$_.MediaType -ne "Unspecified" } | Select-Object DeviceId, Size, PhysicalLocation, SerialNumber, CannotPoolReason 
        $driveLetters = (Get-PSDrive).Name -match '^[a-z]$'

        foreach ($L in $driveLetters) {
            $Serials= Get-Partition -DriveLetter $L | Get-Disk | Select-Object Serialnumber | ForEach {$_.SerialNumber} 
            foreach ($serial in $Serials) {
                foreach ($disk in $Luns) {
                    $Physical = $disk.PhysicalLocation
                    $index = $Physical.IndexOf("LUN")
                    $LunNumber = $Physical.Substring($index+4)
                    $InAStoragePool = if($disk.CannotPoolReason -eq "In A Pool") { "Yes"} else {"No"}
                    if($Serial -match $disk.SerialNumber) {
                        [PSCustomObject]@{
                            Lun             = $LunNumber
                            DriveLetter     = $L
                            DiskNumber      = $disk.DeviceId
                            #Pool            = $InAStoragePool
                            Size         = [math]::Round($($disk.Size / 1TB),2).ToString() + " TB"
                            #SerialNumber   = $disk.SerialNumber
                        }
                    }
        }
        
            }
        }
        #since we put the drive letter in the storage pool name, use that to get disks in pools:
        $StoragePools = Get-StoragePool | Where-Object {$_.FriendlyName -ne "Primordial"} | Sort-Object -Property FriendlyName -Unique
        foreach ($StoragePool in $StoragePools) {
            $DriveLetter = $StoragePools.FriendlyName
            $index = $DriveLetter.IndexOf("Pool (")
            $DriveLetter = $DriveLetter.Substring($index+6,1)
            $PooledDisks = $StoragePools | Get-VirtualDisk | Get-PhysicalDisk | Select-Object DeviceId,Size,SerialNumber, PhysicalLocation
            foreach($disk in $PooledDisks) {
                $Physical = $disk.PhysicalLocation
                $index = $Physical.IndexOf("LUN")
                $LunNumber = $Physical.Substring($index+4)
                [PSCustomObject]@{
                    Lun             = $LunNumber
                    DriveLetter     = $DriveLetter
                    DiskNumber      = $disk.DeviceId
                    #Pool            = $InAStoragePool
                    Size         = [math]::Round($($disk.Size / 1TB),2).ToString() + " TB"
                    #SerialNumber   = $disk.SerialNumber
                }
            }
        }
    }
}

$DiskLunMap=Get-DiskLunMapping
$DiskLunMap | Sort-Object -Property Lun