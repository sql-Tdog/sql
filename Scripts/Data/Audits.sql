IF      SERVERPROPERTY('EngineEdition') IN (8,5)
BEGIN
        RAISERROR(N'  ~ Skipping audit [Audit-DDLChanges] because it is a Managed Instance or Azure SQL DB', 0, 0) WITH NOWAIT;
        RETURN
END

/* Define whether or not we want to drop the existing spec, which we would want to do if changing something */
DECLARE @DropExistingAuditSpec BIT = 1;

DECLARE @AuditFileTarget NVARCHAR(260);
/* Default the path to the same location as the default trace */
SELECT @AuditFileTarget = [path] FROM  sys.dm_os_server_diagnostics_log_configurations


DECLARE @ServerAuditCmd NVARCHAR(MAX);
/*
Create the server audit file.
Currently max 10 x 2GB files
*/
SELECT @ServerAuditCmd = N'CREATE SERVER AUDIT [Audit-DDLChanges]
TO FILE
(   FILEPATH = N'''+@AuditFileTarget+'''
    ,MAXSIZE = 200 MB
    ,MAX_ROLLOVER_FILES = 10
    ,RESERVE_DISK_SPACE = OFF
)
WITH
(   QUEUE_DELAY = 1000
    ,ON_FAILURE = CONTINUE
)
WHERE ([database_name]<>''tempdb'')
AND ([statement] NOT LIKE ''RESTORE LABELONLY%'')
AND ([Object_Name] <> ''EncryptionKeySymmetricKey'')
AND ([Object_Name] <> ''EncryptionKeyCertificate'')
AND ([statement] NOT LIKE ''select db_id() as database_id, COUNT_BIG(*) AS ColumnMasterKeyCount, key_st%'')
AND ([statement] NOT LIKE ''SELECT db_id() as database_id,%COUNT_BIG(DISTINCT(V.column_encryption%'')
AND ([statement] NOT LIKE ''SET IDENTITY_INSERT %'')
';


DECLARE @ServerAuditSpecCmd NVARCHAR(MAX);
/*
This is the server audit specification
*/
SELECT @ServerAuditSpecCmd = N'CREATE SERVER AUDIT SPECIFICATION [DDLAuditSpec]
FOR SERVER AUDIT [Audit-DDLChanges]
ADD (DATABASE_ROLE_MEMBER_CHANGE_GROUP),
ADD (DATABASE_OBJECT_PERMISSION_CHANGE_GROUP),
ADD (SCHEMA_OBJECT_PERMISSION_CHANGE_GROUP),
ADD (DATABASE_CHANGE_GROUP),
ADD (DATABASE_OBJECT_CHANGE_GROUP),
ADD (DATABASE_PRINCIPAL_CHANGE_GROUP),
ADD (SCHEMA_OBJECT_CHANGE_GROUP),
ADD (SCHEMA_OBJECT_OWNERSHIP_CHANGE_GROUP),
ADD (SERVER_ROLE_MEMBER_CHANGE_GROUP),
ADD (SERVER_PRINCIPAL_CHANGE_GROUP),
ADD (USER_CHANGE_PASSWORD_GROUP),
ADD (LOGIN_CHANGE_PASSWORD_GROUP),
ADD (DATABASE_OBJECT_OWNERSHIP_CHANGE_GROUP),
ADD (AUDIT_CHANGE_GROUP)
WITH (STATE = ON)';



BEGIN TRY

EXEC sys.sp_executesql N'IF EXISTS (SELECT * FROM sys.server_audits WHERE name = ''Audit-DDLChanges'' AND predicate NOT LIKE ''%IDENTITY_INSERT%'')
BEGIN
        ALTER SERVER AUDIT [Audit-DDLChanges] WITH (STATE = OFF)
        DROP SERVER AUDIT [Audit-DDLChanges]
END'

/* Create the audit if it does not exist */
IF NOT EXISTS (SELECT * FROM sys.server_audits WHERE name = 'Audit-DDLChanges')
    EXEC sys.sp_executesql @ServerAuditCmd;


/* Always ensure that the audit is started */
EXEC sys.sp_executesql N'ALTER SERVER AUDIT [Audit-DDLChanges] WITH (STATE = ON)'


/* Check the audit is running */
IF      NOT EXISTS (SELECT is_state_enabled FROM sys.server_audits WHERE name = 'Audit-DDLChanges' AND is_state_enabled = 1)
BEGIN
        RAISERROR(N'Audit-DDLChanges server audit is not started', 16, 1) WITH NOWAIT;
END


IF @DropExistingAuditSpec = 1
    BEGIN
        IF EXISTS (SELECT * FROM sys.server_audit_specifications WHERE name = 'DDLAuditSpec')
            BEGIN
                /* Stop the audit */
                EXEC sp_executeSQL N'ALTER SERVER AUDIT SPECIFICATION [DDLAuditSpec] WITH (STATE = OFF)';
                /* Delete the audit spec */
                EXEC sp_executeSQL N'DROP SERVER AUDIT SPECIFICATION [DDLAuditSpec]';
            END
    END

IF NOT EXISTS (SELECT * FROM sys.server_audit_specifications WHERE name = 'DDLAuditSpec')
    EXEC sp_executeSQL @ServerAuditSpecCmd;

/* Ensure that the spec is started */
EXEC sp_executeSQL N'ALTER SERVER AUDIT SPECIFICATION [DDLAuditSpec] WITH (STATE = ON)';

/* Check the audit spec is in place and enabled */
IF      NOT EXISTS (SELECT * FROM sys.server_audit_specifications WHERE name = 'DDLAuditSpec' AND is_state_enabled = 1 )
BEGIN
        RAISERROR(N'DDLAuditSpec server audit specification is not started', 16, 1) WITH NOWAIT;
END

RAISERROR (N'  + Deploying audit [DDLAuditSpec]', 0, 0) WITH NOWAIT;

END TRY
BEGIN CATCH
        ; THROW;
END CATCH