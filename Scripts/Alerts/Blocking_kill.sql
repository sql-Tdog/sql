USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_KillBlocking_dbForge]    Script Date: 3/12/2014 6:28:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[sp_KillBlocking_dbForge] (

	@RecursiveCount int = NULL --# of times to try and kill process, default is 3
)
AS

DECLARE @count int, @spid int, @sql nvarchar(max)
SET @count = ISNULL(@RecursiveCount, 3)

while @count > 0
begin

 begin try
  set @spid = (
   select top 1 spid from sysprocesses (nolock)
   where blocked = 0 and spid in (
    select blocked from sysprocesses (nolock) where blocked <> 0
   ) and program_name like '%dbforge%' and status IN ('sleeping','dormant','suspended')
  )
  if @spid > 50
  begin
   set @sql = N'kill ' + cast(@spid as nvarchar(100))
   exec sp_executesql @sql
   --insert killed process details into a table
   INSERT INTO DBAwork.dbo.killed_dbForge_connections
	   select spid, login_time, status, hostname, program_name, cmd, loginame
	   from sysprocesses (nolock)
	   WHERE spid=@spid
  end
 end try
 begin catch
  --print 'error'
 end catch

 set @count = @count - 1
end
