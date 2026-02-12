-- 00008_verified_resident_and_data_fixes.sql
-- Comprehensive data sync: lot cleanup, tier reclassification, pricing fixes,
-- enforcement hours, pass prices, holidays, and compute_lot_cost update.

-- ============================================================================
-- 1. DELETE DUPLICATE LOTS
-- Research found war-memorial, balboa-park-activity-center, municipal-gym
-- don't exist as distinct named lots — they were erroneous entries.
-- ============================================================================

-- Clean up FK references first
DELETE FROM lot_destination_distances WHERE lot_id IN (
  SELECT id FROM parking_lots WHERE slug IN (
    'war-memorial', 'balboa-park-activity-center', 'municipal-gym'
  )
);
DELETE FROM payment_methods WHERE lot_id IN (
  SELECT id FROM parking_lots WHERE slug IN (
    'war-memorial', 'balboa-park-activity-center', 'municipal-gym'
  )
);
DELETE FROM lot_tier_assignments WHERE lot_id IN (
  SELECT id FROM parking_lots WHERE slug IN (
    'war-memorial', 'balboa-park-activity-center', 'municipal-gym'
  )
);
DELETE FROM parking_lots WHERE slug IN (
  'war-memorial', 'balboa-park-activity-center', 'municipal-gym'
);

-- ============================================================================
-- 2. MERGE pan-american-plaza → palisades
-- City renamed this lot. Migration 00005 added a separate 'palisades' entry.
-- Keep 'palisades', transfer references, delete 'pan-american-plaza'.
-- ============================================================================

-- Transfer distances from pan-american-plaza to palisades
UPDATE lot_destination_distances
SET lot_id = (SELECT id FROM parking_lots WHERE slug = 'palisades')
WHERE lot_id = (SELECT id FROM parking_lots WHERE slug = 'pan-american-plaza')
  AND NOT EXISTS (
    SELECT 1 FROM lot_destination_distances
    WHERE lot_id = (SELECT id FROM parking_lots WHERE slug = 'palisades')
      AND destination_id = lot_destination_distances.destination_id
  );

-- Transfer payment methods
UPDATE payment_methods
SET lot_id = (SELECT id FROM parking_lots WHERE slug = 'palisades')
WHERE lot_id = (SELECT id FROM parking_lots WHERE slug = 'pan-american-plaza')
  AND NOT EXISTS (
    SELECT 1 FROM payment_methods
    WHERE lot_id = (SELECT id FROM parking_lots WHERE slug = 'palisades')
      AND method = payment_methods.method
  );

-- Clean up remaining pan-american-plaza references
DELETE FROM lot_destination_distances
WHERE lot_id = (SELECT id FROM parking_lots WHERE slug = 'pan-american-plaza');
DELETE FROM payment_methods
WHERE lot_id = (SELECT id FROM parking_lots WHERE slug = 'pan-american-plaza');
DELETE FROM lot_tier_assignments
WHERE lot_id = (SELECT id FROM parking_lots WHERE slug = 'pan-american-plaza');
DELETE FROM parking_lots WHERE slug = 'pan-american-plaza';

-- ============================================================================
-- 3. FIX TIER ASSIGNMENTS
-- ============================================================================

-- inspiration-point-upper: tier 1 → tier 2 (research confirmed it's Level 2)
UPDATE lot_tier_assignments
SET tier = 2
WHERE lot_id = (SELECT id FROM parking_lots WHERE slug = 'inspiration-point-upper')
  AND tier = 1;

-- inspiration-point-lower: tier 1 → tier 3 (economy lot, first 3hrs free)
UPDATE lot_tier_assignments
SET tier = 3
WHERE lot_id = (SELECT id FROM parking_lots WHERE slug = 'inspiration-point-lower')
  AND tier = 1;

-- morley-field: tier 2 → tier 0 (free, outside paid zone)
DELETE FROM lot_tier_assignments
WHERE lot_id = (SELECT id FROM parking_lots WHERE slug = 'morley-field');
INSERT INTO lot_tier_assignments (lot_id, tier, effective_date)
SELECT id, 0, '2026-01-05'::date FROM parking_lots WHERE slug = 'morley-field';

-- gold-gulch: tier 2 → tier 0 (free, outside paid zone)
DELETE FROM lot_tier_assignments
WHERE lot_id = (SELECT id FROM parking_lots WHERE slug = 'gold-gulch');
INSERT INTO lot_tier_assignments (lot_id, tier, effective_date)
SELECT id, 0, '2026-01-05'::date FROM parking_lots WHERE slug = 'gold-gulch';

-- presidents-way: tier 2 → tier 0 (free, outside paid zone)
DELETE FROM lot_tier_assignments
WHERE lot_id = (SELECT id FROM parking_lots WHERE slug = 'presidents-way');
INSERT INTO lot_tier_assignments (lot_id, tier, effective_date)
SELECT id, 0, '2026-01-05'::date FROM parking_lots WHERE slug = 'presidents-way';

-- federal-building: remove incorrect tier 0 transition, keep tier 2 permanent
DELETE FROM lot_tier_assignments
WHERE lot_id = (SELECT id FROM parking_lots WHERE slug = 'federal-building')
  AND tier = 0;
UPDATE lot_tier_assignments
SET end_date = NULL
WHERE lot_id = (SELECT id FROM parking_lots WHERE slug = 'federal-building')
  AND tier = 2;

-- palisades: tier 1 → tier 2 on March 2 (free for verified residents)
UPDATE lot_tier_assignments
SET end_date = '2026-03-01'::date
WHERE tier = 1
  AND lot_id = (SELECT id FROM parking_lots WHERE slug = 'palisades');
INSERT INTO lot_tier_assignments (lot_id, tier, effective_date)
SELECT id, 2, '2026-03-02'::date FROM parking_lots WHERE slug = 'palisades';

-- bea-evenson: tier 1 → tier 2 on March 2 (free for verified residents)
UPDATE lot_tier_assignments
SET end_date = '2026-03-01'::date
WHERE tier = 1
  AND lot_id = (SELECT id FROM parking_lots WHERE slug = 'bea-evenson');
INSERT INTO lot_tier_assignments (lot_id, tier, effective_date)
SELECT id, 2, '2026-03-02'::date FROM parking_lots WHERE slug = 'bea-evenson';

-- ============================================================================
-- 4. UPDATE LOT METADATA (capacities, notes)
-- ============================================================================

UPDATE parking_lots SET capacity = 9,
  notes = 'Tiny building-frontage parking area in front of Centro Cultural de la Raza. Free and outside the paid parking zone. Very limited spaces.'
WHERE slug = 'centro-cultural';

UPDATE parking_lots SET capacity = 30,
  notes = 'Small parking area along Presidents Way near Park Blvd intersection. Free and outside the named paid lot system.'
WHERE slug = 'presidents-way';

UPDATE parking_lots SET capacity = 40, has_ada_spaces = false,
  notes = 'Small informal lot in canyon between Organ Pavilion and Zoo. Used as overflow parking and tram staging area. Free and outside the paid parking zone.'
WHERE slug = 'gold-gulch';

UPDATE parking_lots SET
  notes = 'Free parking serving Morley Field Sports Complex (disc golf, tennis, pool, dog park). Located in northeast section of the park, outside the paid parking zone.'
WHERE slug = 'morley-field';

UPDATE parking_lots SET
  notes = 'Large lot at east end of park. Free tram stop available for shuttle to central attractions. Near Veterans Museum. Becomes free for verified city residents March 2, 2026.'
WHERE slug = 'inspiration-point-upper';

UPDATE parking_lots SET
  notes = 'First 3 hours free for all visitors. Adjacent to upper lot tram stop. Becomes free for verified city residents March 2, 2026.'
WHERE slug = 'inspiration-point-lower';

UPDATE parking_lots SET
  notes = 'Smaller lot near Federal Building. Becomes free for verified city residents March 2, 2026.'
WHERE slug = 'federal-building';

-- ============================================================================
-- 5. FIX PRICING RULES
-- ============================================================================

-- Tier 2/3 resident: $0 → $5/day with end_date March 1 (free after March 2)
UPDATE pricing_rules
SET rate_cents = 500, max_daily_cents = 500, end_date = '2026-03-01'::date
WHERE tier IN (2, 3) AND user_type = 'resident' AND rate_cents = 0
  AND effective_date = '2026-01-05'::date;

-- Insert free resident tier 2/3 rules effective March 2
INSERT INTO pricing_rules (tier, user_type, duration_type, rate_cents, max_daily_cents, effective_date)
VALUES
  (2, 'resident', 'daily', 0, 0, '2026-03-02'),
  (3, 'resident', 'daily', 0, 0, '2026-03-02');

-- ADA tier 1: research confirmed free at all tiers since launch
UPDATE pricing_rules
SET rate_cents = 0, max_daily_cents = 0
WHERE user_type = 'ada' AND rate_cents > 0;

-- ============================================================================
-- 6. ENFORCEMENT HOURS: 8am-8pm → 8am-6pm on March 2
-- ============================================================================

UPDATE enforcement_periods
SET end_time = '20:00', end_date = '2026-03-01'::date
WHERE end_date IS NULL;

INSERT INTO enforcement_periods (start_time, end_time, days_of_week, effective_date)
VALUES ('08:00', '18:00', ARRAY[0,1,2,3,4,5,6], '2026-03-02');

-- ============================================================================
-- 7. PARKING PASS PRICES
-- ============================================================================

DELETE FROM parking_passes;

INSERT INTO parking_passes (name, type, price_cents, user_type, effective_date) VALUES
  ('Monthly Resident Pass',       'monthly',    3000, 'resident',    '2026-01-05'),
  ('Quarterly Resident Pass',     'quarterly',  6000, 'resident',    '2026-01-05'),
  ('Annual Resident Pass',        'annual',    15000, 'resident',    '2026-01-05'),
  ('Monthly Non-Resident Pass',   'monthly',    4000, 'nonresident', '2026-01-05'),
  ('Quarterly Non-Resident Pass', 'quarterly', 12000, 'nonresident', '2026-01-05'),
  ('Annual Non-Resident Pass',    'annual',    30000, 'nonresident', '2026-01-05');

-- ============================================================================
-- 8. HOLIDAYS
-- ============================================================================

-- Add MLK Day (if not already present)
INSERT INTO holidays (name, date, is_recurring)
SELECT 'Martin Luther King Jr. Day', '2026-01-19', false
WHERE NOT EXISTS (SELECT 1 FROM holidays WHERE name LIKE '%Martin Luther King%');

-- Remove Christmas Eve (if present — not a free parking holiday)
DELETE FROM holidays WHERE name LIKE '%Christmas Eve%';

-- ============================================================================
-- 9. CANCEL OVERLAPPING SLATED CHANGES
-- The migration applies these fixes directly; cancel any pending/confirmed
-- slated changes that would conflict.
-- ============================================================================

UPDATE slated_changes
SET status = 'cancelled', updated_at = now()
WHERE status IN ('pending', 'confirmed')
  AND target_table IN ('lot_tier_assignments', 'enforcement_periods', 'pricing_rules')
  AND effective_date = '2026-03-02'::date;

-- ============================================================================
-- 10. UPDATE compute_lot_cost
-- ADA: free everywhere always (research confirmed).
-- Residents at tier 2/3: free when no active paid rule.
-- ============================================================================

CREATE OR REPLACE FUNCTION compute_lot_cost(
  p_tier SMALLINT,
  p_lot_slug TEXT,
  p_user_type TEXT,
  p_has_pass BOOLEAN,
  p_visit_hours NUMERIC,
  p_enforced BOOLEAN,
  p_query_date DATE
) RETURNS INTEGER AS $function$
DECLARE
  v_rule RECORD;
BEGIN
  -- Not enforced or has a parking pass -> free
  IF NOT p_enforced OR p_has_pass THEN RETURN 0; END IF;

  -- Free tier (tier 0) is always free
  IF p_tier = 0 THEN RETURN 0; END IF;

  -- ADA: free everywhere (official policy since launch)
  IF p_user_type = 'ada' THEN RETURN 0; END IF;

  -- Inspiration Point Lower: first 3 hours free
  IF p_lot_slug = 'inspiration-point-lower' AND p_visit_hours <= 3 THEN RETURN 0; END IF;

  -- Staff/volunteer free at tier 2/3
  IF p_user_type IN ('staff', 'volunteer') AND p_tier IN (2, 3) THEN RETURN 0; END IF;

  -- Residents free at tier 2/3 when no active paid rule
  IF p_user_type = 'resident' AND p_tier IN (2, 3) THEN
    SELECT pr.rate_cents INTO v_rule
    FROM pricing_rules pr
    WHERE pr.tier = p_tier AND pr.user_type = 'resident'
      AND p_query_date BETWEEN pr.effective_date AND COALESCE(pr.end_date, '9999-12-31'::date)
    ORDER BY pr.effective_date DESC LIMIT 1;
    IF v_rule IS NULL OR v_rule.rate_cents = 0 THEN RETURN 0; END IF;
  END IF;

  -- Look up pricing rule
  SELECT pr.duration_type, pr.rate_cents, pr.max_daily_cents
  INTO v_rule
  FROM pricing_rules pr
  WHERE pr.tier = p_tier AND pr.user_type = p_user_type
    AND p_query_date BETWEEN pr.effective_date AND COALESCE(pr.end_date, '9999-12-31'::date)
  ORDER BY pr.effective_date DESC
  LIMIT 1;

  IF v_rule IS NULL THEN RETURN 0; END IF;

  -- Block pricing: flat rate for up to 4 hours, max_daily for longer visits
  IF v_rule.duration_type = 'block' THEN
    IF p_visit_hours <= 4 THEN
      RETURN v_rule.rate_cents;
    ELSE
      RETURN COALESCE(v_rule.max_daily_cents, v_rule.rate_cents);
    END IF;
  -- Daily pricing: flat rate regardless of hours
  ELSIF v_rule.duration_type = 'daily' THEN
    RETURN v_rule.rate_cents;
  -- Hourly pricing: rate * hours capped at daily max
  ELSE
    RETURN LEAST(
      v_rule.rate_cents * CEIL(p_visit_hours)::integer,
      COALESCE(v_rule.max_daily_cents, v_rule.rate_cents * CEIL(p_visit_hours)::integer)
    );
  END IF;
END;
$function$ LANGUAGE plpgsql STABLE;
