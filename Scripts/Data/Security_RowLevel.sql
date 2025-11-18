--***Row Level Security Example****************
--applies to SQL Server 2016 and newer

--Create three user accounts that will demonstrate different access capabilities.
CREATE USER Manager WITHOUT LOGIN; 
CREATE USER Sales1 WITHOUT LOGIN; 
CREATE USER Sales2 WITHOUT LOGIN; 

CREATE TABLE Sales (OrderID int, SalesRep sysname, Product varchar(10), Qty int ); 

INSERT Sales VALUES  (1, 'Sales1', 'Valve', 5),  (2, 'Sales1', 'Wheel', 2), (3, 'Sales1', 'Valve', 4), (4, 'Sales2', 'Bracket', 2),  
	(5, 'Sales2', 'Wheel', 5), (6, 'Sales2', 'Seat', 5); 

-- View the 6 rows in the table 
SELECT * FROM Sales; 


GRANT SELECT ON Sales TO Manager; 
GRANT SELECT ON Sales TO Sales1; 
GRANT SELECT ON Sales TO Sales2;


--Create a new schema, and an inline table valued function. The function returns 1 when a row in the SalesRep column is the same as the user executing
--the query (@SalesRep = USER_NAME()) or if the user executing the query is the Manager user (USER_NAME() = 'Manager').

CREATE SCHEMA Security; 
GO 

CREATE FUNCTION Security.fn_securitypredicate(@SalesRep AS sysname) 
  RETURNS TABLE 
WITH SCHEMABINDING 
AS 
  RETURN SELECT 1 AS fn_securitypredicate_result  
WHERE @SalesRep = USER_NAME() OR USER_NAME() = 'Manager';


--Create a security policy adding the function as a filter predicate. The state must be set to ON to enable the policy
CREATE SECURITY POLICY SalesFilter 
ADD FILTER PREDICATE Security.fn_securitypredicate(SalesRep) ON dbo.Sales , --will allow user to view rows when the function returns a 1
ADD BLOCK PREDICATE  Security.fn_securitypredicate(SalesRep) ON dbo.Sales AFTER UPDATE  --will block user from updating the record if function does not return a 1

WITH (STATE = ON); 

--to turn off security policy:
ALTER SECURITY POLICY SalesFilter WITH (STATE = OFF);


--Now test the filtering predicate, by selected from the Sales table as each user
EXECUTE AS USER = 'Sales1'; 
SELECT * FROM Sales;  
REVERT; 

EXECUTE AS USER = 'Sales2'; 
SELECT * FROM Sales;  
REVERT; 

EXECUTE AS USER = 'Manager'; 
SELECT * FROM Sales;  
REVERT; 

