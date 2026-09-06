-- Backs the Data Mapping tab (converted from mock to real): the actual fields each
-- live connector call exchanges. Kept separate from field_mappings, which the
-- AI-assisted schema-mapping-suggestion feature owns.
CREATE TABLE IF NOT EXISTS adapter_data_flows (
  id SERIAL PRIMARY KEY,
  department TEXT NOT NULL,
  direction TEXT NOT NULL, -- Outbound | Inbound
  field TEXT NOT NULL,
  canonical_field TEXT NOT NULL,
  sample_value TEXT NOT NULL,
  step_order INT NOT NULL DEFAULT 0,
  UNIQUE (department, direction, field)
);
