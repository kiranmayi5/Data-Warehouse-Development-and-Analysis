

USE cis467_final_project;


SELECT * FROM categories; 

SELECT * FROM products;

SELECT * FROM suppliers;

SELECT * FROM customers;

SELECT * FROM employees;

SELECT * FROM employeeterritories;

SELECT * FROM territories;

SELECT * FROM region;

SELECT * FROM shippers;

SELECT * FROM orders;

SELECT * FROM order_details;



#get subtotal by order id
SELECT Order_Details.OrderID, ROUND(Sum((Order_Details.UnitPrice*Quantity*(1-Discount)/100)*100),2) AS Subtotal
FROM Order_Details
GROUP BY Order_Details.OrderID;

SELECT * FROM order_details WHERE orderID=10250;

SELECT *,Sum((Order_Details.UnitPrice*Quantity*(1-Discount)/100)*100) AS Subtotal
FROM order_details WHERE orderID=10250
GROUP BY Order_Details.OrderID;




#combine many tables
SELECT Orders.ShipName, Orders.ShipAddress, Orders.ShipCity, Orders.ShipRegion, Orders.ShipPostalCode, 
	Orders.ShipCountry, Orders.CustomerID, Customers.CompanyName AS CustomerName, Customers.Address, Customers.City, 
	Customers.Region, Customers.PostalCode, Customers.Country, 
	CONCAT(FirstName, ' ', LastName) AS Salesperson, 
	Orders.OrderID, Orders.OrderDate, Orders.RequiredDate, Orders.ShippedDate, Shippers.CompanyName As ShipperName, 
	Order_Details.ProductID, Products.ProductName, Order_Details.UnitPrice, Order_Details.Quantity, 
	Order_Details.Discount, 
	ROUND((Order_Details.UnitPrice*Quantity*(1-Discount)/100)*100,2) AS ExtendedPrice, Orders.Freight
FROM 	Shippers JOIN 
		(Products  JOIN 
			(
				(Employees  JOIN 
					(Customers  JOIN Orders ON Customers.CustomerID = Orders.CustomerID) 
				ON Employees.EmployeeID = Orders.EmployeeID) 
			 JOIN Order_Details ON Orders.OrderID = Order_Details.OrderID) 
		ON Products.ProductID = Order_Details.ProductID) 
	ON Shippers.ShipperID = Orders.ShipVia;



# Customer and Suppliers by City AS
SELECT City, CompanyName, ContactName, 'Customers' AS Relationship 
FROM Customers
UNION SELECT City, CompanyName, ContactName, 'Suppliers' AS Relationship
FROM Suppliers
ORDER BY City, CompanyName;

#List of products which are not discontinued
SELECT Products.*, Categories.CategoryName
FROM Categories JOIN Products ON Categories.CategoryID = Products.CategoryID
WHERE Products.Discontinued=0;

#Orders by customers
SELECT Orders.OrderID, Orders.CustomerID, Orders.EmployeeID, Orders.OrderDate, Orders.RequiredDate, 
	Orders.ShippedDate, Orders.ShipVia, Orders.Freight, Orders.ShipName, Orders.ShipAddress, Orders.ShipCity, 
	Orders.ShipRegion, Orders.ShipPostalCode, Orders.ShipCountry, 
	Customers.CompanyName, Customers.Address, Customers.City, Customers.Region, Customers.PostalCode, Customers.Country
FROM Customers JOIN Orders ON Customers.CustomerID = Orders.CustomerID;


# Products Above Average Price AS
SELECT Products.ProductName, Products.UnitPrice
FROM Products
WHERE Products.UnitPrice >(SELECT AVG(UnitPrice) From Products);

#fix the date data type
SELECT *, STR_TO_DATE(Orders.ShippedDate,"%m/%d/%Y") AS ShippedDateFixed 
FROM orders;

#Product Sales for 1997 
SELECT Categories.CategoryName, Products.ProductName, 
ROUND(Sum((Order_Details.UnitPrice*Quantity*(1-Discount)/100)*100),2) AS ProductSales, STR_TO_DATE(Orders.ShippedDate,"%m/%d/%Y")
AS ShippedDateFixed
FROM (Categories JOIN Products ON Categories.CategoryID = Products.CategoryID) 
	 JOIN (Orders 
		 JOIN Order_Details ON Orders.OrderID = Order_Details.OrderID) 
	ON Products.ProductID = Order_Details.ProductID
WHERE STR_TO_DATE(Orders.ShippedDate,"%m/%d/%Y") Between '1997-01-01' And '1997-12-31'
GROUP BY Categories.CategoryName, Products.ProductName;


CREATE DATABASE final_dw;
USE final_dw;
-- Create dimension tables
-- DimEmployee
CREATE TABLE DimEmployee (
EmployeeID int PRIMARY KEY,
LastName varchar(20) NOT NULL,
FirstName varchar(10) NOT NULL,
Title varchar(30),
TitleOfCourtesy varchar(25),
BirthDate date,
HireDate date
);
-- DimCustomer
CREATE TABLE DimCustomer (
CustomerID char(5) PRIMARY KEY,
CompanyName varchar(40) NOT NULL,
ContactName varchar(30),
ContactTitle varchar(30),
Address varchar(60),
City varchar(15),
Region varchar(15),
PostalCode varchar(10),
Country varchar(15)
);
-- DimProduct
CREATE TABLE DimProduct (
ProductID int PRIMARY KEY,
ProductName varchar(40) NOT NULL,
SupplierID int,
CategoryID int,
QuantityPerUnit varchar(20),
UnitPrice decimal(9,2) DEFAULT 0,
Discontinued bit DEFAULT 0
);
CREATE TABLE DimCategories(
CategoryID int PRIMARY KEY,
CategoryName varchar(40) NOT NULL
);
-- Fact Tables
-- FactOrders
CREATE TABLE FactOrder (
OrderID int PRIMARY KEY,
EmployeeID int,
CustomerID char(5),
OrderDate date,
Freight decimal(9,2) DEFAULT 0,
ShipName varchar(40),
ShipAddress varchar(60),
ShipCity varchar(15),
ShipRegion varchar(15),
ShipPostalCode varchar(10),
ShipCountry varchar(15),
FOREIGN KEY (EmployeeID) REFERENCES DimEmployee(EmployeeID),
FOREIGN KEY (CustomerID) REFERENCES DimCustomer(CustomerID)
);
-- FactOrderDetails
CREATE TABLE FactOrderDetails (
OrderID int,
ProductID int,
UnitPrice decimal(9,2) DEFAULT 0,
Quantity smallint DEFAULT 1,
Discount real DEFAULT 0,
FOREIGN KEY (OrderID) REFERENCES FactOrder(OrderID),
FOREIGN KEY (ProductID) REFERENCES DimProduct(ProductID)
);
-- FactProductStock
CREATE TABLE FactProductStock (
StockID int auto_increment PRIMARY KEY,
ProductID int,
UnitsInStock smallint DEFAULT 0,
UnitsOnOrder smallint DEFAULT 0,
ReorderLevel smallint DEFAULT 0,
FOREIGN KEY (ProductID) REFERENCES DimProduct(ProductID));
-- Update date formats
SET SQL_SAFE_UPDATES = 0;
UPDATE cis467_final_project.Employees
SET BirthDate = STR_TO_DATE(BirthDate, "%m/%d/%Y");
UPDATE cis467_final_project.Employees
SET HireDate = STR_TO_DATE(HireDate, "%m/%d/%Y");
UPDATE cis467_final_project.Orders
SET RequiredDate = STR_TO_DATE(RequiredDate, "%m/%d/%Y");
UPDATE cis467_final_project.Orders
SET ShippedDate = STR_TO_DATE(ShippedDate, "%m/%d/%Y");
-- Insert data into dimension and fact tables
INSERT INTO DimEmployee (EmployeeID, LastName, FirstName,Title,
TitleOfCourtesy, BirthDate, HireDate)
SELECT EmployeeID, LastName, FirstName,Title, TitleOfCourtesy, BirthDate,
HireDate
FROM cis467_final_project.Employees;
INSERT INTO DimCustomer (CustomerID, CompanyName, ContactName,
ContactTitle, Address, City, Region, PostalCode, Country)
SELECT CustomerID, CompanyName, ContactName, ContactTitle, Address, City,
Region, PostalCode, Country
FROM cis467_final_project.Customers;
INSERT INTO DimProduct (ProductID, ProductName, SupplierID, CategoryID,
QuantityPerUnit, UnitPrice, Discontinued)
SELECT ProductID, ProductName, SupplierID, CategoryID, QuantityPerUnit,
UnitPrice, Discontinued
FROM cis467_final_project.Products;
INSERT INTO DimCategories (CategoryID, CategoryName)
SELECT CategoryID, CategoryName
FROM cis467_final_project.Categories;
INSERT INTO FactOrder (OrderID, EmployeeID, CustomerID, OrderDate, Freight,
ShipName, ShipAddress, ShipCity, ShipRegion, ShipPostalCode, ShipCountry)
SELECT OrderID, EmployeeID, CustomerID, STR_TO_DATE(OrderDate,
'%m/%d/%Y'), Freight, ShipName, ShipAddress, ShipCity, ShipRegion,
ShipPostalCode, ShipCountry
FROM cis467_final_project.Orders;
INSERT INTO FactOrderDetails (OrderID, ProductID, UnitPrice, Quantity, Discount)
SELECT OrderID, ProductID, UnitPrice, Quantity, Discount
FROM cis467_final_project.Order_Details;
CREATE TABLE final_dw.all_data AS
SELECT
o.OrderID, o.OrderDate,
cu.CompanyName, cu.Country,
CONCAT (e.firstname, " ", e.lastname) as employeeName,
p.productName,
od.UnitPrice, od.Quantity, od.Discount,
ca.CategoryName
FROM FactOrder o
JOIN DimCustomer cu ON o.CustomerID = cu.CustomerID
JOIN DimEmployee e ON o.EmployeeID = e.EmployeeID
JOIN FactOrderDetails od ON o.OrderID = od.OrderID
JOIN DimProduct p ON od.ProductID = p.ProductID
JOIN DimCategories ca ON ca.CategoryID = p.categoryID;

-- Top 50 Revenue generating companies
SELECT CompanyName, SUM(UnitPrice * Quantity) AS TotalRevenue
FROM final_dw.all_data
GROUP BY CompanyName
ORDER BY TotalRevenue DESC
LIMIT 50;

-- Revenue by products generating revenue more than $10K
SELECT ProductName, SUM(UnitPrice * Quantity) AS TotalRevenue
FROM final_dw.all_data
GROUP BY ProductName
HAVING TotalRevenue > 10000
ORDER BY TotalRevenue DESC;

-- Revenue by Ship Country
SELECT fo.shipcountry, SUM(fd.unitprice * fd.quantity) AS revenue
FROM factorder fo
JOIN factorderdetails fd ON fo.orderid = fd.orderid
GROUP BY fo.shipcountry
ORDER BY revenue DESC;

-- find the company that has increase in revenue brought over the years and the amount of such;
WITH CompanyYearlyRevenue AS (
SELECT YEAR(OrderDate) AS OrderYear,CompanyName,SUM(UnitPrice * Quantity * (1 - Discount)) AS TotalRevenue
FROM all_data
GROUP BY OrderYear, CompanyName
)
SELECT OrderYear, CompanyName, CurrentYearRevenue, RevenueIncrease
FROM (SELECT CY1.OrderYear, CY1.CompanyName, CY1.TotalRevenue AS CurrentYearRevenue,
CASE
WHEN CY2.TotalRevenue IS NULL THEN 0
ELSE CY1.TotalRevenue - CY2.TotalRevenue
END AS RevenueIncrease
FROM CompanyYearlyRevenue AS CY1
LEFT JOIN CompanyYearlyRevenue AS CY2
ON CY1.CompanyName = CY2.CompanyName
AND CY1.OrderYear = CY2.OrderYear + 1
) 
AS Subquery
WHERE RevenueIncrease > 0
ORDER BY OrderYear, CurrentYearRevenue DESC;

-- find the top seller with max revenue amount in each company sales and the revenue they are bringing;
WITH ProductRevenueRanked AS (SELECT CompanyName, ProductName, SUM(UnitPrice * Quantity * (1 - Discount)) AS TotalRevenue,
RANK() OVER (PARTITION BY CompanyName ORDER BY SUM(UnitPrice * Quantity * (1 - Discount)) DESC) AS RevenueRank
FROM all_data
GROUP BY CompanyName, ProductName
)
SELECT CompanyName, ProductName, TotalRevenue
FROM ProductRevenueRanked
WHERE RevenueRank = 1;

-- Identify companies that ordered at least 3 distinct products and whose maximum Discount is greater than the average discount of all orders
SELECT CompanyName, COUNT(DISTINCT ProductName) AS TotalDistinctProducts,
MAX(Discount) AS MaxDiscount
FROM all_data
GROUP BY CompanyName
HAVING COUNT(DISTINCT ProductName) >= 3 AND MAX(Discount) > (
SELECT AVG(Discount) FROM all_data
);

-- Determine the company that has the widest range of order dates (i.e., the longest time between their first and last order), 
-- but only for those that have ordered the product with the most UnitsInStock
SELECT CompanyName, MAX(OrderDate) - MIN(OrderDate) AS DateRange
FROM all_data
WHERE ProductName = (SELECT ProductName
FROM all_data
ORDER BY UnitsInStock DESC
LIMIT 1
)
GROUP BY CompanyName
ORDER BY DateRange DESC
LIMIT 1;

-- Find products that are frequently ordered by companies who order more than the average and rank these products by total order quantity.
WITH CompanyAboveAvg AS (
-- Find companies whose total order quantity is above average.
SELECT CompanyName
FROM all_data
GROUP BY CompanyName
HAVING SUM(Quantity) > (
SELECT AVG(totalQuantity)
FROM (
SELECT SUM(Quantity) AS totalQuantity
FROM all_data
GROUP BY CompanyName
) AS CompanyTotals
)
),
FrequentlyOrderedProducts AS (
-- List products ordered by those companies
SELECT ProductName, SUM(Quantity) as TotalQuantity
FROM all_data
WHERE CompanyName IN (SELECT CompanyName FROM CompanyAboveAvg)
GROUP BY ProductName
)
-- Rank products by order quantity
SELECT ProductName, TotalQuantity,
RANK() OVER (ORDER BY TotalQuantity DESC) AS QuantityRank
FROM FrequentlyOrderedProducts
ORDER BY TotalQuantity DESC;




