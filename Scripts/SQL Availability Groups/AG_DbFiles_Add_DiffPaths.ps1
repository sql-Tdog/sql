<#
You can remove the database from always on on the secondary server that do not have the 
same drive configuration as the primary server. This puts the database on the secondary 
server in a restoring state.
Now add the File to the primary sever.
Take a log backup on primary
Restore the log on secondary using the with move option and provide a folder that exists 
on the secondary
Now add the database back to always on secondary.
This way you don’t have to reinitialize from scratch


#>

CREATE DATABASE TestAG

BACKUP DATABASE TestAG TO DISK='C:\Temp\TestAG.bak'
BACKUP LOG TestAG TO DISK='C:\Temp\TestAG.bak'

ALTER AVAILABILITY GROUP AGSenI01 ADD DATABASE TestAG


ALTER AVAILABILITY GROUP AGSenI01 MODIFY REPLICA ON N'w3sqlseni01' WITH (SEEDING_MODE = AUTOMATIC);
ALTER AVAILABILITY GROUP AGSenI01 MODIFY REPLICA ON N'e1sqlseni01' WITH (SEEDING_MODE = AUTOMATIC);
ALTER AVAILABILITY GROUP AGSenI01 MODIFY REPLICA ON N'e1sqlseni02' WITH (SEEDING_MODE = AUTOMATIC);

ALTER AVAILABILITY GROUP AGSenI01 MODIFY REPLICA ON N'w3sqlseni01' WITH (SEEDING_MODE = MANUAL);
ALTER AVAILABILITY GROUP AGSenI01 MODIFY REPLICA ON N'e1sqlseni01' WITH (SEEDING_MODE = MANUAL);
ALTER AVAILABILITY GROUP AGSenI01 MODIFY REPLICA ON N'e1sqlseni02' WITH (SEEDING_MODE = MANUAL);

--remove database from the AG, putting it into restoring mode on the secondary nodes
ALTER AVAILABILITY GROUP AGSenI01 REMOVE DATABASE TestAG


--create a new path on the primary, it will not exist on the secondaries
EXEC xp_create_subdir 'Z:\Test' 

--add the file on the primary
ALTER DATABASE TestAG ADD FILE (NAME='TestAG2', FILENAME='Z:\Test\temp5.ndf', SIZE=10MB, FILEGROWTH=10%)

--take a log backup:
BACKUP LOG TestAG TO DISK='C:\Temp\TestAG.trn'

--move the file on the secondaries when restoring the log
ALTER DATABASE TestAG MODIFY FILE (NAME='TestAG2', FILENAME='C:\Temp\temp5.ndf')

--add database back to the AG
ALTER  DATABASE TestAG SET HADR AVAILABILITY GROUP = AGSenI01



DROP DATABASE TestAG
