CREATE PROCEDURE [dbo].[usp_DefragIndexes]
	@RunnerID int
	
AS

BEGIN

	SET NOCOUNT ON

	Declare @SqlCmd nvarchar(max)
		, @IxID int
		, @MaintDay varchar(10)
		, @MaintWindowStart time
		, @MaintWindowEnd time

	Select 
		@MaintDay = MaintDay
		, @MaintWindowStart = StartTime
		, @MaintWindowEnd = EndTime
	from dbo.MaintenanceWindow

	WHILE ( (exists (select top 1 1 from dbo.FragmentedIndexes where RunnerID = @RunnerID and StatusID = 1 and DateCompleted is null)) 
		and (cast(GetDate() as Time) between @MaintWindowStart and @MaintWindowEnd) )
	BEGIN
		-- get index to rebuild
		SELECT TOP 1 
			@IxID = [Id]
			--,[DateAdded]
			, @SqlCmd = 'use ' + quotename(DBName) + ' -- Alter Index ' +quotename(IndexName)+ ' on ' +quotename(SchemaName)+ '.' + quotename(TableName)+ ' REBUILD WITH (ONLINE = ON)'
		FROM dbo.FragmentedIndexes
		WHERE RunnerID = @RunnerID
			AND StatusID = 1
			AND DateCompleted is null
		ORDER BY CustomOrder ASC

		Update dbo.FragmentedIndexes
			set StatusID = 2
				, DateStarted = GetDate()
			where ID = @IxID
		
		Begin Try
			Print @SqlCmd
		
			Update dbo.FragmentedIndexes
				set StatusID = 3
					, DateCompleted = GetDate()
				where ID = @IxID
		End Try
		Begin Catch
			Update dbo.FragmentedIndexes
				set StatusID = 4
					, DateCompleted = GetDate()
				where ID = @IxID
		End Catch
	
	END
	
END