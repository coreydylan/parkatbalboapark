-- 00006_cleanup_duplicate_ada_and_centro_cultural.sql
-- Cleanup from research sweep findings:
-- 1. Remove duplicate ADA tier 1 rule (Mar 2 entry redundant since Jan 5 already $0)
-- 2. Reclassify Centro Cultural de la Raza from tier 3 → tier 0 (not in official paid program)

-- Delete duplicate ADA tier 1 rule
DELETE FROM pricing_rules WHERE id = '39212e94-bc00-452e-b97f-e28efc5ed0e3';

-- Reclassify Centro Cultural de la Raza
UPDATE lot_tier_assignments
SET tier = 0
WHERE id = '5699e709-eb63-467e-8f18-fc6b625dc370';
