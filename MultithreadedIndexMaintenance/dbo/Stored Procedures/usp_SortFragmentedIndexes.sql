CREATE PROCEDURE [dbo].[usp_SortFragmentedIndexes]

AS

BEGIN

	-- set the custom sort order & RunnerID & set all indexes to "New" entries

	Declare @RunnerCount int
	Select @RunnerCount = 
		case Count(RunnerID) 
			when 0 then 1
			else Count(RunnerID)
			end
		from dbo.Runners

	update
		i
	set
		i.CustomOrder = b.RowNum,
		i.RunnerID = (b.RowNum % @RunnerCount)+1,
		i.StatusID = 1
	From
		dbo.FragmentedIndexes as i
		inner join (
			select Id, StatusID, IndexID, PageCount
				, ROW_NUMBER() OVER(partition by StatusID order by case when IndexID > 1 then 2 else 1 end, PageCount desc) as RowNum
				from dbo.FragmentedIndexes
				where DateCompleted is null) as b 
					on b.Id = i.Id


END