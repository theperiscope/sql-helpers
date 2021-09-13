SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [admin].[CreateRelationships]
AS
BEGIN

	IF EXISTS (
			SELECT *
			FROM sys.objects
			WHERE
				object_id = OBJECT_ID(N'[dbo].[Relationships]') AND
				type IN (N'U')
		)
		DROP TABLE [dbo].[Relationships]

	SELECT ConstraintName = ref.CONSTRAINT_NAME,
		   TableCatalog = fk.TABLE_CATALOG,
		   TableSchema = fk.TABLE_SCHEMA,
		   TableName = fk.TABLE_NAME,
		   ColumnName = fk_cols.COLUMN_NAME,
		   RefCatalog = pk.TABLE_CATALOG,
		   RefSchema = pk.TABLE_SCHEMA,
		   RefName = pk.TABLE_NAME,
		   RefColumnName = pk_cols.COLUMN_NAME
	INTO Relationships
	FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS ref
	INNER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS fk ON ref.CONSTRAINT_CATALOG = fk.CONSTRAINT_CATALOG
	AND ref.CONSTRAINT_SCHEMA = fk.CONSTRAINT_SCHEMA
	AND ref.CONSTRAINT_NAME = fk.CONSTRAINT_NAME
	AND fk.CONSTRAINT_TYPE = 'foreign key'
	INNER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS pk ON ref.UNIQUE_CONSTRAINT_CATALOG = pk.CONSTRAINT_CATALOG
	AND ref.UNIQUE_CONSTRAINT_SCHEMA = pk.CONSTRAINT_SCHEMA
	AND ref.UNIQUE_CONSTRAINT_NAME = pk.CONSTRAINT_NAME
	AND pk.CONSTRAINT_TYPE = 'primary key'
	INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE fk_cols ON ref.CONSTRAINT_NAME = fk_cols.CONSTRAINT_NAME
	INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE pk_cols ON pk.CONSTRAINT_NAME = pk_cols.CONSTRAINT_NAME

	ALTER TABLE dbo.Relationships ADD CONSTRAINT PK_Relationships PRIMARY KEY CLUSTERED (ConstraintName ASC)

	CREATE NONCLUSTERED INDEX IX_Relationships_RefName ON dbo.Relationships (RefName ASC)

	CREATE NONCLUSTERED INDEX IX_Relationships_TableName ON dbo.Relationships (TableName ASC)
END
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CanDeleteQueries]
	@table		  VARCHAR(128),
	@pk_to_delete INT
AS
BEGIN
	;
	WITH t (Sql, SqlCount, TableName, Dependency)
	AS
	(
		--main case
		SELECT DISTINCT CAST('select ' + r.RefColumnName + ' from [' + r.TableCatalog + '].[' + r.TableSchema + '].[' + r.TableName + '] where ' + r.ColumnName + ' = ' + CAST(@pk_to_delete AS VARCHAR) AS VARCHAR(1024)),
						CAST('select count(' + r.RefColumnName + ') as N from [' + r.TableCatalog + '].[' + r.TableSchema + '].[' + r.TableName + '] where ' + r.ColumnName + ' = ' + CAST(@pk_to_delete AS VARCHAR) AS VARCHAR(1024)),
						r.TableName,
						CAST(r.RefName + ' -> ' + r.TableName AS VARCHAR(1024))
		FROM dbo.Relationships r
		WHERE
			r.RefName = @table

		UNION ALL

		-- recursive case
		SELECT CAST('select ' + r.RefColumnName + ' from [' + r.TableCatalog + '].[' + r.TableSchema + '].[' + r.TableName + '] where ' + r.ColumnName + ' IN (' + t.Sql + ')' AS VARCHAR(1024)),
			   CAST('select count(' + r.RefColumnName + ') as N from [' + r.TableCatalog + '].[' + r.TableSchema + '].[' + r.TableName + '] where ' + r.ColumnName + ' IN (' + t.Sql + ')' AS VARCHAR(1024)),
			   r.TableName,
			   CAST(t.Dependency + ' -> ' + r.TableName AS VARCHAR(1024))
		FROM Relationships r
		INNER JOIN t ON r.RefName = t.TableName
		WHERE
			r.TableName <> t.TableName -- Jan. 27 2009 fix: recursive fields seem to create problems
	)

	--select distinct 'select ' + r.RefColumnName + ' from [' + r.RefCatalog + '].[' + r.RefSchema + '].[' + r.RefName + '] where ' + RefColumnName + ' = ' + cast(@pk_to_delete as varchar) as Sql from Relationships r where Refname = @table
	--union all
	SELECT SqlCount, TableName, Dependency FROM t
END



GO

CREATE OR ALTER PROCEDURE dbo.CanDelete
	@table		  VARCHAR(128),
	@pk_to_delete INT
AS

BEGIN

	SET NOCOUNT ON;

	DECLARE @canDeleteQueries TABLE (
			[query]		 NVARCHAR(1024),
			[table]		 VARCHAR(128),
			[dependency] VARCHAR(1024)
		);
	INSERT @canDeleteQueries
	EXECUTE dbo.CanDeleteQueries @table		   = @table,
								 @pk_to_delete = @pk_to_delete;

	BEGIN TRY

		DECLARE @query NVARCHAR(1024);

		DECLARE queryCursor CURSOR LOCAL STATIC FOR
				SELECT q.query FROM @canDeleteQueries q;

		OPEN queryCursor;
		FETCH NEXT FROM queryCursor INTO @query;

		WHILE (@@FETCH_STATUS = 0)
		BEGIN

			SET @query = REPLACE(@query, 'count(Id) as N', '@rowCount=count(1)') -- hack to get count in sp_executesql

			DECLARE @rowCount INT
			EXEC sp_executesql @stmt	 = @query,
							   @params	 = N'@rowCount INT OUTPUT',
							   @rowCount = @rowCount OUTPUT

			IF @rowCount > 0
			BEGIN
				CLOSE queryCursor;
				DEALLOCATE queryCursor;
				RETURN 0
			END

			FETCH NEXT FROM queryCursor INTO @query;
		END;

		CLOSE queryCursor;
		DEALLOCATE queryCursor;
		RETURN 1
	END TRY
	BEGIN CATCH
		DECLARE @curStatus INT;
		SET @curStatus = CURSOR_STATUS('local', 'queryCursor'); --set it to LOCAL above, if using global above change here too

		IF @curStatus >= 0
		BEGIN
			CLOSE queryCursor;
			DEALLOCATE queryCursor;
		END
		ELSE

		IF @curStatus = -1 --may have been closed already so just deallocate
		BEGIN
			DEALLOCATE objectsCur;
		END

		SELECT ERROR_NUMBER() [ErrorNumber],
			   ERROR_SEVERITY() [ErrorSeverity],
			   ERROR_STATE() [ErrorState],
			   ERROR_PROCEDURE() [ErrorProcedure],
			   ERROR_LINE() [ErrorLine],
			   ERROR_MESSAGE() [ErrorMessage];

		RETURN 0
	END CATCH

END
GO