
$serverlist=get-content C:\sox\servers.txt
$workingdir="c:\sox"
$script:AllSQLAdmins=@()  # GLOBAL VARIABLE TO HOLD MASTER LIST OF SQL ADMINS
$script:domainlist=@()  # GLOBAL VARIABLE TO HOLD MASTER LIST OF DOMAIN ACCOUNTS AND GROUPS
$script:AllPrivRolesSQL=@()
$type=read-host 'Enter Audit Stage: "validate" OR "baseline"'
function get-DbAdmins
{
    $scriptPath = "C:\Sox\sysadmin-sql.txt"
    foreach($si in $serverlist)
    {
        # GET MEMBERS OF REMOTE LOCAL ADMIN GROUPS AND STORE RESULTS INTO OBJECT
        # WILL RUN AGAINST ALL SERVERS IN SERVER.TXT
        Write-host "Getting data for $si"    
        $SQLAdmins=Invoke-Sqlcmd -ConnectionString "Data Source=$si;Integrated Security=True;" -InputFile $scriptPath
    
 
         # LOOP THROUGH EACH OBJECT AND STORE RESULTS IN MASTER LIST
         ForEach($sa in $SqlAdmins)
         {
            $objUsers= New-Object PSObject
            $objUsers | Add-Member -MemberType noteProperty -Name ComputerName -Value $si
            $objUsers | Add-Member -MemberType noteProperty -Name Name -Value $sa.name
            $objUsers | Add-Member -MemberType noteProperty -Name Group -Value $sa.type
            $objUsers | Add-Member -MemberType noteProperty -Name description -Value $sa.type_desc
            $objUsers | Add-Member -MemberType noteProperty -Name is_disabled -Value $sa.is_disabled
            $objUsers | Add-Member -MemberType noteProperty -Name create_date -Value $sa.create_date
 
            # ADD OBJECT INFO TO MASTER LIST ARRAY
            $script:AllSQLAdmins += $objUsers
        
         }
       }
}

function get-DbRoles
{
    $scriptPath = "c:\sox\dbroles-sql.txt"
    
    foreach($si in $serverlist)
    {
        Write-host "Getting data for $si"    
        
        #GET LIST OF DBS ON THE SERVER       
        $dbs=Invoke-Sqlcmd -ConnectionString "Data Source=$si;Integrated Security=True;" -query "SELECT name, database_id, create_date  FROM sys.databases;"

        foreach($db in $dbs)
        {
            
            #EXCLUDE THE SYSTEMS DATABASES AND THE DBA TOOLBOX
            IF ($db.database_id -gt "4"-AND $db.name -notlike "*DBAToolbox*")
            {
                # GET USERS WHO HAVE ELEVATED ROLES ON ALL PROD DBS ON THE SERVER
                # WILL RUN AGAINST ALL SERVERS IN SERVER.TXT AND ALL DATABASES
                
                $dbName=$db.name  ## NEED TO DO THIS TO PASS VARIABLE IN INVOKE-SQL COMMAND.. NOT SURE WHY I CAN'T USE $db.name
                $PrivRolesSQL=Invoke-Sqlcmd -ConnectionString "Data Source=$si;Integrated Security=True;" -InputFile $scriptPath -v mydb=$dbName
                
                # LOOP THROUGH EACH OBJECT AND STORE RESULTS IN MASTER LIST
                ForEach($PrivRoleSQL in $PrivRolesSQL)
                {

                $objPrivRolesSQL= New-Object PSObject

                $objPrivRolesSQL | Add-Member -MemberType noteProperty -Name ComputerName -Value $si

                $objPrivRolesSQL | Add-Member -MemberType noteProperty -Name DBName -Value $dbName

                $objPrivRolesSQL | Add-Member -MemberType noteProperty -Name Group -Value $PrivRoleSQL.DatabaseRoleName

                $objPrivRolesSQL | Add-Member -MemberType noteProperty -Name description -Value $PrivRoleSQL.DatabaseUserName
                
 
                # ADD OBJECT INFO TO MASTER LIST ARRAY
                $script:AllPrivRolesSQL += $objPrivRolesSQL
             }


            }
        }
    }
}

function get-adadminusers # AD USERS THAT HAVE DIRECT LOCAL ADMIN ACCESS
{

$objdomainusers= New-Object PSObject
            $objdomainusers | Add-Member -MemberType noteProperty -Name group -Value "None"
            $objdomainusers | Add-Member -MemberType noteProperty -Name NestedGroup -Value "None"
            $objdomainusers | Add-Member -MemberType noteProperty -Name Name -Value $objUniqueAdmins.SAMAccountName
            $objdomainusers | Add-Member -MemberType noteProperty -Name Type -Value $objUniqueAdmins.Objectclass
            $objdomainusers | Add-Member -MemberType noteProperty -Name Created -Value $objUniqueAdmins.Created
            $objdomainusers | Add-Member -MemberType noteProperty -Name Changed -Value $objUniqueAdmins.WhenChanged

            $script:domainlist += $objdomainusers
}

function get-adadmingroups # USERS WITH LOCAL ACCESS VIA AD GROUP
{
    
    
    Param($TopLevelGroup,$nestedgroup,$managedby)

    write-host "Processing Groups" -ForegroundColor Red
    write-host $topLevelGroup
    write-host $nestedGroup
    write-host $managedby

    $samAccountName=$TopLevelGroup
    If ($nestedGroup){$samAccountName=$nestedgroup}
    If (!$nestedgroup){$nestedgroup="none"} # If this variable is blank, write "none" in the report"
    
      
    # GET MEMBERS OF THE GROUP
    $GroupMembers=Get-ADGroupMember $samAccountName
        foreach ($itemGM in $GroupMembers)
        {
           # $sam="AccionLabs-Team"
            $sam=$itemGM.sAMAccountName #Get the sAM AccountName used in the next line
            $type=$itemGM.ObjectClass #Get ObjectClass to determine what to do with it
            $objGroupMembers=Get-ADObject -filter "(SamAccountName -like '$sam')" -properties sAMAccountName, ObjectClass, Created, WhenChanged, ManagedBy | select sAMAccountName, ObjectClass, Created, WhenChanged, ManagedBy
            if($managedby){$managedby=$managedby.split(',')[0] -replace ("CN=","")}

            
            If ($type -eq "user") #WRITE TO THE MASTER ARRAY
            {
            $objdomainusers= New-Object PSObject
                $objdomainusers | Add-Member -MemberType noteProperty -Name Group -Value $TopLevelGroup
                $objdomainusers | Add-Member -MemberType noteProperty -Name NestedGroup -Value $nestedgroup
                $objdomainusers | Add-Member -MemberType noteProperty -Name ManagedBy -Value $managedby
                $objdomainusers | Add-Member -MemberType noteProperty -Name Name -Value $objGroupMembers.sAMAccountName
                $objdomainusers | Add-Member -MemberType noteProperty -Name Type -Value $objGroupMembers.Objectclass
                $objdomainusers | Add-Member -MemberType noteProperty -Name Created -Value $objGroupMembers.Created
                $objdomainusers | Add-Member -MemberType noteProperty -Name Changed -Value $objGroupMembers.WhenChanged

                $script:domainlist += $objdomainusers
            }
            If ($type -eq "Group")
            {
                get-adadmingroups -nestedgroup $itemGM.SamAccountName -TopLevelGroup $TopLevelGroup -managedby $objGroupMembers.ManagedBy
            }
        }
}

function get-accounttype  # FINDS THE ACCOUNT TYPE, THEN CALLS PROPER AD FUNCTION FOR USER OR GROUP
{

    # GET RID OF THE DUPLICATES
    $arrLocalAdmins=($script:AllSQLAdmins).Name | select -Unique


    foreach ($iLocalAdmins in $arrLocalAdmins) 
    {
        $iLocalAdmins = $iLocalAdmins -replace "CORP\\" 
        
        $objUniqueAdmins=Get-ADObject -filter "(SamAccountName -like '$iLocalAdmins')" -properties sAMAccountName, ObjectClass, Created, WhenChanged, ManagedBy 
        $class=$objUniqueAdmins.ObjectClass

        IF ($class -eq 'user')
        {
            get-adadminusers
        }
        
        IF ($class -eq 'group')
        {

            get-adadmingroups -TopLevelGroup $objUniqueAdmins.sAMAccountName -managedby $objUniqueAdmins.ManagedBy
            
        }
        
     }
     
}


function write-result
{
     #WRITE LIST TO CSV FILE
    $date=get-date 
    
    $filename=$type+"_UAR_domainusers.csv"
    $domainlist | export-csv $workingdir\$filename -NoTypeInformation
    write-host "Export to $workingdir\$filename complete on" $date -ForegroundColor Yellow

    $filename=$type+"_UAR_sqlusers.csv"
    $AllSQLAdmins | export-csv $workingdir\$filename -NoTypeInformation
    write-host "Export to $workingdir\$filename complete on" $date -ForegroundColor Yellow

    $filename=$type+"_UAR_AllPrivRolesSQL.csv"
    $AllPrivRolesSQL | export-csv $workingdir\$filename -NoTypeInformation
    write-host "Export to $workingdir\$filename complete on" $date -ForegroundColor Yellow

}

get-DBAdmins
get-DbRoles
get-accounttype
write-Result
 


