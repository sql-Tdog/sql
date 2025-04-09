/**Encryption for select columns************
Always Encrypted is available in SQL Server 2016 and SQL Database. (Prior to SQL Server 2016 SP1, 
Always Encrypted was limited to the Enterprise Edition.)

Always Encrypted uses two types of keys: column encryption keys and column master keys. 
A column encryption key is used to encrypt data in an encrypted column. 
A column master key is a key-protecting key that encrypts one or more column encryption keys.

Column Master Keys must be stored in a trusted key store and the keys need to be accessible to applications that need to encrypt or decrypt data, and tools
for configuring Always Encrypted and managing Always Encrypted keys.
Local or Centralized Key Store?
Local Key Stores - can only be used by applications on computers that contain the local key store. In other words, you need to replicate the key store and key to 
each computer running your application. An example of a local key store is Windows Certificate Store. When using a local key store, you need to make sure that the 
key store exists on each machine hosting your application, and that the computer contains the column master keys your application needs to access data protected 
using Always Encrypted. When you provision a column master key for the first time, or when you change (rotate) the key, you need to make sure the key gets deployed 
to all machines hosting your application(s).
Centralized Key Stores - serve applications on multiple computers. An example of a centralized key store is Azure Key Vault. A centralized key store usually makes 
key management easier because you don't need to maintain multiple copies of your column master keys on multiple machines. You need to ensure that your applications 
are configured to connect to the centralized key store.

Always Encrypted keys and protected sensitive data are never revealed in plaintext to the server. Therefore, the Database Engine cannot be involved in key 
provisioning and perform data encryption or decryption operations and T-SQL cannot be used for this task. Use SSMS or PowerShell only.

There are four permissions for Always Encrypted:
ALTER ANY COLUMN MASTER KEY (Required to create and delete a column master key.)
ALTER ANY COLUMN ENCRYPTION KEY (Required to create and delete a column encryption key.)
VIEW ANY COLUMN MASTER KEY DEFINITION (Required to access and read the metadata of the column master keys to manage keys or query encrypted columns.)
VIEW ANY COLUMN ENCRYPTION KEY DEFINITION (Required to access and read the metadata of the column encryption key to manage keys or query encrypted columns.)

Selecting Deterministic or Randomized Encryption
Deterministic encryption always generates the same encrypted value for any given plain text value. Using deterministic encryption allows point lookups, 
equality joins, grouping and indexing on encrypted columns. However, but may also allow unauthorized users to guess information about encrypted values by 
examining patterns in the encrypted column, especially if there is a small set of possible encrypted values, such as True/False, or North/South/East/West region. 
Deterministic encryption must use a column collation with a binary2 sort order for character columns.

Randomized encryption uses a method that encrypts data in a less predictable manner. Randomized encryption is more secure, but prevents searching, grouping, indexing, 
and joining on encrypted columns

Steps to Configure Always Encrypted:
1. Provision encryption keys & configure encryption for columns using Always Encrypted Wizard in SSMS
2. Once keys are provisioned, other columns can be configured for encryption using transact SQL like below:

*/
CREATE COLUMN MASTER KEY MyCMK 
	WITH ( 
    KEY_STORE_PROVIDER_NAME = 'MSSQL_CERTIFICATE_STORE',
    KEY_PATH = 'Current User/Personal/f2260f28d909d21c642a3d8e0b45a830e79a1420' 
        ); 

CREATE COLUMN ENCRYPTION KEY MyCEK WITH VALUES (
    COLUMN_MASTER_KEY = MyCMK, ALGORITHM = 'RSA_OAEP',
    ENCRYPTED_VALUE = 0x01700000016C006F00630061006C006D0061006300680069006E0065002F006D0079002F003200660061006600640038003100320031003400340034006500620031006100320065003000360039003300340038006100350064003400300032003300380065006600620063006300610031006300284FC4316518CF3328A6D9304F65DD2CE387B79D95D077B4156E9ED8683FC0E09FA848275C685373228762B02DF2522AFF6D661782607B4A2275F2F922A5324B392C9D498E4ECFC61B79F0553EE8FB2E5A8635C4DBC0224D5A7F1B136C182DCDE32A00451F1A7AC6B4492067FD0FAC7D3D6F4AB7FC0E86614455DBB2AB37013E0A5B8B5089B180CA36D8B06CDB15E95A7D06E25AACB645D42C85B0B7EA2962BD3080B9A7CDB805C6279FE7DD6941E7EA4C2139E0D4101D8D7891076E70D433A214E82D9030CF1F40C503103075DEEB3D64537D15D244F503C2750CF940B71967F51095BFA51A85D2F764C78704CAB6F015EA87753355367C5C9F66E465C0C66BADEDFDF76FB7E5C21A0D89A2FCCA8595471F8918B1387E055FA0B816E74201CD5C50129D29C015895CD073925B6EA87CAF4A4FAF018C06A3856F5DFB724F42807543F777D82B809232B465D983E6F19DFB572BEA7B61C50154605452A891190FB5A0C4E464862CF5EFAD5E7D91F7D65AA1A78F688E69A1EB098AB42E95C674E234173CD7E0925541AD5AE7CED9A3D12FDFE6EB8EA4F8AAD2629D4F5A18BA3DDCC9CF7F352A892D4BEBDC4A1303F9C683DACD51A237E34B045EBE579A381E26B40DCFBF49EFFA6F65D17F37C6DBA54AA99A65D5573D4EB5BA038E024910A4D36B79A1D4E3C70349DADFF08FD8B4DEE77FDB57F01CB276ED5E676F1EC973154F86 
); 

CREATE TABLE Customers ( 
  CustName nvarchar(60)  
    COLLATE Latin1_General_BIN2 ENCRYPTED WITH (COLUMN_ENCRYPTION_KEY = MyCEK, 
    ENCRYPTION_TYPE = RANDOMIZED, 
    ALGORITHM = 'AEAD_AES_256_CBC_HMAC_SHA_256'),  
  SSN varchar(11)  
    COLLATE Latin1_General_BIN2 ENCRYPTED WITH (COLUMN_ENCRYPTION_KEY = MyCEK, 
    ENCRYPTION_TYPE = DETERMINISTIC , 
    ALGORITHM = 'AEAD_AES_256_CBC_HMAC_SHA_256'),  
  Age int NULL 
); 
GO 


--view column encryption keys
select * from sys.column_encryption_keys ;

--view column master keys:
select * from sys.column_master_keys;

--view encrypted objects:
SELECT object_name(id), encrypted FROM sys.syscomments WHERE encrypted<>0;

SELECT sp.type, sp.type_desc, COUNT(smsp.definition) AS UnencryptedObjects 
-- only non-null or unencrypted objects will be counted
	 , COUNT(*)-COUNT(smsp.definition) AS EncryptedObjects, COUNT(*) AS Total
FROM sys.all_objects sp LEFT JOIN sys.sql_modules smsp  ON smsp.object_id = sp.object_id
WHERE sp.type IN ('FN', 'IF', 'V', 'TR', 'PC', 'TF', 'P') AND sp.is_ms_shipped = 0
GROUP BY sp.type, sp.type_desc

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

/*to make opening the symmetric key work on the database in a secondary replica of an AG, 
the same SMK must be restored on the server by backing it up on the primary replica first
otherwise, the database master key will have to be opened each time using decryption by password:
*/
BACKUP SERVICE MASTER KEY TO FILE = 'C:\Temp\ServerKey.key'  ENCRYPTION BY PASSWORD = 'Sg89ekl%ddosihlkghEfdPOIh33dewGd'
RESTORE SERVICE MASTER KEY   FROM FILE = '\\w3pltsqltooli01\SQL\BackupCert\ServerKey.key'  DECRYPTION BY PASSWORD = 'Sg89ekl%ddosihlkghEfdPOIh33dewGd' FORCE
GO

--the force parameter will throw a message that all encrypted data will be deleted but it will not be
--if the DMK for the database is not encrypted with the SMK, there will be no effect on the data
--it needs to be encrypted with the SMK to allow opening of  symmetric key by certificate:
ALTER MASTER KEY ADD ENCRYPTION BY SERVICE MASTER KEY
GO
OPEN SYMMETRIC KEY BackupContainer_Key DECRYPTION BY CERTIFICATE BackupContainer;

SELECT name, is_master_key_encrypted_by_server FROM sys.databases



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

SELECT CC, CC_Encrypted AS 'Encrypted CC', CONVERT(char,DecryptByKey(CC_Encrypted))AS 'Decrypted CC' FROM customers;
GO
SELECT * FROM customers;

--to remove encryption, first the encrypted data must be dropped, then the symmetric key, certificate, and master key in that order
DROP TABLE customers;

DROP SYMMETRIC KEY CustomerKey;
DROP CERTIFICATE CustomerCert;
DROP MASTER KEY;