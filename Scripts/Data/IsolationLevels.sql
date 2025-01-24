/****Optimistic Locking****/

/** When the READ_COMMITTED_SNAPSHOT database option is set ON, the mechanisms used to support the option are activated immediately. 
*** When setting the READ_COMMITTED_SNAPSHOT option, only the connection executing the ALTER DATABASE command is allowed in the database. 
*** There must be no other open connection in the database until ALTER DATABASE is complete. The database does not have to be in single-user mode.
*/
--
ALTER DATABASE AdventureWorks2012 SET READ_COMMITTED_SNAPSHOT ON;

