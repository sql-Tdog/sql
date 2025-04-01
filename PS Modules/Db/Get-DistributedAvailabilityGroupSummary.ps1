<#

.SYNOPSIS
Summarises Distributed Availability Group information held in SQL Sentry.

.DESCRIPTION

# .PARAMETER

.NOTES

#>

function Get-DistributedAvailabilityGroupSummary {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string] $DistributedAvailabilityGroupName = "*",
        [string] $AvailabilityGroupName = "*"
    )

    begin {
    }

    process {
        $query = @"
SELECT Name AS DAGName, p.PreferredPrimaryReplica as PrimaryAG, UPPER(ar.ReplicaServerName) as SecondaryAG,
    p.RedoLatencyWarningSec, RedoLatencyErrorSec, SendQueueWarning, PreferredAutoFailoverReplicas, ar.ReplicaServerName AS AvailabilityGroupName
FROM SQLSentry.AlwaysOn.AvailabilityGroup ag
JOIN    SQLSentry.AlwaysOn.AvailabilityReplica ar ON ag.GroupID = ar.GroupID
CROSS APPLY (
        SELECT  agr.RedoLatencyWarningSec,
                agr.RedoLatencyErrorSec,
                agr.SendQueueWarning,
                agc.PrimaryReplica AS PreferredPrimaryReplica,
                agc.SyncReplicas AS PreferredSyncReplicas,
                agc.AutoFailoverReplica AS PreferredAutoFailoverReplicas,
                agc.AsyncReplicas AS PreferredAsyncReplicas,
                UPPER(agc.PreferredBackupServer) AS PreferredBackupReplica,
                agc.ReadRoutingOrder AS PreferredReadOnlyRoutingList
        FROM    HealthCheck.dbo.dimAvailabilityGroupRef agr
        JOIN    HealthCheck.dbo.AGConfig agc
        ON      agr.AGID = agc.AGID
        WHERE   agr.AGName = ag.Name
        ) p
        WHERE IsDistributed=1 and p.PreferredPrimaryReplica<>ar.ReplicaServerName
"@

        $data = Get-InternalDatabase | New-DbConnection | New-DbCommand $query | Get-DbData | Where-Object {($DistributedAvailabilityGroupName -and $_.DAGName -like $DistributedAvailabilityGroupName) -and $_.AvailabilityGroupName -like $AvailabilityGroupName }
        $data = $data | Group-Object DAGName | ForEach-Object {
            [PSCustomObject] @{
                DistributedAvailabilityGroupName       = $_.Group[0].DAGName

                PrimaryAvailabilityGroup               = $_.Group[0].PrimaryAG
                PrimaryAvailabilityGroupReplicas       = (Get-AvailabilityGroupSummary -AvailabilityGroupName $_.Group[0].PrimaryAG).AvailabilityReplicas

                SecondaryAvailabilityGroup             = $_.Group[0].SecondaryAG
                SecondaryAvailabilityGroupReplicas     = if(Get-AvailabilityGroupSummary -AvailabilityGroupName $_.Group[0].SecondaryAG)
                            { (Get-AvailabilityGroupSummary -AvailabilityGroupName $_.Group[0].SecondaryAG).AvailabilityReplicas} else {''}

                AutoFailoverPreference                 = $_.Group[0].PreferredAutoFailoverReplicas
                RedoLatencyWarningSec                  = $_.Group[0].RedoLatencyWarningSec
                RedoLatencyErrorSec                    = $_.Group[0].RedoLatencyErrorSec
                SendQueueWarning                       = $_.Group[0].SendQueueWarning
            }
        }

        $data | Sort-Object DAGName
    }

    end {
    }
}
