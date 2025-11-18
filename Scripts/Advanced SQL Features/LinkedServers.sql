/*
When you create a linked or remote server, SQL Server creates a default login mapping to the public server role. This means that by default, 
all logins can view all linked and remote servers. To restrict visibility to these servers, remove the default login mapping by executing 
sp_droplinkedsrvlogin and specifying NULL for the locallogin parameter.

If the default login mapping is deleted, only users that have been explicitly added as a linked login or remote login can view the linked 
or remote servers for which they have a login. To view all linked and remote servers after the default login mapping is deleted requires 
the following permissions:

ALTER ANY LINKED SERVER or ALTER ANY LOGIN ON SERVER
Membership in the setupadmin or sysadmin fixed server roles


*/
--check linked server default logins:
SELECT * FROM sys.linked_logins;

--remove the default login mapping originally created by executing sp_addlinkedserver:
EXEC sp_droplinkedsrvlogin 'servername', NULL

--To give users access to the OLEDB linked server:  
GRANT EXECUTE ON SYS.XP_PROP_OLEDB_PROVIDER TO Login


/*
In order to control the ability of users to run ad hoc queries using OPENROWSET, we must create an entry in the Registry 
for DisallowAdhocAccess and explicitly set it to 0.  In order to do this, open the properties of the provider and check 
DisallowAdhocAccess box.

*/

select * from openquery (INDUSTRYSMJU,'select * from measure_list')

USE master;  
GO  
EXEC sp_addlinkedserver   
    'SEATTLESales',  
    N'SQL Server';  
GO  
sp_testlinkedserver SEATTLESales;  
GO  
