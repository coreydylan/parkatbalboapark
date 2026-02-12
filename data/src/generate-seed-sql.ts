/**
 * @deprecated This script generates seed SQL from data/raw/ JSON files.
 * The JSON files are NO LONGER the source of truth — Supabase migrations are.
 * See data/raw/DEPRECATED.md for details.
 *
 * The generated seed.sql uses ON CONFLICT DO NOTHING, so re-running it will
 * NOT update existing data in Supabase. To update data, write a new migration
 * in supabase/migrations/ instead.
 */
import { readFileSync, writeFileSync, mkdirSync } from "fs";
import { join } from "path";

const rawDir = join(__dirname, "..", "raw");
const genDir = join(__dirname, "..", "generated");
const outDir = join(__dirname, "..", "..", "supabase", "seed");

interface Lot {
  slug: string;
  name: string;
  displayName: string;
  address: string;
  lat: number;
  lng: number;
  capacity: number;
  hasEvCharging: boolean;
  hasAdaSpaces: boolean;
  hasTramStop: boolean;
  notes: string;
  tierHistory: { tier: number; effectiveDate: string; endDate: string | null }[];
  specialRules?: {
    description: string;
    freeMinutes: number;
    effectiveDate: string;
    endDate: string | null;
  }[];
  geocoded?: { lat: number; lng: number };
}

interface Destination {
  slug: string;
  name: string;
  displayName: string;
  area: string;
  type: string;
  address: string;
  lat: number;
  lng: number;
  websiteUrl: string;
  geocoded?: { lat: number; lng: number };
}

interface PricingRule {
  tier: number;
  userType: string;
  durationType: string;
  rateCents: number;
  maxDailyCents: number;
  notes?: string;
}

interface PricingRules {
  effectiveDate: string;
  enforcementHours?: { start: string; end: string };
  rules: PricingRule[];
  postMarch2: {
    effectiveDate: string;
    changes: string;
    enforcementHours?: { start: string; end: string };
    adaRules?: PricingRule[];
    residentPricingChanges?: PricingRule[];
  };
}

interface Holiday {
  name: string;
  date: string;
  isRecurring: boolean;
}

interface TramData {
  stops: {
    name: string;
    lotSlug: string | null;
    lat: number;
    lng: number;
    stopOrder: number;
  }[];
  schedule: {
    startTime: string;
    endTime: string;
    frequencyMinutes: number;
    daysOfWeek: number[];
    effectiveDate: string;
    endDate: string | null;
  };
  notes: string;
}

interface PaymentMethod {
  lotSlug: string;
  methods: string[];
}

interface DistanceEntry {
  lotSlug: string;
  destinationSlug: string;
  walkingDistanceMeters: number;
  walkingTimeSeconds: number;
}

function esc(val: string): string {
  return val.replace(/'/g, "''");
}

function sqlBool(val: boolean): string {
  return val ? "true" : "false";
}

function sqlNull(val: string | null): string {
  return val === null ? "NULL" : `'${esc(val)}'`;
}

function readJSON<T>(path: string): T {
  return JSON.parse(readFileSync(path, "utf-8"));
}

function main() {
  mkdirSync(outDir, { recursive: true });

  // Load raw data
  const lots = readJSON<Lot[]>(join(rawDir, "lots.json"));
  const destinations = readJSON<Destination[]>(join(rawDir, "destinations.json"));
  const pricing = readJSON<PricingRules>(join(rawDir, "pricing-rules.json"));
  const holidays = readJSON<Holiday[]>(join(rawDir, "holidays.json"));
  const tramData = readJSON<TramData>(join(rawDir, "tram-data.json"));
  const paymentMethods = readJSON<PaymentMethod[]>(join(rawDir, "payment-methods.json"));

  // Try to load generated data (may not exist yet)
  let geocodedLots: Lot[] | null = null;
  let geocodedDests: Destination[] | null = null;
  let distances: DistanceEntry[] | null = null;

  try {
    geocodedLots = readJSON<Lot[]>(join(genDir, "lots-geocoded.json"));
    console.log(`Loaded ${geocodedLots.length} geocoded lots`);
  } catch {
    console.warn("No geocoded lots found, using raw coordinates");
  }

  try {
    geocodedDests = readJSON<Destination[]>(join(genDir, "destinations-geocoded.json"));
    console.log(`Loaded ${geocodedDests.length} geocoded destinations`);
  } catch {
    console.warn("No geocoded destinations found, using raw coordinates");
  }

  try {
    distances = readJSON<DistanceEntry[]>(join(genDir, "distances.json"));
    console.log(`Loaded ${distances.length} distance entries`);
  } catch {
    console.warn("No distance data found, skipping lot_destination_distances");
  }

  const lines: string[] = [];

  lines.push("-- =============================================================");
  lines.push("-- Park at Balboa Park - Seed Data");
  lines.push(`-- Generated: ${new Date().toISOString()}`);
  lines.push("-- =============================================================");
  lines.push("");

  // --- Parking Lots ---
  lines.push("-- Parking Lots");
  lines.push("-- =============================================================");
  for (const lot of lots) {
    const geoLot = geocodedLots?.find((g) => g.slug === lot.slug);
    const lat = geoLot?.geocoded?.lat ?? lot.lat;
    const lng = geoLot?.geocoded?.lng ?? lot.lng;

    lines.push(`INSERT INTO parking_lots (slug, name, display_name, address, lat, lng, capacity, has_ev_charging, has_ada_spaces, has_tram_stop, notes)`);
    lines.push(`VALUES ('${esc(lot.slug)}', '${esc(lot.name)}', '${esc(lot.displayName)}', '${esc(lot.address)}', ${lat}, ${lng}, ${lot.capacity}, ${sqlBool(lot.hasEvCharging)}, ${sqlBool(lot.hasAdaSpaces)}, ${sqlBool(lot.hasTramStop)}, '${esc(lot.notes)}')`);
    lines.push(`ON CONFLICT (slug) DO NOTHING;`);
    lines.push("");
  }

  // --- Lot Tier Assignments ---
  lines.push("-- Lot Tier Assignments");
  lines.push("-- =============================================================");
  for (const lot of lots) {
    for (const th of lot.tierHistory) {
      lines.push(`INSERT INTO lot_tier_assignments (lot_id, tier, effective_date, end_date)`);
      lines.push(`VALUES ((SELECT id FROM parking_lots WHERE slug = '${esc(lot.slug)}'), ${th.tier}, '${th.effectiveDate}', ${sqlNull(th.endDate)})`);
      lines.push(`ON CONFLICT (lot_id, effective_date) DO NOTHING;`);
      lines.push("");
    }
  }

  // --- Destinations ---
  lines.push("-- Destinations");
  lines.push("-- =============================================================");
  for (const dest of destinations) {
    const geoDest = geocodedDests?.find((g) => g.slug === dest.slug);
    const lat = geoDest?.geocoded?.lat ?? dest.lat;
    const lng = geoDest?.geocoded?.lng ?? dest.lng;

    lines.push(`INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)`);
    lines.push(`VALUES ('${esc(dest.slug)}', '${esc(dest.name)}', '${esc(dest.displayName)}', '${esc(dest.area)}', '${esc(dest.type)}', '${esc(dest.address)}', ${lat}, ${lng}, '${esc(dest.websiteUrl)}')`);
    lines.push(`ON CONFLICT (slug) DO NOTHING;`);
    lines.push("");
  }

  // --- Pricing Rules ---
  lines.push("-- Pricing Rules");
  lines.push("-- =============================================================");

  // Check which rules get replaced by postMarch2 changes (need end_date)
  const postMarch2ResidentTiers = new Set<number>();
  for (const r of pricing.postMarch2.residentPricingChanges ?? []) {
    if (r.userType === 'resident') postMarch2ResidentTiers.add(r.tier);
  }

  for (const rule of pricing.rules) {
    // Resident rules at tiers that change on March 2 get an end_date
    const needsEndDate =
      rule.userType === 'resident' &&
      rule.rateCents > 0 &&
      postMarch2ResidentTiers.has(rule.tier);
    const endDate = needsEndDate ? `'2026-03-01'` : 'NULL';

    lines.push(`INSERT INTO pricing_rules (tier, user_type, duration_type, rate_cents, max_daily_cents, effective_date, end_date)`);
    lines.push(`VALUES (${rule.tier}, '${esc(rule.userType)}', '${esc(rule.durationType)}', ${rule.rateCents}, ${rule.maxDailyCents}, '${pricing.effectiveDate}', ${endDate})`);
    lines.push(`ON CONFLICT DO NOTHING;`);
    lines.push("");
  }

  // Post-March 2 ADA rules
  if (pricing.postMarch2.adaRules) {
    lines.push("-- Post-March 2 ADA pricing updates");
    for (const rule of pricing.postMarch2.adaRules) {
      lines.push(`INSERT INTO pricing_rules (tier, user_type, duration_type, rate_cents, max_daily_cents, effective_date)`);
      lines.push(`VALUES (${rule.tier}, '${esc(rule.userType)}', '${esc(rule.durationType)}', ${rule.rateCents}, ${rule.maxDailyCents}, '${pricing.postMarch2.effectiveDate}')`);
      lines.push(`ON CONFLICT DO NOTHING;`);
      lines.push("");
    }
  }

  // Post-March 2 resident pricing changes
  if (pricing.postMarch2.residentPricingChanges) {
    lines.push("-- Post-March 2 resident pricing changes (free for verified residents)");
    for (const rule of pricing.postMarch2.residentPricingChanges) {
      lines.push(`INSERT INTO pricing_rules (tier, user_type, duration_type, rate_cents, max_daily_cents, effective_date)`);
      lines.push(`VALUES (${rule.tier}, '${esc(rule.userType)}', '${esc(rule.durationType)}', ${rule.rateCents}, ${rule.maxDailyCents}, '${pricing.postMarch2.effectiveDate}')`);
      lines.push(`ON CONFLICT DO NOTHING;`);
      lines.push("");
    }
  }

  // --- Holidays ---
  lines.push("-- Holidays");
  lines.push("-- =============================================================");
  for (const h of holidays) {
    lines.push(`INSERT INTO holidays (name, date, is_recurring)`);
    lines.push(`VALUES ('${esc(h.name)}', '${h.date}', ${sqlBool(h.isRecurring)})`);
    lines.push(`ON CONFLICT DO NOTHING;`);
    lines.push("");
  }

  // --- Enforcement Periods ---
  lines.push("-- Enforcement Periods");
  lines.push("-- =============================================================");
  const enfStart = pricing.enforcementHours?.start ?? '08:00';
  const enfEnd = pricing.enforcementHours?.end ?? '20:00';
  const hasPostMarch2Enf = pricing.postMarch2?.enforcementHours;

  if (hasPostMarch2Enf) {
    // Current period ends day before March 2
    const endDate = '2026-03-01';
    lines.push(`INSERT INTO enforcement_periods (start_time, end_time, days_of_week, effective_date, end_date)`);
    lines.push(`VALUES ('${enfStart}', '${enfEnd}', ARRAY[0,1,2,3,4,5,6], '${pricing.effectiveDate}', '${endDate}')`);
    lines.push(`ON CONFLICT DO NOTHING;`);
    lines.push("");
    // New period starting March 2
    lines.push(`INSERT INTO enforcement_periods (start_time, end_time, days_of_week, effective_date, end_date)`);
    lines.push(`VALUES ('${hasPostMarch2Enf.start}', '${hasPostMarch2Enf.end}', ARRAY[0,1,2,3,4,5,6], '${pricing.postMarch2.effectiveDate}', NULL)`);
    lines.push(`ON CONFLICT DO NOTHING;`);
    lines.push("");
  } else {
    lines.push(`INSERT INTO enforcement_periods (start_time, end_time, days_of_week, effective_date, end_date)`);
    lines.push(`VALUES ('${enfStart}', '${enfEnd}', ARRAY[0,1,2,3,4,5,6], '${pricing.effectiveDate}', NULL)`);
    lines.push(`ON CONFLICT DO NOTHING;`);
    lines.push("");
  }

  // --- Tram Stops ---
  lines.push("-- Tram Stops");
  lines.push("-- =============================================================");
  for (const stop of tramData.stops) {
    const lotIdExpr = stop.lotSlug
      ? `(SELECT id FROM parking_lots WHERE slug = '${esc(stop.lotSlug)}')`
      : "NULL";
    lines.push(`INSERT INTO tram_stops (name, lot_id, lat, lng, stop_order)`);
    lines.push(`VALUES ('${esc(stop.name)}', ${lotIdExpr}, ${stop.lat}, ${stop.lng}, ${stop.stopOrder})`);
    lines.push(`ON CONFLICT DO NOTHING;`);
    lines.push("");
  }

  // --- Tram Schedule ---
  lines.push("-- Tram Schedule");
  lines.push("-- =============================================================");
  lines.push(`INSERT INTO tram_schedule (start_time, end_time, frequency_minutes, days_of_week, effective_date, end_date)`);
  lines.push(`VALUES ('${tramData.schedule.startTime}', '${tramData.schedule.endTime}', ${tramData.schedule.frequencyMinutes}, ARRAY[${tramData.schedule.daysOfWeek.join(",")}], '${tramData.schedule.effectiveDate}', ${sqlNull(tramData.schedule.endDate)})`);
  lines.push(`ON CONFLICT DO NOTHING;`);
  lines.push("");

  // --- Payment Methods ---
  lines.push("-- Payment Methods");
  lines.push("-- =============================================================");
  for (const pm of paymentMethods) {
    for (const method of pm.methods) {
      lines.push(`INSERT INTO payment_methods (lot_id, method)`);
      lines.push(`VALUES ((SELECT id FROM parking_lots WHERE slug = '${esc(pm.lotSlug)}'), '${esc(method)}')`);
      lines.push(`ON CONFLICT (lot_id, method) DO NOTHING;`);
      lines.push("");
    }
  }

  // --- Lot-Destination Distances ---
  if (distances && distances.length > 0) {
    lines.push("-- Lot-Destination Walking Distances");
    lines.push("-- =============================================================");
    for (const d of distances) {
      lines.push(`INSERT INTO lot_destination_distances (lot_id, destination_id, walking_distance_meters, walking_time_seconds)`);
      lines.push(`VALUES ((SELECT id FROM parking_lots WHERE slug = '${esc(d.lotSlug)}'), (SELECT id FROM destinations WHERE slug = '${esc(d.destinationSlug)}'), ${d.walkingDistanceMeters}, ${d.walkingTimeSeconds})`);
      lines.push(`ON CONFLICT (lot_id, destination_id) DO UPDATE SET walking_distance_meters = EXCLUDED.walking_distance_meters, walking_time_seconds = EXCLUDED.walking_time_seconds;`);
      lines.push("");
    }
  }

  const outPath = join(outDir, "seed.sql");
  writeFileSync(outPath, lines.join("\n"));
  console.log(`\nWrote seed SQL to ${outPath} (${lines.length} lines)`);
}

main();
