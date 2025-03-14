SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO

RAISERROR(N'  + Deploying stored procedure [dbo.GetBackupAccountKey]', 0, 0) WITH NOWAIT;

IF      OBJECT_ID(N'dbo.GetBackupAccountKey', 'P') IS NULL
BEGIN
        EXEC sys.sp_executesql N'CREATE PROCEDURE dbo.GetBackupAccountKey AS SELECT 1;';
END
GO

ALTER PROCEDURE [dbo].[GetBackupAccountKey]
        @ServerInstance NVARCHAR(128)

AS
BEGIN

        OPEN SYMMETRIC KEY BackupContainer_Key DECRYPTION BY CERTIFICATE BackupContainer;

        SELECT StorageAccountName, CONVERT(nvarchar(max),DecryptByKey(StorageAccountKey_Encrypted))
        AS 'StorageAccountKey'
        FROM dbo.BackupContainerKey WHERE BackupGroupName = @ServerInstance


        CLOSE SYMMETRIC KEY BackupContainer_Key;
END
GO