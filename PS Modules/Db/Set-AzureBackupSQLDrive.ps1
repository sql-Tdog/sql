<#
.SYNOPSIS
This script mounts a given Azure Storage Backup Container in SQL Server.
Required input is ServerInstance.  The function calls Get-AzureBackupAccountKey if the
StorageAccountKey or StorageAccountName parameters are not supplied.

.DESCRIPTION
The Set-AzureBackupSQLDrive function is used to mount a given Azure Storage Backup Container in SQL Server.

.PARAMETER ServerInstance
Specifies the name of the SQL Server VM to retrieve backup container key for.

.PARAMETER StorageAccountKey
Is the key needed to access the storage account.

.PARAMETER StorageAccountName
Is the storage account that contains the fileshare that needs to be mounted in SQL server.

.EXAMPLE
Set-AzureBackupAccountKey -ServerInstance SQLServer01 -StorageAccountKey xxxx -StorageAccountName BackupAccount

This example uses the SStorageAccountKey xxxx to mount drive Z on SQL Server named SQLServer01 that points to the Azure backup account BackupAccount.

.NOTES

#>

function Set-AzureBackupSQLDrive {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $ServerInstance = "*",

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $DomainName = (Get-Domain),

        [Parameter(ValueFromPipelineByPropertyName)]
        $StorageAccountKey,

        [Parameter(ValueFromPipelineByPropertyName)]
        $StorageAccountName
   )

    begin {
    }

    process {
        if(!$StorageAccountKey -or !$StorageAccountName) {
            #retrieve the key from .dbo.BackupContainerKey table, not from Azure
            $query = "EXEC dbo.GetBackupAccountKey @ServerInstance = '$ServerInstance'
            "
            $StorageAccountInfo = Get-InternalDatabase | New-DbConnection | New-DbCommand $query | Get-DbData
            $StorageAccountName = [string]($StorageAccountInfo.StorageAccountName)
            $StorageAccountKey = [string]($StorageAccountInfo.StorageAccountKey)
        }
        $FileShareURL = $StorageAccountName+".file.core.windows.net"
        $Fileshare = "backups"
        #enable xp_cmdshell and use the key to mount the drive in SQL:
        $query="
        EXEC sp_configure 'show advanced options', 1;
        GO
        RECONFIGURE;
        GO
        EXEC sp_configure 'xp_cmdshell',1;
        GO
        reconfigure;
        GO
        EXEC xp_cmdshell 'net use Z: \\$fileShareURL\$fileShare /u:localhost\$storageAccountName $StorageAccountKey'
        GO
        EXEC sp_configure 'xp_cmdshell',0;
        GO
        reconfigure;
        "
        Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $query

    }

    end {
    }
}