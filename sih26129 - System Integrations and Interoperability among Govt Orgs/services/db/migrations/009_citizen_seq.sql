-- Generates new master_id values for self-registered citizens (CIT-20001, CIT-20002, ...)
-- — starts well above the seeded CIT-10282 so there's no collision risk.
CREATE SEQUENCE IF NOT EXISTS citizen_seq START 20001;
