<####
This script is to set up read-only routing for AG replicas

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

