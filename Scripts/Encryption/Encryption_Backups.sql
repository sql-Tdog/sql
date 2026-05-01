--The is_master_key_encrypted_by_server column indicates whether the database master key is encrypted by the service master key:
select name, is_master_key_encrypted_by_server, is_encrypted from master.sys.databases;

--check if symmetric key exists:
SELECT * FROM master.sys.symmetric_keys;
SELECT * FROM sys.symmetric_keys;

--check existing certificates:
SELECT * FROM sys.certificates;

--backup the service master key
BACKUP SERVICE MASTER KEY TO FILE = 'E:\SQLServerServiceMasterKey.key' ENCRYPTION BY PASSWORD = ''; 
GO

--now, create the Database Master Key (DMK)
CREATE MASTER KEY ENCRYPTION BY PASSWORD = '';
GO

--backup master key
BACKUP MASTER KEY TO FILE = 'E:\SQLServerMasterKey.key' ENCRYPTION BY PASSWORD = '';
GO

--create the certificate encrypted with the DMK
CREATE CERTIFICATE Testdatabase_BackupEncryptionCert WITH SUBJECT ='';
GO

--backup certificate (the password of the private key is the public key of the certificate)
BACKUP CERTIFICATE Testdatabase_BackupEncryptionCert TO FILE = 'E:\SQLServerDatabaseBackupCert.cert' WITH PRIVATE KEY
    (FILE = 'E:\SQLServerDatabasePrivateKey.key', ENCRYPTION BY PASSWORD = 'a$tr0n9#!P@$$w0r2_f0rDBb@ckupEncryption');
GO

--now, take an encrypted backup:
BACKUP DATABASE databasename TO DISK = 'E:\SQLServerBackup\databasebackup.bak' WITH INIT, CHECKSUM, COMPRESSION, ENCRYPTION (ALGORITHM=AES_256,
	SERVER CERTIFICATE = Testdatabase_BackupEncryptionCert );


--restoring the database on the same instance is operated as usual since all the keys and the certificate are already registered with the master database


--*******************new server setup**********************************************************************************************
--restoring an ancrypted backup file on a different SQL instance requires restoring the backup 
--cert & private key

--on existing server:
USE Master;
GO
select * from sys.certificates;
BACKUP CERTIFICATE TDECert2 TO FILE = 'U:\Keys\TDECert2.cert' WITH PRIVATE KEY 
	(file='U:\Keys\TDECert2.key', ENCRYPTION BY PASSWORD='Password123.#');


--on new server:
CREATE CERTIFICATE TDECert2 FROM FILE = 'U:\Backup\TDECert2.cert' WITH PRIVATE KEY 
	(FILE='U:\Backup\TDECert2.key', DECRYPTION BY PASSWORD='Password123.#');
GO

/*if the database is configured in a DAG and full backups are taken in one AG and t-log 
backups are taken in the other AG and the backup certificates don't match, then restore
the backup certs from both AGs and both full backup and t-log backups can be restored on 
the new node */
