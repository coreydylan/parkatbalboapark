/**
 * build-waypoints.ts
 *
 * Processes raw Overpass API data into a master waypoints file.
 * Tags each element with whether it appears on the official Balboa Park map (v35).
 */

import { readFileSync, writeFileSync } from "fs";
import { join } from "path";

// ---------------------------------------------------------------------------
// 1. Official Map Entries (from balboa-park-map-v35-WEB.pdf legend + labels)
//    Keyed by a normalized match string → grid coordinate on the official map.
// ---------------------------------------------------------------------------

const OFFICIAL_MAP_ENTRIES: Record<string, string> = {
  // Museums & Cultural Institutions
  "san diego museum of art": "5D",
  "mingei international museum": "5C",
  "san diego history center": "5D",
  "museum of photographic arts": "5D",
  "san diego model railroad museum": "5D",
  "fleet science center": "5E",
  "reuben h. fleet science center": "5E",
  "reuben h. fleet space theater": "5E",
  "san diego natural history museum": "5E",
  "san diego air & space museum": "7B",
  "san diego air and space museum": "7B",
  "san diego automotive museum": "7C",
  "veterans museum": "7D",
  "veteran's museum and memorial center": "7D",
  "the veterans museum at balboa park": "7D",
  "worldbeat cultural center": "7D",
  "centro cultural de la raza": "6D",
  "comic-con museum": "7C",
  "museum of us": "5C",
  "museum of man": "5C",
  "timken museum of art": "5D",
  "marston house museum and gardens": "1A",
  "marston house": "1A",
  "institute of contemporary art": "5C",
  "san diego art institute": "5C",
  "balboa art conservation center": "5D",
  "san diego mineral & gem society": "4E",

  // Theatres & Performance
  "old globe theatre": "5C",
  "the old globe": "5C",
  "old globe theater": "5C",
  "sheryl and harvey white theatre": "5C",
  "casa del prado theatre": "5D",
  "marie hitchcock puppet theater": "6C",
  "spreckels organ pavilion": "6D",
  "starlight bowl": "5D",
  "lowell davies festival theatre": "5C",
  "copley auditorium": "5D",
  "recital hall": "6C",
  "san diego junior theatre": "5D",
  "san diego civic youth ballet": "5D",
  "san diego youth symphony": "5D",

  // Gardens
  "alcazar garden": "5C",
  "japanese friendship garden": "6D",
  "japanese friendship garden and museum": "6D",
  "botanical building": "5D",
  "botanical building & lily pond": "5D",
  "desert garden": "5I",
  "inez grant parker memorial rose garden": "5E",
  "rose garden": "5E",
  "kate o. sessions cactus garden": "5I",
  "zoro garden": "5E",
  "australian garden": "6D",
  "california native plant garden": "2I",
  "florida canyon native plant preserve": "4F",
  "casa del rey moro garden": "5D",
  "trees for health garden": "3A",
  "veterans memorial garden": "6A",
  "ethnobotany peace garden": "6D",
  "palm canyon": "6C",
  "may s. marcy sculpture court & garden": "5D",
  "azalea garden": "5D",

  // Restaurants & Cafes
  "the prado": "5D",
  "the prado at balboa park": "5D",
  "prado": "5D",
  "panama 66": "5D",
  "lady carolyn's pub": "5C",
  "tobey's 19th hole cafe": "8G",
  "tobeys 19th hole cafe": "8G",
  "cravology": "5E",
  "cravology cafe": "5E",
  "craveology": "5E",
  "peart cafe": "5C",
  "flight path cafe": "7B",
  "flying squirrel cafe": "5E",
  "oneworld beat cafe": "7D",
  "oneworldbeat cafe": "7D",
  "tea pavilion": "6D",
  "route 6 coffee and smoothies": "H",
  "danish coffee cart": "4E",
  "craft cafe at mingei": "5C",
  "artisan of mingei": "5C",
  "cafe in the park": "5D",
  "prado perk": "5D",

  // Attractions & Landmarks
  "balboa park carousel": "4E",
  "spanish village art center": "4E",
  "balboa park activity center": "7E",
  "balboa park visitors center": "5D",
  "california building": "5C",
  "california tower": "5C",
  "plaza de california": "5C",
  "st. francis chapel": "5C",
  "casa de balboa": "5D",
  "house of charm": "5C",
  "house of hospitality": "5D",
  "casa del prado": "5D",
  "bea evenson fountain": "5I",
  "palisades building": "6C",
  "administration building": "7E",
  "gill administration building": "7E",
  "municipal gymnasium": "7C",
  "pan american plaza": "7C",
  "moreton bay fig tree": "5D",
  "cabrillo bridge": "6A",
  "pepper grove": "6E",
  "inspiration point": "7-8D",
  "balboa park miniature railroad": "4E",
  "balboa park miniature railroad station": "4E",

  // International Houses (HPR International Cottages — all at 6C)
  "house of pacific relations": "6C",
  "hall of nations": "6C",
  "united nations": "6C",
  "house of colombia": "6C",
  "house of panama": "6C",
  "house of mexico": "6C",
  "house of korea": "6C",
  "house of india": "6C",
  "house of peru": "6C",
  "house of chamorros": "6C",
  "house of palestine": "6C",
  "house of turkey": "6C",
  "house of france": "6C",
  "house of italy": "6C",
  "house of china": "6C",
  "house of czechia and slovakia": "6C",
  "house of denmark": "6C",
  "house of england": "6C",
  "house of finland": "6C",
  "house of germany": "6C",
  "house of hungary": "6C",
  "house of iran": "6C",
  "house of ireland": "6C",
  "house of israel": "6C",
  "house of norway": "6C",
  "house of poland": "6C",
  "house of puerto rico": "6C",
  "house of scotland": "6C",
  "house of spain": "6C",
  "house of sweden": "6C",
  "house of the philippines": "6C",
  "house of the united states of america": "6C",
  "house of ukraine": "6C",

  // Recreation & Sports
  "san diego zoo": "3D",
  "morley field sports complex": "2G-3H",
  "morley field dog park": "2E-2G",
  "nate's point dog park": "5B",
  "nates point dog park": "5B",
  "lawn bowling": "5A",
  "san diego lawn bowling club": "5A",
  "balboa park golf course": "8-9G",
  "golf clubhouse": "8G",
  "balboa park tennis club": "2G",
  "bocce ball courts": "2G",
  "bud kearns pool": "2G",
  "morley field archery range": "2I",
  "morley field disc golf course": "3H",
  "rube powell archery range": "5B",
  "velodrome": "3G",
  "petanque courts": "H",
  "redwood bridge club": "2A",

  // Community & Other
  "boy scout headquarters": "2C",
  "blind community center": "1E",
  "roosevelt middle school": "2D",
  "naval medical center": "7F",
  "golden hill recreation center": "9H",
  "golden hill park": "9G",
  "golden hill community garden": "10G",
  "grape street park": "6C",
  "camp fire": "2A",
  "scout camp": "1C",
  "balboa club": "6A",
  "balboa park club": "6C",
  "san diego chess club": "D",
  "san diego horseshoe club": "D",
  "senior lounge": "5D",
  "san diego botanical garden foundation": "5D",
  "san diego floral association": "5D",
  "forever balboa park": "5D",
  "school in the park": "5D",
  "committee of 100": "5D",
  "spreckels organ society": "5D",
  "balboa park cultural partnership": "5D",

  // Parking (shown on map with P icons)
  "inspiration point parking": "7-8D",

  // EV Charging (shown on map with icon)
  "ev charging": "various",
  "blink": "5E", // EV charging shown on map

  // Restrooms (shown on map with icons)
  // (matched generically below)

  // Additional from map labels
  "war memorial building": "6D",
  "hale memorial building": "2D",
  "balboa park administration center": "7E",
  "san diego civic dance arts": "5D",
  "inamori pavilion": "6D",

  // Zoo sub-attractions (zoo is on the map; these are within its boundary)
  "owens aviary": "3D",
  "arctic aviary": "3D",
  "scripps aviary": "3D",
  "polar bear exhibit": "3D",
  "elephant care center": "3D",
  "reptile house": "3D",
  "exhibit hall": "3D",

  // Zoo restaurants/cafes (within zoo boundary on map)
  "albert's restaurant": "3D",
  "sydney's": "3D",
  "safari kitchen": "3D",
  "treetops cafe": "3D",
  "arctic snacks": "3D",
  "tundra treats": "3D",
  "sabertooth mexican grill": "3D",
  "hua mei cafe": "3D",
  "front street sweet shack": "3D",
  "the bridge snacks and refreshments": "3D",

  // Additional cafes on map
  "craft cafe at mingei": "5C",
  "the craft taco at the nat": "5E",
  "daniel's coffee": "4E", // Danish Coffee Cart area
  "canteen": "3D",
  "ituri hut": "3D",
  "the pagoda": "3D",

  // Playgrounds (shown on map with playground icon)
  "bird park swingset": "2I",

  // Additional gardens
  "bonsai exhibit": "6D", // part of Japanese Friendship Garden

  // Chapel & religious (on map)
  "saint francis chapel": "5C",
  "st. francis chapel": "5C",

  // Spreckels misspelling in OSM
  "spreckels organ pavillion": "6D",

  // Lady Carolyn's with various apostrophes
  "lady carolyn's pub": "5C",
  "lady carolyns pub": "5C",

  // Additional map-labeled items
  "plaza de panama fountain": "5D",
  "viewing deck": "5D",
  "veterans war memorial": "6D",
  "conrad prebys theatre center": "5C",
  "photographic arts building": "5D",

  // Zoo sub-attractions (within zoo boundary on map)
  "gorilla building": "3D",
  "koala center": "3D",
  "mountain lions": "3D",
  "otto center": "3D",
  "panda shop": "3D",
  "rondavel": "3D",
  "ituri forest outpost": "3D",
  "arctic trader": "3D",
  "sydney gift shop": "3D",
  "tusker's trunk": "3D",
  "bus tour loading": "3D",
  "bus tour unloading": "3D",
  "elevator tower": "3D",
  "the louis": "3D",
  "4d theater": "3D",
  "kid's theater": "3D",
};

// ---------------------------------------------------------------------------
// 2. Category mapping for cleaner output
// ---------------------------------------------------------------------------

type WaypointCategory =
  | "museum"
  | "theatre"
  | "garden"
  | "restaurant"
  | "cafe"
  | "attraction"
  | "artwork"
  | "recreation"
  | "zoo"
  | "international_house"
  | "amenity_restroom"
  | "amenity_drinking_water"
  | "amenity_parking"
  | "amenity_bench"
  | "amenity_picnic"
  | "amenity_bicycle"
  | "amenity_waste"
  | "amenity_ev_charging"
  | "amenity_other"
  | "playground"
  | "sports"
  | "community"
  | "other";

function categorize(tags: Record<string, string>): WaypointCategory {
  const t = tags;

  if (t.tourism === "museum" || t.building === "museum") return "museum";
  if (t.amenity === "theatre" || t.building === "theatre") return "theatre";
  if (t.leisure === "garden") return "garden";
  if (t.amenity === "restaurant") return "restaurant";
  if (t.amenity === "cafe" || t.amenity === "fast_food" || t.amenity === "ice_cream") return "cafe";
  if (t.artwork_type || t.tourism === "artwork") return "artwork";
  if (t.leisure === "playground") return "playground";
  if (t.amenity === "toilets") return "amenity_restroom";
  if (t.amenity === "drinking_water" || t.amenity === "fountain") return "amenity_drinking_water";
  if (t.amenity === "parking" || t.amenity === "bicycle_parking") return "amenity_parking";
  if (t.amenity === "bench") return "amenity_bench";
  if (t.leisure === "picnic_table") return "amenity_picnic";
  if (t.amenity === "bicycle_rental") return "amenity_bicycle";
  if (t.amenity === "waste_basket" || t.amenity === "recycling") return "amenity_waste";
  if (t.amenity === "charging_station") return "amenity_ev_charging";
  if (t.leisure === "fitness_station" || t.leisure === "sports_centre" || t.sport) return "sports";
  if (t.tourism === "attraction") {
    const name = (t.name || "").toLowerCase();
    if (name.includes("house of")) return "international_house";
    return "attraction";
  }
  if (t.tourism === "zoo" || t.zoo) return "zoo";
  if (t.leisure === "park") return "recreation";
  if (t.amenity === "place_of_worship" || t.amenity === "post_box" || t.amenity === "post_office" || t.amenity === "atm" || t.amenity === "vending_machine" || t.amenity === "public_bookcase") return "amenity_other";

  // Building-based fallbacks
  if (t.building) {
    const name = (t.name || "").toLowerCase();
    if (name.includes("museum")) return "museum";
    if (name.includes("theatre") || name.includes("theater") || name.includes("pavilion")) return "theatre";
    if (name.includes("cafe") || name.includes("restaurant") || name.includes("kitchen") || name.includes("grill") || name.includes("snack") || name.includes("treats")) return "cafe";
    if (name.includes("aviary") || name.includes("exhibit") || name.includes("reptile")) return "zoo";
    return "attraction";
  }

  if (t.tourism === "information") return "attraction";
  if (t.tourism === "viewpoint") return "attraction";
  if (t.natural === "tree") return "attraction";
  if (t.leisure) return "recreation";
  if (t.amenity) return "amenity_other";

  return "other";
}

// ---------------------------------------------------------------------------
// 3. Match logic — check if an element name matches something on official map
// ---------------------------------------------------------------------------

function normalizeForMatch(s: string): string {
  return s
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "") // strip accents (é→e, etc.)
    .replace(/[\u2018\u2019\u2032\u0027]/g, "'")
    .replace(/[\u201c\u201d]/g, '"')
    .replace(/\s+/g, " ")
    .trim();
}

function isOnOfficialMap(tags: Record<string, string>): { match: boolean; gridRef?: string } {
  const name = tags.name || tags["name:en"] || "";
  if (!name) {
    // Unnamed amenities (benches, water fountains, etc.) — check if category is on map generically
    if (tags.amenity === "toilets" || tags.amenity === "drinking_water") {
      return { match: true, gridRef: "various" }; // restrooms & water shown on map with icons
    }
    if (tags.amenity === "parking") {
      return { match: true, gridRef: "various" };
    }
    if (tags.amenity === "charging_station") {
      return { match: true, gridRef: "various" };
    }
    if (tags.leisure === "playground") {
      return { match: true, gridRef: "various" }; // playground icons on map
    }
    return { match: false };
  }

  const normalized = normalizeForMatch(name);

  // Build a normalized version of the dictionary for matching
  const normalizedEntries = Object.entries(OFFICIAL_MAP_ENTRIES).map(
    ([key, grid]) => [normalizeForMatch(key), grid] as const
  );

  // Direct match
  for (const [key, grid] of normalizedEntries) {
    if (normalized === key) {
      return { match: true, gridRef: grid };
    }
  }

  // Substring / fuzzy match
  for (const [key, grid] of normalizedEntries) {
    if (normalized.includes(key) || key.includes(normalized)) {
      return { match: true, gridRef: grid };
    }
  }

  // Special cases: Zoo sub-attractions are on the map (zoo is labeled)
  if (
    tags.zoo ||
    tags.tourism === "zoo" ||
    (normalized.includes("zoo") && !normalized.includes("zoom"))
  ) {
    return { match: true, gridRef: "3D" };
  }

  return { match: false };
}

// ---------------------------------------------------------------------------
// 4. Build the master waypoints list
// ---------------------------------------------------------------------------

interface Waypoint {
  id: number;
  osmType: "node" | "way" | "relation";
  name: string | null;
  category: WaypointCategory;
  lat: number;
  lng: number;
  onOfficialMap: boolean;
  mapGridRef: string | null;
  tags: Record<string, string>;
}

function main() {
  const raw = JSON.parse(
    readFileSync(join(__dirname, "../../tmp/overpass-raw.json"), "utf-8")
  );

  const waypoints: Waypoint[] = raw.elements.map((el: any) => {
    const tags = el.tags || {};
    const lat = el.lat ?? el.center?.lat;
    const lng = el.lon ?? el.center?.lon;
    const { match, gridRef } = isOnOfficialMap(tags);

    return {
      id: el.id,
      osmType: el.type,
      name: tags.name || null,
      category: categorize(tags),
      lat,
      lng,
      onOfficialMap: match,
      mapGridRef: gridRef || null,
      tags,
    };
  });

  // Sort: official map items first, then by category, then by name
  waypoints.sort((a, b) => {
    if (a.onOfficialMap !== b.onOfficialMap) return a.onOfficialMap ? -1 : 1;
    if (a.category !== b.category) return a.category.localeCompare(b.category);
    return (a.name || "").localeCompare(b.name || "");
  });

  const onMap = waypoints.filter((w) => w.onOfficialMap).length;
  const offMap = waypoints.filter((w) => !w.onOfficialMap).length;

  console.log(`Total waypoints: ${waypoints.length}`);
  console.log(`On official map: ${onMap}`);
  console.log(`Not on official map: ${offMap}`);
  console.log();

  // Category breakdown
  const cats: Record<string, { total: number; onMap: number }> = {};
  for (const w of waypoints) {
    if (!cats[w.category]) cats[w.category] = { total: 0, onMap: 0 };
    cats[w.category].total++;
    if (w.onOfficialMap) cats[w.category].onMap++;
  }
  console.log("Category breakdown:");
  for (const [cat, counts] of Object.entries(cats).sort((a, b) => b[1].total - a[1].total)) {
    console.log(`  ${cat}: ${counts.total} total (${counts.onMap} on map)`);
  }

  writeFileSync(
    join(__dirname, "../raw/waypoints.json"),
    JSON.stringify(waypoints, null, 2)
  );
  console.log("\nWritten to data/raw/waypoints.json");
}

main();
