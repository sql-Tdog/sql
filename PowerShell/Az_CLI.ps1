winget install -e --id Microsoft.AzureCLI


#if above doesn't work, try:
$ProgressPreference = 'SilentlyContinue'; 
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; 
Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; 
Remove-Item .\AzureCLI.msi

az login





