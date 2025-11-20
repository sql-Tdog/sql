/**find transactions in the log that dropped tables,
 **insert into table to avoid re-running this slow query

INSERT INTO fn_dblog_results (Current_LSN, Operation, Context, TransactionId, [Description])
SELECT
    [Current LSN],
    [Operation],
    [Context],
    [Transaction ID],
    [Description]
FROM
    fn_dblog (NULL, NULL),
    (SELECT
        [Transaction ID] AS [tid]
    FROM
        fn_dblog (NULL, NULL)
    WHERE
        [Transaction Name] LIKE '%DROPOBJ%') [fd]
WHERE
    [Transaction ID] = [fd].[tid];
GO


SELECT * FROM fn_dblog_results

**/
/**who did the drop? 
 **get the transaction sid in the description field for the DROP 
 **transaction's LOP_BEGIN_XACT log record and then pass it
 **into SUSER_SNAME() function

SELECT SUSER_SNAME(0x01050000000000051500000035ed70f057219e464d2ac715f4010000)
 
 **/

/**Restoring
 **restore to just before the LSN for the LOP_BEGIN_XACT log record,
 **convert LSN to correct format
 **/
DECLARE @LSN varchar(100), @LSN_A varchar(8), @LSN_B varchar(8), @LSN_C varchar(4)
SET @LSN='00000022:000000d5:0001';

SET @LSN_A=LEFT(@LSN,8)
SET @LSN_B= SUBSTRING(@LSN,10,8);
SET @LSN_C=RIGHT(@LSN,4);

SELECT @LSN AS LSN,
       CAST( CAST( CONVERT( varbinary, @LSN_A, 2 ) AS int ) AS varchar ) +
       RIGHT( '0000000000' + CAST( CAST( CONVERT( varbinary, @LSN_B, 2 ) AS int ) AS varchar ), 10 ) +
       RIGHT( '00000'      + CAST( CAST( CONVERT( varbinary, @LSN_C, 2 ) AS int ) AS varchar ), 5 ) AS [Converted LSN]


/**sample code to do the restore:  

RESTORE DATABASE [FNDBLogTest2]
    FROM DISK = N'D:\SQLskills\FNDBLogTest_Full.bak'
WITH
    MOVE N'FNDBLogTest' TO N'C:\SQLskills\FNDBLogTest2.mdf',
    MOVE N'FNDBLogTest_log' TO N'C:\SQLskills\FNDBLogTest2_log.ldf',
    REPLACE, NORECOVERY;
GO

RESTORE LOG [FNDBLogTest2]
    FROM DISK = N'D:\SQLskills\FNDBLogTest_Log1.bak'
WITH
    NORECOVERY;
GO

RESTORE LOG [FNDBLogTest2]
FROM
    DISK = N'D:\SQLskills\FNDBLogTest_Log2.bak'
WITH
    STOPBEFOREMARK = 'lsn:157000000054200001',
    NORECOVERY;
GO

RESTORE DATABASE [FNDBLogTest2] WITH RECOVERY;
GO


**/