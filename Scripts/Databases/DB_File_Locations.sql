select database_id, name into #dbs from sys.databases;
alter table #dbs add rowid int identity;

create table #sum (rowid int identity, dbname varchar(20),databaseid int, [file_name] varchar(30) , physicalname varchar(300))

declare @t int, @i int, @stmt nvarchar(1000), @db varchar(25), @dbid int;
set @t=(select count(*) from sys.databases);
set @i=1;

WHILE @i<=@t BEGIN
	SELECT @db=name, @dbid=database_id FROM #dbs where rowid=@i;
	SELECT @stmt='INSERT INTO #sum select '''+@db+''', '''+convert(varchar(2),@dbid)+ ''', name, physical_name
			from '+[name] from #dbs where rowid=@i;
	SET @stmt += '.sys.database_files';
	EXECUTE sp_executesql @stmt;
	SET @i = @i+1 ;
END

--select * from #dbs
select * from #sum

drop table #dbs
drop table #sum


