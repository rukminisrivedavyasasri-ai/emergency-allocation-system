-- ========================================================
-- Triggers: Automated Resource State Management
-- Role: Person 4 (DBMS Advanced Features)
-- File: database/triggers.sql
-- ========================================================

USE emergencydb;

DROP TRIGGER IF EXISTS allocation_AFTER_INSERT;
DROP TRIGGER IF EXISTS allocation_AFTER_UPDATE;

DELIMITER //

-- 1. Bed and Equipment automatically flip to 'Occupied' upon allocation
CREATE TRIGGER allocation_AFTER_INSERT 
AFTER INSERT ON allocation 
FOR EACH ROW
BEGIN
    UPDATE bed 
    SET status = 'Occupied' 
    WHERE bed_id = NEW.bed_id;

    UPDATE equipment 
    SET status = 'Occupied' 
    WHERE equipment_id = NEW.equipment_id;
END//

-- 2. Bed transitions to 'Cleaning' and Equipment to 'Available' upon patient discharge
CREATE TRIGGER allocation_AFTER_UPDATE 
AFTER UPDATE ON allocation 
FOR EACH ROW
BEGIN
    IF OLD.status = 'Active' AND NEW.status = 'Discharged' THEN
        UPDATE bed 
        SET status = 'Cleaning' 
        WHERE bed_id = NEW.bed_id;

        UPDATE equipment 
        SET status = 'Available' 
        WHERE equipment_id = NEW.equipment_id;
    END IF;
END//

DELIMITER ;