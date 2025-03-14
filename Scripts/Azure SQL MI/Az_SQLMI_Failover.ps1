################################Geo-Failover#############################
#https://learn.microsoft.com/en-us/cli/azure/sql/mi?view=azure-cli-latest#az-sql-mi-failover

#perform a cross region failover (no CLI, PS only)
#failover group must contain a secondary replica in another Azure region

Install-Module -Name Az.Sql  
Import-Module -Name Az.Accounts 

#use a User Assigned Managed Identity with failover permissions to the SQL MI
#managed identity details:
$managedIdClientId ="9004cc76-df01-4062-a3fc-8d6573c06d63" 
$subscription="Microservices-2" 

#connect to Azure:
$AzureContext = (Connect-AzAccount -Identity -AccountId $managedIdClientId -Subscription $subscription).context
$AzureContext

#SQL MI details:
$SQLMIResourceGroup="xxx"
$location="West Europe"  #current primary region
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