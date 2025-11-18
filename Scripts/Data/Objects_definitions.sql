/**see view definitions**/
EXEC sp_helptext vDataDumpBase

EXEC sp_helptext @objname='';

EXEC sp_helpindex FctClaims

SELECT TABLE_NAME as ViewName,
VIEW_DEFINITION as ViewDefinition
FROM INFORMATION_SCHEMA.Views



--users:  need the following permissions to see the VIEW_DEFINITION column:
GRANT SELECT ON SCHEMA::INFORMATION_SCHEMA TO [DOMAIN\USER];
GRANT VIEW DEFINITION TO [DOMAIN\USER];

/**find what objects reference a certain table **/
SELECT * FROM sys.dm_sql_referencing_entities('dbo.HbexOrganization', 'OBJECT')

