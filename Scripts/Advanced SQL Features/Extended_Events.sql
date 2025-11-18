--list all event session definitions:
SELECT * FROM sys.server_event_sessions;



--return a row for each event in an event session
SELECT * FROM sys.server_event_session_events;

--view system_heath extended events
SELECT * FROM sys.server_event_session_events e
	INNER JOIN sys.server_event_sessions s ON e.event_session_id=s.event_session_id
	WHERE s.name='system_health';