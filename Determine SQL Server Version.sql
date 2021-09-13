-- Source: http://support.microsoft.com/kb/321185

-- SQL Server 2000/2005/2008
SELECT SERVERPROPERTY('productversion'), SERVERPROPERTY ('productlevel'), SERVERPROPERTY ('edition'), SERVERPROPERTY ('InstanceName'), @@VERSION

-- SQL Server 7.0/6.5
SELECT @@VERSION