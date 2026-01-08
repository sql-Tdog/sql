<#######Types of Storage###############
page blob: 
limited to 1 TiB: 200GB (50,000 blocks * 4 MB MAXTRANSFERSIZE)
hot tier only, more expensive than block blob storage

block blob: 
is available for SQL Server 2016 and later and is the preferred storage
is cheaper, more performant for large sequential data
supports larger backup sizes - striping up to 64 URLs (64 stripes * 50,000 blocks * 4MB = 12.8 TB)
supports different access APIs:
HTTPS for BlockBlobStorage & SMB for Azure Files and Azure File Shares
#>

<#########Account Kinds###################
BlockBlobStorage: 
hold blob containers only, must generate an SAS token for backups
Shared Access Signature uses block blob storage (safer authorization compared to storage key)
for better backup and restore performance, backups to multiple blobs are supported
must create a credential in SQL with the SAS token to take backups to URL/restore from URL

StorageV2:  
can hold both blob containers and fileshares, standard performance: HDD-based
fileshares can be mounted as drives in SQL server

FileStorage:  
hold fileshares only, premium performance, SSD-based hardware

#>
