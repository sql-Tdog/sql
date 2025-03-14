################################Geo-Failover#############################
#https://learn.microsoft.com/en-us/cli/azure/sql/mi?view=azure-cli-latest#az-sql-mi-failover

######CLI################################################################
#to use CLI, login first
az login
$subscriptionID="xxxxx"
az account set -s $subscriptionID
$SQLMI="xxxx"
$SQLMIResourceGroup="xxx"
#perform the failover:
az sql mi failover -g $SQLMIResourceGroup -n $SQLMI

