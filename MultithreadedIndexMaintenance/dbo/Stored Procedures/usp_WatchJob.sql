CREATE PROCEDURE [dbo].[usp_WatchJob]
	@JobNameToWatch nvarchar(128)
	, @JobRunDurationKillThreshold_Seconds int = 900
AS

BEGIN
	-- Watcher job runs every 1 minute between 0100 and 0600 on saturday morning (maintenance window) calling this procedure

	-- Watcher will kill the job if:
		-- job is still running after maintenance window end
		-- rebuild has been running for longer than @KillThreshold (default 900 seconds = 15 minutes)
			-- in this circumstance, if we are still in the maintenance window, the watcher will kick off the job again

	Declare @SqlCmd nvarchar(max)
		, @IxID int
		, @MaintDay varchar(10)
		, @MaintWindowStart time
		, @MaintWindowEnd time
		, @JobID uniqueidentifier
		, @RunnerID int
		, @program_name nvarchar(256) 

	Select @JobID = JobID
		, @RunnerID = RunnerID
		, @program_name = N'SQLAgent - TSQL JobStep (Job ' +  convert(varchar(128), cast(@JobID as varbinary(128)), 1) + N' : Step 1)'
		from dbo.Runners
		where JobName = @JobNameToWatch

	Select 
		@MaintDay = MaintDay
		, @MaintWindowStart = StartTime
		, @MaintWindowEnd = EndTime
	from dbo.MaintenanceWindow

	-- if the job is running
	IF ( exists (Select top 1 session_id from sys.dm_exec_sessions where program_name = @program_name) )
	BEGIN
		-- if we are outside the maintenance window, stop the job & mark the index it was rebuilding as "in error"
		IF ( cast(GetDate() as Time) > @MaintWindowEnd )
		BEGIN
			
			Exec msdb.dbo.sp_stop_job @job_name = @JobNameToWatch
			
			Update dbo.FragmentedIndexes
				set StatusID = 4
					, DateCompleted = GetDate()
				where RunnerID = @RunnerID
					and StatusID = 2
					and DateCompleted is null
		END
		-- if the job has been rebuilding the same index for more than @KillThreshold seconds, stop the job, mark the index it was rebuilding as "in error", and restart the job
		ELSE IF ( (Select datediff(second,[DateStarted],GetDate()) from dbo.FragmentedIndexes where RunnerID = @RunnerID and StatusID = 2 and DateCompleted is null) > @JobRunDurationKillThreshold_Seconds )
		BEGIN
			Exec msdb.dbo.sp_stop_job @job_name = @JobNameToWatch
		
			Update dbo.FragmentedIndexes
				set StatusID = 4
					, DateCompleted = GetDate()
				where RunnerID = @RunnerID
					and StatusID = 2
					and DateCompleted is null

			IF ( cast(GetDate() as Time) between @MaintWindowStart and @MaintWindowEnd )
			BEGIN
				EXEC msdb.dbo.sp_start_job  @job_name = @JobNameToWatch
			END
		END
	END
	-- if the job IS NOT running but there ARE indexes to process AND we are still in the maintenance window, start the job
	ELSE IF ( (Exists (Select top 1 1 from dbo.FragmentedIndexes where RunnerID = @RunnerID and StatusID = 1 and DateCompleted is null))
		AND (cast(GetDate() as Time) between @MaintWindowStart and @MaintWindowEnd) )
	BEGIN
		EXEC msdb.dbo.sp_start_job  @job_name = @JobNameToWatch
	END

END