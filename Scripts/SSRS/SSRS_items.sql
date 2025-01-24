USE ReportServer
GO
 
select C.UserName, D.RoleName, D.Description, E.Path, E.Name
from dbo.PolicyUserRole A
   inner join dbo.Policies B on A.PolicyID = B.PolicyID
   inner join dbo.Users C on A.UserID = C.UserID
   inner join dbo.Roles D on A.RoleID = D.RoleID
   inner join dbo.Catalog E on A.PolicyID = E.PolicyID
where c.username like '%testbi%' and path like '/accountin%'
order by C.UserName 
 
 
SELECT CASE
         WHEN C.Path = '' THEN 'Home'
         ELSE C.Path
       END    AS Path,
       C.Name AS ItemName,
       USR.UserName,
       RL.RoleName,
       CASE
         WHEN C.TYPE = 1 THEN 'Folder'
         WHEN C.TYPE = 2 THEN 'Report'
         WHEN C.TYPE = 3 THEN 'File'
         WHEN C.TYPE = 4 THEN 'LinkedReport'
         WHEN C.TYPE = 5 THEN 'DataSource'
         WHEN C.TYPE = 6 THEN 'Model'
         WHEN C.TYPE = 7 THEN 'ReportPart'
         WHEN C.TYPE = 8 THEN 'SharedDataset'
       END    AS ItemType FROM   Catalog C
       INNER JOIN Policies PL
               ON C.PolicyID = PL.PolicyID
       INNER JOIN PolicyUserRole PUR
               ON PUR.PolicyID = PL.PolicyID
       INNER JOIN Users USR
               ON PUR.UserID = USR.UserID
       INNER JOIN dbo.Roles RL
               ON RL.RoleID = PUR.RoleID WHERE C.type=1 and usr.username NOT LIKE '%centene%' AND usr.username NOT LIKE '%p-birpt1%' and usr.username NOT LIKE '%builtin%'
                     AND usr.username NOT LIKE 'usscript%'
ORDER  BY C.Path
 