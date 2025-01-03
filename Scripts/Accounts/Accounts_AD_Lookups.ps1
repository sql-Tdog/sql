# UPDATE GROUPS ARRAY WITH DATA FROM SQL QUERIES
$Groups=@(
"Role-ITOperations",
"Role-ITOperationsPriv",
"Role-DevOpsPriv",
"Role-SQLDBAPriv"
)

# CREATE PATH IF IT DOESN"T EXIST
If (-not (test-path "c:\temp\"))
{
new-item "c:\temp" -itemtype Directory
}

$script:arrlist=@() # Array to hold the list of users

# FIND WHICH USERS ARE IN A GROUP
foreach ($g in $groups)
{
        # Get the list of Users for each group
        $arrUser=Get-ADGroupMember $g | select Name,samaccountname,objectclass
         
         # Add the users to an Array
         foreach ($a in $arrUser)
        { 
            $objUsers= New-Object PSObject
            $objUsers  | Add-Member -membertype NoteProperty -Name ADgroup -Value $g
            $objUsers  | Add-Member -membertype NoteProperty -Name UserName -Value $a.name
            $objUsers  | Add-Member -membertype NoteProperty -Name UserAccount -Value $a.SamAccountName
            $objUsers  | Add-Member -membertype NoteProperty -Name ObjectType -Value $a.objectclass
        
            # store the current user and their properties in the main array
            $script:arrlist += $objUsers
       }
}

$date=get-date -format "MMddyyyy_HHmmss"
$date2=get-date
$script:arrlist | export-csv c:\temp\baseline_ADusers$date.csv -NoTypeInformation
write-host "Export complete on" $date2 -ForegroundColor Yellow

