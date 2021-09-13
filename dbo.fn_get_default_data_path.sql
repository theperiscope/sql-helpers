USE master

IF OBJECT_ID('dbo.fn_get_default_data_path') IS NOT NULL
	DROP FUNCTION dbo.fn_get_default_data_path

GO

CREATE FUNCTION dbo.fn_get_default_data_path ()
RETURNS NVARCHAR(260)
AS
BEGIN
	DECLARE @instance_name		  NVARCHAR(200),
			@system_instance_name NVARCHAR(200),
			@registry_key		  NVARCHAR(512),
			@data_path			  NVARCHAR(260),
			@log_path			  NVARCHAR(260);

	SET @instance_name = COALESCE(CONVERT(NVARCHAR(20), SERVERPROPERTY('InstanceName')), 'MSSQLSERVER')

	-- sql 2005/2008 with instance
	EXEC master.dbo.xp_regread N'HKEY_LOCAL_MACHINE',
							   N'Software\Microsoft\Microsoft SQL Server\Instance Names\SQL',
							   @instance_name,
							   @system_instance_name OUTPUT;
	SET @registry_key = N'Software\Microsoft\Microsoft SQL Server\' + @system_instance_name + '\MSSQLServer';

	EXEC master.dbo.xp_regread N'HKEY_LOCAL_MACHINE',
							   @registry_key,
							   N'DefaultData',
							   @data_path OUTPUT;

	IF @data_path IS NULL -- sql 2005/2008 default instance
	BEGIN
		SET @registry_key = N'Software\Microsoft\Microsoft SQL Server\' + @system_instance_name + '\Setup';
		EXEC master.dbo.xp_regread N'HKEY_LOCAL_MACHINE',
								   @registry_key,
								   N'SQLDataRoot',
								   @data_path OUTPUT;
		SET @data_path = @data_path + '\Data';
	END

	IF @data_path IS NULL -- sql 2000 with instance
	BEGIN
		SET @registry_key = N'Software\Microsoft\Microsoft SQL Server\' + @instance_name + '\MSSQLServer';
		EXEC master.dbo.xp_regread N'HKEY_LOCAL_MACHINE',
								   @registry_key,
								   N'DefaultData',
								   @data_path OUTPUT;
	END

	IF @data_path IS NULL -- sql 2000 default instance
	BEGIN
		SET @registry_key = N'Software\Microsoft\MSSQLServer\MSSQLServer';
		EXEC master.dbo.xp_regread N'HKEY_LOCAL_MACHINE',
								   @registry_key,
								   N'DefaultData',
								   @data_path OUTPUT;
	END

	RETURN @data_path
END
GO