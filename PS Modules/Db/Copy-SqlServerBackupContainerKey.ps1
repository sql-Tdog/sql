<#
.SYNOPSIS
Copy data from .dbo.BackupContainerKey to master.dbo.BackupContainerKey on each SQL Server

.DESCRIPTION

.PARAMETER ServerInstance

.PARAMETER Strict
Throw an error if there's a backup container key missing in the central repository. 
It means we need to manually insert Azure backup containers keys into .dbo.BackupContainerKey
table for that SQL Server.

.NOTES

#>

function Copy-SqlServerBackupContainerKey {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string] $ServerInstance,
        [switch] $Strict,

        [Parameter(ValueFromRemainingArguments)]
        [object[]] $Jojoba
    )

    begin {
    }

    process {
        Start-Jojoba {
            if ( (Get-AzureSqlDatabase $ServerInstance) -or (Get-ManagedSqlServer $ServerInstance)) {
                Write-JojobaSkip "Azure Sql Database / Managed Instance detected, skip"
                return
        }
            $existingKey = New-DbConnection -ServerInstance $ServerInstance -DatabaseName "master" | New-DbCommand "IF OBJECT_ID('dbo.BackupContainerKey', 'U') IS NOT NULL SELECT BackupGroupName FROM dbo.BackupContainerKey;" | Get-DbData
            $globalKey = Get-InternalDatabase | New-DbConnection | New-DbCommand "IF OBJECT_ID('dbo.BackupContainerKey', 'U') IS NOT NULL EXECUTE dbo.GetBackupAccountKey @ServerInstance = $ServerInstance" | Get-DbData 
            $StorageAccountName = $globalKey.StorageAccountName
            $globalKey = $globalKey.StorageAccountKey

            # Error out if global table doesn't contain the key
            if (-not $globalKey) {
                if (-not $Strict) {
                    Write-Warning "Required Backup Account Key for [$ServerInstance] not found in Global BackupContainerKey table"
                    continue
                } else {
                    Write-Error "Required Backup Account Key for [$ServerInstance] not found in Global BackupContainerKey table"
                }
            }
            # Copy the key to the SQL instance from the global table if it doesn't exist
            if (-not $existingKey) {
                Write-Host "Adding key for [$ServerInstance]"
                New-DbConnection -ServerInstance $ServerInstance -DatabaseName "master" | New-DbCommand "EXECUTE dbo.SetBackupAccountKey @ServerInstance = '$ServerInstance', @AccountKey = '$globalKey', @StorageAccountName = '$StorageAccountName'" | Get-DbData
            }

            # Mount the drive if not mounted
            $query = "create table #output (subdirectory varchar(100), depth int, [file] int )
                insert #output exec  master.sys.xp_dirtree 'Z:\',1,1
                SELECT TOP 1 subdirectory from #output"
            $mounted = New-DbConnection -ServerInstance $ServerInstance -DatabaseName "master" | New-DbCommand $Query | Get-DbData
            if (-not $mounted) {
                $fileShareURL = $StorageAccountName+".file.core.windows.net"
                Write-Host "Mounting drive on [$ServerInstance]"
                $query="
                    EXEC sp_configure 'show advanced options', 1;
                    GO
                    RECONFIGURE;
                    GO
                    EXEC sp_configure 'xp_cmdshell',1;
                    GO
                    reconfigure;
                    GO
                    EXEC xp_cmdshell 'net use Z: \\$fileShareURL\backups /u:localhost\$storageAccountName $globalKey'
                    GO
                    EXEC sp_configure 'xp_cmdshell',0;
                    GO
                    reconfigure;
                    "
                New-DbConnection -ServerInstance $ServerInstance -DatabaseName "master" | New-DbCommand $Query | Get-DbData
            } 

        }
    }

    end {
        Publish-Jojoba -Property @("UserName", "Suite", "Timestamp", "Time", "ClassName", "Name", "Result", "Repair", "Message", "Data") -JojobaCallback Write-Audit
    }
}
