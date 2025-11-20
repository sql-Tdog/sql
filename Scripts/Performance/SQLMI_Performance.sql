/***For SQL MI: 
IOPs are limited based on database file size

check database file size and then increase it in order to get more IOPs:
sp_helpdb database

ALTER DATABASE database MODIFY FILE (NAME='data_0',SIZE=1100GB)



*/