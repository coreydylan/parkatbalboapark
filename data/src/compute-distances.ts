import { readFileSync, appendFileSync } from "fs";
import { join } from "path";

interface Lot {
  slug: string;
  name: string;
  lat: number;
  lng: number;
}

interface Destination {
  slug: string;
  name: string;
  lat: number;
  lng: number;
}

const R = 6371000; // Earth radius in meters
const PATH_FACTOR = 1.3;
const WALKING_SPEED = 1.34; // m/s
const MAX_STRAIGHT_LINE_METERS = 3000;

/**
 * Haversine distance in meters between two lat/lng points.
 */
function haversine(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number,
): number {
  const toRad = (deg: number) => (deg * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

function main() {
  const rawDir = join(__dirname, "..", "raw");
  const seedPath = join(__dirname, "..", "..", "supabase", "seed", "seed.sql");

  const lots: Lot[] = JSON.parse(
    readFileSync(join(rawDir, "lots.json"), "utf-8"),
  );
  const destinations: Destination[] = JSON.parse(
    readFileSync(join(rawDir, "destinations.json"), "utf-8"),
  );

  console.log(
    `Computing distances for ${lots.length} lots x ${destinations.length} destinations`,
  );

  const lines: string[] = [];
  lines.push("");
  lines.push("-- Lot-Destination Walking Distances (haversine-based)");
  lines.push("-- =============================================================");

  let pairCount = 0;
  let skippedCount = 0;

  for (const lot of lots) {
    for (const dest of destinations) {
      const straightLine = haversine(lot.lat, lot.lng, dest.lat, dest.lng);

      if (straightLine >= MAX_STRAIGHT_LINE_METERS) {
        skippedCount++;
        continue;
      }

      const walkingDistance = Math.round(straightLine * PATH_FACTOR);
      const walkingTime = Math.round((straightLine * PATH_FACTOR) / WALKING_SPEED);

      lines.push(
        `INSERT INTO lot_destination_distances (lot_id, destination_id, walking_distance_meters, walking_time_seconds)` +
          ` VALUES ((SELECT id FROM parking_lots WHERE slug = '${lot.slug}'), (SELECT id FROM destinations WHERE slug = '${dest.slug}'), ${walkingDistance}, ${walkingTime})` +
          ` ON CONFLICT (lot_id, destination_id) DO NOTHING;`,
      );
      pairCount++;
    }
  }

  lines.push("");

  appendFileSync(seedPath, lines.join("\n"));

  console.log(`Appended ${pairCount} distance rows to seed.sql`);
  console.log(
    `Skipped ${skippedCount} pairs (straight-line >= ${MAX_STRAIGHT_LINE_METERS}m)`,
  );
}

main();
