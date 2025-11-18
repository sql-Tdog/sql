
/**have backups been failing? view backups that never finished or were marked as damaged

select top 100 * from msdb.dbo.backupset with (Nolock)
where backup_finish_date IS NULL OR is_damaged='true'
order by backup_set_id desc

*/

/**ARE ALL DATABASES GETTING BACKED UP?
***view the last backup date for each database

SELECT  d.name, MAX(b.backup_finish_date) AS last_backup_finish_date
FROM    master.sys.databases d WITH (NOLOCK)
LEFT OUTER JOIN msdb.dbo.backupset b WITH (NOLOCK) ON d.name = b.database_name AND b.type = 'D'
WHERE d.name <> 'tempdb'
GROUP BY d.name
ORDER BY 2

*/

/**HOW LONG ARE BACKUPS TAKING?
***If backups are run using SQL Server Agent, we can check how long the job takes to execute:
***/

select top 100 j.name jobname, j.enabled, h.step_name, run_date, run_time, run_duration, retries_attempted
from msdb.dbo.sysjobhistory h
inner join msdb.dbo.sysjobs j on j.job_id=h.job_id
where j.job_id='F9F24A96-DF3C-455B-A744-C9EC02FDFA6A' and step_name='Backup Datamart DB'
order by run_date desc

select * from msdb.dbo.sysjobs


/**ARE THE BACKUPS GETTING DATA OUT FAST ENOUGH?
--This query’s actually measuring backup throughput, meaning how fast the backups complete.

INSERT  INTO DBAwork.dbo.backup_speeds
SELECT  @@SERVERNAME AS ServerName ,
        YEAR(backup_finish_date) AS backup_year ,
        MONTH(backup_finish_date) AS backup_month ,
        CAST(AVG(( backup_size / ( DATEDIFF(ss, bset.backup_start_date,
                                            bset.backup_finish_date) )
                   / 1048576 )) AS INT) AS throughput_MB_sec_avg ,
        CAST(MIN(( backup_size / ( DATEDIFF(ss, bset.backup_start_date,
                                            bset.backup_finish_date) )
                   / 1048576 )) AS INT) AS throughput_MB_sec_min ,
        CAST(MAX(( backup_size / ( DATEDIFF(ss, bset.backup_start_date,
                                            bset.backup_finish_date) )
                   / 1048576 )) AS INT) AS throughput_MB_sec_max
		,DateAdd(hour,-7,getdate()) DateChecked
FROM    msdb.dbo.backupset bset
WHERE   bset.type = 'D' /* full backups only */
        AND bset.backup_size > 5368709120 /* 5GB or larger */
        AND DATEDIFF(ss, bset.backup_start_date, bset.backup_finish_date) > 1 /* backups lasting over a second */
GROUP BY YEAR(backup_finish_date) ,
        MONTH(backup_finish_date)
ORDER BY @@SERVERNAME ,
        YEAR(backup_finish_date) DESC ,
        MONTH(backup_finish_date) DESC

*/

/**To see how much data you could lose per database over the last couple of weeks, run this query:

CREATE TABLE #backupset (backup_set_id INT, database_name NVARCHAR(128), backup_finish_date DATETIME, type CHAR(1), next_backup_finish_date DATETIME);
INSERT INTO #backupset (backup_set_id, database_name, backup_finish_date, type)
  SELECT backup_set_id, database_name, backup_finish_date, type
  FROM msdb.dbo.backupset WITH (NOLOCK)
  WHERE backup_finish_date >= DATEADD(dd, -14, GETDATE())
  AND database_name NOT IN ('master', 'model', 'msdb');
CREATE CLUSTERED INDEX CL_database_name_backup_finish_date ON #backupset (database_name, backup_finish_date);
 
UPDATE #backupset
SET next_backup_finish_date = (SELECT TOP 1 backup_finish_date FROM #backupset bsNext WHERE bs.database_name = bsNext.database_name AND bs.backup_finish_date < bsNext.backup_finish_date ORDER BY bsNext.backup_finish_date)
FROM #backupset bs;
 
SELECT bs1.database_name, MAX(DATEDIFF(mi, bs1.backup_finish_date, bs1.next_backup_finish_date)) AS max_minutes_of_data_loss,
  'SELECT bs.database_name, bs.type, bs.backup_start_date, bs.backup_finish_date, DATEDIFF(mi, COALESCE((SELECT TOP 1 bsPrior.backup_finish_date FROM msdb.dbo.backupset bsPrior WHERE bs.database_name = bsPrior.database_name AND bs.backup_finish_date > bsPrior.backup_finish_date ORDER BY bsPrior.backup_finish_date DESC), ''1900/1/1''), bs.backup_finish_date) AS minutes_since_last_backup, DATEDIFF(mi, bs.backup_start_date, bs.backup_finish_date) AS backup_duration_minutes, CASE DATEDIFF(ss, bs.backup_start_date, bs.backup_finish_date) WHEN 0 THEN 0 ELSE CAST(( bs.backup_size / ( DATEDIFF(ss, bs.backup_start_date, bs.backup_finish_date) ) / 1048576 ) AS INT) END AS throughput_mb_sec FROM msdb.dbo.backupset bs WHERE database_name = ''' + database_name + ''' AND bs.backup_start_date > DATEADD(dd, -14, GETDATE()) ORDER BY bs.backup_start_date' AS more_info_query
  FROM #backupset bs1
  GROUP BY bs1.database_name
  ORDER BY bs1.database_name
 
DROP TABLE #backupset;
GO

*/
