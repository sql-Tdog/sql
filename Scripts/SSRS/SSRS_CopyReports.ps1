<#This script is to copy reports to a different SSRS server#>

Invoke-Expression (Invoke-WebRequest https://aka.ms/rstools)

$SourceServer="erxdwssrs1500"

# Make $SourceReportPath the full path including file name
$SourceReportPath="/Client Services/Annual Reports/By TPA/Annual Report"

# Build URIs for ReportServer Services
$SourceServerURL="http://$SourceServer/ReportServer//ReportService2010.asmx"
$DestinationServerURL="http://erxpwssrs1000/ReportServer/ReportService2010.asmx"

# Create web service objects from URLs
$SourceProxy = New-WebServiceProxy -Uri $SourceServerURL -Namespace SSRS.ReportingService2010 -UseDefaultCredential
$DestinationProxy = New-WebServiceProxy -Uri $DestinationServerUrl -Namespace SSRS.ReportingService2010 -UseDefaultCredential

#check destination proxy
$DestinationProxy 

# Pull report definition from source
$ReportDefinition = $SourceProxy.GetItemDefinition($SourceReportPath)

#Define Destination Report Path & variables
$DestinationReportPath="/Client Services/Annual Reports/By TPA"
$ItemName="Annual Report"
$ItemType="Report"
$warnings = $null

# Push report definition to target
$DestinationProxy.CreateCatalogItem($ItemType,$ItemName,$DestinationReportPath,$true,$ReportDefinition,$null,[ref]$warnings)