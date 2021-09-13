-- DATABASE
IF DB_ID('dbTest') IS NOT NULL
	DROP DATABASE dbTest;

-- TABLE
IF OBJECT_ID('dbo.tblTest', 'U') IS NOT NULL
	DROP TABLE dbo.tblTest;

-- TEMP TABLE
IF OBJECT_ID('tempdb..#tempTable1', 'U') IS NOT NULL
	DROP TABLE #tempTable1;

IF OBJECT_ID('tempdb..##tempTable2', 'U') IS NOT NULL
	DROP TABLE #tempTable2;

-- VIEW
IF OBJECT_ID('dbo.vwTest', 'view') IS NOT NULL
	DROP VIEW dbo.vwTest;

-- STORED PROCEDURE
IF OBJECT_ID('dbo.spTest', 'P') IS NOT NULL
	DROP PROCEDURE dbo.spTest;

-- TRIGGER
IF OBJECT_ID('dbo.trTest', 'TR') IS NOT NULL
	DROP TRIGGER dbo.trTest;

-- SCALAR-VALUED FUNCTION
IF OBJECT_ID(N'dbo.svfTest', N'FN') IS NOT NULL
	DROP FUNCTION dbo.svfTest;

-- INLINE TABLE-VALUED FUNCTION
IF OBJECT_ID(N'dbo.tvfTest', N'IF') IS NOT NULL
	DROP FUNCTION dbo.tvfTest;

-- MULTI-STATEMENT TABLE-VALUED FUNCTION
IF OBJECT_ID(N'dbo.tvfTest', N'TF') IS NOT NULL
	DROP FUNCTION dbo.tvfTest;

-- CONSTRAINTS (C-Check, D-Default, F-Foreign Key, PK-Primary Key, UQ-Unique Key)
IF OBJECT_ID('dbo.[CK_Test_Check_Constraint]') IS NOT NULL
	ALTER TABLE dbo.tblTest DROP CONSTRAINT CK_Test_Check_Constraint

-- INDEX
IF EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.tblTest') AND NAME = 'IX_tblTest_Index1')
	DROP INDEX [IX_tblTest_Index1] ON dbo.tblTest

-- SCHEMA
IF EXISTS (SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'testschema')
	DROP SCHEMA testschema

-- SEQUENCE (SQL Server 2012 and later)
IF EXISTS (SELECT * FROM sys.sequences WHERE NAME = N'SEQ_Test1')
	DROP SEQUENCE SEQ_Test1

-- USER-DEFINED TABLE TYPE
IF TYPE_ID(N'dbo.udfttTest') IS NOT NULL
	DROP TYPE dbo.udfttTest