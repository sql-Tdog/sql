/****Full Text Search***************************************************
Full-Text Search in SQL Server lets users and applications run full-text queries against character-based data in SQL Server tables. 
Before you can run full-text queries on a table, the database administrator must create a full-text index on the table. The full-text index 
includes one or more character-based columns in the table. These columns can have any of the following data types: char, varchar, nchar, nvarchar, 
text, ntext, image, xml, or varbinary(max) and FILESTREAM. Each full-text index indexes one or more columns from the table, and each column can use a specific language.

Full-text search architecture consists of the following processes:
The SQL Server process (sqlservr.exe).
The filter daemon host process (fdhost.exe).

To Set up Full-Text Search:
1.  Create a full-text catalog to store full-text indexes.
Each full-text index must belong to a full-text catalog. You can create a separate text catalog for each full-text index, or you can associate multiple full-text indexes with a 
given catalog. A full-text catalog is a virtual object and does not belong to any filegroup. The catalog is a logical concept that refers to a group of full-text indexes.
2.  Create a full-text index on the table or indexed view.
A full-text index is a special type of token-based functional index that is built and maintained by the Full-Text Engine. To create full-text search on a table or view, 
it must have a unique, single-column, non-nullable index. The Full-Text Engine requires this unique index to map each row in the table to a unique, compressible key. A full-text 
index can include char, varchar, nchar, nvarchar, text, ntext, image, xml, varbinary, and varbinary(max) columns.

NOTE:
Only one full-text index allowed per table.
The addition of data to full-text indexes, called a population, can be requested through either a schedule or a specific request, or can occur automatically with the addition 
of new data.
Are grouped within the same database into one or more full-text catalogs.


The process of building a full-text index is fairly I/O intensive (on a high level, it consists of reading data from SQL Server, and then propagating the filtered data to the full-text 
index). As a best practice, locate a full-text index in the database filegroup that is best for maximizing I/O performance or locate the full-text indexes in a different filegroup on 
another volume. 

Assigning the Full-Text Index to a Full-Text Catalog:
It is important to plan the placement of full-text indexes for tables in full-text catalogs.
We recommend associating tables with the same update characteristics (such as small number of changes versus large number of changes, or tables that change frequently during a 
particular time of day) together under the same full-text catalog. By setting up full-text catalog population schedules, full-text indexes stay synchronous with the tables without 
adversely affecting the resource usage of the database server during periods of high database activity.
When you assign a table to a full-text catalog, consider the following guidelines:
*Always select the smallest unique index available for your full-text unique key. (A 4-byte, integer-based index is optimal.) This reduces the resources required by Microsoft Search 
service in the file system significantly. If the primary key is large (over 100 bytes), consider choosing another unique index in the table (or creating another unique index) as the 
full-text unique key. Otherwise, if the full-text unique key size exceeds the maximum size allowed (900 bytes), full-text population will not be able to proceed.
*If you are indexing a table that has millions of rows, assign the table to its own full-text catalog.
*Consider the amount of changes occurring in the tables being full-text indexed, as well as the total number of rows. If the total number of rows being changed, together with 
the numbers of rows in the table present during the last full-text population, represents millions of rows, assign the table to its own full-text catalog.


Associating a Stoplist with the Full-Text Index
A stoplist is a list of stopwords, also known as noise words. To prevent a full-text index from becoming bloated, SQL Server has a mechanism that discards commonly occurring strings 
that do not help the search. These discarded strings are called stopwords. During index creation, the Full-Text Engine omits stopwords from the full-text index. This means that 
full-text queries will not search on stopwords.
A stoplist is associated with each full-text index, and the words in that stoplist are applied to full-text queries on that index. By default, the system stoplist is associated 
with a new full-text index. However, you can create and use your own stoplist instead. 
For example, the following statement creates a new full-text stoplist by copying from the system stoplist:
CREATE FULLTEXT STOPLIST myStoplist FROM SYSTEM STOPLIST;


Updating a Full-Text Index
Like regular SQL Server indexes, full-text indexes can be automatically updated as data is modified in the associated tables. This is the default behavior. Alternatively, you can 
keep your full-text indexes up-to-date manually or at specified scheduled intervals. Populating a full-text index can be time-consuming and resource-intensive, therefore, index 
updating is usually performed as an asynchronous process that runs in the background and keeps the full-text index up to date after modifications in the base table. Updating a 
full-text index immediately after each change in the base table can be resource-intensive. Therefore, if you have a very high update/insert/delete rate, you might experience some 
degradation in query performance. If this occurs, consider scheduling manual change tracking updates to keep up with the numerous changes from time to time, rather than competing 
with queries for resources.
To monitor the population status, use either the FULLTEXTCATALOGPROPERTY or OBJECTPROPERTYEX functions. To get the catalog population status, run the following statement:
SELECT FULLTEXTCATALOGPROPERTY('AdvWksDocFTCat', 'Populatestatus');
Typically, if a full population is in progress, the result returned is 1.


--***Example:  *******************************
--First, check if Full-Text Component is installed on the server.  If not, run setup to add this feature:
SELECT SERVERPROPERTY('IsFullTextInstalled')

--Create a table for this example:
CREATE TABLE Content (RowId INT IDENTITY, Pagename varchar(20) not null primary key, URL varchar(30) not null, Description text null, Keywords varchar(4000) null)

INSERT content values ('home.asp','home.asp','This is the home page','home,SQL')
INSERT content values ('pagetwo.asp','/page2/pagetwo.asp','NT Magazine is great','second')
INSERT content values ('pagethree.asp','/page3/pagethree.asp','SQL Magazine is the greatest','third')
GO 
SELECT * FROM content;
 

--Create a full-text catalog for the table:
USE Database2
GO
CREATE FULLTEXT CATALOG DatabasenameContentCatalog;

--Create a Unique, single-column, non-nullable index on the table.  The Full-Text Engine requires this unique index to map each row in the table to a unique, compressible key
in the full-text index:
CREATE UNIQUE INDEX ui_ukContent ON content(RowId);

--create full-text index on all of the columns we want to text-search, only one allowed per table or view:
CREATE FULLTEXT INDEX ON Content(
    Pagename                        --Full-text index column name 
    --TYPE COLUMN FileExtension		--Name of column that contains file type information, this is needed when full-text column contains binary data
    Language 1033					--1033 is the LCID for English
   ,URL Language 1033
   ,Description Language 1033
)
KEY INDEX ui_ukContent ON DatabasenameContentCatalog --Unique index of the table
WITH CHANGE_TRACKING AUTO            --Population type;
, STOPLIST=SYSTEM
GO

--FREETEXT search:  This queries all full-text-enabled columns in the content table for the string 'home.'
SELECT * FROM content WHERE freetext(*,'home') 

--FREETEXT search:  This only searches the Description column and returns all matches for the string 'Magazine.'
SELECT * FROM content WHERE freetext(description,'Magazine')
 
--FREETEXT search:  Although this appears to search on the string 'SQL Mag,' it actually searches on 'SQL' or 'Mag.'
SELECT * FROM content WHERE freetext(description,'SQL Mag')
 
--FREETEXT search:  The query contains only ignored words; we've queried a noise word here. You'll find 'the' in the noise words file at \MSSQL7\FTDATA\SQLSERVER\CONFIG.
SELECT * FROM content WHERE freetext(description,'the')

--CONTAINS search:  Like the Freetext query, this searches all full-text-enabled columns for the keyword 'home.'
SELECT * FROM content WHERE contains(*,'home')
 
--CONTAINS search:  This statement queries the Description column for a word beginning with 'Magaz.' Note that the asterisk acts as a wildcard or placeholder,
--just as the percent sign (%) does with the LIKE keyword. (To make this work, you need to use single quotes on either side of the double quotes.)
SELECT * FROM content WHERE contains(Description,'"Magaz*"')

--CONTAINS search:  This search yields no results. You can't use an asterisk as a placeholder for a prefix.
SELECT * FROM content WHERE contains(Description,'"*azine"')

--CONTAINS search:  This full-text scan uses OR so that you can search for 'Magazine' or 'Great'; it also works with AND and AND NOT. 
--(Again, note the single quotes around the search criteria.)
SELECT * FROM content WHERE contains(Description,'"Magazine' Or 'Great"')
 

--CONTAINS search:  This search on the Description column finds all rows where 'NT' is near 'great'.
SELECT * FROM content WHERE CONTAINS(description, 'NT NEAR great')
 

--CONTAINS search:  This statement returns all results for 'great,' 'greatest,' 'greater,' and so on.
SELECT * FROM content WHERE contains(description, ' formsof (inflectional, great) ')
 

 --is full text search enabled on databases:
 SELECT name, is_fulltext_enabled FROM sys.databases

EXEC sys.sp_fulltext_database @action='disable';


 --to drop a catalog, the full text index must be dropped first:
 DROP FULLTEXT INDEX ON table_name;
 DROP FULLTEXT CATALOG catalog_name;

  --find all catalogs:
  SELECT fulltext_catalog_id, name FROM sys.fulltext_catalogs


  SELECT t.name AS TableName, c.name AS FTCatalogName  
FROM sys.tables t JOIN sys.fulltext_indexes i  
  ON t.object_id = i.object_id  
JOIN sys.fulltext_catalogs c  
  ON i.fulltext_catalog_id = c.fulltext_catalog_id


  SELECT display_term, column_id, document_count 
FROM sys.dm_fts_index_keywords  
  (DB_ID('AdventureWorks2008'), OBJECT_ID('ProductDocs'))
