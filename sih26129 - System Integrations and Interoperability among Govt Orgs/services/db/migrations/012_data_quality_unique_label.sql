-- No unique constraint existed on data_quality_issues.label, so the seed's
-- "ON CONFLICT DO NOTHING" silently never triggered — a second seed application
-- (or a stray manual re-run) duplicated every row. Adds the constraint the seed
-- always assumed existed.
ALTER TABLE data_quality_issues ADD CONSTRAINT data_quality_issues_label_key UNIQUE (label);
