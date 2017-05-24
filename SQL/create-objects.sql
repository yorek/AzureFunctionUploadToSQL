DROP TABLE IF EXISTS dbo.[FileData]
GO

BEGIN TRY
    ALTER TABLE dbo.[File] SET (SYSTEM_VERSIONING = OFF)
END TRY
BEGIN CATCH
	-- Table does not exists: just ignoe the error
END CATCH
GO

DROP TABLE IF EXISTS dbo.[FileHistory]
GO

DROP TABLE IF EXISTS dbo.[File]
GO

CREATE TABLE dbo.[File]
(
	Id INT IDENTITY NOT NULL PRIMARY KEY,
	[Name] NVARCHAR(128) UNIQUE NOT NULL,
	[ValidFrom] DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    [ValidTo] DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
    PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo])
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.[FileHistory]))
GO

CREATE TABLE dbo.[FileData]
(
	FileId INT NOT NULL REFERENCES dbo.[File](Id),
	[FirstName] NVARCHAR(100) NOT NULL,
	[LastName] NVARCHAR(100) NOT NULL,
	[TwitterHandle] NVARCHAR(100) NOT NULL
)
GO

CREATE OR ALTER PROCEDURE dbo.SetFileMetadata
@fileName NVARCHAR(128)
AS

SET XACT_ABORT ON

BEGIN TRAN

	DELETE d FROM dbo.[FileData] d INNER JOIN dbo.[File] f ON d.FileId = f.Id WHERE f.[Name] = @fileName
	DELETE d FROM dbo.[File] d WHERE d.Name = @fileName

	INSERT INTO dbo.[File](Name) OUTPUT inserted.Id VALUES (@fileName)

COMMIT TRAN

GO

CREATE OR ALTER PROCEDURE [dbo].[BulkLoadFromAzure]
@sourceFileName NVARCHAR(100)
AS

DECLARE @fid INT;
DECLARE @fileName NVARCHAR(MAX) = REPLACE(@sourceFileName, '.csv', '');
DECLARE @bulkFile NVARCHAR(MAX) =  'csv/' + @sourceFileName;

DROP TABLE IF EXISTS #Result;

CREATE TABLE #Result(FileID INT);

INSERT INTO #Result EXEC [dbo].[SetFileMetadata] @fileName;

SELECT TOP 1 @fid = FileID  FROM #Result;

DECLARE @sql NVARCHAR(MAX);
SET @sql = N'
INSERT INTO dbo.FileData
(
	FileId,
	FirstName, 
	LastName, 	
	TwitterHandle
)
SELECT 
	FileId = ' + CAST(@fid AS NVARCHAR(9)) + ',
	FirstName, 
	LastName, 	
	TwitterHandle
FROM OPENROWSET(
	BULK ''' + @bulkFile  + ''', 
	DATA_SOURCE = ''CSV-Storage'',
	FIRSTROW=2,
	FORMATFILE=''csv/csv.fmt'',
	FORMATFILE_DATA_SOURCE = ''Storage'') as t
';
--PRINT @sql;
EXEC(@sql);
GO

