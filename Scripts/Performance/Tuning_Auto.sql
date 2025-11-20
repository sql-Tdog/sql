/*In Azure Portal, automatic indexing can be enabled in the portal under Intelligent Performance > Automatic tuning

Automatic Tuning was introduced in SQL Server 2017
Requires Query Store in read/write mode
*/
use master
go

ALTER DATABASE tn_azure SET AUTOMATIC_TUNING = AUTO; --options are AUTO, INHERIT , CUSTOM 
ALTER DATABASE tn_azure SET AUTOMATIC_TUNING ( CREATE_INDEX =  OFF);
ALTER DATABASE tn_azure SET AUTOMATIC_TUNING ( DROP_INDEX = ON );
ALTER DATABASE tn_azure SET AUTOMATIC_TUNING ( FORCE_LAST_GOOD_PLAN =  DEFAULT );

 
 /*
--FORCE_LAST_GOOD_PLAN: 
The Database Engine automatically forces the last known good plan on the Transact-SQL queries where new query plan causes performance regressions. 
The Database Engine continuously monitors query performance of the Transact-SQL query with the forced plan.
If there are performance gains, the Database Engine will keep using last known good plan. If performance gains are not detected, the Database Engine 
will produce a new query plan. The statement will fail if the Query Store isn't enabled or if the Query Store isn't in Read-Write mode.

*/


--examine the automatic tuning recommendations through a dynamic management view (DMV)
SELECT * FROM 
sys.dm_db_tuning_recommendations