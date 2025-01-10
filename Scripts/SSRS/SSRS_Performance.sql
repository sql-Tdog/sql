use ReportServer
go
select @@version;
/********
select * from sys.databases;
--what reports are running right now?
SELECT * FROM [ReportServer].[dbo].[RunningJobs] J LEFT JOIN [ReportServer].[dbo].[Users] U on U.UserId=J.UserId
 
select getdate()
 
select * from sys.sysprocesses where hostname='p-birpt1'
select * from sys.sysprocesses where spid>50 order by waittime desc;
 
--look at scheduled reports:
SELECT    
Schedule.ScheduleID AS SQLAgent_Job_Name,
Subscriptions.Description AS sub_desc,
Subscriptions.DeliveryExtension AS sub_delExt,
[Catalog].Name AS ReportName,
[Catalog].Path AS ReportPath
FROM         ReportSchedule INNER JOIN
             Schedule ON ReportSchedule.ScheduleID = Schedule.ScheduleID INNER JOIN
             Subscriptions ON ReportSchedule.SubscriptionID = Subscriptions.SubscriptionID INNER JOIN
            [Catalog] ON ReportSchedule.ReportID = [Catalog].ItemID AND
            Subscriptions.Report_OID = [Catalog].ItemID
                     ORDER BY cast(Schedule.ScheduleID as varchar(200))
 
select cmd, * from sys.sysprocesses where hostname='OFLSSRSAD001';
 
--look at failing reports:
Select L.UserName, L.Format, L.TimeStart, L.TimeEnd, L.TimeDataRetrieval, L.TimeProcessing, L.TimeRendering,
       L.Status, L.ByteCount, C.Path, C.Name, C.ModifiedDate
from ExecutionLog L with (nolock) left join catalog c on L.reportid=C.itemid
where status<>'rsSuccess' ORDER BY L.TimeStart DESC
 
--ERRORS:
--rrRenderingError:  check SSRS log, possible that the # of rows exceeds the max
 
--look at the log:
--source:  1=live, 2=cache, 3=snapshot, 4=history
Select top 80 * from ExecutionLog with (nolock) 
--where reportid='1FC2DF52-D4DE-4276-8AA5-F2AE36AD0636' order by Timestart desc
--where status<>'rsSuccess'
--where username like '%barron%'--and format='excel'
order by Timestart desc
TimeProcessing+TimeDataRetrieval+TimeRendering DESC
 
--ExecutionLog2
Select top 40 * from ExecutionLog2 with (nolock)
--where reportpath like'%ra3003%' --and username='CENTENE\AZALDANA' and format='excel'
--where timestart>'12/1/2015'
order by Timestart desc;
 
 
--ExecutionLog3:  contains request type, and item path
Select top 30 * from ExecutionLog3 with (nolock) where itempath like '%claims detail%'--username like '%okata%'
order by timestart desc;
 

--view last time end for reports run in the last 18 months:
SELECT C.Path, A.TimeEnd FROM Catalog C WITH(NOLOCK)
	CROSS APPLY (SELECT TOP 1 TimeEnd FROM ExecutionLog2 E WITH (NOLOCK) WHERE ReportPath<>'' AND DATEDIFF(month,timeend,getdate())<18
		AND E.ReportPath=C.Path ORDER BY TimeEnD DESC) A;

 
--get report information, given a report id:
select * from catalog with (nolock) where path like '%GER%'
where itemid IN ('1A25FD98-4741-45E4-A437-84D87570DCD9')
select top 1 * from datasource
 
select * from ConfigurationInfo
 
--check SQL Server Agent jobs for subscription:
SELECT     Schedule.ScheduleID AS SQLAgent_Job_Name, Schedule.LastRunTime, Subscriptions.Description AS sub_desc, Subscriptions.DeliveryExtension AS sub_delExt,
                      [Catalog].Name AS ReportName, [Catalog].Path AS ReportPath
FROM         ReportSchedule INNER JOIN
                      Schedule ON ReportSchedule.ScheduleID = Schedule.ScheduleID INNER JOIN
                      Subscriptions ON ReportSchedule.SubscriptionID = Subscriptions.SubscriptionID INNER JOIN
                      [Catalog] ON ReportSchedule.ReportID = [Catalog].ItemID AND Subscriptions.Report_OID = [Catalog].ItemID
WHERE [Catalog].Path like '%financial an%client packet%'-- and subscriptions.description like '%2015%'
 
select * from ReportSchedule where ScheduleID='33DE2571-2C55-4AF1-BD4E-A0ADE601E8A4'
 
SELECT    
 Schedule.ScheduleID AS SQLAgent_Job_Name,
 Subscriptions.Description AS sub_desc,
  Subscriptions.DeliveryExtension AS sub_delExt,
  [Catalog].Name AS ReportName,
  [Catalog].Path AS ReportPath,
SUBSTRING(ExtensionSettings, LEN('<Name>TO</Name><Value>') + CHARINDEX('<Name>TO</Name><Value>', ExtensionSettings), CHARINDEX('</Value>', ExtensionSettings, CHARINDEX('<Name>TO</Name><Value>', ExtensionSettings) + 1) - (LEN('<Name>TO</Name><Value>') + CHARINDEX('<Name>TO</Name><Value>', ExtensionSettings))) AS 'To Email recipient List',
CASE CHARINDEX('<Name>CC</Name><Value>', ExtensionSettings) WHEN 0 THEN
  ''
ELSE
   SUBSTRING(ExtensionSettings, LEN('<Name>CC</Name><Value>') + CHARINDEX('<Name>CC</Name><Value>', ExtensionSettings), CHARINDEX('</Value>', ExtensionSettings, CHARINDEX('<Name>CC</Name><Value>', ExtensionSettings) + 1) - (LEN('<Name>CC</Name><Value>') + CHARINDEX('<Name>CC</Name><Value>', ExtensionSettings)))
END AS 'CC Email recipient List',
CASE CHARINDEX('<Name>BCC</Name><Value>', ExtensionSettings) WHEN 0 THEN
''
ELSE
SUBSTRING(ExtensionSettings, LEN('<Name>BCC</Name><Value>') + CHARINDEX('<Name>BCC</Name><Value>', ExtensionSettings), CHARINDEX('</Value>', ExtensionSettings, CHARINDEX('<Name>BCC</Name><Value>', ExtensionSettings) + 1) - (LEN('<Name>BCC</Name><Value>') + CHARINDEX('<Name>BCC</Name><Value>', ExtensionSettings)))
 
END AS 'BCC Email recipient List'
 
FROM        
  ReportSchedule
INNER JOIN Schedule  ON   ReportSchedule.ScheduleID = Schedule.ScheduleID
INNER JOIN Subscriptions  ON   ReportSchedule.SubscriptionID = Subscriptions.SubscriptionID
INNER JOIN [Catalog]  ON   ReportSchedule.ReportID = [Catalog].ItemID 
AND Subscriptions.Report_OID = [Catalog].ItemID
WHERE
  Subscriptions.DeliveryExtension = 'Report Server Email' and [Catalog].Path like '%/Users Folders/CENTENE RMHANGO/My Reports/Client Packet%'
 
SELECT * FROM schedule
  */
 