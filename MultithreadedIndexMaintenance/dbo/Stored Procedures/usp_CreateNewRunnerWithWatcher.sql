CREATE PROCEDURE [dbo].[usp_CreateNewRunnerWithWatcher]

AS

BEGIN

	Declare @RunnerID int
		, @GUID uniqueidentifier
		, @JobName nvarchar(128)
		, @jobId BINARY(16)
		, @schedule_id int
		, @ScheduleName nvarchar(128)
		, @DefragCmd nvarchar(256)
		, @DBName nvarchar(256) = DB_Name()

	Select  @GUID = NEWID()
		, @JobName = 'IxMaint_' + cast(@GUID as nvarchar(128))
		, @ScheduleName = @JobName + '_Sched'
	
	--Select @JobName
	
	-- Create Runner Job
	EXEC  msdb.dbo.sp_add_job @job_name=@JobName,
			@enabled=1, 
			@notify_level_eventlog=0, 
			@notify_level_email=2, 
			@notify_level_page=2, 
			@delete_level=0, 
			@category_name=N'Database Maintenance', 
			@owner_login_name=N'sa', @job_id = @jobId OUTPUT
	--select @jobId
	--GO
	EXEC msdb.dbo.sp_add_jobserver @job_name=@JobName
	--GO
	--USE [msdb]
	--GO
	EXEC msdb.dbo.sp_add_jobstep @job_name=@JobName, @step_name=N'RunIndexMaint', 
			@step_id=1, 
			@cmdexec_success_code=0, 
			@on_success_action=1, 
			@on_fail_action=2, 
			@retry_attempts=0, 
			@retry_interval=0, 
			@os_run_priority=0, @subsystem=N'TSQL', 
			@command=N'-- Exec dbo.usp_DefragIndexes', 
			@database_name=@DBName, 
			@flags=0
	--GO
	--USE [msdb]
	--GO
	EXEC msdb.dbo.sp_update_job @job_name=@JobName, 
			@enabled=1, 
			@start_step_id=1, 
			@notify_level_eventlog=0, 
			@notify_level_email=2, 
			@notify_level_page=2, 
			@delete_level=0, 
			@description=N'', 
			@category_name=N'Database Maintenance', 
			@owner_login_name=N'sa', 
			@notify_email_operator_name=N'', 
			@notify_page_operator_name=N''
	--GO
	--USE [msdb]
	--GO
	--DECLARE 
	EXEC msdb.dbo.sp_add_jobschedule @job_name=@JobName, @name=@ScheduleName, 
			@enabled=1, 
			@freq_type=8, 
			@freq_interval=64, 
			@freq_subday_type=1, 
			@freq_subday_interval=0, 
			@freq_relative_interval=0, 
			@freq_recurrence_factor=1, 
			@active_start_date=20181228, 
			@active_end_date=99991231, 
			@active_start_time=10000, 
			@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
	--select @schedule_id
	--GO

	Insert Into dbo.Runners (JobName, JobID, ScheduleID, CreateDate)
		Select @JobName, @jobId, @schedule_id, GetDate()
	
	Select @RunnerID = RunnerID
		, @DefragCmd = N'Exec dbo.usp_DefragIndexes @RunnerID = ' + cast(RunnerID as nvarchar(10))
		From dbo.Runners
		Where JobName = @JobName

	EXEC msdb.dbo.sp_update_jobstep @job_name=@JobName,
			@step_id=1, 
			@command=@DefragCmd

	Exec dbo.usp_CreateWatcherJob
		@JobNameToWatch = @JobName
		--@RunnerID = @RunnerID, @WatchJobName = @JobName

END

