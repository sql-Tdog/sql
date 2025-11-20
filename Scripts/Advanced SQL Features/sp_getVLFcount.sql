-- ================================================
-- Template generated from Template Explorer using:
-- Create Procedure (New Menu).SQL
--
-- Use the Specify Values for Template Parameters
-- command (Ctrl-Shift-M) to fill in the parameter
-- values below.
--
-- This block of comments will not be included in
-- the definition of the procedure.
-- ================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:           Tatyanna Nikolaychuk
-- Create date: 02/23/2016
-- Description:      Run this procedure to get a count of VLFs in all databases
-- =============================================
CREATE PROCEDURE getVLFcount
       -- Add the parameters for the stored procedure here
AS
BEGIN
       -- SET NOCOUNT ON added to prevent extra result sets from
       -- interfering with SELECT statements.
       SET NOCOUNT ON;
 
              --get a count of VLFs:
 
              DECLARE @query varchar(1000),  @dbname varchar(1000),  @count int
 
              SET NOCOUNT ON
 
              DECLARE csr CURSOR FAST_FORWARD READ_ONLY
              FOR
              SELECT name
              FROM sys.databases
 
              CREATE TABLE ##loginfo ( dbname varchar(100), num_of_rows int)
 
              OPEN csr
 
              FETCH NEXT FROM csr INTO @dbname
 
              WHILE (@@fetch_status <> -1)
              BEGIN
 
              CREATE TABLE #log_info ( RecoveryUnitId tinyint, --RecoveryUnitId does not exist in 2008R2
              fileid tinyint, file_size bigint,
              start_offset bigint, FSeqNo int,[status] tinyint, parity tinyint, create_lsn numeric(25,0))
 
              SET @query = 'DBCC loginfo (' + '''' + @dbname + ''') '
 
              INSERT INTO #log_info
              EXEC (@query)
 
              SET @count = @@rowcount
 
              DROP TABLE #log_info
              --select * from #log_info
              INSERT ##loginfo VALUES(@dbname, @count)
 
              FETCH NEXT FROM csr INTO @dbname
 
              END
 
              CLOSE csr
              DEALLOCATE csr
 
              SELECT dbname,
              num_of_rows
              FROM ##loginfo
              --WHERE num_of_rows >= 50 --My rule of thumb is 50 VLFs. Your mileage may vary.
              ORDER BY num_of_rows desc
 
              DROP TABLE ##loginfo
 
 
END
GO
 
 