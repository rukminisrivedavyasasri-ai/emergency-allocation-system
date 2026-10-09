# 🏥 Healthcare Emergency Bed & Resource Allocation System

An automated full-stack emergency resource coordination platform that allocates hospital beds, critical medical equipment, and on-duty medical personnel based on emergency triage priority. The system enforces concurrency protection using database row-level locking and automates state transitions through database triggers.

---

## Table of Contents

- [Features](#features)
- [Architecture Overview](#architecture-overview)
- [Tech Stack](#tech-stack)
- [System Workflows & Logic](#system-workflows--logic)
- [Prerequisites](#prerequisites)
- [Setup & Installation](#setup--installation)
- [Running the Application](#running-the-application)
- [API Endpoints](#api-endpoints)
- [Database Design Highlights](#database-design-highlights)
- [Troubleshooting](#troubleshooting)
- [Future Enhancements](#future-enhancements)

---

## Features

- **Triage-based prioritization**: highest-acuity patients are served first.
- **Atomic resource matching**: bed + equipment + doctor are allocated together or not at all.
- **Concurrency safety**: `SELECT ... FOR UPDATE` row locks prevent double-booking.
- **Trigger-driven automation**: bed and equipment statuses update automatically on allocation and discharge.
- **Live dashboard**: occupancy and department load powered by SQL views.
- **Shift-aware staffing**: only doctors on duty at the current date/time are matched.

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

| Layer     | Technologies                                                              |
|-----------|---------------------------------------------------------------------------|
| Database  | MySQL 8.0 (Views, Triggers, Transactions, `FOR UPDATE` row locks)         |
| Backend   | Spring Boot 3.x, Java 17, Spring JDBC (`JdbcTemplate`), HikariCP          |
| Frontend  | React 18, Vite, Tailwind CSS, Lucide Icons                                |

---

## System Workflows & Logic

### 1. Triage Prioritization
- Patients are triaged from **1 (Resuscitation – Immediate)** to **5 (Non-Urgent)**.
- The allocation query serves the highest-acuity patients first (`ORDER BY triage_score ASC`).

### 2. Resource Matching Query
Matches, in a single query:
- an available **bed** of the required type,
- available **equipment** of the required type, and
- an **on-duty doctor** whose shift matches `CURDATE()` and `CURTIME()`.

### 3. Transactional Allocation
- Uses `SELECT ... FOR UPDATE` row locks to prevent double-booking beds or equipment during concurrent intake requests.
- Inserting an active record into `allocation` fires triggers that set bed and equipment status to `Occupied`.

### 4. Discharge & Sanitization
- Marking an allocation as `Discharged` automatically moves the bed from `Occupied` → `Cleaning` and the equipment from `Occupied` → `Available`.

```text
Patient intake → Triage score → Match bed + equipment + doctor (locked)
      → INSERT allocation → Trigger: Occupied
      → Discharge → Trigger: bed = Cleaning, equipment = Available
```

---

## Prerequisites

- **MySQL** 8.0+
- **Java** 17+ and **Maven** 3.8+
- **Node.js** 18+ and **npm**

---

## Setup & Installation

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd healthcare-emergency-allocation
```

### 2. Database Initialization (MySQL)

Log in to MySQL and run the scripts in this exact order:

```sql
SOURCE database/schema.sql;
SOURCE database/triggers.sql;
SOURCE database/views.sql;
SOURCE database/seed.sql;
```

> Optional: explore `database/basic_queries.sql` and `database/advanced_queries.sql` for sample operational and analytical queries.

### 3. Backend Configuration

Edit `backend/src/main/resources/application.properties` with your MySQL credentials:

```properties
spring.datasource.url=jdbc:mysql://localhost:3306/<your_database_name>
spring.datasource.username=<your_mysql_username>
spring.datasource.password=<your_mysql_password>
server.port=8080
```

### 4. Install Frontend Dependencies

```bash
cd frontend
npm install
```

---

## Running the Application

**Start the backend** (from `backend/`):

```bash
mvn spring-boot:run
```

The API will be available at `http://localhost:8080`.

**Start the frontend** (from `frontend/`):

```bash
npm run dev
```

The dashboard will be available at `http://localhost:5173` (Vite default).

---

## API Endpoints

> Update this table to match the routes defined in `ApiController.java`.

| Method | Endpoint                | Description                                        |
|--------|-------------------------|----------------------------------------------------|
| GET    | `/api/dashboard`        | Live occupancy and department load (from views)    |
| GET    | `/api/patients`         | List patients awaiting allocation                  |
| POST   | `/api/allocate`         | Allocate bed, equipment, and doctor (transactional)|
| POST   | `/api/discharge/{id}`   | Discharge an allocation and trigger status changes |

---

## Database Design Highlights

- **Constraints & foreign keys** keep patients, beds, equipment, doctors, and allocations consistent.
- **Triggers** automate bed/equipment status transitions, so application code can't leave resources in an inconsistent state.
- **Views** expose live occupancy and department load for the dashboard.
- **Row-level locking** (`FOR UPDATE`) inside a transaction guarantees no two concurrent requests claim the same resource.

---

## Troubleshooting

| Issue                                   | Fix                                                                 |
|-----------------------------------------|---------------------------------------------------------------------|
| `Access denied for user`                | Check username/password in `application.properties`.                |
| `Table doesn't exist`                   | Re-run the SQL scripts in the order listed above.                   |
| No doctor matched                       | Seed shifts must cover the current date/time; update `seed.sql`.    |
| CORS errors in browser                  | Enable CORS for `http://localhost:5173` in the backend.             |
| Port already in use                     | Change `server.port` or the Vite port.                              |

---

## Future Enhancements

- Authentication and role-based access (doctor, admin, triage nurse)
- Real-time updates via WebSockets
- Ambulance dispatch and ETA integration
- Analytics dashboard for wait times and utilization

---

## License

This project was developed for academic purposes as part of a DBMS course project.