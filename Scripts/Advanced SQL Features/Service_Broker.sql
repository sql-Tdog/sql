/*
SQL Server Service Broker  is used to send messages from the OneCMS_Prod_App database to a shared bucket where HiMama can retrieve and ingest the messages.


Service Broker Overview
Service Broker depends on five infrastructure objects in order to operate properly.  These can be queried in the context of the CMS_Prod_App database.
	1. sys.service_message_types
	2. sys.service_contracts
	3. sys.service_queues
	4. sys.services
	5. sys.endpoints

SELECT * FROM sys.service_message_types
SELECT * FROM sys.service_queues
SELECT * FROM sys.service_contracts
SELECT * FROM sys.services
SELECT * FROM sys.transmission_queue

Setting up Service Broker involves:
	1.  Enabling it at the database level:
		ALTER DATABASE CMS_APP_Prod SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
		ALTER DATABASE CMS_QA6_App SET ENABLE_BROKER;
		ALTER DATABASE CMS_APP_Prod SET MULTI_USER;

SELECT name, is_broker_enabled FROM sys. databases 


	2. Creating a message type
	3. Creating a contract for the conversation
	4. Creating queues for the communication
	5. Creating services for the communication

if Steps 2 through 5 have already been executed in a database, the information is stored within the system tables of  the database, 
therefore there is no need to ever re-create these.  If the database is ever restored on a new server, the information will remain intact.


Monitoring

	• Basic Status Check
	SQL Server provides dynamic management views, trace events, and performance objects to monitor Database Engine activity that is related to Service Broker.
	The easiest way to view Service Broker stats is by running the Service Broker Statistics report pre-configured by SQL Server in Management Studio.
	Service Broker>Reports>Service Broker Statistics
	
	The report has the following information:
		Status
		Services
		Queues
		Task Statistics


	• Service Queues
	select * from sys.service_queues
		MobileDataChangedInitiatorQueue
		MobileDataChangedTargetQueue

--check last time a queue was activated and if it has waiting tasks:
SELECT * FROM sys.databases;
SELECT q.name, q.activation_procedure, m.*  FROM sys.service_queues q inner join sys.dm_broker_queue_monitors m on q.object_id=m.queue_id;


ALTER QUEUE MobileDataChangedTargetQueue WITH ACTIVATION ( STATUS = ON )



*/		
--To check queued up messages, execute the statement below.  This is not a history of messages sent, it's only the current queue. 
		SELECT 
		        tq.message_enqueue_time,
		        tq.conversation_handle,
		        tq.priority,
		        tq.service_name,
		        CAST(tq.Message_Body as XML) AS MessageBody
		    FROM dbo.MobileDataChangedTargetQueue tq WITH (NOLOCK)
		    ORDER BY tq.message_enqueue_time DESC
		

--	• Checking Errors
SELECT TOP (1000) *  FROM [log].[Routines_Error_Log] WITH (NOLOCK)  ORDER BY LogDate DESC

/*
Troubleshooting
	1. Check to see if it the Service Broker is already enabled in the database:
		SELECT name, is_broker_enabled FROM sys.databases 


	2. After SQL Server Service Broker is enabled, restart System Center Data Access Service (OMSDK).
		a. Run cmd as an administrator:  net start healthservice/omsdk/cshost
		
	3. In SQL Server Management Studio, go to Databases > OperationsManager > Service Broker
	4. Expand Queues and Services.
	5. Verify that there's a queue and service whose name contains the following values:
		? The IP address of the management server that created the queue and service.
		? The process ID of the OMSDK service (Microsoft.Mom.Sdk.ServiceHost.exe) that's running on that management server.
	6. If you can't find the corresponding queue and service, restart the OMSDK service again. If you still can't find the queue and service, the current Service Broker may be corrupted and needs to be re-created.  For advanced troubleshooting, see https://docs.microsoft.com/en-us/troubleshoot/system-center/scom/troubleshoot-sql-server-service-broker-issues#re-create-the-sql-server-service-broker

Step 2 should resolve most Service Broker issues.

Restoring Service Broker Enabled Database
In order to restore Service Broker enabled database on a new server, restore the database with the 
ENABLE_BROKER option.  This will ensure that a new Broker Service is not set up in the database but the old one is restored and picks up where things were left off.
RESTORE ATABASE CMS_Prod_App …. WITH ENABLE_BROKER;

The following prerequisites must have already been configured on the new server:
	• SQL Ports 1433 and 4022 are open and TCP/IP is enabled

*/