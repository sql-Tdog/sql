<#
.SYNOPSIS
This script retrieves the User Assigned Managed Identity Client Id that can be used to access
various resources in Azure.  We assign a User Managed Identity (UMI) to our SQL Tools VMs only and
with this UMI, we can get access to Azure storage accounts among other things from those VMs.
This function can be called as stand alone on any machine but will normally be called by
Get-AzureBackupAccountKey.
Required inputs are AzureRegion and ComputerName.

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
        if($DomainName -eq "xx1") {
            $UMIClientId = 'xxxx1'
            $ResourceGroup = "xxx1"
        } elseif ($DomainName -eq "xx2") {
            #in CORP, we have 3 different UMIs, based on environment
            if ($data.CategoryName -match "^xxxa$") {
                $UMIClientId = "xxx2"
                $ResourceGroup = "xxx2"
            } elseif ($data.CategoryName -match "^xxxb$") {
                $UMIClientId = "xxx3"
                $ResourceGroup = "xxx3"
            } elseif ($data.CategoryName -match "^Production$") {
                $UMIClientId = "xxx4"
                $ResourceGroup = "xxx4"
            }
        }
        [PSCustomObject] @{ UMIClientId = $UMIClientId; ResourceGroup = $ResourceGroup }

    }
    end {
    }
}