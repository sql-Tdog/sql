<#
block blob vs page blob
block blob is available for SQL Server 2016 and later and is the preferred storage
Shared Access Signature uses block blob storage (safer authorization compared to storage key)
for better backup and restore performance, backups to multiple blobs are supported
block blobs are cheaper than page blobs

blob storage limitations
page blob: 1 TB, block blob:  200GB (50,000 blocks * 4 MB MAXTRANSFERSIZE)

block blob support striping up to 64 URLs (64 stripes * 50,000 blocks * 4MB = 12.8 TB)
#>

<# 
Azure Files and Azure File Share is Azure Blob storage but with a different access API (SMB rather than HTTPS)
#>
