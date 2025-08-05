--add a named replica:  (can specify a different database name from the primary replica)

ALTER DATABASE [WideWorldImporters]
ADD SECONDARY ON SERVER [contosoeast]
WITH (SERVICE_OBJECTIVE = 'HS_Gen5_2', SECONDARY_TYPE = Named, DATABASE_NAME = [WideWorldImporters_NamedReplica]);


--modify named replica:
ALTER DATABASE [WideWorldImporters_NamedReplica] MODIFY (SERVICE_OBJECTIVE = 'HS_Gen5_4')


--drop named replica:
DROP DATABASE [WideWorldImporters_NamedReplica];


--geo replica seeding:
SELECT  db.name as primary_database, 
    grl.start_date, grl.modify_date, grl.partner_server, grl.partner_database, 
    grl.replication_state_desc, grl.role_desc, grl.secondary_allow_connections_desc, grl.percent_copied
FROM sys.geo_replication_links grl INNER JOIN sys.databases db ON grl.database_id = db.database_id