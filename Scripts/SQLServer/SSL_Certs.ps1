#verify cert exists:
$thumbprint = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQLServer\SuperSocketNetLib").Certificate
Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.Thumbprint -eq $thumbprint }


<#if cert is missing, it needs to be imported
open "Manage computer certificates"
expand Personal -> Certificates folder
Right click -> All Tasks -> Request New Certificate
Follow the GUI prompts

if VM cannot import, could be it cannot connect to CA b/c of firewall rules
#>