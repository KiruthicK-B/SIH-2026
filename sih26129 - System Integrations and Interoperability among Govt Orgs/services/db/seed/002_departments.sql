INSERT INTO departments (id, name, description, service_count, interface_type, onboarded_on, modernization_percent, modernization_target, modernization_status) VALUES
  ('dept-education', 'Education Department', 'Manages scholarships, student certification, and academic verification services statewide.', 12, 'REST API', '2025-03-10', 100, 'Modern REST service', 'Fully modernized'),
  ('dept-revenue', 'Revenue Department', 'Issues income and residence certificates, and manages property tax records.', 9, 'REST API', '2025-04-22', 85, 'Modern REST service', 'Migration in progress'),
  ('dept-municipal', 'Municipal Corporation', 'Handles utility connections, property services, and civil registration records.', 8, 'Database Connector', '2025-05-18', 60, 'Modern REST service', 'Migration planned'),
  ('dept-health', 'Health Department', 'Administers state health benefit schemes and insurance enrollment.', 6, 'REST API', '2025-06-30', 100, 'Modern REST service', 'Fully modernized'),
  ('dept-food-supplies', 'Food & Civil Supplies', 'Manages ration card issuance and public distribution system records.', 7, 'File/SFTP', '2025-07-15', 35, 'Event-driven API adapter', 'Integration only'),
  ('dept-welfare', 'Social Welfare Department', 'Administers pension schemes and welfare benefit disbursement.', 6, 'REST API', '2025-08-01', 100, 'Modern REST service', 'Fully modernized'),
  ('dept-business-registry', 'Business Registry', 'Maintains business entity registration records and micro-enterprise licensing history.', 5, 'Legacy SOAP', '2025-09-12', 40, 'Modern REST service', 'Adapter connected · migration planned'),
  ('dept-license-authority', 'License Authority', 'Issues and renews statutory business and trade licenses across the state.', 4, 'GraphQL API', '2025-10-01', 100, 'GraphQL service', 'Fully modernized'),
  ('dept-identity', 'Identity Service', 'Platform-wide federated identity and single sign-on service used by every connected department.', 1, 'OAuth / Federation', '2025-01-15', 100, 'Federated identity', 'Native to platform')
ON CONFLICT (id) DO NOTHING;
