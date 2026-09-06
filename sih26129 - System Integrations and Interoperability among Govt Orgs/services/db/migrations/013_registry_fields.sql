-- Mirrors govt_identity_records' new fields (see digilocker-adapter/index.js) so the
-- identity.family scope has somewhere to copy them into on the OneDesk side.
ALTER TABLE master_identity
  ADD COLUMN IF NOT EXISTS father_name TEXT,
  ADD COLUMN IF NOT EXISTS mother_name TEXT,
  ADD COLUMN IF NOT EXISTS parent_phone_number TEXT,
  ADD COLUMN IF NOT EXISTS siblings TEXT,
  ADD COLUMN IF NOT EXISTS occupation TEXT;
