/**
script to check  msdb backup tables 
make sure maintenance clean up tasks are running to clean up these tables
*/

SELECT TOP 10 *
  FROM msdb.dbo.backupset WITH (NOLOCK)
  ORDER BY backup_set_id ASC


SELECT TOP 10 physical_device_name, backup_finish_date, *
FROM    msdb.dbo.backupset b,
           msdb.dbo.backupmediafamily mf
WHERE    b.media_set_id = mf.media_set_id
	AND b.database_name='Sentinel'
ORDER BY b.backup_finish_date DESC


SELECT COUNT(backup_set_id)
  FROM [msdb].[dbo].[backupset]
 
 SELECT COUNT(backup_set_id) 
 FROM msdb.dbo.backupfile
 
 select COUNT(media_set_id)
 from msdb.dbo.backupmediaset
 
 select COUNT(media_set_id)
 from msdb.dbo.backupmediafamily
 
 select COUNT(backup_set_id)
 from msdb.dbo.backupfilegroup
 

 /**
DECLARE @oldest datetime = (SELECT getdate());
EXEC msdb.dbo.sp_delete_backuphistory @oldest_date = @oldest;

select * FROM msdb.dbo.backupfile order by backup_set_id desc

  **/