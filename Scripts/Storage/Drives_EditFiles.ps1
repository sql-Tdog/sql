#create a new folder:
New-Item "C:\Temp" -ItemType Directory

#create a new SMB Share:
New-SmbShare -Path C:\Temp -Name "SharedFolder$"
 
