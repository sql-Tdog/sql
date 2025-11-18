USE master 
GO
/**
SQL Server Agent proxies use credentials to store information about Windows user accounts.
A proxy allows non-admin users to perform tasks through SQL Server Agent jobs that require admin access.
Therefore, the credential should be a windows account with admin rights on the server.
**/

--First create a credential:
USE msdb ;
GO
CREATE CREDENTIAL AcariaCredential WITH IDENTITY = 'CORP\REPORTS', 
  SECRET = '######';
GO

--DROP CREDENTIAL dbaCredential;

--Now, create a proxy and assign credential:
EXEC dbo.sp_add_proxy
	@proxy_name='AcariaProxy',
	@enabled=1,
	@description='SQL Server Agent proxy account for Acaria Analytics Group',
	@credential_name='AcariaCredential';
GO

--DROP PROXY AcariaProxy;

--assign permissions to the proxy:
EXEC dbo.sp_grant_proxy_to_subsystem
	@proxy_name='AcariaProxy',
	@subsystem_id=11;

/*
2	Microsoft ActiveX Script
3	Operating System (CmdExec)
4	Replication Snapshot Agent
5	Replication Log Reader Agent
6	Replication Distribution Agent
7	Replication Merge Agent
8	Replication Queue Reader Agent
9	Analysis Services Query
10	Analysis Services Command
11	SSIS package execution
12	PowerShell Script

*/

--give users access to the proxy:
sp_grant_login_to_proxy 
	@login_name='CORP\LOGIN',
	@proxy_name='AcariaProxy';



/**Proxy for executing xp_cmdshell**************
use master
go
EXEC sp_xp_cmdshell_proxy_account 'CENTENE\SSRS_RPT_DLVRY_SVC','DomainAccountPassword';

--this proxy account will need access to the database and the drive where files will be dropped


GO
CREATE ROLE [CmdShell_Executor] AUTHORIZATION dbo;
GRANT EXECUTE ON xp_cmdshell TO [CmdShell_Executor];
GO
--add users to the role to give them access to rum xp_cmdshell commands
--every time this user will try to execute xp_cmdshell, the proxy account will be used

*/

