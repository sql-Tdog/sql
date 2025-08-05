-- Verify UMI exists on the elastic job server
--Create the login:  

CREATE LOGIN UMIname FROM EXTERNAL PROVIDER;


--primary node:
USE DB_NAME
GO
CREATE USER jobuser FROM LOGIN UMIname;


GRANT ALTER ON SCHEMA::dbo TO jobuser;
GRANT CREATE TABLE TO jobuser;


--connect to elastic job server, ElasticJob database

-- Add a target group containing server(s)
EXEC ElasticJob.jobs.sp_add_target_group 'GroupName';

-- Add a server target member
EXEC jobs.sp_add_target_group_member
@target_group_name = 'GroupName',
@target_type = 'SqlServer',
@server_name = 'azserver.database.windows.net';

EXEC jobs.sp_add_target_group_member
@target_group_name = 'GroupName',
@target_type = 'SqlServer',
@server_name = 'azserver.database.windows.net';

--View the recently created target group and target group members
SELECT * FROM jobs.target_groups
SELECT * FROM jobs.target_group_members 


EXEC  jobs.sp_add_job @job_name=N'Schedule - Maintenance Jobs',
		@enabled=1

EXEC jobs.sp_add_jobstep @job_name='Schedule - Maintenance Jobs', @step_name=N'Step One',
		@step_id=1,
		@retry_attempts=0,
		@command=N'DECLARE @Jobs VARCHAR(MAX);',
		@target_group_name='GroupName'

SELECT * FROM jobs_internal.jobs

SELECT * FROM jobs_internal.job_executions e
INNER JOIN jobs_internal.jobs j ON e.job_id=j.job_id
WHERE j.name='Schedule - Maintenance Jobs'

SELECT * FROM jobs.job_executions

