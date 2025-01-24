/**scriptlets for working with strings***********


--select all rows where a column contains an upper case letter:
SELECT Description, CASE WHEN BINARY_CHECKSUM(Description) = BINARY_CHECKSUM(LOWER(Description)) THEN 0 ELSE 1 END AS DoesContainUpperCase
FROM @Table

--select the location of the first lower case letter in a string
SELECT PATINDEX('%[abcdefghijklmnopqrstuvwxyz]%',[Description]COLLATE Latin1_General_CS_AS), Description FROM sttts.MLynchT
WHERE PATINDEX('%[abcdefghijklmnopqrstuvwxyz]%',[Description] COLLATE Latin1_General_CS_AS)>0

--select location of the first upper case letter where there are at least 2 uppercase letters in a row in the string
SELECT PATINDEX('%[ABCDEFGHIJKLMNOPQRSTUVWXYZ][ABCDEFGHIJKLMNOPQRSTUVWXYZ]%',[Description]COLLATE Latin1_General_CS_AS), Description FROM sttts.MLynchT

--divide up the column
SELECT PATINDEX('%[ABCDEFGHIJKLMNOPQRSTUVWXYZ][ABCDEFGHIJKLMNOPQRSTUVWXYZ]%',[Description]COLLATE Latin1_General_CS_AS), Description
	,substring([Description],PATINDEX('%[ABCDEFGHIJKLMNOPQRSTUVWXYZ][ABCDEFGHIJKLMNOPQRSTUVWXYZ]%',[Description]COLLATE Latin1_General_CS_AS),
		len(Description)-PATINDEX('%[ABCDEFGHIJKLMNOPQRSTUVWXYZ][ABCDEFGHIJKLMNOPQRSTUVWXYZ]%',[Description]COLLATE Latin1_General_CS_AS)+1)
	,substring([Description],1, PATINDEX('%[ABCDEFGHIJKLMNOPQRSTUVWXYZ][ABCDEFGHIJKLMNOPQRSTUVWXYZ]%',[Description]COLLATE Latin1_General_CS_AS)-1)
FROM sttts.MLynchT
