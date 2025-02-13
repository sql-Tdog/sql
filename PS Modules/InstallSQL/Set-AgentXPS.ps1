<#
.SYNOPSIS
This function is to enable Agent XPs 


.NOTES

#>

function Set-AgentXPS {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $ServerInstance 
    )


    begin {
    }

    process {
        #enable xp_cmdshell and use the key to mount the drive in SQL:
        $query="
        sp_configure 'show advanced options', 1;
        GO
        RECONFIGURE;
        GO
        sp_configure 'Agent XPs', 1;
        GO
        RECONFIGURE
        GO
        "
        Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $query

    }

    end {
    }
}
