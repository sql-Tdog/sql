<####
Set up:  AG1 & AG2 in the first DAG and AG2 & AG3 in the second DAG
Goal:  
This script is to switch AGs for the DAGs by tearing down both DAGs and recreating them
with different underlying AGs

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
$inst1a=""
$inst1b=""
$inst1c=""
$inst1d=""
$inst1e=""

#AG2 instances:
$inst3=""
$inst4=""

#AG3 instances:
$inst5=""
$inst6=""

$FQDN=$env:userdnsdomain

$db1=""
$db2=""
$db3=""




$Query = "EXEC msdb.dbo.sp_update_job  
    @job_name = N`'Instance Backup - LOG`',  
    @enabled = 0 ;  
GO"

Invoke-Sqlcmd -ServerInstance $inst1a -Query $Query 
Invoke-Sqlcmd -ServerInstance $inst1b -Query $Query 
Invoke-Sqlcmd -ServerInstance $inst1c -Query $Query 
Invoke-Sqlcmd -ServerInstance $inst1d -Query $Query 
Invoke-Sqlcmd -ServerInstance $inst1e -Query $Query 
Invoke-Sqlcmd -ServerInstance $inst3 -Query $Query 
Invoke-Sqlcmd -ServerInstance $inst4 -Query $Query 
Invoke-Sqlcmd -ServerInstance $inst5 -Query $Query 
Invoke-Sqlcmd -ServerInstance $inst6 -Query $Query 


#Setup:  DAG1 (List1 to List2), DAG2 (List2 to List3)
#Goal:  Swap AGs underneath the DAGs so that they are reversed

#turn off HADR to break syncing
$Query=
  "ALTER DATABASE $db1 SET HADR OFF;
  GO
  ALTER DATABASE $db2 SET HADR OFF;
  GO
  ALTER DATABASE $db3 SET HADR OFF;
  "
Invoke-Sqlcmd -ServerInstance $inst5 -Query $Query 
Invoke-Sqlcmd -ServerInstance $inst6 -Query $Query 
Invoke-Sqlcmd -ServerInstance $inst3 -Query $Query 
Invoke-Sqlcmd -ServerInstance $inst4 -Query $Query 

#tear down DAG2: 
$Query = "DROP AVAILABILITY GROUP [$DAGname2]"
Invoke-Sqlcmd -ServerInstance $List2 -Query $Query 
Invoke-Sqlcmd -ServerInstance $List3 -Query $Query 


#tear down DAG1:  
$Query="DROP AVAILABILITY GROUP [$DAGname1]"
Invoke-Sqlcmd -ServerInstance $List1 -Query $Query 
Invoke-Sqlcmd -ServerInstance $List2 -Query $Query 


#create the new DAG
$Query="CREATE AVAILABILITY GROUP [$DAGName1]  
   WITH (DISTRIBUTED)  
   AVAILABILITY GROUP ON  
      '$AG1' WITH    
      (  
         LISTENER_URL = 'tcp://$List1.$FQDN`:5022',    
         AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,  
         FAILOVER_MODE = MANUAL,  
         SEEDING_MODE = MANUAL 
      ),  
      '$AG3' WITH    
      ( 
         LISTENER_URL = 'tcp://$List3.$FQDN`:5022',  
         AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,  
         FAILOVER_MODE = MANUAL,  
         SEEDING_MODE = MANUAL 
      );    
GO  
"

Invoke-Sqlcmd -ServerInstance $List1 -Query $Query 


$Query="ALTER AVAILABILITY GROUP [$DAGName1]  
   JOIN  
   AVAILABILITY GROUP ON    
      '$AG1' WITH    
      (  
         LISTENER_URL = 'tcp://$List1.$FQDN`:5022',    
         AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,  
         FAILOVER_MODE = MANUAL,  
         SEEDING_MODE = MANUAL 
      ),  
      '$AG3' WITH    
      ( 
         LISTENER_URL = 'tcp://$List3.$FQDN`:5022',  
         AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,  
         FAILOVER_MODE = MANUAL,  
         SEEDING_MODE = MANUAL 
      );    
GO  
"
Invoke-Sqlcmd -ServerInstance $List3 -Query $Query 



#set HADR back ON, execute on the primary replica first
$Query=
  "ALTER  DATABASE $db1 SET HADR AVAILABILITY GROUP = $AG3;
  GO
  ALTER DATABASE $db2 SET HADR AVAILABILITY GROUP = $AG3;
  GO
  ALTER DATABASE $db3 SET HADR AVAILABILITY GROUP = $AG3;
  "
Invoke-Sqlcmd -ServerInstance $inst5 -Query $Query 
Invoke-Sqlcmd -ServerInstance $inst6 -Query $Query 


#create the second new DAG
$Query="CREATE AVAILABILITY GROUP [$DAGName2]  
   WITH (DISTRIBUTED)  
   AVAILABILITY GROUP ON  
      '$AG3' WITH    
      (  
         LISTENER_URL = 'tcp://$List3.$FQDN`:5022',    
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

Invoke-Sqlcmd -ServerInstance $List3 -Query $Query 


$Query="ALTER AVAILABILITY GROUP [$DAGName2]  
   JOIN  
   AVAILABILITY GROUP ON    
      '$AG3' WITH    
      (  
         LISTENER_URL = 'tcp://$List3.$FQDN`:5022',    
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
Invoke-Sqlcmd -ServerInstance $List2 -Query $Query 



#set HADR back ON, execute on the primary replica first
$Query="ALTER  DATABASE $db1 SET HADR AVAILABILITY GROUP = $AG2;
GO
ALTER DATABASE $db2 SET HADR AVAILABILITY GROUP = $AG2;
GO
ALTER DATABASE $db3 SET HADR AVAILABILITY GROUP = $AG2;
"
Invoke-Sqlcmd -ServerInstance $inst4 -Query $Query 
Invoke-Sqlcmd -ServerInstance $inst3 -Query $Query 



$Query = "EXEC msdb.dbo.sp_update_job  
    @job_name = N`'Instance Backup - LOG`',  
    @enabled = 1 ;  
GO"

Invoke-Sqlcmd -ServerInstance $inst1a -Query $Query 
Invoke-Sqlcmd -ServerInstance $inst1b -Query $Query 
Invoke-Sqlcmd -ServerInstance $inst1c -Query $Query 
Invoke-Sqlcmd -ServerInstance $inst1d -Query $Query 
Invoke-Sqlcmd -ServerInstance $inst1e -Query $Query 
Invoke-Sqlcmd -ServerInstance $inst3 -Query $Query 
Invoke-Sqlcmd -ServerInstance $inst4 -Query $Query 
Invoke-Sqlcmd -ServerInstance $inst5 -Query $Query 
Invoke-Sqlcmd -ServerInstance $inst6 -Query $Query 