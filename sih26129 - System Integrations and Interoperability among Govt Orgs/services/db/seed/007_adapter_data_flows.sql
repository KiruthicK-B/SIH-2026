-- Truthful to what each hardened adapter (see connectors.service.ts) actually sends
-- and receives — not invented citizen-record fields. Most of these adapters are thin
-- (applicationId in, status out); the real "what does this department know about the
-- citizen" story lives in department_identifiers, surfaced separately by the
-- /data-mapping endpoint as identity-resolution info per department.

INSERT INTO adapter_data_flows (department, direction, field, canonical_field, sample_value, step_order) VALUES
  ('Identity Service', 'Outbound', 'applicationId', 'applicationId', 'BL-2026-00128', 0),
  ('Identity Service', 'Inbound', 'active', 'tokenActive', 'true', 1),
  ('Identity Service', 'Inbound', 'sub', 'subjectId', 'BL-2026-00128', 2),
  ('Identity Service', 'Inbound', 'token_type', 'tokenType', 'Bearer', 3),

  ('Business Registry', 'Outbound', 'ApplicationId', 'applicationId', 'BL-2026-00128', 0),
  ('Business Registry', 'Inbound', 'ApplicationId', 'applicationId', 'BL-2026-00128', 1),
  ('Business Registry', 'Inbound', 'Status', 'verificationStatus', 'VERIFIED', 2),

  ('Revenue Department', 'Internal', 'consents.status', 'consentStatus', 'Active', 0),
  ('Revenue Department', 'Outbound', 'applicationId', 'applicationId', 'BL-2026-00128', 1),
  ('Revenue Department', 'Inbound', 'status', 'verificationStatus', 'VERIFIED', 2),

  ('Municipal Corporation', 'Outbound', 'applicationId', 'applicationId', 'BL-2026-00128', 0),
  ('Municipal Corporation', 'Inbound', 'status', 'reviewStatus', 'REVIEWED', 1),
  ('Municipal Corporation', 'Inbound', 'reviewed_at', 'reviewedAt', '2026-08-27T10:41:00Z', 2),

  ('License Authority', 'Outbound', 'applicationId', 'applicationId', 'BL-2026-00128', 0),
  ('License Authority', 'Inbound', 'applicationId', 'applicationId', 'BL-2026-00128', 1),
  ('License Authority', 'Inbound', 'status', 'approvalStatus', 'APPROVED', 2)
ON CONFLICT (department, direction, field) DO NOTHING;
