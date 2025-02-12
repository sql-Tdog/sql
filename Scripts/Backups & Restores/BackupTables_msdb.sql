/**script to check  msdb backup tables 
-- make sure maintenance clean up tasks are running 

SELECT TOP 10 *
  FROM msdb.dbo.backupset WITH (NOLOCK)
  ORDER BY backup_set_id ASC

  **/

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