--get the SQL Service Account info:
SELECT DSS.servicename, DSS.startup_type_desc, DSS.status_desc, DSS.last_startup_time,
	DSS.service_account, DSS.is_clustered, DSS.cluster_nodename, DSS.filename, DSS.startup_type,
	DSS.status, DSS.process_id
FROM sys.dm_server_services AS DSS;


--check if Lock Pages in memory is enabled (Conventional=not enabled)
SELECT sql_memory_model, sql_memory_model_desc
FROM sys.db_os_sys_info;
