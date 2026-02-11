-- 00001_initial_schema.sql
-- Initial database schema for Park at Balboa Park
-- Parking recommendation app for Balboa Park, San Diego
-- Balboa Park introduced paid parking Jan 5, 2026; 7 lots become free for residents March 2, 2026.

-- ============================================================================
-- TABLES
-- ============================================================================

-- 1. parking_lots
CREATE TABLE parking_lots (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug           text UNIQUE NOT NULL,
  name           text NOT NULL,
  display_name   text NOT NULL,
  address        text,
  lat            double precision,
  lng            double precision,
  capacity       integer,
  boundary_geojson jsonb,
  has_ev_charging boolean DEFAULT false,
  has_ada_spaces  boolean DEFAULT true,
  has_tram_stop   boolean DEFAULT false,
  notes          text,
  created_at     timestamptz DEFAULT now()
);

-- 2. lot_tier_assignments
CREATE TABLE lot_tier_assignments (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lot_id         uuid REFERENCES parking_lots(id),
  tier           smallint NOT NULL CHECK (tier BETWEEN 0 AND 3),
  effective_date date NOT NULL,
  end_date       date,
  created_at     timestamptz DEFAULT now(),
  UNIQUE (lot_id, effective_date)
);

-- 3. pricing_rules
CREATE TABLE pricing_rules (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tier           smallint NOT NULL,
  user_type      text NOT NULL CHECK (user_type IN ('resident','nonresident','staff','volunteer','ada')),
  duration_type  text NOT NULL DEFAULT 'hourly' CHECK (duration_type IN ('hourly','daily','event')),
  rate_cents     integer NOT NULL DEFAULT 0,
  max_daily_cents integer,
  effective_date date NOT NULL,
  end_date       date,
  created_at     timestamptz DEFAULT now()
);

-- 4. enforcement_periods
CREATE TABLE enforcement_periods (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  start_time     time NOT NULL DEFAULT '08:00',
  end_time       time NOT NULL DEFAULT '18:00',
  days_of_week   integer[] NOT NULL DEFAULT '{1,2,3,4,5,6,0}',
  effective_date date NOT NULL,
  end_date       date,
  created_at     timestamptz DEFAULT now()
);

-- 5. holidays
CREATE TABLE holidays (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name           text NOT NULL,
  date           date NOT NULL,
  is_recurring   boolean DEFAULT false,
  created_at     timestamptz DEFAULT now()
);

-- 6. destinations
CREATE TABLE destinations (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug           text UNIQUE NOT NULL,
  name           text NOT NULL,
  display_name   text NOT NULL,
  area           text NOT NULL CHECK (area IN ('central_mesa','palisades','east_mesa','florida_canyon','morley_field','pan_american')),
  type           text NOT NULL CHECK (type IN ('museum','garden','theater','landmark','recreation','dining','zoo','other')),
  address        text,
  lat            double precision,
  lng            double precision,
  website_url    text,
  created_at     timestamptz DEFAULT now()
);

-- 7. lot_destination_distances
CREATE TABLE lot_destination_distances (
  id                      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lot_id                  uuid REFERENCES parking_lots(id),
  destination_id          uuid REFERENCES destinations(id),
  walking_distance_meters integer NOT NULL,
  walking_time_seconds    integer NOT NULL,
  route_geojson           jsonb,
  created_at              timestamptz DEFAULT now(),
  UNIQUE (lot_id, destination_id)
);

-- 8. tram_stops
CREATE TABLE tram_stops (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name           text NOT NULL,
  lot_id         uuid REFERENCES parking_lots(id),
  lat            double precision,
  lng            double precision,
  stop_order     integer NOT NULL,
  created_at     timestamptz DEFAULT now()
);

-- 9. tram_schedule
CREATE TABLE tram_schedule (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  start_time        time NOT NULL,
  end_time          time NOT NULL,
  frequency_minutes integer NOT NULL,
  days_of_week      integer[] NOT NULL DEFAULT '{1,2,3,4,5,6,0}',
  effective_date    date NOT NULL,
  end_date          date,
  created_at        timestamptz DEFAULT now()
);

-- 10. parking_passes
CREATE TABLE parking_passes (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name           text NOT NULL,
  type           text NOT NULL CHECK (type IN ('monthly','quarterly','annual')),
  price_cents    integer NOT NULL,
  user_type      text NOT NULL CHECK (user_type IN ('resident','nonresident')),
  effective_date date NOT NULL,
  end_date       date,
  created_at     timestamptz DEFAULT now()
);

-- 11. payment_methods
CREATE TABLE payment_methods (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lot_id         uuid REFERENCES parking_lots(id),
  method         text NOT NULL CHECK (method IN ('credit_card','apple_pay','google_pay','coins','parkmobile')),
  created_at     timestamptz DEFAULT now(),
  UNIQUE (lot_id, method)
);

-- 12. street_meters
CREATE TABLE street_meters (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name                  text NOT NULL,
  zone                  text,
  rate_cents_per_hour   integer NOT NULL,
  max_hours             numeric(3,1),
  lat                   double precision,
  lng                   double precision,
  boundary_geojson      jsonb,
  created_at            timestamptz DEFAULT now()
);

-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX idx_lot_tier_assignments_lot_date ON lot_tier_assignments (lot_id, effective_date);
CREATE INDEX idx_pricing_rules_tier_user_date ON pricing_rules (tier, user_type, effective_date);
CREATE INDEX idx_lot_dest_dist_lot ON lot_destination_distances (lot_id);
CREATE INDEX idx_lot_dest_dist_dest ON lot_destination_distances (destination_id);
CREATE INDEX idx_destinations_slug ON destinations (slug);
CREATE INDEX idx_parking_lots_slug ON parking_lots (slug);

-- ============================================================================
-- VIEW
-- ============================================================================

CREATE VIEW v_current_lot_pricing AS
SELECT
  pl.id,
  pl.slug,
  pl.name,
  pl.display_name,
  pl.lat,
  pl.lng,
  pl.capacity,
  pl.has_tram_stop,
  pl.has_ada_spaces,
  lta.tier,
  pr.user_type,
  pr.duration_type,
  pr.rate_cents,
  pr.max_daily_cents
FROM parking_lots pl
JOIN lot_tier_assignments lta
  ON lta.lot_id = pl.id
 AND CURRENT_DATE BETWEEN lta.effective_date AND COALESCE(lta.end_date, '9999-12-31'::date)
JOIN pricing_rules pr
  ON pr.tier = lta.tier
 AND CURRENT_DATE BETWEEN pr.effective_date AND COALESCE(pr.end_date, '9999-12-31'::date);

-- ============================================================================
-- RPC FUNCTION
-- ============================================================================

CREATE OR REPLACE FUNCTION get_parking_recommendations(
  p_user_type      text       DEFAULT 'nonresident',
  p_has_pass       boolean    DEFAULT false,
  p_destination_slug text     DEFAULT NULL,
  p_query_time     timestamptz DEFAULT now(),
  p_visit_hours    numeric    DEFAULT 2
)
RETURNS TABLE (
  lot_slug                text,
  lot_name                text,
  lot_display_name        text,
  lat                     double precision,
  lng                     double precision,
  tier                    smallint,
  cost_cents              integer,
  cost_display            text,
  is_free                 boolean,
  walking_distance_meters integer,
  walking_time_seconds    integer,
  walking_time_display    text,
  has_tram                boolean,
  tram_time_minutes       integer,
  score                   numeric,
  tips                    text[]
)
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v_enforced       boolean := false;
  v_query_date     date;
  v_query_time_of_day time;
  v_day_of_week    integer;
  v_is_holiday     boolean := false;
  v_max_cost       integer;
  v_max_walk       integer;
BEGIN
  -- Extract date/time components
  v_query_date := (p_query_time AT TIME ZONE 'America/Los_Angeles')::date;
  v_query_time_of_day := (p_query_time AT TIME ZONE 'America/Los_Angeles')::time;
  v_day_of_week := EXTRACT(DOW FROM p_query_time AT TIME ZONE 'America/Los_Angeles')::integer;

  -- Check if today is a holiday
  SELECT EXISTS (
    SELECT 1 FROM holidays h
    WHERE h.date = v_query_date
       OR (h.is_recurring AND EXTRACT(MONTH FROM h.date) = EXTRACT(MONTH FROM v_query_date)
                           AND EXTRACT(DAY FROM h.date) = EXTRACT(DAY FROM v_query_date))
  ) INTO v_is_holiday;

  -- Check if enforcement is active
  IF NOT v_is_holiday THEN
    SELECT EXISTS (
      SELECT 1 FROM enforcement_periods ep
      WHERE v_query_date BETWEEN ep.effective_date AND COALESCE(ep.end_date, '9999-12-31'::date)
        AND v_query_time_of_day BETWEEN ep.start_time AND ep.end_time
        AND v_day_of_week = ANY(ep.days_of_week)
    ) INTO v_enforced;
  END IF;

  -- Build results into a temp table for scoring
  CREATE TEMP TABLE _recommendations ON COMMIT DROP AS
  SELECT
    pl.slug                           AS lot_slug,
    pl.name                           AS lot_name,
    pl.display_name                   AS lot_display_name,
    pl.lat                            AS lat,
    pl.lng                            AS lng,
    COALESCE(lta.tier, 0::smallint)   AS tier,
    pl.has_tram_stop                  AS has_tram,
    pl.has_ev_charging                AS has_ev_charging,
    pl.has_ada_spaces                 AS has_ada_spaces,
    ldd.walking_distance_meters       AS walking_distance_meters,
    ldd.walking_time_seconds          AS walking_time_seconds,
    -- Cost calculation
    CASE
      -- Not enforced or user has a pass: free everywhere
      WHEN NOT v_enforced OR p_has_pass THEN 0
      -- ADA: always free
      WHEN p_user_type = 'ada' THEN 0
      -- Tier 0: always free for everyone
      WHEN COALESCE(lta.tier, 0) = 0 THEN 0
      -- Lower Inspiration Point: first 3 hours free for everyone
      WHEN pl.slug = 'inspiration-point-lower' AND p_visit_hours <= 3 THEN 0
      -- Staff/volunteer: free in tier 0, 2, 3; normal pricing in tier 1
      WHEN p_user_type IN ('staff','volunteer') AND COALESCE(lta.tier, 0) IN (2, 3) THEN 0
      -- Resident: free in tier 2, 3
      WHEN p_user_type = 'resident' AND COALESCE(lta.tier, 0) IN (2, 3) THEN 0
      -- Otherwise: look up pricing
      ELSE COALESCE(
        (
          SELECT LEAST(
            pr.rate_cents * CEIL(p_visit_hours)::integer,
            COALESCE(pr.max_daily_cents, pr.rate_cents * CEIL(p_visit_hours)::integer)
          )
          FROM pricing_rules pr
          WHERE pr.tier = COALESCE(lta.tier, 0)
            AND pr.user_type = p_user_type
            AND pr.duration_type = 'hourly'
            AND v_query_date BETWEEN pr.effective_date AND COALESCE(pr.end_date, '9999-12-31'::date)
          ORDER BY pr.effective_date DESC
          LIMIT 1
        ),
        0
      )
    END AS cost_cents,
    -- Tram time estimate (based on frequency / 2 as average wait + ~5 min ride)
    CASE
      WHEN pl.has_tram_stop THEN (
        SELECT (ts.frequency_minutes / 2) + 5
        FROM tram_schedule ts
        WHERE v_query_date BETWEEN ts.effective_date AND COALESCE(ts.end_date, '9999-12-31'::date)
          AND v_query_time_of_day BETWEEN ts.start_time AND ts.end_time
          AND v_day_of_week = ANY(ts.days_of_week)
        ORDER BY ts.effective_date DESC
        LIMIT 1
      )
      ELSE NULL
    END AS tram_time_minutes
  FROM parking_lots pl
  LEFT JOIN lot_tier_assignments lta
    ON lta.lot_id = pl.id
   AND v_query_date BETWEEN lta.effective_date AND COALESCE(lta.end_date, '9999-12-31'::date)
  LEFT JOIN lot_destination_distances ldd
    ON ldd.lot_id = pl.id
   AND p_destination_slug IS NOT NULL
   AND ldd.destination_id = (
     SELECT d.id FROM destinations d WHERE d.slug = p_destination_slug LIMIT 1
   );

  -- Get max values for normalization
  SELECT GREATEST(MAX(r.cost_cents), 1), GREATEST(MAX(r.walking_distance_meters), 1)
    INTO v_max_cost, v_max_walk
    FROM _recommendations r;

  -- Return scored results
  RETURN QUERY
  SELECT
    r.lot_slug,
    r.lot_name,
    r.lot_display_name,
    r.lat,
    r.lng,
    r.tier,
    r.cost_cents,
    -- cost_display
    CASE
      WHEN r.cost_cents = 0 THEN 'FREE'
      ELSE '$' || (r.cost_cents / 100.0)::numeric(10,2)::text
    END AS cost_display,
    -- is_free
    (r.cost_cents = 0) AS is_free,
    r.walking_distance_meters,
    r.walking_time_seconds,
    -- walking_time_display
    CASE
      WHEN r.walking_time_seconds IS NULL THEN NULL
      ELSE CEIL(r.walking_time_seconds / 60.0)::integer::text || ' min walk'
    END AS walking_time_display,
    r.has_tram,
    r.tram_time_minutes,
    -- Score: cost 0.40, walk 0.35, tram 0.10, tier 0.10, ada 0.05
    ROUND(
      0.40 * (1.0 - (r.cost_cents::numeric / v_max_cost))
      + 0.35 * (1.0 - COALESCE(r.walking_distance_meters::numeric / v_max_walk, 0.5))
      + 0.10 * CASE WHEN r.has_tram THEN 1 ELSE 0 END
      + 0.10 * (1.0 - r.tier::numeric / 3.0)
      + 0.05 * CASE WHEN r.has_ada_spaces THEN 1 ELSE 0 END
    , 4) AS score,
    -- Tips
    ARRAY_REMOVE(ARRAY[
      CASE WHEN r.lot_slug = 'inspiration-point-lower' AND v_enforced AND p_visit_hours <= 3
           THEN 'First 3 hours free' END,
      CASE WHEN NOT v_enforced
           THEN 'Free parking (outside enforcement hours)' END,
      CASE WHEN v_is_holiday
           THEN 'Free parking (holiday)' END,
      CASE WHEN p_has_pass AND v_enforced
           THEN 'Free with parking pass' END,
      CASE WHEN r.has_tram AND r.tram_time_minutes IS NOT NULL
           THEN 'Tram available to destination' END,
      CASE WHEN r.has_ev_charging
           THEN 'EV charging available' END,
      CASE WHEN r.tier = 0
           THEN 'Always free lot' END
    ], NULL) AS tips
  FROM _recommendations r
  ORDER BY score DESC;
END;
$$;

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE parking_lots ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access" ON parking_lots FOR SELECT USING (true);

ALTER TABLE lot_tier_assignments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access" ON lot_tier_assignments FOR SELECT USING (true);

ALTER TABLE pricing_rules ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access" ON pricing_rules FOR SELECT USING (true);

ALTER TABLE enforcement_periods ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access" ON enforcement_periods FOR SELECT USING (true);

ALTER TABLE holidays ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access" ON holidays FOR SELECT USING (true);

ALTER TABLE destinations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access" ON destinations FOR SELECT USING (true);

ALTER TABLE lot_destination_distances ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access" ON lot_destination_distances FOR SELECT USING (true);

ALTER TABLE tram_stops ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access" ON tram_stops FOR SELECT USING (true);

ALTER TABLE tram_schedule ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access" ON tram_schedule FOR SELECT USING (true);

ALTER TABLE parking_passes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access" ON parking_passes FOR SELECT USING (true);

ALTER TABLE payment_methods ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access" ON payment_methods FOR SELECT USING (true);

ALTER TABLE street_meters ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access" ON street_meters FOR SELECT USING (true);
