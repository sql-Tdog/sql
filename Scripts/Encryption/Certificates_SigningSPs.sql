/*
Certificates are used to sign stored procedures when you want to require permissions on them without explicitly granting a user any rights.  
Although this can be accomplished using the EXECUTE AS statement, using a cert allows you to use a trace to find the original caller of the stored 
procedure and provides a high level of auditing, especially during security or DDL operations.

**Side note:  DDL Triggers cannot be digitally signed.  When create a trigger or stored proc with an EXECUTE AS statement, you can use EXECUTE AS CALLER 
to select the SUSER_NAME() and get the caller's info and then REVERT to switch back to impersonated context.


For server-level permissions, the cert must be created in the master db.  

For user database-level permissions, create the cert in the user db and then use it to sign stored procs.  A cert account must also be created and given access to 
execute the stored procs.
In the following example, a user with no rights to the CertTest db needs access to a stored proc only.  



use master
go
--set up a login for the test user:
CREATE LOGIN TestCertUser WITH PASSWORD='ASDECd2439587y'  
GO  

use CertTest
go
CREATE CERTIFICATE TestClaimAmtCert ENCRYPTION BY PASSWORD = 'pGFD4bb925DGvbd2439587y'  
      WITH SUBJECT = 'Credit Rating Records Access',  EXPIRY_DATE = '12/05/2019';  
GO  

--create and sign a stored proc:
CREATE PROCEDURE TestClaimAmtSP WITH EXECUTE AS OWNER
AS  
BEGIN  
   -- Show who is running the stored procedure  
   SELECT SYSTEM_USER 'system Login'  
   , USER AS 'Database Login'  
   , NAME AS 'Context'  
   , TYPE  
   , USAGE   
   FROM sys.user_token     

   -- Now get the data  
   SELECT TOP 50 claim_amt, tax_amt FROM MyTable
END  
GO  
ADD SIGNATURE TO TestClaimAmtSP   
   BY CERTIFICATE TestClaimAmtCert WITH PASSWORD = 'pGFD4bb925DGvbd2439587y';  
GO

--next, create a user that would have the ownership chain associated with the certificate
--this account has no server login & will grant access to the stored procs to the database account that has no access to the database tables
CREATE USER TestCertUserAccount FROM CERTIFICATE TestClaimAmtCert;

--grant the cert account database access rights:
REVOKE SELECT ON MyTable TO TestCertUserAccount;
GRANT EXECUTE ON TestClaimAmtSP TO TestCertUserAccount;

CREATE USER TestCertUser  FOR LOGIN TestCertUser;  
GO  
GRANT EXECUTE ON TestClaimAmtSP TO TestCertUser;

--test the cert account rights:
EXECUTE AS LOGIN='TestCertUser';
GO
EXECUTE CertTest.dbo.TestClaimAmtSP;

REVERT;
GO  
DROP PROCEDURE TestClaimAmtSP;  
GO  
DROP USER TestCertUserAccount;  
GO  
DROP USER TestCertUser;  
GO  
DROP LOGIN TestCertUser;  
GO  
DROP CERTIFICATE TestClaimAmtCert;  
GO  
*/