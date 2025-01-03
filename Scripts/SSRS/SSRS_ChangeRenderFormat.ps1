<#This script is to update the render format for multiple reports simultaneously#>
$servername="Localhost"
$SQLServer="erxpwssrs1000"
$sqldatabase="master"
$Query="SELECT subscriptionid FROM SubscriptionsToUpdate"

#Create connection to SSRS Server
$ReportServerUri = "http://$servername/ReportServer//ReportService2010.asmx?wsdl"
$ssrs = New-WebServiceProxy -Uri $ReportServerUri -UseDefaultCredential

#Get Reports from SQL Query
$connectionString = "Data Source=$SQLServer;Initial Catalog=$sqldatabase;Trusted_Connection=True;"
$connection = New-Object -TypeName System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $connectionString
$command = $connection.CreateCommand()
$command.CommandText = $Query
$adapter = New-Object -TypeName System.Data.SqlClient.SqlDataAdapter $command
$dataset = New-Object -TypeName System.Data.DataSet
$numrows = $adapter.Fill($dataset)
$subscriptions = ($dataset.Tables[0])

#Get the namespace for use in later steps, needed to create objects using the Policy class
$namespace = $ssrs.getType().namespace

#there is no method to change the render of format of subscriptions
foreach($subscription in $subscriptions)
{
	Write-Host $message
	$policy = New-Object ($namespace + ".ExtensionSettings")
	$policy
}
$itempolicies = $ssrs.GetPolicies($folder.path,[ref]"null")
	$itempolicies +=$policy

	$message = "{0}: Update completed." -f $(get-date -displayint DateTime)
	Write-Host $message
	Write-Host ""
	$policy.Format = $format
	$policy.Roles = $role

#Update the folder with the new role assignments
$ssrs.SetPolicies($folder.Path,$itempolicies)

#SetSubscriptionProperties

#unfinished work