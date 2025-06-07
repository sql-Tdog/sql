Connect-AzAccount -ServicePrincipal -ApplicationId "xxx" -FederatedToken $(Get-Content  $env:AZURE_FEDERATED_TOKEN_FILE -raw) -Tenant $env:AZURE_TENANT_ID
$access_token = (Get-AzAccessToken -ResourceUrl https://database.windows.net).Token
Invoke-Sqlcmd -Query "SELECT * FROM sys.server_principals;" -ServerInstance "xxx.database.windows.net" -AccessToken $access_token