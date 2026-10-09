-- ========================================================
-- Advanced Queries & Transaction Scenarios
-- Role: Person 4 (DBMS Advanced Features)
-- File: database/advanced_queries.sql
-- ========================================================

USE emergencydb;

-- 1. Advanced Resource Matching Query for a Specific Patient (Patient ID: 1)
-- Matches an available bed, matching available equipment, and an on-duty specialist
SELECT 
    p.patient_id,
    p.name AS patient_name,
    p.triage_score,
    b.bed_id,
    b.bed_number,
    b.bed_type,
    eq.equipment_id,
    eq.equipment_type,
    e.employee_id AS doctor_id,
    e.name AS doctor_name,
    e.specialization
FROM patient p
JOIN bed b 
    ON b.bed_type = p.required_bed_type 
    AND b.status = 'Available'
JOIN equipment eq 
    ON eq.equipment_type = p.required_equipment_type 
    AND eq.status = 'Available'
JOIN employee e 
    ON e.specialization = p.required_specialization
JOIN shift_schedule s 
    ON s.employee_id = e.employee_id 
    AND s.shift_date = CURDATE() 
    AND CURTIME() BETWEEN s.start_time AND s.end_time
WHERE p.patient_id = 1
  AND NOT EXISTS (
      SELECT 1 
      FROM allocation a 
      WHERE a.patient_id = p.patient_id 
        AND a.status = 'Active'
  )
LIMIT 1;


-- 2. Doctor Availability Right Now
SELECT 
    e.employee_id,
    e.name AS doctor_name,
    e.specialization,
    d.name AS department_name,
    s.start_time,
    s.end_time
FROM employee e
JOIN department d ON e.department_id = d.department_id
JOIN shift_schedule s ON e.employee_id = s.employee_id
WHERE s.shift_date = CURDATE()
  AND CURTIME() BETWEEN s.start_time AND s.end_time;


-- 3. Department with the Highest Bed Occupancy Rate
SELECT 
    d.name AS department_name,
    COUNT(b.bed_id) AS total_beds,
    SUM(CASE WHEN b.status = 'Occupied' THEN 1 ELSE 0 END) AS occupied_beds,
    ROUND((SUM(CASE WHEN b.status = 'Occupied' THEN 1 ELSE 0 END) / COUNT(b.bed_id)) * 100, 2) AS occupancy_rate_pct
FROM department d
JOIN bed b ON d.department_id = b.department_id
GROUP BY d.department_id, d.name
HAVING total_beds > 0
ORDER BY occupancy_rate_pct DESC
LIMIT 1;


-- 4. Average Length of Stay for Discharged Patients (in Hours)
SELECT 
    COUNT(allocation_id) AS total_discharged_patients,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, allocated_at, discharged_at)) / 60.0, 2) AS avg_stay_duration_hours
FROM allocation
WHERE status = 'Discharged' 
  AND discharged_at IS NOT NULL;


-- 5. Safe Transaction Allocation Pattern with Row-Level Locking (Pessimistic Locking)
-- This pattern is passed to Person 2 (Spring Boot) for @Transactional execution
START TRANSACTION;

-- Step A: Check and lock the required bed to prevent race conditions
SELECT bed_id, status 
FROM bed 
WHERE bed_id = 1 AND status = 'Available' 
FOR UPDATE;

-- Step B: Check and lock the required equipment
SELECT equipment_id, status 
FROM equipment 
WHERE equipment_id = 1 AND status = 'Available' 
FOR UPDATE;

-- Step C: If both resources are locked and available, insert allocation record
-- (Triggers will automatically switch bed and equipment status to 'Occupied')
INSERT INTO allocation (patient_id, bed_id, employee_id, equipment_id, status)
VALUES (1, 1, 1, 1, 'Active');

-- Step D: Finalize atomic changes
COMMIT;

-- (Note: If Step A or Step B returns 0 rows or status is not 'Available', execute: ROLLBACK;)