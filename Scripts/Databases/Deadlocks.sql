SELECT * FROM sys.databases;


USE FMSProd
GO
SELECT * FROM sys.objects where object_id=1330468164
SELECT * FROM sys.objects where object_id=523461239
SELECT * FROM sys.objects where object_id=552037398


SELECT object_id, object_name(object_id) ObjectName ,name, index_id, type_desc, fill_factor
FROM sys.indexes  WHERE  object_id=87007391


--look at locked pages:
DBCC PAGE('FMSProd',1,28496930,3) WITH TABLERESULTS  --DBCC PAGE('databasename',filenumber, pagenumber,printoption)
DBCC PAGE('FMSProd',1,28438330,3) WITH TABLERESULTS
DBCC PAGE('FMSProd',1,842432,3) WITH TABLERESULTS
DBCC PAGE('FMSProd',1,30865449,3) WITH TABLERESULTS


--look at locked KEY resource: Wait Resource KEY: 9:72057598087987200 

SELECT 
    sc.name as schema_name, 
    so.name as object_name, 
    si.name as index_name
FROM sys.partitions AS p
JOIN sys.objects as so on 
    p.object_id=so.object_id
JOIN sys.indexes as si on 
    p.index_id=si.index_id and 
    p.object_id=si.object_id
JOIN sys.schemas AS sc on 
    so.schema_id=sc.schema_id
WHERE hobt_id = 72057598066753536  ;
GO


-- an old-fashioned way to get deadlock information:  run a trace to detect all deadlocks then review the SQL Server event log
DBCC TRACEON (1222)


EXEC xp_readerrorlog 0,1,NULL,NULL,NULL,NULL,'desc'


-- new way:  Extended Events and system_health session
/*
In SQL Server 2008, Extended Events were introduced and a default Extended Events session called system_health was defined. This session 
starts automatically with the SQL Server Database Engine and collects system data to help DBAs in troubleshooting performance issues.

Actually, it collects information about any detected deadlock into XEL files. We can extract information from these files either:

using Dynamic Management views and functions;
using the function provided by Microsoft to read data from an Extended Events Session file:
 
sys.fn_xe_file_target_read_file
 
This collection is totally integrated and does not harm performances.

You will find below an example query to get deadlock XML from system_health session.

 */

-- Tested on SQL Server 2008 R2 and 2012
 
DECLARE @versionNb			int;
DECLARE @EventSessionName	       VARCHAR(256);
DECLARE @DeadlockXMLLookup		VARCHAR(4000);
DECLARE @tsql				NVARCHAR(MAX);
DECLARE @LineFeed			CHAR(2);
 
SELECT	
@LineFeed		= CHAR(13) + CHAR(10),
@versionNb		= (@@microsoftversion / 0x1000000) & 0xff,
@EventSessionName	= ISNULL(@EventSessionName,'system_health')
;
 
IF (@versionNb = 10) 
BEGIN
SET @DeadlockXMLLookup = 'XEventData.XEvent.value(''(data/value)[1]'',''VARCHAR(MAX)'')';
END;
ELSE IF(@versionNb < 10)
BEGIN
RAISERROR('Extended events do not exist in this version',12,1) WITH NOWAIT;
RETURN;
END;	
ELSE 
BEGIN 
SET @DeadlockXMLLookup = 'XEventData.XEvent.query(''(data/value/deadlock)[1]'')';
END;
 
SET @tsql = 'WITH DeadlockData' + @LineFeed + 
		'AS (' + @LineFeed +
		'    SELECT ' + @LineFeed +
		'	    CAST(target_data as xml) AS TargetData' + @LineFeed +
		'    FROM ' + @LineFeed +
		'	    sys.dm_xe_session_targets st' + @LineFeed +
		'    JOIN ' + @LineFeed +
		'	    sys.dm_xe_sessions s ' + @LineFeed +
		'    ON s.address = st.event_session_address' + @LineFeed +
		'    WHERE name   = ''' + 'system_health' + '''' + @LineFeed +
		'    AND st.target_name = ''ring_buffer'' ' + @LineFeed +
	')' + @LineFeed +
		'SELECT ' + @LineFeed +
		'    XEventData.XEvent.value(''@name'', ''varchar(100)'') as eventName,' + @LineFeed +
		'    XEventData.XEvent.value(''@timestamp'', ''datetime'') as eventDate,' + @LineFeed +
		'    CAST(' + @DeadlockXMLLookup + ' AS XML) AS DeadLockGraph ' + @LineFeed +
		'FROM ' + @LineFeed +
		'    DeadlockData' + @LineFeed +
		'CROSS APPLY ' + @LineFeed +
		'    TargetData.nodes(''//RingBufferTarget/event'') AS XEventData (XEvent)' + @LineFeed +
		'WHERE ' + @LineFeed +
		'    XEventData.XEvent.value(''@name'',''varchar(4000)'') = ''xml_deadlock_report''' + @LineFeed +
		';'
		;
EXEC sp_executesql @tsql;
 




/*
Script to get all deadlocks data:

Declaration of the variables 
 
#DeadLockXMLData to store each Dead lock XML from the extended Event
#DeadLockDetails to store deadlock process, victim and application information
@GetDeadLocksForLastMinutes For how many number of Minutes to watch for
 

SET NOCOUNT ON;
CREATE TABLE #DeadLockXMLData(DeadLockXMLData XML,DeadLockNumber INT)
CREATE TABLE #DeadLockDetails(ProcessID nVARCHAR(50),HostName nVARCHAR(50),LoginName nVARCHAR(100)
,ClientApp nVARCHAR(100), Frame nVARCHAR(MAX),TSQLString nVARCHAR(MAX),DeadLockDateTime DATETIME,IsVictim TINYINT,DeadLockNumber INT)
DECLARE @DeadLockXMLData AS XML,@DeadLockNumber INT,@getInputBuffer CURSOR,@Document AS INT, @SQLString NVARCHAR (MAX),@GetDeadLocksForLastMinutes INT;
 
SET	   @GetDeadLocksForLastMinutes = 5;
 
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
	   ,(SELECT ISNULL(Frame,'')+' **'+ISNULL(TSQLString,'')+'**' AS TSQLString FROM #DeadLockDetails WHERE DeadLockNumber = D.DeadLockNumber AND ISNULL(IsVictim,0) = 0) ProcessTSQL
FROM	#DeadLockDetails D
WHERE   DATEDIFF(MINUTE,DeadLockDateTime,GETDATE()) <= @GetDeadLocksForLastMinutes
		AND IsVictim = 1
ORDER BY DeadLockNumber
 
DROP TABLE #DeadLockXMLData,#DeadLockDetails


**/


