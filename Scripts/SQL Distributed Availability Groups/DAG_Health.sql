select replica_server_name, database_name, rs.synchronization_health_desc, log_send_queue_size, log_send_rate, last_redone_time 
from sys.dm_hadr_database_replica_states dr inner join sys.availability_replicas ar on ar.replica_id=dr.replica_id
inner join sys.availability_databases_cluster dc on dc.group_database_id=dr.group_database_id
inner join sys.dm_hadr_availability_replica_states rs on rs.replica_id=ar.replica_id 
--where database_name=''
where log_send_queue_size >0
