<#

.SYNOPSIS

.DESCRIPTION

.PARAMETER Request
Pull a new version from a source first, using the Send-Module / Request-Module commands.

.PARAMETER SourceJunction
Use a special version of the source from this directory. If you specify a .zip, it will extract and use that.

.PARAMETER ComputerName
By default all computers in a number of categories are published to. This overrides to just one or more computers.

.NOTES
It's important that any special functions here should also be added to
New-ModuleInstall, for first time installs to a new domain.

#>

function Publish-Module {
    [CmdletBinding(DefaultParameterSetName = "Existing")]
    param (
        [Parameter(ParameterSetName = "Request")]
        [switch] $Request,
        [Parameter(ParameterSetName = "Existing")]
        [string] $SourceJunction = "C:\DBA\PowerShell\Modules",

        # Position is needed otherwise Jojoba swallows everything, this only happens when default parameter sets are in use
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
        [string] $ComputerName,

        [Parameter(ValueFromRemainingArguments)]
        [object[]] $Jojoba
    )

    begin {
        if ($Request) {
            Test-JojobaConfiguration $PSCmdlet
            Request-Module
        }
    }

    process {
        if ($SourceJunction -like "*.zip") {
            Add-Type -AssemblyName "System.IO.Compression.FileSystem" | Out-Null
            $tempSourceJunction = [System.IO.Path]::GetTempFileName()
            Remove-Item $tempSourceJunction
            New-Item $tempSourceJunction -ItemType Directory | Out-Null
            [System.IO.Compression.ZipFile]::ExtractToDirectory($SourceJunction, $tempSourceJunction)
            $SourceJunction = $tempSourceJunction
        }

        if ($ComputerName) {
            #check if computer is tagged with a category that should have  deployed to it
            $CategoryName = (Get-Computer -ComputerName $ComputerName).CategoryName -match @("ConstrainedEndpoint|DBA|SqlSentry|SqlSentryMonitoringService|Restore|EDW")
            if($CategoryName) {
                Start-Jojoba {
                    $junction = "C:\DBA\PowerShell\Modules"
                    $moduleVersion = (Get-Module "$($SourceJunction)\").Version.ToString()
                    $modulePath = "$($junction)_$ModuleVersion"
                    if ($ComputerName -ne (Get-ComputerName)) {
                        $remoteModulePath = "\\$ComputerName\$($modulePath.Replace(":", "$"))"
                    } else {
                        $remoteModulePath = $modulePath
                    }

                    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                        [CmdletBinding()]
                        param (
                            [Parameter(Mandatory)]
                            [ValidateNotNullOrEmpty()]
                            [string] $Junction,
                            [Parameter(Mandatory)]
                            [ValidateNotNullOrEmpty()]
                            [string] $ModulePath
                        )

                        if (Test-Path $Junction) {
                            # Avoid seeding from a junction into itself (it will hang up with errors)
                            $junctionTarget = &fsutil reparsepoint query $Junction | Where-Object { $_ -imatch "Print Name:" } | ForEach-Object { $_ -replace "Print Name\:\s*", "" }
                            if (-not $junctionTarget) {
                                # Windows Server 2019 changed it to this
                                $junctionTarget = &fsutil reparsepoint query $Junction | Where-Object { $_ -imatch "Substitute Name:" } | ForEach-Object { $_ -replace "Substitute Name\:\s+\\\?+\\", "" }
                            }

                            if ($ModulePath -ne $junctionTarget) {
                                Write-Host "Seeding $Junction into $ModulePath"
                                &robocopy $Junction $ModulePath /MIR /MT /R:3 /W:5 | Out-Null
                            }
                        }
                    } -ArgumentList $junction, $modulePath

                    # Copy from the SourceJunction to the destination. But if we are trying to copy from a junction to its own target
                    # folder that will hang, so don't do that.
                    $robocopy = $true
                    if ($modulePath -eq $remoteModulePath) {
                        $sourceJunctionProperties = Get-Item $SourceJunction
                        if ($sourceJunctionProperties.psobject.Properties["Target"] -and $sourceJunctionProperties.Target -eq $remoteModulePath) {
                            $robocopy = $false
                        }
                    }
                    if ($robocopy) {
                        Write-Host "Robocopy from $SourceJunction to $remoteModulePath"
                        &robocopy $SourceJunction $remoteModulePath /MIR /MT /R:3 /W:5
                    }

                    try {
                        (Get-Item $remoteModulePath).LastWriteTimeUtc = (Get-Date).ToUniversalTime()
                    } catch {
                        Write-Warning "Couldn't set $remoteModulePath LastWriteTime but this shouldn't affect anything"
                    }

                    Write-Host "Executing Cleanup"
                    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                        [CmdletBinding()]
                        param (
                            [Parameter(Mandatory)]
                            [ValidateNotNullOrEmpty()]
                            [string] $Junction,
                            [Parameter(Mandatory)]
                            [ValidateNotNullOrEmpty()]
                            [string] $ModulePath
                        )

                        # This temporary path addition is needed for servers that don't already have the junction in the path
                        $env:PSModulePath = "$ModulePath\;$($env:PSModulePath)"
                        Import-Module ""
                        Set-Junction -Target $ModulePath
                        Add-EnvironmentJunction
                        # Remove our temporary path addition
                        $env:PSModulePath = $env:PSModulePath.Replace("$ModulePath\;", "")

                        try {
                            if (Get-Module "" -ListAvailable) {
                                Remove-Module "" -Force
                            }
                            Import-Module ""
                        } catch {
                            Write-Warning "Couldn't remove and reload the new  module but this shouldn't affect anything"
                        }

                        Write-Host "Removing Module History"
                        Remove-ModuleHistory
                        Write-Host "Set Permissions"
                        [PSCustomObject] @{
                            AclType           = "NTFS"
                            ComputerName      = $null # Local
                            Path              = $Junction
                            Action            = "Grant"
                            AccountName       = "$(Get-Domain)\DBA Admin"
                            AccessControlType = [System.Security.AccessControl.AccessControlType] "Allow"
                            AccessRight       = [System.Security.AccessControl.FileSystemRights] "FullControl"
                            InheritanceFlags  = [System.Security.AccessControl.InheritanceFlags] "ContainerInherit, ObjectInherit"
                            PropagationFlags  = [System.Security.AccessControl.PropagationFlags] "None"
                        } | Update-BackupPermission -Quiet
                    } -ArgumentList $Junction, $ModulePath -FunctionList "Import-Module"

                    Write-Host "Checking for pre-requisities"
                    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                        [CmdletBinding()] param ()
                        Import-Module "ServerManager"

                        $features = Get-WindowsFeature | Where-Object { $_.InstallState -eq "Installed" }
                        foreach ($feature in @("RSAT-Clustering", "RSAT-AD-Tools", "RSAT-AD-PowerShell", "RSAT-ADDS", "RSAT-DNS-Server", "GPMC")) {
                            # This image has problems installing this feature but it's not required for PS only helpful for GUI use
                            if ($feature -ne "RSAT-ADDS" -or (Get-CimInstance -ClassName Win32_OperatingSystem -OperationTimeoutSec 30).Caption -ne "Microsoft Windows Storage Server 2016 Standard") {
                                if (-not ($features | Where-Object { $_.Name -eq $feature })) {
                                    "Adding Windows Feature [$feature]"
                                    Add-WindowsFeature $feature
                                }
                            }
                        }
                    } -FunctionList "Import-Module"

                    Write-Host "Copy Complete"
                }
            } else {
                Write-Warning "Failed to Publish to $ComputerName because it should not have  on it"
            }
        } else {
            $failures =
            Get-Computer | Where-Object {
                $_.CategoryName -eq "ConstrainedEndpoint" -or
                $_.CategoryName -eq "DBA" -or
                $_.CategoryName -eq "SqlSentry" -or
                $_.CategoryName -eq "SqlSentryMonitoringService" -or
                $_.CategoryName -eq "Restore" -or
                $_.CategoryName -eq "EDW"
            } | Select-Object -ExpandProperty ComputerName | Sort-Object -Unique | Publish-Module -SourceJunction $SourceJunction -JojobaPassThru | Where-Object { $_.Result -eq "Fail" }

            if ($failures) {
                Write-Error "Failed to Publish to $($failures.Name)"
            }

        }
    }

    end {
        if ($ComputerName) {
            Publish-Jojoba -Property @("UserName", "Suite", "Timestamp", "Time", "ClassName", "Name", "Result", "Repair", "Message", "Data") -JojobaCallback Write-Audit
        }
    }
}