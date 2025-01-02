/***********************TRANSPARENT DATA ENCRYPTION***************************************************
**there are 2 parts to this encryption script:
Performs real-time I/O encryption and decryption of the data and log files
Uses a Database Encryption Key (DEK), stored in the database boot record and secured by a certificate
stored in the master database or an assymetric key protected by an EKM module
TDE protects data at rest (data and log files), no encryption across communication channels
The certificate & private key will be needed to restore the database on a new server; 
retain these even if TDE gets turned off, it may be needed for some operations.
Backup files of a TDE enabled database are also encrypted using the DEK.

***************************************************************************************/
/***
The database master key is a symmetric key that is used to protect the private keys of certificates and asymmetric keys that are present in the database. 
It can also be used to encrypt data, but it has length limitations that make it less practical for data than using a symmetric key.
When it is created, the master key is encrypted by using the Triple DES algorithm and a user-supplied password. To enable the automatic decryption of the master key, 
a copy of the key is encrypted by using the service master key and stored in both the database when it is in use and in the master system database. 
Typically, the copy stored in the master db is silently updated whenever the database master key is changed. This default can be changed by using the 
DROP ENCRYPTION BY SERVICE MASTER KEY option of ALTER MASTER KEY. 
A master key that is not encrypted by the service master key must be opened by using the OPEN MASTER KEY statement and a password.

To encrypt a database using TDE (Transparent Database Encryption, at the file level), the certificate or asymmetric key that is used to encrypt the database
encryption key must be located in the master system database.

Database Master Key is created in the context of the master database and is used to create certificates used for database level encryption.

If I detach an encrypted database, I will need to open the master key encryption with password to re-attach it or restore it
*/
--check if databases have TDE turned on
SELECT DB_Name(database_id) As [DB Name], encryption_state, encryption_state_desc
FROM sys.dm_database_encryption_keys
GO
SELECT name, is_encrypted FROM sys.databases
Go

--turn off TDE:
ALTER DATABASE TDE_DB SET ENCRYPTION OFF;
-- then, drop the Database Encryption key
USE TDE_DB;
GO
DROP DATABASE ENCRYPTION KEY;
GO

--The is_master_key_encrypted_by_server column indicates whether the database master key exists & if is encrypted by the SMK:
select name, is_master_key_encrypted_by_server, is_encrypted from master.sys.databases;

--check if symmetric key exists:
SELECT * FROM master.sys.symmetric_keys;
SELECT * FROM sys.symmetric_keys;

--check existing certificates:
SELECT * FROM sys.certificates;

--create symmetric DMK (Database Master Key), protected by the Service Master Key (SMK) and a password
--SMK is created when SQL Server DB Engine is installed
USE Master;
IF NOT EXISTS 
    (SELECT * FROM sys.symmetric_keys WHERE symmetric_key_id = 101)
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Password123.' 
GO

--create a server level certificate that will be used by the database for encryption, encrypted using Database Master Key DMK
CREATE CERTIFICATE testEncryption  WITH SUBJECT = 'Encryption Test';  --using DMK (more secure than just encrypting by password)
GO

--OR:  encrypt using a password if a MASTER KEY is not going to be used:
CREATE CERTIFICATE testEncryption  ENCRYPTION BY PASSWORD='Password123.' WITH SUBJECT = 'Encryption Test';  --encrypt certificate by password instead of DMK
GO


--backup keys & certificates; if certificate is deleted and no backup exists, there will be no way of decrypting database files
--to restore the database on a new server, we can copy the SMK, DMK, and Certificate backups
USE Master;
GO
BACKUP SERVICE MASTER KEY TO FILE = 'C:\SMK.key' ENCRYPTION BY PASSWORD='Password123.';
GO
BACKUP MASTER KEY TO FILE = 'C:\DMK.key' ENCRYPTION BY PASSWORD='Password123.';
GO
BACKUP CERTIFICATE testEncryption TO FILE = 'C:\EncryptionCert.cert' WITH PRIVATE KEY (file='C:\EncryptionCert.key', ENCRYPTION BY PASSWORD='Password123.');
GO

--to restore on a new server with a new database backup cert*************************************************************
--1.  create a temporary backup cert on original server: (user password, MASTER KEY is not going to be used for encrypting the cert):
CREATE CERTIFICATE testEncryption  ENCRYPTION BY PASSWORD='Password123.' WITH SUBJECT = 'Encryption Test';
--2.  take a copy-only backup of the database encrypted with this backup cert:
BACKUP DATABASE test_db TO @backupPath WITH COPY_ONLY, ENCRYPTION (ALGORITHM = AES_256, SERVER CERTIFICATE = BackupCert);
--3.  create the same  cert on the new server and restore the database backup:
RESTORE DATABASE test_db FROM FILE


--to restore the master key:
RESTORE MASTER KEY FROM FILE='C:\DMK.key' DECRYPTION BY PASSWORD='Password123.'	ENCRYPTION BY PASSWORD='';
	GO

CREATE DATABASE TestEncryption;
GO
USE TestEncryption
GO
CREATE DATABASE ENCRYPTION KEY WITH ALGORITHM= AES_256 ENCRYPTION BY SERVER CERTIFICATE testEncryption;
GO
ALTER DATABASE testEncryption SET ENCRYPTION ON; 
GO;

--selecting from the database will not be affected, as long as the encryption certificate remains intact 


--database encryption key can be mapped to the certificate stored in the master database on the thumbrpint column
select d.name, key_algorithm, encryption_state_desc=
	CASE encryption_state	
		WHEN '0' THEN 'No Encryption'
		WHEN '1' THEN 'Unencrypted'
		WHEN '2' THEN 'Encryptin in Progress'
		WHEN '3' THEN 'Encrypted'
		WHEN '4' THEN 'Key change in progress'
		WHEN '5' THEN 'Decryption in progress'
		WHEN '6' THEN 'Protection change in progress'
		ELSE 'No Status' END
	from sys.dm_database_encryption_keys e 
LEFT JOIN master.sys.certificates c ON e.encryptor_thumbprint=c.thumbprint
inner join sys.databases d on d.database_id=e.database_id;

--view which databases are encrypted:
select name, is_encrypted from sys.databases;

--view encrypted objects:
SELECT object_name(id), encrypted FROM sys.syscomments GROUP BY encrypted;



SELECT sp.type, sp.type_desc, COUNT(smsp.definition) AS UnencryptedObjects -- only non-null or unencrypted objects will be counted
	 , COUNT(*)-COUNT(smsp.definition) AS EncryptedObjects, COUNT(*) AS Total
FROM sys.all_objects sp LEFT JOIN sys.sql_modules smsp  ON smsp.object_id = sp.object_id
WHERE sp.type IN ('FN', 'IF', 'V', 'TR', 'PC', 'TF', 'P') AND sp.is_ms_shipped = 0
GROUP BY sp.type, sp.type_desc


--to reset server encryption:
ALTER DATABASE TestEncryption SET ENCRYPTION OFF;  --check error log, database encryption scan will happen in the backgroud
DROP DATABASE ENCRYPTION KEY;
USE master
GO
DROP CERTIFICATE testEncryption;
DROP MASTER KEY;
--restoring encrypted database backup will not work now that the cert has been removed

--if using the same instance of SQL server, the Server Master Key does not need to be restored to get back the original encryption
--we can simply re-create the DMK using the same password as before 
 CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Password123.' 
--and restore the cert from file using the original password:
RESTORE CERTIFICATE testEncryption FROM FILE = 'C:\EncryptionCert.cert' WITH PRIVATE KEY (FILE='C:\EncryptionCert.key', DECRYPTION BY PASSWORD='Password123.');
--next, restore encrypted database backup


--to change the encryption algorithm of the database encryption key
USE CMS_Prod_App
GO
ALTER DATABASE ENCRYPTION KEY  REGENERATE WITH ALGORITHM = AES_256;  
/*  Will do a database encryption scan.  There will be an entry in the error log: 
Beginning database encryption scan for database 'CMS_Prod_App'.

*/


EXEC xp_readerrorlog 0,1,"encr",NULL,NULL,NULL,'desc'
sp_whoisactive

RESTORE FILELISTONLY FROM DISK = N'U:\Backups\PDX1CMSDBAHP\Fin_Data\FULL\PDX1CMSDBAHP_Fin_Data_FULL_20230518_233000.bak';

--Encrypt at the cell level (Column Level Encryption) ******************************************************************************************************************
Use TestEncryption
GO

--create a certificate either encrypted by password (or encrypted by database encryption key)
CREATE CERTIFICATE CustomerCert ENCRYPTION BY PASSWORD='Password123.'  WITH SUBJECT = 'Customer Table Encryption';  --encrypt certificate by password (less secure)
GO
--this will place the encryption certificate in the database, can be seen by expanding Security, then Certificates folder in Object Explorer

--to create a certificate encrypted with the database encryption key, first create a database master key:
CREATE MASTER KEY ENCRYPTION BY PASSWORD='Password123.';
GO
CREATE CERTIFICATE CustomerCertMKE  WITH SUBJECT = 'Customer Table Encryption by DMK';  --encrypt certificate by database master key

--view certificates:
SELECT * FROM sys.certificates;


--now that we have a certificate for encryption, create the symmetric key that will be used to encrypt/decrypt column:
CREATE SYMMETRIC KEY CustomerKey WITH ALGORITHM = AES_256 ENCRYPTION BY CERTIFICATE CustomerCertMKE;
--OR   encrypt with password:
CREATE SYMMETRIC KEY CustomerKey WITH ALGORITHM = AES_256 ENCRYPTION BY PASSWORD ='Password123';

GO

-- Create a column in which to store the encrypted data.
ALTER TABLE customers ADD CC_Encrypted varbinary(1500); 
GO
ALTER TABLE customers DROP COLUMN CC_Encrypted;

select * from customers;

-- Open the symmetric key with which to encrypt the data.
OPEN SYMMETRIC KEY CustomerKey DECRYPTION BY CERTIFICATE CustomerCert WITH PASSWORD='Password123.';
--OR
OPEN SYMMETRIC KEY CustomerKey DECRYPTION BY CERTIFICATE CustomerCertMKE;


-- Encrypt the value in column using the symmetric key, save the result in another column  
UPDATE customers SET CC_Encrypted = EncryptByKey(Key_GUID('CustomerKey'), CC);
GO

CLOSE SYMMETRIC KEY CustomerKey;

-- Verify the encryption.
-- First, open the symmetric key with which to decrypt the data.

OPEN SYMMETRIC KEY CustomerKey DECRYPTION BY CERTIFICATE MerchantCert WITH PASSWORD='Password123.';
GO

-- Now list the original card number, the encrypted card number,
-- and the decrypted ciphertext. If the decryption worked,
-- the original number will match the decrypted number.

SELECT cc, CC_Encrypted AS 'Encrypted CC', CONVERT(char,DecryptByKey(CC_Encrypted))AS 'Decrypted CC' FROM customers;
GO
SELECT * FROM customers;

--to remove encryption, first the encrypted data must be dropped, then the symmetric key, certificate, and master key in that order
DROP TABLE customers;

DROP SYMMETRIC KEY CustomerKey;
DROP CERTIFICATE CustomerCert;
DROP MASTER KEY;