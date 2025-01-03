$PSVersionTable
#look at the contents of the servers text file:
get-content -Path "C:\Users\Tanya.Nikolaychuk-AM\Documents\DBA Scripts\PowerShell\servers.txt"

#assign the values to an array:
$serverlist = @(get-content -Path "C:\Users\Tanya.Nikolaychuk-AM\Documents\DBA Scripts\PowerShell\servers.txt")

#iterate through the list:
foreach ($server in $serverlist)
    {
       write-output "server: $server"
       Invoke-Command -ComputerName $server -ScriptBlock {$PSVersionTable.PSVersion} | Export-Csv -Path "C:\Users\Tanya.Nikolaychuk-AM\Documents\KC DB Scripts\ServerPSversion.csv" -Append
    }

get-content -Path "C:\Users\Tanya.Nikolaychuk-AM\Documents\KC DB Scripts\ServerPSversion.csv"