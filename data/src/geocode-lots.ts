import "dotenv/config";
import { readFileSync, writeFileSync, mkdirSync } from "fs";
import { join } from "path";

const MAPBOX_TOKEN = process.env.MAPBOX_TOKEN;
if (!MAPBOX_TOKEN) {
  console.error("Error: MAPBOX_TOKEN environment variable is required");
  process.exit(1);
}

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
}

interface GeocodedLot extends Lot {
  geocoded: {
    lat: number;
    lng: number;
    source: "mapbox" | "manual_override";
    placeName: string | null;
    geocodedAt: string;
  };
}

// Manual coordinate overrides for lots that don't geocode well
// Parking lots are often not well-represented in geocoding services
const MANUAL_OVERRIDES: Record<string, { lat: number; lng: number }> = {
  "inspiration-point-upper": { lat: 32.728, lng: -117.152 },
  "inspiration-point-lower": { lat: 32.7275, lng: -117.1515 },
  "alcazar-parking-structure": { lat: 32.732, lng: -117.148 },
  "organ-pavilion": { lat: 32.731, lng: -117.15 },
  "pan-american-plaza": { lat: 32.73, lng: -117.149 },
  "federal-building": { lat: 32.7315, lng: -117.1465 },
  "morley-field": { lat: 32.7395, lng: -117.141 },
  "gold-gulch": { lat: 32.734, lng: -117.1435 },
  "centro-cultural": { lat: 32.733, lng: -117.15 },
  "presidents-way": { lat: 32.7325, lng: -117.1455 },
  "war-memorial": { lat: 32.735, lng: -117.147 },
  "balboa-park-activity-center": { lat: 32.7365, lng: -117.1445 },
  "municipal-gym": { lat: 32.737, lng: -117.143 },
};

async function geocodeAddress(
  address: string,
): Promise<{ lat: number; lng: number; placeName: string } | null> {
  const url = new URL(
    `https://api.mapbox.com/geocoding/v5/mapbox.places/${encodeURIComponent(address)}.json`,
  );
  url.searchParams.set("access_token", MAPBOX_TOKEN!);
  url.searchParams.set("limit", "1");
  // Bias results toward Balboa Park
  url.searchParams.set("proximity", "-117.1446,32.7341");

  const res = await fetch(url.toString());
  if (!res.ok) {
    console.error(`Geocode failed for "${address}": ${res.status} ${res.statusText}`);
    return null;
  }

  const data = await res.json();
  if (!data.features || data.features.length === 0) {
    console.warn(`No results for "${address}"`);
    return null;
  }

  const [lng, lat] = data.features[0].center;
  return { lat, lng, placeName: data.features[0].place_name };
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function main() {
  const rawDir = join(__dirname, "..", "raw");
  const outDir = join(__dirname, "..", "generated");
  mkdirSync(outDir, { recursive: true });

  const lots: Lot[] = JSON.parse(readFileSync(join(rawDir, "lots.json"), "utf-8"));
  const results: GeocodedLot[] = [];

  console.log(`Geocoding ${lots.length} lots...`);

  for (const lot of lots) {
    const override = MANUAL_OVERRIDES[lot.slug];

    if (override) {
      console.log(`  [override] ${lot.slug}: using manual coordinates`);
      results.push({
        ...lot,
        geocoded: {
          lat: override.lat,
          lng: override.lng,
          source: "manual_override",
          placeName: null,
          geocodedAt: new Date().toISOString(),
        },
      });
      continue;
    }

    console.log(`  [mapbox] ${lot.slug}: geocoding "${lot.address}"...`);
    const result = await geocodeAddress(lot.address);

    if (result) {
      results.push({
        ...lot,
        geocoded: {
          lat: result.lat,
          lng: result.lng,
          source: "mapbox",
          placeName: result.placeName,
          geocodedAt: new Date().toISOString(),
        },
      });
    } else {
      // Fall back to the raw coordinates from lots.json
      console.warn(`  [fallback] ${lot.slug}: using raw coordinates from lots.json`);
      results.push({
        ...lot,
        geocoded: {
          lat: lot.lat,
          lng: lot.lng,
          source: "manual_override",
          placeName: null,
          geocodedAt: new Date().toISOString(),
        },
      });
    }

    // Rate limit: Mapbox free tier allows ~10 req/s, be conservative
    await sleep(200);
  }

  const outPath = join(outDir, "lots-geocoded.json");
  writeFileSync(outPath, JSON.stringify(results, null, 2));
  console.log(`\nWrote ${results.length} geocoded lots to ${outPath}`);
}

main().catch((err) => {
  console.error("Fatal error:", err);
  process.exit(1);
});
