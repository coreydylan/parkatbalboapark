-- 00003_street_meters_sync.sql
-- Recreate street_meters table to match City of San Diego CSV schema
-- for daily sync from https://seshat.datasd.org/parking_meters_locations/parking_meters_current.csv

-- Drop the stub table (empty, no data loss)
DROP POLICY IF EXISTS "Public read access" ON street_meters;
DROP TABLE IF EXISTS street_meters;

CREATE TABLE street_meters (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pole                text UNIQUE NOT NULL,        -- natural key from CSV
  zone                text,
  area                text,
  sub_area            text,                         -- block/street identifier
  lat                 double precision,
  lng                 double precision,
  config_id           integer,
  config_name         text,
  time_start          text,                         -- e.g. "8am"
  time_end            text,                         -- e.g. "8pm"
  time_limit          text,                         -- e.g. "2 hour", "30 min"
  days_in_operation   text,                         -- e.g. "Mon-Sat"
  rate_cents_per_hour integer,                      -- parsed from price string
  mobile_pay          boolean DEFAULT false,
  multi_space         boolean DEFAULT false,
  restrictions        text,
  synced_at           timestamptz DEFAULT now()
);

CREATE INDEX idx_street_meters_zone ON street_meters (zone);
CREATE INDEX idx_street_meters_lat_lng ON street_meters (lat, lng);

ALTER TABLE street_meters ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access" ON street_meters FOR SELECT USING (true);
