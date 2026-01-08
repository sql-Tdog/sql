SELECT *
FROM sys.dm_database_backups 
--WHERE backup_type='D'
ORDER BY backup_finish_date DESC;
