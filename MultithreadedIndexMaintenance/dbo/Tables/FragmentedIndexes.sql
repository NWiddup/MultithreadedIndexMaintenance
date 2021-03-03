CREATE TABLE [dbo].[FragmentedIndexes]
(
	[Id] BIGINT IDENTITY (1,1) NOT NULL, 
	[DateAdded] DATETIME NOT NULL DEFAULT GetDate(),
	[DateStarted] DATETIME NULL ,
	[DateCompleted] DATETIME NULL ,
    [DBName] VARCHAR(128) NOT NULL, 
    [SchemaName] VARCHAR(256) NOT NULL, 
    [TableName] VARCHAR(256) NOT NULL, 
    [IndexName] VARCHAR(256) NOT NULL, 
	[FragmentationPercent] DECIMAL(15,2) NOT NULL,
    [IndexID] INT NOT NULL, 
    [PageCount] INT NOT NULL, 
    [RunnerID] SMALLINT NULL, 
    [StatusID] SMALLINT NULL DEFAULT '1', 
    [CustomOrder] INT NULL, 
    CONSTRAINT [PK_FragmentedIndexes_ID] PRIMARY KEY (Id), 
)
