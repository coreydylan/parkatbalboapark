import "dotenv/config";
import { readFileSync, writeFileSync, mkdirSync } from "fs";
import { join } from "path";

const MAPBOX_TOKEN = process.env.MAPBOX_TOKEN;
if (!MAPBOX_TOKEN) {
  console.error("Error: MAPBOX_TOKEN environment variable is required");
  process.exit(1);
}

interface GeocodedLot {
  slug: string;
  name: string;
  geocoded: { lat: number; lng: number };
}

interface GeocodedDestination {
  slug: string;
  name: string;
  geocoded: { lat: number; lng: number };
}

interface DistanceEntry {
  lotSlug: string;
  destinationSlug: string;
  walkingDistanceMeters: number;
  walkingTimeSeconds: number;
  route: GeoJSON.LineString | null;
  computedAt: string;
}

// Rate limit: max 2 requests/second for Mapbox Directions API
const RATE_LIMIT_MS = 500;

async function getWalkingRoute(
  from: { lat: number; lng: number },
  to: { lat: number; lng: number },
): Promise<{
  distanceMeters: number;
  timeSeconds: number;
  route: GeoJSON.LineString | null;
} | null> {
  const coords = `${from.lng},${from.lat};${to.lng},${to.lat}`;
  const url = new URL(
    `https://api.mapbox.com/directions/v5/mapbox/walking/${coords}`,
  );
  url.searchParams.set("access_token", MAPBOX_TOKEN!);
  url.searchParams.set("geometries", "geojson");
  url.searchParams.set("overview", "simplified");

  const res = await fetch(url.toString());
  if (!res.ok) {
    console.error(`Directions failed: ${res.status} ${res.statusText}`);
    return null;
  }

  const data = await res.json();
  if (!data.routes || data.routes.length === 0) {
    return null;
  }

  const route = data.routes[0];
  return {
    distanceMeters: Math.round(route.distance),
    timeSeconds: Math.round(route.duration),
    route: route.geometry as GeoJSON.LineString,
  };
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function main() {
  const genDir = join(__dirname, "..", "generated");
  mkdirSync(genDir, { recursive: true });

  const lots: GeocodedLot[] = JSON.parse(
    readFileSync(join(genDir, "lots-geocoded.json"), "utf-8"),
  );
  const destinations: GeocodedDestination[] = JSON.parse(
    readFileSync(join(genDir, "destinations-geocoded.json"), "utf-8"),
  );

  const totalPairs = lots.length * destinations.length;
  console.log(
    `Computing walking distances for ${lots.length} lots x ${destinations.length} destinations = ${totalPairs} pairs`,
  );
  console.log(
    `Estimated time at ${RATE_LIMIT_MS}ms rate limit: ~${Math.ceil((totalPairs * RATE_LIMIT_MS) / 60000)} minutes`,
  );

  const results: DistanceEntry[] = [];
  let completed = 0;
  let failed = 0;

  for (const lot of lots) {
    for (const dest of destinations) {
      completed++;
      const pct = ((completed / totalPairs) * 100).toFixed(1);
      process.stdout.write(
        `\r  [${pct}%] ${completed}/${totalPairs} - ${lot.slug} -> ${dest.slug}`,
      );

      const result = await getWalkingRoute(lot.geocoded, dest.geocoded);

      if (result) {
        results.push({
          lotSlug: lot.slug,
          destinationSlug: dest.slug,
          walkingDistanceMeters: result.distanceMeters,
          walkingTimeSeconds: result.timeSeconds,
          route: result.route,
          computedAt: new Date().toISOString(),
        });
      } else {
        failed++;
        // Still record the pair with haversine fallback
        const haversineDist = haversineDistance(lot.geocoded, dest.geocoded);
        const estimatedTime = Math.round(haversineDist / 1.2); // ~1.2 m/s walking

        results.push({
          lotSlug: lot.slug,
          destinationSlug: dest.slug,
          walkingDistanceMeters: Math.round(haversineDist),
          walkingTimeSeconds: estimatedTime,
          route: null,
          computedAt: new Date().toISOString(),
        });
      }

      await sleep(RATE_LIMIT_MS);
    }
  }

  console.log(`\n\nCompleted: ${completed}, Failed (haversine fallback): ${failed}`);

  const outPath = join(genDir, "distances.json");
  writeFileSync(outPath, JSON.stringify(results, null, 2));
  console.log(`Wrote ${results.length} distance entries to ${outPath}`);
}

/**
 * Haversine distance in meters between two lat/lng points.
 * Used as fallback when Mapbox Directions API fails.
 */
function haversineDistance(
  a: { lat: number; lng: number },
  b: { lat: number; lng: number },
): number {
  const R = 6371000; // Earth radius in meters
  const toRad = (deg: number) => (deg * Math.PI) / 180;

  const dLat = toRad(b.lat - a.lat);
  const dLng = toRad(b.lng - a.lng);
  const sinLat = Math.sin(dLat / 2);
  const sinLng = Math.sin(dLng / 2);

  const h =
    sinLat * sinLat +
    Math.cos(toRad(a.lat)) * Math.cos(toRad(b.lat)) * sinLng * sinLng;

  return 2 * R * Math.asin(Math.sqrt(h));
}

main().catch((err) => {
  console.error("Fatal error:", err);
  process.exit(1);
});
