Get-ADUser ta.ni.temp -Properties * | Select-Object Name, LockedOut, LastLogonDate

Unlock-ADAccount -Identity ta.ni.temp

Enable-PSRemoting -Force

Get-DeebSqlSentryMonitoringService -ComputerName "wesqlsentryi01"

Get-ADServiceAccount -Identity "gmSqlTSen1Agt1$" -Properties *
Get-ADServiceAccount -Identity "gmSqlSenAgtI01$" -Properties *