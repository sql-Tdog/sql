<#
.SYNOPSIS
This function updates the .dbo.BackupContainerKey table with Azure SQL Backup storage
account keys that are to be used for mounting backup drives on our SQL servers.  Every time
SQL services are restarted, the drive will get dismounted and the Set-AzureBackupSQLDrive
will mount the drive.
Required input is ComputerName, which can be the name of the SQL VM or the name of the SQL AG.
To bypass accessing Azure to obtain Storage key info, BackupAccountKey and StorageAccountName must
both be provided

.DESCRIPTION
The Set-AzureBackupAccountKey function calls Get-AzureBackupAccountKey to get the

.PARAMETER ServerInstance
Specifies the name of the SQL Server VM to retrieve backup container key for.

.EXAMPLE
Set-AzureBackupAccountKey -ServerInstance SQLServer01

This example retrieves a key to the Azure backup account for the SQL Server named SQLServer01.

.NOTES

#>

function Set-AzureBackupAccountKey {
    [CmdletBinding()]
    param (

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $DomainName = (Get-Domain),

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $ComputerName = "*",

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $BackupAccountKey = "*",

        [Parameter(ValueFromPipelineByPropertyName)]
        $StorageAccountName

    )

    begin {
    }

    process {
        if (!$BackupAccountKey -or !$StorageAccountName) {
            $BackupAccountKeyInfo = Get-AzureBackupAccountKey $ComputerName
            $BackupAccountKey = $BackupAccountKeyInfo.StorageAccountKey
            $StorageAccountName = $BackupAccountKeyInfo.StorageAccountName
        }

        $query = "EXEC dbo.SetBackupAccountKey @ServerInstance = '$ComputerName',
            @AccountKey = '$BackupAccountKey', @StorageAccountName = '$StorageAccountName'
        "

        Get-InternalDatabase | New-DbConnection | New-DbCommand $query | Get-DbData


    }
    end {
    }
}