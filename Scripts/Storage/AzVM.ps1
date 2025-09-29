$managedIdClientId = "xxx"
$AzureContext = (Connect-AzAccount -Identity -AccountId $managedIdClientId).context 
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription  
$AzureContext


Install-Module Az.Compute
Start-AzVM -ResourceGroupName "ResourceGroupName" -Name "VM_Name"