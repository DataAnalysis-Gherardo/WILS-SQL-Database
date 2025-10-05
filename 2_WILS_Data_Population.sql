/* ==========================================================
   WILS PROJECT
   File: 2_WILS_Data_Population.sql
   Description:
     Inserts demo data into the WILS database for testing.
     Includes warehouses, employees, items, orders, and transactions.
   ========================================================== */

USE WILS;

SET FOREIGN_KEY_CHECKS = 0;


INSERT INTO Warehouse (Name, Address, Manager, Phone, Email, TotalCapacity, Status, CurrentInventoryLevel, ZoneCount)
VALUES
('Warehouse 1', '123 Main St, Dublin', 'Alice Johnson', '123456789', 'warehouse1@demo.com', 50000.00, 'Active', 30000.00, 10),
('Warehouse 2', '456 Elm St, Cork', 'John Smith', '987654321', 'warehouse2@demo.com', 40000.00, 'Active', 25000.00, 8),
('Warehouse 3', '789 Oak St, Galway', 'Mary Brown', '1122334455', 'warehouse3@demo.com', 60000.00, 'Inactive', 20000.00, 12);

INSERT INTO RegionalWarehouse (WarehouseID) VALUES (1), (2);

INSERT INTO CoverageZone (WarehouseID, ZoneCode, Description)
VALUES
(1, 'R14', 'East Leinster Route'),
(1, 'R15', 'West Leinster Route'),
(2, 'M20', 'Cork & Kerry Corridor'),
(2, 'M21', 'Shannon Route');

INSERT INTO CentralWarehouse (WarehouseID, HeadOfficeContact)
VALUES
(3, 'centraloffice@warehouse3.com');


INSERT INTO Employee (Name, Role, Shift, Phone, Email, WarehouseID, EmploymentType)
VALUES
('Emma O’Brien', 'Admin Assistant', 'Morning', '0831234567', 'emma.obrien@example.com', 1, 'Full-time'),
('Liam Murphy', 'Technician', 'Evening', '0839876543', 'liam.murphy@example.com', 2, 'Part-time'),
('Sophia Byrne', 'Manager', 'Morning', '0835555555', 'sophia.byrne@example.com', 3, 'Full-time');



INSERT INTO StorageLocation (WarehouseID, RackNumber, ShelfNumber, Aisle, Zone, Section, Capacity, Status, Max_WeightCapacity, ClimateControl, LastInspectionDate)
VALUES
(1, 1, 1, 'A1', 'Zone A', 'S1', 1000.00, 'empty', 1200.00, 'Temperature Controlled', '2025-01-01 10:00:00'),
(1, 1, 2, 'A2', 'Zone A', 'S2', 900.00, 'occupied', 1000.00, 'None', '2025-01-02 10:00:00'),
(2, 2, 1, 'B1', 'Zone B', 'S3', 1500.00, 'empty', 1800.00, 'Humidity Controlled', '2025-01-03 09:00:00');

INSERT INTO TransitLocation (WarehouseID, RackNumber, ShelfNumber, Aisle, Zone, Section, Capacity, Status, Temp_Stor_TimeLimit, IsTransitArea)
VALUES
(1, 1, 1, 'T1', 'Transit', 'TS1', 800.00, 'empty', 12, TRUE),
(1, 1, 2, 'T2', 'Transit', 'TS2', 900.00, 'occupied', 24, TRUE),
(2, 2, 1, 'T3', 'Transit', 'TS3', 1000.00, 'empty', 6, FALSE);


INSERT INTO Item (ItemName, SKU, Description, Weight, Dimensions, Category, Quantity, CommodityCode)
VALUES
('Milk - 2L', 'SKU-MILK2L', 'Full Fat Milk', 2.0, '10x10x25', 'Dairy', 500, 'MILK-001'),
('Laptop', 'SKU-LAPTOP', 'Portable Computer', 2.5, '35x25x3', 'Electronics', 20, 'ELEC-001');

INSERT INTO ConsumableItem (ItemID, ExpiryDate, StorageCondition, BatchNumber)
VALUES (1, '2025-01-31', 'Chilled', 'BATCH001');

INSERT INTO NonConsumableItem (ItemID, Type, StorageRequirement, StockRotationRules)
VALUES (2, 'Electronic', 'Ambient', 'FIFO');

INSERT INTO Customer (Name, Email, Phone, Address)
VALUES
('Alice Green', 'alice.green@email.com', '0831002003', '5 River St, Dublin'),
('Mark White', 'mark.white@email.com', '0831002004', '17 Hill Rd, Cork');

INSERT INTO Supplier (SupplierName, Phone, Email, Address)
VALUES
('Dairy Supplies Ltd', '018765432', 'dairy@supplies.ie', '123 Milk St, Dublin'),
('Tech Solutions Ltd', '016543210', 'tech@solutions.ie', '456 Tech Park, Cork');

INSERT INTO Orders (Date, DeliveryDate, Status, PriorityLevel, Currency, Type)
VALUES
('2025-01-10 10:00:00', '2025-01-12 09:00:00', 'Pending', 'High', 'EUR', 'Customer'),
('2025-01-11 11:00:00', '2025-01-13 15:00:00', 'Pending', 'Medium', 'EUR', 'Customer');

INSERT INTO CustomerOrder (OrderID, CustomerID, DeliveryAddress, PaymentStatus)
VALUES
(1, 1, '5 River St, Dublin', 'Unpaid'),
(2, 2, '17 Hill Rd, Cork', 'Paid');

INSERT INTO OrderItem (OrderID, ItemID, Quantity, UnitPrice, Discount, TotalPrice)
VALUES
(1, 1, 10, 1.50, 0, 15.00),
(1, 2, 1, 800.00, 5, 760.00),
(2, 2, 2, 800.00, 0, 1600.00);

-- Inbound Transaction (Milk received)
INSERT INTO Transactions (ItemID, StorageLocationID, EmployeeID, TransactionDateTime)
VALUES (1, 1, 1, '2025-01-05 08:00:00');

INSERT INTO InboundTransaction (TransactionID, SupplierID, DeliveryNote, InspectionStatus)
VALUES (1, 1, 'Delivery Note #001', 'Passed');

-- Outbound Transactions (for Orders)
INSERT INTO Transactions (ItemID, StorageLocationID, EmployeeID, TransactionDateTime)
VALUES 
(1, 1, 1, '2025-01-12 08:00:00'),
(2, 2, 2, '2025-01-12 08:15:00'),
(2, 2, 3, '2025-01-13 14:30:00');

SET FOREIGN_KEY_CHECKS = 1;

SELECT COUNT(*) AS TotalTransactions FROM Transactions;
SELECT COUNT(*) AS TotalItems FROM Item;
