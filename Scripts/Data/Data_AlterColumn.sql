/**to alter a column data type as quickly as possible:


1.  compress the data, rebuilding it online prevents blocking (available in Enterprise or Developer editions only)
	SQL Server will create a new index and take a quick schema lock to substitute in once it's ready

2.  alter the column, will be lightning fast

*/

ALTER TABLE dbo.Posts REBUILD WITH (DATA_COMPRESSION = ROW /* or PAGE */, ONLINE=ON);  --multithreaded

SET STATISTICS TIME, IO ON;

BEGIN TRAN
ALTER TABLE dbo.Posts ALTER COLUMN OwnerUserId BIGINT;  --will take a schema modification lock, blocking SELECT users even WITH(NOLOCK)


select count(*) from Posts

COMMIT TRAN


