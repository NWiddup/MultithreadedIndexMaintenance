﻿CREATE TABLE [dbo].[Runners]
(
	[RunnerID] SMALLINT IDENTITY(1,1) NOT NULL, 
    [JobName] NVARCHAR(128) NOT NULL, 
    [JobID] UNIQUEIDENTIFIER NOT NULL, 
    [ScheduleID] INT NOT NULL, 
    [CreateDate] DATETIME NOT NULL, 
    CONSTRAINT [PK_Runners_RunnerID] PRIMARY KEY (RunnerID)
)
