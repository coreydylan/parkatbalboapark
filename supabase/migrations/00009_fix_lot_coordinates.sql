-- 00009_fix_lot_coordinates.sql
-- Fix parking lot coordinates using OSM (Overpass API) polygon centroids
-- cross-referenced with geocoding and landmark triangulation.
--
-- Source: OpenStreetMap Overpass API query for amenity=parking in Balboa Park
-- bounding box (32.724,-117.160,32.742,-117.134), run 2026-02-11.
--
-- 5 lots already correct (Alcazar, Organ Pavilion, Federal Building,
-- Morley Field, Centro Cultural). 11 lots need fixing.

-- ============================================================================
-- LEVEL 1 LOTS
-- ============================================================================

-- Space Theater: was pointing ~170m too far west.
-- OSM way 25841660 (unnamed lot south of Fleet Science Center).
UPDATE parking_lots SET lat = 32.7301, lng = -117.1470
WHERE slug = 'space-theater';

-- Casa de Balboa: was ~120m too far west.
-- OSM way 132957478 (unnamed lot behind Casa de Balboa building).
UPDATE parking_lots SET lat = 32.7304, lng = -117.1487
WHERE slug = 'casa-de-balboa';

-- Palisades: was ~790m off (pointed near Cabrillo Bridge area).
-- OSM way 60194988 (surface lot near Comic-Con Museum / Municipal Gym).
-- Near Air & Space Museum (32.7262, -117.1544) and Comic-Con (32.7273, -117.1524).
UPDATE parking_lots SET lat = 32.7280, lng = -117.1527
WHERE slug = 'palisades';

-- Bea Evenson: was ~330m too far west (near Alcazar area).
-- OSM way 25841666 ("Natural History Museum Parking Lot").
-- On Village Place Rd, east of Natural History Museum.
UPDATE parking_lots SET lat = 32.7325, lng = -117.1467
WHERE slug = 'bea-evenson';

-- South Carousel: was ~490m off (too far south and west).
-- OSM way 272748125 (unnamed lot near Spanish Village Art Center).
-- Near Carousel (32.7346, -117.1467) and Spanish Village (32.7338, -117.1476).
UPDATE parking_lots SET lat = 32.7342, lng = -117.1479
WHERE slug = 'south-carousel';

-- ============================================================================
-- LEVEL 2 LOTS
-- ============================================================================

-- Pepper Grove: was ~460m off (too far north and west).
-- OSM way 25841657 (access=customers, near Pepper Grove Playground).
-- Adjacent to Space Theater lot, south of Fleet Science Center.
UPDATE parking_lots SET lat = 32.7291, lng = -117.1472
WHERE slug = 'pepper-grove';

-- Marston Point: was ~870m off (pointed near Cabrillo Bridge, not west mesa).
-- OSM ways 159270349-353 (lane parking along Balboa Dr near Bankers Hill).
-- Center of 4 OSM lane parking polygons on Balboa Dr.
UPDATE parking_lots SET lat = 32.7275, lng = -117.1577
WHERE slug = 'marston-point';

-- Inspiration Point Upper: was ~430m too far west (near Pan American Rd).
-- OSM way 1299328333 (street_side parking near Park Blvd / Presidents Way).
-- City description: "north of Presidents Way and Park Blvd intersection."
-- Near Veterans Museum (32.7258, -117.1488).
UPDATE parking_lots SET lat = 32.7267, lng = -117.1483
WHERE slug = 'inspiration-point-upper';

-- ============================================================================
-- LEVEL 3 LOT
-- ============================================================================

-- Inspiration Point Lower: was ~580m too far west (near Federal Building).
-- OSM way 1300285107 (operator=City of San Diego, access=permit).
-- City description: "south of Presidents Way and Park Blvd intersection."
UPDATE parking_lots SET lat = 32.7258, lng = -117.1473
WHERE slug = 'inspiration-point-lower';

-- ============================================================================
-- FREE (TIER 0) LOTS
-- ============================================================================

-- Gold Gulch: was ~600m off (pointed near Zoo, not Organ Pavilion canyon).
-- OSM way 267018353 (access=private, in canyon near Organ Pavilion).
-- Canyon between Organ Pavilion and Zoo, accessed via Paseo de Oro.
UPDATE parking_lots SET lat = 32.7290, lng = -117.1499
WHERE slug = 'gold-gulch';

-- Presidents Way: was ~390m too far north.
-- No clear OSM polygon match; estimated from Presidents Way / Park Blvd
-- intersection geography. Small lot along Presidents Way west of Park Blvd.
UPDATE parking_lots SET lat = 32.7280, lng = -117.1478
WHERE slug = 'presidents-way';
