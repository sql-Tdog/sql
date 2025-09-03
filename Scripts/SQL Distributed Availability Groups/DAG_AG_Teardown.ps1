<####
Script to tear down the DAG and the secondary AG of the DAG 
####>

$List1 = "" #listener of primary AG of the DAG
$List2 = "" #listener secondary AG of the DAG
$DAGname = ""  #DAG to tear down 
$AG = ""  #AG to tear down 

 
$Query="DROP AVAILABILITY GROUP [$DAGname]"
Invoke-Sqlcmd -ServerInstance $List2 -Query $Query 
Invoke-Sqlcmd -ServerInstance $List1 -Query $Query 

$Query="DROP AVAILABILITY GROUP [$AG]"
Invoke-Sqlcmd -ServerInstance $List2 -Query $Query 

#the above query will error out because SQL Server won't be able to confirm that the AG was dropped since
#it will be trying to connect to the listener that will be dropped
