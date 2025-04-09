/************for a database in a SQL Availability Group*************************************
to prevent opening the symmetric key using a password on the database in a secondary replica of an AG, 
the SMK from the primary server must be restored on the secondary server 

*/
BACKUP SERVICE MASTER KEY TO FILE = 'C:\Temp\ServerKey.key'  ENCRYPTION BY PASSWORD = ''
RESTORE SERVICE MASTER KEY FROM FILE = '\\server\SQL\BackupCert\ServerKey.key'  DECRYPTION BY PASSWORD = '' 
GO

/*
if the database is already in an AG and has a DMK but the servers were not set up with the same SMK,
use the force parameter on the secondaries to restore the SMK, it will throw an error that all 
encrypted data will be deleted but it will not be deleted if the DMK for the database is not encrypted 
with the SMK

*/

--***to redo encryption on a database that already has a DMK:
USE [db]
GO
select * from sys.symmetric_keys
select * from sys.certificates
--drop key and certs before restoring SMKs on the secondary AG nodes:
DROP SYMMETRIC KEY BackupContainer_Key
DROP CERTIFICATE backupcontainer
DROP MASTER KEY
GO
--restore SMKs on the secondaries, then:
CREATE CERTIFICATE BackupContainer FROM FILE = '\\w3pltsqltooli01\SQL\BackupCert\BackupContainer.cert' WITH PRIVATE KEY (
	FILE='\\w3pltsqltooli01\SQL\BackupCert\BackupContainer.key', DECRYPTION BY PASSWORD='Sg89ekl%ddosihlkghEfdPOIh33dewG');
GO
CREATE SYMMETRIC KEY BackupContainer_Key WITH ALGORITHM = AES_256
    ENCRYPTION BY CERTIFICATE BackupContainer;
ALTER MASTER KEY ADD ENCRYPTION BY SERVICE MASTER KEY

select is_master_key_encrypted_by_server , * from sys.databases

ALTER MASTER KEY ADD ENCRYPTION BY SERVICE MASTER KEY
GO
OPEN SYMMETRIC KEY BackupContainer_Key DECRYPTION BY CERTIFICATE BackupContainer;

SELECT name, is_master_key_encrypted_by_server FROM sys.databases
