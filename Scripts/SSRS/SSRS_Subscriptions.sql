USE ReportServer;
GO

/***
--view all subscriptions:

c.Type: 2=report,4=Linked Report


SELECT s.subscriptionid, c.Name, c.Type, u.UserName AS SubscriptionOwner, c.CreationDate, c.ModifiedDate
	, s.Description AS Subscription, s.DeliveryExtension AS SubscriptionDelivery, d.Name AS DataSource
	, s.LastStatus, s.LastRunTime, s.Parameters, sch.StartDate AS ScheduleStarted, sch.LastRunTime AS LastSubRun
	, sch.NextRunTime, c.Path, *
FROM Catalog c WITH (NOLOCK) INNER JOIN Subscriptions s ON c.ItemID = s.Report_OID 
INNER JOIN DataSource d ON c.ItemID = d.ItemID LEFT OUTER JOIN Users u ON u.UserID = s.ownerid
LEFT OUTER JOIN ReportSchedule rs ON c.ItemID = rs.ReportID LEFT OUTER JOIN Schedule sch ON rs.ScheduleID = sch.ScheduleID 
WHERE s.subscriptionid='1CB0EC1B-D0D1-4DCC-A9D9-C146F15E4A7C'
	--laststatus IN('The value ''EXCEL'' is not valid for setting ''Render Format''.')
	--u.username LIKE '%ovsak%'
	--CAST(sch.NextRunTime AS time)<'10:00 AM' --see subscriptions that are scheduled to run before a certain time
ORDER BY s.LastRunTime desc

--see # of subscriptions each user owns:
SELECT count(DISTINCT c.Path) [# of subscritions], u.UserName AS [Subscription Owner]
FROM Catalog c WITH (NOLOCK) INNER JOIN Subscriptions s ON c.ItemID = s.Report_OID 
INNER JOIN DataSource d ON c.ItemID = d.ItemID LEFT OUTER JOIN Users u ON u.UserID = s.ownerid
LEFT OUTER JOIN ReportSchedule rs ON c.ItemID = rs.ReportID LEFT OUTER JOIN Schedule sch ON rs.ScheduleID = sch.ScheduleID 
GROUP BY u.UserName


--look for subscriptions that are being saved to a shared network drive:
SELECT u.UserName AS SubscriptionOwner,c.Path, s.Description AS Subscription, s.LastStatus, s.ExtensionSettings
	, s.LastRunTime,  c.Name
FROM Catalog c WITH (NOLOCK) INNER JOIN Subscriptions s ON c.ItemID = s.Report_OID LEFT OUTER JOIN Users u ON u.UserID = s.ownerid
WHERE s.ExtensionSettings LIKE '%203%'

--get a list of all subscriptions with schedule info:
SELECT u.UserName AS SubscriptionOwner,c.Path, s.LastStatus, s.LastRunTime,  c.Name, s.Description AS Subscription    
         ,Sch.StartDate  
         ,sch.EndDate  
         ,Sch.[Recurrence Type]  
         ,Sch.[Recurrence Sub Type]  
         ,Sch.[Run every (Hours)]  
         ,Sch.[Runs every (Days)]  
         ,Sch.[Runs every (weeks)]  
         ,CASE   
          WHEN len(Sch.[Runs every (Week Days)]) > 0 THEN substring(Sch.[Runs every (Week Days)],1,len(Sch.[Runs every (Week Days)])-1)  
          ELSE ''  
          END AS [Runs every (Week Days)]  
         ,Sch.[Runs every (Week of Month)]  
         ,CASE   
          WHEN len(Sch.[Runs every (Month)]) > 0 THEN substring(Sch.[Runs every (Month)],1,len(Sch.[Runs every (Month)])-1)  
          ELSE ''  
          END AS [Runs every (Month)]  
         ,CASE   
          WHEN len(Sch.[Runs every (Calendar Days)]) > 0 THEN substring(Sch.[Runs every (Calendar Days)],1,len(Sch.[Runs every (Calendar Days)])-1)  
          ELSE ''  
          END AS [Runs every (Calendar Days)]  
   FROM   [Catalog] c WITH (NOLOCK)
   INNER JOIN  Subscriptions s on  c.ItemID  = s.Report_OID
   left join ReportSchedule rs ON c.ItemID=rs.ReportID
   LEFT OUTER JOIN
  
   (  
         SELECT ScheduleID 
               ,Name  
               ,CASE   
               WHEN RecurrenceType=1 THEN 'Once'  
               WHEN RecurrenceType=2 THEN 'Hourly'  
               WHEN RecurrenceType=3 THEN 'Daily'  
               WHEN RecurrenceType=4 THEN 'Weekly'  
               WHEN RecurrenceType in (5,6) THEN 'Monthly'  
               END as 'Recurrence Type'  
               ,CASE   
               WHEN RecurrenceType=1 THEN 'Once'  
               WHEN RecurrenceType=2 THEN 'Hourly'  
               WHEN RecurrenceType=3 THEN 'Daily'  
               WHEN RecurrenceType=4 and WeeksInterval <= 1 THEN 'Daily'  
               WHEN RecurrenceType=4 and WeeksInterval > 1 THEN 'Weekly'  
               WHEN RecurrenceType=5 THEN 'Calendar Daywise'  
               WHEN RecurrenceType=6 THEN 'WeekWise'  
               END  
               as 'Recurrence Sub Type'  
              ,CASE RecurrenceType  
               WHEN 2 THEN CONCAT(MinutesInterval/60, ' Hours(s) ' ,MinutesInterval%60,' Minutes(s) ')     
               ELSE ''  
               END as 'Run every (Hours)'  
              ,ISNULL(CONVERT(VARCHAR(3),DaysInterval),'')  as 'Runs every (Days)'  
              ,ISNULL(CONVERT(VARCHAR(3),WeeksInterval),'')  as 'Runs every (weeks)'  
              ,CASE WHEN Daysofweek & POWER(2, 0) = POWER(2,0) THEN 'Sun,' ELSE '' END +  
               CASE WHEN Daysofweek & POWER(2, 1) = POWER(2,1) THEN 'Mon,' ELSE '' END +  
               CASE WHEN Daysofweek & POWER(2, 2) = POWER(2,2) THEN 'Tue,' ELSE '' END +  
               CASE WHEN Daysofweek & POWER(2, 3) = POWER(2,3) THEN 'Wed,' ELSE '' END +  
               CASE WHEN Daysofweek & POWER(2, 4) = POWER(2,4) THEN 'Thu,' ELSE '' END +  
               CASE WHEN Daysofweek & POWER(2, 5) = POWER(2,5) THEN 'Fri,' ELSE '' END +  
               CASE WHEN Daysofweek & POWER(2, 6) = POWER(2,6) THEN 'Sat,' ELSE '' END  as 'Runs every (Week Days)'  
              ,CASE   
               WHEN MonthlyWeek <= 4 THEN CONVERT(VARCHAR(2),MonthlyWeek )  
               WHEN MonthlyWeek = 5 THEN 'Last'  
               ELSE ''  
               END as 'Runs every (Week of Month)'  
              ,CASE WHEN Month & POWER(2, 0) = POWER(2,0) THEN 'Jan,' ELSE '' END +  
               CASE WHEN Month & POWER(2, 1) = POWER(2,1) THEN 'Feb,' ELSE '' END +  
               CASE WHEN Month & POWER(2, 2) = POWER(2,2) THEN 'Mar,' ELSE '' END +  
               CASE WHEN Month & POWER(2, 3) = POWER(2,3) THEN 'Apr,' ELSE '' END +  
               CASE WHEN Month & POWER(2, 4) = POWER(2,4) THEN 'May,' ELSE '' END +  
               CASE WHEN Month & POWER(2, 5) = POWER(2,5) THEN 'Jun,' ELSE '' END +  
               CASE WHEN Month & POWER(2, 6) = POWER(2,6) THEN 'Jul,' ELSE '' END +  
               CASE WHEN Month & POWER(2, 7) = POWER(2,7) THEN 'Aug,' ELSE '' END +  
               CASE WHEN Month & POWER(2, 8) = POWER(2,8) THEN 'Sep,' ELSE '' END +  
               CASE WHEN Month & POWER(2, 9) = POWER(2,9) THEN 'Oct,' ELSE '' END +  
               CASE WHEN Month & POWER(2, 10) = POWER(2,10) THEN 'Nov,' ELSE '' END +   
               CASE WHEN Month & POWER(2, 11) = POWER(2,11) THEN 'Dec,' ELSE '' END      as 'Runs every (Month)'  
              ,CASE WHEN DaysOfMonth & POWER(2, 0) = POWER(2, 0) THEN '1,' ELSE '' END +  
                CASE WHEN DaysOfMonth & POWER(2, 1) = POWER(2, 1) THEN '2,' ELSE '' END +  
                CASE WHEN DaysOfMonth & POWER(2, 2) = POWER(2, 2) THEN '3,' ELSE '' END +  
                CASE WHEN DaysOfMonth & POWER(2, 3) = POWER(2, 3) THEN '4,' ELSE '' END +  
                CASE WHEN DaysOfMonth & POWER(2, 4) = POWER(2, 4) THEN '5,' ELSE '' END +  
                CASE WHEN DaysOfMonth & POWER(2, 5) = POWER(2, 5) THEN '6,' ELSE '' END +  
                CASE WHEN DaysOfMonth & POWER(2, 6) = POWER(2, 6) THEN '7,' ELSE '' END +  
                CASE WHEN DaysOfMonth & POWER(2, 7) = POWER(2, 7) THEN '8,' ELSE '' END +  
                CASE WHEN DaysOfMonth & POWER(2, 8) = POWER(2, 8) THEN '9,' ELSE '' END +  
                CASE WHEN DaysOfMonth & POWER(2, 9) = POWER(2, 9) THEN '10,' ELSE '' END +  
                CASE WHEN DaysOfMonth & POWER(2, 10) = POWER(2, 10) THEN '11,' ELSE '' END +  
                CASE WHEN DaysOfMonth & POWER(2, 11) = POWER(2, 11) THEN '12,' ELSE '' END +  
                CASE WHEN DaysOfMonth & POWER(2, 12) = POWER(2, 12) THEN '13,' ELSE '' END +  
                CASE WHEN DaysOfMonth & POWER(2, 13) = POWER(2, 13) THEN '14,' ELSE '' END +  
                CASE WHEN DaysOfMonth & POWER(2, 14) = POWER(2, 14) THEN '15,' ELSE '' END +  
                CASE WHEN DaysOfMonth & POWER(2, 15) = POWER(2, 15) THEN '16,' ELSE '' END +  
                CASE WHEN DaysOfMonth & POWER(2, 16) = POWER(2, 16) THEN '17,' ELSE '' END +  
                CASE WHEN DaysOfMonth & POWER(2, 17) = POWER(2, 17) THEN '18,' ELSE '' END +  
                CASE WHEN DaysOfMonth & POWER(2, 18) = POWER(2, 18) THEN '19,' ELSE '' END +  
                CASE WHEN DaysOfMonth & POWER(2, 19) = POWER(2, 19) THEN '20,' ELSE '' END +  
                CASE WHEN DaysOfMonth & POWER(2, 20) = POWER(2, 20) THEN '21,' ELSE '' END +  
                CASE WHEN DaysOfMonth & POWER(2, 21) = POWER(2, 21) THEN '22,' ELSE '' END +  
                CASE WHEN DaysOfMonth & POWER(2, 22) = POWER(2, 22) THEN '23,' ELSE '' END +  
                CASE WHEN DaysOfMonth & POWER(2, 23) = POWER(2, 23) THEN '24,' ELSE '' END +  
                CASE WHEN DaysOfMonth & POWER(2, 24) = POWER(2, 24) THEN '25,' ELSE '' END +  
                CASE WHEN DaysOfMonth & POWER(2, 25) = POWER(2, 25) THEN '26,' ELSE '' END +  
                CASE WHEN DaysOfMonth & POWER(2, 26) = POWER(2, 26) THEN '27,' ELSE '' END +  
                CASE WHEN DaysOfMonth & POWER(2, 27) = POWER(2, 27) THEN '28,' ELSE '' END +  
                CASE WHEN DaysOfMonth & POWER(2, 28) = POWER(2, 28) THEN '29,' ELSE '' END +  
                CASE WHEN DaysOfMonth & POWER(2, 29) = POWER(2, 29) THEN '30,' ELSE '' END +   
                CASE WHEN DaysOfMonth & POWER(2, 30) = POWER(2, 30) THEN '31,' ELSE '' END   as 'Runs every (Calendar Days)'  
               ,StartDate  
               ,NextRunTime  
               ,LastRunTime  
               ,EndDate  
               ,Recurrencetype  
          FROM Schedule  
    ) Sch  ON sch.ScheduleID=rs.scheduleID
LEFT OUTER JOIN Users u ON u.UserID = s.ownerid
ORDER BY UserID


--look for subscriptions with a certain parameter:
SELECT u.UserName AS SubscriptionOwner,s.Description AS Subscription, s.LastStatus
	,substring(s.Parameters, patindex('%<Name>TPA_ID</Name><Value>173<%',s.Parameters), 29) Parameter
	, s.LastRunTime, c.Path, c.Name [Subscription Name]
FROM Catalog c WITH (NOLOCK) INNER JOIN Subscriptions s ON c.ItemID = s.Report_OID LEFT OUTER JOIN Users u ON u.UserID = s.ownerid
WHERE s.Parameters LIKE '%TPA_ID</Name><Value>173%'


select len('<ParameterValues><ParameterValue><Name>PATH</Name><Value>')
FROM Catalog c WITH (NOLOCK) INNER JOIN Subscriptions s ON c.ItemID = s.Report_OID LEFT OUTER JOIN Users u ON u.UserID = s.ownerid
WHERE s.DeliveryExtension='Report Server FileShare'

--look for EXCEL in ExtensionSettings to identify subscriptions that render in Excel 2003 format
SELECT c.Path, LastStatus, LastRunTime from Subscriptions s LEFT JOIN Catalog C ON c.ItemID = s.Report_OID 
where ExtensionSettings LIKE '%>EXCEL<%' and year(LastRunTime)=year(getdate())
ORDER BY Path DESC

--"log on error", "failure", "access"
select  c.path, lastruntime, laststatus from subscriptions s WITH (NOLOCK) LEFT JOIN Catalog C on c.ItemID = s.Report_OID
where laststatus like '%access%' order by lastruntime desc

--windows file share subscriptions:
select c.path, c.name, lastruntime, username, s.laststatus from catalog c with (nolock) 
left join subscriptions s on c.itemid=s.report_oid left join Users u ON u.userid=s.ownerid where DeliveryExtension='Report Server FileShare' order by lastruntime desc

--view all subscriptions owned by a specific user:
SELECT c.path, LastStatus,s.ModifiedDate, LastRunTime, DeliveryExtension, UserName, Name
FROM Subscriptions s WITH (NOLOCK) LEFT JOIN Users u ON u.UserID = s.ownerid  LEFT JOIN Catalog C ON c.ItemID = s.Report_OID 
WHERE u.username LIKE '%deapodaca%' AND LastStatus <> 'disabled' order by path

--view all subscription failures:
SELECT c.path, LastStatus,s.ModifiedDate, LastRunTime, DeliveryExtension, UserName, Name
FROM Subscriptions s WITH (NOLOCK) LEFT JOIN Users u ON u.UserID = s.ownerid  LEFT JOIN Catalog C ON c.ItemID = s.Report_OID 
WHERE  LastStatus LIKE 'failure%' order by LastRunTime DESC

--find subscriptions that is throwing an error due to DaysOfWeek having a value that is not valid, look for xml tag that is not closed
SELECT  U.Username,  s.MatchData, c.path
FROM Catalog c INNER JOIN Subscriptions s ON c.ItemID = s.Report_OID 
INNER JOIN DataSource d ON c.ItemID = d.ItemID INNER JOIN Users u ON u.UserID = s.ownerid
INNER JOIN ReportSchedule rs ON c.ItemID = rs.ReportID INNER JOIN Schedule sch ON rs.ScheduleID = sch.ScheduleID
WHERE MatchData LIKE '%<DaysOfWeek>%' AND MatchData NOT LIKE '%</DaysOfWeek>%' 


--update the owner of a subscription to the reports user account:
begin transaction
update subscriptions set ownerid='E4CFD8EB-120E-4C5B-B7F5-BBFF75CA71C5' where subscriptionid='DF24CA7B-89AD-476E-B764-B3B7E13C4C35'

select @@trancount
commit transaction
rollback transaction
select * from subscriptions where subscriptionid='FABF36F7-34AA-4559-AB1D-7CA117BA3DF5'

--how can I deactivate subscriptions?  
--If I delete all SQL Server Agent jobs associated with subscriptions, they will recreate if SSRS is restarted
--they appear to recreate a couple of minutes after syspolicy_purge_history job runs
--better option is to delete them
--the reportserver tables have the necessary triggers on delete
USE ReportServer
GO
DELETE FROM ReportSchedule
GO
DELETE FROM Subscriptions
GO
DELETE FROM Schedule
GO


--find all subscriptions sent to an email address:
SELECT * FROM Subscriptions where Description like '%cross%' 
order by lastruntime desc

--if it's a data-driven subscription, the Description column will show the Description field in the subscription
SELECT * FROM Catalog c INNER JOIN Subscriptions s ON c.ItemID = s.Report_OID 
WHERE s.Description='Quarterly Cenpatico Prescriber Scorecard'

select * from users where username like '%brooks%';
*/