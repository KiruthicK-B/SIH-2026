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
