SELECT
  CASE type
  WHEN 'S' THEN 'CREATE USER ['+name+'] FOR LOGIN ['+SUSER_SNAME(sid)+'] WITH DEFAULT_SCHEMA=['+default_schema_name +']'
  WHEN 'U' THEN 'CREATE USER ['+name+'] FOR LOGIN ['+SUSER_SNAME(sid)+'] WITH DEFAULT_SCHEMA=['+default_schema_name +']'
  WHEN 'G' THEN 'CREATE USER ['+name+'] FOR LOGIN ['+SUSER_SNAME(sid)+']'
  WHEN 'A' THEN 'CREATE APPLICATION ROLE ['+name+'] WITH DEFAULT_SCHEMA=['+default_schema_name +'],PASSWORD=''TempPassword$'''
  WHEN 'R' THEN 'CREATE ROLE ['+name+'] AUTHORIZATION ['+USER_NAME(owning_principal_id)+']'
  END FROM sys.database_principals
WHERE type IN ('S','U','G','A','R') and name not like '##%' and name not in('sa','dbo','guest','sys','INFORMATION_SCHEMA','public')
AND is_fixed_role <> 1
ORDER BY type
--Script Users and Associated roles
SELECT
  'EXEC sp_addrolemember '''+USER_NAME(b.role_principal_id)+''',''' +a.name + ''''
FROM sys.database_principals a
LEFT OUTER JOIN sys.database_role_members b
ON a.principal_id=b.member_principal_id
WHERE a.sid NOT IN (0x01,0x00) AND a.sid IS NOT NULL
  AND a.type IN ('S','U','G','A','R') AND a.is_fixed_role <> 1 AND
  a.name NOT LIKE '##%' AND b.role_principal_id IS NOT NULL AND name not in ('dbo')
ORDER BY Name