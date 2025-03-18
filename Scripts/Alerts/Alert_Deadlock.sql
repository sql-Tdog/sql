SET NOCOUNT ON;
CREATE TABLE #DeadLockXMLData(DeadLockXMLData XML,DeadLockNumber INT)
CREATE TABLE #DeadLockDetails(ProcessID nVARCHAR(50),HostName nVARCHAR(50),LoginName nVARCHAR(100)
,ClientApp nVARCHAR(100), Frame nVARCHAR(MAX),TSQLString nVARCHAR(MAX),DeadLockDateTime DATETIME,IsVictim TINYINT,DeadLockNumber INT)
DECLARE @DeadLockXMLData AS XML,@DeadLockNumber INT,@getInputBuffer CURSOR,@Document AS INT, @SQLString NVARCHAR (MAX),@GetDeadLocksForLastMinutes INT;
 
SET	   @GetDeadLocksForLastMinutes = 10;
 
/*INSERT THE DEADLOCKS FROM EXTENDED EVENTS TO TEMP TABLES & FILTER ONLY DEADLOCKS*/
INSERT INTO #DeadLockXMLData(DeadLockXMLData,DeadLockNumber)
SELECT  CONVERT(XML, event_data) DeadLockXMLData,ROW_NUMBER() OVER (ORDER BY Object_name) DeadLockNumber
FROM	sys.fn_xe_file_target_read_file(N'system_health*.xel', NULL, NULL, NULL)
WHERE   OBJECT_NAME = 'xml_deadlock_report'
 
/*START A CURSOR TO LOOP THROUGH ALL THE DEADLOCKS AS YOU MIGHT GET MUTLTIPLE DEADLOCK IN PRODUCTION AND YOU WOULD WANT ALL OF THEM*/
SET	   @getInputBuffer = CURSOR FOR
SELECT  DeadLockXMLData,DeadLockNumber  FROM	#DeadLockXMLData
OPEN	   @getInputBuffer
 
FETCH NEXT
FROM	   @getInputBuffer INTO @DeadLockXMLData,@DeadLockNumber
 
WHILE	@@FETCH_STATUS = 0
 
BEGIN
SET	   @Document	=   0
SET	   @SQLString	=   ''
 
EXEC	   sp_xml_preparedocument @Document OUTPUT, @DeadLockXMLData
 
/*INSERT PARSED DOCUMENT'S DATA FROM XML TO TEMP TABLE FOR READABILITY*/
INSERT INTO #DeadLockDetails(ProcessID,HostName,LoginName,ClientApp,Frame,TSQLString,DeadLockDateTime,DeadLockNumber)
SELECT  ProcessID, HostName,LoginName,ClientApp, Frame,TSQL AS  TSQLString,LastBatchCompleted,@DeadLockNumber
FROM	   OPENXML(@Document, 'event/data/value/deadlock/process-list/process')
WITH 
(
ProcessID [varchar](50) '@id',
HostName [varchar](50) '@hostname',
LoginName [varchar](50) '@loginname',
ClientApp [varchar](50) '@clientapp',
CustomerName [varchar](100) '@clientapp',
TSQL [nvarchar](4000) 'inputbuf',
Frame nVARCHAR(4000) 'executionStack/frame',
LastBatchCompleted nVARCHAR(50) '@lastbatchcompleted'
)
 
/*UPDATE THE VICTIM SPID TO HIGHLIGHT TWO QUERIES SEPARETELY, THE PROCESS (WHO CREATED THE DEADLOCK) AND THE VICTIM*/
 
UPDATE  #DeadLockDetails
SET	   IsVictim = 1
WHERE   ProcessID IN (
SELECT  ProcessID 
FROM	   OPENXML(@Document, 'event/data/value/deadlock/victim-list/victimProcess')
WITH 
(
ProcessID [varchar](50) '@id',
HostName [varchar](50) '@hostname',
LoginName [varchar](50) '@loginname',
ClientApp [varchar](50) '@clientapp',
CustomerName [varchar](100) '@clientapp',
TSQL [nvarchar](4000) 'inputbuf',
Frame nVARCHAR(4000) 'executionStack/frame',
LastBatchCompleted nVARCHAR(50) '@lastbatchcompleted'
)
)
 
EXEC sp_xml_removedocument @Document
 
FETCH NEXT
FROM	   @getInputBuffer INTO @DeadLockXMLData,@DeadLockNumber
 
END
 
CLOSE   @getInputBuffer
DEALLOCATE @getInputBuffer
 
 
/*GET ALL THE DEADLOCKS AS A RESULT IN EASY READABLE TABLE FORMAT AND ANALYZE IT FOR FURTHER OPTIMIZATION */
 
SELECT  DeadLockDateTime,HostName,LoginName,ClientApp,ISNULL(Frame,'')+' **'+ISNULL(TSQLString,'')+'**' VictimTSQL
	   ,(SELECT ISNULL(Frame,'')+' **'+ISNULL(TSQLString,'')+'**' AS TSQLString FROM #DeadLockDetails WHERE ProcessID = D.ProcessID AND ISNULL(IsVictim,0) = 0) ProcessTSQL
INTO #temp
FROM	#DeadLockDetails D
WHERE   DATEDIFF(MINUTE,DeadLockDateTime,GETDATE()) <= @GetDeadLocksForLastMinutes --AND IsVictim = 1
ORDER BY DeadLockNumber
 

DECLARE @xml NVARCHAR(MAX)
DECLARE @body NVARCHAR(MAX)

SET @xml = CAST(( SELECT DeadLockDateTime AS 'td','',HostName AS 'td','', LoginName AS 'td','', ClientApp AS 'td','', VictimTSQL AS 'td','', ProcessTSQL AS  'td'
FROM #temp 
FOR XML PATH('tr'), ELEMENTS ) AS NVARCHAR(MAX))

SET @body ='<html><body><H3>Deadlock Info</H3>
<table border = 1> 
<tr>
<th> Dead Lock Date Time </th> <th> Host Name </th> <th> Login Name </th> <th> Client App </th> <th> Victim TSQL </th> <th> Process TSQL </th></tr>'    

SET @body = @body + @xml +'</table></body></html>'



DECLARE @recipientsList varchar(8000)='tanya.nikolaychuk@kindercare.com';
DECLARE @subject varchar(300)='Alert! Deadlock on '+@@SERVERNAME;
DECLARE @mail_profile varchar(300)=(SELECT TOP 1 name FROM msdb.dbo.sysmail_profile);


--send alert only if deadlocks occurred:
IF EXISTS ( SELECT TOP 1 * FROM #temp )  BEGIN
	EXEC msdb.dbo.sp_send_dbmail
		@profile_name		= @mail_profile, 
		@recipients			= @recipientsList,
		@body				= @body,
		@body_format		= 'HTML',
		@subject			= @subject,
		@importance			= 'High' ;
END

DROP TABLE #DeadLockXMLData,#DeadLockDetails, #temp
