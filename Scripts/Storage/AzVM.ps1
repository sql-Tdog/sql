$managedIdClientId = "9bf00545-75f4-4f0e-9b8e-7c771fb28edc"
$AzureContext = (Connect-AzAccount -Identity -AccountId $managedIdClientId).context 
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription  
$AzureContext


Install-Module Az.Compute
Start-AzVM -ResourceGroupName "sqlfabric-e1-integration-eastus" -Name "e1sqldseusi02"