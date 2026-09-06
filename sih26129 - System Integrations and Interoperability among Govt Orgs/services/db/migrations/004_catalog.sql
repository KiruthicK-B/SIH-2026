-- Removes the last static/mock arrays living in the frontend bundle (services,
-- notifications, documents, grievances, plus identity fields the Application Wizard
-- was faking). sla_rules and data_quality_issues tables already exist from 001_init.sql
-- but were never seeded or read from — this migration doesn't touch those.

ALTER TABLE master_identity ADD COLUMN IF NOT EXISTS date_of_birth DATE;
ALTER TABLE master_identity ADD COLUMN IF NOT EXISTS address TEXT;
ALTER TABLE master_identity ADD COLUMN IF NOT EXISTS annual_income TEXT;
ALTER TABLE master_identity ADD COLUMN IF NOT EXISTS education_details TEXT;

CREATE TABLE IF NOT EXISTS service_categories (
  name TEXT PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS services (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  department TEXT NOT NULL,
  category TEXT NOT NULL REFERENCES service_categories (name),
  processing_time TEXT NOT NULL,
  required_documents TEXT[] NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS notifications (
  id TEXT PRIMARY KEY,
  citizen_master_id TEXT NOT NULL REFERENCES master_identity (master_id) ON DELETE CASCADE,
  type TEXT NOT NULL, -- application | consent | document | system
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  read BOOLEAN NOT NULL DEFAULT false
);

CREATE TABLE IF NOT EXISTS documents (
  id TEXT PRIMARY KEY,
  citizen_master_id TEXT NOT NULL REFERENCES master_identity (master_id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  issued_by TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'Pending Verification', -- Verified | Pending Verification
  issued_on DATE NOT NULL DEFAULT CURRENT_DATE,
  application_id TEXT REFERENCES applications (id) ON DELETE SET NULL
);

CREATE SEQUENCE IF NOT EXISTS grievance_seq START 502;

CREATE TABLE IF NOT EXISTS grievances (
  id TEXT PRIMARY KEY,
  citizen_master_id TEXT NOT NULL REFERENCES master_identity (master_id) ON DELETE CASCADE,
  subject TEXT NOT NULL,
  department TEXT NOT NULL,
  related_application TEXT REFERENCES applications (id),
  status TEXT NOT NULL DEFAULT 'Open', -- Open | In Progress | Resolved
  filed_on DATE NOT NULL DEFAULT CURRENT_DATE,
  description TEXT NOT NULL
);

-- Backs DataQualityTab's aggregate cards; data_quality_issues (existing table)
-- backs its per-issue-type breakdown.
CREATE TABLE IF NOT EXISTS data_quality_metrics (
  id INT PRIMARY KEY DEFAULT 1,
  records_processed INT NOT NULL,
  valid_records INT NOT NULL,
  warnings INT NOT NULL,
  validation_errors INT NOT NULL,
  CHECK (id = 1)
);

CREATE TABLE IF NOT EXISTS data_quality_department_rates (
  department TEXT PRIMARY KEY,
  valid_rate NUMERIC NOT NULL
);

-- Small scalar-metric store for aggregate numbers that aren't derivable from a
-- single table's rows (e.g. overall SLA compliance is a historical rollup, not
-- simply "categories currently passing / total categories").
CREATE TABLE IF NOT EXISTS platform_stats (
  key TEXT PRIMARY KEY,
  value NUMERIC NOT NULL
);
