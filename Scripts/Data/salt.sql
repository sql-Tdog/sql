/*********Export salted data from a table:
1.  Right click on database and select Tasks>Generate Scripts
2.  Select Specific Database Objects>Tables>EDWExport.ExportSalt>Next
3.  Select Advanced>Types of Data To Script>Data Only>Open in New Query Window>Finish
4.  Copy the script
5.  Connect to target database
6.  Paste the script 
7.  Insert
*/


--create a table with a 
CREATE TABLE dbo.[TestPass]
(
    UserID INT IDENTITY(1,1) NOT NULL,
    LoginName NVARCHAR(40) NOT NULL,
    PasswordHash BINARY(64) NOT NULL,
    FirstName NVARCHAR(40) NULL,
    LastName NVARCHAR(40) NULL,
    CONSTRAINT [PK_User_UserID] PRIMARY KEY CLUSTERED (UserID ASC)
)

GO

INSERT INTO dbo.TestPass VALUES ('testname',HASHBYTES('SHA2_512', 'password'),'Jane','Doe')

ALTER TABLE dbo.TestPass ADD Salt UNIQUEIDENTIFIER 

DECLARE @salt UNIQUEIDENTIFIER=NEWID()
INSERT INTO dbo.TestPass (LoginName, PasswordHash, Salt, FirstName, LastName)
VALUES('testname2', HASHBYTES('SHA2_512', 'password'+CAST(@salt AS NVARCHAR(36))), @salt, 'John', 'Doe')


SELECT * FROM dbo.TestPass

--authenticate users:
DECLARE @pPassword varchar(254)='password';
SELECT LoginName FROM [dbo].TestPass WHERE PasswordHash=
	HASHBYTES('SHA2_512', @pPassword+CAST(Salt AS NVARCHAR(36)))

  