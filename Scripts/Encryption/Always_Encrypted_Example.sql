SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO

RAISERROR(N'  + Deploying table [dbo.BackupContainerKey]', 0, 0) WITH NOWAIT;

IF NOT EXISTS ( SELECT  *
    FROM    sys.symmetric_keys
    WHERE   name LIKE '%DatabaseMasterKey%') BEGIN
        DECLARE @char CHAR = ''
        DECLARE @charI INT = 0
        DECLARE @password VARCHAR(100) = ''
        DECLARE @len INT = 20 -- Length of Password
        WHILE @len > 0
        BEGIN
            SET @charI = ROUND(RAND()*100,0)
            SET @char = CHAR(@charI)
            IF @charI > 48 AND @charI < 122
            BEGIN
                SET @password += @char
                SET @len = @len - 1
            END
        END
        DECLARE @stmt nvarchar(max)
        SET @stmt='CREATE MASTER KEY ENCRYPTION BY PASSWORD = ''' + @password + ''''
        EXECUTE sp_executesql @stmt
END

IF NOT EXISTS ( SELECT  *
    FROM    sys.certificates
    WHERE   name = 'BackupContainer') BEGIN
        CREATE CERTIFICATE BackupContainer WITH SUBJECT = 'Azure Backup Container'
END

IF NOT EXISTS ( SELECT * FROM sys.symmetric_keys WHERE name ='BackupContainer_Key' ) BEGIN
    CREATE SYMMETRIC KEY BackupContainer_Key WITH ALGORITHM = AES_256
    ENCRYPTION BY CERTIFICATE BackupContainer;
END

IF NOT EXISTS ( SELECT  *
                FROM    sys.tables
                WHERE   object_id = OBJECT_ID(N'dbo.BackupContainerKey', 'U') )
BEGIN
        CREATE TABLE dbo.BackupContainerKey (
                BackupGroupName NVARCHAR(128) NOT NULL,
                StorageAccountName NVARCHAR(1024) NULL,
                ResourceGroupName NVARCHAR(1024) NULL,
                UMIClientId NVARCHAR(1024) NULL,
                StorageAccountKey_Encrypted varbinary(1024) NULL,

                CreatedBy NVARCHAR(36) NOT NULL,
                CreatedOn DATETIMEOFFSET(7) NOT NULL,
                ModifiedBy NVARCHAR(36) NOT NULL,
                ModifiedOn DATETIMEOFFSET(7) NOT NULL,

                ValidFrom DATETIME2(7) GENERATED ALWAYS AS ROW START HIDDEN,
                ValidTo DATETIME2(7) GENERATED ALWAYS AS ROW END HIDDEN,
                PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo),

                CONSTRAINT PK_BackupGroupName PRIMARY KEY CLUSTERED (BackupGroupName) WITH (DATA_COMPRESSION = PAGE)
        ) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.BackupContainerKey_History));
END
GO

--Insert data into the table:
OPEN SYMMETRIC KEY BackupContainer_Key DECRYPTION BY CERTIFICATE BackupContainer;

DECLARE @VM varchar(100) = 'w3sqlseni01'
DECLARE @key varbinary(1024) = ENCRYPTBYKEY(Key_GUID('BackupContainer_Key'),'6ot2ru9QztwhCdyN3TIJiGNTmuh2nj5VNgtssQrdl98qBzoavFafOzk+YHjz1LRuw0Ed7KiRokCi+AStyFtEIQ==')
DECLARE @user varchar (100) =  ORIGINAL_LOGIN();
DECLARE @today datetime = getdate()

INSERT INTO dbo.BackupContainerKey (BackupGroupName,StorageAccountKey_Encrypted,CreatedBy,CreatedOn,ModifiedBy,ModifiedOn) VALUES (@VM,
@key,@user,@today,@user,@today)

SELECT CONVERT(nvarchar(max),DecryptByKey(StorageAccountKey_Encrypted))AS 'StorageAccountKey' 
FROM dbo.BackupContainerKey

CLOSE SYMMETRIC KEY BackupContainer_Key;

