<####
Script to tear down the DAG 
####>

$List1 = "" #listener of primary AG of the DAG
$List2 = "" #listener secondary AG of the DAG
$DAGname = ""  #DAG to tear down 

 
$Query="DROP AVAILABILITY GROUP [$DAGname]"
Invoke-Sqlcmd -ServerInstance $List1 -Query $Query 
Invoke-Sqlcmd -ServerInstance $List2 -Query $Query 

