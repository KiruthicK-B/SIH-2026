-- Which data-sharing scope a pending consent request needs (nullable — requests with
-- no scope requirement, e.g. seeded before this feature, are unaffected).
ALTER TABLE pending_consent_requests ADD COLUMN IF NOT EXISTS required_scope TEXT;
