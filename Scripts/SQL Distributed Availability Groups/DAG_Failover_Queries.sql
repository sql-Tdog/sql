--verify SYNCHRONOUS_COMMIT on the primaries of the local availability groups that form the distributed availability group:
SELECT DISTINCT ag.name AS [Availability Group], ar.replica_server_name AS [Replica],
                ar.availability_mode_desc AS [Availability Mode]
FROM sys.availability_replicas AS ar 
     INNER JOIN sys.availability_groups AS ag ON ar.group_id = ag.group_id
     INNER JOIN sys.dm_hadr_database_replica_states AS rs ON ar.group_id = rs.group_id
        AND ar.replica_id = rs.replica_id
WHERE  rs.is_primary_replica = 1
ORDER BY [Availability Group];

--if needed, to set a given replica to SYNCHRONOUS for node N1, default instance
ALTER AVAILABILITY GROUP [testag] MODIFY REPLICA ON N'N1' WITH (AVAILABILITY_MODE = SYNCHRONOUS_COMMIT);

select ag.name, ag.is_distributed, ar.replica_server_name, ar.availability_mode_desc, ars.connected_state_desc, ars.role_desc, 
     ars.operational_state_desc, ars.synchronization_health_desc from sys.availability_groups ag  
     join sys.availability_replicas ar on ag.group_id=ar.group_id
     left join sys.dm_hadr_availability_replica_states ars
     on ars.replica_id=ar.replica_id
     where name='DAGDSI02'


SELECT ag.name
         , drs.database_id
         , db_name(drs.database_id) as database_name
         , drs.group_id
         , drs.replica_id
         , drs.synchronization_state_desc
         , drs.last_hardened_lsn  
FROM sys.dm_hadr_database_replica_states drs 
INNER JOIN sys.availability_groups ag on drs.group_id = ag.group_id
where db_name(drs.database_id)='Docusign' and ag.name IN ('AGDSI01','AGDSI02','DAGDSI02');