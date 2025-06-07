$inst1="xxx"
$inst2="xxx2"
$gmsaSQL="gmsa$"
$FQDN=$env:USERDNSDOMAIN


#remove SPN:
$array =  @(
     "MSSQLSvc/$inst1.$FQDN:1433",
     "MSSQLSvc/$inst1.$FQDN",
     "MSSQLSvc/$inst1:1433",
     "MSSQLSvc/$inst1"
)
foreach($item in $array){
    setspn -d $item $gmsaSQL
    }


#set SPN
$array =  @(
     "MSSQLSvc/$inst2.$FQDN:1433",
     "MSSQLSvc/$inst2.$FQDN",
     "MSSQLSvc/$inst2:1433"
)
foreach($item in $array){
    setspn -s $item $gmsaSQL
    }



#check if SPN is registered correctly:
setspn -L $gmsaSQL 

