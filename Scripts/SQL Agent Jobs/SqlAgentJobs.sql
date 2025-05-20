
use msdb
go

--look at all current SQL Server Agent jobs:
SELECT
sj.name AS jobName
, ss.name AS scheduleName , ss.schedule_id
, sja.next_scheduled_run_date
FROM msdb.dbo.sysjobs sj
INNER JOIN msdb.dbo.sysjobactivity sja ON sja.job_id = sj.job_id
INNER JOIN msdb.dbo.sysjobschedules sjs ON sjs.job_id = sja.job_id
INNER JOIN msdb.dbo.sysschedules ss ON ss.schedule_id = sjs.schedule_id
WHERE sj.name='Alert - DAG HADR Restart'

--since not all users exist in the master.dbo.sysusers (if they are accessing through a windows group),
--use the SUSER_NAME() function to get owner of each job:
SELECT s.name, SUSER_SNAME(s.owner_sid) AS owner
FROM msdb..sysjobs s 
ORDER BY name

select * from master.dbo.sysusers

--look at all enabled jobs:
select * from msdb.dbo.sysjobs where enabled=1;

--job notification settings:
SELECT s.name , o.name notify_email_operator, p.name notify_page_operator
FROM msdb..sysjobs s
LEFT JOIN msdb.dbo.sysoperators o ON o.id=s.nofity_email_operator_id
LEFT JOIN msdb.dbo.sysoperators p ON p.id=s.nofity_page_operator_id
ORDER BY name


--change a job (enable/disable/etc)
msdb.dbo.sp_update_job @job_name='', @enabled=0;


/*
update msdb.dbo.sysjobs set enabled=0 where name NOT IN ('Service_restart_notification','syspolicy_purge_history');

*/



/*************Use a cursor to delete each job that is currently disabled*************************************
DECLARE @j UNIQUEIDENTIFIER;
DECLARE @name VARCHAR(100);
 
DECLARE j_cursor CURSOR
FOR
SELECT job_id, NAME
FROM msdb..sysjobs
WHERE enabled = 0

OPEN j_cursor
 
FETCH NEXT
FROM j_cursor
INTO @j, @name
 
WHILE @@fetch_status = 0
BEGIN
 EXEC msdb..sp_delete_job @job_id = @j, @delete_unused_schedule = 0
 
PRINT 'Deleted job: ' + @name
 
FETCH NEXT
 FROM j_cursor
 INTO @j, @name
END
 
CLOSE j_cursor
 
DEALLOCATE j_cursor

*/


--look at a certain job's history:
select job_id, name from msdb.dbo.sysjobs where name='SQLBackups.Log'

select job_id, name from msdb.dbo.sysjobs order by name;

select * from msdb.dbo.sysjobhistory h inner join msdb.dbo.sysjobs b on b.job_id=h.job_id
where b.name='DBA-BackupAgentJobs'

select * from msdb.dbo.sysjobhistory where job_id IN 
	('0AC22E7F-0C90-4DD1-B06D-D5BDC34AFE5A')
	and run_date='20200319'


--look at how long a certain job runs:
--run_status:
0: failed
1: succeeded
2: retry
3: canceled
4: in progress

select  run_date, sum(run_duration) 'hhmmss' from msdb.dbo.sysjobhistory
where job_id IN ('9B56F223-E631-44F6-9EBC-CE563ACB74BD','F9F24A96-DF3C-455B-A744-C9EC02FDFA6A') and step_id=2
group by run_date


--look up job from job_id that can be retrieved from sp_whoisactive:
sp_help_job @job_id=0xEAC37D3030BEB141812F337DFAB5643B

--look up job from job name:
sp_help_job @job_name='DB Refresh-Acaria'

--look up job step from job_id:
sp_help_jobstep @job_id=0xEAC37D3030BEB141812F337DFAB5643B

SELECT count(*) FROM msdb.dbo.sysjobhistory where job_id='F9F24A96-DF3C-455B-A744-C9EC02FDFA6A'
and run_date=convert(varchar(8),getdate(),112) and step_id=7 and run_status=1

--How long did index job wait for ETL process to complete before executing?
DECLARE @lastrundate varchar(8);
SET @lastrundate=(SELECT TOP 1 run_date from msdb.dbo.sysjobhistory where job_id='9B56F223-E631-44F6-9EBC-CE563ACB74BD' ORDER BY run_date DESC);

select * 
FROM msdb.dbo.sysjobhistory where job_id='F9F24A96-DF3C-455B-A744-C9EC02FDFA6A'
AND run_date=convert(varchar(8),getdate(),112) and step_id=7 and run_status=1




--To re-run a subscription, just modify it and look at the last modified timestamp to get job_id:
select j.job_id, js.last_run_date,j.date_created, j.date_modified, ja.next_scheduled_run_date from msdb.dbo.sysjobs J 
inner join msdb.dbo.sysjobsteps js ON J.job_id=js.job_id
inner join msdb.dbo.sysjobactivity ja on j.job_id=ja.job_id
order by j.date_modified DESC

select * from ReportServer.dbo.Subscriptions WHERE Description='PA Reqs with Address Mismatch'


/**
sp_start_job @job_id='FF44A62A-C01F-4CCB-B5E0-5F1E65804C85'

msdb.dbo.sp_start_job @job_name=''

--Re-run certain jobs based on last run date and next scheduled run:
select j.job_id, js.last_run_date,j.date_created, j.date_modified, ja.next_scheduled_run_date from msdb.dbo.sysjobs J 
inner join msdb.dbo.sysjobsteps js ON J.job_id=js.job_id
inner join msdb.dbo.sysjobactivity ja on j.job_id=ja.job_id
WHERE js.last_run_date IN (20191028) 
AND day(next_scheduled_run_date) IN (11) AND month(next_scheduled_run_date) =11 and year(next_scheduled_run_date)=2019
order by date_created


SELECT J.job_id
INTO #jobs
from msdb.dbo.sysjobs J 
inner join msdb.dbo.sysjobsteps js ON J.job_id=js.job_id
inner join msdb.dbo.sysjobactivity ja on j.job_id=ja.job_id
WHERE js.last_run_date IN (20191001,20191002,20191003,20191004) 
AND day(next_scheduled_run_date) IN (1,2,3,4) AND month(next_scheduled_run_date) =12 and year(next_scheduled_run_date)=2019

SELECT * FROM #jobs

ALTER TABLE #jobs ALTER COLUMN job_id varchar(2500);

UPDATE #jobs SET job_id='sp_start_job @job_id='''+RTRIM(job_id)+'''';

ALTER TABLE #jobs ADD id INT IDENTITY;

--now execute:

DECLARE @stmt nvarchar(1500);
DECLARE @i int=1, @j int;
SET @j=(SELECT count(*) FROM #jobs);

WHILE @i<=@j BEGIN
	SET @stmt=(SELECT job_id FROM #jobs WHERE id=@i);
	SELECT @stmt;
	EXECUTE sp_executesql @stmt;
	SET @i=@i+1;
	WAITFOR DELAY '00:01:00'
END




**/