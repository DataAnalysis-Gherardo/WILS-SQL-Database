# WILS Project (Warehouse Item Location System)

### Author
**Gherardo Frusci** – Higher Diploma in Business Systems Analysis, SETU Waterford

### Project Overview
WILS is a database-driven warehouse management and tracking system designed to manage storage locations, track item movements, and provide business analytics.

### File Structure
1. `1_WILS_Database_Schema.sql` — defines all tables and relationships
2. `2_WILS_Data_Population.sql` — inserts test/demo data
3. `3_WILS_Analytics_Queries.sql` — includes views and management KPI reports

### Usage
1. Run `1_WILS_Database_Schema.sql`
2. Then run `2_WILS_Data_Population.sql`
3. Optionally, execute `3_WILS_Analytics_Queries.sql` to generate reports or views

### Requirements
- MySQL 8.0+
- Recommended client: MySQL Workbench or DBeaver

### Author Note
This project demonstrates practical database design, implementation, and analytics integration for warehouse management.

### Demonstration
After loading the database, you can run:
SELECT * FROM v_warehouse_efficiency;
to view the system’s live warehouse KPIs.

## Database Design Evolution
The original conceptual model is available in the file:
[`Drawing EER - 5.pdf`](Drawing%20EER%20-%205.pdf)

This EER diagram represents the initial design phase of the WILS database.  
The final implementation (SQL scripts in this repository) expands the model with additional entities, constraints, and analytics queries for operational and business intelligence purposes.


