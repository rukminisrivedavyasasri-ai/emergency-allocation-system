# Healthcare Emergency Bed & Resource Allocation System

An automated full-stack emergency resource coordination platform designed to allocate hospital beds, critical medical equipment, and on-duty medical personnel based on emergency triage priority. The system enforces concurrency protection using database row-level locking and automates state transitions via database triggers.

---

## Architecture Overview

```text
healthcare-emergency-allocation/
├── database/                   # MySQL DDL, Views, Triggers, & Seed Data
│   ├── schema.sql              # Core schema with constraints & foreign keys
│   ├── triggers.sql            # Automated bed/equipment state transition triggers
│   ├── views.sql               # Live dashboard views (occupancy, department load)
│   ├── seed.sql                # Seed dataset for demo & testing
│   ├── basic_queries.sql       # Baseline operational queries
│   └── advanced_queries.sql    # Complex matching & analytical queries
├── backend/                    # Spring Boot 3 + Java 17 REST API
│   ├── src/main/java/com/hospital/backend/
│   │   ├── BackendApplication.java
│   │   └── ApiController.java  # REST endpoints with transactional locking
│   └── src/main/resources/
│       └── application.properties
├── frontend/                   # React 18 + Vite + Tailwind CSS dashboard
│   ├── src/
│   │   ├── App.jsx             # Emergency monitoring & allocation UI
│   │   └── index.css           # Tailwind styling directives
│   ├── package.json
│   └── vite.config.js
└── README.md
```

---

## Tech Stack

- **Database**: MySQL 8.0 (Views, Triggers, Transactions, `FOR UPDATE` row locks)
- **Backend**: Spring Boot 3.x, Java 17, Spring JDBC (`JdbcTemplate`), HikariCP
- **Frontend**: React 18, Vite, Tailwind CSS, Lucide Icons

---

## System Workflows & Logic

1. **Triage Prioritization**
   - Patients are triaged from **1 (Resuscitation – Immediate)** to **5 (Non-Urgent)**.
   - Resource allocation queries prioritize highest-acuity patients first (`ORDER BY triage_score ASC`).
2. **Resource Matching Query**
   - Concurrently matches an available bed of the required type, available equipment of the required type, and an on-duty doctor whose shift schedule matches `CURDATE()` and `CURTIME()`.
3. **Transactional Allocation**
   - Employs `SELECT ... FOR UPDATE` row locks to prevent double-booking beds or equipment during concurrent intake requests.
   - Inserting an active record into `allocation` fires triggers that transition bed and equipment statuses to `Occupied`.
4. **Discharge & Sanitization**
   - Marking an allocation as `Discharged` automatically triggers the bed transition from `Occupied` → `Cleaning` and equipment from `Occupied` → `Available`.

---

## Setup & Installation

### 1. Database Initialization (MySQL)

Log in to MySQL and run the database setup scripts in this exact sequence:

```sql
SOURCE database/schema.sql;
SOURCE database/triggers.sql;
SOURCE database/views.sql;
SOURCE database/seed.sql;
```

Verify that the database `emergencydb` has been created and populated with sample departments, beds, equipment, and schedules.

### 2. Backend Configuration & Run (Spring Boot)

Open `backend/src/main/resources/application.properties` and verify your local MySQL credentials:

```properties
spring.datasource.url=jdbc:mysql://localhost:3306/emergencydb?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC
spring.datasource.username=root
spring.datasource.password=YOUR_MYSQL_PASSWORD
```

Open a terminal inside `backend/` and start the server:

```powershell
cd backend
.\mvnw.cmd spring-boot:run
```

The service will boot Apache Tomcat on `http://localhost:8080`.

### 3. Frontend Configuration & Run (React + Vite)

Open a second terminal inside `frontend/`:

```powershell
cd frontend
npm install
npm run dev
```

Open your browser and navigate to: `http://localhost:5173`

---

## API Endpoints Reference

| Method | Endpoint                              | Description                                                              |
|--------|---------------------------------------|--------------------------------------------------------------------------|
| GET    | `/api/dashboard/occupancy`            | Returns bed counts (available, occupied, cleaning) via `vw_current_occupancy` |
| GET    | `/api/dashboard/load`                 | Returns active resource utilization via `vw_department_load`             |
| POST   | `/api/patients`                       | Registers a new incoming emergency patient                               |
| GET    | `/api/allocations/match/{patientId}`  | Executes matching query for bed, equipment, and on-duty doctor           |
| POST   | `/api/allocations`                    | Transactionally locks resources and creates an active allocation         |
| GET    | `/api/allocations/active`             | Lists all active emergency allocations                                   |
| PUT    | `/api/allocations/{id}/discharge`     | Discharges patient; triggers update bed to Cleaning                      |

---

## Team Roles & Contributions

- **Person 1 (Database Architect)**: Designed the relational ER schema, normalization, foreign key constraints, analytical views (`vw_current_occupancy`, `vw_department_load`), and automated state transition triggers.
- **Person 2 (Backend API & Concurrency Engineer)**: Developed the Spring Boot 3 REST API using `JdbcTemplate`, managing transactional boundaries and row-level locking (`SELECT ... FOR UPDATE`) to prevent race conditions.
- **Person 3 (Frontend & UI/UX Engineer)**: Built the React + Vite dashboard with Tailwind CSS layouts and Lucide icons for triage monitoring, patient intake, and bed status views.
- **Person 4 (QA, Testing & Integration Engineer)**: Wrote test cases, tested concurrent booking collision scenarios, validated frontend–backend API integration, and prepared project documentation.