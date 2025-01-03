#this script takes a list of reports paths that need their data sources to be 
#updated and updates them to a shared data source located in the Data Sources
#folder
$servername="Localhost"
$SQLServer="(local)"
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
$paths = ($dataset.Tables[0])
$role = $ssrs.ListRoles("Catalog",$null) | where-object {$_.name -eq "Content Manager"}

#Get the namespace for use in later steps, needed to create objects using the Policy class
$namespace = $ssrs.getType().namespace

$reportpath="/Reports/IPAS/Reports Retired/1 CEE Details 20160720_1559"

foreach($reportpath in $paths)
{
	#current data source name: (this is a guess in some cases)
	$DataSourceName="IPAS" #will not use this
	$dataSources = $ssrs.GetItemDataSources($reportpath)
	$DatasourcePath = "/Data Sources/Ipas-Prod"
	$d = $dataSources[0] # | Where-Object {$_.name -like $DataSourceName }
        $proxyNameSpace = $dataSources.gettype().Namespace
    	$newDataSource = New-Object ("$proxyNameSpace.DataSource")
        $newDataSource.Name = "Ipas-Prod"
        $newDataSource.Item = New-Object ("$proxyNamespace.DataSourceReference")
        $newDataSource.Item.Reference = $DatasourcePath 
        $d.item = $newDataSource.item
        $ssrs.SetItemDataSources($reportpath, $d)
        $set = ($ssrs.GetItemDataSources("$reportPath")).name
        

	$message = "{0}: Update completed." -f $(get-date -displayint DateTime)
	Write-Host $message
	Write-Host ""
}


#written with help from:  https://stackoverflow.com/questions/49418709/bulk-change-ssrs-data-sources-using-powershell


