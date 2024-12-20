
$db1=""
$db2=""
$db3=""


$Query="ALTER DATABASE $db1 SET HADR AVAILABILITY GROUP = $AG2;"
Invoke-Sqlcmd -ServerInstance $inst3 -Query $Query 
Invoke-Sqlcmd -ServerInstance $inst4 -Query $Query 
$Query="ALTER DATABASE $db1 SET HADR AVAILABILITY GROUP = $AG3;"
Invoke-Sqlcmd -ServerInstance $inst5 -Query $Query 
Invoke-Sqlcmd -ServerInstance $inst6 -Query $Query 


$Query="ALTER DATABASE $db2 SET HADR AVAILABILITY GROUP = $AG2;"
Invoke-Sqlcmd -ServerInstance $inst3 -Query $Query 
Invoke-Sqlcmd -ServerInstance $inst4 -Query $Query 
$Query="ALTER DATABASE $db2 SET HADR AVAILABILITY GROUP = $AG3;"
Invoke-Sqlcmd -ServerInstance $inst5 -Query $Query 
Invoke-Sqlcmd -ServerInstance $inst6 -Query $Query 


$Query="ALTER DATABASE $db3 SET HADR AVAILABILITY GROUP = $AG2;"
Invoke-Sqlcmd -ServerInstance $inst3 -Query $Query 
Invoke-Sqlcmd -ServerInstance $inst4 -Query $Query 
$Query="ALTER DATABASE $db3 SET HADR AVAILABILITY GROUP = $AG3;"
Invoke-Sqlcmd -ServerInstance $inst5 -Query $Query 
Invoke-Sqlcmd -ServerInstance $inst6 -Query $Query 
