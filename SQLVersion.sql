-- You can find a complete list of the different version numbers for all of the different releases of SQL Server at
-- http://support.microsoft.com/kb/321185

SELECT @@servername + '\' + @@servicename,
	   @@version,
	   SERVERPROPERTY('productversion'),
	   SERVERPROPERTY('productlevel'),
	   SERVERPROPERTY('edition')
