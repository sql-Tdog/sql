/***script to work with a mounted Azure fileshare drive ***/

--check if the drive is mounted, will return 1 for "Parent Directory Exists":
EXEC xp_fileexist 'Z:\'

--this command will return something in the subdirectory if drive is mounted:
EXEC xp_dirtree 'Z:\', 1,1

--to mount:
EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
EXEC sp_configure 'xp_cmdshell',1;
GO
reconfigure;
