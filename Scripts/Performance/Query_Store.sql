/*****Query Store**********************************************************************
--introduced in SQL 2016, used to store a history of executed queries for performance monitoring & tuning

--data is initially stored in memory
--after about 15 minutes, execution data is flushed to disk
--configurable interval comes with a performance hit, a balance need to be created about how often data should be saved
--new execution plans are saved faster than existing plans
--data servives across server restarts and continues to grow over time
--different from the plan cache which empties on restart
--not automatically enabled on new databases


*/

ALTER DATABASE SDGEESA SET QUERY_STORE = ON;
GO

/*
--this will create a new folder in Object Explorer under database, with reports
--to see the reports in a graphical interface, right click on the database and go to Properties, in the main tab will be a new page Query Store
--there are 3 Operation Modes available:
Off: turn Query Store off
Read Only:  read existing statistics but don't collect anymore
Read Write:  keep collecting statistics

*/
USE DBAwork
GO

--to view query store status:
SELECT * FROM sys.database_query_store_options;




