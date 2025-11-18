/**Script to configure database mirroring  
	operating mode: High Safety with automatic failover (synchronous)
	from http://www.sqlservercentral.com/articles/Database+Mirroring/72009/
	modified and added by Tatyanna Nikolaychuk, 1/7/2014


--**************SETUP********************************************
-- verify database uses the full recovery model
select name, recovery_model_desc from sys.databases

--*****CREATE CERTIFICATES FOR LOGIN***********************
--1.  On Principal Server:
USE master;

--use a different name for a new certificate because the current certificate cannot be dropped, it is associated with the mirroring endpoint
--it can be dropped after the new certificate gets associated with the mirroring endpoint

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'xxx';
GO
CREATE CERTIFICATE SQLPROD_cert2015 WITH SUBJECT = 'Principal certificate', EXPIRY_DATE='3/31/2020';
GO
ALTER ENDPOINT Mirroring  --OR CREATE ENDPOINT Mirroring
STATE = STARTED
AS TCP (LISTENER_PORT=5022, LISTENER_IP = ALL)
FOR DATABASE_MIRRORING (AUTHENTICATION = CERTIFICATE SQLPROD_cert2015, ENCRYPTION = REQUIRED ALGORITHM AES, ROLE = ALL);
GO
BACKUP CERTIFICATE SQLPROD_cert2015 TO FILE = 'C:\certs\SQLPROD_cert2015.cer';
GO

--2.  On Mirror Server Machine
USE master;
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Mn42477.#';
GO
CREATE CERTIFICATE SQLPRODM_cert2015 WITH SUBJECT = 'Mirror certificate', EXPIRY_DATE='3/31/2020';
GO
ALTER ENDPOINT Mirroring  --OR CREATE
STATE = STARTED
AS TCP (LISTENER_PORT=5022, LISTENER_IP = ALL)
FOR DATABASE_MIRRORING (AUTHENTICATION = CERTIFICATE SQLPRODM_cert2015, ENCRYPTION = REQUIRED ALGORITHM AES, ROLE = ALL);
GO
BACKUP CERTIFICATE SQLPRODM_cert2015 TO FILE = 'C:\certs\SQLPRODM_cert2015.cer';
GO

--3.  On Witness Server
USE master;
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Mn42477.$';
GO
CREATE CERTIFICATE SQLPRODW_cert2015 WITH SUBJECT = 'SQLPRODW certificate';
GO
ALTER ENDPOINT Mirroring
STATE = STARTED
AS TCP (LISTENER_PORT=5022, LISTENER_IP = ALL)
FOR DATABASE_MIRRORING (AUTHENTICATION = CERTIFICATE SQLPRODW_cert2015, ENCRYPTION = REQUIRED ALGORITHM AES, ROLE = WITNESS);
GO
BACKUP CERTIFICATE SQLPRODW_cert2015 TO FILE = 'C:/certs/SQLPRODW_cert2015.cer';
GO

--******CREATE LOGINS**************************************
--4. copy certificates from both mirror and witness servers to the principal server machine
--On Principal Server Machine, grant login permissions to Mirror & Witness Servers using their certificates:
CREATE LOGIN DBMirroringLogin WITH PASSWORD ='Mn42477.';
GO
CREATE USER DBMirroringLogin FOR LOGIN DBMirroringLogin;
GO
CREATE CERTIFICATE SQLPRODM_cert2015 AUTHORIZATION DBMirroringLogin FROM FILE = 'C:\certs\SQLPRODM_cert2015.cer'
GO
CREATE CERTIFICATE SQLPRODW_cert2015 AUTHORIZATION DBMirroringLogin FROM FILE = 'C:\certs\SQLPRODW_cert2015.cer'
GO
GRANT CONNECT ON ENDPOINT:: Mirroring TO [DBMirroringLogin];
GO

--5. copy certificates from both principal and witness servers to the mirror server machine
--On Mirror Server Machine, grant login permissions to Principal & Witness Servers using their certificates:
CREATE LOGIN DBMirroringLogin WITH PASSWORD ='xxx';
GO
CREATE USER DBMirroringLogin FOR LOGIN DBMirroringLogin;
GO
CREATE CERTIFICATE SQLPROD_cert2015 AUTHORIZATION DBMirroringLogin FROM FILE = 'C:\certs\SQLPROD_cert2015.cer'
GO
CREATE CERTIFICATE SQLPRODW_cert2015 AUTHORIZATION DBMirroringLogin FROM FILE = 'C:\certs\SQLPRODW_cert2015.cer'
GO
GRANT CONNECT ON ENDPOINT:: Mirroring TO [DBMirroringLogin];
GO

--6. copy certificates from both principal and mirror servers to the witness server machine
--On Witness Server Machine, grant login permissions to Principal & Mirror Servers using their certificates:
CREATE LOGIN DBMirroringLogin WITH PASSWORD ='xxx';
GO
CREATE USER DBMirroringLogin FOR LOGIN DBMirroringLogin;
GO
CREATE CERTIFICATE SQLPROD_cert2015 AUTHORIZATION DBMirroringLogin FROM FILE = 'C:\certs\SQLPROD_cert2015.cer'
GO
CREATE CERTIFICATE SQLPRODM_cert2015 AUTHORIZATION DBMirroringLogin FROM FILE = 'C:\certs\SQLPRODM_cert2015.cer'
GO
GRANT CONNECT ON ENDPOINT:: Mirroring TO [DBMirroringLogin];
GO


--**************TAKE BACKUPS*************************************************
1. On principal:  Take a full backup of each database that will be configured with mirroring, then take a transaction log backup of each of those databases
2. On witness server: restore full backup of databases from principal server db backup files with NORECOVERY option, leaving db in restoring state
		then, restore transaction log backup files from principal server with NO RECOVERY

--************SET ENDPOINTS**************************************************
--From the mirror server set the endpoint to reference the principal server (if mirroring is done over a non-standard port, replace 5022 with the port we are using)
ALTER DATABASE NavigatorsGrant SET PARTNER='TCP://HBEXSQLPROD:5022'
GO

--from the principal server:
ALTER DATABASE NavigatorsGrant SET PARTNER='TCP://HBEXSQLPRODM:5022'
GO

ALTER DATABASE NavigatorsGrant SET WITNESS='TCP://HBEXSQLW:5022'
GO

/**database mirroring is now configured. 
The principal and mirror servers have been configured, and are synchronizing according to the configured safety mode, 
full (this is the default). If the witness server is configured, the database is capable of automatic failover. 
**/

/**script to automatically failover back to principal server if we failed over to mirror


--As long as we have a database with 'principal' mirroring role,
--keep checking if principal server is available again and failover all databases back to the principal server

WHILE (SELECT count(database_id) FROM sys.database_mirroring where mirroring_role=1)>0 BEGIN
	--wait for 30 seconds
	WAITFOR DELAY '00:00.30'
	
	DECLARE @stmt nvarchar(200);
	--check if principal server is available:
	If (Select count(database_id) From sys.database_mirroring 
			Where mirroring_state = 4 --synchronized
			) >0
	  Begin
		--manually fail over database to principal server
		 SELECT @stmt = 'Alter Database ' + quotename(db_name(database_id)) + ' Set Partner Failover;'
			FROM sys.database_mirroring WHERE mirroring_role=1 AND mirroring_state=4;
		 --Exec sp_executesql @SQL;
		 SELECT @stmt;
	  End
END
*/


/************************TROUBLESHOOTING*******************************/
--get current LSN of database
select db_id('ipas')
Select * from sys.master_files where database_id = db_id('ipas') and type = 0

--if database state is principal, disconnnected, in recovery; end mirroring to recover database
ALTER ENDPOINT Mirroring STATE=STOPPED


ALTER ENDPOINT Mirroring STATE=STARTED


--if database state is principal, suspended; mirroring has been paused, resume mirroring:
ALTER DATABASE CLCAApplicationPortal SET PARTNER RESUME

