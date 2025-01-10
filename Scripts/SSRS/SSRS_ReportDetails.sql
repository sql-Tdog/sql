use ReportServer
GO
EXECUTE AS USER='CENTENE\TAWEST';
GO
SELECT SUSER_NAME(), USER_NAME();
GO
;WITH XMLNAMESPACES (
DEFAULT 'http://schemas.microsoft.com/sqlserver/reporting/2010/01/reportdefinition',
   'http://schemas.microsoft.com/SQLServer/reporting/reportdesigner' AS rd
)
SELECT
name,
x.value('CommandType[1]',  'VARCHAR(50)') AS CommandType,
x.value('CommandText[1]',  'VARCHAR(50)') AS CommandText,
x.value('DataSourceName[1]', 'VARCHAR(50)') AS DataSource
FROM (
select TOP 10
  name,
  CAST(CAST(content AS VARBINARY(MAX)) AS XML) AS reportXML
 from
  ReportServer.dbo.Catalog
where
  content is not null
  and type = 2
) a
CROSS APPLY reportXML.nodes('/Report/DataSets/DataSet/Query') r(x)
WHERE
x.value('CommandType[1]', 'VARCHAR(50)') = 'StoredProcedure'
ORDER BY
name
;
 