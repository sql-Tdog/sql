/**backup types:
D = Database
I = Differential database
L = Log
F = File or filegroup
G =Differential file
P = Partial
Q = Differential partial

*/
SELECT B.database_name, B.type, B.backup_start_date, B.backup_finish_date, DATEDIFF(second, B.backup_start_date, B.backup_finish_date) AS [duration (sec)], 
B.backup_size, B.compressed_backup_size, B.backup_size / B.compressed_backup_size AS ratio, B.is_damaged, F.physical_device_name, B.recovery_model, 
B.user_name
FROM msdb.dbo.backupset AS B INNER JOIN
msdb.dbo.backupmediafamily AS F ON F.media_set_id = B.media_set_id
WHERE database_name='SDGEESA' and type='D'
ORDER BY backup_start_date DESC



DECLARE @filename varchar(100);

WITH backups AS( SELECT TOP 2 physical_device_name,backup_finish_date  FROM msdb.dbo.backupset AS B INNER JOIN
msdb.dbo.backupmediafamily AS F ON F.media_set_id = B.media_set_id
WHERE database_name='Datamart' and type='D'
ORDER BY backup_finish_date DESC ) 
SELECT TOP 1 @filename=physical_device_name 
FROM backups ORDER BY backup_finish_date ASC

SELECT @filename;

IF (NOT sys.fn_hadr_backup_is_preferred_replica('Datamart'))
BEGIN
Select 'This is not the preferred replica, exiting with success';
RETURN 0 -- This is a normal, expected condition, so the script returns success
END
BACKUP DATABASE Datamart TO DISK=@filename;