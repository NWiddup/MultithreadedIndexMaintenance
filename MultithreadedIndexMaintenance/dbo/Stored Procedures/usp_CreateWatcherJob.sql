CREATE PROCEDURE [dbo].[usp_CreateWatcherJob]
	@JobNameToWatch nvarchar(128)

AS

BEGIN

	Declare
		@WatcherJobName nvarchar(128)
		, @WatcherScheduleName nvarchar(128)
		, @jobId BINARY(16)
		, @schedule_id int
		, @ScheduleName nvarchar(128)
		, @WatcherJobStepCommand nvarchar(512)
		, @DBName nvarchar(256) = DB_Name()

	Select @WatcherJobName = @JobNameToWatch + '_Watcher'
		, @WatcherScheduleName = @WatcherJobName + '_Sched'
		, @WatcherJobStepCommand = N'Exec dbo.usp_WatchJob @JobNameToWatch = ''' + cast(@JobNameToWatch as nvarchar(128)) + ''''

	-- Create Watcher Job
	EXEC  msdb.dbo.sp_add_job @job_name=@WatcherJobName,
			@enabled=1, 
			@notify_level_eventlog=0, 
			@notify_level_email=2, 
			@notify_level_page=2, 
			@delete_level=0, 
			@category_name=N'Database Maintenance', 
			@owner_login_name=N'sa', @job_id = @jobId OUTPUT
	--select @jobId
	--GO
	EXEC msdb.dbo.sp_add_jobserver @job_name=@WatcherJobName
	--GO
	--USE [msdb]
	--GO
	EXEC msdb.dbo.sp_add_jobstep @job_name=@WatcherJobName, @step_name=N'WatchIndexMaint', 
			@step_id=1, 
			@cmdexec_success_code=0, 
			@on_success_action=1, 
			@on_fail_action=2, 
			@retry_attempts=0, 
			@retry_interval=0, 
			@os_run_priority=0, @subsystem=N'TSQL', 
			@command=@WatcherJobStepCommand, 
			@database_name=@DBName, 
			@flags=0
	--GO
	--USE [msdb]
	--GO
	EXEC msdb.dbo.sp_update_job @job_name=@WatcherJobName, 
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
	EXEC msdb.dbo.sp_add_jobschedule @job_name=@WatcherJobName, @name=@WatcherScheduleName, 
			@enabled=1, 
			@freq_type=8, 
			@freq_interval=64, 
			@freq_subday_type=4, 
			@freq_subday_interval=1, 
			@freq_relative_interval=0, 
			@freq_recurrence_factor=1, 
			@active_start_date=20181228, 
			@active_end_date=99991231, 
			@active_start_time=10000, 
			@active_end_time=60001, @schedule_id = @schedule_id OUTPUT
	--select @schedule_id
	--GO


END
