SELECT name, recovery_model_desc 
FROM sys.databases 

/**change the recovery model of a database

USE master;
ALTER DATABASE gpas_audit SET RECOVERY SIMPLE;
ALTER DATABASE ipas_audit SET RECOVERY SIMPLE;

ALTER DATABASE gpas_audit2 SET RECOVERY SIMPLE;
ALTER DATABASE gpas_audit3 SET RECOVERY SIMPLE;

ALTER DATABASE DBAWork SET RECOVERY Bulk_logged;
ALTER DATABASE DBAWork SET RECOVERY FULL;


Recommendations:
**Before switching from the full recovery or bulk-logged recovery model, back up the transaction log
**After switching between the full and bulk-logged recovery models
    *After completing the bulk operations, immediately switch back to full recovery mode.
    *After switching from the bulk-logged recovery model back to the full recovery model, back up the log. 
*/