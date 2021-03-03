CREATE TABLE [dbo].[MaintenanceWindow]
(
	[Id] INT IDENTITY(1,1) NOT NULL PRIMARY KEY, 
	[MaintDay] VARCHAR(10) NOT NULL,
    [StartTime] TIME NOT NULL, 
    [EndTime] TIME NOT NULL
)
