-- ========================================================
-- Schema: Emergency Bed & Resource Allocation System
-- Role: Person 1 (Database Architect)
-- File: schema.sql
-- ========================================================

CREATE DATABASE IF NOT EXISTS emergencydb;
USE emergencydb;

-- 1. Departments
CREATE TABLE department (
    department_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    floor INT NOT NULL
);

-- 2. Hospital Beds
CREATE TABLE bed (
    bed_id INT AUTO_INCREMENT PRIMARY KEY,
    department_id INT NOT NULL,
    bed_number VARCHAR(20) NOT NULL UNIQUE,
    bed_type VARCHAR(30) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Available',
    FOREIGN KEY (department_id) REFERENCES department(department_id) ON DELETE RESTRICT,
    CONSTRAINT chk_bed_status CHECK (status IN ('Available', 'Occupied', 'Cleaning'))
);

-- 3. Employees / Doctors
CREATE TABLE employee (
    employee_id INT AUTO_INCREMENT PRIMARY KEY,
    department_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    specialization VARCHAR(100) NOT NULL,
    role VARCHAR(50) NOT NULL,
    FOREIGN KEY (department_id) REFERENCES department(department_id) ON DELETE RESTRICT
);

-- 4. Medical Equipment
CREATE TABLE equipment (
    equipment_id INT AUTO_INCREMENT PRIMARY KEY,
    department_id INT NOT NULL,
    equipment_type VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Available',
    FOREIGN KEY (department_id) REFERENCES department(department_id) ON DELETE RESTRICT,
    CONSTRAINT chk_equipment_status CHECK (status IN ('Available', 'Occupied', 'Maintenance'))
);

-- 5. Duty Shifts
CREATE TABLE shift_schedule (
    shift_id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id INT NOT NULL,
    shift_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    FOREIGN KEY (employee_id) REFERENCES employee(employee_id) ON DELETE CASCADE,
    CONSTRAINT chk_shift_time CHECK (start_time <> end_time)
);

-- 6. Emergency Patients
CREATE TABLE patient (
    patient_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    age INT NOT NULL,
    condition_description VARCHAR(255) NOT NULL,
    triage_score INT NOT NULL,
    required_bed_type VARCHAR(30) NOT NULL,
    required_equipment_type VARCHAR(50) NOT NULL,
    required_specialization VARCHAR(100) NOT NULL,
    arrival_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_patient_age CHECK (age >= 0),
    CONSTRAINT chk_patient_triage CHECK (triage_score BETWEEN 1 AND 5)
);

-- 7. Resource Allocations (Central Transaction Table)
CREATE TABLE allocation (
    allocation_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    bed_id INT NOT NULL,
    employee_id INT NOT NULL,
    equipment_id INT NOT NULL,
    allocated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    discharged_at DATETIME NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Active',
    FOREIGN KEY (patient_id) REFERENCES patient(patient_id) ON DELETE RESTRICT,
    FOREIGN KEY (bed_id) REFERENCES bed(bed_id) ON DELETE RESTRICT,
    FOREIGN KEY (employee_id) REFERENCES employee(employee_id) ON DELETE RESTRICT,
    FOREIGN KEY (equipment_id) REFERENCES equipment(equipment_id) ON DELETE RESTRICT,
    CONSTRAINT chk_allocation_status CHECK (status IN ('Active', 'Discharged', 'Cancelled')),
    CONSTRAINT chk_discharge_time CHECK (discharged_at IS NULL OR discharged_at >= allocated_at)
);