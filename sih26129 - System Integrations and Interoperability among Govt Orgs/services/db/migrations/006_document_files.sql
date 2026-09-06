-- Real file upload (previously the ApplicationWizard's "Documents" step was just a
-- boolean checkbox with nothing stored anywhere).
ALTER TABLE documents ADD COLUMN IF NOT EXISTS file_path TEXT;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS mime_type TEXT;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS size_bytes INT;
