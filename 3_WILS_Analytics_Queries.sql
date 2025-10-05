/* ==========================================================
   WILS PROJECT
   File: 3_WILS_Analytics_Queries.sql
   Description:
     Contains analytical SQL queries and reporting views
     for warehouse performance, inventory tracking, and KPIs.
   ========================================================== */

USE WILS;

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
SELECT
    w.Name AS Warehouse,
    sl.Zone,
    COUNT(i.ItemID) AS TotalItems,
    SUM(i.Quantity) AS TotalQuantity,
    SUM(i.Weight) AS TotalWeight
FROM Item i
JOIN Transactions t ON i.ItemID = t.ItemID
JOIN StorageLocation sl ON t.StorageLocationID = sl.LocationID
JOIN Warehouse w ON sl.WarehouseID = w.WarehouseID
GROUP BY w.Name, sl.Zone
ORDER BY w.Name, sl.Zone;

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
    ROUND((w.CurrentInventoryLevel / w.TotalCapacity) * 100, 2) AS CapacityUsedPercent,
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
CREATE OR REPLACE VIEW v_operator_summary AS
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

-- 1️⃣ Top 5 Items by Total Transactions
SELECT 
    i.ItemName,
    i.Category,
    COUNT(t.TransactionID) AS TotalMovements,
    SUM(CASE WHEN it.TransactionID IS NOT NULL THEN 1 ELSE 0 END) AS InboundCount,
    SUM(CASE WHEN ot.TransactionID IS NOT NULL THEN 1 ELSE 0 END) AS OutboundCount,
    SUM(CASE WHEN tt.TransactionID IS NOT NULL THEN 1 ELSE 0 END) AS TransferCount
FROM Transactions t
JOIN Item i ON t.ItemID = i.ItemID
LEFT JOIN InboundTransaction it ON t.TransactionID = it.TransactionID
LEFT JOIN OutboundTransaction ot ON t.TransactionID = ot.TransactionID
LEFT JOIN TransferTransaction tt ON t.TransactionID = tt.TransactionID
GROUP BY i.ItemName, i.Category
ORDER BY TotalMovements DESC
LIMIT 5;

-- 2️⃣ Top 5 Warehouses by Transaction Volume
SELECT 
    w.Name AS Warehouse,
    COUNT(t.TransactionID) AS TotalTransactions,
    ROUND(COUNT(t.TransactionID) / (SELECT COUNT(*) FROM Transactions) * 100, 2) AS PercentOfTotal,
    MAX(t.TransactionDateTime) AS LastActivity
FROM Transactions t
JOIN Employee e ON t.EmployeeID = e.EmployeeID
JOIN Warehouse w ON e.WarehouseID = w.WarehouseID
GROUP BY w.Name
ORDER BY TotalTransactions DESC
LIMIT 5;

-- 3️⃣ Top 5 Active Operators by Transactions
SELECT 
    e.Name AS Operator,
    w.Name AS Warehouse,
    COUNT(t.TransactionID) AS TotalTransactions,
    MAX(t.TransactionDateTime) AS LastActivity
FROM Transactions t
JOIN Employee e ON t.EmployeeID = e.EmployeeID
JOIN Warehouse w ON e.WarehouseID = w.WarehouseID
GROUP BY e.EmployeeID, e.Name, w.Name
ORDER BY TotalTransactions DESC
LIMIT 5;

-- 4️⃣ Average Item Rotation Speed (days between first and last transaction)
SELECT 
    i.ItemName,
    i.Category,
    DATEDIFF(MAX(t.TransactionDateTime), MIN(t.TransactionDateTime)) AS DaysInCirculation,
    COUNT(t.TransactionID) AS TotalMovements,
    ROUND(COUNT(t.TransactionID) / NULLIF(DATEDIFF(MAX(t.TransactionDateTime), MIN(t.TransactionDateTime)), 0), 2) AS MovementsPerDay
FROM Transactions t
JOIN Item i ON t.ItemID = i.ItemID
GROUP BY i.ItemName, i.Category
HAVING TotalMovements > 1
ORDER BY MovementsPerDay DESC
LIMIT 5;

-- 5️⃣ Top Active Zones per Warehouse
SELECT 
    w.Name AS Warehouse,
    s.Zone AS Zone,
    COUNT(t.TransactionID) AS TotalMovements
FROM Transactions t
JOIN StorageLocation s ON t.StorageLocationID = s.LocationID
JOIN Warehouse w ON s.WarehouseID = w.WarehouseID
GROUP BY w.Name, s.Zone
ORDER BY TotalMovements DESC
LIMIT 10;

-- 6️⃣ Items at Risk (Low Stock or Near Expiry)
SELECT 
    i.ItemName,
    i.Category,
    i.Quantity,
    c.ExpiryDate,
    CASE 
        WHEN i.Quantity < 50 THEN 'Low Stock'
        WHEN c.ExpiryDate <= DATE_ADD(NOW(), INTERVAL 30 DAY) THEN 'Near Expiry'
        ELSE 'OK'
    END AS StatusFlag
FROM Item i
LEFT JOIN ConsumableItem c ON i.ItemID = c.ItemID
WHERE i.Quantity < 50 OR c.ExpiryDate <= DATE_ADD(NOW(), INTERVAL 30 DAY)
ORDER BY StatusFlag;

-- 7️⃣ Total Sales Value per Customer
SELECT 
    c.Name AS Customer,
    SUM(oi.TotalPrice) AS TotalOrderValue,
    COUNT(DISTINCT o.OrderID) AS OrdersCount
FROM Customer c
JOIN CustomerOrder co ON c.CustomerID = co.CustomerID
JOIN Orders o ON co.OrderID = o.OrderID
JOIN OrderItem oi ON o.OrderID = oi.OrderID
GROUP BY c.Name
ORDER BY TotalOrderValue DESC
LIMIT 5;

INSERT INTO OutboundTransaction (TransactionID, OrderID)
VALUES
(2, 1),
(3, 1),
(4, 2);
