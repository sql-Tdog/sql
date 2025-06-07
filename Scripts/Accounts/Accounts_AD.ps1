Get-ADUser ta.ni.temp -Properties * | Select-Object Name, LockedOut, LastLogonDate

Unlock-ADAccount -Identity ta.ni.temp

Enable-PSRemoting -Force


Get-ADServiceAccount -Identity "gmSql$" -Properties *
Get-ADServiceAccount -Identity "gmSqlAgt$" -Properties *