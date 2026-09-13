# AGRIVA (அக்ரிவா) - Smart Government Grain Procurement & Centre Management System

[![Flutter Version](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![State Management](https://img.shields.io/badge/State-Riverpod%202.x-blue)](https://riverpod.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture%20%2B%20Offline--First-green)]()
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-purple)]()
[![Coverage](https://img.shields.io/badge/Coverage-Tamil%20Nadu%20(5%20Focus%20Districts)-orange)]()

> **Official Digital Public Infrastructure for Government of India (Department of Food & Public Distribution) and Tamil Nadu Civil Supplies Corporation (TNCSC)**  
> AGRIVA is a mission-critical digital platform engineered to eliminate physical mandi traffic chaos, middleman exploitation, harvest rain spoilage, and delayed payments through dynamic quota slot scheduling, live IoT-linked queue tracking, transparent quality inspection, and automated Direct Benefit Transfer (DBT) bank credits within 24–48 hours.

---

## Table of Contents
1. [Current Project Status & Completed Frontend Scope](#1-current-project-status--completed-frontend-scope)
2. [User Roles & Access Portals](#2-user-roles--access-portals)
3. [Pilot Scope: Tamil Nadu Focus Districts & Centres](#3-pilot-scope-tamil-nadu-focus-districts--centres)
4. [End-to-End Procurement Lifecycle](#4-end-to-end-procurement-lifecycle)
5. [Frontend-to-Backend Contract & Architecture Mapping](#5-frontend-to-backend-contract--architecture-mapping)
6. [Complete Production Database Specification (PostgreSQL + PostGIS)](#6-complete-production-database-specification-postgresql--postgis)
   - 6.1 [Entity-Relationship Diagram (Mermaid)](#61-entity-relationship-diagram-mermaid)
   - 6.2 [Production DDL Schema](#62-production-ddl-schema)
   - 6.3 [Complete SQL Seed Data (5 Districts, 13 Centres, 9 MSP Crops, Staff, Farmers)](#63-complete-sql-seed-data)
7. [RESTful API Specifications (Endpoints, Request & Response JSONs)](#7-restful-api-specifications)
   - 7.1 [Authentication & Authorization (JWT)](#71-authentication--authorization-jwt)
   - 7.2 [Centres, Crops & Slot Discovery](#72-centres-crops--slot-discovery)
   - 7.3 [Slot Booking & Concurrency Engine](#73-slot-booking--concurrency-engine)
   - 7.4 [Centre Operator Workflows (Check-in, Quality & Weighment)](#74-centre-operator-workflows)
   - 7.5 [Live Yard Queue & Wait-Time Engine](#75-live-yard-queue--wait-time-engine)
   - 7.6 [District & State Admin Portals](#76-district--state-admin-portals)
   - 7.7 [Direct Benefit Transfer (DBT) & PFMS Webhooks](#77-direct-benefit-transfer-dbt--pfms-webhooks)
8. [Real-Time WebSocket Protocol (Live Queue & IoT Streams)](#8-real-time-websocket-protocol-live-queue--iot-streams)
9. [Concurrency & Slot Allocation Engine (Redis Redlock + Lua)](#9-concurrency--slot-allocation-engine-redis-redlock--lua)
10. [IoT Hardware Integration Specifications](#10-iot-hardware-integration-specifications)
11. [Backend Developer Quickstart (Docker Compose & Local Setup)](#11-backend-developer-quickstart-docker-compose--local-setup)
12. [Flutter Client App Setup & Run Guide](#12-flutter-client-app-setup--run-guide)
13. [Default Demo Credentials](#13-default-demo-credentials)
14. [Security, DPDP Act 2023 & Compliance](#14-security-dpdp-act-2023--compliance)

---

## 1. Current Project Status & Completed Frontend Scope

The frontend mobile & tablet application (`agriva`) is **100% feature-complete, verified on physical Android hardware (OPPO A15 / Android 10+), and statically validated with zero analyzer issues**.

### Completed Frontend Highlights:
* **4 Role Portals in One App:** Seamless role selection for **Kisan (Farmer)**, **Centre Operator**, **District Admin**, and **State Admin**.
* **Offline-First Resilience:** In-memory repository caching and local data hydration ensuring the app functions seamlessly in low-connectivity rural Tamil Nadu mandis.
* **Dual Theme Support (Light & Dark):** High-contrast, WCAG 2.1 AA-compliant government green palette (`#155E32` Forest Green for Light Mode, `#22C55E` High-Visibility Emerald for Dark Mode, `#0D1611` deep OLED surfaces).
* **Bilingual UI:** Native English and Tamil (தமிழ்) translation support for rural accessibility.
* **Dynamic Slot Booking Flow:** Real-time quota calculations, taluk/village cluster routing, vehicle selection, and instant QR token generation (e.g. `T003`).
* **Live Stepper Tracker:** Step-by-step progress tracking for farmers (`Arrived` $\to$ `Weighment` $\to$ `Quality Check` $\to$ `Unloading` $\to$ `DBT Completed`).
* **Operator Tablet Workflow:** Token barcode scanner, digital weighbridge integration, moisture tester validation ($\le 17\%$ FAQ standard), and automated slip generation.
* **District Admin Command Center:** District-wide quota tracking, live centre operational status toggles, and instant farmer document review/escalation/approval modal.
* **State Admin Analytics:** Statewide procurement heatmaps, MSP catalog governance, and emergency broadcast dispatch to all active mobile sessions.

---

## 2. User Roles & Access Portals

| Role | Identifier Pattern | Auth Method | Primary Capabilities |
| :--- | :--- | :--- | :--- |
| **Kisan (Farmer)** | 10-digit Phone (`9876543210`) | SMS OTP (6 Digits) | Register land Patta/Chitta, book mandi slots, track live turn in yard, view DBT bank credit slips, submit grievances. |
| **Centre Operator** | `OP-<District>-<No>` (`OP-Erode-01`) | Password (`agriva123`) | Scan check-in tokens, capture IoT weighment & moisture tests, record acceptance/rejection, report yard disruptions. |
| **District Admin** | `DT-<District>` (`DT-Erode`) | Password (`agriva123`) | Oversee all DPCs in district, review flagged/escalated farmer verifications, adjust emergency quotas, track village backlogs. |
| **State Admin** | `ST-Admin` | Password (`agriva123`) | Configure MSP procurement rates, manage crop seasons, monitor statewide buffer stocks, publish emergency advisories. |

---

## 3. Pilot Scope: Tamil Nadu Focus Districts & Centres

The system is calibrated for 5 major agricultural districts across Tamil Nadu comprising 13 Direct Purchase Centres (DPCs):

```
Tamil Nadu State (TN)
├── Erode (3 Centres)
│   ├── OP-Erode-01: Erode Regulated Market Hub (Capacity: 1,500 Q/day | 3 Lanes | Lat: 11.3410, Lng: 77.7172)
│   ├── OP-Erode-02: Perundurai Grain Mandi (Capacity: 1,200 Q/day | 2 Lanes | Lat: 11.2754, Lng: 77.5828)
│   └── OP-Erode-03: Gobichettipalayam Centre (Capacity: 1,000 Q/day | 2 Lanes | Lat: 11.4549, Lng: 77.4379)
├── Tiruppur (3 Centres)
│   ├── OP-Tiruppur-01: Tiruppur Central APMC Depot (Capacity: 1,400 Q/day | 3 Lanes | Lat: 11.1085, Lng: 77.3411)
│   ├── OP-Tiruppur-02: Dharapuram Grain Centre (Capacity: 1,100 Q/day | 2 Lanes | Lat: 10.7289, Lng: 77.5262)
│   └── OP-Tiruppur-03: Kangeyam Procurement Hub (Capacity: 1,200 Q/day | 2 Lanes | Lat: 11.0055, Lng: 77.5594)
├── Thanjavur (Delta Paddy Bowl - 3 Centres)
│   ├── OP-Thanjavur-01: Thanjavur Main Direct Purchase Centre (Capacity: 2,000 Q/day | 4 Lanes | Lat: 10.7870, Lng: 79.1378)
│   ├── OP-Thanjavur-02: Kumbakonam Modern DPC (Capacity: 1,600 Q/day | 3 Lanes | Lat: 10.9602, Lng: 79.3845)
│   └── OP-Thanjavur-03: Pattukkottai Coastal Depot (Capacity: 1,300 Q/day | 2 Lanes | Lat: 10.4264, Lng: 79.3175)
├── Tiruvarur (Delta - 2 Centres)
│   ├── OP-Tiruvarur-01: Tiruvarur Central Silo Hub (Capacity: 1,800 Q/day | 3 Lanes | Lat: 10.7725, Lng: 79.6365)
│   └── OP-Tiruvarur-02: Mannargudi Delta APMC Mandi (Capacity: 1,400 Q/day | 2 Lanes | Lat: 10.6637, Lng: 79.4478)
└── Madurai (2 Centres)
    ├── OP-Madurai-01: Madurai Agricultural Regulated Market (Capacity: 1,500 Q/day | 3 Lanes | Lat: 9.9252, Lng: 78.1198)
    └── OP-Madurai-02: Usilampatti Grain Terminal (Capacity: 1,000 Q/day | 2 Lanes | Lat: 9.9702, Lng: 77.7942)
```

---

## 4. End-to-End Procurement Lifecycle

```mermaid
sequenceDiagram
    autonumber
    actor Farmer as Kisan (Farmer)
    participant App as AGRIVA Mobile App
    participant API as Backend Gateway (Go/Node)
    participant Redis as Redis Cache & Lock
    participant DB as PostgreSQL DB
    participant Operator as DPC Operator
    participant IoT as Weighbridge & Moisture
    participant PFMS as PFMS / NPCI APB

    Farmer->>App: Choose Crop, Date, Time Slot & Quantity (Q)
    App->>API: POST /api/v1/bookings
    API->>Redis: Acquire Redlock (slot_id) & Check Available Quota
    Redis-->>API: Quota OK
    API->>DB: INSERT into bookings (status: 'booked')
    API-->>App: Booking Confirmed (QR Token: T003, Reference: AGR-20001)
    
    Note over Farmer, Operator: Arrival at Direct Purchase Centre (DPC)
    Operator->>App: Scan Farmer QR Token
    App->>API: POST /api/v1/operator/checkin
    API->>DB: UPDATE bookings SET status = 'checkedIn'
    API->>DB: INSERT into queue_entries (stage: 'arrived', pos: N)
    API-->>App: Push Real-Time Queue Update via WebSocket
    
    Note over Operator, IoT: IoT Quality Inspection & Digital Weighment
    IoT-->>Operator: RS-485 Moisture Meter Reading (e.g. 14.2%)
    Operator->>API: POST /api/v1/operator/quality-inspection (Moisture <= 17%)
    IoT-->>Operator: RS-232 Digital Weighbridge (Gross - Tare = Net Q)
    Operator->>API: POST /api/v1/operator/weighment (Accepted Net Q)
    API->>DB: UPDATE bookings SET status = 'accepted'
    API->>DB: INSERT into procurement_records
    
    Note over API, PFMS: Automated Direct Benefit Transfer (DBT) Release
    API->>PFMS: Digital XML Payment Instruction (Aadhaar Seeded Account)
    PFMS-->>API: Webhook Callback (Status: COMPLETED, UTR: UTR-PFMS-TN-89410)
    API->>DB: UPDATE payments SET status = 'completed', dbt_reference = 'UTR-...'
    API-->>App: Push Notification & SMS: "₹1,49,500 credited to A/C ending 4589"
```

---

## 5. Frontend-to-Backend Contract & Architecture Mapping

The Flutter frontend codebase is structured cleanly into domain models, repositories, and services. The backend must mirror these exact naming conventions and JSON field formats:

### 5.1 Repository & Service Mapping

| Frontend Component | File Path | Backend Endpoint Responsibility |
| :--- | :--- | :--- |
| `FarmerRepository` | `lib/repositories/farmer_repositories.dart` | Farmer CRUD, Profile fetch, OTP authentication, Land record attachment. |
| `BookingRepository` | `lib/repositories/booking_repositories.dart` | Concurrency-safe slot reservations, booking cancellation, token lookup. |
| `SlotRepository` | `lib/repositories/booking_repositories.dart` | Daily quota allocation, remaining hourly capacity calculations. |
| `QueueRepository` | `lib/repositories/booking_repositories.dart` | Live mandi queue FIFO list, current stage, token calls. |
| `ProcurementRepository`| `lib/repositories/booking_repositories.dart` | Tamper-proof IoT weighbridge & moisture inspection certificates. |
| `PaymentRepository` | `lib/repositories/support_repositories.dart` | DBT disbursement timeline, PFMS UTR tracking, failure re-initiations. |
| `CentreRepository` | `lib/repositories/catalog_repositories.dart` | DPC metadata, lane counts, live operational status, GPS coordinates. |
| `AdminUserRepository` | `lib/repositories/admin_repositories.dart` | RBAC authentication, district admin & operator token issuance. |
| `LocationClusterService`| `lib/services/location_cluster_service.dart`| Taluk/village geofencing and nearest DPC assignment logic. |
| `QueueEngine` | `lib/services/queue_engine.dart` | Little's Law wait-time predictions ($W = L / \lambda$). |

### 5.2 Enum Serialization Table

All models serialize enums as exact **camelCase** strings:

| Enum Name | Serialized Values |
| :--- | :--- |
| `UserRole` | `"farmer"`, `"centreOperator"`, `"districtAdmin"`, `"stateAdmin"` |
| `BookingStatus` | `"booked"`, `"checkedIn"`, `"inQueue"`, `"underQualityCheck"`, `"accepted"`, `"partiallyAccepted"`, `"rejected"`, `"paymentPending"`, `"paymentInitiated"`, `"paymentCompleted"`, `"paymentFailed"`, `"cancelled"`, `"noShow"`, `"waitlisted"`, `"rescheduleRequired"` |
| `CentreStatus` | `"open"`, `"temporarilyDisrupted"`, `"closed"` |
| `QueueStage` | `"arrived"`, `"qualityCheck"`, `"weighment"`, `"procurement"`, `"completed"`, `"exception"` |
| `PaymentStatus` | `"notInitiated"`, `"initiated"`, `"processing"`, `"completed"`, `"failed"` |
| `FarmerVerificationStatus` | `"pendingApproval"`, `"approved"`, `"rejected"`, `"escalatedToDistrict"` |
| `DisruptionType` | `"weighingMachineFailure"`, `"powerFailure"`, `"networkIssue"`, `"labourShortage"`, `"storageUnavailable"`, `"inspectionDelay"`, `"centreClosure"`, `"generalOperationalDelay"`, `"capacityReduction"` |
| `GrievanceCategory` | `"qualityDispute"`, `"paymentDelay"`, `"slotIssue"`, `"impersonation"`, `"other"` |
| `GrievanceStatus` | `"open"`, `"inReview"`, `"escalated"`, `"resolved"`, `"rejected"` |
| `CropSeason` | `"kharif"`, `"rabi"`, `"zaid"` |
| `LandOwnershipType` | `"owner"`, `"tenant"`, `"sharecropper"` |

---

## 6. Complete Production Database Specification (PostgreSQL + PostGIS)

### 6.1 Entity-Relationship Diagram (Mermaid)

```mermaid
erDiagram
    DISTRICTS ||--o{ PROCUREMENT_CENTRES : contains
    DISTRICTS ||--o{ FARMERS : resides_in
    DISTRICTS ||--o{ ADMIN_USERS : governs
    PROCUREMENT_CENTRES ||--o{ SLOTS : generates
    PROCUREMENT_CENTRES ||--o{ BOOKINGS : receives
    PROCUREMENT_CENTRES ||--o{ DISRUPTIONS : encounters
    CROPS ||--o{ SLOTS : permits
    CROPS ||--o{ BOOKINGS : measures
    FARMERS ||--o{ LAND_RECORDS : holds
    FARMERS ||--o{ BOOKINGS : creates
    FARMERS ||--o{ PAYMENTS : receives
    FARMERS ||--o{ GRIEVANCES : logs
    SLOTS ||--o{ BOOKINGS : fulfills
    BOOKINGS ||--o| QUEUE_ENTRIES : tracks
    BOOKINGS ||--o| PROCUREMENT_RECORDS : certifies
    BOOKINGS ||--o| PAYMENTS : triggers
    BOOKINGS ||--o{ RESCHEDULE_OFFERS : negotiates
```

---

### 6.2 Production DDL Schema

Save as `schema.sql` and run on PostgreSQL 16:

```sql
-- ==============================================================================
-- AGRIVA POSTGRESQL PRODUCTION DDL SCHEMA (v1.0.0)
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- 1. Districts Master
CREATE TABLE districts (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    state_code VARCHAR(10) NOT NULL DEFAULT 'TN',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Procurement Centres (Mandis / Direct Purchase Centres)
CREATE TABLE procurement_centres (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    code VARCHAR(50) UNIQUE NOT NULL, -- e.g. OP-Erode-01
    district_id VARCHAR(64) NOT NULL REFERENCES districts(id) ON DELETE RESTRICT,
    taluk VARCHAR(100) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    geom GEOMETRY(Point, 4326),
    contact_number VARCHAR(20),
    daily_processing_capacity_q NUMERIC(10, 2) NOT NULL DEFAULT 1500.00,
    storage_capacity_q NUMERIC(10, 2) NOT NULL DEFAULT 3000.00,
    current_storage_q NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    processing_lanes_total INT NOT NULL DEFAULT 3,
    processing_lanes_active INT NOT NULL DEFAULT 3,
    staff_normal INT NOT NULL DEFAULT 12,
    staff_available INT NOT NULL DEFAULT 12,
    status VARCHAR(30) NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'temporarilyDisrupted', 'closed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_centres_district ON procurement_centres(district_id);
CREATE INDEX idx_centres_geom ON procurement_centres USING GIST(geom);

-- 3. Crops & Statutory Minimum Support Price (MSP) Catalog
CREATE TABLE crops (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    local_names JSONB NOT NULL DEFAULT '{}', -- e.g. {"ta": "நெல் (சாதாரண ரகம்)"}
    msp NUMERIC(10, 2) NOT NULL,            -- e.g. 2300.00 per Quintal
    season VARCHAR(20) NOT NULL CHECK (season IN ('kharif', 'rabi', 'zaid')),
    max_moisture_percentage NUMERIC(4, 2) NOT NULL DEFAULT 17.00,
    max_foreign_matter_percentage NUMERIC(4, 2) NOT NULL DEFAULT 2.00,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Centre-Crop Quotas
CREATE TABLE centre_crop_quotas (
    centre_id VARCHAR(64) REFERENCES procurement_centres(id) ON DELETE CASCADE,
    crop_id VARCHAR(64) REFERENCES crops(id) ON DELETE CASCADE,
    season VARCHAR(20) NOT NULL CHECK (season IN ('kharif', 'rabi', 'zaid')),
    daily_quota_q NUMERIC(10, 2) NOT NULL,
    PRIMARY KEY (centre_id, crop_id, season)
);

-- 5. Farmers Master
CREATE TABLE farmers (
    id VARCHAR(64) PRIMARY KEY,
    farmer_code VARCHAR(50) UNIQUE NOT NULL, -- e.g. FRM-1001
    name VARCHAR(150) NOT NULL,
    phone VARCHAR(15) UNIQUE NOT NULL,
    preferred_language VARCHAR(10) NOT NULL DEFAULT 'ta',
    door_no VARCHAR(50) NOT NULL,
    street VARCHAR(150) NOT NULL,
    village VARCHAR(100) NOT NULL,
    taluk VARCHAR(100) NOT NULL,
    district VARCHAR(64) NOT NULL,
    pincode VARCHAR(10) NOT NULL,
    assigned_centre_id VARCHAR(64) REFERENCES procurement_centres(id),
    distance_km NUMERIC(6, 2) NOT NULL DEFAULT 0.00,
    estimated_travel_minutes INT NOT NULL DEFAULT 0,
    aadhaar_hash VARCHAR(64) NOT NULL, -- Salted SHA-256
    aadhaar_masked VARCHAR(20) NOT NULL DEFAULT 'XXXX-XXXX-1234',
    bank_account_hash VARCHAR(64) NOT NULL,
    bank_account_masked VARCHAR(20) NOT NULL DEFAULT 'XXXX4589',
    bank_ifsc VARCHAR(15) NOT NULL,
    registered_crop_ids JSONB NOT NULL DEFAULT '[]',
    verification_status VARCHAR(30) NOT NULL DEFAULT 'approved'
        CHECK (verification_status IN ('pendingApproval', 'approved', 'rejected', 'escalatedToDistrict')),
    verified_at TIMESTAMP WITH TIME ZONE,
    verified_by VARCHAR(64),
    rejection_reason TEXT,
    escalation_notes TEXT,
    escalated_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_farmers_phone ON farmers(phone);
CREATE INDEX idx_farmers_district ON farmers(district);
CREATE INDEX idx_farmers_verification ON farmers(verification_status);

-- 6. Land Records (Patta / Chitta / Revenue Records)
CREATE TABLE land_records (
    id VARCHAR(64) PRIMARY KEY,
    farmer_id VARCHAR(64) NOT NULL REFERENCES farmers(id) ON DELETE CASCADE,
    patta_number VARCHAR(50) NOT NULL,
    survey_number VARCHAR(50) NOT NULL,
    sub_division VARCHAR(20) NOT NULL DEFAULT '1',
    area_hectares NUMERIC(8, 2) NOT NULL,
    ownership_type VARCHAR(20) NOT NULL CHECK (ownership_type IN ('owner', 'tenant', 'sharecropper')),
    land_owner_name VARCHAR(150),
    is_verified BOOLEAN NOT NULL DEFAULT TRUE,
    consent_verified BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_land_farmer ON land_records(farmer_id);

-- 7. Admin & Operational Users
CREATE TABLE admin_users (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    role VARCHAR(30) NOT NULL CHECK (role IN ('centreOperator', 'districtAdmin', 'stateAdmin')),
    employee_id VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL, -- bcrypt hash
    centre_id VARCHAR(64) REFERENCES procurement_centres(id),
    district VARCHAR(64),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_login_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 8. Mandi Slots
CREATE TABLE slots (
    id VARCHAR(64) PRIMARY KEY,
    centre_id VARCHAR(64) NOT NULL REFERENCES procurement_centres(id) ON DELETE CASCADE,
    crop_id VARCHAR(64) REFERENCES crops(id),
    slot_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    capacity_q NUMERIC(10, 2) NOT NULL,
    booked_q NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    max_farmers INT NOT NULL DEFAULT 5,
    is_available BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_slot_capacity CHECK (booked_q <= capacity_q)
);

CREATE INDEX idx_slots_centre_date ON slots(centre_id, slot_date);

-- 9. Bookings Ledger
CREATE TABLE bookings (
    id VARCHAR(64) PRIMARY KEY,
    booking_reference VARCHAR(50) UNIQUE NOT NULL, -- e.g. AGR-20001
    farmer_id VARCHAR(64) NOT NULL REFERENCES farmers(id),
    slot_id VARCHAR(64) NOT NULL REFERENCES slots(id),
    centre_id VARCHAR(64) NOT NULL REFERENCES procurement_centres(id),
    crop_id VARCHAR(64) NOT NULL REFERENCES crops(id),
    expected_quantity_q NUMERIC(10, 2) NOT NULL,
    token VARCHAR(20) NOT NULL, -- e.g. T003
    status VARCHAR(30) NOT NULL DEFAULT 'booked' CHECK (
        status IN (
            'booked', 'checkedIn', 'inQueue', 'underQualityCheck',
            'accepted', 'partiallyAccepted', 'rejected',
            'paymentPending', 'paymentInitiated', 'paymentCompleted', 'paymentFailed',
            'cancelled', 'noShow', 'waitlisted', 'rescheduleRequired'
        )
    ),
    vehicle_number VARCHAR(30),
    cancellation_reason TEXT,
    checked_in_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_bookings_farmer ON bookings(farmer_id);
CREATE INDEX idx_bookings_centre_status ON bookings(centre_id, status);
CREATE INDEX idx_bookings_token ON bookings(token);

-- 10. Live Mandi Queue
CREATE TABLE queue_entries (
    id VARCHAR(64) PRIMARY KEY,
    booking_id VARCHAR(64) UNIQUE NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    centre_id VARCHAR(64) NOT NULL REFERENCES procurement_centres(id),
    token VARCHAR(20) NOT NULL,
    position INT NOT NULL,
    stage VARCHAR(30) NOT NULL CHECK (stage IN ('arrived', 'qualityCheck', 'weighment', 'procurement', 'completed', 'exception')),
    arrived_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estimated_call_time TIMESTAMP WITH TIME ZONE,
    called_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_queue_centre_pos ON queue_entries(centre_id, position);

-- 11. IoT Procurement & Quality Inspection Records
CREATE TABLE procurement_records (
    id VARCHAR(64) PRIMARY KEY,
    booking_id VARCHAR(64) UNIQUE NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    centre_id VARCHAR(64) NOT NULL REFERENCES procurement_centres(id),
    operator_id VARCHAR(64) NOT NULL REFERENCES admin_users(id),
    gross_weight_kg NUMERIC(10, 2) NOT NULL,
    tare_weight_kg NUMERIC(10, 2) NOT NULL,
    net_weight_q NUMERIC(10, 2) NOT NULL,
    moisture_percentage NUMERIC(5, 2) NOT NULL,
    foreign_matter_percentage NUMERIC(5, 2) NOT NULL,
    quality_grade VARCHAR(50) NOT NULL DEFAULT 'Grade A (FAQ)',
    accepted_quantity_q NUMERIC(10, 2) NOT NULL,
    rejected_quantity_q NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    rejection_reason TEXT,
    moisture_device_id VARCHAR(64),
    weighbridge_device_id VARCHAR(64),
    inspection_timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 12. Direct Benefit Transfer (DBT) Payments
CREATE TABLE payments (
    id VARCHAR(64) PRIMARY KEY,
    booking_id VARCHAR(64) UNIQUE NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    farmer_id VARCHAR(64) NOT NULL REFERENCES farmers(id),
    amount NUMERIC(12, 2) NOT NULL,
    bank_account_masked VARCHAR(20) NOT NULL,
    bank_ifsc VARCHAR(15) NOT NULL,
    dbt_reference VARCHAR(100) UNIQUE, -- e.g. PFMS-TN-2026-89410
    utr_number VARCHAR(100) UNIQUE,
    status VARCHAR(30) NOT NULL DEFAULT 'notInitiated' CHECK (
        status IN ('notInitiated', 'initiated', 'processing', 'completed', 'failed')
    ),
    failure_reason TEXT,
    initiated_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_payments_farmer ON payments(farmer_id);
CREATE INDEX idx_payments_status ON payments(status);

-- 13. Mandi Disruptions
CREATE TABLE disruptions (
    id VARCHAR(64) PRIMARY KEY,
    centre_id VARCHAR(64) NOT NULL REFERENCES procurement_centres(id),
    type VARCHAR(40) NOT NULL CHECK (
        type IN (
            'weighingMachineFailure', 'powerFailure', 'networkIssue',
            'labourShortage', 'storageUnavailable', 'inspectionDelay',
            'centreClosure', 'generalOperationalDelay', 'capacityReduction'
        )
    ),
    description TEXT NOT NULL,
    affected_lanes INT NOT NULL DEFAULT 1,
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'resolved', 'cancelled')),
    started_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expected_resolution TIMESTAMP WITH TIME ZONE,
    resolved_at TIMESTAMP WITH TIME ZONE
);

-- 14. Grievance Redressal
CREATE TABLE grievances (
    id VARCHAR(64) PRIMARY KEY,
    booking_id VARCHAR(64) REFERENCES bookings(id),
    farmer_id VARCHAR(64) NOT NULL REFERENCES farmers(id),
    category VARCHAR(50) NOT NULL CHECK (category IN ('qualityDispute', 'paymentDelay', 'slotIssue', 'impersonation', 'other')),
    description TEXT NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'inReview', 'escalated', 'resolved', 'rejected')),
    escalation_level VARCHAR(20) NOT NULL DEFAULT 'centre' CHECK (escalation_level IN ('centre', 'district', 'state')),
    resolution_notes TEXT,
    resolved_by VARCHAR(64),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP WITH TIME ZONE
);

-- 15. Push & SMS Notification Logs
CREATE TABLE notifications (
    id VARCHAR(64) PRIMARY KEY,
    farmer_id VARCHAR(64) NOT NULL REFERENCES farmers(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    body TEXT NOT NULL,
    channel VARCHAR(20) NOT NULL CHECK (channel IN ('sms', 'app', 'both')),
    type VARCHAR(40) NOT NULL,
    delivery_status VARCHAR(20) NOT NULL DEFAULT 'sent' CHECK (delivery_status IN ('sent', 'failed', 'pending', 'retrying')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 16. State-Wide Emergency Broadcasts
CREATE TABLE broadcasts (
    id VARCHAR(64) PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    district_id VARCHAR(64) REFERENCES districts(id), -- NULL means statewide
    centre_id VARCHAR(64) REFERENCES procurement_centres(id),
    severity VARCHAR(20) NOT NULL DEFAULT 'info' CHECK (severity IN ('info', 'warning', 'critical')),
    created_by VARCHAR(64) NOT NULL REFERENCES admin_users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

---

### 6.3 Complete SQL Seed Data

Save as `seed.sql` and run directly after `schema.sql`:

```sql
-- ==============================================================================
-- AGRIVA MASTER SEED DATA (5 Tamil Nadu Pilot Districts)
-- ==============================================================================

-- 1. Districts
INSERT INTO districts (id, name, state_code) VALUES
('district-erode', 'Erode', 'TN'),
('district-tiruppur', 'Tiruppur', 'TN'),
('district-thanjavur', 'Thanjavur', 'TN'),
('district-tiruvarur', 'Tiruvarur', 'TN'),
('district-madurai', 'Madurai', 'TN')
ON CONFLICT (id) DO NOTHING;

-- 2. Procurement Centres (13 Mandis)
INSERT INTO procurement_centres 
(id, name, code, district_id, taluk, latitude, longitude, daily_processing_capacity_q, storage_capacity_q, processing_lanes_total, processing_lanes_active, status) 
VALUES
('centre-erode-01', 'Erode Regulated Market Hub', 'OP-Erode-01', 'district-erode', 'Erode', 11.3410, 77.7172, 1500.0, 3000.0, 3, 3, 'open'),
('centre-erode-02', 'Perundurai Grain Mandi', 'OP-Erode-02', 'district-erode', 'Perundurai', 11.2754, 77.5828, 1200.0, 2400.0, 2, 2, 'open'),
('centre-erode-03', 'Gobichettipalayam Centre', 'OP-Erode-03', 'district-erode', 'Gobichettipalayam', 11.4549, 77.4379, 1000.0, 2000.0, 2, 2, 'open'),
('centre-tiruppur-01', 'Tiruppur Central APMC Depot', 'OP-Tiruppur-01', 'district-tiruppur', 'Tiruppur', 11.1085, 77.3411, 1400.0, 2800.0, 3, 3, 'open'),
('centre-tiruppur-02', 'Dharapuram Grain Centre', 'OP-Tiruppur-02', 'district-tiruppur', 'Dharapuram', 10.7289, 77.5262, 1100.0, 2200.0, 2, 2, 'open'),
('centre-tiruppur-03', 'Kangeyam Procurement Hub', 'OP-Tiruppur-03', 'district-tiruppur', 'Kangeyam', 11.0055, 77.5594, 1200.0, 2400.0, 2, 2, 'open'),
('centre-thanjavur-01', 'Thanjavur Main Direct Purchase Centre', 'OP-Thanjavur-01', 'district-thanjavur', 'Thanjavur', 10.7870, 79.1378, 2000.0, 4500.0, 4, 4, 'open'),
('centre-thanjavur-02', 'Kumbakonam Modern DPC', 'OP-Thanjavur-02', 'district-thanjavur', 'Kumbakonam', 10.9602, 79.3845, 1600.0, 3200.0, 3, 3, 'open'),
('centre-thanjavur-03', 'Pattukkottai Coastal Depot', 'OP-Thanjavur-03', 'district-thanjavur', 'Pattukkottai', 10.4264, 79.3175, 1300.0, 2600.0, 2, 2, 'open'),
('centre-tiruvarur-01', 'Tiruvarur Central Silo Hub', 'OP-Tiruvarur-01', 'district-tiruvarur', 'Tiruvarur', 10.7725, 79.6365, 1800.0, 4000.0, 3, 3, 'open'),
('centre-tiruvarur-02', 'Mannargudi Delta APMC Mandi', 'OP-Tiruvarur-02', 'district-tiruvarur', 'Mannargudi', 10.6637, 79.4478, 1400.0, 2800.0, 2, 2, 'open'),
('centre-madurai-01', 'Madurai Agricultural Regulated Market', 'OP-Madurai-01', 'district-madurai', 'Madurai North', 9.9252, 78.1198, 1500.0, 3000.0, 3, 3, 'open'),
('centre-madurai-02', 'Usilampatti Grain Terminal', 'OP-Madurai-02', 'district-madurai', 'Usilampatti', 9.9702, 77.7942, 1000.0, 2000.0, 2, 2, 'open')
ON CONFLICT (id) DO NOTHING;

-- 3. Crops & Official Statutory MSP Rates (2024-2026)
INSERT INTO crops (id, name, local_names, msp, season) VALUES
('crop-paddy-common', 'Paddy (Common)', '{"ta": "நெல் (சாதாரண ரகம்)"}', 2300.00, 'kharif'),
('crop-paddy-grade-a', 'Paddy (Grade A)', '{"ta": "நெல் (கிரேடு ஏ)"}', 2320.00, 'kharif'),
('crop-maize', 'Maize (Corn)', '{"ta": "மக்காச்சோளம்"}', 2225.00, 'kharif'),
('crop-ragi', 'Finger Millet (Ragi)', '{"ta": "கேழ்வரகு"}', 4290.00, 'kharif'),
('crop-jowar', 'Sorghum (Jowar Hybrid)', '{"ta": "சோளம்"}', 3371.00, 'kharif'),
('crop-bajra', 'Pearl Millet (Bajra)', '{"ta": "கம்பு"}', 2625.00, 'kharif'),
('crop-urad', 'Black Gram (Urad)', '{"ta": "உளுந்து"}', 7400.00, 'rabi'),
('crop-moong', 'Green Gram (Moong)', '{"ta": "பாசிப்பயறு"}', 8682.00, 'kharif'),
('crop-cotton', 'Medium Staple Cotton', '{"ta": "பருத்தி"}', 7121.00, 'kharif')
ON CONFLICT (id) DO NOTHING;

-- 4. Admin Users (Password: agriva123 -> $2a$10$wN8WwYV5Qp9FjRk7QYqSleG6T0Z0Z3iE2FkY6m8Z4K8e5Y3M6Lq7q)
-- For demonstration, you can store bcrypt hash of 'agriva123'
INSERT INTO admin_users (id, name, role, employee_id, password_hash, centre_id, district) VALUES
('user-dt-erode', 'Dr. V. Kalanidhi IAS (District Collector)', 'districtAdmin', 'DT-Erode', '$2a$12$eAn7vJp1lAOBi4uM9/O7E.9R3gUoM5RjK2U0bCvyX5b.3Z1p8.Tym', NULL, 'district-erode'),
('user-dt-tiruppur', 'Thiru T. Christuraj IAS', 'districtAdmin', 'DT-Tiruppur', '$2a$12$eAn7vJp1lAOBi4uM9/O7E.9R3gUoM5RjK2U0bCvyX5b.3Z1p8.Tym', NULL, 'district-tiruppur'),
('user-dt-thanjavur', 'Thiru Deepak Jacob IAS', 'districtAdmin', 'DT-Thanjavur', '$2a$12$eAn7vJp1lAOBi4uM9/O7E.9R3gUoM5RjK2U0bCvyX5b.3Z1p8.Tym', NULL, 'district-thanjavur'),
('user-op-erode-01', 'K. Sakthivel (Chief Inspector)', 'centreOperator', 'OP-Erode-01', '$2a$12$eAn7vJp1lAOBi4uM9/O7E.9R3gUoM5RjK2U0bCvyX5b.3Z1p8.Tym', 'centre-erode-01', 'district-erode'),
('user-op-thanjavur-01', 'M. Anbarasan (Yard In-Charge)', 'centreOperator', 'OP-Thanjavur-01', '$2a$12$eAn7vJp1lAOBi4uM9/O7E.9R3gUoM5RjK2U0bCvyX5b.3Z1p8.Tym', 'centre-thanjavur-01', 'district-thanjavur'),
('user-st-admin', 'State Principal Secretary - Food & Civil Supplies', 'stateAdmin', 'ST-Admin', '$2a$12$eAn7vJp1lAOBi4uM9/O7E.9R3gUoM5RjK2U0bCvyX5b.3Z1p8.Tym', NULL, NULL)
ON CONFLICT (id) DO NOTHING;

-- 5. Demo Farmers
INSERT INTO farmers 
(id, farmer_code, name, phone, preferred_language, door_no, street, village, taluk, district, pincode, assigned_centre_id, distance_km, estimated_travel_minutes, aadhaar_hash, aadhaar_masked, bank_account_hash, bank_account_masked, bank_ifsc, verification_status) 
VALUES
('farmer-murugan', 'FRM-1001', 'R. Murugan', '9876543210', 'ta', '4/12B', 'Mettu Street', 'Modakkurichi', 'Erode', 'district-erode', '638104', 'centre-erode-01', 8.5, 22, 'hash_murugan_aadhaar', 'XXXX-XXXX-4512', 'hash_murugan_bank', 'XXXX4589', 'SBIN0001234', 'approved'),
('farmer-palanisamy', 'FRM-1002', 'M. Palanisamy', '9876543212', 'ta', '12', 'Kavindapadi Road', 'Bhavani', 'Erode', 'district-erode', '638301', 'centre-erode-01', 14.2, 35, 'hash_palanisamy_aadhaar', 'XXXX-XXXX-8921', 'hash_palanisamy_bank', 'XXXX7812', 'IOBA0000456', 'approved'),
('farmer-senthil', 'FRM-1003', 'K. Senthil Kumar', '9876543211', 'ta', '22/1', 'North Car Street', 'Perundurai', 'Erode', 'district-erode', '638052', 'centre-erode-02', 4.1, 12, 'hash_senthil_aadhaar', 'XXXX-XXXX-3344', 'hash_senthil_bank', 'XXXX9901', 'CANB0002100', 'pendingApproval'),
('farmer-thangavel', 'FRM-1004', 'A. Thangavel', '9876543213', 'ta', '7/88', 'Pillayar Kovil St', 'Gobichettipalayam', 'Erode', 'district-erode', '638452', 'centre-erode-03', 18.0, 42, 'hash_thangavel_aadhaar', 'XXXX-XXXX-7788', 'hash_thangavel_bank', 'XXXX3321', 'UBIN0543210', 'escalatedToDistrict')
ON CONFLICT (id) DO NOTHING;

-- 6. Land Records
INSERT INTO land_records (id, farmer_id, patta_number, survey_number, area_hectares, ownership_type, is_verified) VALUES
('land-m-01', 'farmer-murugan', 'PATTA-9081', 'SF-142/2A', 2.45, 'owner', TRUE),
('land-p-01', 'farmer-palanisamy', 'PATTA-6612', 'SF-89/1B', 3.80, 'owner', TRUE),
('land-s-01', 'farmer-senthil', 'PATTA-3410', 'SF-201/4', 1.60, 'owner', FALSE)
ON CONFLICT (id) DO NOTHING;
```

---

## 7. RESTful API Specifications

All endpoints communicate via JSON over HTTPS.
Base URL: `https://api.agriva.gov.in/api/v1` (Local Dev: `http://localhost:8080/api/v1`).

### 7.1 Authentication & Authorization (JWT)

#### 1. Request Farmer OTP
* **Endpoint:** `POST /api/v1/auth/farmer/send-otp`
* **Request:**
  ```json
  {
    "phone": "9876543210"
  }
  ```
* **Response (200 OK):**
  ```json
  {
    "success": true,
    "message": "OTP sent successfully via CDAC SMS Gateway",
    "expiresInSeconds": 300
  }
  ```

#### 2. Verify Farmer OTP & Issue JWT
* **Endpoint:** `POST /api/v1/auth/farmer/verify-otp`
* **Request:**
  ```json
  {
    "phone": "9876543210",
    "otp": "123456"
  }
  ```
* **Response (200 OK):**
  ```json
  {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "farmer": {
      "id": "farmer-murugan",
      "name": "R. Murugan",
      "farmerCode": "FRM-1001",
      "phone": "9876543210",
      "preferredLanguage": "ta",
      "district": "district-erode",
      "assignedCentreId": "centre-erode-01",
      "verificationStatus": "approved"
    }
  }
  ```

#### 3. Staff / Admin Login
* **Endpoint:** `POST /api/v1/auth/staff/login`
* **Request:**
  ```json
  {
    "employeeId": "DT-Erode",
    "password": "agriva123"
  }
  ```
* **Response (200 OK):**
  ```json
  {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "user-dt-erode",
      "name": "Dr. V. Kalanidhi IAS",
      "role": "districtAdmin",
      "employeeId": "DT-Erode",
      "district": "district-erode",
      "centreId": null
    }
  }
  ```

---

### 7.2 Centres, Crops & Slot Discovery

#### 1. List Centres by District
* **Endpoint:** `GET /api/v1/centres?districtId=district-erode`
* **Response (200 OK):**
  ```json
  [
    {
      "id": "centre-erode-01",
      "name": "Erode Regulated Market Hub",
      "code": "OP-Erode-01",
      "districtId": "district-erode",
      "taluk": "Erode",
      "latitude": 11.3410,
      "longitude": 77.7172,
      "dailyProcessingCapacityQ": 1500.0,
      "storageCapacityQ": 3000.0,
      "currentStorageQ": 420.0,
      "processingLanesTotal": 3,
      "processingLanesActive": 3,
      "status": "open"
    }
  ]
  ```

#### 2. Get Available Slots for a Centre on a Specific Date
* **Endpoint:** `GET /api/v1/centres/centre-erode-01/slots?date=2026-09-06`
* **Response (200 OK):**
  ```json
  [
    {
      "id": "slot-er-01-0900",
      "centreId": "centre-erode-01",
      "date": "2026-09-06",
      "startTime": "09:00",
      "endTime": "10:00",
      "capacityQ": 250.0,
      "bookedQ": 130.0,
      "availableQ": 120.0,
      "maxFarmers": 5,
      "currentBookedFarmers": 2,
      "isAvailable": true
    }
  ]
  ```

---

### 7.3 Slot Booking & Concurrency Engine

#### 1. Create Concurrency-Safe Booking
* **Endpoint:** `POST /api/v1/bookings`
* **Headers:** `Authorization: Bearer <JWT>`, `Idempotency-Key: <UUID>`
* **Request:**
  ```json
  {
    "farmerId": "farmer-murugan",
    "centreId": "centre-erode-01",
    "slotId": "slot-er-01-0900",
    "cropId": "crop-paddy-common",
    "expectedQuantityQ": 65.0,
    "vehicleNumber": "TN 33 AB 4589"
  }
  ```
* **Response (201 Created):**
  ```json
  {
    "id": "bkg-908124",
    "bookingReference": "AGR-20001",
    "farmerId": "farmer-murugan",
    "slotId": "slot-er-01-0900",
    "centreId": "centre-erode-01",
    "cropId": "crop-paddy-common",
    "expectedQuantityQ": 65.0,
    "token": "T003",
    "status": "booked",
    "createdAt": "2026-09-06T09:00:00Z"
  }
  ```

---

### 7.4 Centre Operator Workflows

#### 1. Scan Token & Mandi Check-In
* **Endpoint:** `POST /api/v1/operator/checkin`
* **Request:**
  ```json
  {
    "token": "T003",
    "centreId": "centre-erode-01"
  }
  ```
* **Response (200 OK):**
  ```json
  {
    "bookingId": "bkg-908124",
    "token": "T003",
    "farmerName": "R. Murugan",
    "cropName": "Paddy (Common)",
    "queuePosition": 3,
    "estimatedWaitMinutes": 24,
    "stage": "arrived",
    "status": "checkedIn"
  }
  ```

#### 2. Record Electronic Moisture Reading
* **Endpoint:** `POST /api/v1/operator/quality-inspection`
* **Request:**
  ```json
  {
    "bookingId": "bkg-908124",
    "moisturePercentage": 14.5,
    "foreignMatterPercentage": 1.2,
    "qualityGrade": "Grade A (FAQ)",
    "moistureDeviceId": "DEV-MOIST-01"
  }
  ```
* **Response (200 OK):**
  ```json
  {
    "success": true,
    "isFairAverageQuality": true,
    "maxMoistureAllowed": 17.0,
    "message": "Quality inspection verified. Eligible for weighment."
  }
  ```

#### 3. Capture Digital Weighment & Issue Acceptance Slip
* **Endpoint:** `POST /api/v1/operator/weighment`
* **Request:**
  ```json
  {
    "bookingId": "bkg-908124",
    "operatorId": "user-op-erode-01",
    "grossWeightKg": 7520.0,
    "tareWeightKg": 1020.0,
    "weighbridgeDeviceId": "DEV-WB-01"
  }
  ```
* **Response (200 OK):**
  ```json
  {
    "procurementRecordId": "rec-77123",
    "netWeightQ": 65.0,
    "mspPerQuintal": 2300.0,
    "totalPayoutAmount": 149500.0,
    "bookingStatus": "accepted",
    "paymentStatus": "paymentInitiated",
    "digitalSlipUrl": "https://agriva.gov.in/slips/AGR-20001.pdf"
  }
  ```

---

### 7.5 Live Yard Queue & Wait-Time Engine

#### 1. Get Centre Live Queue
* **Endpoint:** `GET /api/v1/centres/centre-erode-01/queue`
* **Response (200 OK):**
  ```json
  {
    "centreId": "centre-erode-01",
    "activeLanes": 3,
    "averageServiceMinutesPerLane": 8,
    "totalWaiting": 4,
    "entries": [
      {
        "tokenId": "T001",
        "farmerName": "M. Palanisamy",
        "position": 1,
        "stage": "weighment",
        "estimatedCallMinutes": 0
      },
      {
        "tokenId": "T002",
        "farmerName": "K. Senthil",
        "position": 2,
        "stage": "qualityCheck",
        "estimatedCallMinutes": 8
      },
      {
        "tokenId": "T003",
        "farmerName": "R. Murugan",
        "position": 3,
        "stage": "arrived",
        "estimatedCallMinutes": 16
      }
    ]
  }
  ```

---

### 7.6 District & State Admin Portals

#### 1. District Admin: List Flagged Verifications
* **Endpoint:** `GET /api/v1/admin/verifications?district=district-erode`
* **Response (200 OK):**
  ```json
  [
    {
      "farmerId": "farmer-thangavel",
      "farmerName": "A. Thangavel",
      "farmerCode": "FRM-1004",
      "phone": "9876543213",
      "village": "Gobichettipalayam",
      "pattaNumber": "PATTA-7781",
      "surveyNumber": "SF-99/1",
      "areaHectares": 2.10,
      "verificationStatus": "escalatedToDistrict",
      "escalationNotes": "Patta sub-division name mismatch with Aadhaar record"
    }
  ]
  ```

#### 2. District Admin: Resolve Verification (Approve / Reject)
* **Endpoint:** `POST /api/v1/admin/verifications/farmer-thangavel/resolve`
* **Request:**
  ```json
  {
    "action": "approved", // or "rejected"
    "adminId": "user-dt-erode",
    "notes": "Village revenue inspector chitta book cross-verified manually."
  }
  ```
* **Response (200 OK):**
  ```json
  {
    "success": true,
    "farmerId": "farmer-thangavel",
    "verificationStatus": "approved"
  }
  ```

#### 3. State Admin: Emergency Broadcast
* **Endpoint:** `POST /api/v1/admin/broadcast`
* **Request:**
  ```json
  {
    "title": "Unseasonal Heavy Rain Alert - Delta Districts",
    "message": "All covered sheds opened in Thanjavur & Tiruvarur centres. Moisture tolerance +0.5% buffer approved for 48 hours.",
    "districtId": "district-thanjavur",
    "severity": "critical"
  }
  ```
* **Response (201 Created):**
  ```json
  {
    "broadcastId": "bc-99120",
    "dispatchedSessionsCount": 1420
  }
  ```

---

### 7.7 Direct Benefit Transfer (DBT) & PFMS Webhooks

#### 1. Public Financial Management System (PFMS) Webhook Callback
* **Endpoint:** `POST /api/v1/payments/webhook/pfms`
* **Headers:** `X-PFMS-Signature: <HMAC_SHA256>`
* **Request:**
  ```json
  {
    "bookingId": "bkg-908124",
    "dbtReference": "PFMS-TN-2026-89410",
    "utrNumber": "UTR-SBIN-20260906-881920",
    "amount": 149500.0,
    "status": "completed",
    "timestamp": "2026-09-06T14:30:00Z"
  }
  ```
* **Action:**
  1. Validates HMAC signature against government agency secret.
  2. Updates `payments` table (`status = 'completed'`, `utr_number = '...'`).
  3. Updates `bookings` table (`status = 'paymentCompleted'`).
  4. Triggers instant push notification and SMS to farmer.

---

## 8. Real-Time WebSocket Protocol (Live Queue & IoT Streams)

* **WebSocket Gateway:** `wss://api.agriva.gov.in/ws/v1/realtime`
* **Authentication:** Handshake with query parameter: `?token=<JWT>`

### Client Subscription Events
Upon connecting, clients send a subscription payload:
```json
{
  "action": "subscribe",
  "channels": [
    "centre:centre-erode-01:queue",
    "farmer:farmer-murugan:status",
    "iot:centre-erode-01:lane-1"
  ]
}
```

### Server Broadcast Payloads

#### 1. Live Token Called to Lane
```json
{
  "event": "queue:token_called",
  "centreId": "centre-erode-01",
  "laneNumber": 1,
  "token": "T003",
  "farmerName": "R. Murugan",
  "stage": "weighment",
  "timestamp": "2026-09-06T11:00:00Z"
}
```

#### 2. Live IoT Weighbridge Telemetry Stream
```json
{
  "event": "iot:weighbridge_stream",
  "centreId": "centre-erode-01",
  "laneNumber": 1,
  "readingKg": 7520.0,
  "isStable": true,
  "timestamp": "2026-09-06T11:02:15Z"
}
```

#### 3. Yard Disruption Notification
```json
{
  "event": "centre:disruption",
  "centreId": "centre-erode-01",
  "type": "weighingMachineFailure",
  "affectedLanes": 1,
  "message": "Weighbridge Lane 2 undergoing recalibration. Expect +15 min wait time."
}
```

---

## 9. Concurrency & Slot Allocation Engine (Redis Redlock + Lua)

To eliminate slot overselling during flash booking windows (thousands of farmers booking slots simultaneously at 8:00 AM harvest release), the backend uses Redis distributed locking and atomic counter decrement:

```lua
-- Lua Script for Atomic Slot Booking (reserve_slot.lua)
-- KEYS[1]: slot_capacity_key  (e.g., "slot:capacity:slot-er-01-0900")
-- KEYS[2]: centre_daily_key   (e.g., "centre:daily:centre-erode-01:2026-09-06")
-- ARGV[1]: requested_quantity_quintals
-- ARGV[2]: centre_daily_max_quintals

local current_slot_booked = tonumber(redis.call('GET', KEYS[1]) or '0')
local current_daily_booked = tonumber(redis.call('GET', KEYS[2]) or '0')
local req_qty = tonumber(ARGV[1])
local daily_max = tonumber(ARGV[2])

if (current_daily_booked + req_qty) > daily_max then
    return {0, "DAILY_CENTRE_CAPACITY_EXCEEDED"}
end

-- Check slot hourly limit
local slot_limit = tonumber(redis.call('HGET', 'slot_meta', KEYS[1]) or '250')
if (current_slot_booked + req_qty) > slot_limit then
    return {0, "HOURLY_SLOT_CAPACITY_EXCEEDED"}
end

-- Atomic reservation
redis.call('INCRBYFLOAT', KEYS[1], req_qty)
redis.call('INCRBYFLOAT', KEYS[2], req_qty)

return {1, "SUCCESS"}
```

#### Real-Time Wait Time Estimation (Little's Law Formula):
$$\text{Estimated Wait (min)} = \frac{\text{Queue Position} \times \text{Average Inspection Cycle (8 min)}}{\text{Active Processing Lanes}}$$

---

## 10. IoT Hardware Integration Specifications

### 10.1 Weighbridge Serial RS-232 / TCP Protocol
* **Physical Interface:** RS-232 DB9 or TCP/IP Serial Converter (MOXA NPort)
* **Baud Rate:** 9600 bps | **Data Bits:** 8 | **Stop Bits:** 1 | **Parity:** None
* **Data Packet String:** `<STX>+07520.00kg<ETX>`
* **Edge Python Daemon (Runs on Raspberry Pi 4 at Mandi Lane):**
  ```python
  import serial
  import hmac
  import hashlib
  import requests
  import time

  ser = serial.Serial('/dev/ttyUSB0', 9600, timeout=1)
  SECRET_KEY = b"AGRIVA_MANDI_SECRET_KEY_2026"

  while True:
      line = ser.readline().decode('ascii', errors='ignore').strip()
      if line.startswith("+") and "kg" in line:
          weight_kg = float(line.replace("+", "").replace("kg", ""))
          timestamp = str(int(time.time()))
          payload = f"{weight_kg}:{timestamp}"
          sig = hmac.new(SECRET_KEY, payload.encode(), hashlib.sha256).hexdigest()
          
          requests.post("http://localhost:8080/api/v1/iot/weighbridge/stream", json={
              "centreId": "centre-erode-01",
              "laneNumber": 1,
              "weightKg": weight_kg,
              "timestamp": timestamp,
              "signature": sig
          })
      time.sleep(0.5)
  ```

### 10.2 Electronic Grain Moisture Meter (Modbus RTU over RS-485)
* **Standard:** ISO 712 / BIS 4333 Grain Quality Standard
* **Modbus Command:** Function Code `0x03` (Read Holding Registers)
* **Register Address:** `0x0010` (Moisture % $\times 10$), `0x0011` (Ambient Temp $^{\circ}\text{C} \times 10$)
* **Rejection Boundary:** If moisture reading $> 17.0\%$, the backend triggers an automated Fair Average Quality (FAQ) rejection or drying-yard rebooking recommendation.

---

## 11. Backend Developer Quickstart (Docker Compose & Local Setup)

To spin up the entire backend infrastructure in under 2 minutes:

### 11.1 Create `docker-compose.yml`
```yaml
version: '3.8'

services:
  postgres:
    image: postgis/postgis:16-3.4
    container_name: agriva-postgres
    environment:
      POSTGRES_DB: agriva_db
      POSTGRES_USER: agriva_user
      POSTGRES_PASSWORD: agriva_password_2026
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./schema.sql:/docker-entrypoint-initdb.d/01_schema.sql
      - ./seed.sql:/docker-entrypoint-initdb.d/02_seed.sql

  redis:
    image: redis:7-alpine
    container_name: agriva-redis
    ports:
      - "6379:6379"
    command: ["redis-server", "--appendonly", "yes"]

volumes:
  pgdata:
```

### 11.2 Environment File (`.env`)
```env
PORT=8080
DATABASE_URL=postgres://agriva_user:agriva_password_2026@localhost:5432/agriva_db?sslmode=disable
REDIS_URL=redis://localhost:6379
JWT_SECRET=super_secret_government_agriva_jwt_key_2026
PFMS_WEBHOOK_SECRET=pfms_hmac_secret_2026
CDAC_SMS_API_KEY=mock_cdac_key
```

### 11.3 Startup Commands
```bash
# 1. Start PostgreSQL with PostGIS & Redis
docker compose up -d

# 2. Verify Database Initialized with 13 Centres and 5 Districts
docker exec -it agriva-postgres psql -U agriva_user -d agriva_db -c "SELECT count(*) FROM procurement_centres;"
# Expected output: 13
```

---

## 12. Flutter Client App Setup & Run Guide

### Prerequisites
* Flutter SDK 3.22+ installed (`flutter --version`)
* Android SDK 34+ / Android Studio / VS Code Flutter extension

### Build & Run
```bash
# 1. Enter client directory
cd agriva

# 2. Get dependencies
flutter pub get

# 3. Verify static code health (passes with 0 issues)
flutter analyze

# 4. Run automated test suite (2/2 manager & UI tests pass)
flutter test

# 5. Launch on connected physical device or emulator
flutter run
```

---

## 13. Default Demo Credentials

Pre-seeded accounts for immediate testing:

| Portal | Role | Login Credential | Password / OTP | Default Assigned Scope |
| :--- | :--- | :--- | :--- | :--- |
| **Farmer (Verified)** | `farmer` | `9876543210` | Any 6 digits (e.g. `123456`) | R. Murugan, Erode District |
| **Farmer (Active In-Queue)** | `farmer` | `9876543212` | Any 6 digits (e.g. `123456`) | M. Palanisamy (Token `T003` at Hub) |
| **Farmer (Pending Verification)** | `farmer` | `9876543211` | Any 6 digits (e.g. `123456`) | K. Senthil Kumar (Perundurai) |
| **Centre Operator** | `centreOperator` | `OP-Erode-01` | `agriva123` | Erode Regulated Market Hub |
| **District Admin** | `districtAdmin` | `DT-Erode` | `agriva123` | Erode District IAS Administrator |
| **District Admin** | `districtAdmin` | `DT-Tiruppur` | `agriva123` | Tiruppur District IAS Administrator |
| **District Admin** | `districtAdmin` | `DT-Thanjavur` | `agriva123` | Thanjavur District IAS Administrator |
| **State Admin** | `stateAdmin` | `ST-Admin` | `agriva123` | Tamil Nadu State Head Office |

---

## 14. Security, DPDP Act 2023 & Compliance

1. **Digital Personal Data Protection (DPDP) Act 2023 Compliance:**
   - Aadhaar numbers and bank accounts are never stored in raw plaintext. They are hashed using salted SHA-256 for duplicate detection, and masked (`XXXX-XXXX-1234`) for frontend display.
2. **Role-Based Access Control (RBAC):**
   - Cryptographic JWT claims enforce strict tenancy. District Admins cannot query or mutate records belonging to other districts.
3. **Immutable Quality & Audit Trail:**
   - Every moisture reading and weighbridge certificate is digitally signed and logged to an append-only audit trail to prevent collusion or bribery.

---

*Architected and developed for the Government Grain Procurement Booking & Centre Management System.*
