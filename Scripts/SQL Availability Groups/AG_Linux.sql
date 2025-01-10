/***Linux Availability Group Set Up*******************************************************************
--SQL SERVER 2017******************************/
--there are 2 types of architectures for Availability Groups: read-scale and high availability
--high availability requries a cluster manager, read-scale does not

--to create a cluster that includes replicas hosted on different operating systems, an availability group
--with CLUSTER_TYPE=NONE is used on Linux OS

--First, install SQL Server on the Linux machine
--Then, ping each host that will be a node in the AG
--Enable AlwaysOn availability groups on the Linux server by setting hadr.hadrenabled to 1:
		sudo /opt/mssql/bin/mssql-conf set hadr.hadrenabled  1
		sudo systemctl restart mssql-server


--Enable extended events to monitor/troubleshoot health:
ALTER EVENT SESSION  AlwaysOn_health ON SERVER WITH (STARTUP_STATE=ON);
GO

--SQL Server service on Linux uses certificates to authenticate communication between the mirroring endpoints
select * from sys.certificates;
SELECT * FROM master.sys.symmetric_keys;
SELECT * FROM master.sys.symmetric_keys;


--Create a certificate on the primary instace:  (Windows machine)
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'EncrPass123#';
CREATE CERTIFICATE AG_certificate WITH SUBJECT = 'Availability Groups';
BACKUP CERTIFICATE AG_certificate
   TO FILE = 'E:\SQLData\AG_cert.cer'
   WITH PRIVATE KEY (
           FILE = 'E:\SQLData\AG_cert.pvk',
           ENCRYPTION BY PASSWORD = 'AGcertPass123#'
       );


DROP CERTIFICATE AG_certificate;
DROP MASTER KEY;

--RDP to Windows Server and copy the certificate & private key to the Linux server by using WINSCP
--move it /var/opt/mssql/data/
--give the mssql user access to the certificate:  chown mssql:mssql dbm_certificate.*
--now, create the certificate on the Linux server from the backup file:
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'EncrPass123#';
CREATE CERTIFICATE AG_certificate
    FROM FILE = '/var/opt/mssql/data/AG_cert.cer'
    WITH PRIVATE KEY (
    FILE = '/var/opt/mssql/data/AG_cert.pvk',
    DECRYPTION BY PASSWORD = 'AGcertPass123#'
            );

CREATE CERTIFICATE AG_certificate
    FROM FILE = 'H:\SQLData\AG_cert.cer'
    WITH PRIVATE KEY (
    FILE = 'H:\SQLData\AG_cert.pvk',
    DECRYPTION BY PASSWORD = 'AGcertPass123#'
            );


--The is_master_key_encrypted_by_server column indicates whether the database master key exists & if is encrypted by the SMK:
--it should be set to 1 for the master database:
select name, is_master_key_encrypted_by_server, is_encrypted from master.sys.databases;


--create database mirroring endpoints on all replicas:
select * from sys.endpoints;

CREATE ENDPOINT [Hadr_endpoint] AS TCP (LISTENER_PORT = 5022) FOR DATA_MIRRORING (
        ROLE = ALL,
        AUTHENTICATION = CERTIFICATE AG_certificate,
        ENCRYPTION = REQUIRED ALGORITHM AES
        );
ALTER ENDPOINT [Hadr_endpoint] STATE = STARTED;

--check if AlwaysOn Availability Groups feature is enabled:
SELECT SERVERPROPERTY ('IsHadrEnabled');  
--if it's not enabled, use the Configuration Manager or Powershell to enable it

--create the AG on the primary replica with CLUSTER_TYPE=NON and FAILOVER_MODE=MANUL
--SEEDING_MODE=AUTOMATIC causes SQL Server to automatically create the database on each secondary server after it is added to the AG
CREATE AVAILABILITY GROUP [AG_APP_ADMIN]
    WITH (CLUSTER_TYPE = NONE)
    FOR REPLICA ON
        N'erxdwssas1500' WITH (
            ENDPOINT_URL = N'tcp://erxdwssas1500:5022',
            AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,
            FAILOVER_MODE = MANUAL,
            SEEDING_MODE = AUTOMATIC,
                    SECONDARY_ROLE (ALLOW_CONNECTIONS = ALL)
            ),
        N'erxrxprsm1002' WITH ( 
            ENDPOINT_URL = N'tcp://erxrxprsm1002:5022', 
            AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,
            FAILOVER_MODE = MANUAL,
            SEEDING_MODE = AUTOMATIC,
            SECONDARY_ROLE (ALLOW_CONNECTIONS = ALL)
            );
ALTER AVAILABILITY GROUP [AG_APP_ADMIN] GRANT CREATE ANY DATABASE;

--on secondary, join to the group:
ALTER AVAILABILITY GROUP [AG_APP_ADMIN] JOIN WITH (CLUSTER_TYPE = NONE);
GO
ALTER AVAILABILITY GROUP [AG_APP_ADMIN] GRANT CREATE ANY DATABASE;


--create database on Windows machine (primary replica):
RESTORE DATABASE [APP_ADMIN]  FROM  DISK ='J:\APP_ADMIN.bak';
ALTER DATABASE APP_ADMIN SET COMPATIBILITY_LEVEL=140;

--make sure database is in FULL recovery mode:
SELECT name, recovery_model_desc FROM sys.databases where database_id=db_id('Datamart');

--take a full backup and a log backup of database on primary replica:
BACKUP DATABASE APP_ADMIN TO DISK = 'J:\APP_ADMIN.bak';
GO
BACKUP LOG APP_ADMIN TO DISK ='J:\APP_ADMIN.trn';
GO


--connect to secondary replicas and restore backups with no recovery option, then join to the AG group:
RESTORE FILELISTONLY   FROM  DISK = '/var/opt/mssql/data/APP_ADMIN.bak';

RESTORE DATABASE [APP_ADMIN]  FROM  DISK = '/var/opt/mssql/data/APP_ADMIN.bak' WITH NORECOVERY, MOVE 'APP_ADMIN' TO '/var/opt/mssql/data/APP_ADMIN.mdf',
	MOVE 'APP_ADMIN_log' TO  '/var/opt/mssql/data/APP_ADMIN.ldf';

RESTORE DATABASE [APP_ADMIN]  FROM  DISK = N'/var/opt/mssql/data/APP_ADMIN.trn' WITH NORECOVERY;
GO

--add a database to the group from the primary replica, it will automatically add the copy of the db on the secondary replica to the AG:
ALTER AVAILABILITY GROUP [AG_APP_ADMIN] ADD DATABASE APP_ADMIN;


ALTER AVAILABILITY GROUP [AG_APP_ADMIN] REMOVE DATABASE APP_ADMIN;

--If I try adding the database to the AG group on the primary replica w/out creating it on the secondary, it does not get created automatically on the secondary
--essentially, nothing happens if I don't do the file restore manually first

--drop database on Linux server since I cannot copy backup file from Linux to Windows (security)
--this command will also delete mdf and ldf files
DROP DATABASE APP_ADMIN;

--look at replicas and their roles:
select synchronization_health_desc,* from sys.dm_hadr_availability_replica_states

***/

--view replica details:
select rs.synchronization_health_desc, replica_server_name, database_name, role_desc, synchronization_state_desc, availability_mode_desc, failover_mode_desc,* 
from sys.dm_hadr_database_replica_states dr inner join sys.availability_replicas ar on ar.replica_id=dr.replica_id
inner join sys.availability_databases_cluster dc on dc.group_database_id=dr.group_database_id
inner join sys.dm_hadr_availability_replica_states rs on rs.replica_id=ar.replica_id


select replica_server_name, database_name, rs.synchronization_health_desc, log_send_queue_size, last_redone_time 
from sys.dm_hadr_database_replica_states dr inner join sys.availability_replicas ar on ar.replica_id=dr.replica_id
inner join sys.availability_databases_cluster dc on dc.group_database_id=dr.group_database_id
inner join sys.dm_hadr_availability_replica_states rs on rs.replica_id=ar.replica_id where log_send_queue_size IS NOT NULL;



/**
--since this is a read-scale set up (not high availability), I can failover manually only
--there are 2 options:  forced failover with data loss or without data loss (involves changed availability mode to synchronous commit first)

--to force failover with data loss, run the following command from the server that I want to be the primary:
--it will take a few seconds for the databases to become healthy again
ALTER AVAILABILITY GROUP [AG_APP_ADMIN] FORCE_FAILOVER_ALLOW_DATA_LOSS;

--if it does not become healthy, check to make sure both replicas don't think they are the primary
--if they do, force the target secondary to transition into its proper role:
ALTER AVAILABILITY GROUP [AG_APP_ADMIN]  SET (ROLE = SECONDARY);
ALTER DATABASE APP_ADMIN SET HADR RESUME;

--to force failover without data loss, connect to the target replica, & change the mode to synchronous commit:
ALTER AVAILABILITY GROUP AG_APP_ADMIN MODIFY REPLICA ON 'erxdwssas1500' WITH (AVAILABILITY_MODE = SYNCHRONOUS_COMMIT);
--now, the health of the replica should say NOT_HEALTHY, NOT SYNCHRONIZING; resume HADR manually:
ALTER DATABASE APP_ADMIN SET HADR RESUME;
--now connect to the primary and set its availability mode to SYNCHRONOUS as well:
ALTER AVAILABILITY GROUP AG_APP_ADMIN MODIFY REPLICA ON 'erxrxprsm1002' WITH (AVAILABILITY_MODE = SYNCHRONOUS_COMMIT);
--now, we can do the failover (connect to the target primary):
ALTER AVAILABILITY GROUP AG_APP_ADMIN FAILOVER; 
--this works perfectly when I fail over to the Windows server, but when trying to fail over back to the Linux server, I get an error:
Cannot failover an availability replica for availability group 'AG_APP_ADMIN' since it has CLUSTER_TYPE = NONE. Only force failover is supported in this version of SQL Server.
--so the only option is to force failover with data loss, but will make both replicas think they are primary


--**************************Errors**********************************************************
--if both replicas show as being primary for some reason, first try to transition the primary into a secondary role:
ALTER AVAILABILITY GROUP [AG_APP_ADMIN]  SET (ROLE = SECONDARY);

--if that doesn't work, then AGs need to be dropped & recreated on all replicas
--and AlwaysOn feature on all servers must be turned off and then back on again
DROP AVAILABILITY GROUP [AG_APP_ADMIN];


**/
