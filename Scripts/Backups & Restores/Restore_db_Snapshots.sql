/**script to revert to a database snapshot
 **this would be faster than doing a full database restore

Before reverting a database, consider the following:
Reverting from a database snapshot is not intended for media recovery. Unlike a regular backup set, the database snapshot is an incomplete copy of the database files. 
If either the database or the database snapshot is corrupted, reverting from a snapshot is likely to be impossible. Furthermore, even when it is possible, reverting in the 
event of corruption is unlikely to correct the problem.
During a revert operation, both the snapshot and the source database are unavailable. The source database and snapshot are both marked "In restore." If an error occurs during 
the revert operation, when the database starts up again, the revert operation will try to finish reverting.
Because a successful revert operation automatically rebuilds the log, Microsoft recommends that you back up the log before reverting a database. Although you cannot restore the 
original log to roll forward the database, the information in the original log file can be useful for reconstructing lost data.
Reverting breaks the log backup chain. Therefore, before you can take log backups of the reverted database, you must first take a full database backup or file backup. Microsoft 
recommends a full database backup.

Reverting overwrites updates made to the source database since the snapshot was created by copying the copy-on-write pages from the sparse files back into the database. Only the 
updated pages are overwritten. The revert operation then overwrites the old log file and rebuilds the log. Consequently, you cannot later roll the reverted database forward to 
the point of user error, and any updates to the database since the snapshot's creation are lost. The metadata of a reverted database is the same as the metadata at the time of 
the snapshot.


Restrictions:
The source database contains any read-only or compressed filegroups.
Any files are offline that were online when the snapshot was created.
More than one snapshot of the database currently exists.  Drop all unwanted snapshots before reverting.


--view all snapshots of a database:
SELECT name,database_id,source_database_id FROM sys.databases
WHERE source_database_id=5

--drop any unwanted snapshots:
DROP DATABASE  Datamart_Snapshot;  --can use IF EXISTS condition in SQL Server 2016 and newer

--restore snapshot:
RESTORE DATABASE Datamart FROM DATABASE_SNAPSHOT='Datamart_Snapshot';

*/