
/* Clean out the current job if it exists */
IF EXISTS ( SELECT  *
                FROM    msdb..sysjobs
                WHERE   name = N'Instance - Backup Drive Remount' )
        EXEC msdb.dbo.sp_delete_job @job_name = N'Instance - Backup Drive Remount', @delete_unused_schedule = 0;

/* Some checks to see whether or not we should be deploying the job on this server */
/* Skip if it's a Managed Instance */
IF      SERVERPROPERTY('EngineEdition') = 8
BEGIN
        RAISERROR(N'  ~ Skipping job [Instance - Backup Drive Remount]', 0, 0) WITH NOWAIT;
        RETURN
END
/* Until Azure backups are configured in East US 2 & Central US, check for US East 1 & US West 3 regions*/
IF      NOT EXISTS (SELECT * FROM master.dbo.DeebCategoryName WHERE CategoryName LIKE 'Azure%') OR NOT EXISTS (
    SELECT * FROM master.dbo.DeebCategoryName WHERE CategoryName LIKE 'USWest3%' OR CategoryName LIKE 'USEast1%')
BEGIN
        RAISERROR(N'  ~ Skipping job [Instance - Backup Drive Remount] because [it is only for Azure US West 3 & East 1 VMs]', 0, 0) WITH NOWAIT;
        RETURN
END

ELSE
    BEGIN

        RAISERROR(N'  + Deploying job [Instance - Backup Drive Remount]', 0, 0) WITH NOWAIT;


        BEGIN TRANSACTION
        DECLARE @ReturnCode INT
        SELECT  @ReturnCode = 0;
        DECLARE @saname varchar(25) = SUSER_NAME(1);

        DECLARE @jobId BINARY(16)
		EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Instance - Backup Drive Remount', 
				@enabled=1, 
				@notify_level_eventlog=0, 
				@notify_level_email=0, 
				@notify_level_netsend=0, 
				@notify_level_page=0, 
				@delete_level=0, 
				@description=N'No description available.', 
				@category_name=N'Database Maintenance', 
				@owner_login_name=N'Essay', @job_id = @jobId OUTPUT
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback


		EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Remount Z drive', 
				@step_id=1, 
				@cmdexec_success_code=0, 
				@on_success_action=1, 
				@on_success_step_id=0, 
				@on_fail_action=2, 
				@on_fail_step_id=0, 
				@retry_attempts=0, 
				@retry_interval=0, 
				@os_run_priority=0, @subsystem=N'TSQL', 
				@command=N'CREATE TABLE #output (StorageAccountName varchar(200), StorageAccountKey nvarchar(max))

		IF OBJECT_ID(''dbo.BackupContainerKey'', ''U'') IS NOT NULL BEGIN
			INSERT #output EXECUTE dbo.GetBackupAccountKey @ServerInstance = @@SERVERNAME
		END

		EXEC sp_configure ''show advanced options'', 1;
		GO
		RECONFIGURE;
		GO
		EXEC sp_configure ''xp_cmdshell'',1;
		GO
		reconfigure;
		GO
		DECLARE @storageAccountName varchar(1000)=(SELECT StorageAccountName  FROM #output)
		DECLARE @fileshareURL varchar(1000) = @StorageAccountName + ''.file.core.windows.net''
		DECLARE @key varchar(1000) = (SELECT StorageAccountKey  FROM #output)
		DECLARE @stmt varchar(2000) = ''net use Z: \\''+@fileshareURL+''backups /u:localhost\''+@storageAccountName+'' ''+@key
		SELECT @stmt
		EXEC xp_cmdshell @stmt
		GO
		EXEC sp_configure ''xp_cmdshell'',0;
		GO
		reconfigure;

		DROP TABLE #output', 
				@database_name=N'master', 
				@flags=0
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
		EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
		EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'On Server Start', 
				@enabled=1, 
				@freq_type=64, 
				@freq_interval=0, 
				@freq_subday_type=0, 
				@freq_subday_interval=0, 
				@freq_relative_interval=0, 
				@freq_recurrence_factor=0, 
				@active_start_date=20250318, 
				@active_end_date=99991231, 
				@active_start_time=0, 
				@active_end_time=235959, 
				@schedule_uid=N'c69a0ed8-3fb5-432d-ad5b-17a738e29781'
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
		EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
		COMMIT TRANSACTION
		GOTO EndSave
		QuitWithRollback:
			IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
		EndSave:
	END
GO

