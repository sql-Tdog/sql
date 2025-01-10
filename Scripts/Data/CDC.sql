/****************CHANGE DATA CAPTURE***********************************************
sp_replcmds will be executed by SQL Server Agent to capture changed data 
sp_repldone marks that change data has been sent to the cdc tables

will see REPLICATION in the log_reuse_wait for the cdc database

if log is not getting truncated:
	Stop and disable (or drop, then recreate later) cdc jobs then:  
		exec sp_repldone @exactid=NULL, @xact_seqno=NULL, @numtrans=0, @time=0, @reset=1;
		exec sp_replflush
	--recreate cdc jobs, if dropped


cdc_capture job fails with a message that another connection is running the sp_replcmds:
	this could happen if someone executed the sp_repldone and did not run sp_replflush command, just run the sp_replflush


*/
--check if cdc is enabled: 
select name, is_cdc_enabled
from sys.databases

--to turn off cdc:  (cdc jobs will be dropped automatically)
USE CMS_D6_App
GO
sys.sp_cdc_disable_db;


--enable change data capture for db before any tables can be enabled*
USE ipas
GO
sys.sp_cdc_enable_db;

--check what tables have cdc enabled: 
SELECT s.name AS Schema_Name, tb.name AS Table_Name , tb.object_id, tb.type, tb.type_desc, tb.is_tracked_by_cdc 
FROM sys.tables tb INNER JOIN sys.schemas s on s.schema_id = tb.schema_id WHERE tb.is_tracked_by_cdc = 1
ORDER BY s.name, tb.name;

select capture_instance 
from cdc.change_tables where source_object_id = object_id('enrl.Enrollment')

--check which columns are enabled for a table:
sys.sp_cdc_get_captured_columns 'enrl_Enrollment'


EXEC [sys].[sp_cdc_help_change_data_capture]

EXEC xp_readerrorlog 0,1,NULL,NULL,NULL,NULL,'desc'

SELECT * FROM sys.dm_cdc_errors;

SELECT * FROM sys.dm_cdc_log_scan_sessions;


SELECT * 
FROM sys.change_tracking_databases 
WHERE database_id=DB_ID('CMS_QA6_App')


--by default, the cdc cleanup job deletes cdc data older than 3 days
--to modify:
use CMS_Prod_App
GO
select retention from msdb.dbo.cdc_jobs

exec sys.sp_cdc_change_job @job_type='cleanup', retention=10080;


/*
DECLARE @capture_instance sysname

DECLARE @capture_instances table (
		source_schema           sysname,    
		source_table            sysname,    
		capture_instance		sysname,	
		object_id				int,		
		source_object_id		int,		
		start_lsn				binary(10),	
		end_lsn					binary(10)	NULL,	
		supports_net_changes	bit,		
		has_drop_pending		bit		NULL,		
		role_name				sysname	NULL,	
		index_name				sysname	NULL,	
		filegroup_name			sysname	NULL,				 
		create_date				datetime,	
		index_column_list		nvarchar(max) NULL, 
		captured_column_list	nvarchar(max))
		
DECLARE @ddl_history table (
        source_schema		sysname,
		source_table		sysname,
		capture_instance	sysname,
		required_column_update	bit,		
		ddl_command			nvarchar(max),
		ddl_lsn				binary(10),
		ddl_time			datetime)

INSERT INTO @capture_instances
EXEC [sys].[sp_cdc_help_change_data_capture]

DECLARE #hinstance CURSOR LOCAL fast_forward
FOR
	SELECT capture_instance  
	FROM @capture_instances
    
OPEN #hinstance
FETCH #hinstance INTO @capture_instance
	
WHILE (@@fetch_status <> -1)
BEGIN
	INSERT INTO @ddl_history
	EXEC [sys].[sp_cdc_get_ddl_history] @capture_instance
			
	FETCH #hinstance INTO @capture_instance
END
	
CLOSE #hinstance
DEALLOCATE #hinstance

SELECT source_schema, source_table, capture_instance, ddl_time, ddl_command
FROM @ddl_history
ORDER BY ddl_time
GO

*/

