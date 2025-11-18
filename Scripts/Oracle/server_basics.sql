--get the database name:
show parameter db_name;
select name from v$database;

--check status of database:
select status from v$instance;

--check all tablespaces in the database (containers for segments such as tables, indexes, etc.)
select tablespace_name FROM dba_tablespaces;

--check archivelog mode of database:
SELECT log_mode from v$database;

