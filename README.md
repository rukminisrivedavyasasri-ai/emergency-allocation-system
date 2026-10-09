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