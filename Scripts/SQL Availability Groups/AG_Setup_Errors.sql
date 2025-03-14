--if the connection is broken to the secondary, check the connection state and errors on it:
select r.replica_server_name, r.endpoint_url,
       rs.connected_state_desc, rs.last_connect_error_description, 
       rs.last_connect_error_number, rs.last_connect_error_timestamp 
 from sys.dm_hadr_availability_replica_states rs 
  join sys.availability_replicas r
   on rs.replica_id=r.replica_id
 where rs.is_local=1

 /*possible errors
 An error occurred while receiving data: 
 '10054(An existing connection was forcibly closed by the remote host.)'.

Solution:  In the AG settings, check endpoint URLs for the relica.  If they are incorrect,
remove the replica and add it back with the correct endpoint URL.

*/
