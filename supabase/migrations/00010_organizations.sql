-- 00003_organizations.sql
-- Park organizations that qualify for staff/volunteer parking benefits
-- These are Balboa Park organizations with leaseholds or special use permits

CREATE TABLE IF NOT EXISTS park_organizations (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug           text UNIQUE NOT NULL,
  name           text NOT NULL,
  category       text NOT NULL CHECK (category IN ('museum','performing-arts','cultural','garden','nonprofit','club','zoo','government')),
  created_at     timestamptz DEFAULT now()
);

-- Enable RLS but allow public read access (this is non-sensitive public data)
ALTER TABLE park_organizations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access on park_organizations"
  ON park_organizations FOR SELECT
  USING (true);
