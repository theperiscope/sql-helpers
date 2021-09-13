SELECT DATABASE_NAME = DB_NAME(s_mf.database_id),
	   DATABASE_SIZE = CONVERT(INT, CASE -- more than 2TB(maxint) worth of pages (by 8K each) can not fit an int...  
		 WHEN CONVERT(BIGINT, SUM(s_mf.size)) >= 268435456 THEN NULL
		 ELSE SUM(s_mf.size) * 8 -- Convert from 8192 byte pages to Kb  
	   END),
	   REMARKS = CONVERT(VARCHAR(254), NULL)
FROM sys.master_files s_mf
WHERE
	s_mf.state = 0 AND -- ONLINE  
	HAS_DBACCESS(DB_NAME(s_mf.database_id)) = 1 -- Only look at databases to which we have access  
GROUP BY
	s_mf.database_id
ORDER BY 1 ASC