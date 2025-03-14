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
--restoring an ancrypted backup file on a different SQL instance requires restoring 3 files:
--1.  restoring the server master key a& database master key from their backup files
--2.  creating the certificate from its backup file, which involves the private key file and the original encryption password


USE Master;
GO
BACKUP SERVICE MASTER KEY TO FILE = 'U:\K\SMK.key' ENCRYPTION BY PASSWORD='Password123.#';
GO
USE SSISDB
GO
BACKUP MASTER KEY TO FILE = 'U:\Backup\DMK.key' ENCRYPTION BY PASSWORD='Password123.#';
GO
select * from sys.certificates;
SELECT * FROM master.sys.symmetric_keys;
SELECT * FROM sys.symmetric_keys 
SELECT * FROM sys.credentials;

select * from sys.databases;
BACKUP CERTIFICATE TDECert2 TO FILE = 'U:\Keys\TDECert2.cert' WITH PRIVATE KEY (file='U:\Keys\TDECert2.key', ENCRYPTION BY PASSWORD='Password123.#');
BACKUP CERTIFICATE ServerCert_PDX1ONECMSDBCL TO FILE = 'U:\Keys\ServerCert_PDX1ONECMSDBCL.cert' WITH PRIVATE KEY 
	(file='U:\Keys\ServerCert_PDX1ONECMSDBCL.key'
	, ENCRYPTION BY PASSWORD='Password123.#');


RESTORE SERVICE MASTER KEY FROM FILE ='U:\Backup\SMK.key' DECRYPTION BY PASSWORD ='Password123.#';
GO
RESTORE MASTER KEY FROM FILE='U:\Backup\DMK.key' DECRYPTION BY PASSWORD='Password123.#'	ENCRYPTION BY PASSWORD='Turbul3ntPhras3!&';
GO
OPEN MASTER KEY DECRYPTION BY PASSWORD='Turbul3ntPhras3!&';
ALTER MASTER KEY ADD ENCRYPTION BY SERVICE MASTER KEY;

GO
CREATE CERTIFICATE TDECert2 FROM FILE = 'U:\Backup\TDECert2.cert' WITH PRIVATE KEY (FILE='U:\Backup\TDECert2.key', DECRYPTION BY 
	PASSWORD='Password123.#');
GO
--this cert is used to encrypt CMS_APP database backups:
CREATE CERTIFICATE ServerCert_PDX1ONECMSDBCL FROM FILE = 'U:\Backup\ServerCert_PDX1ONECMSDBCL.cert' WITH PRIVATE KEY 
(FILE='U:\Backup\ServerCert_PDX1ONECMSDBCL.key', DECRYPTION BY 	PASSWORD='Password123.#');
