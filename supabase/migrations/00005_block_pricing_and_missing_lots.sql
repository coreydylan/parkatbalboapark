-- 00005_block_pricing_and_missing_lots.sql
-- Corrects pricing model from hourly to block-based for tier 1,
-- adds 7 missing parking lots identified by research sweep,
-- and updates compute_lot_cost to handle block pricing.

-- ============================================================================
-- 1. Add 'block' to pricing_rules duration_type constraint
-- ============================================================================
ALTER TABLE pricing_rules DROP CONSTRAINT IF EXISTS pricing_rules_duration_type_check;
ALTER TABLE pricing_rules ADD CONSTRAINT pricing_rules_duration_type_check
  CHECK (duration_type = ANY (ARRAY['hourly','daily','event','block']));

-- ============================================================================
-- 2. Update tier 1 pricing to block-based (flat rate ≤4hrs, max_daily >4hrs)
-- ============================================================================
-- Nonresident tier 1: $10/block, $16 max
UPDATE pricing_rules
SET duration_type = 'block', rate_cents = 1000, max_daily_cents = 1600
WHERE tier = 1 AND user_type = 'nonresident';

-- Resident tier 1: $5/block, $8 max
UPDATE pricing_rules
SET duration_type = 'block', rate_cents = 500, max_daily_cents = 800
WHERE tier = 1 AND user_type = 'resident';

-- ============================================================================
-- 3. Add 7 missing lots from research sweep
-- ============================================================================
INSERT INTO parking_lots (name, slug, display_name, lat, lng, capacity, has_ada_spaces)
VALUES
  ('Space Theater', 'space-theater', 'Space Theater Lot', 32.7313, -117.1494, 120, true),
  ('Casa de Balboa', 'casa-de-balboa', 'Casa de Balboa Lot', 32.7307, -117.1501, 80, true),
  ('Palisades', 'palisades', 'Palisades Lot', 32.7339, -117.1537, 150, true),
  ('Bea Evenson', 'bea-evenson', 'Bea Evenson Lot', 32.7320, -117.1505, 100, true),
  ('South Carousel', 'south-carousel', 'South Carousel Lot', 32.7318, -117.1516, 90, true),
  ('Pepper Grove', 'pepper-grove', 'Pepper Grove Lot', 32.7335, -117.1503, 100, true),
  ('Marston Point', 'marston-point', 'Marston Point Lot', 32.7348, -117.1524, 80, true);

-- ============================================================================
-- 4. Assign tiers to new lots
-- ============================================================================
INSERT INTO lot_tier_assignments (lot_id, tier, effective_date)
SELECT id, 1, '2026-01-05'::date FROM parking_lots WHERE slug = 'space-theater'
UNION ALL
SELECT id, 1, '2026-01-05'::date FROM parking_lots WHERE slug = 'casa-de-balboa'
UNION ALL
SELECT id, 1, '2026-01-05'::date FROM parking_lots WHERE slug = 'palisades'
UNION ALL
SELECT id, 1, '2026-01-05'::date FROM parking_lots WHERE slug = 'bea-evenson'
UNION ALL
SELECT id, 1, '2026-01-05'::date FROM parking_lots WHERE slug = 'south-carousel'
UNION ALL
SELECT id, 2, '2026-01-05'::date FROM parking_lots WHERE slug = 'pepper-grove'
UNION ALL
SELECT id, 2, '2026-01-05'::date FROM parking_lots WHERE slug = 'marston-point';

-- ============================================================================
-- 5. Update compute_lot_cost to handle block pricing
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

  -- Residents free at tier 2/3 (via pricing rule end_date; after March 2 handled by $0 rule)
  IF p_user_type = 'resident' AND p_tier IN (2, 3) THEN
    -- Check if there's an active paid rule; if not, free
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
