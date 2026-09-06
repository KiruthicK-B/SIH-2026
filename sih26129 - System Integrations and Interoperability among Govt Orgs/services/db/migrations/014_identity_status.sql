-- Cached copy of the govt registry's identity_status as of the last time OneDesk
-- checked it (at registration, or at the most recent workflow revalidation) — see
-- WorkflowService.runAutoAdvance's live-vs-cached check. Not the source of truth;
-- the registry (digilocker-adapter's own DB) always is.
ALTER TABLE master_identity ADD COLUMN IF NOT EXISTS identity_status TEXT DEFAULT 'ACTIVE';
