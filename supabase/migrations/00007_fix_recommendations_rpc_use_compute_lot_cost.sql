-- 00007_fix_recommendations_rpc_use_compute_lot_cost.sql
-- Fix get_parking_recommendations to use compute_lot_cost() instead of
-- inlined hourly-only pricing logic. This fixes the bug where block-priced
-- tier 1 lots showed as free (the old RPC filtered by duration_type = 'hourly'
-- but tier 1 rules were changed to 'block' in migration 00005).

CREATE OR REPLACE FUNCTION get_parking_recommendations(
  p_user_type TEXT DEFAULT 'nonresident',
  p_has_pass BOOLEAN DEFAULT false,
  p_destination_slug TEXT DEFAULT NULL,
  p_query_time TIMESTAMPTZ DEFAULT now(),
  p_visit_hours NUMERIC DEFAULT 2
) RETURNS TABLE (
  lot_slug TEXT,
  lot_name TEXT,
  lot_display_name TEXT,
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  tier SMALLINT,
  cost_cents INTEGER,
  cost_display TEXT,
  is_free BOOLEAN,
  walking_distance_meters INTEGER,
  walking_time_seconds INTEGER,
  walking_time_display TEXT,
  has_tram BOOLEAN,
  tram_time_minutes INTEGER,
  score NUMERIC,
  tips TEXT[]
) LANGUAGE plpgsql STABLE AS $function$
DECLARE
  v_enforced       boolean := false;
  v_query_date     date;
  v_query_time_of_day time;
  v_day_of_week    integer;
  v_is_holiday     boolean := false;
BEGIN
  v_query_date := (p_query_time AT TIME ZONE 'America/Los_Angeles')::date;
  v_query_time_of_day := (p_query_time AT TIME ZONE 'America/Los_Angeles')::time;
  v_day_of_week := EXTRACT(DOW FROM p_query_time AT TIME ZONE 'America/Los_Angeles')::integer;

  -- Check holidays
  SELECT EXISTS (
    SELECT 1 FROM holidays h
    WHERE h.date = v_query_date
       OR (h.is_recurring AND EXTRACT(MONTH FROM h.date) = EXTRACT(MONTH FROM v_query_date)
                           AND EXTRACT(DAY FROM h.date) = EXTRACT(DAY FROM v_query_date))
  ) INTO v_is_holiday;

  -- Check enforcement
  IF NOT v_is_holiday THEN
    SELECT EXISTS (
      SELECT 1 FROM enforcement_periods ep
      WHERE v_query_date BETWEEN ep.effective_date AND COALESCE(ep.end_date, '9999-12-31'::date)
        AND v_query_time_of_day BETWEEN ep.start_time AND ep.end_time
        AND v_day_of_week = ANY(ep.days_of_week)
    ) INTO v_enforced;
  END IF;

  -- Use a CTE to compute cost once per lot via compute_lot_cost()
  RETURN QUERY
  WITH lot_costs AS (
    SELECT
      pl.id AS lot_id,
      pl.slug,
      pl.name AS lot_name_val,
      pl.display_name,
      pl.lat AS lot_lat,
      pl.lng AS lot_lng,
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
      ) AS computed_cost,
      ldd.walking_distance_meters AS walk_dist,
      ldd.walking_time_seconds AS walk_time
    FROM parking_lots pl
    LEFT JOIN lot_tier_assignments lta ON lta.lot_id = pl.id
      AND v_query_date BETWEEN lta.effective_date AND COALESCE(lta.end_date, '9999-12-31'::date)
    LEFT JOIN lot_destination_distances ldd ON ldd.lot_id = pl.id
      AND p_destination_slug IS NOT NULL
      AND ldd.destination_id = (SELECT d.id FROM destinations d WHERE d.slug = p_destination_slug LIMIT 1)
  )
  SELECT
    lc.slug,
    lc.lot_name_val,
    lc.display_name,
    lc.lot_lat,
    lc.lot_lng,
    lc.lot_tier,
    lc.computed_cost,
    CASE
      WHEN lc.computed_cost = 0 THEN 'FREE'
      WHEN lc.computed_cost % 100 = 0 THEN '$' || (lc.computed_cost / 100)::text
      ELSE '$' || (lc.computed_cost / 100.0)::numeric(10,2)::text
    END,
    lc.computed_cost = 0,
    lc.walk_dist,
    lc.walk_time,
    CASE
      WHEN lc.walk_time IS NULL THEN NULL
      ELSE CEIL(lc.walk_time / 60.0)::integer::text || ' min walk'
    END,
    lc.has_tram_stop,
    CASE
      WHEN lc.has_tram_stop THEN (
        SELECT (ts.frequency_minutes / 2) + 5
        FROM tram_schedule ts
        WHERE v_query_date BETWEEN ts.effective_date AND COALESCE(ts.end_date, '9999-12-31'::date)
          AND v_query_time_of_day BETWEEN ts.start_time AND ts.end_time
          AND v_day_of_week = ANY(ts.days_of_week)
        ORDER BY ts.effective_date DESC LIMIT 1)
      ELSE NULL
    END,
    ROUND(
      0.40 * (1.0 - lc.computed_cost::numeric / GREATEST((SELECT MAX(lc2.computed_cost) FROM lot_costs lc2), 1))
      + 0.35 * (1.0 - COALESCE(lc.walk_dist::numeric / GREATEST((SELECT MAX(lc2.walk_dist) FROM lot_costs lc2), 1), 0.5))
      + 0.10 * CASE WHEN lc.has_tram_stop THEN 1 ELSE 0 END
      + 0.10 * (1.0 - lc.lot_tier::numeric / 3.0)
      + 0.05 * CASE WHEN lc.has_ada_spaces THEN 1 ELSE 0 END
    , 4),
    ARRAY_REMOVE(ARRAY[
      CASE WHEN lc.slug = 'inspiration-point-lower' AND v_enforced AND p_visit_hours <= 3 THEN 'First 3 hours free' END,
      CASE WHEN NOT v_enforced THEN 'Free parking (outside enforcement hours)' END,
      CASE WHEN v_is_holiday THEN 'Free parking (holiday)' END,
      CASE WHEN p_has_pass AND v_enforced THEN 'Free with parking pass' END,
      CASE WHEN lc.has_tram_stop AND (SELECT (ts2.frequency_minutes / 2) + 5 FROM tram_schedule ts2
        WHERE v_query_date BETWEEN ts2.effective_date AND COALESCE(ts2.end_date, '9999-12-31'::date)
          AND v_query_time_of_day BETWEEN ts2.start_time AND ts2.end_time
          AND v_day_of_week = ANY(ts2.days_of_week) LIMIT 1) IS NOT NULL THEN 'Tram available to destination' END,
      CASE WHEN lc.has_ev_charging THEN 'EV charging available' END,
      CASE WHEN lc.lot_tier = 0 THEN 'Always free lot' END
    ], NULL)
  FROM lot_costs lc
  ORDER BY score DESC;
END;
$function$;
