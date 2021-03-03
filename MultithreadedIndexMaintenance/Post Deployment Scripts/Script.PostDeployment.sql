/*
Post-Deployment Script Template							
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.		
 Use SQLCMD syntax to include a file in the post-deployment script.			
 Example:      :r .\myfile.sql								
 Use SQLCMD syntax to reference a variable in the post-deployment script.		
 Example:      :setvar TableName MyTable							
               SELECT * FROM [$(TableName)]					
--------------------------------------------------------------------------------------
*/

-- Insert Reference Data for Statuses
Truncate table dbo.Statuses

SET IDENTITY_INSERT dbo.Statuses ON

Insert into dbo.Statuses (StatusID, StatusDesc)
Select 1, 'New'
Union Select 2, 'In-Progress'
Union Select 3, 'Complete'
Union Select 4, 'Error'

SET IDENTITY_INSERT dbo.Statuses OFF

-- Insert Reference Data for Maintenance Window
Truncate Table dbo.MaintenanceWindow

Insert into dbo.MaintenanceWindow (MaintDay, StartTime, EndTime)
Select 'Saturday', '01:00:00', '06:00:00'


-- Create Job to build table of Indexes needing maintenance

USE [msdb]
GO
DECLARE @jobId BINARY(16)
	, @JobName nvarchar(128) = 'IxMaintBuildTable'
EXEC  msdb.dbo.sp_add_job @job_name=@JobName, 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
EXEC msdb.dbo.sp_add_jobserver @job_name=@JobName

EXEC msdb.dbo.sp_add_jobstep @job_name=@JobName, @step_name=N'Get Indexes', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Exec dbo.usp_GetFragmentedIndexes', 
		@database_name=N'$(DatabaseName)', 
		@flags=0

EXEC msdb.dbo.sp_add_jobstep @job_name=@JobName, @step_name=N'Sort Indexes by Custom Priority', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Exec dbo.usp_SortFragmentedIndexes', 
		@database_name=N'$(DatabaseName)', 
		@flags=0

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

DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_name=@JobName, @name=N'Build Index Maint list', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=64, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20181228, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
GO
