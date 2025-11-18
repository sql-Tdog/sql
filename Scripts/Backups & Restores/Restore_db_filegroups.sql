/**
This script is for taking backups and doing a piecemeal restore of a database with 
multiple filegroups.



--take a full backup of database:
BACKUP DATABASE FilegroupFull TO DISK = N'C:\SQLData\backups\BackupFilegroupFull_full.bak'


--take a transaction log backup:
BACKUP LOG FilegroupFull TO DISK = N'C:\SQLData\backups\BackupFilegroupFull_tlog1.trn'


--take a back up of the tail of transaction log, this step is essential!:
USE Master
GO
BACKUP LOG FilegroupFull TO DISK = N'C:\SQLData\backups\BackupFilegroupFull_tlogtail.trn' 
WITH NORECOVERY, NO_TRUNCATE;


--restore primary filegroup:
RESTORE DATABASE FilegroupFull 
FILEGROUP = 'Primary'
FROM DISK = N'C:\SQLData\backups\BackupFilegroupFull_full.bak' 
WITH PARTIAL, NORECOVERY 

RESTORE LOG FilegroupFull 
FROM DISK = N'C:\SQLData\backups\BackupFilegroupFull_tlog1.trn' 
WITH NORECOVERY 

RESTORE LOG FilegroupFull 
FROM DISK = N'C:\SQLData\backups\BackupFilegroupFull_tlogtail.trn' 
WITH NORECOVERY;  

--******
In Enterprise Edition:  we restore last log with RECOVERY to bring PRIMARY filegroup online and then continue restoring other filegroups (piecemeal restore)
In Standard Edition: restoring process will have to started from beginning with NORECOVERY for each filegroup until ALL filegroups have been restored
--*****
GO




--restore another filegroup:  (filegroup-restore sequence)

RESTORE DATABASE FilegroupFull 
FILEGROUP = 'FGFullFG2'
FROM DISK = N'C:\SQLData\backups\BackupFilegroupFull_full.bak' 
WITH PARTIAL, NORECOVERY 

RESTORE LOG FilegroupFull 
FROM DISK = N'C:\SQLData\backups\BackupFilegroupFull_tlog1.trn' 
WITH NORECOVERY 

RESTORE LOG FilegroupFull 
FROM DISK = N'C:\SQLData\backups\BackupFilegroupFull_tlogtail.trn' 
WITH NORECOVERY;
GO


RESTORE DATABASE FilegroupFull 
FILEGROUP = 'FGFullFG3'
FROM DISK = N'C:\SQLData\backups\BackupFilegroupFull_full.bak' 
WITH PARTIAL, NORECOVERY 

RESTORE LOG FilegroupFull 
FROM DISK = N'C:\SQLData\backups\BackupFilegroupFull_tlog1.trn' 
WITH NORECOVERY 

RESTORE LOG FilegroupFull 
FROM DISK = N'C:\SQLData\backups\BackupFilegroupFull_tlogtail.trn' 
WITH NORECOVERY;
GO


--restore the final ***read-only***  filegroup and bring database online:
RESTORE DATABASE FilegroupFull 
FILEGROUP = 'FGFullFG4'
FROM DISK = N'C:\SQLData\backups\BackupFilegroupFull_full.bak' 
WITH RECOVERY 

GO


--if a filegroup needs to be brought online and its data is undamaged, it does not need to be restored from a backup:
RESTORE DATABASE FilegroupFull FILEGROUP = 'FGFullFG2'; 
*/

--check the status of each file (Enterprise Edition Only):
SELECT [name], [state_desc] 
FROM FilegroupFull.sys.database_files;
GO

/**take backups of individual files and/or filegroups***********************
--backup a filegroup of a database:
BACKUP DATABASE FilegroupFull FILEGROUP='FGFullFG3' TO DISK = 'C:\SQLData\backups\BackupFilegroupFGFullFG3.bak';

--backup a file of a filegroup:
BACKUP DATABASE FilegroupFull FILE='filegroup1file1', FILE='filegroup1file2' TO DISK='C:\SQLBackups\dfa.bak';

*/
/**The first RESTORE statement in a piecemeal restore, which is known as a partial-restore sequence, must include the PRIMARY filegroup. 
***It also must include the option WITH PARTIAL. You can restore as many filegroups as you want in the first restore. 
***You should know how large your filegroups are, and how long they will take to restore, and how many you can restore at one time, 
***to meet your company’s disaster recovery business requirements. 

***If the database is in FULL recovery mode, transaction log must be restored with every filegroup that is in read-write mode. 

******IMPORTANT:  database can be brought online after Primary filegroup is restored only in Enterprise Edition*******

--restore Primary filegroup:

RESTORE DATABASE FilegroupFull 
FILEGROUP = 'Primary'
FROM DISK = N'C:\SQLData\backups\BackupFilegroupFull_full.bak' 
WITH PARTIAL, NORECOVERY 

RESTORE LOG FilegroupFull 
FROM DISK = N'C:\SQLData\backups\BackupFilegroupFull_tlog1.trn' 
WITH NORECOVERY 

RESTORE LOG FilegroupFull 
FROM DISK = N'C:\SQLData\backups\BackupFilegroupFull_tlogtail.trn' 
WITH NORECOVERY;  --****use WITH RECOVERY in Enterprise Edition to bring this filegroup online after this restore is complete****
GO


--check the status of each file if database is brought online (Enterprise Edition only):
SELECT [name], [state_desc] 
FROM FilegroupFull.sys.database_files;
GO


--restore another filegroup:  (filegroup-restore sequence)

RESTORE DATABASE FilegroupFull 
FILEGROUP = 'FGFullFG2'
FROM DISK = N'C:\SQLData\backups\BackupFilegroupFull_full.bak' 
WITH PARTIAL, NORECOVERY 

RESTORE LOG FilegroupFull 
FROM DISK = N'C:\SQLData\backups\BackupFilegroupFull_tlog1.trn' 
WITH NORECOVERY 

RESTORE LOG FilegroupFull 
FROM DISK = N'C:\SQLData\backups\BackupFilegroupFull_tlogtail.trn' 
WITH NORECOVERY;  --****use WITH RECOVERY in Enterprise Edition to bring this filegroup online after this restore is complete****
GO


--restore the final ***read-only***  filegroup and brind database online:
RESTORE DATABASE FilegroupFull 
FILEGROUP = 'FGFullFG4'
FROM DISK = N'C:\SQLData\backups\BackupFilegroupFull_full.bak' 
WITH RECOVERY 



*/