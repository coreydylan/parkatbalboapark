import "dotenv/config";
import { parse } from "csv-parse/sync";
import { createClient } from "@supabase/supabase-js";

// Bounding box around Balboa Park + nearby Uptown meters
const BBOX = {
  latMin: 32.71,
  latMax: 32.75,
  lngMin: -117.175,
  lngMax: -117.135,
};

const ZONE_ALLOWLIST = ["Balboa Park", "Uptown"];

const CSV_URL =
  "https://seshat.datasd.org/parking_meters_locations/parking_meters_current.csv";

interface CsvRow {
  zone: string;
  area: string;
  "sub-area": string;
  pole: string;
  latitude: string;
  longitude: string;
  configid: string;
  configname: string;
  time_start: string;
  time_end: string;
  time_limit: string;
  days_in_operation: string;
  price: string;
  mobile_pay: string;
  multi_space: string;
  restrictions: string;
}

/**
 * Parse price string like "$2.50 HR" → 250 (cents per hour).
 * Returns null if unparseable.
 */
function parsePriceCents(price: string): number | null {
  const match = price.match(/\$(\d+(?:\.\d+)?)/);
  if (!match) return null;
  return Math.round(parseFloat(match[1]!) * 100);
}

function toBool(val: string): boolean {
  return val.trim().toUpperCase() === "Y" || val.trim() === "1" || val.trim().toLowerCase() === "yes";
}

async function main() {
  const supabaseUrl = process.env.SUPABASE_URL;
  const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!supabaseUrl || !supabaseKey) {
    console.error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
    process.exit(1);
  }

  const supabase = createClient(supabaseUrl, supabaseKey);

  // 1. Fetch CSV
  console.log(`Fetching CSV from ${CSV_URL}...`);
  const response = await fetch(CSV_URL);
  if (!response.ok) {
    console.error(`Failed to fetch CSV: ${response.status} ${response.statusText}`);
    process.exit(1);
  }
  const csvText = await response.text();

  // 2. Parse CSV
  const rows: CsvRow[] = parse(csvText, {
    columns: true,
    skip_empty_lines: true,
    trim: true,
  });
  console.log(`Total meters in CSV: ${rows.length}`);

  // 3. Filter by zone allowlist + bounding box
  const filtered = rows.filter((row) => {
    const lat = parseFloat(row.latitude);
    const lng = parseFloat(row.longitude);
    const inBbox =
      lat >= BBOX.latMin &&
      lat <= BBOX.latMax &&
      lng >= BBOX.lngMin &&
      lng <= BBOX.lngMax;
    const inZone = ZONE_ALLOWLIST.includes(row.zone);
    return inBbox && inZone;
  });
  console.log(`Meters after filtering: ${filtered.length}`);

  if (filtered.length === 0) {
    console.warn("No meters matched filters. Exiting without changes.");
    return;
  }

  // 4. Transform to DB rows
  const syncedAt = new Date().toISOString();
  const dbRows = filtered.map((row) => ({
    pole: row.pole,
    zone: row.zone || null,
    area: row.area || null,
    sub_area: row["sub-area"] || null,
    lat: parseFloat(row.latitude) || null,
    lng: parseFloat(row.longitude) || null,
    config_id: parseInt(row.configid, 10) || null,
    config_name: row.configname || null,
    time_start: row.time_start || null,
    time_end: row.time_end || null,
    time_limit: row.time_limit || null,
    days_in_operation: row.days_in_operation || null,
    rate_cents_per_hour: parsePriceCents(row.price),
    mobile_pay: toBool(row.mobile_pay),
    multi_space: toBool(row.multi_space),
    restrictions: row.restrictions || null,
    synced_at: syncedAt,
  }));

  // 5. Upsert in batches (Supabase has a payload size limit)
  const BATCH_SIZE = 200;
  let upserted = 0;

  for (let i = 0; i < dbRows.length; i += BATCH_SIZE) {
    const batch = dbRows.slice(i, i + BATCH_SIZE);
    const { error } = await supabase
      .from("street_meters")
      .upsert(batch, { onConflict: "pole" });

    if (error) {
      console.error(`Upsert error (batch ${i / BATCH_SIZE + 1}):`, error);
      process.exit(1);
    }
    upserted += batch.length;
  }
  console.log(`Upserted: ${upserted}`);

  // 6. Delete stale rows (meters no longer in filtered dataset)
  const { data: deleted, error: deleteError } = await supabase
    .from("street_meters")
    .delete()
    .lt("synced_at", syncedAt)
    .select("pole");

  if (deleteError) {
    console.error("Delete error:", deleteError);
    process.exit(1);
  }

  const deletedCount = deleted?.length ?? 0;
  console.log(`Deleted stale: ${deletedCount}`);

  console.log(
    `\nSync complete. Fetched: ${rows.length}, Filtered: ${filtered.length}, Upserted: ${upserted}, Deleted: ${deletedCount}`
  );
}

main();
