-- source:    http://foxtricks.blogspot.com/2009/06/how-to-determine-default-database-path.html
-- reference: http://msdn.microsoft.com/en-us/library/ms143547.aspx
USE master

IF OBJECT_ID('dbo.fn_get_default_log_path') IS NOT NULL
	DROP FUNCTION dbo.fn_get_default_log_path

GO

CREATE FUNCTION fn_get_default_log_path ()
RETURNS NVARCHAR(260)
AS
BEGIN
	DECLARE @instance_name		  NVARCHAR(200),
			@system_instance_name NVARCHAR(200),
			@registry_key		  NVARCHAR(512),
			@data_path			  NVARCHAR(260),
			@log_path			  NVARCHAR(260);

	SET @instance_name = COALESCE(CONVERT(NVARCHAR(20), SERVERPROPERTY('InstanceName')), 'MSSQLSERVER');

	-- sql 2005/2008 instance
	EXEC master.dbo.xp_regread N'HKEY_LOCAL_MACHINE',
							   N'Software\Microsoft\Microsoft SQL Server\Instance Names\SQL',
							   @instance_name,
							   @system_instance_name OUTPUT;
	SET @registry_key = N'Software\Microsoft\Microsoft SQL Server\' + @system_instance_name + '\MSSQLServer';

	EXEC master.dbo.xp_regread N'HKEY_LOCAL_MACHINE',
							   @registry_key,
							   N'DefaultData',
							   @data_path OUTPUT;
	EXEC master.dbo.xp_regread N'HKEY_LOCAL_MACHINE',
							   @registry_key,
							   N'DefaultLog',
							   @log_path OUTPUT;

	IF @log_path IS NULL -- sql 2000 with instance
	BEGIN
		SET @registry_key = N'Software\Microsoft\Microsoft SQL Server\' + @instance_name + '\MSSQLServer';
		EXEC master.dbo.xp_regread N'HKEY_LOCAL_MACHINE',
								   @registry_key,
								   N'DefaultLog',
								   @log_path OUTPUT;
	END

	IF @log_path IS NULL -- sql 2000 default instance
	BEGIN
		SET @registry_key = N'Software\Microsoft\MSSQLServer\MSSQLServer';
		EXEC master.dbo.xp_regread N'HKEY_LOCAL_MACHINE',
								   @registry_key,
								   N'DefaultLog',
								   @log_path OUTPUT;
	END

	SELECT @data_path = dbo.fn_get_default_data_path()

	IF @log_path IS NULL
	BEGIN
		SET @log_path = @data_path
	END

	RETURN @log_path
END
GO
