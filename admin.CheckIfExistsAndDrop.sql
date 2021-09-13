/* Object type (ones marked with '>' are supported by stored procedure):

    AF = Aggregate function (CLR)
    C = CHECK constraint
    D = DEFAULT (constraint or stand-alone)
    F = FOREIGN KEY constraint
>   FN = SQL scalar function
    FS = Assembly (CLR) scalar-function
    FT = Assembly (CLR) table-valued function
>   IF = SQL inline table-valued function
    IT = Internal table
    P = SQL Stored Procedure
    PC = Assembly (CLR) stored-procedure
    PG = Plan guide
    PK = PRIMARY KEY constraint
    R = Rule (old-style, stand-alone)
    RF = Replication-filter-procedure
    S = System base table
    SN = Synonym
    SO = Sequence object
    SQ = Service queue
    TA = Assembly (CLR) DML trigger
>   TF = SQL table-valued-function
>   TR = SQL DML trigger 
    TT = Table type
>   U = Table (user-defined)
>   UQ = UNIQUE constraint
>   V = View
    X = Extended stored procedure

Custom object types:

>   I = Index

 */

ALTER PROCEDURE admin.CheckIfExistsAndDrop
	@objectName VARCHAR(128),
	@objectType CHAR(2)
AS
BEGIN

	DECLARE @sql NVARCHAR(256) = ''

	-- custom object types
	IF @objectType = 'I'
	BEGIN

		DECLARE @p1 NVARCHAR(256)

		SELECT @p1 = '[' + OBJECT_SCHEMA_NAME(o.[object_id]) + '].[' + OBJECT_NAME(o.[object_id]) + ']'
		FROM sys.indexes o
		WHERE
			o.name = @objectName AND
			o.object_id <> 0

	    -- verify object name, we can't simply plus-together strings
		IF @p1 IS NULL
			RETURN 0;

		SELECT @sql = 'DROP INDEX ' + @objectName + ' ON ' + @p1;

	END
	ELSE
	BEGIN

	    -- verify object name, we can't simply plus-together strings
		IF OBJECT_ID(@objectName, @objectType) IS NULL
			RETURN 0;

		-- table

		IF @objectType = 'U'
			SELECT @sql = 'DROP TABLE ' + @objectName;

		-- stored procedure

		IF @objectType = 'P'
			SELECT @sql = 'DROP PROCEDURE ' + @objectName;

		-- view

		IF @objectType = 'V'
			SELECT @sql = 'DROP VIEW ' + @objectName;

		-- trigger

		IF @objectType = 'TR'
			SELECT @sql = 'DROP TRIGGER ' + @objectName;

		-- scalar valued function, inline TVF, multi-statement TVF

		IF @objectType = 'FN' OR
			@objectType = 'IF' OR
			@objectType = 'TF'
			SELECT @sql = 'DROP FUNCTION ' + @objectName;

		-- unique constraint

		IF @objectType = 'UQ'
		BEGIN
			DECLARE @parent NVARCHAR(256)

			SELECT @parent = '[' + OBJECT_SCHEMA_NAME(o.parent_object_id) + '].[' + OBJECT_NAME(o.parent_object_id) + ']'
			FROM sys.objects o
			WHERE
				o.name = @objectName AND
				o.parent_object_id <> 0

			IF @parent IS NOT NULL
				SELECT @sql = 'ALTER TABLE ' + @parent + ' DROP CONSTRAINT ' + @objectName;

		END

	END

	IF @sql IS NOT NULL
	BEGIN
		EXEC sp_executesql @sql
		PRINT @sql
	END

	RETURN 1;
END
GO

EXEC admin.CheckIfExistsAndDrop @objectName = 'UQ_User_Username',
								@objectType = 'UQ'
GO


SELECT OBJECT_SCHEMA_NAME(o.parent_object_id), OBJECT_NAME(o.parent_object_id)


ALTER TABLE dbo.[user] ADD CONSTRAINT UQ_User_Username UNIQUE NONCLUSTERED (Username)
GO


SELECT OBJECT_ID('UQ_User_Username', N'UQ')