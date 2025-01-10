/***************
Configure SQL Server replication for distribution databases in SQL Server
Always On Availability Groups


We can add the replication distribution database in the availability group for high availability starting from SQL Server 2017 CU6 and SQL Server 2016 SP2-CU3. It requires special considerations for adding the distribution database.

You must use a SQL listener for the distribution configuration
It creates SQL jobs with the listener’s name
It creates a new job to monitor the status of the distribution database in primary or secondary AG
SQL Server automatically disables and enables the jobs based on the primary replica. For example, if the distribution database is on the SQLAG1, jobs are enabled on the SQLAG1 instance. In the case of DB failover, jobs got disabled on the SQLAG1 and enabled on the SQLAG2 instance
The publisher and distributor database cannot exist in an instance
We cannot use merge, Peer-To-Peer replication
All replication databases (publisher, subscriber, and distributor) should be a minimum of SQL Server 2017 CU6 and SQL Server 2016 SP2-CU3
We can use both synchronous and asynchronous data synchronization for the distribution database
We cannot use the SSMS wizard for the distribution database AG configuration. It needs to set up using the scripts
We cannot use an existing distribution database for the AG configuration. If the replication is already configured, we need to break the replication first and configure it using the scripts for AG configuration
The secondary replica of the distribution database should allow read-only connections
You should use the same domain account in all replica of the distribution database AG
***************/



-- Install the Distributor and the distribution database.
DECLARE @distributor AS sysname;
DECLARE @distributionDB AS sysname;
DECLARE @publisher AS sysname;
DECLARE @directory AS nvarchar(500);
DECLARE @publicationDB AS sysname;
-- Specify the Distributor name.
SET @distributor = $(DistPubServer);
-- Specify the distribution database.
SET @distributionDB = N'distribution';
-- Specify the Publisher name.
SET @publisher = $(DistPubServer);
-- Specify the replication working directory.
SET @directory = N'\\' + $(DistPubServer) + '\repldata';
-- Specify the publication database.
SET @publicationDB = N'AdventureWorks2012'; 

-- Install the server MYDISTPUB as a Distributor using the defaults,
-- including autogenerating the distributor password.
USE master
EXEC sp_adddistributor @distributor = @distributor;

-- Create a new distribution database using the defaults, including
-- using Windows Authentication.
USE master
EXEC sp_adddistributiondb @database = @distributionDB, 
    @security_mode = 1;
GO

-- Create a Publisher and enable AdventureWorks2012 for replication.
-- Add MYDISTPUB as a publisher with MYDISTPUB as a local distributor
-- and use Windows Authentication.
DECLARE @distributionDB AS sysname;
DECLARE @publisher AS sysname;
-- Specify the distribution database.
SET @distributionDB = N'distribution';
-- Specify the Publisher name.
SET @publisher = $(DistPubServer);

USE [distribution]
EXEC sp_adddistpublisher @publisher=@publisher, 
    @distribution_db=@distributionDB, 
    @security_mode = 1;
GO 