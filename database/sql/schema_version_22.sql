ALTER TABLE feeds ADD COLUMN fetch_disabled BOOLEAN DEFAULT false;
UPDATE feeds SET fetch_disabled = false;
