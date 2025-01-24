/***** find triggers in a database *************/
use gpas
GO
select TR.name as 'Trigger', TR.create_date, TR.modify_date, T.name AS 'Table Name' from sys.triggers TR
inner join sys.tables T ON t.object_id=TR.parent_id


/**LOGON triggers:
--check for any logon triggers:
SELECT *, object_definition(object_id) FROM sys.server_triggers;

select APP_NAME();
select ORIGINAL_LOGIN();
sp_whoisactive


SELECT * FROM APP_ADMIN.dbo.[User_LastLogin];

--p-biodswin01:  (exclude SSRS Server IP first)
ALTER TRIGGER trg_ServerLogonAudit ON ALL SERVER WITH EXECUTE AS 'sa' FOR LOGON AS   
	DECLARE @IP Varchar(500);
	SET @IP = EVENTDATA().value('(/EVENT_INSTANCE/ClientHost)[1]', 'varchar(50)');
	IF @IP NOT IN ('10.6.242.165') BEGIN
		IF (select role_desc
			from sys.dm_hadr_database_replica_states dr inner join sys.availability_replicas ar on ar.replica_id=dr.replica_id
			inner join sys.availability_databases_cluster dc on dc.group_database_id=dr.group_database_id
			inner join sys.dm_hadr_availability_replica_states rs on rs.replica_id=ar.replica_id
			WHERE database_name='APP_ADMIN' AND replica_server_name=@@SERVERNAME)='PRIMARY' BEGIN
				IF NOT EXISTS (SELECT UserName FROM APP_ADMIN.dbo.[User_LastLogin] WHERE UserName=ORIGINAL_LOGIN()) 
					INSERT INTO APP_ADMIN.dbo.[User_LastLogin] (UserName, LastLogon, ip) SELECT ORIGINAL_LOGIN(), GetDate(), @ip;
				ELSE UPDATE APP_ADMIN.dbo.[User_LastLogin] SET LastLogon=getDate(), ip=@ip WHERE UserName=ORIGINAL_LOGIN()
	END 
	IF APP_NAME() LIKE ('%Microsoft Office%') BEGIN
		IF ORIGINAL_LOGIN() NOT IN ('SSRS_User', 'CENTENE\REPORTS') 
			BEGIN
				ROLLBACK
			END    
	END
END	

--p-biodswin02:	
ALTER TRIGGER trg_ServerLogonAudit ON ALL SERVER WITH EXECUTE AS 'sa' FOR LOGON AS   
	DECLARE @IP Varchar(500);
	SET @IP = EVENTDATA().value('(/EVENT_INSTANCE/ClientHost)[1]', 'varchar(50)');
	IF @IP NOT IN ('10.6.242.165') BEGIN
		IF NOT EXISTS (SELECT UserName FROM APP_ADMIN.dbo.[User_LastLogin] WHERE UserName=ORIGINAL_LOGIN()) 
			INSERT INTO APP_ADMIN.dbo.[User_LastLogin] (UserName, LastLogon, ip) SELECT ORIGINAL_LOGIN(), GetDate(), @ip;
		ELSE UPDATE APP_ADMIN.dbo.[User_LastLogin] SET LastLogon=getDate(), ip=@ip WHERE UserName=ORIGINAL_LOGIN()
	END 
	IF APP_NAME() LIKE ('%Microsoft Office%') BEGIN
		IF ORIGINAL_LOGIN() NOT IN ('CENTENE\BRLONG', 'CENTENE\ERX_MED_D_REPORTING','SSRS_User') 
			BEGIN
				ROLLBACK
			END    
	END
		   
--for specific account:
CREATE TRIGGER sa_limitfailedattempts ON ALL SERVER WITH EXECUTE AS 'sa'
FOR LOGON AS BEGIN
	declare @data XML;
	declare @hostname varchar(150), @user varchar(150), @IPAddress varchar(15);
	SET @data=EVENTDATA();
	SET @user=@data.value('(/EVENT_INSTANCE/LoginName)[1]','nvarchar(150)');
	set @IPAddress = @data.value('(/EVENT_INSTANCE/ClientHost)[1]', 'nvarchar(15)')
	set @HostName = Cast(Host_Name() as nvarchar(64));

	IF ORIGINAL_LOGIN()= 'sa' AND @HostName<>'T-BIODSWIN01'
		ROLLBACK;
END;



--drop server trigger:
DROP TRIGGER  trg_ServerLogonAudit ON ALL SERVER;

*/

/***drop all triggers:

select TR.name as 'Trigger'
INTO #triggers
from sys.triggers TR
inner join sys.tables T ON t.object_id=TR.parent_id

ALTER TABLE #triggers ADD rowid INT IDENTITY PRIMARY KEY

BEGIN TRANSACTION


DECLARE @count int, @stmt nvarchar(500), @i int=1;
SET @count=(SELECT count([trigger]) from #triggers);

WHILE @i<2 BEGIN
	SET @stmt='DROP TRIGGER '+ (SELECT [trigger] FROM #triggers WHERE rowid=@i);
	SELECT @stmt;
	EXEC(@STMT);

	SET @i=@i+1;
END 



SELECT @@TRANCOUNT

ROLLBACK TRANSACTION  --OR COMMIT TRANSACTION


*/

/*******Database Triggers*******************************************
--in the database context:
SELECT m.definition, * FROM sys.trigger_events TE 
JOIN sys.triggers T ON T.object_id=TE.object_id
INNER JOIN sys.sql_modules M ON M.object_id=T.object_id
WHERE t.parent_class=0


CREATE TRIGGER TR_ALTERTABLE ON DATABASE  FOR ALTER_TABLE  AS  BEGIN     INSERT INTO TableSchemaChanges  SELECT EVENTDATA(),GETDATE()     END
DROP  TRIGGER TR_ALTERTABLE ON DATABASE 


--if Extended Events data is used in a database trigger, the database will need to have the TRUSTWORTHY setting turned on
--may need to turn it on for msdb as well (test this)
USE master
GO
CREATE LOGIN [ServerStateViewer] WITH PASSWORD ='USscript#2.!@';
GRANT VIEW SERVER STATE TO [ServerStateViewer];

SELECT name,is_trustworthy_on FROM sys.databases

alter database auditdb set trustworthy Off;
alter database Analytics_Workspace set trustworthy ON;
alter database Acaria_Analytics set trustworthy ON;
alter database Staging_Acaria_Analytics set trustworthy ON;

use msdb
go

GRANT VIEW SERVER STATE TO ServerStateViewer;

CREATE TRIGGER DDLTrigger_SP_Audit    ON DATABASE 
	WITH EXECUTE AS 'ServerStateViewer'
    FOR CREATE_PROCEDURE, ALTER_PROCEDURE, DROP_PROCEDURE, ALTER_SCHEMA, RENAME
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE
        @EventData XML = EVENTDATA();
    DECLARE
        @ip VARCHAR(32) =
        (
            SELECT client_net_address
                FROM sys.dm_exec_connections
                WHERE session_id = @@SPID
        );
	EXECUTE AS CALLER
	DECLARE @user varchar(255)= SUSER_SNAME();
	REVERT;
    INSERT AuditDB.dbo.DDLEvents
    (
        EventType,
        EventDDL,
        EventXML,
        DatabaseName,
        SchemaName,
        ObjectName,
        HostName,
        IPAddress,
        ProgramName,
        LoginName
    )
    SELECT
        @EventData.value('(/EVENT_INSTANCE/EventType)[1]',   'NVARCHAR(100)'),
        @EventData.value('(/EVENT_INSTANCE/TSQLCommand)[1]', 'NVARCHAR(MAX)'),
        @EventData,
        DB_NAME(),
        @EventData.value('(/EVENT_INSTANCE/SchemaName)[1]',  'NVARCHAR(255)'),
        @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]',  'NVARCHAR(255)'),
        HOST_NAME(),
        @ip,
        PROGRAM_NAME(),
        @user;
END
GO



 */