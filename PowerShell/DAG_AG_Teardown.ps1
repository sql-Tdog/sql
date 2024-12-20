<####
Script to tear down the AGs and the DAG
####>

$AG1=""
$AG2=""
$AG3=""

$AG1acct="$"
$AG2acct="$"

$inst1=""
$inst2=""
$inst3=""
$inst4=""
$inst5=""
$inst6=""

$List1=""
$List2=""
$List3=""

$dbshare="\\xxx\TempShare"
$dbshare2="\\xxx\TempShare"
$DAGname=""
$DAGname2=""

$AD=$Env:userdomain
$FQDN=$env:USERDNSDOMAIN


#tear down DAG2 and AG3:
$Query="DROP AVAILABILITY GROUP [$DAGname2]"
Invoke-Sqlcmd -ServerInstance $List2 -Query $Query -TrustServerCertificate
Invoke-Sqlcmd -ServerInstance $List3 -Query $Query -TrustServerCertificate

$Query="DROP AVAILABILITY GROUP [$AG3]"
Invoke-Sqlcmd -ServerInstance $List3 -Query $Query -TrustServerCertificate

#tear down DAG1 and AG2
$Query="DROP AVAILABILITY GROUP [$DAGname]"
Invoke-Sqlcmd -ServerInstance $List1 -Query $Query -TrustServerCertificate
Invoke-Sqlcmd -ServerInstance $List2 -Query $Query -TrustServerCertificate


$Query="ALTER AVAILABILITY GROUP [$AG2] REMOVE DATABASE DocuSign
ALTER AVAILABILITY GROUP [$AG2] REMOVE DATABASE test_db"
Invoke-Sqlcmd -ServerInstance $List2 -Query $Query -TrustServerCertificate

$Query="DROP DATABASE DocuSign
DROP DATABASE test_db"
Invoke-Sqlcmd -ServerInstance $inst3 -Query $Query -TrustServerCertificate
Invoke-Sqlcmd -ServerInstance $inst4 -Query $Query -TrustServerCertificate


$Query="DROP AVAILABILITY GROUP [$AG2]"
Invoke-Sqlcmd -ServerInstance $inst3 -Query $Query -TrustServerCertificate
