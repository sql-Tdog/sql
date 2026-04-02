<#
Proxy connection type puts memory pressure on the Azure SQL Gateway.


Proxy Mode:
All traffic is routed through the Azure SQL Gateway, which listens on port 1433.
The gateway then forwards traffic internally to the Managed Instance.
This mode simplifies networking and works even if outbound ports are restricted, but it can introduce 
slightly higher latency due to the additional hop.

Redirect Mode:
The client first contacts the gateway on port 1433, which then provides the actual node IP 
and a dynamic port (within the 11000–11999 range). The client reconnects directly to the 
Managed Instance node on that port, providing a more direct path and lower latency.
This requires network access to the MI subnet and the ability to open the dynamic ports.
Switching to Redirect mode will reduce load on the gateway and improve performance by 
lowering latency and increasing throughput. MS confirms that since the MIs are hosted 
in a cluster dedicated to our subscription, this configuration remains secure.
#>

<#
check NSG rules to make sure the extra ports are added:
go to MI settings ->Virtual network/subnet -> subnets -> Security group -> View inbound
security groups and ports, filter by port 1433
#>
proxy_override = "Redirect"

