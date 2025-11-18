SELECT 'ALTER SERVER ROLE ' + r.name + ' ADD MEMBER ['+ m.name +']' as STMT
FROM master.sys.server_role_members rm INNER JOIN master.sys.server_principals r 
	ON r.principal_id = rm.role_principal_id and r.type = 'R'
INNER JOIN master.sys.server_principals m ON m.principal_id = rm.member_principal_id
WHERE m.name NOT IN ('sa','NT Service\MSSQLSERVER','NT SERVICE\SQLWriter','NT SERVICE\Winmgmt',
	'NT AUTHORITY\SYSTEM','NT SERVICE\SQLSERVERAGENT') and m.is_disabled=0
ORDER BY m.name