/**

When ON, the system is in implicit transaction mode. This means that if @@TRANCOUNT = 0, any of the following Transact-SQL statements begins a new transaction. 
It is equivalent to an unseen BEGIN TRANSACTION being executed first (no unseen COMMIT TRANSACTION):
ALTER TABLE,	FETCH,	REVOKE,
BEGIN TRANSACTION,	GRANT,	SELECT (See exception below.)
CREATE,	INSERT,	TRUNCATE TABLE, DELETE,	OPEN, UPDATE, DROP

When OFF, each of the preceding T-SQL statements is bounded by an unseen BEGIN TRANSACTION AND an unseen COMMIT TRANSACTION statement. 
In other words, the transaction mode is autocommit.
**/

DECLARE @IMPLICIT_TRANSACTIONS VARCHAR(3) = 'OFF';  
IF ( (2 & @@OPTIONS) = 2 ) SET @IMPLICIT_TRANSACTIONS = 'ON';  
SELECT @IMPLICIT_TRANSACTIONS AS IMPLICIT_TRANSACTIONS; 