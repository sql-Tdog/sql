$servername="Localhost"
$site="/"

#Create connection to SSRS Server
$ReportServerUri = "http://$servername/ReportServer//ReportService2010.asmx?wsdl"
$ssrs = New-WebServiceProxy -Uri $ReportServerUri -UseDefaultCredential
$subscriptions = $ssrs.ListSubscriptions($site); #list all subscriptions

$reportpath="/Financial Analysis/GER"
$lastdate=(Get-Date).AddDays(-3)
$todelete = $subscriptions | select path,report,description,owner,subscriptionid, lastexecuted, status | where {$_.path -eq $reportpath -and $_.description -like "*2015*"}
$todelete.count
$deletedsubs = $todelete | select subscriptionid
$deletedsubs = $deletedsubs | % {[string].$_.SubscriptionID} #conver to strings

#dump this data into a table

$SQLServer="erxpwssrs1000"
$sqldatabase="master"
$connectionString = "Data Source=$SQLServer;Initial Catalog=$sqldatabase;Trusted_Connection=True;MultipleActiveResultSets=True;"
$connection = New-Object -TypeName System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $connectionString
$connection.Open()
$command = New-Object System.Data.SQLClient.SQLCommand
$command.connection=$connection
$sql="create table SubsToDelete (sub varchar(500))"
$command.CommandText = $sql
$command.ExecuteReader()
$connection.Close()

$connection.Open()

foreach($i in $deletedsubs) {
	$sql="insert into SubsToDelete select '$i'"
	$command.CommandText = $sql
	$command.executenonquery() #executes and returns the numbers of rows affected

}

$connection.Close()