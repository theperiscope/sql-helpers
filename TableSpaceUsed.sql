CREATE OR ALTER PROCEDURE dbo.TableSpaceUsed
AS
BEGIN
	-- Create the temporary table...
	CREATE TABLE #tblResults (
		[name]			 NVARCHAR(80),
		[rows]			 INT,
		[reserved]		 VARCHAR(18),
		[reserved_int]	 INT DEFAULT (0),
		[data]			 VARCHAR(18),
		[data_int]		 INT DEFAULT (0),
		[index_size]	 VARCHAR(18),
		[index_size_int] INT DEFAULT (0),
		[unused]		 VARCHAR(18),
		[unused_int]	 INT DEFAULT (0)
	)


	-- Populate the temp table...
	EXEC sp_MSforeachtable @command1 =
	  "INSERT INTO #tblResults
           ([name]],[rows]],[reserved]],[data]],[index_size]],[unused]])
          EXEC sp_spaceused '?'"

	-- Strip out the " KB" portion from the fields
	UPDATE #tblResults
	SET [reserved_int]	 = CAST(SUBSTRING([reserved], 1,
		CHARINDEX(' ', [reserved])) AS INT),
		[data_int]		 = CAST(SUBSTRING([data], 1,
		CHARINDEX(' ', [data])) AS INT),
		[index_size_int] = CAST(SUBSTRING([index_size], 1,
		CHARINDEX(' ', [index_size])) AS INT),
		[unused_int]	 = CAST(SUBSTRING([unused], 1,
		CHARINDEX(' ', [unused])) AS INT)

	-- Return the results...
	SELECT * FROM #tblResults ORDER BY [name]
END
GO

EXEC TableSpaceUsed
GO

DROP PROCEDURE dbo.TableSpaceUsed
GO