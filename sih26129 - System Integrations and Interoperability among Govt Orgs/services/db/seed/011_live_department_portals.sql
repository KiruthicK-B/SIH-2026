-- The three live department portals backing the "Trade & Establishment Clearance"
-- flow (LIVE_DEPARTMENT_PORTALS_PLAN.md) — distinct department identities from the
-- Business License flow's stub adapters above, on purpose: this never touches that
-- flow's already-shipped consent-gating.

INSERT INTO departments (id, name, description, service_count, interface_type, onboarded_on, modernization_percent, modernization_target, modernization_status) VALUES
  ('dept-business-registry-portal', 'Business Registry Portal', 'Independently-run business registration system — own SOAP API, own MySQL database, own officer login.', 1, 'Legacy SOAP', '2026-09-12', 40, 'Own officer portal', 'Live connector · independent system'),
  ('dept-license-authority-portal', 'License Authority Portal', 'Independently-run trade licensing system — own GraphQL API, own MongoDB database, own officer login.', 1, 'GraphQL API', '2026-09-12', 100, 'Own officer portal', 'Live connector · independent system'),
  ('dept-revenue-portal', 'Revenue Department Portal', 'Independently-run revenue clearance system — own REST API, own PostgreSQL database, own officer login.', 1, 'REST API', '2026-09-12', 100, 'Own officer portal', 'Live connector · independent system')
ON CONFLICT (id) DO NOTHING;

INSERT INTO connector_registry (name, protocol, health, kill_switch_enabled) VALUES
  ('Business Registry Portal', 'SOAP', 'Healthy', false),
  ('License Authority Portal', 'GraphQL', 'Healthy', false),
  ('Revenue Department Portal', 'REST', 'Healthy', false)
ON CONFLICT (name) DO NOTHING;

INSERT INTO services (id, name, department, category, processing_time, required_documents, description) VALUES
  ('svc-trade-clearance', 'Trade & Establishment Clearance', 'Business Registry Portal', 'Business', '7 working days',
    ARRAY['Identity Proof', 'Business Registration Draft', 'Address Proof'],
    'One application reviewed by three independently-run department systems in sequence — Business Registry (SOAP), License Authority (GraphQL), Revenue (REST) — each with its own database and its own officer making the call.')
ON CONFLICT (id) DO NOTHING;

-- Real request/response shape sent by connectors.service.ts's buildCanonicalPayload +
-- submitSoap/submitGraphQl/submitRest — not illustrative filler (see the "Identity
-- Service" rows above this same table, which explain why this table exists at all).
INSERT INTO adapter_data_flows (department, direction, field, canonical_field, sample_value, step_order) VALUES
  ('Business Registry Portal', 'Outbound', 'ApplicationId', 'applicationId', 'TRD-2026-0042', 0),
  ('Business Registry Portal', 'Outbound', 'CitizenName', 'citizen.name', 'Kiruthick B', 1),
  ('Business Registry Portal', 'Outbound', 'Address', 'citizen.address', '…', 2),
  ('Business Registry Portal', 'Inbound', 'Accepted', 'submitted', 'true', 3),
  ('Business Registry Portal', 'Internal', 'decision', 'callback.decision', 'APPROVED', 4),

  ('License Authority Portal', 'Outbound', 'input.applicationId', 'applicationId', 'TRD-2026-0042', 0),
  ('License Authority Portal', 'Outbound', 'input.citizenName', 'citizen.name', 'Kiruthick B', 1),
  ('License Authority Portal', 'Inbound', 'data.submitCase.accepted', 'submitted', 'true', 2),
  ('License Authority Portal', 'Internal', 'decision', 'callback.decision', 'APPROVED', 3),

  ('Revenue Department Portal', 'Outbound', 'applicationId', 'applicationId', 'TRD-2026-0042', 0),
  ('Revenue Department Portal', 'Outbound', 'citizen.consentedDataCategory', 'consentedDataCategory', 'Identity & Address Details', 1),
  ('Revenue Department Portal', 'Inbound', 'accepted', 'submitted', 'true', 2),
  ('Revenue Department Portal', 'Internal', 'decision', 'callback.decision', 'APPROVED', 3)
ON CONFLICT (department, direction, field) DO NOTHING;
