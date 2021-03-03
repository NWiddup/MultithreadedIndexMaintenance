CREATE PROCEDURE [dbo].[usp_GetFragmentedIndexes]

AS

BEGIN
	--Select [DBName], [SchemaName], [TableName], [IndexName], [IndexID] , [RunnerID], [StatusID], [CustomOrder] 
	Declare @SqlCmd nvarchar(max)

	-- Get all fragmented indexes on the instance to be rebuilt
	set @SqlCmd = '
	exec sp_MSforeachdb ''
		use [?]
		declare @dbid int
		
		select @dbid = database_id
		from sys.databases
		where name = DB_NAME()

		SELECT 
			''''?'''' as dbname,
			OBJECT_SCHEMA_NAME(ps.object_id),
			OBJECT_NAME(ps.object_id)
			, i.name
			, ps.avg_fragmentation_in_percent
			, i.index_id
			, ps.page_count
		from sys.dm_db_index_physical_stats(@dbid,null,null,null,null) as ps
			join sys.indexes as i
				on ps.object_id = i.object_id AND ps.index_id = i.index_id
		where avg_fragmentation_in_percent > 30 and page_count > 100 and ps.index_id > 0
		order by ps.index_id, ps.object_id
	''
'



	Insert Into dbo.FragmentedIndexes ([DBName], [SchemaName], [TableName], [IndexName], [FragmentationPercent], [IndexID], [PageCount])
		Exec (@SqlCmd)



END