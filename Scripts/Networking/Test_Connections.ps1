netstat -an |findstr -i 1433

#for SQL
Test-NetConnection localhost -port 1433
#for SQL AG:
Test-NetConnection localhost -port 5022

#check to make sure TCP/IP protocol is enabled on the server
#if not, "Access Denied" will be thrown when trying to connect 