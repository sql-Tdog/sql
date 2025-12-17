$managedIdClientId = "xx"
$resourceGroup= "xxx"


# Connect to Azure with user-managed-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity -AccountId $managedIdClientId).context 
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription  
$AzureContext

# Connect to Azure with my account:
Connect-AzAccount -UseDeviceAuthentication -Subscription $subscriptionId

$subscriptionId = "xxx"
$response = Invoke-AzRestMethod -Method GET -Path "/subscriptions/$subscriptionId/locations?api-version=2022-12-01"
$locations = ($response.Content | ConvertFrom-Json).value
$locations | Where-Object {$null -ne $_.availabilityZoneMappings} | Select-Object -Property name,displayName,@{name='availabilityZoneMappings';expression={$_.availabilityZoneMappings | convertto-json}} | Format-List
