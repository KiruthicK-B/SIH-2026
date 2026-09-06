-- Backs "login with mobile number / citizen ID / Aadhaar-style number" — citizens
-- shouldn't need to remember a Keycloak username, only whichever identifier they
-- already know. This table maps any of those to the actual Keycloak username; the
-- resolved username is used only as a loginHint pre-filling Keycloak's own hosted
-- login page (core-api never sees or handles the password).
ALTER TABLE master_identity ADD COLUMN IF NOT EXISTS keycloak_username TEXT;
ALTER TABLE master_identity ADD COLUMN IF NOT EXISTS phone_number TEXT;
ALTER TABLE master_identity ADD COLUMN IF NOT EXISTS aadhaar_number TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS master_identity_phone_idx ON master_identity (phone_number) WHERE phone_number IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS master_identity_aadhaar_idx ON master_identity (aadhaar_number) WHERE aadhaar_number IS NOT NULL;
