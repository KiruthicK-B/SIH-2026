-- OneDesk core-api schema. Mirrors the frontend TS types 1:1 (see onedesk/src/data/*.ts),
-- plus the additions the build plan calls out explicitly:
--   audit_log.purpose / audit_log.consent_id   -> satisfy "who/what/when/why/consent"
--   timeline_steps.blocked_reason_code         -> distinguish killed vs revoked vs quarantined
--   connector_registry.kill_switch_enabled     -> generalizes the old hardcoded
--                                                  "department === 'Municipal Corporation'" check

-- Mirrors the frontend's in-memory `let sequence = 1007` counter for generating
-- BL-2026-NNNN / APP-2026-NNNN ids across submissions.
CREATE SEQUENCE IF NOT EXISTS application_seq START 1007;

CREATE TABLE IF NOT EXISTS applications (
  id TEXT PRIMARY KEY,
  service TEXT NOT NULL,
  department TEXT NOT NULL,
  status TEXT NOT NULL,
  last_updated DATE NOT NULL,
  submitted_on DATE NOT NULL,
  citizen_name TEXT NOT NULL,
  citizen_master_id TEXT,
  description TEXT NOT NULL,
  flagship BOOLEAN NOT NULL DEFAULT false
);

CREATE TABLE IF NOT EXISTS timeline_steps (
  id SERIAL PRIMARY KEY,
  application_id TEXT NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  step_order INT NOT NULL,
  label TEXT NOT NULL,
  department TEXT NOT NULL,
  status TEXT NOT NULL, -- done | active | blocked | pending
  step_date DATE,
  system_type TEXT,
  note TEXT,
  blocked_reason_code TEXT, -- connector_killed | consent_revoked | data_quarantined
  UNIQUE (application_id, step_order)
);

CREATE TABLE IF NOT EXISTS consents (
  id TEXT PRIMARY KEY,
  data_category TEXT NOT NULL,
  department TEXT NOT NULL,
  purpose TEXT NOT NULL,
  status TEXT NOT NULL, -- Active | Revoked | Expired
  granted_on DATE NOT NULL,
  valid_until DATE NOT NULL,
  citizen_master_id TEXT
);

CREATE TABLE IF NOT EXISTS pending_consent_requests (
  id TEXT PRIMARY KEY,
  department TEXT NOT NULL,
  purpose TEXT NOT NULL,
  data_requested TEXT[] NOT NULL,
  requested_on DATE NOT NULL,
  citizen_master_id TEXT
);

CREATE TABLE IF NOT EXISTS audit_log (
  id TEXT PRIMARY KEY,
  ts TIMESTAMPTZ NOT NULL DEFAULT now(),
  actor TEXT NOT NULL,
  department TEXT NOT NULL,
  action TEXT NOT NULL, -- READ | WRITE | VERIFY | GRANT CONSENT | REVOKE CONSENT | APPROVE
  resource TEXT NOT NULL,
  result TEXT NOT NULL, -- Success | Failed | Denied
  purpose TEXT,
  consent_id TEXT REFERENCES consents (id)
);

CREATE TABLE IF NOT EXISTS master_identity (
  master_id TEXT PRIMARY KEY,
  citizen_name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS department_identifiers (
  id SERIAL PRIMARY KEY,
  master_id TEXT NOT NULL REFERENCES master_identity (master_id) ON DELETE CASCADE,
  department TEXT NOT NULL,
  identifier TEXT NOT NULL,
  confidence NUMERIC,
  UNIQUE (master_id, department)
);

CREATE TABLE IF NOT EXISTS identity_conflicts (
  id SERIAL PRIMARY KEY,
  candidate_master_id TEXT,
  department TEXT NOT NULL,
  identifier TEXT NOT NULL,
  candidate_name TEXT NOT NULL,
  confidence NUMERIC NOT NULL,
  status TEXT NOT NULL DEFAULT 'Pending', -- Pending | Resolved | Rejected
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS connector_registry (
  name TEXT PRIMARY KEY,
  protocol TEXT NOT NULL, -- REST | SOAP | DB | SFTP | OAuth
  health TEXT NOT NULL DEFAULT 'Healthy', -- Healthy | Degraded | Down
  kill_switch_enabled BOOLEAN NOT NULL DEFAULT false
);

CREATE TABLE IF NOT EXISTS field_mappings (
  id SERIAL PRIMARY KEY,
  source_field TEXT NOT NULL,
  source_system TEXT NOT NULL,
  target_field TEXT NOT NULL,
  confidence NUMERIC,
  rationale TEXT,
  status TEXT NOT NULL DEFAULT 'suggested' -- suggested | approved | rejected
);

CREATE TABLE IF NOT EXISTS data_quality_issues (
  id SERIAL PRIMARY KEY,
  label TEXT NOT NULL,
  department TEXT,
  count INT NOT NULL DEFAULT 1,
  status TEXT NOT NULL DEFAULT 'Quarantined', -- Quarantined | Resolved
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS sla_rules (
  label TEXT PRIMARY KEY,
  target_label TEXT NOT NULL,
  target_hours NUMERIC NOT NULL,
  current_label TEXT NOT NULL,
  current_hours NUMERIC NOT NULL,
  within_sla BOOLEAN NOT NULL
);
