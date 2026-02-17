#!/usr/bin/env python3
"""Download destination images from Wikipedia REST API for the iOS app."""

import json
import os
import subprocess
import sys
import time
from pathlib import Path
from typing import Optional
from urllib.parse import quote

# Mapping of destination slug → Wikipedia article title
# For destinations without their own article, we use related/parent articles
WIKI_MAP = {
    "alcazar-garden": "Alcazar Garden (Balboa Park)",
    "botanical-building": "Botanical Building",
    "california-tower": "California Tower (Balboa Park)",
    "cabrillo-bridge": "Cabrillo Bridge",
    "fleet-science-center": "Fleet Science Center",
    "japanese-friendship-garden": "Japanese Friendship Garden (San Diego)",
    "mingei-international-museum": "Mingei International Museum",
    "museum-of-us": "Museum of Us",
    "old-globe-theatre": "The Old Globe",
    "san-diego-air-space-museum": "San Diego Air & Space Museum",
    "san-diego-automotive-museum": "San Diego Automotive Museum",
    "san-diego-history-center": "San Diego History Center",
    "san-diego-model-railroad-museum": "San Diego Model Railroad Museum",
    "san-diego-museum-of-art": "San Diego Museum of Art",
    "san-diego-natural-history-museum": "San Diego Natural History Museum",
    "san-diego-zoo": "San Diego Zoo",
    "spanish-village-art-center": "Spanish Village Art Center",
    "spreckels-organ-pavilion": "Spreckels Organ Pavilion",
    "timken-museum-of-art": "Timken Museum of Art",
    "veterans-museum": "Veterans Museum and Memorial Center",
    "worldbeat-cultural-center": "WorldBeat Cultural Center",
    "comic-con-museum": "Comic-Con Museum",
    "marston-house": "Marston House",
    "casa-de-balboa": "Casa de Balboa",
    "casa-del-prado": "Casa del Prado",
    "house-of-hospitality": "House of Hospitality",
    "centro-cultural-de-la-raza": "Centro Cultural de la Raza",
    "museum-of-photographic-arts": "Museum of Photographic Arts",
    "san-diego-junior-theatre": "San Diego Junior Theatre",
    "starlight-bowl": "Starlight Bowl",
    "war-memorial-building": "Balboa Park",  # No dedicated article
    "palisades-building": "Balboa Park",
    "palm-canyon": "Balboa Park",
    "redwood-circle": "Balboa Park",
    "zoro-garden": "Zoro Garden",
    "inez-grant-parker-memorial-rose-garden": "Inez Grant Parker Memorial Rose Garden",
    "san-diego-hall-of-champions": "Hall of Champions (museum)",
    "balboa-park-carousel": "Balboa Park",
    "balboa-park-miniature-train": "Balboa Park",
    "balboa-park-visitor-center": "Balboa Park",
    "balboa-park-club": "Balboa Park",
    "el-prado-walkway": "El Prado (San Diego)",
    "puppet-theater": "Marie Hitchcock Puppet Theatre",
    "bea-evenson-fountain": "Bea Evenson Fountain",
    "plaza-de-panama": "Balboa Park",
    "international-cottages": "House of Pacific Relations",
    "the-prado-restaurant": "The Prado at Balboa Park",
    "panama-66": "San Diego Museum of Art",  # It's in the SDMA sculpture garden
    "institute-of-contemporary-art": "Institute of Contemporary Art San Diego",
    "desert-garden": "Balboa Park",
    "florida-canyon-native-plant-garden": "Balboa Park",
    "florida-canyon-nature-center": "Florida Canyon",
    "kate-sessions-cactus-garden": "Kate Sessions",
    "casa-del-rey-moro-garden": "Balboa Park",
    "ethnobotany-peace-garden": "Balboa Park",
    "veterans-memorial-garden": "Balboa Park",
    "trees-for-health-garden": "Balboa Park",
    "may-marcy-sculpture-garden": "San Diego Museum of Art",
    "california-native-plant-garden": "Balboa Park",
    "australian-garden": "Balboa Park",
    "administration-building": "Balboa Park",
    "balboa-park-golf-course": "Balboa Park Golf Course",
    "morley-field-tennis": "Morley Field",
    "morley-field-disc-golf": "Morley Field",
    "morley-field-pool": "Morley Field",
    "morley-field-baseball": "Morley Field",
    "morley-field-velodrome": "San Diego Velodrome",
    "morley-field-dog-park": "Morley Field",
    "san-diego-lawn-bowling-club": "Balboa Park",
    "lawn-bowling-green": "Balboa Park",
    "golden-hill-recreation-center": "Golden Hill, San Diego",
    "grape-street-dog-park": "Balboa Park",
    "balboa-park-dog-park": "Balboa Park",
    "municipal-gymnasium": "Balboa Park",
    "rube-powell-archery-range": "Balboa Park",
    "canyonside-community-park": "Balboa Park",
    "pan-american-community-park": "Balboa Park",
    "food-truck-alley": "Balboa Park",
    "craft-coffee": "Balboa Park",
    "tea-pavilion": "Japanese Friendship Garden (San Diego)",
    "arizona-street-landfill-park": "Balboa Park",
}

OUTPUT_DIR = Path(__file__).parent.parent.parent / "ios" / "ParkAtBalboaPark" / "Resources" / "DestinationImages"
UA = "ParkAtBalboaPark/1.0 (https://parkatbalboapark.com; dev@parkatbalboapark.com)"


def get_wiki_image_url(article_title: str, width: int = 800) -> Optional[str]:
    """Fetch the main image URL for a Wikipedia article using the REST API."""
    encoded = quote(article_title.replace(" ", "_"))
    url = f"https://en.wikipedia.org/api/rest_v1/page/summary/{encoded}"

    try:
        result = subprocess.run(
            ["curl", "-sL", "-H", f"User-Agent: {UA}", url],
            capture_output=True,
            text=True,
            timeout=15,
        )
        data = json.loads(result.stdout)

        # Get the thumbnail or original image
        if "thumbnail" in data:
            # Build a resized URL from the original
            orig = data.get("originalimage", {}).get("source", "")
            if orig and "upload.wikimedia.org" in orig:
                # Construct thumbnail URL at desired width
                # Pattern: /commons/thumb/x/xx/File.jpg/{width}px-File.jpg
                parts = orig.split("/commons/")
                if len(parts) == 2:
                    filename = parts[1].split("/")[-1]
                    return f"https://upload.wikimedia.org/wikipedia/commons/thumb/{parts[1]}/{width}px-{filename}"
            # Fallback to the thumbnail source
            return data["thumbnail"]["source"]
    except Exception as e:
        print(f"  Error fetching wiki data for '{article_title}': {e}")
    return None


def download_image(url: str, output_path: Path) -> bool:
    """Download an image from URL to the given path."""
    try:
        result = subprocess.run(
            ["curl", "-sL", "-o", str(output_path), "-w", "%{http_code}",
             "-H", f"User-Agent: {UA}", url],
            capture_output=True,
            text=True,
            timeout=30,
        )
        status = result.stdout.strip()
        if status == "200" and output_path.exists() and output_path.stat().st_size > 1000:
            return True
        else:
            output_path.unlink(missing_ok=True)
            return False
    except Exception as e:
        print(f"  Download error: {e}")
        output_path.unlink(missing_ok=True)
        return False


def main():
    # Load destinations
    dests_file = Path(__file__).parent.parent / "raw" / "destinations.json"
    with open(dests_file) as f:
        destinations = json.load(f)

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    downloaded = 0
    skipped = 0
    failed = []

    for dest in destinations:
        slug = dest["slug"]
        name = dest["name"]
        output_path = OUTPUT_DIR / f"{slug}.jpg"

        # Skip if already downloaded
        if output_path.exists() and output_path.stat().st_size > 1000:
            print(f"  SKIP {slug} (already exists)")
            skipped += 1
            continue

        wiki_title = WIKI_MAP.get(slug)
        if not wiki_title:
            print(f"  MISS {slug} - no Wikipedia mapping")
            failed.append(slug)
            continue

        print(f"  Fetching {slug} ('{wiki_title}')...", end=" ", flush=True)

        image_url = get_wiki_image_url(wiki_title)
        if not image_url:
            print("NO IMAGE")
            failed.append(slug)
            continue

        if download_image(image_url, output_path):
            print(f"OK ({output_path.stat().st_size // 1024}KB)")
            downloaded += 1
        else:
            print("DOWNLOAD FAILED")
            failed.append(slug)

        # Be respectful of rate limits
        time.sleep(0.3)

    print(f"\nDone! Downloaded: {downloaded}, Skipped: {skipped}, Failed: {len(failed)}")
    if failed:
        print(f"Failed slugs: {', '.join(failed)}")


if __name__ == "__main__":
    main()
