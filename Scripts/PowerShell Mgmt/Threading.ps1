Get-Process  #returns a list of all the processes on the machine
Start-Job -ScriptBlock {Get-Process}  #runs the Get-Process in the background so there is no output of all the processes, only returns job info

#place the job into a variable:
$j = Start-Job -ScriptBlock {Get-EventLog -Log system -Credential "DESKTOP-H84N787\tanya"} #Credential can be requested ahead of time & can be stored in a variable
#take the variable J and format it before displaying
$j | Format-List -Property *  #will return properties of $j, which is a BackgroundJob object with a PSBeginTime, no PSENdTime, & State:Running
#executing the line above a second time will show us when the job began and when it ended
#other commands Stop-Job, Wait-Job, Receive-Job, Get-Job, Remove-Job
