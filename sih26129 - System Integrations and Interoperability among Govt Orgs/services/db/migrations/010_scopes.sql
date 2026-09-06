-- Per-citizen data-sharing scope grants, and the master_identity columns the wider
-- scope catalog can populate (see core-api's scope-catalog.ts).
CREATE TABLE IF NOT EXISTS citizen_scope_grants (
  citizen_master_id TEXT NOT NULL REFERENCES master_identity (master_id) ON DELETE CASCADE,
  scope_key TEXT NOT NULL,
  granted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (citizen_master_id, scope_key)
);

ALTER TABLE master_identity
  ADD COLUMN IF NOT EXISTS gender TEXT,
  ADD COLUMN IF NOT EXISTS photo_path TEXT,
  ADD COLUMN IF NOT EXISTS employer_name TEXT,
  ADD COLUMN IF NOT EXISTS designation TEXT,
  ADD COLUMN IF NOT EXISTS institution_name TEXT;
