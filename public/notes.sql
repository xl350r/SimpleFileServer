### join

SELECT o.DonutOrderID, ## 
c.LastName,
p.DonutName,
o.OrderQty,
p.DonutPrice
FROM uc_donutorder As o
INNER JOIN uc_donut AS p ON p.DonutID = o.DonutID
INNER JOIN uc_customer AS c ON c.CustomerID = o.CustomerID;

### view

CREATE VIEW V_Customer # view name is  case sensative
AS SELECT CustomerID,
CONCAT(FirstName , ' ',LastName) AS CustomerName,
Street,
Apt,
City,
State,
Zip,
HomePhone,
MobilePhone,
OtherPhone
FROM Customer;

###index 

CREATE INDEX I_DonutName ON Donut(DonutName);


## create table 
CREATE TABLE customerdonutorder (
DonutOrderID INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
CustomerID INT(11) NOT NULL,
DonutOrderTimestamp TIMESTAMP DEFAULT NOW(),
SpecialNotes VARCHAR(500) NULL,
FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID));
