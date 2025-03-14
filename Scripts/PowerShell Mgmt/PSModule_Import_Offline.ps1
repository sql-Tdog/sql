#Download needed module from www.powershellgallery.com
#it will be a nupkg file
#unblock the file:
Unblock-File -Path C:\SQL\az.11.2.0.nupkg

#rename it to a .zip and then extract to a folder
#copy that folder to the PS module folder, check here:
$env:PSModulePath.split(";")

#if module was copied as a folder from another machine
Install-Module -Name Az.accounts

#for modules that have dependencies: main module gets its own folder, ie Az
#dependencies are named Az.accounts, Az.storage, etc.
#verify name of module folder is like this:  SqlServer>22.2.0
#then import module:  (install tries to download it from a remote repository)
Import-Module -Name SqlServer
Import-Module -Name Az


#look at the contents of the servers text file:
get-content -Path "C:\Users\Tanya.Nikolaychuk-AM\Documents\DBA Scripts\PowerShell\BingNonProdservers.txt"
Get-InstalledModule -Name SQLSERVER
Get-Module -ListAvailable -Name SQLSERVER
#assign the values to an array:
$serverlist = @(get-content -Path "C:\Users\Tanya.Nikolaychuk-AM\Documents\DBA Scripts\PowerShell\BingNonProdservers.txt")

#Get PS version of all servers without using a for loop:
Invoke-Command -ComputerName $serverlist  -ScriptBlock {$PSVersionTable.PSVersion}
#Get PS version of all servers without using a for loop and dump the info into a CSV file
Invoke-Command -ComputerName $serverlist  -ScriptBlock {$PSVersionTable.PSVersion} | Export-Csv -Path "C:\Users\Tanya.Nikolaychuk-AM\Documents\KC DB Scripts\ServerPSversion.csv" -Append

Invoke-Command -ComputerName $serverlist  -ScriptBlock {Get-Module -ListAvailable -Name SQLSERVER}

#iterate through the list and get PS version and check if SQLSERVER module is installed:
foreach ($server in $serverlist)
    {
        write-output "server: $server"
       
        Invoke-Command -ComputerName $server -ScriptBlock {$PSVersionTable.PSVersion} # | Export-Csv -Path "C:\Users\Tanya.Nikolaychuk-AM\Documents\KC DB Scripts\ServerPSversion.csv" -Append
        Invoke-Command -ComputerName $server -ScriptBlock { Get-InstalledModule -Name SQLSERVER} #| Export-Csv -Path "C:\Users\Tanya.Nikolaychuk-AM\Documents\KC DB Scripts\ServerPSSQLModuleversion.csv" -Append
       
    }

get-content -Path "C:\Users\Tanya.Nikolaychuk-AM\Documents\KC DB Scripts\ServerPSversion.csv"
get-content -Path "C:\Users\Tanya.Nikolaychuk-AM\Documents\KC DB Scripts\ServerPSSQLModuleversion.csv"

#sample script to install SQLSERVER module on each server if they have internet access:
Invoke-WebRequest -UseBasicParsing -Uri https://psg-prod-eastus.azureedge.net/packages/powershell-yaml.0.4.2.nupkg  -OutFile powershell-yaml.0.4.2.zip
Invoke-Command -ComputerName (Get-Content -Path "C:\Users\Tanya.Nikolaychuk-AM\Documents\DBA Scripts\PowerShell\servers.txt") -ScriptBlock {Install-module SQLSERVER} 


Enter-PSSession -ComputerName P1BNGBSN1P02
    cd 'C:\Program Files\WindowsPowerShell\Modules'
    [Environment]::Is64BitProcess
    $env:PSModulePath
    Get-InstalledModule -Name SQLPS
    Get-InstalledModule -Name SQLSERVER
    Get-Module -ListAvailable -Name SQLSERVER
    Import-Module -Name SQLServer #import vs install:  install downloads the module from the web & installs, import is offline
    Get-PSRepository
    Get-PackageSource
    Install-Package "C:\Program Files\WindowsPowerShell\Modules\sqlserver\21.1.18256" 
    Install-module SQLSERVER
    Find-Module -Name *sqlserver*| Select Name, Version, Repository
    $Env:PSModulePath
    Get-ChildItem "C:\Program Files\WindowsPowerShell\Modules\"
    Get-ChildItem "C:\Program Files\WindowsPowerShell\Modules\sqlserver\21.1.18256"
    Expand-Archive -Path "C:\Program Files\WindowsPowerShell\Modules\sqlserver.21.1.18256.zip" -DestinationPath "C:\Program Files\WindowsPowerShell\Modules\21.1.18256"
Exit-PSSession

#connect to a server to copy over the file
$mySession = New-PSSession -ComputerName PDX1KUPAYDB1Q
Copy-Item "C:\Users\Tanya.Nikolaychuk-AM\Documents\KC DB Scripts\sqlserver.21.1.18256.nupkg" -Destination "E:\" -ToSession $mySession

#iterate through the list to copy SQLSERVER module installation file and install it:
foreach ($server in $serverlist)
    {
        write-output "server: $server" #print out the server name first so that I know which server the commands ran on
        $mySession = New-PSSession -ComputerName $server
        Copy-Item "C:\Users\Tanya.Nikolaychuk-AM\Documents\KC DB Scripts\sqlserver.21.1.18256.nupkg" -Destination "D:\" -ToSession $mySession
        #the nupkg file must be renamed to a zip file so that it can be expanded
        Invoke-Command -ScriptBlock { Move-Item "D:\sqlserver.21.1.18256.nupkg" -Destination "C:\Program Files\WindowsPowerShell\Modules\sqlserver.21.1.18256.zip" } -Session $mySession
        Invoke-Command -ScriptBlock {New-Item -Path $env:ProgramFiles\WindowsPowerShell\Modules\SqlServer -ItemType Directory} -Session $mySession
        Invoke-Command -ScriptBlock { Expand-Archive -Path "C:\Program Files\WindowsPowerShell\Modules\sqlserver.21.1.18256.zip" -DestinationPath "C:\Program Files\WindowsPowerShell\Modules\SqlServer\21.1.18256"} -Session $mySession
        Invoke-Command -ScriptBlock { Import-Module -Name SQLSERVER} -Session $mySession
        Invoke-Command -ScriptBlock { Get-Module -ListAvailable -Name SQLSERVER} -Session $mySession | Export-Csv -Path "C:\Users\Tanya.Nikolaychuk-AM\Documents\KC DB Scripts\ServerPS_SQLModule.csv" -Append
    }

get-content -Path "C:\Users\Tanya.Nikolaychuk-AM\Documents\KC DB Scripts\ServerPS_SQLModule.csv"
