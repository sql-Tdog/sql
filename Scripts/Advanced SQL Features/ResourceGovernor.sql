/**
--enable Resource Governor (requires CONTROL SERVER permission)

ALTER RESOURCE GOVERNOR RECONFIGURE;  
GO  

--Pool Concepts:
MIN_CPU_PERCENT and MAX_CPU_PERCENT:  guaranteed average CPU bandwidth for all requests in the pool when there is CPU contention
CAP_CPU_PERCENT:  hard cap limit on the CPU bandwidth for all requests in the resource pool
MIN_MEMORY_PERCENT and MAX_MEMORY_PERCENT:  amount of memory reserved for the pool that cannot be shared with other pools, this is query
	execution memory and not buffer pool memory (data & index pages)
AFFINITY:  allows a pool to be scheduled on a certain CPU for greater isolation of CPU resources
MIN_IOPS_PER_VOLUME and MAX_IOPS_PER_VOLUME:  this setting is per disk volume for a resource pool


--create a Resource pool
CREATE RESOURCE POOL poolStagingDB WITH (MAX_CPU_PERCENT = 20);  
GO  
ALTER RESOURCE GOVERNOR RECONFIGURE;  
GO  



SELECT name AS 'Pool Name', 
cache_memory_kb/1024.0 AS [cache_memory_MB], 
used_memory_kb/1024.0 AS [used_memory_MB] 
FROM sys.dm_resource_governor_resource_pools;


*/