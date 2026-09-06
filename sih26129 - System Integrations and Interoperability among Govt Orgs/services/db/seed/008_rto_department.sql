-- RTO didn't exist as a department at all before eligibility rules needed a
-- concrete example beyond Revenue Department. Manual Processing — same honest
-- category as Health/Education/Welfare/Food, no live connector invented just to
-- make this look more complete than it is.
INSERT INTO departments (id, name, description, service_count, interface_type, onboarded_on, modernization_percent, modernization_target, modernization_status) VALUES
  ('dept-rto', 'RTO', 'Issues and renews driving licences and vehicle registration certificates.', 3, 'REST API', '2026-09-05', 20, 'Modern REST service', 'Not yet integrated')
ON CONFLICT (id) DO NOTHING;
