Add-WindowsFeature -Name RSAT-AD-Powershell -ErrorAction Stop
Import-Module -Name ActiveDirectory -ErrorAction Stop

#if not able to Install-ADServiceAccount, open Cmd Prompt as Admin, enter:
klist purge -li 0x3e7


$gmsaSQL="$"
$gmsaAgent="$"
$inst1=""
$inst2=""


#to create new AD Service Accounts:
New-ADServiceAccount gmSqlI01 -ManagedPasswordIntervalInDays 1 -PrincipalsAllowedToRetrieveManagedPassword "SQL Server Service Accounts - TK1R1S1 DSDB" -DNSHostName "gmSqlI01.tkad.dsinfra.net"
New-ADServiceAccount gmSqlIAgt01 -ManagedPasswordIntervalInDays 1 -PrincipalsAllowedToRetrieveManagedPassword "SQL Server Service Accounts - TK1R1S1 DSDB" -DNSHostName "gmSqlIAgt01.tkad.dsinfra.net"



#install them on local SQL Server:
Install-AdServiceAccount $gmsaSQL -ErrorAction Stop
Install-AdServiceAccount $gmsaAgent -ErrorAction Stop

#test on local server:
Test-ADServiceAccount -Identity $gmsaSQL
Test-ADServiceAccount -Identity $gmsaAgent


#install & test remotely:
Enter-PSSession -ComputerName $inst1

    add-windowsfeature RSAT-AD-PowerShell
    install-ADServiceAccount -Identity $gmsaSQL
    install-ADServiceAccount -Identity $gmsaAgent
    test-ADServiceAccount -Identity $gmsaSQL
    test-ADServiceAccount -Identity $gmsaAgent


Exit-PSSession


Enter-PSSession -ComputerName $inst2

    add-windowsfeature RSAT-AD-PowerShell
    install-ADServiceAccount -Identity $gmsaSQL
    install-ADServiceAccount -Identity $gmsaAgent
    test-ADServiceAccount -Identity $gmsaSQL
    test-ADServiceAccount -Identity $gmsaAgent


Exit-PSSession


#Give the account permission to "Perform volume maintenance tasks" & "Lock Pages in Memory"
#secpol > Local Policies > User Rights Assignment
#this can also be set through the GPO, set by OU


#to add user to local admin:
lusrmgr.msc