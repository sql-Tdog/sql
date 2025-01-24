/***

--view users and all the possible roles they have without looking at each item's security level
--since each report could technically have unique permissions instead of them being inherited

SELECT DISTINCT U.UserName, R.RoleName
FROM Users U INNER JOIN  PolicyUserRole P ON P.UserId=U.UserID INNER JOIN Roles R On R.RoleId=P.RoleId


--now, view each user's role for each item
SELECT  
	CASE C.Type WHEN 1 THEN 'Folder'
		WHEN 2 THEN 'Report'
		WHEN 3 THEN 'Resources'
		WHEN 4 THEN 'Linked Report'
		WHEN 5 THEN 'Data Source'
		WHEN 6 THEN 'Report Model'
		WHEN 7 THEN 'Report Park'
		WHEN 8 THEN 'Shared Dataset'
	END [Type Item],  C.Name, U.UserName, R.RoleName
FROM Users U INNER JOIN  PolicyUserRole P ON P.UserId=U.UserID INNER JOIN Roles R On R.RoleId=P.RoleId
	INNER JOIN Catalog C ON C.PolicyId=P.PolicyID
	WHERE C.Name<>''


--get a list of all users and the last time they ran a report:

Select DISTINCT E.UserName, E2.TimeEnd from ExecutionLog E with (nolock)  
	CROSS APPLY (SELECT TOP 1 TimeEnd FROM ExecutionLog WHERE UserName=E.Username ORDER BY TimeEnd DESC) E2
	ORDER BY E2.TimeEnd 

*/
--for new installs, starting with SQL 2019, permission requirements are different
--grant the following to the SSRS service account:
USE ReportServer
GO
GRANT EXECUTE ON SCHEMA::sys TO [NT SERVICE\SQLServerReportingServices]

USE msdb
GO
GRANT EXECUTE ON SCHEMA::dbo TO [NT SERVICE\SQLServerReportingServices]
GRANT SELECT ON SCHEMA::dbo TO [NT SERVICE\SQLServerReportingServices]

use master
go
GRANT EXECUTE ON master.dbo.xp_sqlagent_notify TO RSExecRole
GO
GRANT EXECUTE ON master.dbo.xp_sqlagent_enum_jobs TO RSExecRole
GO



