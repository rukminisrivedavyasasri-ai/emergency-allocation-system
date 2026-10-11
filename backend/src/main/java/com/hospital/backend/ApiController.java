package com.hospital.backend;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*")
public class ApiController {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    // 1. Dashboard: Current Occupancy View
    @GetMapping("/dashboard/occupancy")
    public ResponseEntity<?> getOccupancy() {
        try {
            List<Map<String, Object>> data = jdbcTemplate.queryForList("SELECT * FROM vw_current_occupancy");
            return ResponseEntity.ok(data);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body(Map.of("error", e.getMessage()));
        }
    }

    // 2. Dashboard: Department Load View
    @GetMapping("/dashboard/load")
    public ResponseEntity<?> getDepartmentLoad() {
        try {
            List<Map<String, Object>> data = jdbcTemplate.queryForList("SELECT * FROM vw_department_load");
            return ResponseEntity.ok(data);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body(Map.of("error", e.getMessage()));
        }
    }

    // 3. Register New Patient
    @PostMapping("/patients")
    public ResponseEntity<?> registerPatient(@RequestBody Map<String, Object> payload) {
        try {
            String sql = "INSERT INTO patient (name, age, condition_description, triage_score, " +
                         "required_bed_type, required_equipment_type, required_specialization) " +
                         "VALUES (?, ?, ?, ?, ?, ?, ?)";

            jdbcTemplate.update(
                sql,
                payload.get("name"),
                payload.get("age"),
                payload.get("conditionDescription"),
                payload.get("triageScore"),
                payload.get("requiredBedType"),
                payload.get("requiredEquipmentType"),
                payload.get("requiredSpecialization")
            );

            Integer newPatientId = jdbcTemplate.queryForObject("SELECT LAST_INSERT_ID()", Integer.class);
            return ResponseEntity.ok(Map.of(
                "message", "Patient registered successfully!",
                "patientId", newPatientId != null ? newPatientId : 0
            ));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body(Map.of("error", e.getMessage()));
        }
    }

    // 4. Resource Matching Query for a given Patient ID
    @GetMapping("/allocations/match/{patientId}")
    public ResponseEntity<?> findMatch(@PathVariable int patientId) {
        try {
            String sql = "SELECT p.patient_id, p.name AS patient_name, p.triage_score, " +
                         "b.bed_id, b.bed_number, b.bed_type, " +
                         "eq.equipment_id, eq.equipment_type, " +
                         "e.employee_id AS doctor_id, e.name AS doctor_name, e.specialization " +
                         "FROM patient p " +
                         "JOIN bed b ON b.bed_type = p.required_bed_type AND b.status = 'Available' " +
                         "JOIN equipment eq ON eq.equipment_type = p.required_equipment_type AND eq.status = 'Available' " +
                         "JOIN employee e ON e.specialization = p.required_specialization " +
                         "JOIN shift_schedule s ON s.employee_id = e.employee_id " +
                         "WHERE p.patient_id = ? " +
                         "AND CURTIME() BETWEEN s.start_time AND s.end_time " +
                         "AND NOT EXISTS (SELECT 1 FROM allocation a WHERE a.patient_id = p.patient_id AND a.status = 'Active') " +
                         "LIMIT 1";

            List<Map<String, Object>> matches = jdbcTemplate.queryForList(sql, patientId);
            if (matches.isEmpty()) {
                return ResponseEntity.status(404).body(Map.of(
                    "message", "No matching resources currently available for this patient."
                ));
            }
            return ResponseEntity.ok(matches.get(0));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body(Map.of("error", e.getMessage()));
        }
    }

    // 5. Create Allocation (Transactional with Row Locking)
    @PostMapping("/allocations")
    @Transactional
    public ResponseEntity<?> createAllocation(@RequestBody Map<String, Object> payload) {
        try {
            int patientId = Integer.parseInt(payload.get("patientId").toString());
            int bedId = Integer.parseInt(payload.get("bedId").toString());
            int equipmentId = Integer.parseInt(payload.get("equipmentId").toString());
            int doctorId = Integer.parseInt(payload.get("doctorId").toString());

            // Lock & Verify Bed
            List<Map<String, Object>> bedCheck = jdbcTemplate.queryForList(
                "SELECT bed_id FROM bed WHERE bed_id = ? AND status = 'Available' FOR UPDATE", bedId
            );
            if (bedCheck.isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of("error", "Bed is no longer available."));
            }

            // Lock & Verify Equipment
            List<Map<String, Object>> eqCheck = jdbcTemplate.queryForList(
                "SELECT equipment_id FROM equipment WHERE equipment_id = ? AND status = 'Available' FOR UPDATE", equipmentId
            );
            if (eqCheck.isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of("error", "Equipment is no longer available."));
            }

            // Insert allocation
            jdbcTemplate.update(
                "INSERT INTO allocation (patient_id, bed_id, employee_id, equipment_id, status) VALUES (?, ?, ?, ?, 'Active')",
                patientId, bedId, doctorId, equipmentId
            );

            // Update statuses to Occupied
            jdbcTemplate.update("UPDATE bed SET status = 'Occupied' WHERE bed_id = ?", bedId);
            jdbcTemplate.update("UPDATE equipment SET status = 'Occupied' WHERE equipment_id = ?", equipmentId);

            return ResponseEntity.ok(Map.of("message", "Allocation confirmed. Bed & Equipment marked Occupied."));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body(Map.of("error", e.getMessage()));
        }
    }

    // 6. Discharge Patient
    @PutMapping("/allocations/{allocationId}/discharge")
    public ResponseEntity<?> dischargePatient(@PathVariable int allocationId) {
        try {
            List<Map<String, Object>> alloc = jdbcTemplate.queryForList(
                "SELECT bed_id, equipment_id FROM allocation WHERE allocation_id = ? AND status = 'Active'", allocationId
            );
            if (alloc.isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of("error", "Active allocation not found or already discharged."));
            }

            int bedId = (int) alloc.get(0).get("bed_id");
            int equipmentId = (int) alloc.get(0).get("equipment_id");

            jdbcTemplate.update(
                "UPDATE allocation SET status = 'Discharged', discharged_at = NOW() WHERE allocation_id = ?", allocationId
            );
            jdbcTemplate.update("UPDATE bed SET status = 'Cleaning' WHERE bed_id = ?", bedId);
            jdbcTemplate.update("UPDATE equipment SET status = 'Available' WHERE equipment_id = ?", equipmentId);

            return ResponseEntity.ok(Map.of("message", "Patient discharged successfully. Bed set to Cleaning."));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body(Map.of("error", e.getMessage()));
        }
    }

    // 7. List Active Allocations
    @GetMapping("/allocations/active")
    public ResponseEntity<?> getActiveAllocations() {
        try {
            String sql = "SELECT a.allocation_id, a.allocated_at, " +
                         "p.name AS patient_name, p.triage_score, " +
                         "b.bed_number, eq.equipment_type, e.name AS doctor_name " +
                         "FROM allocation a " +
                         "JOIN patient p ON a.patient_id = p.patient_id " +
                         "JOIN bed b ON a.bed_id = b.bed_id " +
                         "JOIN equipment eq ON a.equipment_id = eq.equipment_id " +
                         "JOIN employee e ON a.employee_id = e.employee_id " +
                         "WHERE a.status = 'Active'";
            return ResponseEntity.ok(jdbcTemplate.queryForList(sql));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body(Map.of("error", e.getMessage()));
        }
    }

    // 8. Add Hospital Bed
    @PostMapping("/beds")
    public ResponseEntity<?> addBed(@RequestBody Map<String, Object> body) {
        try {
            int departmentId = Integer.parseInt(body.get("departmentId").toString());
            String bedNumber = body.get("bedNumber").toString();
            String bedType = body.get("bedType").toString();

            jdbcTemplate.update(
                "INSERT INTO bed (department_id, bed_number, bed_type, status) VALUES (?, ?, ?, 'Available')",
                departmentId, bedNumber, bedType
            );
            return ResponseEntity.ok(Map.of("message", "Bed " + bedNumber + " added successfully!"));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body(Map.of("error", e.getMessage()));
        }
    }

    // 9. Add Medical Equipment
    @PostMapping("/equipment")
    public ResponseEntity<?> addEquipment(@RequestBody Map<String, Object> body) {
        try {
            int departmentId = Integer.parseInt(body.get("departmentId").toString());
            String equipmentType = body.get("equipmentType").toString();

            jdbcTemplate.update(
                "INSERT INTO equipment (department_id, equipment_type, status) VALUES (?, ?, 'Available')",
                departmentId, equipmentType
            );
            return ResponseEntity.ok(Map.of("message", equipmentType + " added successfully!"));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body(Map.of("error", e.getMessage()));
        }
    }

    // 10. Add Doctor & Auto-Assign Shift
    @PostMapping("/employees")
    public ResponseEntity<?> addEmployee(@RequestBody Map<String, Object> body) {
        try {
            int departmentId = Integer.parseInt(body.get("departmentId").toString());
            String name = body.get("name").toString();
            String specialization = body.get("specialization").toString();
            String role = "Doctor";

            jdbcTemplate.update(
                "INSERT INTO employee (department_id, name, specialization, role) VALUES (?, ?, ?, ?)",
                departmentId, name, specialization, role
            );

            Number empIdNum = jdbcTemplate.queryForObject("SELECT LAST_INSERT_ID()", Number.class);
            int empId = (empIdNum != null) ? empIdNum.intValue() : 0;

            jdbcTemplate.update(
                "INSERT INTO shift_schedule (employee_id, shift_date, start_time, end_time) VALUES (?, CURDATE(), '00:00:00', '23:59:59')",
                empId
            );
            return ResponseEntity.ok(Map.of("message", "Doctor " + name + " added with an active shift!"));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body(Map.of("error", e.getMessage()));
        }
    }
}