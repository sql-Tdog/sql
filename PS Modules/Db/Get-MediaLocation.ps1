<#

.SYNOPSIS

.DESCRIPTION

.PARAMETER All
Return all the matching NAS without confirming they are in inventory and without checking if they are in maintenance mode.

.PARAMETER Force
Force the return of NAS from other domains.

.NOTES

#>

function Get-MediaLocation {
    [CmdletBinding()]
    param (
        [Alias("ComputerName")]
        $Location,

        [switch] $All,
        [switch] $Force
    )

    begin {
    }

    process {
        # Record the network storage locations for every domain. Each domain should have a "*" record as a fallback, because some
        # functions don't pass in a Location (which is used to identify the closest location to a specific computer)
        $data =
        
        [PSCustomObject] @{
            DomainName   = "CORP"
            Location     = "*"
            ComputerName = "xxx" #Stage, USWest3
        },
        [PSCustomObject] @{
            DomainName   = "CORP"
            Location     = "*"
            ComputerName = "xxx" #Demo, USWest3
        }

        # Add a full path property to each entry in the above data
        $data | ForEach-Object {
            $_ | Add-Member -MemberType NoteProperty -Name Share -Value "DBA_InstallBits"
            if ($_.ComputerName -ne "localhost") {
                $_ | Add-Member -MemberType NoteProperty -Name Path -Value "\\$($_.ComputerName)\DBA_InstallBits"
            } else {
                $_ | Add-Member -MemberType NoteProperty -Name Path -Value "C:\DBA\DBA_InstallBits"
            }
        }

        # Filter it down to just what's applicable to this domain
        if (-not $Force) {
            $data = $data | Where-Object { $_.DomainName -eq (Get-Domain) }
        }

        if ($All) {
            # Dump all the data
            $data
        } else {
            # Find the first match based on Location (remember: * matches all)
            $data = $data | Where-Object { $Location -like $_.Location } | ForEach-Object {
                if ($_.ComputerName -ne "localhost" -and -not (Get-NetworkStorage $_.ComputerName)) {
                    Write-Warning "Skipping media location [$($_.ComputerName)] because it is not in inventory"
                } elseif ($_.ComputerName -ne "localhost" -and (Get-ComputerMaintenanceMode $_.ComputerName)) {
                    Write-Warning "Skipping media location [$($_.ComputerName)] because it is in maintenance mode"
                } else {
                    $_
                }
            } | Select-Object -First 1
            if ($data) {
                $data.Path
            } else {
                Write-Error "Could not find a Media Location"
            }
        }
    }

    end {
    }
}