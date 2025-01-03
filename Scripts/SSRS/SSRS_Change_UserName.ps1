$servername="Localhost"
$SQLServer="erxpwssrs1000"
$sqldatabase="master"
$Query="SELECT Path FROM FoldersToUpdate ORDER BY Path"

#Create connection to SSRS Server
$ReportServerUri = "http://$servername/ReportServer//ReportService2010.asmx?wsdl"
$ssrs = New-WebServiceProxy -Uri $ReportServerUri -UseDefaultCredential

#Get Folders from SQL Query
$connectionString = "Data Source=$SQLServer;Initial Catalog=$sqldatabase;Trusted_Connection=True;"
$connection = New-Object -TypeName System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $connectionString
$command = $connection.CreateCommand()
$command.CommandText = $Query
$adapter = New-Object -TypeName System.Data.SqlClient.SqlDataAdapter $command
$dataset = New-Object -TypeName System.Data.DataSet
$numrows = $adapter.Fill($dataset)
$folders = ($dataset.Tables[0])
$login = "CENTENE\BI ReportContentManager"
$role = $ssrs.ListRoles("Catalog",$null) | where-object {$_.name -eq "Content Manager"}

#Get the namespace for use in later steps, needed to create objects using the Policy class
$namespace = $ssrs.getType().namespace

foreach($folder in $folders)
{
	$message = "{0}: Updating user for the following report: '{1}'." -f $(get-date -displayint DateTime), $folder.Path
	Write-Host $message
	$policy = New-Object ($namespace + ".policy")
	$policy.GroupUserName = $login
	$policy.Roles = $role
	$itempolicies = $ssrs.GetPolicies($folder.path,[ref]"null")
	$itempolicies +=$policy

	#Update the folder with the new role assignments
	$ssrs.SetPolicies($folder.Path,$itempolicies)


	$message = "{0}: Update completed." -f $(get-date -displayint DateTime)
	Write-Host $message
	Write-Host ""
}