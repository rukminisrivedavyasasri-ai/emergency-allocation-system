-- ========================================================
-- Views: Real-Time Operational & Department Analytics
-- Role: Person 4 (DBMS Advanced Features)
-- File: database/views.sql
-- ========================================================

USE emergencydb;

-- 1. Bed Occupancy per Department
CREATE OR REPLACE VIEW vw_current_occupancy AS
SELECT
    d.department_id,
    d.name AS department_name,
    COUNT(b.bed_id) AS total_beds,
    SUM(CASE WHEN b.status = 'Occupied' THEN 1 ELSE 0 END) AS occupied_beds,
    SUM(CASE WHEN b.status = 'Available' THEN 1 ELSE 0 END) AS available_beds,
    SUM(CASE WHEN b.status = 'Cleaning' THEN 1 ELSE 0 END) AS cleaning_beds
FROM department d
LEFT JOIN bed b ON d.department_id = b.department_id
GROUP BY d.department_id, d.name;

-- 2. Overall Department Load (Beds, Equipment, Active Allocations)
CREATE OR REPLACE VIEW vw_department_load AS
SELECT 
    d.department_id,
    d.name AS department_name,
    COUNT(DISTINCT b.bed_id) AS total_beds,
    COUNT(DISTINCT CASE WHEN b.status = 'Occupied' THEN b.bed_id END) AS occupied_beds,
    COUNT(DISTINCT eq.equipment_id) AS total_equipment,
    COUNT(DISTINCT CASE WHEN eq.status = 'Occupied' THEN eq.equipment_id END) AS occupied_equipment,
    COUNT(DISTINCT CASE WHEN a.status = 'Active' THEN a.allocation_id END) AS active_patients
FROM department d
LEFT JOIN bed b ON d.department_id = b.department_id
LEFT JOIN equipment eq ON d.department_id = eq.department_id
LEFT JOIN allocation a ON b.bed_id = a.bed_id AND a.status = 'Active'
GROUP BY d.department_id, d.name;

-- 3. Live Available Equipment View
CREATE OR REPLACE VIEW vw_available_equipment AS
SELECT
    equipment_id,
    department_id,
    equipment_type,
    status
FROM equipment
WHERE status = 'Available';