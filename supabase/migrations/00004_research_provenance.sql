-- 00004_research_provenance.sql
-- Research provenance system: trusted domains, rule sources, submission queue, slated changes
-- Enables agent-powered verification of parking rules against official sources.

-- ============================================================================
-- TABLES
-- ============================================================================

-- 1. trusted_domains — domains that trigger auto-confirmation of submissions
CREATE TABLE trusted_domains (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  domain           text UNIQUE NOT NULL,
  match_subdomains boolean NOT NULL DEFAULT true,
  notes            text,
  created_at       timestamptz DEFAULT now()
);

INSERT INTO trusted_domains (domain, match_subdomains, notes) VALUES
  ('sandiego.gov',   true, 'City of San Diego official domain'),
  ('balboapark.org', true, 'Balboa Park Conservancy official domain'),
  ('bfrsd.org',      true, 'Balboa Park Facilities & Reservation Services District');

-- 2. rule_sources — provenance log for every verified rule
CREATE TABLE rule_sources (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  target_table  text NOT NULL CHECK (target_table IN (
    'pricing_rules', 'lot_tier_assignments', 'enforcement_periods', 'holidays'
  )),
  target_id     uuid NOT NULL,
  source_url    text NOT NULL,
  source_domain text GENERATED ALWAYS AS (
    regexp_replace(regexp_replace(source_url, '^https?://', ''), '/.*$', '')
  ) STORED,
  source_title  text,
  excerpt       text,
  agent_id      text,
  verified_at   timestamptz NOT NULL DEFAULT now(),
  status        text NOT NULL DEFAULT 'confirmed' CHECK (status IN ('confirmed', 'disputed', 'stale')),
  created_at    timestamptz DEFAULT now()
);

CREATE INDEX idx_rule_sources_target ON rule_sources (target_table, target_id);
CREATE INDEX idx_rule_sources_domain ON rule_sources (source_domain);

-- 3. research_submissions — agent submission queue
CREATE TABLE research_submissions (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  action         text NOT NULL CHECK (action IN ('create', 'update', 'confirm', 'delete')),
  target_table   text NOT NULL CHECK (target_table IN (
    'pricing_rules', 'lot_tier_assignments', 'enforcement_periods', 'holidays'
  )),
  target_id      uuid,
  proposed_data  jsonb,
  source_url     text NOT NULL,
  source_domain  text GENERATED ALWAYS AS (
    regexp_replace(regexp_replace(source_url, '^https?://', ''), '/.*$', '')
  ) STORED,
  source_title   text,
  excerpt        text,
  agent_id       text,
  agent_task_ref text,
  status         text NOT NULL DEFAULT 'pending' CHECK (status IN (
    'pending', 'auto_confirmed', 'manually_confirmed', 'rejected', 'applied'
  )),
  created_at     timestamptz DEFAULT now(),
  updated_at     timestamptz DEFAULT now()
);

CREATE INDEX idx_research_submissions_status ON research_submissions (status);
CREATE INDEX idx_research_submissions_target ON research_submissions (target_table, target_id);

-- 4. slated_changes — future announced changes not yet in effect
CREATE TABLE slated_changes (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  target_table    text NOT NULL CHECK (target_table IN (
    'pricing_rules', 'lot_tier_assignments', 'enforcement_periods', 'holidays'
  )),
  target_id       uuid,
  action          text NOT NULL CHECK (action IN ('create', 'update', 'delete')),
  change_data     jsonb NOT NULL,
  effective_date  date NOT NULL,
  description     text NOT NULL,
  source_url      text,
  source_title    text,
  excerpt         text,
  status          text NOT NULL DEFAULT 'pending' CHECK (status IN (
    'pending', 'confirmed', 'promoted', 'cancelled'
  )),
  created_at      timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now()
);

CREATE INDEX idx_slated_changes_status_date ON slated_changes (status, effective_date);

-- ============================================================================
-- AUTO-CONFIRM TRIGGER
-- ============================================================================

CREATE OR REPLACE FUNCTION auto_confirm_submission()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_domain text;
BEGIN
  -- Extract domain from source_url (strip protocol and path)
  v_domain := regexp_replace(regexp_replace(NEW.source_url, '^https?://', ''), '/.*$', '');

  -- Check against trusted_domains (exact match or subdomain match)
  IF EXISTS (
    SELECT 1 FROM trusted_domains td
    WHERE v_domain = td.domain
       OR (td.match_subdomains AND v_domain LIKE '%.' || td.domain)
  ) THEN
    NEW.status := 'auto_confirmed';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_auto_confirm_submission
  BEFORE INSERT ON research_submissions
  FOR EACH ROW EXECUTE FUNCTION auto_confirm_submission();

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE trusted_domains ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access" ON trusted_domains FOR SELECT USING (true);
CREATE POLICY "Service role write" ON trusted_domains FOR ALL USING (auth.role() = 'service_role');

ALTER TABLE rule_sources ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access" ON rule_sources FOR SELECT USING (true);
CREATE POLICY "Service role write" ON rule_sources FOR ALL USING (auth.role() = 'service_role');

ALTER TABLE research_submissions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access" ON research_submissions FOR SELECT USING (true);
CREATE POLICY "Service role write" ON research_submissions FOR ALL USING (auth.role() = 'service_role');

ALTER TABLE slated_changes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access" ON slated_changes FOR SELECT USING (true);
CREATE POLICY "Service role write" ON slated_changes FOR ALL USING (auth.role() = 'service_role');
