az login

$subscriptionID="xxxxx"
az account set -s $subscriptionID


#####################################################################
#to failover the primary SQL MI to another replica in the same region#
#if there is only one replica in the region, the failover will occur but nothing will change#
$SQLMI="xxxx"
$SQLMIResourceGroup="xxx"
az sql mi failover -g $SQLMIResourceGroup -n $SQLMI


################################Geo-Failover#############################
#perform a cross region failover (no CLI, PS only for this part)
#failover group must contain a secondary replica in another Azure region#
#Failover group read-write listener
#
Install-Module -Name Az.Sql  
Import-Module -Name Az.Accounts -RequiredVersion 2.19.0

$AzureContext = (Connect-AzAccount -Subscription "microservices").context
$AzureContext
$SQLMIResourceGroup="xxx"
$location="West Europe"
$subscriptionID='xxxx'


# Verify the current primary role
Get-AzSqlDatabaseInstanceFailoverGroup -ResourceGroupName $SQLMIResourceGroup `
    -Location $location 

######Failover the primary managed instance to the secondary role#######
#in the general tier, if we configure the application to use the secondary listener, does the listener remain the same?
# Failover the primary managed instance to the secondary role
$failoverGroupName="xxx"
$drLocation="North Europe" #the location we want the new primary to be on
Write-host "Failing primary over to the secondary location"
Get-AzSqlDatabaseInstanceFailoverGroup -ResourceGroupName $resourceGroupName `
    -Location $drLocation -Name $failoverGroupName | Switch-AzSqlDatabaseInstanceFailoverGroup
Write-host "Successfully failed failover group to secondary location"

# Verify the current primary role
Get-AzSqlDatabaseInstanceFailoverGroup -ResourceGroupName $resourceGroupName `
    -Location $drLocation -Name $failoverGroupName