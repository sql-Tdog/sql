$inst1="e1sqldseuss02"
$inst2="e1sqldss02"
$gmsaSQL="gmSqlDSS02$"
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
     "MSSQLSvc/$inst2:1433",
     "MSSQLSvc/$inst2",
)
foreach($item in $array){
    setspn -s $item $gmsaSQL
    }



#check if SPN is registered correctly:
setspn -L $gmsaSQL 


#set SPN
setspn -S MSSQLSvc/$inst1.tkad.dsinfra.test:1433 TKAD\gmSqlI01$
setspn -S MSSQLSvc/w3sqldswu3i02.tkad.dsinfra.test:1433 TKAD\gmSqlI01$

