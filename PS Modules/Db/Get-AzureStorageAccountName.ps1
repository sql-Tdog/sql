<#
.SYNOPSIS
This script retrieves the Azure Storage Account Name for a given Server with a required input of
the AzureRegion and ComputerName.
This function can be run as stand alone on any machine but will normally be called by
Get-AzureBackupAccountKey


.DESCRIPTION
The Get-AzureStorageAccountName function is used to get the Azure Storage Account Name assigned to the VM for db backups.


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

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $AzureRegion = "*",

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        $CategoryName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $ComputerName = "*",

        [switch] $Force
    )

    begin {
    }

    process {
        if($DomainName -eq "TKAD") {
            $StorageAccountName = switch ($AzureRegion) {
                "USWest3" {
                    "sqlbackupwestus3wu3lsto"
                }
                "USEast1" {
                    "sqlbackupeastuseuslsto"
                }
            }
        } elseif ($DomainName -eq "CORP") {
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
            } elseif (CategoryName -match "^Demo$") {
                $StorageAccountName = switch ($AzureRegion) {
                    "USWest3" {
                        "sqlbackupwu3dsto"
                    }
                    "USEast1" {
                        "sqlbackupdreusdsto"
                    }
                }
            } elseif (CategoryName -match "^Production$") {
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