/**
Backups can be done on secondary replicas but there are a few considerations:
       • When setting up the Availability Group, set backup preferences to whatever replica I want to take backups on
       • Script the backups and create a SQL Server Agent job on all of the replicas
       • Include the check to see if this is the preferred replica for doing backups
       • Full backups have to be done with COPY_ONLY option on secondary replicas
       • Taking a transaction log backup on any replica, truncates it on all replicas
 
--sample full backup script
DECLARE @DeleteDate DATETIME=DATEADD(hour,-36,getdate());
EXECUTE master.dbo.xp_delete_file 0,N'J:\Datamart',N'bak',@DeleteDate,1;
DECLARE @filename varchar(100);
SET @filename = 'J:\Datamart\Datamart_'+convert(varchar(11),getDate(),112) +'.bak';
IF (sys.fn_hadr_backup_is_preferred_replica('Datamart')=0) BEGIN
      Select 'This is not the preferred replica, exiting with success';
END ELSE
BACKUP DATABASE Datamart TO DISK=@filename WITH COPY_ONLY;
 
 
 
--sample log backup:
DECLARE @DeleteDate DATETIME=DATEADD(hour,-36,getdate());
EXECUTE master.dbo.xp_delete_file 0,N'J:\Datamart',N'trn',@DeleteDate,1;
DECLARE @filename varchar(100);
SET @filename = 'J:\Datamart\Datamart_'+convert(varchar(11),getDate(),112) + convert(varchar(5),getDate(),108) + '.bak';
IF (sys.fn_hadr_backup_is_preferred_replica('Datamart')=0) BEGIN
      Select 'This is not the preferred replica, exiting with success';
END ELSE
BACKUP LOG Datamart TO DISK=@filename ;
 
 
--Ola Hallegren backups:
Set @CopyOnly='Y' on all replicas
https://www.brentozar.com/archive/2015/06/how-to-configure-alwayson-ag-backups-with-ola-hallengrens-scripts/



--***********backups on DAGs*****************************************************************************************
BACKUP DATABASE supports copy-only full backups of databases, files, or filegroups when it's executed on secondary replicas. 
Copy-only backups don't impact the log chain or clear the differential bitmap.

Differential backups aren't supported on secondary replicas.

Concurrent backups, such as executing a transaction log backup on the primary replica while a full database backup is executing on the 
secondary replica, is currently not supported.

BACKUP LOG supports only regular log backups (the COPY_ONLY option is not supported for log backups on secondary replicas).

A consistent log chain is ensured across log backups taken on any of the replicas (primary or secondary), irrespective of their availability mode
(synchronous-commit or asynchronous-commit).

To back up a secondary database, a secondary replica must be able to communicate with the primary replica and must be SYNCHRONIZED or SYNCHRONIZING.
https://learn.microsoft.com/en-us/sql/database-engine/availability-groups/windows/active-secondaries-backup-on-secondary-replicas-always-on-availability-groups?view=sql-server-ver15

--copy_only log backups do not work
--this error will be thrown:  This BACKUP or RESTORE command is not supported on a database mirror or secondary replica

--transaction log backups are not supported on any secondary AG replicas except for the forwarder
--they can be taken on any replica of the primary AG or the primary replica of the secondary AG only
--the following error will be thrown:
--Log backup for database "DocusignAPILog" on secondary replica failed because the new backup information could not be committed on primary database


 --with a set up of AG1 and AG2 connected by DAG1, AG2 and AG3 connected by DAG2:
--Transaction log backups can be taken on the primary AG (all nodes) and on the forwarder without COPY_ONLY 


AG2:  
primary node: 
without COPY_ONLY:  log backup works 
with COPY_ONLY: This BACKUP or RESTORE command is not supported on a database mirror or secondary replica


AG3 (all nodes) & AG2 all secondary nodes: log backups are NOT supported AT ALL 
**Only replicas that communicate directly with the global primary replica can perform backup operations.
with COPY_ONLY: This BACKUP or RESTORE command is not supported on a database mirror or secondary replica
without COPY_ONLY:  Log backup for database "" on secondary replica failed because the new backup information 
could not be committed on primary database



*/
