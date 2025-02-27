<#
You can remove the database from always on on the secondary server that do not have the 
same drive configuration as the primary server. This puts the database on the secondary 
server in a restoring state.
Now add the File to the primary sever.
Take a log backup on primary
Restore the log on secondary using the with move option and provide a folder that exists 
on the secondary
Now add the database back to always on secondary.
This way you don’t have to reinitialize from scratch


#>

