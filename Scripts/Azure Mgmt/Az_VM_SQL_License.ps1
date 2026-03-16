<#
https://learn.microsoft.com/en-us/azure/azure-sql/virtual-machines/windows/licensing-model-azure-hybrid-benefit-ahb-change?view=azuresql&tabs=azure-powershell#change-license-model
#>

$subscriptionId = "xxx"

# Connect to Azure with my account, using device authentication:
# There should be a response message with website link & code to login
Connect-AzAccount -UseDeviceAuthentication -Subscription $subscriptionId

$RGname = "xxx"
$VMname = "xxx"
$LicenseType = "DR"
Update-AzSqlVM -ResourceGroupName $RGname -Name $VMname -LicenseType $LicenseType


