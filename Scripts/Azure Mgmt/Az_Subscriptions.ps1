# Connect to Azure account
Connect-AzAccount

# Get all subscriptions
$subscriptions = Get-AzSubscription

# Create an array to store all Virtual WAN Hub resource URIs
$allVirtualWanHubUris = @()

# Loop through each subscription
foreach ($subscription in $subscriptions) {
    # Set the current subscription context
    Set-AzContext -SubscriptionId $subscription.Id

    # Get all resource groups in the current subscription
    $resourceGroups = Get-AzResourceGroup

    # Loop through each resource group to get Virtual WAN Hubs
    foreach ($resourceGroup in $resourceGroups) {
        $resourceGroupName = $resourceGroup.ResourceGroupName

        # Get all Virtual WAN Hubs in the current resource group
        $virtualWanHubs = Get-AzVirtualHub -ResourceGroupName $resourceGroupName

        # Extract the resource URI and add to the array
        $virtualWanHubs.ForEach({ $allVirtualWanHubUris += $_.Id })
    }
}

# Output the list of all Virtual WAN Hub resource URIs
$allVirtualWanHubUris