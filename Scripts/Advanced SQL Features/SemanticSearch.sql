/**Semantic Search**********************************************************************************************
Semantic search builds upon the existing full-text search feature in SQL Server, but enables new scenarios that extend beyond keyword searches. 
While full-text search lets you query the words in a document, semantic search lets you query the meaning of the document. Solutions that are now 
possible include automatic tag extraction, related content discovery, and hierarchical navigation across similar content. For example, you can query 
the index of key phrases to build the taxonomy for an organization, or for a corpus of documents. Or, you can query the document similarity index to 
identify resumes that match a job description.

Step-by-step, enabling Semantic Search on a column in SQL Server 2012 involves:
1.  Install the Full-Text and Semantic Extractions for Search feature
2.  Install the Microsoft Office 2010 Filter Packs and Service Pack 1
3.  Install, attach and register the semantic language database
4.  Create a full-text catalog
5.  Create a full-text index with the Statistical_Semantics option enabled

Check Whether the Semantic Language Statistics Database Is Installed (if not, run SQL server setup to add the feature):
SELECT * FROM sys.fulltext_semantic_language_statistics_database
GO

Install the Microsoft Office 2010 Filter Packs and Service Pack 1
The Microsoft Office 2010 Filter Packs contain IFilters (the DLLs used by SQL Server’s full-text indexing to extract text from various file formats, 
including those from Office 2010, but also other formats) that are not included by default. Without these additional IFilters, SQL Server Full-Text 
(and by extension, Semantic Search) only understands 50 file formats. After adding the additional filter packs, the number goes up to 157 formats.

The Microsoft Office 2010 Filter Packs can be downloaded from http://www.microsoft.com/download/en/details.aspx?id=17062 and their Service Pack 1 
from http://www.microsoft.com/download/en/details.aspx?id=26604 (for 64-bit operating systems).
If you want to index and search PDF files, you will need the Adobe IFilter from http://www.adobe.com/support/downloads/detail.jsp?ftpID=4025.
After installing the filter packs, you will need to execute a few T-SQL commands to actually let SQL Server know that additional IFilters are available:

EXEC sp_fulltext_service @action='load_os_resources', @value=1;
EXEC sp_fulltext_service 'update_languages';
EXEC sp_fulltext_service 'restart_all_fdhosts';
After running these commands, you can obtain a list of supported formats using this SQL command:

EXEC sp_help_fulltext_system_components 'filter'



Install, Attach and Register the Semantic Language Database
The semantic analysis performed by SQL Server is essentially statistical analysis of the words in the column contents that have already been indexed by Full-Text Indexing. 
This statistical analysis relies on base data which is provided as a SQL Server database. This database however is not installed on your system by default; it requires 
executing a separate installation as well as manually attaching the database files to your SQL Server instance.

The installation is found on the SQL Server installation media in a folder for your processor type:

For x86, the setup is \x86\Setup\SemanticLanguageDatabase.msi
For x64, the setup is \x64\Setup\SemanticLanguageDatabase.msi
The setup file will simply extract the MDF and LDF database files to a location of your choice. After the installation, you will attach the database to your SQL Server instance. 
You would do this like you would any other database file. You can use SSMS or T-SQL script.

Finally, you must register that database as the language statistics database using the following T-SQL command:
EXEC sp_fulltext_semantic_register_language_statistics_db @dbname = '_SemanticsDB'

Create a Full-Text Catalog
For each database where you want to perform Full-Text Indexing and semantic search, you must create at least one full-text catalog. This T-SQL command creates a Full-Text Catalog 
and sets it as the default catalog for new Full-Text Indices:
CREATE FULLTEXT CATALOG CatalogName AS DEFAULT


Create a Full-Text Index with the Statistical_Semantics Option Enabled
The last step is to create a Full-Text Index and specify that you want to use statistical semantics also:
CREATE FULLTEXT INDEX ON TableName(
    ColumnName
        LANGUAGE 1033
        Statistical_Semantics
)
KEY INDEX PK__PrimaryKey
This code creates a full-text index in the default full-text catalog for the table with name “TableName” and includes only one column: ColumnName. This code assumes that 
the column selected for the index contains the actual text data. If the column contains binary data (for example, a PDF file), you must also specify the TYPE COLUMN clause 
with the name of the column that stores the file extension. This will allow proper selection of the IFilter for that row.



