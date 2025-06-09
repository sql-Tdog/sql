<#
.SYNOPSIS
This script retrieves the Azure Storage Account Name for a given Server with a required input of
the AzureRegion and ComputerName.



.DESCRIPTION
The Get-AzureStorageAccountName function is used to get the Azure Storage Account Name assigned to the VM for db backups.


.EXAMPLE
Get-AzureStorageAccountName -ServerInstance Server01 -AzureRegion WestUS3 -CategoryName Stage

This example retrieves the Azure Storage Account Name a Server named Server01.

.NOTES
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
        if($DomainName -eq "xxx1") {
            $StorageAccountName = switch ($AzureRegion) {
                "USWest3" {
                    "xxxx"
                }
                "USEast1" {
                    "xxxx"
                }
            }
        } elseif ($DomainName -eq "xxx2") {
            #in CORP, we have 3 different UMIs, based on environment
            if ($CategoryName -match "^Stage$") {
                $StorageAccountName = switch ($AzureRegion) {
                    "USWest3" {
                        "xxxx"
                    }
                    "USEast1" {
                        "xxxx"
                    }
                }
            } elseif (CategoryName -match "^Demo$") {
                $StorageAccountName = switch ($AzureRegion) {
                    "USWest3" {
                        "xxxx"
                    }
                    "USEast1" {
                        "xxx"
                    }
                }
            } elseif (CategoryName -match "^Production$") {
                $StorageAccountName = switch ($AzureRegion) {
                    "USEast2" {
                        "xxxx"
                    }
                    "USCentral" {
                        "xxxxx"
                    }
                }
            }
        }
        $StorageAccountName

    }
    end {
    }
}