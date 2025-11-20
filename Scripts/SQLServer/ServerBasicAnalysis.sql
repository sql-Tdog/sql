/*****************
Server Check
******************/
 
/*****************
check how many CPUs (cores) a particular instance of SQL Server can see,
******************/
select cpu_count from sys.dm_os_sys_info
 
/**if CPU affinity is being used to assign specific CPUs to SQL server,
cpu_id column will always be less than 255 */
--find out how many CPUs a particular instance is actually using
select scheduler_id,cpu_id, status, is_online from sys.dm_os_schedulers where status='VISIBLE ONLINE'
 
--check hyperthreading:
SELECT (cpu_count / hyperthread_ratio) AS PhysicalCPUs,
cpu_count AS logicalCPUs
FROM sys.dm_os_sys_info
 
--check NUMA configuration:
EXEC sys.sp_readerrorlog 0, 1,'node'
--there will be an output for each NUMA node, example below:
--Node configuration: node 0: CPU mask: 0x000000000000003f:0 Active CPU mask: 0x000000000000003f:0. This message provides a description of the NUMA configuration for this computer. This is an informational message only. No user action is required.
 
/*****************
Determine which version and edition of SQL Server Database Engine is running
 
******************/
Select @@version
 
SELECT SERVERPROPERTY('productversion') [Version], SERVERPROPERTY ('productlevel') [Level], SERVERPROPERTY ('edition') [Edition]

SELECT SERVERPROPERTY('EngineEdition')


SELECT * FROM sys.dm_user_db_resource_governance -- Available only in Azure SQL Database and SQL Managed Instance
SELECT * FROM sys.dm_instance_resource_governance -- Available only in Azure SQL Managed Instance
SELECT * FROM sys.dm_os_job_object -- Available only in Azure SQL Database and SQL Managed Instance

/*****************
How long has our instance been up?
******************/
 
select cast(
       datediff(hh,crdate,GETDATE())
       /24. as numeric(10,1)) as [Days Uptime]
       ,crdate
from master..sysdatabases where name='tempdb'
 
 
/***************************************************/
--parallelism
 
--cost threshold for parallelism option & max degree of parallelism are advanced options:
--first do a check:
sp_configure 'max degree of parallelism'
 

/*reconfigure if needed:
sp_configure 'max degree of parallelism';
go
sp_configure 'cost threshold for parallelism',5;
 
--*************************************************/
--Check if named pipes protocol is enabled:

SELECT 'Named Pipes' AS [Protocol], iif(value_data = 1, 'Yes', 'No') AS isEnabled
FROM sys.dm_server_registry
WHERE registry_key LIKE '%np' AND value_name = 'Enabled'
UNION
SELECT 'Shared Memory', iif(value_data = 1, 'Yes', 'No')
FROM sys.dm_server_registry
WHERE registry_key LIKE '%sm' AND value_name = 'Enabled'
UNION
SELECT 'TCP/IP', iif(value_data = 1, 'Yes', 'No')
FROM sys.dm_server_registry
WHERE registry_key LIKE '%tcp' AND value_name = 'Enabled'




--Identify SQL Server TCP IP port being used (using SQL Server Error Log or dm_exec_connections table)
USE master
GO
EXEC xp_readerrorlog 2, 1, @p3="Server is listening on",@p4="any", @p5=NULL, @p6=NULL, @p7='asc'
GO
 
--OR
 
SELECT distinct protocol_type, local_tcp_port
FROM sys.dm_exec_connections
 
 --check backup compression setting or reconfigure:
EXEC sp_configure 'backup compression default', 1 ;  
RECONFIGURE;  
