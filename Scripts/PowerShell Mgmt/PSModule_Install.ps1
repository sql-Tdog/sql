#I used this script to install PS 5.1 on 2012R2 Servers, I had to RDP to the servers to run the msu file
get-content -Path "C:\Users\Tanya.Nikolaychuk-AM\Documents\DBA Scripts\PowerShell\ServersInstallPS51.txt"

#assign the values to an array:
$serverlist = @(get-content -Path "C:\Users\Tanya.Nikolaychuk-AM\Documents\DBA Scripts\PowerShell\ServersInstallPS51.txt")

Get-WmiObject Win32_OperatingSystem -ComputerName $serverlist |Select PSComputerName, Caption, OSArchitecture, Version, BuildNumber | FL

Invoke-Command -ScriptBlock { $PSVersionTable.PSVersion } -ComputerName $serverlist 


foreach ($server in $serverlist)
    {
        write-output "server: $server"
        $mySession = New-PSSession -ComputerName $server
        #Invoke-Command -ScriptBlock {New-Item -Path $env:ProgramFiles\WindowsPowerShell\Install51 -ItemType Directory} -Session $mySession
        #for Windows Server 2012 R2 and Windows 8.1: Win7AndW2K8R2-KB3191566-x64:
        #Copy-Item "C:\Users\Tanya.Nikolaychuk-AM\Documents\KC DB Scripts\PowerShell51\Win8.1AndW2K12R2-KB3191564-x64.msu" -Destination "C:\Program Files\WindowsPowerShell" -ToSession $mySession
        # expand command won't work on versions below 5.1
        #Invoke-Command -ScriptBlock { Expand-Archive -Path "C:\Program Files\WindowsPowerShell\Win7AndW2K8R2-KB3191566-x64.zip" -DestinationPath "C:\Program Files\WindowsPowerShell\Install51\"} -Session $mySession
        #Invoke-Command -ScriptBlock {Invoke-Expression -Command “C:\Users\Tanya.Nikolaychuk-AM\Documents\KC DB Scripts\PowerShell51\Win7AndW2K8R2-KB3191566-x64\Win7AndW2K8R2-KB3191566-x64.msu} -Session $mySession
       
    }

Invoke-Command -ComputerName PDX1HORIZDB1D -ScriptBlock {
    Start-Process 'wusa.exe' -ArgumentList '$env:ProgramFiles\WindowsPowerShell\PowerShell51\Win8.1AndW2K12R2-KB3191564-x64.msu', '/quiet','/norestart'
}

$mySession = New-PSSession -ComputerName PDX1HORIZDB1S
Copy-Item "C:\Users\Tanya.Nikolaychuk-AM\Documents\KC DB Scripts\PowerShell51\Win8.1AndW2K12R2-KB3191564-x64.msu" -Destination "C:\Program Files\WindowsPowerShell\Install51" -ToSession $mySession
Restart-Computer -ComputerName PDX1KUPAYDB1L -Force

Enter-PSSession -ComputerName PDX1KUPAYDB1L
    $PSVersionTable.PSVersion 
Exit
    Invoke-Command -ScriptBlock { Expand-Archive -Path "C:\Program Files\WindowsPowerShell\Win7AndW2K8R2-KB3191566-x64.zip" -DestinationPath "C:\Program Files\WindowsPowerShell\Install51\"} 
    wusa $env:ProgramFiles\WindowsPowerShell\Win7AndW2K8R2-KB3191566-x64\Win7AndW2K8R2-KB3191566-x64.msu /quiet /norestart
    $PSVersionTable.PSVersion 
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