#by default, remoting is enabled on Windows 12 and later and
#PS uses WMI for communications, ports 5985 & 5986
#you can specify to use HTTP for remoting, ports 80 & 443
#ports need to be configured to listed on HTTP ports either using group policy or WinRM


$sessions = New-PSSession -ComputerName t-biodswin01,p-biodswin01,p-biodswin02
$result = Invoke-Command -Session $sessions -FilePath .\GatherTroubleshootingData.ps1
dir -Path C:\users -Filter *.sql

#using different credentials:
$c = Get-Credential  #enter credentials in a pop up window, this credential needs no access to my current computer
$sessions = New-PSSession -ComputerName t-biodswin01 -Cred $c
whoami

Enter-PSSession #can only be used to connect to a single remote computer, enters an existing session, does not cosume additional resources
New-PSSession  #creates a new session on the remote server rather than using an existing session
Exit-PSSession

#to enable remoting on old boxes: (starts WinRM service & sets to automatic startup, creates listener, opens firewall
Enable-PSRemoting