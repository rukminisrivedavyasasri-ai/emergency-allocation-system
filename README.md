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
│   │   └── ApiController.java  # REST Endpoints with transactional locking
│   └── src/main/resources/
│       └── application.properties
├── frontend/                   # React 18 + Vite + Tailwind CSS Dashboard
│   ├── src/
│   │   ├── App.jsx             # Emergency monitoring & allocation UI
│   │   └── index.css           # Tailwind styling directives
│   ├── package.json
│   └── vite.config.js
└── README.md
---

## Tech Stack

- **Database**: MySQL 8.0 (Views, Triggers, Transactions, `FOR UPDATE` Row Locks)
- **Backend**: Spring Boot 3.x, Java 17, Spring JDBC (`JdbcTemplate`), HikariCP
- **Frontend**: React 18, Vite, Tailwind CSS, Lucide Icons

---

## System Workflows & Logic

1. **Triage Prioritization**:
   - Patients are triaged from **1 (Resuscitation - Immediate)** to **5 (Non-Urgent)**.
   - Resource allocation query prioritizes highest-acuity patients first (`ORDER BY triage_score ASC`).
2. **Resource Matching Query**:
   - Concurrently matches an available bed of the required type, available equipment of the required type, and an on-duty doctor whose shift schedule matches `CURDATE()` and `CURTIME()`.
3. **Transactional Allocation**:
   - Employs `SELECT ... FOR UPDATE` row locks to prevent double-booking beds or equipment during concurrent intake requests.
   - Inserting an active record into `allocation` fires triggers that transition bed and equipment statuses to `Occupied`.
4. **Discharge & Sanitization**:
   - Marking an allocation as `Discharged` automatically triggers the bed transition from `Occupied` $\rightarrow$ `Cleaning` and equipment from `Occupied` $\rightarrow$ `Available`.

---

## Setup & Installation

### 1. Database Initialization (MySQL)

Log in to MySQL and run the SQL scripts in this exact order:

```sql
SOURCE database/schema.sql;
SOURCE database/triggers.sql;
SOURCE database/views.sql;
SOURCE database/seed.sql;