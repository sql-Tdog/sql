$AG1=""
$AG2=""

$AG1acct="$"
$AG2acct="$"

$inst1=""
$inst2=""
$inst3=""
$inst4=""

$List1=""
$List2=""

$AD=$Env:userdomain
$FQDN=$env:USERDNSDOMAIN

#service account from AG1 to AG 2:
$Query="CREATE LOGIN [$AD\$AG1acct] FROM WINDOWS WITH DEFAULT_DATABASE=[master]
GO
GRANT ALTER ANY AVAILABILITY GROUP TO [$AD\$AG1acct];
GRANT CONNECT SQL TO [$AD\$AG1acct];
GRANT VIEW SERVER STATE TO [$AD\$AG1acct];
GO
GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [$AD\$AG1acct]"
Invoke-Sqlcmd -ServerInstance $inst3 -Query $Query -TrustServerCertificate
Invoke-Sqlcmd -ServerInstance $inst4 -Query $Query -TrustServerCertificate


#service account from AG 2 to AG 1:
$Query="CREATE LOGIN [$AD\$AG2acct] FROM WINDOWS WITH DEFAULT_DATABASE=[master]
GO
GRANT ALTER ANY AVAILABILITY GROUP TO [$AD\$AG2acct];
GRANT CONNECT SQL TO [$AD\$AG2acct];
GRANT VIEW SERVER STATE TO [$AD\$AG2acct];
GO
GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [$AD\$AG2acct]"
Invoke-Sqlcmd -ServerInstance $inst1 -Query $Query -TrustServerCertificate
Invoke-Sqlcmd -ServerInstance $inst2 -Query $Query -TrustServerCertificate

#first, create the DAG on global primary:
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

Invoke-Sqlcmd -ServerInstance $List1-Query $Query 

$Query="ALTER AVAILABILITY GROUP [$DAGName]  
   JOIN  
   AVAILABILITY GROUP ON    
      '$AG1' WITH    
      (  
         LISTENER_URL = 'tcp://$List1.$FQDN`:5022',    
         AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,  
         FAILOVER_MODE = MANUAL,  
         SEEDING_MODE = AUTOMATIC
      ),  
      '$AG2' WITH    
      ( 
         LISTENER_URL = 'tcp://$List2.$FQDN`:5022',  
         AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,  
         FAILOVER_MODE = MANUAL,  
         SEEDING_MODE = AUTOMATIC
      );    
GO  
"
Invoke-Sqlcmd -ServerInstance $List2-Query $Query 

#Add db to the global primary AG:
$Query="ALTER AVAILABILITY GROUP $AG1 ADD DATABASE [Sentry];"
Invoke-Sqlcmd -ServerInstance $List1 -Query $Query 
