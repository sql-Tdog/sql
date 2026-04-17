<#
Proxy connection type puts memory pressure on the Azure SQL Gateway.

https://techcommunity.microsoft.com/blog/azuresqlblog/improved-connectivity-types-in-azure-sql-managed-instance/4457301

Proxy Mode:
All traffic is routed through the Azure SQL Gateway, which listens on port 1433.
The gateway then forwards traffic internally to the Managed Instance.
This mode simplifies networking and works even if outbound ports are restricted, but it can introduce 
higher latency due to the additional hop.  

Redirect Mode:
The client first contacts the gateway on port 1433, which used to provide it the actual node IP 
and a dynamic port (within the 11000–11999 range).  Now, it tells it to abandon the current connection
and connect to the SQL MI IP instead. The client reconnects directly to the 
Managed Instance node, providing a more direct path and lower latency.
Switching to Redirect mode will reduce load on the gateway and improve performance by 
lowering latency and increasing throughput. MS confirms that since the MIs are hosted 
in a cluster dedicated to our subscription, this configuration remains secure.
#>

<#
check NSG rules to make sure the extra ports are added:
go to MI settings ->Virtual network/subnet -> subnets -> Security group -> View inbound
security groups and ports, filter by port 1433
make sure every 1433 rule also includes 11000–11999 range
#>
proxy_override = "Redirect"

