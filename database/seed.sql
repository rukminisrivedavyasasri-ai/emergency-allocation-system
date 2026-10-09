-- ========================================================
-- Seed Data: Emergency Bed & Resource Allocation System
-- Role: Person 1 (Database Architect)
-- File: seed.sql
-- ========================================================

USE emergencydb;

-- Clear previous data in reverse-dependency order
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE allocation;
TRUNCATE TABLE shift_schedule;
TRUNCATE TABLE patient;
TRUNCATE TABLE equipment;
TRUNCATE TABLE employee;
TRUNCATE TABLE bed;
TRUNCATE TABLE department;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. Departments
INSERT INTO department (department_id, name, floor) VALUES
(1, 'Emergency Medicine', 1),
(2, 'Intensive Care Unit (ICU)', 2),
(3, 'Cardiology', 3),
(4, 'Neurology', 3);

-- 2. Beds
INSERT INTO bed (bed_id, department_id, bed_number, bed_type, status) VALUES
(1, 2, 'ICU-101', 'ICU', 'Available'),
(2, 2, 'ICU-102', 'ICU', 'Available'),
(3, 1, 'ER-101', 'Emergency', 'Available'),
(4, 1, 'ER-102', 'Emergency', 'Cleaning'),
(5, 3, 'CARD-101', 'General', 'Available');

-- 3. Employees / Doctors
INSERT INTO employee (employee_id, department_id, name, specialization, role) VALUES
(1, 3, 'Dr. Ravi Kumar', 'Cardiology', 'Doctor'),
(2, 2, 'Dr. Ananya Rao', 'Critical Care', 'Doctor'),
(3, 1, 'Dr. Priya Sharma', 'Emergency Medicine', 'Doctor'),
(4, 4, 'Dr. Arjun Reddy', 'Neurology', 'Doctor');

-- 4. Equipment
INSERT INTO equipment (equipment_id, department_id, equipment_type, status) VALUES
(1, 2, 'Ventilator', 'Available'),
(2, 2, 'Cardiac Monitor', 'Available'),
(3, 1, 'Oxygen Cylinder', 'Available'),
(4, 3, 'ECG Machine', 'Available'),
(5, 2, 'Defibrillator', 'Maintenance');

-- 5. Shifts (Covers today's full 24-hour cycle for live testing)
INSERT INTO shift_schedule (employee_id, shift_date, start_time, end_time) VALUES
(1, CURDATE(), '00:00:00', '23:59:00'),
(2, CURDATE(), '00:00:00', '23:59:00'),
(3, CURDATE(), '00:00:00', '23:59:00'),
(4, CURDATE(), '00:00:00', '23:59:00');

-- 6. Sample Patients
INSERT INTO patient (name, age, condition_description, triage_score, required_bed_type, required_equipment_type, required_specialization) VALUES
('Patient Alpha', 58, 'Acute Myocardial Infarction', 5, 'ICU', 'Ventilator', 'Cardiology'),
('Patient Beta', 34, 'Severe Respiratory Distress', 4, 'ICU', 'Cardiac Monitor', 'Critical Care'),
('Patient Gamma', 22, 'Trauma / Fracture', 2, 'Emergency', 'Oxygen Cylinder', 'Emergency Medicine');