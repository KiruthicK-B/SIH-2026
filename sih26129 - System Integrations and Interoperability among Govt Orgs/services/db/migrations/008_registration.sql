-- Citizen self-registration needs fields real Aadhaar/DigiLocker eKYC never returns
-- (employment, education) — self-declared at registration, same as most e-governance
-- systems do (verified against the relevant department later, not upfront) — plus a
-- PAN column the user asked to collect at signup.
ALTER TABLE master_identity ADD COLUMN IF NOT EXISTS pan_number TEXT;
ALTER TABLE master_identity ADD COLUMN IF NOT EXISTS employment_status TEXT;
ALTER TABLE master_identity ADD COLUMN IF NOT EXISTS highest_qualification TEXT;
