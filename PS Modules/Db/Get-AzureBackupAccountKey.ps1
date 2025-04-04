<#
.SYNOPSIS
This function retrieves keys to the Azure SQL Backup Containers.  It uses the UMI assigned to the
machine to access the key in Azure.  It can be run on a SQL Tools VM only.
Required input is ComputerName.

.DESCRIPTION
The Get-AzureBackupAccountKey function calls Get-Computer with the ComputerName input to
retrieve the AzureRegion of the given machine.  Then, it calls Get-AzureComputerUMIClientId to
get the client id of the User Managed Id assigned to the machines in this Azure region.  Then, if
StorageAccountName is not provided, it calls Get-AzureStorageAccountName to get the Storage
Account Name to where the SQL backups are to be taken.  Finally, it connects to Azure and returns the
storage account key.

.PARAMETER ServerInstance
Specifies the name of the SQL Server VM to retrieve backup container key for.

.EXAMPLE
Get-AzureBackupAccountKey -ServerInstance SQLServer01

This example retrieves a key to the Azure backup account for the SQL Server named SQLServer01.

.NOTES

#>

function Get-AzureBackupAccountKey {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string] $ServerInstance,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $StorageAccountName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $DomainName = (Get-Domain),

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $ComputerName = "*",

        [switch] $Force
    )

    begin {
    }

    process {
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
        $AzureRegion = ([string]$data.AzureRegion)
        $UMIClientId = Get-AzureComputerUMIClientId -ServerInstance $ServerInstance -AzureRegion $AzureRegion
        $ResourceGroup = ([string]$UMIClientId.ResourceGroup)
        $UMIClientId = ([string]$UMIClientId.UMIClientId)
        if($StorageAccountName -eq $null) {
            $StorageAccountName = Get-AzureStorageAccountName -ServerInstance $ServerInstance -AzureRegion $AzureRegion -CategoryName $data.CategoryName
        }
        $AzureContext = (Connect-AzAccount -Identity -AccountId $UMIClientId).context
        $AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription
        $StAccountKey = Get-AzStorageAccountKey -ResourceGroupName $resourceGroup -Name $storageAccountName
        if($StAccountKey[1].Value -eq $null) {
            Write-Error "Was not able to get the key to the storage account $StorageAccountName"
        } else {
            [PSCustomObject] @{ StorageAccountKey = $StAccountKey[1].Value; StorageAccountName = $StorageAccountName; AzureRegion = $AzureRegion }
        }


    }
    end {
    }
}