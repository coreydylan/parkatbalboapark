#!/usr/bin/env python3
"""Crop destination images to 3:1 aspect ratio for 130pt x full-width cards.
Each image gets a custom vertical crop position based on composition analysis."""

import os
from pathlib import Path
from PIL import Image

TARGET_WIDTH = 800
ASPECT_RATIO = 3.0  # width:height = 3:1 for 130pt tall cards
TARGET_HEIGHT = int(TARGET_WIDTH / ASPECT_RATIO)  # ~267px

IMG_DIR = Path(__file__).parent.parent.parent / "ios" / "ParkAtBalboaPark" / "Resources" / "DestinationImages"

# Per-image crop position: fraction (0.0=top, 1.0=bottom) for CENTER of crop window.
# Analyzed by viewing each image's composition.
# - Buildings with lots of sky: 0.50-0.60 (crop lower to show building, cut sky)
# - Buildings shot from below: 0.40-0.50 (center, architecture fills frame)
# - Gardens/nature: 0.40-0.50 (center)
# - Wide panoramics: 0.50 (center)
# - Water/fountain scenes: 0.35-0.45 (keep reflection)
# - Aerial views: 0.40-0.50 (center on subject)

CROP_POSITIONS = {
    # Museums - mostly building facades
    "san-diego-museum-of-art": 0.42,       # building centered, some sky, plaza below
    "san-diego-natural-history-museum": 0.40,  # tall facade
    "fleet-science-center": 0.50,           # night shot, fountain + building centered
    "mingei-international-museum": 0.45,    # Mission-style facade, some sky
    "museum-of-us": 0.42,                   # tower/dome, cut sky above
    "museum-of-photographic-arts": 0.45,    # building facade
    "san-diego-history-center": 0.45,       # glass entrance
    "san-diego-model-railroad-museum": 0.45,
    "san-diego-air-space-museum": 0.45,     # building with Blackbird jet in front
    "san-diego-automotive-museum": 0.45,
    "comic-con-museum": 0.40,              # Art Deco Federal Building, prominent entrance
    "timken-museum-of-art": 0.45,          # mid-century modern, centered facade
    "centro-cultural-de-la-raza": 0.55,    # circular building, big trees/sky above
    "worldbeat-cultural-center": 0.50,     # already nearly panoramic, murals fill frame
    "veterans-museum": 0.45,
    "marston-house": 0.40,                 # Arts & Crafts house, roof important
    "institute-of-contemporary-art": 0.45,
    "san-diego-hall-of-champions": 0.45,

    # Gardens
    "alcazar-garden": 0.45,                # formal garden with hedges, building background
    "australian-garden": 0.45,             # lush forest path
    "botanical-building": 0.40,            # building + lily pond reflection - keep both
    "desert-garden": 0.45,                 # cacti spread across frame
    "inez-grant-parker-memorial-rose-garden": 0.45,
    "japanese-friendship-garden": 0.45,    # winding path through garden
    "palm-canyon": 0.45,                   # palm-lined path
    "zoro-garden": 0.45,                   # sunken amphitheater
    "redwood-circle": 0.45,               # looking up at canopy
    "casa-del-rey-moro-garden": 0.45,
    "kate-sessions-cactus-garden": 0.45,
    "ethnobotany-peace-garden": 0.45,
    "veterans-memorial-garden": 0.45,
    "trees-for-health-garden": 0.45,
    "may-marcy-sculpture-garden": 0.42,    # California Tower in background
    "florida-canyon-native-plant-garden": 0.45,
    "california-native-plant-garden": 0.45,

    # Landmarks
    "cabrillo-bridge": 0.40,              # aerial - bridge in center band, sky above, trees below
    "california-tower": 0.40,             # tower extends high, lots of sky
    "balboa-park-visitor-center": 0.42,   # Spanish Colonial arches
    "el-prado-walkway": 0.40,            # lily pond + building, want reflection
    "casa-de-balboa": 0.40,              # ornate tower top, lots of sky - crop to show tower
    "casa-del-prado": 0.55,              # Churrigueresque facade, big blue sky above
    "house-of-hospitality": 0.42,         # tower + fountain + umbrellas
    "spreckels-organ-pavilion": 0.38,     # grand arch high up, benches below, cloudy sky
    "spanish-village-art-center": 0.45,
    "bea-evenson-fountain": 0.40,         # cherry trees + fountain, keep both
    "plaza-de-panama": 0.45,
    "palisades-building": 0.45,
    "balboa-park-club": 0.45,
    "administration-building": 0.45,
    "war-memorial-building": 0.45,

    # Theaters & Dining
    "old-globe-theatre": 0.42,            # Tudor roofline important, hedges below
    "san-diego-junior-theatre": 0.45,
    "puppet-theater": 0.45,
    "starlight-bowl": 0.42,              # arched stage important
    "the-prado-restaurant": 0.45,
    "panama-66": 0.45,                   # sculpture garden
    "tea-pavilion": 0.45,
    "craft-coffee": 0.45,
    "food-truck-alley": 0.45,

    # Recreation
    "san-diego-zoo": 0.42,               # lion statue + entrance centered
    "balboa-park-carousel": 0.45,
    "balboa-park-miniature-train": 0.45,
    "balboa-park-dog-park": 0.45,
    "grape-street-dog-park": 0.45,
    "morley-field-dog-park": 0.45,
    "morley-field-disc-golf": 0.45,
    "morley-field-tennis": 0.45,
    "morley-field-baseball": 0.45,
    "morley-field-pool": 0.45,
    "morley-field-velodrome": 0.42,       # cyclists centered on banked track
    "balboa-park-golf-course": 0.45,
    "lawn-bowling-green": 0.45,
    "golden-hill-recreation-center": 0.45,
    "rube-powell-archery-range": 0.45,
    "canyonside-community-park": 0.45,
    "pan-american-community-park": 0.45,
    "municipal-gymnasium": 0.45,
    "international-cottages": 0.45,
    "arizona-street-landfill-park": 0.45,

    # Other
    "balboa-park-visitor-center": 0.42,
}

DEFAULT_CROP = 0.45  # slightly above center - works for most


def crop_image(img_path: Path, center_fraction: float) -> None:
    """Crop image to TARGET_WIDTH x TARGET_HEIGHT, positioned at center_fraction."""
    with Image.open(img_path) as img:
        w, h = img.size

        # First resize to TARGET_WIDTH if wider
        if w != TARGET_WIDTH:
            scale = TARGET_WIDTH / w
            new_h = int(h * scale)
            img = img.resize((TARGET_WIDTH, new_h), Image.LANCZOS)
            w, h = img.size

        # If already shorter than target, skip cropping
        if h <= TARGET_HEIGHT:
            img.save(img_path, "JPEG", quality=85)
            return

        # Calculate crop box
        crop_center_y = int(h * center_fraction)
        top = crop_center_y - TARGET_HEIGHT // 2
        bottom = top + TARGET_HEIGHT

        # Clamp to image bounds
        if top < 0:
            top = 0
            bottom = TARGET_HEIGHT
        if bottom > h:
            bottom = h
            top = h - TARGET_HEIGHT

        cropped = img.crop((0, top, w, bottom))
        cropped.save(img_path, "JPEG", quality=85)


def main():
    if not IMG_DIR.exists():
        print(f"Image directory not found: {IMG_DIR}")
        return

    files = sorted(IMG_DIR.glob("*.jpg"))
    print(f"Processing {len(files)} images → {TARGET_WIDTH}x{TARGET_HEIGHT}px (3:1)")

    for img_path in files:
        slug = img_path.stem
        center = CROP_POSITIONS.get(slug, DEFAULT_CROP)

        with Image.open(img_path) as img:
            w, h = img.size
            # Calculate what the height will be after resize
            scale = TARGET_WIDTH / w
            new_h = int(h * scale)

        if new_h <= TARGET_HEIGHT:
            print(f"  SKIP {slug} ({w}x{h} → too short to crop)")
            continue

        crop_image(img_path, center)
        print(f"  CROP {slug} (center={center:.0%})")

    print(f"\nDone! All images cropped to {TARGET_WIDTH}x{TARGET_HEIGHT}px")
    # Verify
    total_size = sum(f.stat().st_size for f in IMG_DIR.glob("*.jpg"))
    print(f"Total size: {total_size / 1024 / 1024:.1f}MB")


if __name__ == "__main__":
    main()
