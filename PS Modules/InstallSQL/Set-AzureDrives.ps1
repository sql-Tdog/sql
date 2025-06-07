<#
.SYNOPSIS
Creates, formats, and assigns drives for Azure nvme storage.

.DESCRIPTION
Grabs a list of nvme drives installed on an Azure VM.
  - Initializes each disk with the GPT format (if required)
  - Assigns a drive letter (if not already assigned)
  - Creates a new partition with the maximum size of the drive
  - Formats the volume with a 64K allocation unit and large FRS

.EXAMPLE
Set-AzureDrives
#>

Function Set-AzureDrives {
    Write-Host "Configure simple disks first: System, Log, Data, or TempDB" -ForegroundColor Yellow
    try {

        # Kill off the ShellHWDetection service so we don't get the Explorer prompts to format drives
        Stop-Service -Name ShellHWDetection

        # Check if a CDROM drive is mounted with a drive letter (and if it is, remove the drive letter)
        Remove-CdRomDriveLetter

        #Filter disks: C and D drive will not have RAW Partition Style
        $Disks = (Get-Disk | Where-Object { $_.PartitionStyle -eq "RAW" } )
        if(!$Disks) {
            $Go = Read-Host "No disks available.  Enter Yes to continue, No to quit"
            if ($Go -eq "No") {
                "No selected.  Quitting."
                Exit
                } 
        } else {
            $DiskList = $Disks.Number
            $DisplayDisks=$Disks | Format-Table 
            $DisplayDisks

            $DiskList = Read-Host "Enter disk numbers that will be simple disks, separated by commas. Enter no to skip setting these."
            if ($DiskList -eq "No") {
                "No selected.  Using existing storage."
                } else {
                $DiskList = $DiskList.Split(',')
                foreach ($Disk in $DiskList) 
                {
                    # Check that the disk is initialized (GPT) or is a RAW disk
                    $CurrentDiskPartitionStyle = (Get-DiskPartitionStyle -DiskNumber $Disk).PartitionStyle
                    Write-Host "Starting to configure Disk $Disk.  Current partition style : $CurrentDiskPartitionStyle" -ForegroundColor Cyan
                    if ($CurrentDiskPartitionStyle -eq "RAW") 
                    {
                        # Init the disk as GPT
                        Write-Host "  Initializing disk: $Disk" -ForegroundColor Cyan
                        Initialize-Disk -Number $Disk -PartitionStyle GPT
                    }

          

                    # Check to see that the disk does not already have a volume associated
                    if (Get-VolumeForDisk -DiskNumber $Disk)
                    {
                        Write-Host "  Disk $Disk already has a volume associated"
                
                             } 
                    else 
                    {
                        $DriveType = Read-Host "Enter Drive Type: Log, TempDB, or System"
                        $NewDriveLetter = Read-Host "Enter drive letter. E for System, L for Logs, T for TempDB"
                        $NewLabel= "SQL $($DriveType) ($($NewDriveLetter))"
                        New-Partition -DiskNumber $Disk -UseMaximumSize -DriveLetter $NewDriveLetter 
                        Format-Volume -DriveLetter $NewDriveLetter -NewFileSystemLabel $NewLabel -AllocationUnitSize 65536 -UseLargeFRS -Confirm:$false | Out-Null
                        write-host "The $($DriveType) disk ($($NewDriveLetter)) successfully created" -ForegroundColor Green
                    }
                }
            }
            Write-Host "We are finished with simple disks.  Now, we will configure Data Drives on Storage Spaces direct"
            $NewDriveLetter = Read-Host "Enter drive letters for all Data disks to be created, separated by a comma.  Start with F,G,H, etc. "
            $NewDriveLetter = $NewDriveLetter.Split(',')
            foreach ($DriveLetter in $NewDriveLetter) {
                Add-AzureDataDisk -DriveLetter $DriveLetter -DriveType "Data"
            }

            # Start the ShellHWDetection service back up
            Start-Service -Name ShellHWDetection
            Start-Sleep -Seconds 5
            Write-Host "Azure volumes added" -ForegroundColor Green
        }

    } 
    catch 
    {
        Write-Error $_.Exception.Message
    }
}
