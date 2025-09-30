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


Test-NetConnection ListenerName
The client attempts to connect to all IP addresses for the listener, until it succeeds.
Resolve by setting the RegisterAllProvidersIP cluster parameter to 0 for the listener
RegisterAllProvidersIP controls whether all IP addresses are registered in DNS. 
By setting it to 0, only the active IP address is registered.
$clust1 = ""
$listener1 = ""
$AGname1 = ""
$AGName_Listener1="$AGname1`_$listener1"
get-ClusterResource -Cluster $clust1 -Name $AGName_Listener1 | set-ClusterParameter RegisterAllProvidersIP 1
get-ClusterResource -Cluster $clust1 -Name $AGName_Listener1 | set-ClusterParameter HostRecordTTL 300
stop-clusterresource -Cluster $clust1 -Name $AGName_Listener1
start-clusterresource -Cluster $clust1 -Name $AGName_Listener1
Start-ClusterResource  -Cluster $clust1 -Name $AGname1

*/
