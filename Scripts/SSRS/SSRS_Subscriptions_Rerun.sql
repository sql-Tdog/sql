USE ReportServer
GO

/**
SELECT DISTINCT  [Catalog].Path AS ReportPath
FROM ReportSchedule 
INNER JOIN Schedule ON ReportSchedule.ScheduleID = Schedule.ScheduleID 
INNER JOIN Subscriptions ON ReportSchedule.SubscriptionID = Subscriptions.SubscriptionID 
INNER JOIN [Catalog] ON ReportSchedule.ReportID = [Catalog].ItemID AND Subscriptions.Report_OID = [Catalog].ItemID
WHERE Catalog.Path LIKE '%TAT/Daily PA TAT Report - New Rules%'

DROP TABLE #jobs;
GO

SELECT   Schedule.ScheduleID AS SQLAgent_Job_Name, Schedule.LastRunTime, LastStatus, Subscriptions.Description AS sub_desc, Subscriptions.DeliveryExtension AS sub_delExt, 
                      [Catalog].Name AS ReportName, [Catalog].Path AS ReportPath
INTO #jobsTemp
FROM ReportSchedule 
INNER JOIN Schedule ON ReportSchedule.ScheduleID = Schedule.ScheduleID 
INNER JOIN Subscriptions ON ReportSchedule.SubscriptionID = Subscriptions.SubscriptionID 
INNER JOIN [Catalog] ON ReportSchedule.ReportID = [Catalog].ItemID AND Subscriptions.Report_OID = [Catalog].ItemID
WHERE  --Subscriptions.NextRunTime between '11/3/18 12:00' and '11/4/18 00:00'
[Catalog].Path like '%TAT/Daily PA TAT Report - New Rules%' 
	and Subscriptions.Description NOT LIKE '%reject%'
	--and Schedule.LastRunTime between '10/4/18' and '10/5/18'
	--and LastStatus LIKE '%failure%error%' --and Subscriptions.Description='Send e-mail to Juan.F.Sosa@centene.com'

SELECT * FROM #jobsTemp;

--get failed subscriptions from a certain date:
SELECT Schedule.ScheduleID AS SQLAgent_Job_Name, Schedule.LastRunTime, LastStatus, Subscriptions.Description AS sub_desc, Subscriptions.DeliveryExtension AS sub_delExt, 
                      [Catalog].Name AS ReportName, [Catalog].Path AS ReportPath, E. Status, E.timestart
--INTO #jobsTemp
FROM ReportSchedule 
INNER JOIN Schedule ON ReportSchedule.ScheduleID = Schedule.ScheduleID 
INNER JOIN Subscriptions ON ReportSchedule.SubscriptionID = Subscriptions.SubscriptionID 
INNER JOIN [Catalog] ON ReportSchedule.ReportID = [Catalog].ItemID AND Subscriptions.Report_OID = [Catalog].ItemID
INNER JOIN ExecutionLog3 E ON E.ItemPath=[Catalog].Path
WHERE E.status<>'rsSuccess' and timestart>'2018-08-18 04:20' ANd LAstStatus LIKE 'Fail%'

--get subscriptions to rerun that belong to certain users and that failed on certain dates:
SELECT Schedule.ScheduleID AS SQLAgent_Job_Name, Schedule.LastRunTime, LastStatus, Subscriptions.Description AS sub_desc, Subscriptions.DeliveryExtension AS sub_delExt, 
                      [Catalog].Name AS ReportName, [Catalog].Path AS ReportPath, E. Status, E.timestart
--INTO #jobsTemp
FROM ReportSchedule 
INNER JOIN Schedule ON ReportSchedule.ScheduleID = Schedule.ScheduleID 
INNER JOIN Subscriptions ON ReportSchedule.SubscriptionID = Subscriptions.SubscriptionID 
INNER JOIN [Catalog] ON ReportSchedule.ReportID = [Catalog].ItemID AND Subscriptions.Report_OID = [Catalog].ItemID
LEFT JOIN Users U ON U.UserID=Subscriptions.OwnerId
WHERE U.Username IN ('CENTENE\KABROOKS') AND Subscriptions.LastRunTime BETWEEN '4/1/20' AND '4/7/20' AND (LastStatus LIKE 'Failure%' OR LastStatus LIKE 'An error%')


--update #jobs table to include the string to execute the job:
ALTER TABLE #jobsTemp ALTER COLUMN SQLAgent_Job_Name varchar(1500);
SELECT DISTINCT SQLAgent_Job_Name INTO #jobs FROM #jobsTemp;
GO
ALTER TABLE #jobs ADD id INT IDENTITY;
SELECT * FROM #jobs;

DROP TABLE #jobsTemp;

BEGIN TRANSACTION
UPDATE #jobs SET SQLAgent_Job_Name='sp_start_job @job_name='''+RTRIM(SQLAgent_Job_Name)+'''';


SELECT @@TRANCOUNT;

ROLLBACK TRANSACTION;
COMMIT TRANSACTION;

use msdb
go
DECLARE @stmt nvarchar(1500);
DECLARE @i int=1, @j int;
SET @j=(SELECT count(*) FROM #jobs);

WHILE @i<=@j BEGIN
	SET @stmt=(SELECT SQLAgent_Job_Name FROM #jobs WHERE id=@i);
	SELECT @stmt;
	EXECUTE sp_executesql @stmt;
	SET @i=@i+1;
	WAITFOR DELAY '00:01:00'
END


*/


/**
--get all subscriptions that will run at certain times

SELECT   Schedule.ScheduleID AS SQLAgent_Job_Name, Schedule.LastRunTime, LastStatus, Subscriptions.Description AS sub_desc, Subscriptions.DeliveryExtension AS sub_delExt, 
                      [Catalog].Name AS ReportName, [Catalog].Path AS ReportPath, Schedule.DaysInterval, DaysOfWeek, DaysOfMonth
INTO #jobsTemp
FROM         ReportSchedule INNER JOIN
                      Schedule ON ReportSchedule.ScheduleID = Schedule.ScheduleID INNER JOIN
                      Subscriptions ON ReportSchedule.SubscriptionID = Subscriptions.SubscriptionID INNER JOIN
                      [Catalog] ON ReportSchedule.ReportID = [Catalog].ItemID AND Subscriptions.Report_OID = [Catalog].ItemID
SELECT * FROM Schedule

SELECT SQLAgent_Job_Name FROM #jobsTemp
SELECT * FROM #jobsTemp

UPDATE #jobsTemp SET SQLAgent_Job_Name= RTRIM(SQLAgent_Job_Name);

ALTER TABLE #jobsTEMP ALTER COLUMN SQLAgent_Job_Name nvarchar(36);
use msdb
go

SELECT * FROM msdb.dbo.sysjobs; 
SELECT * FROM msdb.dbo.sysjobschedules;

SELECT ReportName, ReportPath, S.next_run_date, S.Next_run_time, DaysInterval, DaysOfWeek, DaysOfMonth
FROM #jobsTemp T INNER JOIN msdb.dbo.sysjobs J on J.name=T.SQLAgent_Job_Name
INNER JOIN msdb.dbo.sysjobschedules S ON S.job_id=J.job_id
WHERE S.next_run_date='20181103' and S.next_run_time between 115900 AND 230000
ORDER BY next_run_time


SELECT ReportName, ReportPath, S.next_run_date, S.Next_run_time, DaysInterval, DaysOfWeek, DaysOfMonth
FROM #jobsTemp T INNER JOIN msdb.dbo.sysjobs J on J.name=T.SQLAgent_Job_Name
INNER JOIN msdb.dbo.sysjobschedules S ON S.job_id=J.job_id
WHERE S.next_run_date>'20181104' -- AND DaysInterval=1
ORDER BY next_run_time

DROP TABLE #jobsTemp				 

SELECT job_id from msdb.dbo.sysjobs where job_id LIKE '2ECA%'
**/


SELECT ReportName, ReportPath, S.next_run_date, S.Next_run_time, DaysInterval, DaysOfWeek, DaysOfMonth
FROM #jobsTemp T INNER JOIN msdb.dbo.sysjobs J on J.name=T.SQLAgent_Job_Name
INNER JOIN msdb.dbo.sysjobschedules S ON S.job_id=J.job_id
WHERE S.next_run_date>'20181101'  AND S.next_run_date<'20181103'
ORDER BY next_run_time