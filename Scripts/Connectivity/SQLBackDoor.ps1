<########################################################
If SQL Services won't start post upgrade:  use trace flag 902 to bypass script upgrade mode
Every time when you try to start your sql service it also looks for script upgrades and when the script upgrade fail your service unable to start. 
So, Whenever we have such upgrade script failure issue and SQL is not getting started, we need to use trace flag 902 to start SQL.
#>
net start MSSQLSERVER /T902

