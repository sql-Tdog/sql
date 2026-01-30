$subscriptionId = "xxx"


# Connect to Azure with my account, using device authentication:
# There should be a response message with website link & code to login
Connect-AzAccount -UseDeviceAuthentication -Subscription $subscriptionId


$response = Invoke-AzRestMethod -Method GET -Path "/subscriptions/$subscriptionId/locations?api-version=2022-12-01"
$locations = ($response.Content | ConvertFrom-Json).value
$locations | Where-Object {$null -ne $_.availabilityZoneMappings} | Select-Object -Property name,displayName,@{name='availabilityZoneMappings';expression={$_.availabilityZoneMappings | convertto-json}} | Format-List
