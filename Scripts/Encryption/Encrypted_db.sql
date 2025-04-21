/************for a database in a SQL Availability Group*************************************
to prevent opening the symmetric key using a password on the database in a secondary replica of an AG, 
the SMK from the primary server must be restored on the secondary server 

*/
BACKUP SERVICE MASTER KEY TO FILE = 'C:\Temp\ServerKey.key'  ENCRYPTION BY PASSWORD = ''
RESTORE SERVICE MASTER KEY FROM FILE = '\\server\C$\Temp\ServerKey.key'  DECRYPTION BY PASSWORD = '' 
GO

--if restoring fails with 'The master key file does not exist or has invalid format.'
--make sure SQL server has access to the location from which the key is being restored
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
--restore SMKs on the secondaries, then create a new DMK and cert:
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'xxxxx'
CREATE CERTIFICATE BackupContainer WITH SUBJECT = 'Azure Backup Container'
GO
CREATE SYMMETRIC KEY BackupContainer_Key WITH ALGORITHM = AES_256
    ENCRYPTION BY CERTIFICATE BackupContainer;
ALTER MASTER KEY ADD ENCRYPTION BY SERVICE MASTER KEY

--if SMK cannot be restored because of an error, restart SQL server and try again
--it worked after a restart on one of the nodes
select is_master_key_encrypted_by_server , * from sys.databases

ALTER MASTER KEY ADD ENCRYPTION BY SERVICE MASTER KEY
GO
OPEN SYMMETRIC KEY BackupContainer_Key DECRYPTION BY CERTIFICATE BackupContainer;

SELECT name, is_master_key_encrypted_by_server FROM sys.databases
