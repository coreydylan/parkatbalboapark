import "dotenv/config";
import { readFileSync, writeFileSync, mkdirSync } from "fs";
import { join } from "path";

const MAPBOX_TOKEN = process.env.MAPBOX_TOKEN;
if (!MAPBOX_TOKEN) {
  console.error("Error: MAPBOX_TOKEN environment variable is required");
  process.exit(1);
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
}

interface GeocodedDestination extends Destination {
  geocoded: {
    lat: number;
    lng: number;
    source: "mapbox" | "fallback";
    placeName: string | null;
    geocodedAt: string;
  };
}

// Balboa Park center for proximity bias
const BALBOA_PARK_CENTER = { lat: 32.7341, lng: -117.1446 };

async function geocodeAddress(
  address: string,
): Promise<{ lat: number; lng: number; placeName: string } | null> {
  const url = new URL(
    `https://api.mapbox.com/geocoding/v5/mapbox.places/${encodeURIComponent(address)}.json`,
  );
  url.searchParams.set("access_token", MAPBOX_TOKEN!);
  url.searchParams.set("limit", "1");
  url.searchParams.set(
    "proximity",
    `${BALBOA_PARK_CENTER.lng},${BALBOA_PARK_CENTER.lat}`,
  );

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

  const destinations: Destination[] = JSON.parse(
    readFileSync(join(rawDir, "destinations.json"), "utf-8"),
  );
  const results: GeocodedDestination[] = [];

  console.log(`Geocoding ${destinations.length} destinations...`);

  for (const dest of destinations) {
    console.log(`  [mapbox] ${dest.slug}: geocoding "${dest.address}"...`);
    const result = await geocodeAddress(dest.address);

    if (result) {
      results.push({
        ...dest,
        geocoded: {
          lat: result.lat,
          lng: result.lng,
          source: "mapbox",
          placeName: result.placeName,
          geocodedAt: new Date().toISOString(),
        },
      });
    } else {
      // Fall back to the manually provided coordinates
      console.warn(`  [fallback] ${dest.slug}: using raw coordinates from destinations.json`);
      results.push({
        ...dest,
        geocoded: {
          lat: dest.lat,
          lng: dest.lng,
          source: "fallback",
          placeName: null,
          geocodedAt: new Date().toISOString(),
        },
      });
    }

    // Rate limit: be conservative with Mapbox geocoding API
    await sleep(200);
  }

  const outPath = join(outDir, "destinations-geocoded.json");
  writeFileSync(outPath, JSON.stringify(results, null, 2));
  console.log(`\nWrote ${results.length} geocoded destinations to ${outPath}`);
}

main().catch((err) => {
  console.error("Fatal error:", err);
  process.exit(1);
});
