
--check the number of replicas under the Managed Instance:
--there should be 4 for business critical tier and 1 for general purpose
SELECT db_name(RS.database_id) DatabaseName, * 
FROM sys.dm_hadr_database_replica_states RS
INNER JOIN sys.dm_hadr_fabric_replica_states FRS ON RS.replica_id = FRS. replica_id 