--SQL MI:

select DATABASEPROPERTYEX('DatabaseName', 'Updateability')

SELECT configuration_id, name, value, value_for_secondary  
FROM sys.database_scoped_configurations;

/********read-only routing:
sqlminame.secondary.database.windows.net in the connection string will send traffic to geo secondary replica
sqlminame.database.windows.net with "ApplicationIntent": "ReadOnly" will send traffic to local secondary replicas
*/

/*
Each SQL MI cluster has 3 nodes that run the gateways, these gateways deal with the traffic coming in, 
but if the connection type is proxy, then the connection will stay on the gateway and the traffic flows 
between the gateway and the instance running it.

The proxy connection type is not recommended because it increases latency with the additional hop. 
Additionally, these nodes can become unresponsive due to CPU or memory pressure. When this happens, 
the gateway is restarted, killing off all existing connections.

By changing your instances to redirect, you free up resources for the gateway to deal with new connections 
and you get increased throughput and improved latency because your connection sits on the node hosting the 
instance.

Another note is that changing the connection policy does not work when your instance is in a failover group. 
You would need to drop the failover group, make the change, and then set the failover group up again

*/
