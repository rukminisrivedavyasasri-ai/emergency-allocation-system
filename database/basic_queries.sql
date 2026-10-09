-- ========================================================
-- Basic Queries: Emergency Bed & Resource Allocation System
-- Role: Person 1 (Database Architect)
-- File: basic_queries.sql
-- ========================================================

USE emergencydb;

-- 1. SELECT: Fetch all currently available ICU beds
SELECT bed_id, bed_number, status 
FROM bed 
WHERE bed_type = 'ICU' AND status = 'Available';

-- 2. INSERT: Intake a new patient via triage form
INSERT INTO patient (name, age, condition_description, triage_score, required_bed_type, required_equipment_type, required_specialization)
VALUES ('Rahul Varma', 45, 'Chest pain and sweating', 5, 'ICU', 'Ventilator', 'Cardiology');

-- 3. JOIN: Find on-duty doctors currently working right now
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

-- 4. COMPLEX JOIN: Resource-Matching Query for a Specific Patient
-- Matches available Bed, Equipment, and on-duty Doctor based on patient requirements
SELECT 
    p.patient_id,
    p.name AS patient_name,
    p.triage_score,
    b.bed_id,
    b.bed_number,
    eq.equipment_id,
    eq.equipment_type,
    e.employee_id AS doctor_id,
    e.name AS doctor_name
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
      SELECT 1 FROM allocation a WHERE a.patient_id = p.patient_id AND a.status = 'Active'
  )
LIMIT 1;

-- 5. UPDATE: Mark a patient allocation as Discharged
UPDATE allocation
SET status = 'Discharged', discharged_at = NOW()
WHERE allocation_id = 1 AND status = 'Active';

-- 6. DELETE: Remove completed cleaning state once sanitization finishes
UPDATE bed
SET status = 'Available'
WHERE status = 'Cleaning';