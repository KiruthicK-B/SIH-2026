-- Demonstrates scope-gated consent blocking out of the box: citizen1 (CIT-10282) has
-- no citizen_scope_grants rows at all (the scopes system postdates their seed record),
-- so any request tagged with a required_scope is blocked until they grant it in Settings.
UPDATE pending_consent_requests SET required_scope = 'identity.address' WHERE id = 'req-2001';

INSERT INTO pending_consent_requests (id, department, purpose, data_requested, requested_on, citizen_master_id, required_scope) VALUES
  ('req-2002', 'Revenue Department', 'Income Tax Cross-Verification', ARRAY['PAN Details'], '2026-09-01', 'CIT-10282', 'identity.pan')
ON CONFLICT (id) DO NOTHING;
