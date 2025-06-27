Import-Module "C:\Program Files\SolarWinds SQL Sentry\2025.0\Intercerve.SQLSentry.Powershell.psd1"

$servername = ""
$database = "SQLSentry"
Connect-SQLSentry -ServerName $servername -DatabaseName $database

$servers = @("", "", "", "")

foreach ($server in $servers) {
    try {
        # Register the SQL Server connection
        Register-Connection -ConnectionType SqlServer -Name $server
        
        # Invoke the connection using Get-Connection
        Get-Connection -Name $server -NamedServerConnectionType SqlServer | Invoke-WatchConnection

        Write-Host "Successfully registered and invoked connection for $server" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to process $server. Error: $_" -ForegroundColor Red
    }
}