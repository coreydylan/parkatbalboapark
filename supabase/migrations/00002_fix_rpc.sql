-- 00002_fix_rpc.sql
-- Deduplicate cost calculation in get_parking_recommendations RPC
-- Fix enforcement time boundary (use >= start AND < end, not BETWEEN)
-- Fix ADA pricing to be date-aware (free after 2026-03-02; pays tier 1 before)

-- ============================================================================
-- HELPER: compute_lot_cost
-- Single source of truth for per-lot cost calculation (was duplicated 6x).
-- ============================================================================

CREATE OR REPLACE FUNCTION compute_lot_cost(
  p_tier         smallint,
  p_lot_slug     text,
  p_user_type    text,
  p_has_pass     boolean,
  p_visit_hours  numeric,
  p_enforced     boolean,
  p_query_date   date
) RETURNS integer
LANGUAGE plpgsql STABLE
AS $$
BEGIN
  -- Not enforced or has a parking pass -> free
  IF NOT p_enforced OR p_has_pass THEN RETURN 0; END IF;

  -- Free tier (tier 0) is always free
  IF p_tier = 0 THEN RETURN 0; END IF;

  -- ADA: free everywhere on/after 2026-03-02; before that, free at tier 2/3 only
  IF p_user_type = 'ada' THEN
    IF p_query_date >= '2026-03-02'::date OR p_tier != 1 THEN
      RETURN 0;
    END IF;
  END IF;

  -- Inspiration Point Lower: first 3 hours free
  IF p_lot_slug = 'inspiration-point-lower' AND p_visit_hours <= 3 THEN RETURN 0; END IF;

  -- Staff/volunteer free at tier 2/3
  IF p_user_type IN ('staff', 'volunteer') AND p_tier IN (2, 3) THEN RETURN 0; END IF;

  -- Residents free at tier 2/3 (matches pricing data: rateCents=0)
  IF p_user_type = 'resident' AND p_tier IN (2, 3) THEN RETURN 0; END IF;

  -- Look up hourly pricing rule
  RETURN COALESCE(
    (SELECT LEAST(
       pr.rate_cents * CEIL(p_visit_hours)::integer,
       COALESCE(pr.max_daily_cents, pr.rate_cents * CEIL(p_visit_hours)::integer)
     )
     FROM pricing_rules pr
     WHERE pr.tier = p_tier
       AND pr.user_type = p_user_type
       AND pr.duration_type = 'hourly'
       AND p_query_date BETWEEN pr.effective_date AND COALESCE(pr.end_date, '9999-12-31'::date)
     ORDER BY pr.effective_date DESC
     LIMIT 1),
    0);
END;
$$;

-- ============================================================================
-- REPLACE: get_parking_recommendations
-- Same RETURNS TABLE signature so callers are unaffected.
-- ============================================================================

CREATE OR REPLACE FUNCTION get_parking_recommendations(
  p_user_type        text        DEFAULT 'nonresident',
  p_has_pass         boolean     DEFAULT false,
  p_destination_slug text        DEFAULT NULL,
  p_query_time       timestamptz DEFAULT now(),
  p_visit_hours      numeric     DEFAULT 2
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
  v_enforced         boolean := false;
  v_query_date       date;
  v_query_time_of_day time;
  v_day_of_week      integer;
  v_is_holiday       boolean := false;
  v_max_cost         integer;
  v_max_walk         integer;
BEGIN
  -- Convert to Pacific time
  v_query_date        := (p_query_time AT TIME ZONE 'America/Los_Angeles')::date;
  v_query_time_of_day := (p_query_time AT TIME ZONE 'America/Los_Angeles')::time;
  v_day_of_week       := EXTRACT(DOW FROM p_query_time AT TIME ZONE 'America/Los_Angeles')::integer;

  -- Holiday check
  SELECT EXISTS (
    SELECT 1 FROM holidays h
    WHERE h.date = v_query_date
       OR (h.is_recurring
           AND EXTRACT(MONTH FROM h.date) = EXTRACT(MONTH FROM v_query_date)
           AND EXTRACT(DAY   FROM h.date) = EXTRACT(DAY   FROM v_query_date))
  ) INTO v_is_holiday;

  -- Enforcement check: >= start AND < end (exclusive end boundary)
  IF NOT v_is_holiday THEN
    SELECT EXISTS (
      SELECT 1 FROM enforcement_periods ep
      WHERE v_query_date BETWEEN ep.effective_date AND COALESCE(ep.end_date, '9999-12-31'::date)
        AND v_query_time_of_day >= ep.start_time
        AND v_query_time_of_day <  ep.end_time
        AND v_day_of_week = ANY(ep.days_of_week)
    ) INTO v_enforced;
  END IF;

  -- Normalization maxima via CTE
  SELECT
    GREATEST(MAX(sub.c), 1),
    GREATEST(MAX(sub.w), 1)
  INTO v_max_cost, v_max_walk
  FROM (
    SELECT
      compute_lot_cost(
        COALESCE(lta.tier, 0::smallint),
        pl.slug,
        p_user_type,
        p_has_pass,
        p_visit_hours,
        v_enforced,
        v_query_date
      ) AS c,
      ldd.walking_distance_meters AS w
    FROM parking_lots pl
    LEFT JOIN lot_tier_assignments lta ON lta.lot_id = pl.id
      AND v_query_date BETWEEN lta.effective_date AND COALESCE(lta.end_date, '9999-12-31'::date)
    LEFT JOIN lot_destination_distances ldd ON ldd.lot_id = pl.id
      AND p_destination_slug IS NOT NULL
      AND ldd.destination_id = (SELECT d.id FROM destinations d WHERE d.slug = p_destination_slug LIMIT 1)
  ) sub;

  -- Main query: compute cost once per lot, derive all columns from it
  RETURN QUERY
  WITH lot_costs AS (
    SELECT
      pl.id           AS lot_id,
      pl.slug         AS lot_slug,
      pl.name         AS lot_name,
      pl.display_name AS lot_display_name,
      pl.lat          AS lot_lat,
      pl.lng          AS lot_lng,
      pl.has_tram_stop,
      pl.has_ev_charging,
      pl.has_ada_spaces,
      COALESCE(lta.tier, 0::smallint) AS lot_tier,
      compute_lot_cost(
        COALESCE(lta.tier, 0::smallint),
        pl.slug,
        p_user_type,
        p_has_pass,
        p_visit_hours,
        v_enforced,
        v_query_date
      ) AS cost,
      ldd.walking_distance_meters,
      ldd.walking_time_seconds
    FROM parking_lots pl
    LEFT JOIN lot_tier_assignments lta ON lta.lot_id = pl.id
      AND v_query_date BETWEEN lta.effective_date AND COALESCE(lta.end_date, '9999-12-31'::date)
    LEFT JOIN lot_destination_distances ldd ON ldd.lot_id = pl.id
      AND p_destination_slug IS NOT NULL
      AND ldd.destination_id = (SELECT d.id FROM destinations d WHERE d.slug = p_destination_slug LIMIT 1)
  )
  SELECT
    lc.lot_slug,
    lc.lot_name,
    lc.lot_display_name,
    lc.lot_lat,
    lc.lot_lng,
    lc.lot_tier,
    -- cost_cents
    lc.cost,
    -- cost_display
    CASE WHEN lc.cost = 0 THEN 'FREE'
         ELSE '$' || (lc.cost / 100.0)::numeric(10,2)::text
    END,
    -- is_free
    lc.cost = 0,
    -- walking
    lc.walking_distance_meters,
    lc.walking_time_seconds,
    CASE WHEN lc.walking_time_seconds IS NULL THEN NULL
         ELSE CEIL(lc.walking_time_seconds / 60.0)::integer::text || ' min walk'
    END,
    -- tram
    lc.has_tram_stop,
    CASE WHEN lc.has_tram_stop THEN (
      SELECT (ts.frequency_minutes / 2) + 5
      FROM tram_schedule ts
      WHERE v_query_date BETWEEN ts.effective_date AND COALESCE(ts.end_date, '9999-12-31'::date)
        AND v_query_time_of_day >= ts.start_time
        AND v_query_time_of_day <  ts.end_time
        AND v_day_of_week = ANY(ts.days_of_week)
      ORDER BY ts.effective_date DESC
      LIMIT 1)
    ELSE NULL END,
    -- score
    ROUND(
      0.40 * (1.0 - lc.cost::numeric / v_max_cost)
      + 0.35 * (1.0 - COALESCE(lc.walking_distance_meters::numeric / v_max_walk, 0.5))
      + 0.10 * CASE WHEN lc.has_tram_stop THEN 1 ELSE 0 END
      + 0.10 * (1.0 - lc.lot_tier::numeric / 3.0)
      + 0.05 * CASE WHEN lc.has_ada_spaces THEN 1 ELSE 0 END
    , 4),
    -- tips
    ARRAY_REMOVE(ARRAY[
      CASE WHEN lc.lot_slug = 'inspiration-point-lower' AND v_enforced AND p_visit_hours <= 3
           THEN 'First 3 hours free' END,
      CASE WHEN NOT v_enforced
           THEN 'Free parking (outside enforcement hours)' END,
      CASE WHEN v_is_holiday
           THEN 'Free parking (holiday)' END,
      CASE WHEN p_has_pass AND v_enforced
           THEN 'Free with parking pass' END,
      CASE WHEN lc.has_tram_stop AND (
             SELECT 1 FROM tram_schedule ts2
             WHERE v_query_date BETWEEN ts2.effective_date AND COALESCE(ts2.end_date, '9999-12-31'::date)
               AND v_query_time_of_day >= ts2.start_time
               AND v_query_time_of_day <  ts2.end_time
               AND v_day_of_week = ANY(ts2.days_of_week)
             LIMIT 1) IS NOT NULL
           THEN 'Tram available to destination' END,
      CASE WHEN lc.has_ev_charging
           THEN 'EV charging available' END,
      CASE WHEN lc.lot_tier = 0
           THEN 'Always free lot' END
    ], NULL)
  FROM lot_costs lc
  ORDER BY score DESC;
END;
$$;
