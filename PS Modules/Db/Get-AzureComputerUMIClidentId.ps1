<#
.SYNOPSIS
This script retrieves the User Assigned Managed Identity Client Id that can be used to access various resources in Azure.
We assign a User Managed Identity (UMI) to all of our SQL Azure VMs including the SQL Tools VMs.  This UMI gives us access
to Azure storage accounts among other things.

.DESCRIPTION
The Get-AzureComputerUMIClientId function is used to get the User Assigned Managed Identity Client Id for accessing Azure resources.

.PARAMETER ServerInstance
Specifies the name of the Azure VM to retrieve UMI Client Id for.
.PARAMETER AzureRegion
Specifies the name of the Azure region where the server resides.

.EXAMPLE
Get-AzureComputerUMIClientId -ServerInstance Server01

This example retrieves the UMI Client Id for a Server named Server01.

.NOTES

#>

function Get-AzureComputerUMIClientId {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string] $ServerInstance = "*",

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $DomainName = (Get-Domain),

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $AzureRegion = "*",

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $ComputerName = "*",

        [switch] $Force
    )

    begin {
    }

    process {
        if($AzureRegion -contains "Not Azure") {
            Write-Warning "Computer is not in Azure, cannot retrieve its User Assigned Managed Identity"
        } elseif ($AzureRegion -eq $null) {
            $data = Get-Computer | Where-Object {$_.ServerInstance -and $_.ComputerName -eq $ServerInstance}
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
            $AzureRegion = $data.AzureRegion
        } 
        if($DomainName = "TKAD") {
            $UMIClientId = '9bf00545-75f4-4f0e-9b8e-7c771fb28edc'
            $ResourceGroup = "MsfSqlfabricStorageDevUs"
        } elseif ($DomainName = "CORP") {
            #in CORP, we have 3 different UMIs, based on environment
            if ($data.CategoryName -match "^Stage$") {
                $UMIClientId = "94bf2c40-7767-4bea-8e77-1d8d622b1401"
                $ResourceGroup = "MsfSqlfabricStorageStageUs"
            } elseif ($data.CategoryName -match "^Demo$") {
                $UMIClientId = "9da21448-ec56-4e1c-a9e1-fb4ebafbcc93"
                $ResourceGroup = "MsfSqlfabricStorageDemoUs"
            } elseif ($data.CategoryName -match "^Production$") {
                $UMIClientId = "465cca92-edda-43c4-96c0-e6e90f4cf05f"
                $ResourceGroup = "MsfSqlUssProd" 
            }
        }
        [PSCustomObject] @{ UMIClientId = $UMIClientId; ResourceGroup = $ResourceGroup }

    }
    end {
    }
}