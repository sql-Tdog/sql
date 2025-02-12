/***IMPORTANT*************************************************************
restoring SSISDB across environments will cause the SSISDB catalog to point to the Master servers of the original source 
it's better to recreate the SSISDB from scratch or restore it from an older backup file of the current environment if something went missing

I restored SSISDB to an older backup file on Staging and all of the symmetric encryption keys that were gone, were restored successfully;
there was no need to restore the master key either because I was not doing a refresh on a new/different server

*/


backup database ssisdb to disk = 'U:\backup\ssisdb_20230816.bak'

use SSISDB
go
backup master key to file ='U:\backup\SSISEncrptKey' encryption by password = 'Password123.#';

--on primary replica:
alter availability group p1bngimc1sag remove database SSISDB;
GO
alter database ssisdb set multi_user with rollback immediate;
drop database SSISDB


--when SSISDB is in an AG, make sure every replica has the same service master key to make failovers seamless
--otherwise, SSISDB will thrown an error that you need to open the master key
---- On Primary replica 
USE Master;
GO
BACKUP SERVICE MASTER KEY TO FILE = 'U:\Backup\SMK.key' ENCRYPTION BY PASSWORD='Password123.#';
GO
USE SSISDB
GO
BACKUP MASTER KEY TO FILE = 'U:\Backup\DMK.key' ENCRYPTION BY PASSWORD='Password123.#';

---- On Secondary replica 
RESTORE SERVICE MASTER KEY FROM FILE ='U:\Keys\SMK.key' DECRYPTION BY PASSWORD ='Password123.#';
GO
RESTORE MASTER KEY FROM FILE='U:\Keys\DMK.key' DECRYPTION BY PASSWORD='Password123.#' ENCRYPTION BY PASSWORD='Turbul3ntPhras3!&';
GO
OPEN MASTER KEY DECRYPTION BY PASSWORD='Turbul3ntPhras3!&';
ALTER MASTER KEY ADD ENCRYPTION BY SERVICE MASTER KEY;  --encrypt MK by SMK so that opening the MK by password is not needed every time database is altered


RESTORE MASTER KEY FROM FILE='U:\Backup\DMK.key' DECRYPTION BY PASSWORD='Password123.#'	ENCRYPTION BY PASSWORD='Turbul3ntPhras3!&';




restore database SSISDB FROM DISK='U:\backup\p1bngimc1sfc$p1bngimc1sag\SSISDB\FULL\p1bngimc1sfc$p1bngimc1sag_SSISDB_FULL_20230810_150013.bak'
	with replace;
RESTORE MASTER KEY FROM FILE='U:\Backup\DMK.key' DECRYPTION BY PASSWORD='Password123.#'	ENCRYPTION BY PASSWORD='Turbul3ntPhras3!&';


--if restoring the database to a SQL Server instance where the catalog was never created, enable CLR:
USE SSISDB
EXEC sp_configure 'clr enabled', 1
RECONFIGURE

use master
go
ALTER DATABASE SSISDB SET TRUSTWORTHY ON;

ALTER AUTHORIZATION ON database::SSISDB TO glassbreak

--may need to follow additional steps listed here: 
https://techcommunity.microsoft.com/t5/sql-server-integration-services/ssis-catalog-backup-and-restore/ba-p/388058
--such as creating an asymmetric key and unsafe assembly loading principal that SSISDB database depends on
--The login is used only for granting permission and hence does not have to be mapped to a database user.
USE MASTER
CREATE ASYMMETRIC KEY MS_SQLEnableSystemAssemblyLoadingKey FROM EXECUTABLE FILE = 'C:\Program Files\Microsoft SQL Server\110\DTS\Binn\ISServerExec.exe'
CREATE LOGIN MS_SQLEnableSystemAssemblyLoadingUser FROM ASYMMETRIC KEY MS_SQLEnableSystemAssemblyLoadingKey
GRANT UNSAFE ASSEMBLY TO MS_SQLEnableSystemAssemblyLoadingUser


:CONNECT P1BNGIMN1S02
DROP DATABASE SSISDB


alter availability group p1bngimc1sag add database SSISDB;
