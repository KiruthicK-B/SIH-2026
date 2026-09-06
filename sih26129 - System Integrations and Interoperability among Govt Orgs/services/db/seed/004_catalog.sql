-- Converts what used to be hardcoded frontend arrays (src/data/services.ts,
-- sla.ts, dataQuality.ts, notifications.ts, documents.ts, grievances.ts) into
-- real seed rows, same content, same IDs — matches 001_seed.sql's own pattern.

UPDATE master_identity
SET date_of_birth = '2000-08-27',
    address = '221, Shivaji Nagar, Pune, Maharashtra - 411005',
    annual_income = '2,40,000',
    education_details = 'B.Sc. Computer Science, Savitribai Phule Pune University (2024)'
WHERE master_id = 'CIT-10282';

-- Services catalog ------------------------------------------------------------

INSERT INTO service_categories (name) VALUES
  ('Business'), ('Education'), ('Revenue'), ('Municipal'), ('Health'), ('Social Welfare')
ON CONFLICT (name) DO NOTHING;

INSERT INTO services (id, name, department, category, processing_time, required_documents, description) VALUES
  ('svc-business-license', 'Business License', 'Business Registry', 'Business', '5 working days',
    ARRAY['Identity Proof', 'Business Registration Draft', 'Address Proof', 'Income Declaration'],
    'A single application that is verified across identity, business registry, tax, and municipal records before a license is issued — you submit your details once.'),
  ('svc-scholarship', 'Scholarship Scheme', 'Education Department', 'Education', '10-15 working days',
    ARRAY['Academic Records', 'Income Certificate', 'Aadhaar Card', 'Bank Passbook'],
    'Merit-cum-means scholarship support for undergraduate and postgraduate students enrolled in recognized institutions.'),
  ('svc-student-certificate', 'Student Certificates', 'Education Department', 'Education', '5-7 working days',
    ARRAY['School/College ID', 'Previous Marksheet'],
    'Issuance of bonafide, transfer, and migration certificates for enrolled students.'),
  ('svc-academic-verification', 'Academic Verification', 'Education Department', 'Education', '3-5 working days',
    ARRAY['Degree Certificate', 'Marksheet'],
    'Verification of academic credentials for employment or higher education purposes.'),
  ('svc-income-certificate', 'Income Certificate', 'Revenue Department', 'Revenue', '7-10 working days',
    ARRAY['Salary Slip / Income Proof', 'Aadhaar Card', 'Residence Proof'],
    'Official certification of annual household income for scheme eligibility purposes.'),
  ('svc-residence-certificate', 'Residence Certificate', 'Revenue Department', 'Revenue', '5-7 working days',
    ARRAY['Aadhaar Card', 'Utility Bill', 'Ration Card'],
    'Proof of domicile issued for education, employment, and welfare scheme applications.'),
  ('svc-tax-services', 'Tax Services', 'Revenue Department', 'Revenue', '3-5 working days',
    ARRAY['Property Documents', 'Previous Tax Receipt'],
    'Property tax assessment, payment, and dispute resolution services.'),
  ('svc-utility-connection', 'Utility Connection', 'Municipal Corporation', 'Municipal', '12-15 working days',
    ARRAY['Property Ownership Proof', 'Identity Proof'],
    'New water and electricity connection requests for residential and commercial properties.'),
  ('svc-property-services', 'Property Registration', 'Municipal Corporation', 'Municipal', '10-12 working days',
    ARRAY['Sale Deed', 'Property Tax Receipt'],
    'Property mutation, ownership transfer, and building plan approval services.'),
  ('svc-birth-certificate', 'Birth Certificate', 'Municipal Corporation', 'Municipal', '3-5 working days',
    ARRAY['Hospital Discharge Record', 'Parents'' Identity Proof'],
    'Registration and certified copy issuance for birth records.'),
  ('svc-health-benefits', 'Health Benefits', 'Health Department', 'Health', '7-10 working days',
    ARRAY['Aadhaar Card', 'Income Certificate'],
    'Enrollment into state-sponsored health benefit and treatment assistance schemes.'),
  ('svc-insurance-services', 'Insurance Services', 'Health Department', 'Health', '10-14 working days',
    ARRAY['Aadhaar Card', 'Family Details Form'],
    'Enrollment and claims support for state health insurance coverage.'),
  ('svc-pension', 'Pension', 'Social Welfare Department', 'Social Welfare', '15-20 working days',
    ARRAY['Age Proof', 'Income Certificate', 'Bank Passbook'],
    'Old-age, widow, and disability pension scheme enrollment and disbursement tracking.'),
  ('svc-welfare-schemes', 'Welfare Schemes', 'Social Welfare Department', 'Social Welfare', '10-15 working days',
    ARRAY['Aadhaar Card', 'Caste Certificate (if applicable)'],
    'Access to state and central welfare scheme benefits for eligible households.'),
  ('svc-benefits', 'Benefits Disbursement', 'Social Welfare Department', 'Social Welfare', '5-7 working days',
    ARRAY['Scheme Enrollment ID', 'Bank Passbook'],
    'Tracking and direct benefit transfer status for enrolled welfare schemes.')
ON CONFLICT (id) DO NOTHING;

-- SLA -------------------------------------------------------------------------

INSERT INTO sla_rules (label, target_label, target_hours, current_label, current_hours, within_sla) VALUES
  ('Business License (end-to-end)', '5 working days', 120, '3.2 days', 76.8, true),
  ('Identity Verification', '1 hour', 1, '4 minutes', 0.07, true),
  ('Tax Verification', '24 hours', 24, '6 hours', 6, true),
  ('Municipal Verification', '48 hours', 48, '51 hours', 51, false)
ON CONFLICT (label) DO NOTHING;

INSERT INTO platform_stats (key, value) VALUES
  ('overall_sla_compliance', 97.8)
ON CONFLICT (key) DO NOTHING;

-- Data quality ------------------------------------------------------------------

-- Placeholder baseline only — DataQualityService.computeAndPersist() overwrites
-- these on every GET /data-quality with numbers derived from real tables
-- (master_identity/consents/timeline_steps), so a fresh clone never actually shows
-- these values to a user.
INSERT INTO data_quality_metrics (id, records_processed, valid_records, warnings, validation_errors) VALUES
  (1, 0, 0, 0, 0)
ON CONFLICT (id) DO NOTHING;

-- Must match exactly the 3 labels DataQualityService.computeAndPersist() knows how
-- to recompute — any other label here would be a permanently-fake row.
INSERT INTO data_quality_issues (label, department, count, status) VALUES
  ('Missing Required Field', NULL, 0, 'Resolved'),
  ('Invalid Format', NULL, 0, 'Resolved'),
  ('Orphaned Consent Record', NULL, 0, 'Resolved')
ON CONFLICT (label) DO NOTHING;

INSERT INTO data_quality_department_rates (department, valid_rate) VALUES
  ('Education Department', 98.2),
  ('Revenue Department', 95.6),
  ('Municipal Corporation', 96.9),
  ('Health Department', 97.4),
  ('Food & Civil Supplies', 94.1)
ON CONFLICT (department) DO NOTHING;

-- Notifications -----------------------------------------------------------------

INSERT INTO notifications (id, citizen_master_id, type, title, description, created_at, read) VALUES
  ('ntf-1', 'CIT-10282', 'application', 'Application APP-2026-1001', 'Eligibility verification is in progress with the Revenue Department.', '2026-08-26T11:20:00Z', false),
  ('ntf-2', 'CIT-10282', 'document', 'Application APP-2026-1002', 'Income certificate document has been verified.', '2026-08-25T09:45:00Z', false),
  ('ntf-3', 'CIT-10282', 'consent', 'Consent request', 'Education Department requested access to academic details.', '2026-08-27T08:15:00Z', false),
  ('ntf-4', 'CIT-10282', 'application', 'Application APP-2026-1003', 'Business registration has been approved by the Business Registry.', '2026-08-24T16:30:00Z', true),
  ('ntf-5', 'CIT-10282', 'system', 'Scheduled maintenance', 'Municipal Corporation connector will be briefly unavailable on 30 Aug, 11 PM-1 AM.', '2026-08-23T10:00:00Z', true),
  ('ntf-6', 'CIT-10282', 'application', 'Application APP-2026-1005', 'Ration card application has been completed.', '2026-08-05T14:10:00Z', true)
ON CONFLICT (id) DO NOTHING;

-- Documents -----------------------------------------------------------------------

INSERT INTO documents (id, citizen_master_id, name, issued_by, status, issued_on, application_id) VALUES
  ('doc-1', 'CIT-10282', 'Aadhaar Card', 'UIDAI', 'Verified', '2021-02-14', NULL),
  ('doc-2', 'CIT-10282', 'Income Certificate', 'Revenue Department', 'Verified', '2026-01-10', 'APP-2026-1002'),
  ('doc-3', 'CIT-10282', 'Residence Certificate', 'Revenue Department', 'Verified', '2025-11-02', NULL),
  ('doc-4', 'CIT-10282', 'Academic Marksheet', 'Education Department', 'Verified', '2024-06-20', NULL),
  ('doc-5', 'CIT-10282', 'Ration Card', 'Food & Civil Supplies', 'Verified', '2026-08-05', 'APP-2026-1005'),
  ('doc-6', 'CIT-10282', 'Bank Passbook', 'Self-uploaded', 'Pending Verification', '2026-08-22', NULL)
ON CONFLICT (id) DO NOTHING;

-- Grievances --------------------------------------------------------------------

INSERT INTO grievances (id, citizen_master_id, subject, department, related_application, status, filed_on, description) VALUES
  ('GRV-2026-501', 'CIT-10282', 'Delay in income certificate verification', 'Revenue Department', 'APP-2026-1002', 'In Progress', '2026-08-24', 'Field verification for income certificate has been pending for more than 5 working days.'),
  ('GRV-2026-498', 'CIT-10282', 'Duplicate beneficiary record blocking enrollment', 'Health Department', 'APP-2026-1006', 'Open', '2026-08-13', 'Health insurance enrollment was rejected citing a duplicate record that does not belong to the applicant.'),
  ('GRV-2026-475', 'CIT-10282', 'Incorrect address on ration card', 'Food & Civil Supplies', 'APP-2026-1005', 'Resolved', '2026-08-06', 'Address printed on the issued ration card did not match the submitted residence proof.')
ON CONFLICT (id) DO NOTHING;
