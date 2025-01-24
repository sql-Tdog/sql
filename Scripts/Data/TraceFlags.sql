/***
Trace flag in SQL Server is to change certain behavior. You can think of them as an “IF” condition in SQL Server. 
To enable a trace flag, run DBCC TRACEON command
You must be a membership of sysadmin fixed server role in SQL Server if you want to enable or disable
First parameter is the flag # 
Second parameter defines the scope of the trace flag. 
	If value is 0 or not supplied it enabled only for the session where the query was run.
	If value is specified as -1 then it would be enabled for all sessions on the SQL instance.
	
*/
DBCC TRACEON(1222,-1)  --used for deadlock graph printing in ERROLROG

DBCC TRACESTATUS

DBCC TRACEOFF(1222,-1)


/**Important trace flags:
Trace Flag 1222:  Write the information about resources and types of locks in an XML format.  The format has three major sections. 
		The first section declares the deadlock victim. The second section describes each process involved in the deadlock. 
		The third section describes the resources that are synonymous with nodes in trace flag 1204.
		
Trace Flag 1204: Write the information about the deadlock in a text format.  Focused on the nodes involved in the deadlock. 
		Each node has a dedicated section, and the final section describes the deadlock victim.
		
Trace Flag 7806: Enables a dedicated administrator connection on SQL Server Express Edition.

Trace Flag 1806: You can disable the instant file initialization.

Trace Flag 4616: The Application can access server level roles.

Trace Flag 3625: It limits the information for those users who are not part of the sysadmin role and it prevents sensitive information.

Trace Flag 3608: It stops the SQL Server to start automatically backup and restore for all Databases except the Master database.

Trace Flag 3226: When we are taking log backups frequently, we can avoid some unnecessary additional log information.

Trace Flag 3014: Trace more information of error log during the backup operation.

Trace Flag 3505: It disables all information about the instant file initialization.

*/