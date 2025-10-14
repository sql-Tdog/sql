Install-Module -Name Az.Sql  
Install-Module -Name Az.Accounts  

Import-Module -Name Az.Accounts -RequiredVersion 2.19.0


az-login
$subscriptionId=""
$AzureContext = (Connect-AzAccount -Subscription "microservices").context

$AzureContext

# Verify the current primary role
$location="West Europe"
$sourceRG=""

Get-AzSqlDatabaseInstanceFailoverGroup -ResourceGroupName $sourceRG `
    -Location $location 

$failoverGroupName=" "
Get-AzSqlDatabaseInstanceFailoverGroup -ResourceGroupName $sourceRG `
    -Location $location -Name $failoverGroupName

$sourceMI=" "
$sourcedb=" "
$pointInTime=""
$targetRG=" "
$targetMI=" "
$targetdb=" "

#look at source MI:
Get-AzSqlInstanceDatabase -ResourceGroupName $sourceRG -InstanceName $sourceMI -Name $sourcedb
#look at target MI:
Get-AzSqlInstanceDatabase -ResourceGroupName $targetRG -InstanceName $targetMI
Get-AzSubscription -SubscriptionId $subscriptionId
Select-AzSubscription -SubscriptionId $subscriptionId

#source and target must be in the same region, cross-region restore isn't supported
#source SQL MI cannot be a secondary replica, must be the primary instance
#when crossing regions, I get this error:Subscription 'xxx' does not have the server 'xxx'
Restore-AzSqlInstanceDatabase -FromPointInTimeBackup -ResourceGroupName $sourceRG `
    -InstanceName $sourceMI `
    -Name $sourcedb -PointInTime $pointInTime -TargetInstanceDatabaseName $targetdb `
    -TargetResourceGroupName $targetRG -TargetInstanceName $targetMI 


#instead of backup & restore, copy the SQL MI database to a different MI:
#copying from a secondary replica is not supported
#copying across regions is not supported
#can't copy or move a database that's part of a failover group
#source or destination managed instance shouldn't be configured with a failover group
Copy-AzSqlInstanceDatabase -DatabaseName $sourceDB -InstanceName $sourceMI -ResourceGroupName $sourceRG `
    -TargetResourceGroupName $targetRG -TargetInstanceName $targetMI 
