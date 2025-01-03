<####
Set up:  AG1 & AG2 in the first DAG and AG2 & AG3 in the second DAG
Goal:  
This script is to set up read-only routing for AG replicas

####>

$AG1="" 
$AG3=""  
$DAGName="" 
$DAGname2=""
$List1="" 
$List2=""
$List3="" 
$AG1acct="$" 
$AG1acct1="$"
$AG1acct2="$"

$AG2acct="$" 

#AG1 instances:
$inst1=""
$inst1b=""
$inst1c=""
$inst1d=""
$inst1e=""
$inst1f=""

#AG2 instances:
$inst3=""
$inst4=""

#AG3 instances:
$inst5=""
$inst6=""

$FQDN=$env:userdnsdomain
$AD="$Env:userdomain"

$db1=""
$db2=""
$db3=""


#turn off HADR to break syncing
$Query="ALTER DATABASE $db1 SET HADR OFF;
GO
ALTER DATABASE $db2 SET HADR OFF;
GO
ALTER DATABASE $db3 SET HADR OFF;
"
Invoke-Sqlcmd -ServerInstance $List3 -Query $Query 
Invoke-Sqlcmd -ServerInstance $List2 -Query $Query 


#tear down DAG2, connecting AG2 & AG3:
$Query="DROP AVAILABILITY GROUP [$DAGname2]"
Invoke-Sqlcmd -ServerInstance $List2 -Query $Query 


#tear down DAG1, connecting AG1 & AG2:
$Query="DROP AVAILABILITY GROUP [$DAGname]"
Invoke-Sqlcmd -ServerInstance $List1 -Query $Query 


#databases will be removed from the AG



#create the new DAG with new structure:
$Query="CREATE AVAILABILITY GROUP [$DAGName]  
   WITH (DISTRIBUTED)  
   AVAILABILITY GROUP ON  
      '$AG1' WITH    
      (  
         LISTENER_URL = 'tcp://$List1.$FQDN`:5022',    
         AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,  
         FAILOVER_MODE = MANUAL,  
         SEEDING_MODE = MANUAL 
      ),  
      '$AG2' WITH    
      ( 
         LISTENER_URL = 'tcp://$List2.$FQDN`:5022',  
         AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,  
         FAILOVER_MODE = MANUAL,  
         SEEDING_MODE = MANUAL 
      );    
GO  
"

Invoke-Sqlcmd -ServerInstance $inst1 -Query $Query 


$Query="ALTER AVAILABILITY GROUP [$DAGName]  
   JOIN  
   AVAILABILITY GROUP ON    
      '$AG1' WITH    
      (  
         LISTENER_URL = 'tcp://$List1.$FQDN`:5022',    
         AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,  
         FAILOVER_MODE = MANUAL,  
         SEEDING_MODE = MANUAL 
      ),  
      '$AG2' WITH    
      ( 
         LISTENER_URL = 'tcp://$List2.$FQDN`:5022',  
         AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,  
         FAILOVER_MODE = MANUAL,  
         SEEDING_MODE = MANUAL 
      );    
GO  
"
Invoke-Sqlcmd -ServerInstance $inst3 -Query $Query 




#restore t-logs on AG3, if any backups occurred
#set HADR back ON
$Query="ALTER  DATABASE $db1 SET HADR AVAILABILITY GROUP = $AG3;
GO
ALTER DATABASE $db2 SET HADR AVAILABILITY GROUP = $AG3;
GO
ALTER DATABASE $db3 SET HADR AVAILABILITY GROUP = $AG3;
"
Invoke-Sqlcmd -ServerInstance $inst5 -Query $Query 
Invoke-Sqlcmd -ServerInstance $inst6 -Query $Query 




