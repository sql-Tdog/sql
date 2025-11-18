--Inline Table Valued Function: (treated somewhat as a view)
CREATE FUNCTION MyNS.GetUnshippedOrders()
RETURNS TABLE
AS 
RETURN SELECT a.SaleId, a.CustomerID, b.Qty
  FROM Sales.Sales a INNER JOIN Sales.SaleDetail b
    ON a.SaleId = b.SaleId
    INNER JOIN Production.Product c ON b.ProductID = c.ProductID
  WHERE a.ShipDate IS NULL
GO

--Multi Statement Table Valued Function:  equivalent to stuffing the entire contents of the SELECT statement into a table variable and then joining to that,
--thus the compiler cannot use any table statistics on the tables in the MSTVF
CREATE FUNCTION MyNS.GetLastShipped(@CustomerID INT)
RETURNS @CustomerOrder TABLE
(SaleOrderID  INT     NOT NULL,
CustomerID   INT     NOT NULL,
OrderDate    DATETIME  NOT NULL,
OrderQty    INT     NOT NULL)
AS
BEGIN
  DECLARE @MaxDate DATETIME

  SELECT @MaxDate = MAX(OrderDate)
  FROM Sales.SalesOrderHeader
  WHERE CustomerID = @CustomerID

  INSERT @CustomerOrder
  SELECT a.SalesOrderID, a.CustomerID, a.OrderDate, b.OrderQty
  FROM Sales.SalesOrderHeader a INNER JOIN Sales.SalesOrderHeader b
    ON a.SalesOrderID = b.SalesOrderID
    INNER JOIN Production.Product c ON b.ProductID = c.ProductID
  WHERE a.OrderDate = @MaxDate
    AND a.CustomerID = @CustomerID
  RETURN
END
GO

--Scalar Function:
CREATE FUNCTION dbo.fn_GetName 
  (
   @CustomerID INT
   ) 
RETURNS VARCHAR(100)
AS
BEGIN
 DECLARE @CustomerName VARCHAR(100);
 SELECT @CustomerName = PC.LastName + ', ' + PC.FirstName
 FROM Sales.Customer SC
 JOIN Sales.Individual SI
 ON SC.CustomerID = SI.CustomerID
 JOIN Person.Contact PC
 ON SI.ContactID = PC.ContactID 
 WHERE SC.CustomerID = @CustomerID
 RETURN @CustomerName
END
GO

--can use the scalar function in a select statement like this
--if the function is used in the where clause, it performs much like a cursor since it is called repeatedly to resolve the query
SELECT dbo.fn_GetName(CustomerID) 
   ,CustomerType
FROM Sales.Customer
WHERE dbo.fn_GetName(CustomerID) IS NOT NULL
GO

--if we turn this scalar function into an inline table valued function, we can use CROSS APPLY on it: (more efficient)
CREATE FUNCTION fn_GetNameTable(@CustomerID int)
RETURNS TABLE
AS 
RETURN (
 SELECT LastName + ', ' + FirstName [Customer Name]
 FROM Sales.Customer SC
 JOIN Sales.Individual SI
 ON SC.CustomerID = SI.CustomerID
 JOIN Person.Contact PC
 ON SI.ContactID = PC.ContactID 
 WHERE SC.CustomerID = @CustomerID
)

SELECT I.[Customer Name]
   ,SC.CustomerType
FROM Sales.Customer SC
CROSS APPLY fn_GetNameTable(SC.CustomerID) I