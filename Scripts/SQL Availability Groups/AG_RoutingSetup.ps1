<####
This script is to set up read-only routing for AG replicas

Remember that Read-only routing doesn't completely work for DAGs.  It can be configured for all 
AGs but will work for the primary AG only.  It will not work for the secondary AGs.
https://learn.microsoft.com/en-us/sql/database-engine/availability-groups/windows/distributed-availability-groups?view=sql-server-ver16#:~:text=Read%2Donly%20routing%20doesn%27t,the%20distributed%20availability%20group.

####>
$AG=""
$List=""

$inst1=""
$inst2=""
$inst3=""
$inst4=""

$Query="
ALTER AVAILABILITY GROUP $AG MODIFY REPLICA ON '$inst1' WITH (SECONDARY_ROLE (ALLOW_CONNECTIONS = ALL))
ALTER AVAILABILITY GROUP $AG MODIFY REPLICA ON '$inst1' WITH (SECONDARY_ROLE (READ_ONLY_ROUTING_URL = N'TCP://$inst1.$FQDN`:1433'))
GO
ALTER AVAILABILITY GROUP $AG MODIFY REPLICA ON '$inst2' WITH (SECONDARY_ROLE (ALLOW_CONNECTIONS = ALL))
ALTER AVAILABILITY GROUP $AG MODIFY REPLICA ON '$inst2' WITH (SECONDARY_ROLE (READ_ONLY_ROUTING_URL = N'TCP://$inst2.$FQDN`:1433'))
GO
ALTER AVAILABILITY GROUP $AG MODIFY REPLICA ON '$inst3' WITH (SECONDARY_ROLE (ALLOW_CONNECTIONS = ALL))
ALTER AVAILABILITY GROUP $AG MODIFY REPLICA ON '$inst3' WITH (SECONDARY_ROLE (READ_ONLY_ROUTING_URL = N'TCP://$inst3.$FQDN`:1433'))
GO
ALTER AVAILABILITY GROUP $AG MODIFY REPLICA ON '$inst4' WITH (SECONDARY_ROLE (ALLOW_CONNECTIONS = ALL))
ALTER AVAILABILITY GROUP $AG MODIFY REPLICA ON '$inst4' WITH (SECONDARY_ROLE (READ_ONLY_ROUTING_URL = N'TCP://$inst4.$FQDN`:1433'))
GO
ALTER AVAILABILITY GROUP $AG MODIFY REPLICA ON '$inst1' WITH (PRIMARY_ROLE (READ_ONLY_ROUTING_LIST=('$inst2','$inst3','$inst4','$inst1')));  
ALTER AVAILABILITY GROUP $AG MODIFY REPLICA ON '$inst2' WITH (PRIMARY_ROLE (READ_ONLY_ROUTING_LIST=('$inst1','$inst3','$inst4','$inst2')));  
ALTER AVAILABILITY GROUP $AG MODIFY REPLICA ON '$inst3' WITH (PRIMARY_ROLE (READ_ONLY_ROUTING_LIST=('$inst1','$inst2','$inst4','$inst3')));  
ALTER AVAILABILITY GROUP $AG MODIFY REPLICA ON '$inst4' WITH (PRIMARY_ROLE (READ_ONLY_ROUTING_LIST=('$inst1','$inst2','$inst3','$inst4')));  
" 
  
$Query
Invoke-Sqlcmd -ServerInstance $List -Query $Query 


