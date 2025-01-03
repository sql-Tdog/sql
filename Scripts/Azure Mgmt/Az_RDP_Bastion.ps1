<####
This script is to natively RDP to an Azure VM from a local computer using the Azure bastion host

####>

#always login first
az login

#set subscription to access:
$subscription="xxxx"
az account set -s $subscription


#bastion of the VM, found on Connect>Bastion page
$bastion="xx-bastion" 
$VM="xxx"
#click on bastion from  Connect>Bastion page to get the Resource group
$bastionresourcegroup="xxxx"
$VMresourcegroup="xxxx"
#rdp to the bastion host:
az network bastion rdp --name $bastion --resource-group $bastionresourcegroup --target-resource-id "/subscriptions/$subscription/resourceGroups/$VMresourcegroup/providers/Microsoft.Compute/virtualMachines/$VM"

