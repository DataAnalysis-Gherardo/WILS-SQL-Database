/* ==========================================================
   WILS PROJECT (Warehouse Item Location System)
   File: 1_WILS_Database_Schema.sql
   Version: 1.0
   Author: Gherardo Frusci
   Description:
     Defines the full database structure for WILS,
     including all tables, relationships, and constraints.
   ========================================================== */

DROP DATABASE IF EXISTS WILS;
CREATE DATABASE WILS CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE WILS;

-- Superclass: Warehouse
CREATE TABLE Warehouse (
    WarehouseID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(52) NOT NULL UNIQUE,
    Address VARCHAR(255) NOT NULL,
    Manager VARCHAR(52) NOT NULL,
    Phone VARCHAR(30),
    Email VARCHAR(100),
    TotalCapacity DECIMAL(10,2) DEFAULT 0 CHECK (TotalCapacity >= 0),
    Status ENUM('Active', 'Inactive') DEFAULT 'Active',
    CurrentInventoryLevel DECIMAL(10,2) DEFAULT 0 CHECK (CurrentInventoryLevel >= 0),
    ZoneCount INT DEFAULT 0 CHECK (ZoneCount >= 0),
    IsOverCapacity BOOLEAN GENERATED ALWAYS AS (CurrentInventoryLevel > TotalCapacity) STORED
);

-- DESCRIBE warehouse; 


-- Subclass of Warehouse: RegionalWarehouse
CREATE TABLE RegionalWarehouse (
    WarehouseID INT PRIMARY KEY,
    FOREIGN KEY (WarehouseID)
        REFERENCES Warehouse (WarehouseID)
        ON DELETE CASCADE
);

-- Child of RegionalWarehouse: CoverageZone
CREATE TABLE CoverageZone (
    ZoneID INT AUTO_INCREMENT PRIMARY KEY,
    WarehouseID INT NOT NULL,
    ZoneCode VARCHAR(50) NOT NULL,
    Description VARCHAR(255),
    CONSTRAINT uq_coveragezone_wh_zone UNIQUE (WarehouseID, ZoneCode),
    FOREIGN KEY (WarehouseID)
        REFERENCES RegionalWarehouse(WarehouseID)
        ON DELETE CASCADE
);


-- Subclass of Warehouse: CentralWarehouse
CREATE TABLE CentralWarehouse (
    WarehouseID INT PRIMARY KEY,
    HeadOfficeContact VARCHAR(102) NOT NULL,
    FOREIGN KEY (WarehouseID)
        REFERENCES Warehouse (WarehouseID)
        ON DELETE CASCADE
);

-- Superclass: Employee
CREATE TABLE Employee (
    EmployeeID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    Role VARCHAR(255) NOT NULL,
    Shift ENUM('Morning', 'Evening', 'Night') DEFAULT 'Morning',
    Phone VARCHAR(30),
    Email VARCHAR(100) UNIQUE,
    WarehouseID INT NOT NULL,
    EmploymentType ENUM('Full-time', 'Part-time', 'Contract') DEFAULT 'Full-time',
    FOREIGN KEY (WarehouseID)
        REFERENCES Warehouse (WarehouseID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Subclass of Employee: AdministrationStaff
CREATE TABLE AdministrationStaff (
    EmployeeID INT PRIMARY KEY,
    OfficeLocation VARCHAR(255),
    AssignmentDepartment VARCHAR(255) DEFAULT 'Unassigned',
    FOREIGN KEY (EmployeeID)
        REFERENCES Employee (EmployeeID)
);

-- Subclass of Employee: OperationalStaff
CREATE TABLE OperationalStaff (
    EmployeeID INT PRIMARY KEY,
    AssignedZone VARCHAR(255),           
    EquipmentPermission BOOLEAN DEFAULT FALSE,
    Training BOOLEAN DEFAULT FALSE,
    Certifications VARCHAR(255),
    FOREIGN KEY (EmployeeID)
        REFERENCES Employee (EmployeeID)
);

-- Subclass of Employee: ManagementStaff
CREATE TABLE ManagementStaff (
    EmployeeID INT PRIMARY KEY,
    Location VARCHAR(255),
    KPIsManaged VARCHAR(255),
    FOREIGN KEY (EmployeeID)
        REFERENCES Employee (EmployeeID)
);


-- Child of Warehouse: StorageLocation
CREATE TABLE StorageLocation (
    LocationID INT AUTO_INCREMENT PRIMARY KEY,
    WarehouseID INT NOT NULL,
    RackNumber INT NOT NULL,
    ShelfNumber INT NOT NULL,
    Aisle VARCHAR(10) NOT NULL,
    Zone VARCHAR(20) NOT NULL,
    Section VARCHAR(10) NOT NULL,
    Capacity DECIMAL(10,2) NOT NULL CHECK (Capacity > 0 AND Capacity <= 2500),
    Status ENUM('occupied', 'empty', 'damaged', 'blocked') DEFAULT 'empty',
    Max_WeightCapacity DECIMAL(10,2) NOT NULL CHECK (Max_WeightCapacity > 0 AND Max_WeightCapacity <= 2500),
    ClimateControl ENUM('Temperature Controlled', 'Humidity Controlled', 'None') DEFAULT 'None',
    LastInspectionDate DATETIME NULL,
    BinCode VARCHAR(64)
        GENERATED ALWAYS AS (
            CONCAT(Aisle, '-', Zone, '-', Section, '-R', RackNumber, '-S', ShelfNumber)
        ) STORED,
    CONSTRAINT uq_aisle_per_warehouse UNIQUE (WarehouseID, Aisle),
    FOREIGN KEY (WarehouseID) REFERENCES Warehouse(WarehouseID) ON DELETE CASCADE
);



-- Child of Warehouse: TransitLocation
CREATE TABLE TransitLocation (
    LocationID INT AUTO_INCREMENT PRIMARY KEY,
    WarehouseID INT NOT NULL,
    RackNumber INT NOT NULL,
    ShelfNumber INT NOT NULL,
    Aisle VARCHAR(10) NOT NULL,
    Zone VARCHAR(20) NOT NULL,
    Section VARCHAR(10) NOT NULL,
    Capacity DECIMAL(10,2) NOT NULL CHECK (Capacity > 0 AND Capacity <= 2500),
    Status ENUM('occupied', 'empty', 'damaged', 'blocked') DEFAULT 'empty',
    Temp_Stor_TimeLimit INT,  -- numero massimo di ore
    IsTransitArea BOOLEAN DEFAULT FALSE,
    CONSTRAINT uq_transit_aisle_per_warehouse UNIQUE (WarehouseID, Aisle),
    FOREIGN KEY (WarehouseID) REFERENCES Warehouse(WarehouseID) ON DELETE CASCADE
);

-- Superclass: Item
CREATE TABLE Item (
    ItemID INT AUTO_INCREMENT PRIMARY KEY, 
    ItemName VARCHAR(100) NOT NULL,       
    SKU VARCHAR(50) UNIQUE NOT NULL,      
    Description TEXT,                     
    Weight DECIMAL(10, 2) CHECK (Weight > 0), 
    Dimensions VARCHAR(50),              
    Category VARCHAR(50),                
    Quantity INT NOT NULL CHECK (Quantity >= 0),
    CommodityCode VARCHAR(20) UNIQUE NOT NULL
);

-- Subclass of Item: ConsumableItem
CREATE TABLE ConsumableItem (
    ItemID INT PRIMARY KEY,
    ExpiryDate DATE,
    StorageCondition ENUM('Ambient', 'Chilled', 'Meat and Poultry', 'Seasonal', 'Freezer', 'Fruit and Vegetable', 'Cold Room') DEFAULT 'Ambient',
    BatchNumber VARCHAR(20) UNIQUE NOT NULL,
    FOREIGN KEY (ItemID) REFERENCES Item(ItemID) ON DELETE CASCADE
);

-- Subclass of Item: NonConsumableItem
CREATE TABLE NonConsumableItem (
    ItemID INT PRIMARY KEY,
    Type ENUM('Electronic', 'Clothes', 'Plants', 'Cleaning', 'Restricted', 'Chemist', 'Gardening', 'Handwear', 'Stationery') DEFAULT 'Electronic',
    StorageRequirement ENUM('Ambient', 'Chilled', 'Frozen', 'Dry', 'Moisture Controlled', 'Ventilated') DEFAULT 'Ambient',
    StockRotationRules ENUM('FIFO', 'LIFO', 'FEFO', 'Custom', 'None') DEFAULT 'FIFO',
    FOREIGN KEY (ItemID) REFERENCES Item(ItemID) ON DELETE CASCADE
);

-- Independent Entity: Customer 
-- Linked via FK to CustomerOrder (CustomerID) 
CREATE TABLE Customer (
    CustomerID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE,
    Phone VARCHAR(30),
    Address VARCHAR(255)
);

-- Superclass: Orders
CREATE TABLE Orders (
    OrderID INT AUTO_INCREMENT PRIMARY KEY,
    Date DATETIME NOT NULL,
    DeliveryDate DATETIME,
    Status ENUM('Pending', 'Completed', 'Cancelled') NOT NULL DEFAULT 'Pending',
    PriorityLevel ENUM('Low', 'Medium', 'High') DEFAULT 'Low',
    Currency VARCHAR(3) NOT NULL,
    Type ENUM('Customer', 'Internal') NOT NULL
    -- (Quantity rimosso perché calcolabile da OrderItem)
);


-- Subclass of Orders: InternalOrder
CREATE TABLE InternalOrder (
    OrderID INT PRIMARY KEY,
    RequestingDep VARCHAR(100) NOT NULL,
    Purpose VARCHAR(255),
    FOREIGN KEY (OrderID) REFERENCES Orders (OrderID)
);

-- Subclass of Orders: CustomerOrder
-- Linked via FK to Customer (CustomerID)
CREATE TABLE CustomerOrder (
    OrderID INT PRIMARY KEY,
    CustomerID INT NOT NULL,
    DeliveryAddress VARCHAR(255) NOT NULL,
    PaymentStatus ENUM('Paid', 'Unpaid', 'Deposit') DEFAULT 'Unpaid',
    FOREIGN KEY (OrderID) REFERENCES Orders (OrderID),
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
);

-- Subclass of CustomerOrder: WebOrder
CREATE TABLE WebOrder (
    OrderID INT PRIMARY KEY,
    DropShipping BOOLEAN NOT NULL DEFAULT FALSE,
    WebSalePlatform VARCHAR(100) NOT NULL,
    FOREIGN KEY (OrderID) REFERENCES CustomerOrder (OrderID)
);

-- Subclass of CustomerOrder: SalesRepOrder
-- Linked via FK to Employee (SalesRepID)
CREATE TABLE SalesRepOrder (
    OrderID INT PRIMARY KEY,
    SalesRepID INT NOT NULL,
    CommissionRate DECIMAL(5 , 2 ) NOT NULL,
    FOREIGN KEY (OrderID) REFERENCES CustomerOrder (OrderID),
    FOREIGN KEY (SalesRepID) REFERENCES Employee (EmployeeID)
);

-- Child of Orders: OrderItem
-- Linked via FK to Item (ItemID)
CREATE TABLE OrderItem (
    OrderItemID INT AUTO_INCREMENT PRIMARY KEY,
    OrderID INT NOT NULL,
    ItemID INT NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    UnitPrice DECIMAL(10 , 2 ) NOT NULL CHECK (UnitPrice >= 0),
    Discount DECIMAL(5 , 2 ) CHECK (Discount >= 0 AND Discount <= 100),
    TotalPrice DECIMAL(12 , 2 ) NOT NULL CHECK (TotalPrice >= 0),
    FOREIGN KEY (OrderID) REFERENCES Orders (OrderID),
    FOREIGN KEY (ItemID) REFERENCES Item (ItemID)
);

-- Superclass: Supplier
CREATE TABLE Supplier (
    SupplierID INT AUTO_INCREMENT PRIMARY KEY,
    SupplierName VARCHAR(100) NOT NULL,
    Phone VARCHAR(30),
    Email VARCHAR(100),
    Address VARCHAR(255) NOT NULL
);

-- Child of Supplier: ItemSupplier
-- Linked via FK to Item (ItemID)
CREATE TABLE ItemSupplier (
    ItemSupplierID INT AUTO_INCREMENT PRIMARY KEY,
    ItemID INT NOT NULL,
    SupplierID INT NOT NULL,
    Cost DECIMAL(10,2) NOT NULL CHECK (Cost >= 0),
    SupplyDate DATE NOT NULL,
    MOQ SMALLINT NOT NULL CHECK (MOQ > 0),
    CONSTRAINT uq_itemsupplier_item_supplier UNIQUE (ItemID, SupplierID),
    FOREIGN KEY (ItemID) REFERENCES Item(ItemID),
    FOREIGN KEY (SupplierID) REFERENCES Supplier(SupplierID) ON DELETE CASCADE
);

-- Superclass: Transactions
CREATE TABLE Transactions (
    TransactionID INT AUTO_INCREMENT PRIMARY KEY,
    ItemID INT NOT NULL,
    StorageLocationID INT NULL,
    TransitLocationID INT NULL,
    EmployeeID INT NOT NULL,
    TransactionDateTime DATETIME NOT NULL,
    FOREIGN KEY (ItemID) REFERENCES Item(ItemID),
    FOREIGN KEY (StorageLocationID) REFERENCES StorageLocation(LocationID),
    FOREIGN KEY (TransitLocationID) REFERENCES TransitLocation(LocationID),
    FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID),
    CONSTRAINT chk_location CHECK (
        (StorageLocationID IS NOT NULL AND TransitLocationID IS NULL)
     OR (StorageLocationID IS NULL AND TransitLocationID IS NOT NULL)
    )
);

-- Subclass of Transactions: InboundTransaction
-- Linked via FK to Supplier (SupplierID)
CREATE TABLE InboundTransaction (
    TransactionID INT PRIMARY KEY,
    SupplierID INT,
    DeliveryNote VARCHAR(255),
    InspectionStatus ENUM('Passed', 'Failed', 'Pending'),
    FOREIGN KEY (TransactionID) REFERENCES Transactions(TransactionID),
    FOREIGN KEY (SupplierID) REFERENCES Supplier(SupplierID)
);

-- Subclass of Transactions: OutboundTransaction
-- Linked via FK to Orders (OrderID)
CREATE TABLE OutboundTransaction (
    TransactionID INT PRIMARY KEY,
    OrderID INT,
    FOREIGN KEY (TransactionID) REFERENCES Transactions(TransactionID),
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID)
);

-- Subclass of Transactions: TransferTransaction
-- Linked via FK to StorageLocation / TransitLocation
CREATE TABLE TransferTransaction (
    TransactionID INT PRIMARY KEY,
    OldStorageLocationID INT NULL,
    OldTransitLocationID INT NULL,
    NewStorageLocationID INT NULL,
    NewTransitLocationID INT NULL,
    FOREIGN KEY (TransactionID) REFERENCES Transactions(TransactionID),
    FOREIGN KEY (OldStorageLocationID) REFERENCES StorageLocation(LocationID),
    FOREIGN KEY (OldTransitLocationID) REFERENCES TransitLocation(LocationID),
    FOREIGN KEY (NewStorageLocationID) REFERENCES StorageLocation(LocationID),
    FOREIGN KEY (NewTransitLocationID) REFERENCES TransitLocation(LocationID),
    CONSTRAINT chk_transfer_location CHECK (
        (OldStorageLocationID IS NOT NULL OR OldTransitLocationID IS NOT NULL)
     AND (NewStorageLocationID IS NOT NULL OR NewTransitLocationID IS NOT NULL)
    )
);

-- ==========================================
-- VIEWS (Database Operational Queries)
-- ==========================================

-- ==========================================
-- View 1: Transfer Movements (Pallet Tracking)
-- ==========================================
CREATE OR REPLACE VIEW v_transfer_movements AS
SELECT
    t.TransactionID,
    i.ItemName,
    e.Name AS Operator,
    osl.WarehouseID AS FromWarehouse,
    osl.Zone AS FromZone,
    osl.Aisle AS FromAisle,
    osl.RackNumber AS FromRack,
    osl.ShelfNumber AS FromShelf,
    nsl.WarehouseID AS ToWarehouse,
    nsl.Zone AS ToZone,
    nsl.Aisle AS ToAisle,
    nsl.RackNumber AS ToRack,
    nsl.ShelfNumber AS ToShelf,
    t.TransactionDateTime
FROM TransferTransaction tt
JOIN Transactions t ON tt.TransactionID = t.TransactionID
JOIN Item i ON t.ItemID = i.ItemID
JOIN Employee e ON t.EmployeeID = e.EmployeeID
LEFT JOIN StorageLocation osl ON tt.OldStorageLocationID = osl.LocationID
LEFT JOIN StorageLocation nsl ON tt.NewStorageLocationID = nsl.LocationID
ORDER BY t.TransactionDateTime DESC;

-- ==========================================
-- View 2: Inventory by Zone
-- ==========================================
CREATE OR REPLACE VIEW v_inventory_by_zone AS
WITH last_tx AS (
  SELECT t.*
  FROM Transactions t
  JOIN (
    SELECT ItemID, MAX(TransactionDateTime) AS max_ts
    FROM Transactions
    GROUP BY ItemID
  ) m ON m.ItemID = t.ItemID AND m.max_ts = t.TransactionDateTime
)
SELECT
  w.Name AS Warehouse,
  COALESCE(sl.Zone, tl.Zone) AS Zone,
  COUNT(DISTINCT i.ItemID) AS DistinctItems,
  SUM(i.Quantity) AS TotalQuantity
FROM last_tx t
JOIN Item i ON i.ItemID = t.ItemID
LEFT JOIN StorageLocation sl ON t.StorageLocationID = sl.LocationID
LEFT JOIN TransitLocation tl ON t.TransitLocationID = tl.LocationID
LEFT JOIN Warehouse w ON w.WarehouseID = COALESCE(sl.WarehouseID, tl.WarehouseID)
GROUP BY w.Name, COALESCE(sl.Zone, tl.Zone)
ORDER BY w.Name, Zone;


-- ==========================================
-- View 3: Item History
-- ==========================================
CREATE OR REPLACE VIEW v_item_history AS
SELECT
    i.ItemName,
    e.Name AS Employee,
    t.TransactionDateTime,
    CASE
        WHEN it.TransactionID IS NOT NULL THEN 'Inbound'
        WHEN ot.TransactionID IS NOT NULL THEN 'Outbound'
        WHEN tt.TransactionID IS NOT NULL THEN 'Transfer'
        ELSE 'Unknown'
    END AS TransactionType,
    COALESCE(sl.Zone, tl.Zone) AS LocationZone,
    COALESCE(sl.Aisle, tl.Aisle) AS Aisle,
    COALESCE(sl.RackNumber, tl.RackNumber) AS Rack,
    COALESCE(sl.ShelfNumber, tl.ShelfNumber) AS Shelf
FROM Transactions t
JOIN Item i ON t.ItemID = i.ItemID
JOIN Employee e ON t.EmployeeID = e.EmployeeID
LEFT JOIN InboundTransaction it ON t.TransactionID = it.TransactionID
LEFT JOIN OutboundTransaction ot ON t.TransactionID = ot.TransactionID
LEFT JOIN TransferTransaction tt ON t.TransactionID = tt.TransactionID
LEFT JOIN StorageLocation sl ON t.StorageLocationID = sl.LocationID
LEFT JOIN TransitLocation tl ON t.TransitLocationID = tl.LocationID
ORDER BY i.ItemName, t.TransactionDateTime;

-- ==========================================
-- View 4: Operator Performance Summary
-- ==========================================
CREATE OR REPLACE VIEW v_operator_performance AS
SELECT
    e.EmployeeID,
    e.Name AS Employee,
    e.Role,
    w.Name AS Warehouse,
    COUNT(t.TransactionID) AS TotalTransactions,
    SUM(CASE WHEN it.TransactionID IS NOT NULL THEN 1 ELSE 0 END) AS InboundCount,
    SUM(CASE WHEN ot.TransactionID IS NOT NULL THEN 1 ELSE 0 END) AS OutboundCount,
    SUM(CASE WHEN tt.TransactionID IS NOT NULL THEN 1 ELSE 0 END) AS TransferCount,
    ROUND(COUNT(t.TransactionID) / COUNT(DISTINCT DATE(t.TransactionDateTime)), 2) AS AvgTransactionsPerDay
FROM Employee e
JOIN Warehouse w ON e.WarehouseID = w.WarehouseID
LEFT JOIN Transactions t ON e.EmployeeID = t.EmployeeID
LEFT JOIN InboundTransaction it ON t.TransactionID = it.TransactionID
LEFT JOIN OutboundTransaction ot ON t.TransactionID = ot.TransactionID
LEFT JOIN TransferTransaction tt ON t.TransactionID = tt.TransactionID
GROUP BY e.EmployeeID, e.Name, e.Role, w.Name
ORDER BY TotalTransactions DESC;


-- ==========================================
-- View 5: Warehouse Efficiency Overview
-- ==========================================
CREATE OR REPLACE VIEW v_warehouse_efficiency AS
SELECT
  w.WarehouseID,
  w.Name AS WarehouseName,
  w.Manager,
  w.TotalCapacity,
  w.CurrentInventoryLevel,
  ROUND((w.CurrentInventoryLevel / NULLIF(w.TotalCapacity,0)) * 100, 2) AS CapacityUsedPercent,
  w.ZoneCount,
  CASE WHEN w.IsOverCapacity THEN '⚠️ Over Capacity' ELSE 'OK' END AS CapacityStatus,
  COUNT(DISTINCT sl.LocationID) AS StorageLocations,
  COUNT(DISTINCT tl.LocationID) AS TransitLocations,
  COUNT(DISTINCT t.TransactionID) AS TotalTransactions,
  COUNT(DISTINCT e.EmployeeID) AS TotalEmployees
FROM Warehouse w
LEFT JOIN StorageLocation sl ON w.WarehouseID = sl.WarehouseID
LEFT JOIN TransitLocation tl ON w.WarehouseID = tl.WarehouseID
LEFT JOIN Employee e ON w.WarehouseID = e.WarehouseID
LEFT JOIN Transactions t ON e.EmployeeID = t.EmployeeID
GROUP BY w.WarehouseID, w.Name, w.Manager, w.TotalCapacity, w.CurrentInventoryLevel, w.ZoneCount, w.IsOverCapacity
ORDER BY CapacityUsedPercent DESC;


-- ==========================================
-- View 6: Stock Rotation per Categoria
-- ==========================================
CREATE OR REPLACE VIEW v_stock_rotation AS
SELECT
    i.Category,
    COUNT(DISTINCT it.TransactionID) AS InboundCount,
    COUNT(DISTINCT ot.TransactionID) AS OutboundCount,
    (COUNT(DISTINCT ot.TransactionID) - COUNT(DISTINCT it.TransactionID)) AS NetOutflow,
    ROUND(
        (COUNT(DISTINCT ot.TransactionID) / NULLIF(COUNT(DISTINCT it.TransactionID), 0)),
        2
    ) AS TurnoverRatio,
    SUM(i.Quantity) AS TotalStock,
    ROUND(SUM(i.Quantity) / NULLIF((COUNT(DISTINCT ot.TransactionID) + COUNT(DISTINCT it.TransactionID)) / 2, 0), 2) AS AvgStockPerTransaction
FROM Item i
LEFT JOIN Transactions t ON i.ItemID = t.ItemID
LEFT JOIN InboundTransaction it ON t.TransactionID = it.TransactionID
LEFT JOIN OutboundTransaction ot ON t.TransactionID = ot.TransactionID
GROUP BY i.Category
ORDER BY TurnoverRatio DESC;

-- ==========================================
-- View 7: Warehouse Operator Performance Overview
-- ==========================================
CREATE OR REPLACE VIEW v_operator_performance_overview AS
SELECT
    e.EmployeeID,
    e.Name AS OperatorName,
    w.Name AS Warehouse,
    e.Role,
    COUNT(t.TransactionID) AS TotalTransactions,
    SUM(CASE WHEN it.TransactionID IS NOT NULL THEN 1 ELSE 0 END) AS InboundOps,
    SUM(CASE WHEN ot.TransactionID IS NOT NULL THEN 1 ELSE 0 END) AS OutboundOps,
    SUM(CASE WHEN tt.TransactionID IS NOT NULL THEN 1 ELSE 0 END) AS TransferOps,
    ROUND(SUM(CASE WHEN it.TransactionID IS NOT NULL THEN 1 ELSE 0 END) / NULLIF(COUNT(t.TransactionID),0) * 100,2) AS InboundPct,
    ROUND(SUM(CASE WHEN ot.TransactionID IS NOT NULL THEN 1 ELSE 0 END) / NULLIF(COUNT(t.TransactionID),0) * 100,2) AS OutboundPct,
    ROUND(SUM(CASE WHEN tt.TransactionID IS NOT NULL THEN 1 ELSE 0 END) / NULLIF(COUNT(t.TransactionID),0) * 100,2) AS TransferPct,
    MAX(t.TransactionDateTime) AS LastActivity,
    TIMESTAMPDIFF(DAY, MAX(t.TransactionDateTime), NOW()) AS DaysSinceLastActivity
FROM Employee e
LEFT JOIN Warehouse w ON e.WarehouseID = w.WarehouseID
LEFT JOIN Transactions t ON e.EmployeeID = t.EmployeeID
LEFT JOIN InboundTransaction it ON t.TransactionID = it.TransactionID
LEFT JOIN OutboundTransaction ot ON t.TransactionID = ot.TransactionID
LEFT JOIN TransferTransaction tt ON t.TransactionID = tt.TransactionID
GROUP BY e.EmployeeID, e.Name, w.Name, e.Role
ORDER BY TotalTransactions DESC;

-- ======================================================
-- 5) Index FK (boost performance)
-- ======================================================

CREATE INDEX idx_employee_wh ON Employee (WarehouseID);
CREATE INDEX idx_storage_wh ON StorageLocation (WarehouseID);
CREATE INDEX idx_transit_wh ON TransitLocation (WarehouseID);

CREATE INDEX idx_orderitem_order ON OrderItem (OrderID);
CREATE INDEX idx_orderitem_item ON OrderItem (ItemID);

CREATE INDEX idx_tx_item  ON Transactions (ItemID);
CREATE INDEX idx_tx_emp   ON Transactions (EmployeeID);
CREATE INDEX idx_tx_stloc ON Transactions (StorageLocationID);
CREATE INDEX idx_tx_trloc ON Transactions (TransitLocationID);
CREATE INDEX idx_tx_dt    ON Transactions (TransactionDateTime);

CREATE INDEX idx_inbound_supplier  ON InboundTransaction (SupplierID);
CREATE INDEX idx_outbound_order    ON OutboundTransaction (OrderID);