CREATE TABLE [dbo].[Statuses]
(
	[StatusID] SMALLINT IDENTITY (1,1) NOT NULL, 
    [StatusDesc] VARCHAR(128) NOT NULL, 
    CONSTRAINT [PK_Statuses_StatusID] PRIMARY KEY (StatusID)
)
