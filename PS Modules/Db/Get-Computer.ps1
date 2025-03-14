<#
.SYNOPSIS
Retrieves information about computers from the  SQL Sentry inventory.

.DESCRIPTION
The Get-Computer function retrieves and processes information about computers from the  SQL Sentry inventory.
It supports filtering by various parameters such as ComputerName, DomainName, CategoryName, ClusterName, ServerInstance,
AvailabilityGroupName, and AvailabilityGroupListenerName. The function also categorizes computers into maintenance sections
and assigns maintenance windows based on their categories.

.PARAMETER ComputerName
Specifies the name of the computer to retrieve. Supports wildcard characters. Default is "*".

.PARAMETER DomainName
Specifies the domain name of the computer. Default is the result of Get-Domain.

.PARAMETER CategoryName
Specifies the category name of the computer. Supports wildcard characters. Default is "*".

.PARAMETER ClusterName
Specifies the cluster name of the computer. Supports wildcard characters. Default is "*".

.PARAMETER ServerInstance
Specifies the server instance of the computer. Supports wildcard characters. Default is "*".

.PARAMETER AvailabilityGroupName
Specifies the availability group name of the computer. Supports wildcard characters. Default is "*".

.PARAMETER AvailabilityGroupListenerName
Specifies the availability group listener name of the computer. Supports wildcard characters. Default is "*".

.PARAMETER Force
If specified, forces the retrieval of all computers, including those that are not watched.

.EXAMPLE
Get-Computer -ComputerName "Server01"

Retrieves information about the computer named "Server01".

.EXAMPLE
Get-Computer -DomainName "Domain01" -CategoryName "Production"

Retrieves information about all production computers in the "Domain01" domain.

.NOTES

#>

function Get-Computer {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string] $ComputerName = "*",

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $DomainName = (Get-Domain),
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $CategoryName = "*",
        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $ClusterName = "*",
        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $ServerInstance = "*",
        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $AvailabilityGroupName = "*",
        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $AvailabilityGroupListenerName = "*",

        [switch] $Force
    )

    begin {
        if ((Get-Domain) -in @("HQTEST")) {
            # HQTest has named instances
            $data = Get-SqlSentryInventory | Where-Object { ($_.IsWatched -or $Force) -and $_.ComputerName }
        } else {
            $data = Get-SqlSentryInventory | Where-Object { ($_.IsWatched -or $Force) -and $_.ComputerName -and -not $_.InstanceName }
        }

        # Merge records so each base object shows once but has a unique merge of each property
        # The explicit casts are necessary because if not used the hashtable then after conversion to PSCustomObject the individual
        # properties, when null, can inherit a strange property type of PSCustomObject. That type doesn't play well with comparisons
        # or Group-Object.
        $data = $data | Group-Object ComputerName | ForEach-Object {
            [PSCustomObject] @{
                DomainName                            = [string] ($_.Group.DomainName | Sort-Object -Unique)
                CategoryName                          = [string[]] ($_.Group.CategoryName | Optimize-CategoryName)
                AzureRegion                           = [string[]] ($_.Group.AzureRegion)
                ClusterName                           = [string] ($_.Group.ClusterName | Sort-Object -Unique)
                ComputerName                          = [string] $_.Name
                WindowsVersion                        = [string] ($_.Group.WindowsVersion | Sort-Object -Unique)
                ServerInstance                        = [string[]] ($_.Group.ServerInstance | Sort-Object -Unique)
                InstanceName                          = [string[]] ($_.Group.InstanceName | Sort-Object -Unique)
                ServerInstanceVersion                 = [string[]] ($_.Group.ServerInstanceVersion | Sort-Object -Unique)
                AvailabilityGroupName                 = [string[]] ($_.Group.AvailabilityGroupName | Sort-Object -Unique)
                EndpointUrl                           = [string[]] ($_.Group.EndpointUrl | Sort-Object -Unique)
                AvailabilityGroupListenerInstanceName = [string[]] ($_.Group.AvailabilityGroupListenerInstanceName | Sort-Object -Unique)
                DnsName                               = [string[]] ($_.Group.DnsName | Sort-Object -Unique)
                Port                                  = [string[]] ($_.Group.Port | Sort-Object -Unique)
                AvailabilityGroupListenerName         = [string[]] ($_.Group.AvailabilityGroupListenerName | Sort-Object -Unique)
                MaintenanceOrder                      = [string] ($_.Group.MaintenanceOrder | Sort-Object | Select-Object -Last 1)
            }
        }

        #region Define maintenance groups

        <#
            Maintenance Order = For an arbitrary group of servers, the order they should be patched (least critical to most critical)
            Maintenance Section = Groups of servers that should be patched before moving onto the next group
            Maintenance Section Order = Sections, split by category, ordered by orders
            Maintenance Group = Combined section orders with ever-increasing numbers
        #>

        # Separate overall types of computer; specifically we want non-production, demo, and production completed in sequence, and
        # we also need constrained endpoints and network storage patched separately from everything to reduce failure rates of FSBU
        # endpoints and backups/witnesses respectively.
        # It's possible for Test servers to have Constrained Endpoints and Network Storage, and we want those done separately to any
        # Test server so as to avoid failures, which is why they're checked first.
        foreach ($computer in $data) {
            $maintenanceSection = if ($computer.CategoryName -match "^ConstrainedEndpoint$") {
                # Each constrained endpoint is put in its own group, this way they are all patched
                # separate to each other. This is because DCAuto can't patch any other server when
                # the first constrained endpoint is being patched. We can't really determine which
                # endpoint that will be, so, we do them all separately.
                "3. Constrained Endpoint $($computer.ComputerName)"
            } elseif ($computer.CategoryName -match "^NetworkStorage$") {
                "4. Network Storage"
            } elseif ($computer.CategoryName -match "^Build$|^Decommission$|^Test$|^Stage$") {
                "1. Non-Production"
            } elseif ($computer.CategoryName -eq "Demo") {
                "2. Demo"
            } elseif ($computer.CategoryName -eq "Production") {
                if ($computer.CategoryName -eq "OLTP" -and $computer.MaintenanceOrder -in @("4. Primary", "3. Sync")) {
                    # e.g. NA1-4 EU1 FED1
                    $oltpName = $computer.CategoryName | Where-Object { $_ -match "^\w\w\w?\d$" }
                    Write-Verbose "Using [$oltpName] for [$($computer.ComputerName)]"
                    # Note that Optimize-PatchSchedule is sensitive to this maintenance section's exact naming
                    "6. Production OLTP Partner $oltpName"
                } else {
                    "5. Production"
                }
            } else {
                Write-Error "Computer [$($computer.ComputerName)] categories [$($computer.CategoryName)] must include one category in the list [Build, Decommission, Test, Stage, Demo, or Production]"
            }
            $computer | Add-Member -MemberType NoteProperty -Name MaintenanceSection -Value $maintenanceSection
        }

        # Within each section, number the computers within a category (a complete list of category names). This allows the
        # computers within a sequence to be patched together; e.g. if "AccountServer" was one category and "EnvelopeSearch"
        # was a second category, then the servers numbered "1" can be patched together, "2" can be patched together, etc.
        # Old and New categories are ignored (as they should be treated as one and not patched together)
        # NOTE: Assert-ComputerConflict uses part of this logic for conflict management. If the logic is changed here,
        # it MUST be updated there too.
        foreach ($maintenanceSection in ($data | Group-Object MaintenanceSection)) {
            foreach ($categoryNameList in ($maintenanceSection.Group | Group-Object { ($_.CategoryName -join ", " ) })) {
                # The sorting inside here forces None/Async servers to be patched first, then Sync, then Primary.
                $i = 1
                foreach ($entry in ($categoryNameList.Group | Sort-Object MaintenanceOrder, ComputerName)) {
                    $entry | Add-Member -MemberType NoteProperty -Name MaintenanceSectionOrder -Value $i

                    # Pure Restore servers can be patched simultaneously (unless they're part of a cluster, which happens
                    # temporarily in Production and all the time in HQTEST). Same with Build servers.
                    if (-not (($entry.CategoryName -eq "Restore" -or $entry.CategoryName -eq "Build") -and -not $entry.ClusterName)) {
                        $i++
                    }
                }
            }
        }

        # Assign a single ascending group number that's valid across maintenance sections
        $i = 1
        $data = foreach ($group in ($data | Group-Object MaintenanceSection, MaintenanceSectionOrder | Sort-Object { $_.Group[0].MaintenanceSection }, { $_.Group[0].MaintenanceSectionOrder })) {
            $group.Group | Select-Object *, @{ l = "MaintenanceGroup"; e = { $i } }
            $i++
        }

        #endregion End maintenance groups

        #region Add maintenance window information
        foreach ($computer in $data) {
            # Some of the below seems too simple except that
            $maintenanceWindow = if ($computer.DomainName -eq "FEDAD") {
                # US DOC requested all of FEDAD be patched in US hours even though this will have customer impact
                "During business hours"
            } elseif ($computer.CategoryName -match "^Build$|^Decommission$|^Test$|^Stage$") {
                # Make sure any other categories like "Account Server, Test" translate down to the most open window
                "Any time"
            } elseif ($computer.CategoryName -match "^NetworkStorage$|^SqlSentry$|^SqlSentryMonitoringService$|^ReportServer$") {
                # These are done inside business hours to limit problems with backups, false alarms, and reports
                "During business hours"
            } elseif ($computer.CategoryName -match "^Kazmon\d?$") {
                # KazMon is done outside of business hours as we believe it will generate too many false alarms
                "Outside of business hours"
            } elseif ($computer.CategoryName -match "^Demo$|^Production$") {
                # The remaining major environments. EDW runs exports from 4am to 10pm.
                "Late night"
            } else {
                Write-Warning "Cannot determine the default maintenance window for [$($computer.ComputerName)]"
            }

            $computer | Add-Member -MemberType NoteProperty -Name MaintenanceWindow -Value $maintenanceWindow
        }
        #endregion
    }

    process {
        # Filter the results
        $data | Where-Object {
            ($_.DomainName -like $DomainName) -and
            ($_.ComputerName -like $ComputerName) -and
            ($_.CategoryName -like $CategoryName) -and
            ($_.ClusterName -like $ClusterName) -and
            ($_.ServerInstance -like $ServerInstance) -and
            ($_.AvailabilityGroupName -like $AvailabilityGroupName) -and
            ($_.AvailabilityGroupListenerName -like $AvailabilityGroupListenerName)
        } | Sort-Object ComputerName
    }

    end {
    }
}