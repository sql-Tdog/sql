# SSRS Encryption Key Rotation Script with PagerDuty and Slack Integration

$sessions = New-PSSession -ComputerName P1CMSRPN1T01
$servername="Localhost"
$site="/"

#Create connection to SSRS Server
$ReportServerUri = "http://$servername/ReportServer//ReportService2010.asmx?wsdl"
$ssrs = New-WebServiceProxy -Uri $ReportServerUri -UseDefaultCredential
$subscriptions = $ssrs.ListSubscriptions($site); #list all subscriptions

# Set the Report Server URL and credentials

$ReportServerUrl = "http://localhost/ReportServer"
$Username = "tanya.nikolaychuk"

# Prompt for the list of servers
$ServerList = Read-Host "Enter a comma-separated list of server names"

# Split the server names into an array
$Servers = $ServerList -split ','

Write-Host "Rotating encryption keys for server: $Server"

# Create a proxy object to interact with the SSRS web service
$SSRSWebService = New-WebServiceProxy -Uri "$Server/ReportService2010.asmx?wsdl"
$SSRSWebService.Url = "$Server/ReportService2010.asmx"

# Set the credentials for the SSRS web service
$SSRSWebService.Credentials = New-Object System.Net.NetworkCredential($Username, $Password)

# Generate a new encryption key
$NewEncryptionKey = $SSRSWebService.GenerateEncryptionKey()

# Backup the existing encryption key
$BackupEncryptionKey = $SSRSWebService.GetEncryptionKey()

# Apply the new encryption key
$SSRSWebService.SetEncryptionKey($NewEncryptionKey)

        # Verify the new encryption key
$CurrentEncryptionKey = $SSRSWebService.GetEncryptionKey()
if ($NewEncryptionKey -eq $CurrentEncryptionKey) {
    Write-Host "Encryption key rotation completed successfully for server: $Server"
} else {
    Write-Host "Encryption key rotation failed for server: $Server. Please check the SSRS configuration."
}
catch {
Write-Host "An error occurred while rotating encryption keys for server: $Server"
Write-Host $_.Exception.Message
}

