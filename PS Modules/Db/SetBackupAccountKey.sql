SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO

RAISERROR(N'  + Deploying stored procedure [dbo.SetBackupAccountKey]', 0, 0) WITH NOWAIT;

IF      OBJECT_ID(N'dbo.SetBackupAccountKey', 'P') IS NULL
BEGIN
        EXEC sys.sp_executesql N'CREATE PROCEDURE dbo.SetBackupAccountKey AS SELECT 1;';
END
GO

ALTER PROCEDURE [dbo].[SetBackupAccountKey]
        @ServerInstance NVARCHAR(128),
        @AccountKey NVARCHAR(MAX),
        @StorageAccountName NVARCHAR(150),

        @ModifiedBy NVARCHAR(36) = NULL,
        @ModifiedOn DATETIMEOFFSET(7) = NULL
AS
BEGIN
        IF      @ModifiedBy IS NULL
        BEGIN
                SET     @ModifiedBy = ORIGINAL_LOGIN();
        END
        IF      @ModifiedOn IS NULL
        BEGIN
                SET     @ModifiedOn = SYSDATETIMEOFFSET();
        END

        OPEN SYMMETRIC KEY BackupContainer_Key DECRYPTION BY CERTIFICATE BackupContainer;
        DECLARE @key VARBINARY(1024) = ENCRYPTBYKEY(Key_GUID('BackupContainer_Key'), @AccountKey)

        MERGE
        INTO    dbo.BackupContainerKey o
        USING   (
                SELECT  @ServerInstance AS ServerInstance,
                        @key AS AccountKey,
                        @StorageAccountName AS StorageAccountName

                ) i
        ON      i.ServerInstance = o.BackupGroupName
        WHEN    MATCHED
        THEN    UPDATE
                SET     o.StorageAccountKey_Encrypted = i.AccountKey,
                        o.StorageAccountName = i.StorageAccountName,

                        o.ModifiedBy = @ModifiedBy,
                        o.ModifiedOn = @ModifiedOn
        WHEN    NOT MATCHED
        THEN    INSERT (BackupGroupName,StorageAccountKey_Encrypted,CreatedBy,CreatedOn,ModifiedBy,ModifiedOn)
                VALUES (i.ServerInstance, i.AccountKey, @ModifiedBy, @ModifiedOn, @ModifiedBy, @ModifiedOn)
        ;
        CLOSE SYMMETRIC KEY BackupContainer_Key;
END
GO