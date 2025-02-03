<#
.SYNOPSIS
This script retrieves the Azure Storage Account Name for a given Server with a required input of the User Managed Client Id that
can be used to access the storage account.
Expected inputs are AzureRegion, UMIClientId, and ResourceGroupName


.DESCRIPTION
The Get-AzureComputerUMIClientId function is used to get the User Assigned Managed Identity Client Id for accessing Azure resources.

.PARAMETER ServerInstance
Specifies the name of the Azure VM to retrieve UMI Client Id for.

.EXAMPLE
Get-AzureStorageAccountName -ServerInstance Server01 -AzureRegion WestUS3 -CategoryName Stage

This example retrieves the Azure Storage Account Name a Server named Server01.

.NOTES
This function needs to be modified after we add Storage Accounts to Sentry and tag them.  We will be able to pull data from there instead of having it hard coded here.
#>

function Get-AzureStorageAccountName {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string] $ServerInstance = "*",

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $DomainName = (Get-Domain),

        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $AzureRegion = "*",

        [Parameter(ValueFromPipelineByPropertyName)]
        $CategoryName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $ComputerName = "*",

        [switch] $Force
    )

    begin {
    }

    process {
        if($DomainName = "TKAD") {
            $StorageAccountName = switch ($AzureRegion) {
                "USWest3" {
                    "sqlbackupwestus3wu3lsto"
                }
                "USEast1" {
                    "sqlbackupeastuseuslsto"
                }
            }
        } elseif ($DomainName = "CORP") {
            #in CORP, we have 3 different UMIs, based on environment
            if ($CategoryName -match "^Stage$") {
                $StorageAccountName = switch ($AzureRegion) {
                    "USWest3" {
                        "sqlbackupwu3ssto"
                    }
                    "USEast1" {
                        "sqlbackupdreusssto"
                    }
                }
            } elseif ($CategoryName -match "^Demo$") {
                $StorageAccountName = switch ($AzureRegion) {
                    "USWest3" {
                        "sqlbackupwu3dsto"
                    }
                    "USEast1" {
                        "sqlbackupdreusdsto"
                    }
                }
            } elseif ($CategoryName -match "^Production$") {
                $StorageAccountName = switch ($AzureRegion) {
                    "USEast2" {
                        "sqlbackupwu3dsto"
                    }
                    "USCentral" {
                        "sqlbackupdreusdsto"
                    }
                }
            }
        }
        $StorageAccountName

    }
    end {
    }
}
