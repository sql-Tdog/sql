#Export CSV File
Get-Process | Export-Csv -Path "C:\users\tanya\downloads\process.csv"

notepad C:\users\tanya\downloads\process.csv

#Import CSV File
$values = Import-Csv -Path "C:\users\tanya\downloads\process.csv"
$values | Select-Object -First 10  | Out-GridView

#Export XML File
Get-Process | Export-Clixml -Path "C:\users\tanya\downloads\process.xml"

notepad C:\users\tanya\downloads\process.xml

#Import XML File
$values = Import-Clixml -Path "C:\users\tanya\downloads\process.xml"
$values | Select-Object -First 10  | Out-GridView
