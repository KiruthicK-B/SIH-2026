-- Mirrors onedesk/src/data/*.ts exactly (same IDs) so the demo has zero visual regression
-- when contexts switch from static arrays to real API calls.

INSERT INTO master_identity (master_id, citizen_name) VALUES
  ('CIT-10282', 'Asha Patil')
ON CONFLICT (master_id) DO NOTHING;

INSERT INTO department_identifiers (master_id, department, identifier, confidence) VALUES
  ('CIT-10282', 'Revenue', 'REV-8892', 1.0),
  ('CIT-10282', 'Education', 'EDU-2198', 1.0),
  ('CIT-10282', 'Welfare', 'WEL-7781', 1.0),
  ('CIT-10282', 'Business Registry', 'BR-5521', 1.0)
ON CONFLICT (master_id, department) DO NOTHING;

-- Applications ---------------------------------------------------------------

INSERT INTO applications (id, service, department, status, last_updated, submitted_on, citizen_name, citizen_master_id, description, flagship) VALUES
  ('BL-2026-00128', 'Business License', 'Business Registry', 'In Progress', '2026-08-27', '2026-08-27', 'Asha Patil', 'CIT-10282', 'One application, submitted once — verified across identity, business registry, tax, and municipal systems before a license is issued.', true),
  ('APP-2026-1001', 'Scholarship Scheme', 'Education Department', 'In Progress', '2026-08-26', '2026-08-20', 'Asha Patil', 'CIT-10282', 'Merit-cum-means scholarship for undergraduate students, cross-verified with income records from the Revenue Department.', false),
  ('APP-2026-1002', 'Income Certificate', 'Revenue Department', 'Under Review', '2026-08-25', '2026-08-19', 'Asha Patil', 'CIT-10282', 'Annual income certificate required for scholarship and welfare scheme eligibility verification.', false),
  ('APP-2026-1003', 'Business Registration', 'Business Registry', 'Approved', '2026-08-24', '2026-08-10', 'Asha Patil', 'CIT-10282', 'New micro-enterprise registration under the state industries promotion scheme.', false),
  ('APP-2026-1004', 'Utility Connection', 'Municipal Corporation', 'In Progress', '2026-08-23', '2026-08-15', 'Asha Patil', 'CIT-10282', 'New water and electricity connection request for a registered residential property.', false),
  ('APP-2026-1005', 'Ration Card', 'Food & Civil Supplies', 'Completed', '2026-08-05', '2026-07-22', 'Asha Patil', 'CIT-10282', 'New household ration card issuance linked to verified residence and identity records.', false),
  ('APP-2026-1006', 'Health Insurance Enrollment', 'Health Department', 'Rejected', '2026-08-12', '2026-08-01', 'Asha Patil', 'CIT-10282', 'Enrollment under the state health benefit scheme; rejected due to duplicate beneficiary record.', false)
ON CONFLICT (id) DO NOTHING;

INSERT INTO timeline_steps (application_id, step_order, label, department, status, step_date, system_type, note) VALUES
  ('BL-2026-00128', 0, 'Application Submitted', 'OneDesk', 'done', '2026-08-27', 'Unified Portal', NULL),
  ('BL-2026-00128', 1, 'Identity Verified', 'Identity Service', 'done', '2026-08-27', 'OAuth / Federation', NULL),
  ('BL-2026-00128', 2, 'Business Details Verified', 'Business Registry', 'done', '2026-08-27', 'Legacy SOAP', NULL),
  ('BL-2026-00128', 3, 'Tax Verification', 'Revenue Department', 'active', NULL, 'REST API', NULL),
  ('BL-2026-00128', 4, 'Municipal Review', 'Municipal Corporation', 'pending', NULL, 'Legacy Database Adapter', NULL),
  ('BL-2026-00128', 5, 'Final Approval', 'License Authority', 'pending', NULL, 'GraphQL API', NULL),

  ('APP-2026-1001', 0, 'Application Submitted', 'Unified Portal', 'done', '2026-08-20', NULL, NULL),
  ('APP-2026-1001', 1, 'Documents Verified', 'Education Department', 'done', '2026-08-21', NULL, NULL),
  ('APP-2026-1001', 2, 'Eligibility Verification', 'Revenue Department', 'active', '2026-08-26', NULL, NULL),
  ('APP-2026-1001', 3, 'Department Approval', 'Education Department', 'pending', NULL, NULL, NULL),
  ('APP-2026-1001', 4, 'Application Completed', 'Education Department', 'pending', NULL, NULL, NULL),

  ('APP-2026-1002', 0, 'Application Submitted', 'Unified Portal', 'done', '2026-08-19', NULL, NULL),
  ('APP-2026-1002', 1, 'Document Check', 'Revenue Department', 'done', '2026-08-20', NULL, NULL),
  ('APP-2026-1002', 2, 'Field Verification', 'Local Govt Office', 'active', '2026-08-25', NULL, NULL),
  ('APP-2026-1002', 3, 'Committee Review', 'Revenue Department', 'pending', NULL, NULL, NULL),
  ('APP-2026-1002', 4, 'Certificate Issued', 'Revenue Department', 'pending', NULL, NULL, NULL),

  ('APP-2026-1003', 0, 'Application Submitted', 'Unified Portal', 'done', '2026-08-10', NULL, NULL),
  ('APP-2026-1003', 1, 'Documents Verified', 'Business Registry', 'done', '2026-08-13', NULL, NULL),
  ('APP-2026-1003', 2, 'Site Verification', 'Municipal Corporation', 'done', '2026-08-18', NULL, NULL),
  ('APP-2026-1003', 3, 'Department Approval', 'Business Registry', 'done', '2026-08-24', NULL, NULL),
  ('APP-2026-1003', 4, 'Registration Completed', 'Business Registry', 'pending', NULL, NULL, NULL),

  ('APP-2026-1004', 0, 'Application Submitted', 'Unified Portal', 'done', '2026-08-15', NULL, NULL),
  ('APP-2026-1004', 1, 'Property Verification', 'Municipal Corporation', 'done', '2026-08-19', NULL, NULL),
  ('APP-2026-1004', 2, 'Technical Survey', 'Municipal Corporation', 'active', '2026-08-23', NULL, NULL),
  ('APP-2026-1004', 3, 'Connection Approval', 'Municipal Corporation', 'pending', NULL, NULL, NULL),
  ('APP-2026-1004', 4, 'Connection Activated', 'Municipal Corporation', 'pending', NULL, NULL, NULL),

  ('APP-2026-1005', 0, 'Application Submitted', 'Unified Portal', 'done', '2026-07-22', NULL, NULL),
  ('APP-2026-1005', 1, 'Documents Verified', 'Food & Civil Supplies', 'done', '2026-07-25', NULL, NULL),
  ('APP-2026-1005', 2, 'Field Verification', 'Local Govt Office', 'done', '2026-07-30', NULL, NULL),
  ('APP-2026-1005', 3, 'Department Approval', 'Food & Civil Supplies', 'done', '2026-08-02', NULL, NULL),
  ('APP-2026-1005', 4, 'Application Completed', 'Food & Civil Supplies', 'done', '2026-08-05', NULL, NULL),

  ('APP-2026-1006', 0, 'Application Submitted', 'Unified Portal', 'done', '2026-08-01', NULL, NULL),
  ('APP-2026-1006', 1, 'Eligibility Check', 'Health Department', 'done', '2026-08-05', NULL, NULL),
  ('APP-2026-1006', 2, 'Duplicate Record Flagged', 'Health Department', 'done', '2026-08-12', NULL, NULL),
  ('APP-2026-1006', 3, 'Department Approval', 'Health Department', 'pending', NULL, NULL, NULL),
  ('APP-2026-1006', 4, 'Enrollment Completed', 'Health Department', 'pending', NULL, NULL, NULL)
ON CONFLICT (application_id, step_order) DO NOTHING;

-- Consents --------------------------------------------------------------------

INSERT INTO consents (id, data_category, department, purpose, status, granted_on, valid_until, citizen_master_id) VALUES
  ('con-1001', 'Business Income Details', 'Revenue Department', 'Tax Verification for Business License Processing', 'Active', '2026-08-27', '2026-09-26', 'CIT-10282'),
  ('con-1002', 'Academic Details', 'Education Department', 'Scholarship Application', 'Active', '2026-08-20', '2026-12-15', 'CIT-10282'),
  ('con-1003', 'Aadhaar Verification', 'All Departments', 'Identity Verification Across Services', 'Active', '2026-06-10', '2026-12-10', 'CIT-10282'),
  ('con-1004', 'Property Records', 'Municipal Corporation', 'Utility Connection Verification', 'Expired', '2026-05-01', '2026-08-01', 'CIT-10282'),
  ('con-1005', 'Health Records', 'Health Department', 'Insurance Enrollment Assessment', 'Revoked', '2026-04-12', '2026-10-12', 'CIT-10282')
ON CONFLICT (id) DO NOTHING;

INSERT INTO pending_consent_requests (id, department, purpose, data_requested, requested_on, citizen_master_id) VALUES
  ('req-2001', 'Municipal Corporation', 'Municipal Verification for Business License', ARRAY['Business Address', 'Property Records'], '2026-08-27', 'CIT-10282')
ON CONFLICT (id) DO NOTHING;

-- Audit log ---------------------------------------------------------------

INSERT INTO audit_log (id, ts, actor, department, action, resource, result, purpose, consent_id) VALUES
  ('aud-1', '2026-08-27T10:42:00Z', 'Education Officer', 'Education Department', 'READ', 'Income Information', 'Success', 'Scholarship eligibility verification', NULL),
  ('aud-2', '2026-08-27T10:41:00Z', 'Citizen', 'Unified Portal', 'GRANT CONSENT', 'Academic Details', 'Success', 'Scholarship Application', 'con-1002'),
  ('aud-3', '2026-08-27T10:39:00Z', 'Revenue Officer', 'Revenue Department', 'VERIFY', 'Income Certificate', 'Success', 'Income certificate verification', NULL),
  ('aud-4', '2026-08-26T16:05:00Z', 'Municipal Officer', 'Municipal Corporation', 'READ', 'Property Records', 'Denied', 'Utility connection verification (consent expired)', 'con-1004'),
  ('aud-5', '2026-08-26T14:22:00Z', 'Citizen', 'Unified Portal', 'REVOKE CONSENT', 'Health Records', 'Success', 'Citizen-initiated revocation', 'con-1005'),
  ('aud-6', '2026-08-26T11:10:00Z', 'Health Officer', 'Health Department', 'READ', 'Insurance Eligibility', 'Success', 'Insurance enrollment assessment', NULL),
  ('aud-7', '2026-08-25T09:47:00Z', 'Revenue Officer', 'Revenue Department', 'WRITE', 'Income Certificate Status', 'Success', 'Status update', NULL),
  ('aud-8', '2026-08-25T09:02:00Z', 'System', 'Interoperability Layer', 'VERIFY', 'Citizen Identity Mapping', 'Failed', 'Entity resolution', NULL),
  ('aud-9', '2026-08-24T16:32:00Z', 'Business Registry Officer', 'Business Registry', 'APPROVE', 'Business Registration APP-2026-1003', 'Success', 'Registration approval', NULL),
  ('aud-10', '2026-08-23T10:15:00Z', 'Welfare Officer', 'Social Welfare Department', 'READ', 'Pension Eligibility', 'Success', 'Pension eligibility check', NULL),
  ('aud-11', '2026-08-20T12:03:00Z', 'Citizen', 'Unified Portal', 'GRANT CONSENT', 'Income Certificate', 'Success', 'Income certificate request', NULL),
  ('aud-12', '2026-08-19T15:40:00Z', 'Education Officer', 'Education Department', 'READ', 'Academic Records', 'Success', 'Scholarship document check', NULL)
ON CONFLICT (id) DO NOTHING;

-- Connector registry (backs the Phase 2 kill-switch, seeded now so the admin panel has rows) ---

INSERT INTO connector_registry (name, protocol, health, kill_switch_enabled) VALUES
  ('Identity Service', 'OAuth', 'Healthy', false),
  ('Business Registry', 'SOAP', 'Healthy', false),
  ('Revenue Department', 'REST', 'Healthy', false),
  ('Municipal Corporation', 'DB', 'Healthy', false),
  ('License Authority', 'GraphQL', 'Healthy', false)
ON CONFLICT (name) DO NOTHING;

-- Identity conflict seed for the manual-reconciliation demo (Phase 3) --------

INSERT INTO identity_conflicts (candidate_master_id, department, identifier, candidate_name, confidence, status) VALUES
  (NULL, 'Welfare', 'WEL-9034', 'K. Kiruthick', 0.62, 'Pending')
ON CONFLICT DO NOTHING;
