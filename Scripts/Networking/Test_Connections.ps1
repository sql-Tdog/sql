netstat -an |findstr -i 1433

Test-NetConnection localhost -port 1433

#check to make sure TCP/IP protocol is enabled on the server
#if not, "Access Denied" will be thrown when trying to connect 