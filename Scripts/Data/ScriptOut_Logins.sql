SET NOCOUNT ON

DECLARE
        @sql nvarchar(max)
,       @Line int = 1
,       @max int = 0
,       @@CurDB nvarchar(100) = ''

CREATE TABLE #SQL
       (
        Idx int IDENTITY
       ,xSQL nvarchar(max)
       )

INSERT INTO #SQL
        ( xSQL
        )
        SELECT
                'IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'''
                + QUOTENAME(name) + ''')
' + '	CREATE LOGIN ' + QUOTENAME(name) + ' WITH PASSWORD='
                + sys.fn_varbintohexstr(password_hash) + ' HASHED, SID='
                + sys.fn_varbintohexstr(sid) + ', ' + 'DEFAULT_DATABASE='
                + QUOTENAME(COALESCE(default_database_name , 'master'))
                + ', DEFAULT_LANGUAGE='
                + QUOTENAME(COALESCE(default_language_name , 'us_english'))
                + ', CHECK_EXPIRATION=' + CASE is_expiration_checked
                                            WHEN 1 THEN 'ON'
                                            ELSE 'OFF'
                                          END + ', CHECK_POLICY='
                + CASE is_policy_checked
                    WHEN 1 THEN 'ON'
                    ELSE 'OFF'
                  END + '
Go

'
           FROM
                sys.sql_logins
            WHERE
                name <> 'sa' AND name NOT LIKE '%##MS%' AND is_disabled=0

INSERT INTO #SQL
        ( xSQL
        )
        SELECT
                'IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'''
                + QUOTENAME(name) + ''')
' + '	CREATE LOGIN ' + QUOTENAME(name) + ' FROM WINDOWS WITH '
                + 'DEFAULT_DATABASE='
                + QUOTENAME(COALESCE(default_database_name , 'master'))
                + ', DEFAULT_LANGUAGE='
                + QUOTENAME(COALESCE(default_language_name , 'us_english'))
                + ';
Go

'
            FROM
                sys.server_principals
            WHERE
                type IN ( 'U' , 'G' )
                AND name NOT IN ( 'BUILTIN\Administrators' , 'NT AUTHORITY\SYSTEM' ) AND name NOT LIKE '%NT%SERVICE%'
				AND is_disabled=0;
                                  
PRINT '/*****************************************************************************************/'
PRINT '/*************************************** Create Logins ***********************************/'
PRINT '/*****************************************************************************************/'
SELECT
        @Max = MAX(idx)
    FROM
        #SQL 
WHILE @Line <= @max
      BEGIN



            SELECT
                    @sql = xSql
                FROM
                    #SQL AS s
                WHERE
                    idx = @Line
            PRINT @sql

            SET @line = @line + 1
        
      END
DROP TABLE #SQL