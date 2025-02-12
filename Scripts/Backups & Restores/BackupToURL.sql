--create a credential for backups to URL using SAS token:
--generate the token using PS and the VM's User Assigned Identity (or az-login)
CREATE CREDENTIAL [https://xxxx.blob.core.windows.net/container] WITH IDENTITY='Shared Access Signature', SECRET='sv=2023-08-03&si=DBBackup&sr=c&sig=iv5%2FiMD4GjtXGZ66ZqiHKnWAKZXmWhuNEQvtoro0SlQ%3D'


select * from sys.credentials

DROP CREDENTIAL [https://sqlbkp2euweulsto.blob.core.windows.net/dsdb]

BACKUP DATABASE Dxxx TO URL ='https://sqlbkp2euweulsto.blob.core.windows.net/dsdb/Dxx.bak' WITH COPY_ONLY;


--to troubleshoot error 50 when trying to perform a backup, try accessing a file in the container
--this one will throw "Access Denied" if firewall is not open to the container
RESTORE FILELISTONLY FROM URL = 'https://sqlbkp1euneulsto.blob.core.windows.net/dsdb/Quartz.bak'

