/**
--locate login:
select principal_id,name, type_desc, is_disabled
FROM sys.server_principals where type_desc IN('WINDOWS_LOGIN','SQL_LOGIN','SERVER_ROLE') 
AND name LIKE '%CN130563%';

--create a new login with windows authentication:
CREATE LOGIN [CENTENE\tnikolaychuk] FROM WINDOWS;
ALTER ROLE sysadmin ADD MEMBER [CENTENE\tnikolaychuk];

--create a new account with sql authentication:
CREATE LOGIN tnikolaychuk WITH PASSWORD='asdlkfhasd;kl';  --MUST_CHANGE


--create a database user from an existing login account:
CREATE USER [test] FROM LOGIN [test] WITH DEFAULT_SCHEMA=dbo;
--add user to a database role:
ALTER ROLE SQLAgentOperatorRole ADD MEMBER [test]


--unlock an account that was locked out:
ALTER LOGIN [sa] WITH CHECK_POLICY=OFF;
ALTER LOGIN [sa] WITH CHECK_POLICY=ON;
GO


--change password expiration for a login:
ALTER LOGIN [tnikolaychuk] WITH CHECK_EXPIRATION=OFF;

--create logon trigger:
CREATE TRIGGER sa_limitfailedattempts ON ALL SERVER WITH EXECUTE AS 'sa'
FOR LOGON
AS
BEGIN
declare @data XML;
declare @hostname varchar(150), @user varchar(150), @IPAddress varchar(15);
SET @data=EVENTDATA();
SET @user=@data.value('(/EVENT_INSTANCE/LoginName)[1]','nvarchar(150)');
set @IPAddress = @data.value('(/EVENT_INSTANCE/ClientHost)[1]', 'nvarchar(15)')
set @HostName = Cast(Host_Name() as nvarchar(64));

IF ORIGINAL_LOGIN()= 'sa' AND @HostName<>'RXDPBSSL01P'
	ROLLBACK;
END;

select * from sys.server_triggers;

DROP TRIGGER sa_limitfailedattempts ON ALL SERVER
*/
select * from sys.sysprocesses

select * from sys.server_triggers