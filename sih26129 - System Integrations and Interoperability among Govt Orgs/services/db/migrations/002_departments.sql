-- Moves department metadata out of the frontend bundle (onedesk/src/data/departments.ts)
-- into real backend state — served live via GET /departments, not baked into the JS
-- build. Health/kill-switch for the 5 departments with a live connector still comes
-- from connector_registry; departments without one honestly report 'Manual Processing'
-- rather than a fake "Healthy".

CREATE TABLE IF NOT EXISTS departments (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  description TEXT NOT NULL,
  service_count INT NOT NULL DEFAULT 0,
  interface_type TEXT NOT NULL,
  onboarded_on DATE NOT NULL,
  modernization_percent INT NOT NULL DEFAULT 0,
  modernization_target TEXT NOT NULL,
  modernization_status TEXT NOT NULL
);
