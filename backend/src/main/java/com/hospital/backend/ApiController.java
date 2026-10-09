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
    public List<Map<String, Object>> getOccupancy() {
        return jdbcTemplate.queryForList("SELECT * FROM vw_current_occupancy");
    }

    // 2. Dashboard: Department Load View
    @GetMapping("/dashboard/load")
    public List<Map<String, Object>> getDepartmentLoad() {
        return jdbcTemplate.queryForList("SELECT * FROM vw_department_load");
    }

    // 3. Register New Patient
    @PostMapping("/patients")
    public ResponseEntity<?> registerPatient(@RequestBody Map<String, Object> payload) {
        String sql = "INSERT INTO patient (name, age, condition_description, triage_score, " +
                     "required_bed_type, required_equipment_type, required_specialization) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?)";
        
        jdbcTemplate.update(sql,
                payload.get("name"),
                payload.get("age"),
                payload.get("conditionDescription"),
                payload.get("triageScore"),
                payload.get("requiredBedType"),
                payload.get("requiredEquipmentType"),
                payload.get("requiredSpecialization")
        );
        return ResponseEntity.ok(Map.of("message", "Patient registered successfully"));
    }

    // 4. Resource Matching Query for a given Patient ID
    @GetMapping("/allocations/match/{patientId}")
    public ResponseEntity<?> findMatch(@PathVariable int patientId) {
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
                     "  AND s.shift_date = CURDATE() " +
                     "  AND CURTIME() BETWEEN s.start_time AND s.end_time " +
                     "  AND NOT EXISTS (SELECT 1 FROM allocation a WHERE a.patient_id = p.patient_id AND a.status = 'Active') " +
                     "LIMIT 1";

        List<Map<String, Object>> matches = jdbcTemplate.queryForList(sql, patientId);
        if (matches.isEmpty()) {
            return ResponseEntity.status(404).body(Map.of("message", "No matching resources currently available for this patient."));
        }
        return ResponseEntity.ok(matches.get(0));
    }

    // 5. Create Allocation (Transactional with Row Locking)
    @PostMapping("/allocations")
    @Transactional
    public ResponseEntity<?> createAllocation(@RequestBody Map<String, Object> payload) {
        int patientId = (int) payload.get("patientId");
        int bedId = (int) payload.get("bedId");
        int equipmentId = (int) payload.get("equipmentId");
        int doctorId = (int) payload.get("doctorId");

        // Lock & Verify Bed
        List<Map<String, Object>> bedCheck = jdbcTemplate.queryForList(
                "SELECT bed_id FROM bed WHERE bed_id = ? AND status = 'Available' FOR UPDATE", bedId);
        if (bedCheck.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Bed is no longer available."));
        }

        // Lock & Verify Equipment
        List<Map<String, Object>> eqCheck = jdbcTemplate.queryForList(
                "SELECT equipment_id FROM equipment WHERE equipment_id = ? AND status = 'Available' FOR UPDATE", equipmentId);
        if (eqCheck.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Equipment is no longer available."));
        }

        // Insert allocation (Triggers flip Bed & Equipment to Occupied)
        jdbcTemplate.update(
                "INSERT INTO allocation (patient_id, bed_id, employee_id, equipment_id, status) VALUES (?, ?, ?, ?, 'Active')",
                patientId, bedId, doctorId, equipmentId
        );

        return ResponseEntity.ok(Map.of("message", "Allocation confirmed. Bed & Equipment marked Occupied via trigger."));
    }

    // 6. Discharge Patient
    @PutMapping("/allocations/{allocationId}/discharge")
    public ResponseEntity<?> dischargePatient(@PathVariable int allocationId) {
        int rows = jdbcTemplate.update(
                "UPDATE allocation SET status = 'Discharged', discharged_at = NOW() WHERE allocation_id = ? AND status = 'Active'",
                allocationId
        );
        if (rows == 0) {
            return ResponseEntity.badRequest().body(Map.of("error", "Active allocation not found or already discharged."));
        }
        return ResponseEntity.ok(Map.of("message", "Patient discharged successfully. Bed moved to Cleaning via trigger."));
    }

    // 7. List Active Allocations
    @GetMapping("/allocations/active")
    public List<Map<String, Object>> getActiveAllocations() {
        String sql = "SELECT a.allocation_id, a.allocated_at, " +
                     "p.name AS patient_name, p.triage_score, " +
                     "b.bed_number, eq.equipment_type, e.name AS doctor_name " +
                     "FROM allocation a " +
                     "JOIN patient p ON a.patient_id = p.patient_id " +
                     "JOIN bed b ON a.bed_id = b.bed_id " +
                     "JOIN equipment eq ON a.equipment_id = eq.equipment_id " +
                     "JOIN employee e ON a.employee_id = e.employee_id " +
                     "WHERE a.status = 'Active'";
        return jdbcTemplate.queryForList(sql);
    }
}