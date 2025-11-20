SELECT * FROM sys.traces;


--view everything a trace can track:
SELECT * FROM sys.trace_events;

--view what events the default trace is tracking
SELECT t.EventId, e.name as Event_Description
	FROM sys.fn_trace_geteventinfo(1) t JOIN sys.trace_events e ON t.eventid=e.trace_event_id
	GROUP BY t.eventid, e.name;

--get trace file name:
SELECT * FROM fn_trace_getinfo(NULL) where property=2 and traceid = 1

--copy trace contents into a temp table:
SELECT * INTO #TraceTempTable 
	FROM  fn_trace_gettable('C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Log\log_187.trc', -1)

SELECT * FROM #TraceTempTable
WHERE eventclass IN (46,47,164)

--TextData like '%monit%'
eventclass IN (46,47,164) and 
databasename='datamart' and objectid=642817352
 --objecttype='19539' --credential
 --and objectname= 'DimClaim'
order by starttime desc

select TOP 3 starttime from fn_trace_gettable('D:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Log\log_419.trc', -1)
order by starttime

select count(StartTime) from fn_trace_gettable('C:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Log\log_134.trc', -1)

DBCC SHOW_STATISTICS ('AUDIT_LOG_TRANSACTIONS','IX_AUDIT_LOG_TRANSACTION_ID')

