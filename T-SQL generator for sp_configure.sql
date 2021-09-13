-- Good for rebuilding a SQL server from scratch

USE master
GO

SELECT 'EXEC sp_configure ''' + name + ''', ''' + CONVERT(VARCHAR(20), value_in_use) + ''';RECONFIGURE WITH OVERRIDE;'
FROM master.sys.configurations