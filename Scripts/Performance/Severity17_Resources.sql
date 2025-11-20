/*****Error:  There is insufficient system memory in resource pool 'default' to run this query.*************************/

--check to make sure there is enough memory left for the OS...lower memory allocated to SQL server to free up memory to the OS

--if a certain database is taking up the memory cache, I would think I could configure Resource Governor to limit that but 
--that is not an option.  RG only allows me to limit the query execution memory, not buffer pool memory

--check the resource pool:
select * from sys.dm_resource_governor_resource_pools

/*
--clear all cache entries associated with the default resource pool:
DBCC FREEPROCCACHE ('default');  

--clear procedure cache:
DBCC FREEPROCCACHE 



*/