netstat -an |findstr -i 1433

#for SQL
Test-NetConnection localhost -port 1433
#for SQL AG:
#running the tests below will fail against all listener NICs except the current primary
#both tests should be successful against the current primary listener & primary NICs.
Test-NetConnection localhost -port 1433
Test-NetConnection localhost -port 5022

#check to make sure TCP/IP protocol is enabled on the server
#if not, "Access Denied" will be thrown when trying to connect 


#Error: The target principal name is incorrect.  Cannot generate SSPI context.
#check spn for SQL service account
#may need to just uninstall and reinstall SQL, this resolved the error