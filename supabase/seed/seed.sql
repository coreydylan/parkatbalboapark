-- =============================================================
-- Park at Balboa Park - Seed Data
-- Generated: 2026-02-14T22:32:49.652Z
-- =============================================================

-- Parking Lots
-- =============================================================
INSERT INTO parking_lots (slug, name, display_name, address, lat, lng, capacity, has_ev_charging, has_ada_spaces, has_tram_stop, notes)
VALUES ('space-theater', 'Space Theater', 'Space Theater Lot', '1875 El Prado, San Diego, CA 92101', 32.7312, -117.146, 154, false, true, false, 'Behind Fleet Science Center, accessed from Park Blvd. Previously called North Pepper Grove lot. Walking access to Natural History Museum, Casa del Prado Theatre, Casa de Balboa.')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO parking_lots (slug, name, display_name, address, lat, lng, capacity, has_ev_charging, has_ada_spaces, has_tram_stop, notes)
VALUES ('casa-de-balboa', 'Casa de Balboa', 'Casa de Balboa Lot', '1649 El Prado, San Diego, CA 92101', 32.7308, -117.1475, 82, false, true, false, 'Behind Casa de Balboa building, accessed from Park Blvd. Walking access to Museum of Photographic Arts, Model Railroad Museum, History Center.')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO parking_lots (slug, name, display_name, address, lat, lng, capacity, has_ev_charging, has_ada_spaces, has_tram_stop, notes)
VALUES ('alcazar-parking-structure', 'Alcazar Garden', 'Alcazar Garden Lot', '2170 Pan American Rd, San Diego, CA 92101', 32.73056, -117.15188, 120, false, true, true, 'Surface parking lot near Alcazar Garden and The Prado. Near House of Charm tram stop.')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO parking_lots (slug, name, display_name, address, lat, lng, capacity, has_ev_charging, has_ada_spaces, has_tram_stop, notes)
VALUES ('organ-pavilion', 'Organ Pavilion', 'Organ Pavilion Lot', '2125 Pan American Rd E, San Diego, CA 92101', 32.7284, -117.15118, 352, false, true, true, 'Located near the Spreckels Organ Pavilion. Tram stop on site. Convenient for Japanese Friendship Garden and international cottages.')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO parking_lots (slug, name, display_name, address, lat, lng, capacity, has_ev_charging, has_ada_spaces, has_tram_stop, notes)
VALUES ('palisades', 'Palisades', 'Palisades Lot', '2175 Pan American Rd, San Diego, CA 92101', 32.7275, -117.1515, 150, false, true, false, 'Formerly Pan American Plaza lot. Near Comic-Con Museum, Air & Space Museum, and Municipal Gymnasium. Becomes free for verified city residents March 2, 2026.')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO parking_lots (slug, name, display_name, address, lat, lng, capacity, has_ev_charging, has_ada_spaces, has_tram_stop, notes)
VALUES ('bea-evenson', 'Bea Evenson', 'Bea Evenson Lot', '1788 El Prado, San Diego, CA 92101', 32.7325, -117.1467, 102, false, true, false, 'On Village Place Rd, east of Natural History Museum. Walking access to Fleet Science Center, Spanish Village Art Center, Botanical Building. Becomes free for verified city residents March 2, 2026.')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO parking_lots (slug, name, display_name, address, lat, lng, capacity, has_ev_charging, has_ada_spaces, has_tram_stop, notes)
VALUES ('south-carousel', 'South Carousel', 'South Carousel Lot', '1889 Zoo Pl, San Diego, CA 92101', 32.7335, -117.1465, 80, false, true, false, 'Near Balboa Park Carousel and Spanish Village Art Center.')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO parking_lots (slug, name, display_name, address, lat, lng, capacity, has_ev_charging, has_ada_spaces, has_tram_stop, notes)
VALUES ('pepper-grove', 'Pepper Grove', 'Pepper Grove Lot', '2005 Park Blvd, San Diego, CA 92101', 32.73, -117.146, 120, false, true, false, 'Adjacent to Space Theater lot, behind Fleet Science Center. Near Pepper Grove Playground. Becomes free for verified city residents March 2, 2026.')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO parking_lots (slug, name, display_name, address, lat, lng, capacity, has_ev_charging, has_ada_spaces, has_tram_stop, notes)
VALUES ('federal-building', 'Federal Building', 'Federal Building Lot', '2490 Pan American Plaza, San Diego, CA 92101', 32.72612, -117.15183, 80, false, true, true, 'Smaller lot near Federal Building. Free tram stop nearby. Becomes free for verified city residents March 2, 2026.')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO parking_lots (slug, name, display_name, address, lat, lng, capacity, has_ev_charging, has_ada_spaces, has_tram_stop, notes)
VALUES ('marston-point', 'Marston Point', 'Marston Point Lot', '2040 Balboa Dr, San Diego, CA 92101', 32.7275, -117.1575, 80, false, true, false, 'Southwest mesa, off Balboa Dr near Bankers Hill. Becomes free for verified city residents March 2, 2026.')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO parking_lots (slug, name, display_name, address, lat, lng, capacity, has_ev_charging, has_ada_spaces, has_tram_stop, notes)
VALUES ('inspiration-point-upper', 'Inspiration Point (Upper)', 'Inspiration Point Upper Lot', '2040 Pan American Rd, San Diego, CA 92101', 32.72795, -117.15273, 624, false, true, true, 'Large lot at east end of park. Free tram stop available for shuttle to central attractions. Near Veterans Museum. Becomes free for verified city residents March 2, 2026.')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO parking_lots (slug, name, display_name, address, lat, lng, capacity, has_ev_charging, has_ada_spaces, has_tram_stop, notes)
VALUES ('inspiration-point-lower', 'Inspiration Point (Lower)', 'Inspiration Point Lower Lot', '2050 Pan American Rd, San Diego, CA 92101', 32.7265, -117.15, 300, false, true, false, 'First 3 hours free for all visitors. Adjacent to upper lot tram stop. Becomes free for verified city residents March 2, 2026.')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO parking_lots (slug, name, display_name, address, lat, lng, capacity, has_ev_charging, has_ada_spaces, has_tram_stop, notes)
VALUES ('morley-field', 'Morley Field', 'Morley Field Lot', '2221 Morley Field Dr, San Diego, CA 92104', 32.73938, -117.14244, 120, false, true, false, 'Free parking serving Morley Field Sports Complex (disc golf, tennis, pool, dog park). Located in northeast section of the park, outside the paid parking zone.')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO parking_lots (slug, name, display_name, address, lat, lng, capacity, has_ev_charging, has_ada_spaces, has_tram_stop, notes)
VALUES ('gold-gulch', 'Gold Gulch', 'Gold Gulch Lot', '2500 Zoo Pl, San Diego, CA 92101', 32.7342, -117.14788, 40, false, false, false, 'Small informal lot in canyon between Organ Pavilion and Zoo. Named after the 1935 Exposition''s Gold Gulch mining town. Used as overflow parking and tram staging area. Free and outside the paid parking zone.')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO parking_lots (slug, name, display_name, address, lat, lng, capacity, has_ev_charging, has_ada_spaces, has_tram_stop, notes)
VALUES ('centro-cultural', 'Centro Cultural de la Raza', 'Centro Cultural Lot', '2004 Park Blvd, San Diego, CA 92101', 32.72772, -117.14866, 9, false, true, false, 'Tiny building-frontage parking area in front of Centro Cultural de la Raza. Free and outside the paid parking zone. Very limited spaces.')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO parking_lots (slug, name, display_name, address, lat, lng, capacity, has_ev_charging, has_ada_spaces, has_tram_stop, notes)
VALUES ('presidents-way', 'Presidents Way', 'Presidents Way Lot', '2400 Presidents Way, San Diego, CA 92101', 32.7285, -117.149, 30, false, true, false, 'Small parking area along Presidents Way near Park Blvd intersection. May partially overlap with metered street parking along the road. Free and outside the named paid lot system.')
ON CONFLICT (slug) DO NOTHING;

-- Lot Tier Assignments
-- =============================================================
INSERT INTO lot_tier_assignments (lot_id, tier, effective_date, end_date)
VALUES ((SELECT id FROM parking_lots WHERE slug = 'space-theater'), 1, '2026-01-05', NULL)
ON CONFLICT (lot_id, effective_date) DO NOTHING;

INSERT INTO lot_tier_assignments (lot_id, tier, effective_date, end_date)
VALUES ((SELECT id FROM parking_lots WHERE slug = 'casa-de-balboa'), 1, '2026-01-05', NULL)
ON CONFLICT (lot_id, effective_date) DO NOTHING;

INSERT INTO lot_tier_assignments (lot_id, tier, effective_date, end_date)
VALUES ((SELECT id FROM parking_lots WHERE slug = 'alcazar-parking-structure'), 1, '2026-01-05', NULL)
ON CONFLICT (lot_id, effective_date) DO NOTHING;

INSERT INTO lot_tier_assignments (lot_id, tier, effective_date, end_date)
VALUES ((SELECT id FROM parking_lots WHERE slug = 'organ-pavilion'), 1, '2026-01-05', NULL)
ON CONFLICT (lot_id, effective_date) DO NOTHING;

INSERT INTO lot_tier_assignments (lot_id, tier, effective_date, end_date)
VALUES ((SELECT id FROM parking_lots WHERE slug = 'palisades'), 1, '2026-01-05', '2026-03-01')
ON CONFLICT (lot_id, effective_date) DO NOTHING;

INSERT INTO lot_tier_assignments (lot_id, tier, effective_date, end_date)
VALUES ((SELECT id FROM parking_lots WHERE slug = 'palisades'), 2, '2026-03-02', NULL)
ON CONFLICT (lot_id, effective_date) DO NOTHING;

INSERT INTO lot_tier_assignments (lot_id, tier, effective_date, end_date)
VALUES ((SELECT id FROM parking_lots WHERE slug = 'bea-evenson'), 1, '2026-01-05', '2026-03-01')
ON CONFLICT (lot_id, effective_date) DO NOTHING;

INSERT INTO lot_tier_assignments (lot_id, tier, effective_date, end_date)
VALUES ((SELECT id FROM parking_lots WHERE slug = 'bea-evenson'), 2, '2026-03-02', NULL)
ON CONFLICT (lot_id, effective_date) DO NOTHING;

INSERT INTO lot_tier_assignments (lot_id, tier, effective_date, end_date)
VALUES ((SELECT id FROM parking_lots WHERE slug = 'south-carousel'), 1, '2026-01-05', NULL)
ON CONFLICT (lot_id, effective_date) DO NOTHING;

INSERT INTO lot_tier_assignments (lot_id, tier, effective_date, end_date)
VALUES ((SELECT id FROM parking_lots WHERE slug = 'pepper-grove'), 2, '2026-01-05', NULL)
ON CONFLICT (lot_id, effective_date) DO NOTHING;

INSERT INTO lot_tier_assignments (lot_id, tier, effective_date, end_date)
VALUES ((SELECT id FROM parking_lots WHERE slug = 'federal-building'), 2, '2026-01-05', NULL)
ON CONFLICT (lot_id, effective_date) DO NOTHING;

INSERT INTO lot_tier_assignments (lot_id, tier, effective_date, end_date)
VALUES ((SELECT id FROM parking_lots WHERE slug = 'marston-point'), 2, '2026-01-05', NULL)
ON CONFLICT (lot_id, effective_date) DO NOTHING;

INSERT INTO lot_tier_assignments (lot_id, tier, effective_date, end_date)
VALUES ((SELECT id FROM parking_lots WHERE slug = 'inspiration-point-upper'), 2, '2026-01-05', NULL)
ON CONFLICT (lot_id, effective_date) DO NOTHING;

INSERT INTO lot_tier_assignments (lot_id, tier, effective_date, end_date)
VALUES ((SELECT id FROM parking_lots WHERE slug = 'inspiration-point-lower'), 3, '2026-01-05', NULL)
ON CONFLICT (lot_id, effective_date) DO NOTHING;

INSERT INTO lot_tier_assignments (lot_id, tier, effective_date, end_date)
VALUES ((SELECT id FROM parking_lots WHERE slug = 'morley-field'), 0, '2026-01-05', NULL)
ON CONFLICT (lot_id, effective_date) DO NOTHING;

INSERT INTO lot_tier_assignments (lot_id, tier, effective_date, end_date)
VALUES ((SELECT id FROM parking_lots WHERE slug = 'gold-gulch'), 0, '2026-01-05', NULL)
ON CONFLICT (lot_id, effective_date) DO NOTHING;

INSERT INTO lot_tier_assignments (lot_id, tier, effective_date, end_date)
VALUES ((SELECT id FROM parking_lots WHERE slug = 'centro-cultural'), 0, '2026-01-05', NULL)
ON CONFLICT (lot_id, effective_date) DO NOTHING;

INSERT INTO lot_tier_assignments (lot_id, tier, effective_date, end_date)
VALUES ((SELECT id FROM parking_lots WHERE slug = 'presidents-way'), 0, '2026-01-05', NULL)
ON CONFLICT (lot_id, effective_date) DO NOTHING;

-- Destinations
-- =============================================================
INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('alcazar-garden', 'Alcazar Garden', 'Alcazar Garden', 'palisades', 'garden', '2100 Pan American Rd, San Diego, CA 92101', 32.73113, -117.15159, 'https://balboapark.org/explore/alcazar-garden')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('arizona-street-landfill-park', 'Arizona Street Landfill Park', 'Arizona Landfill Park', 'east_mesa', 'recreation', 'Arizona St, San Diego, CA 92104', 32.734, -117.141, '')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('australian-garden', 'Australian Garden', 'Australian Garden', 'palisades', 'garden', '2150 Pan American Rd, San Diego, CA 92101', 32.7314, -117.15044, 'https://balboapark.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('balboa-park-carousel', 'Balboa Park Carousel', 'Carousel', 'central_mesa', 'recreation', '1889 Zoo Pl, San Diego, CA 92101', 32.73458, -117.14666, 'https://balboapark.org/explore/balboa-park-carousel')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('balboa-park-club', 'Balboa Park Club', 'Balboa Park Club', 'palisades', 'landmark', '2150 Pan American Plaza, San Diego, CA 92101', 32.72901, -117.15363, 'https://balboapark.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('craft-coffee', 'Balboa Park Craft Coffee', 'Craft Coffee', 'central_mesa', 'dining', '1889 Zoo Pl, San Diego, CA 92101', 32.73384, -117.14769, '')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('balboa-park-dog-park', 'Balboa Park Dog Park (Nate''s Point)', 'Nate''s Point Dog Park', 'palisades', 'recreation', '2167 6th Ave, San Diego, CA 92101', 32.73058, -117.15656, 'https://balboapark.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('balboa-park-miniature-train', 'Balboa Park Miniature Railroad', 'Miniature Railroad', 'central_mesa', 'recreation', '1800 Zoo Pl, San Diego, CA 92101', 32.73474, -117.14812, 'https://bfrr.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('municipal-gymnasium', 'Balboa Park Municipal Gymnasium', 'Municipal Gymnasium', 'pan_american', 'recreation', '2111 Pan American Plaza, San Diego, CA 92101', 32.72913, -117.14721, 'https://www.sandiego.gov')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('balboa-park-visitor-center', 'Balboa Park Visitor Center', 'Visitor Center', 'central_mesa', 'landmark', '1549 El Prado, San Diego, CA 92101', 32.73097, -117.14968, 'https://balboapark.org/plan-your-visit')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('botanical-building', 'Botanical Building & Lily Pond', 'Botanical Building', 'central_mesa', 'garden', '1549 El Prado, San Diego, CA 92101', 32.73252, -117.14923, 'https://balboapark.org/explore/botanical-building')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('cabrillo-bridge', 'Cabrillo Bridge', 'Cabrillo Bridge', 'central_mesa', 'landmark', 'Cabrillo Bridge, San Diego, CA 92101', 32.7318, -117.1584, 'https://balboapark.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('california-tower', 'California Tower', 'California Tower', 'central_mesa', 'landmark', '1350 El Prado, San Diego, CA 92101', 32.73148, -117.15255, 'https://www.museumofus.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('canyonside-community-park', 'Canyonside Community Park', 'Canyonside Park', 'florida_canyon', 'recreation', 'Pershing Dr, San Diego, CA 92101', 32.7355, -117.1435, '')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('casa-de-balboa', 'Casa de Balboa', 'Casa de Balboa', 'central_mesa', 'landmark', '1649 El Prado, San Diego, CA 92101', 32.73116, -117.1488, 'https://balboapark.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('casa-del-prado', 'Casa del Prado', 'Casa del Prado', 'central_mesa', 'landmark', '1650 El Prado, San Diego, CA 92101', 32.73249, -117.14839, 'https://balboapark.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('centro-cultural-de-la-raza', 'Centro Cultural de la Raza', 'Centro Cultural', 'pan_american', 'museum', '2004 Park Blvd, San Diego, CA 92101', 32.72772, -117.14866, 'https://centroraza.com')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('desert-garden', 'Desert Garden', 'Desert Garden', 'central_mesa', 'garden', 'Park Blvd, San Diego, CA 92101', 32.73211, -117.14565, 'https://balboapark.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('el-prado-walkway', 'El Prado Walkway', 'El Prado', 'central_mesa', 'landmark', 'El Prado, San Diego, CA 92101', 32.732, -117.15, 'https://balboapark.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('fleet-science-center', 'Fleet Science Center', 'Fleet Science Center', 'central_mesa', 'museum', '1875 El Prado, San Diego, CA 92101', 32.73082, -117.14707, 'https://www.fleetscience.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('florida-canyon-native-plant-garden', 'Florida Canyon Native Plant Garden', 'Native Plant Garden', 'florida_canyon', 'garden', 'Morley Field Dr, San Diego, CA 92104', 32.7358, -117.144, 'https://balboapark.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('florida-canyon-nature-center', 'Florida Canyon Nature Center', 'Florida Canyon', 'florida_canyon', 'landmark', 'Morley Field Dr, San Diego, CA 92104', 32.736, -117.144, 'https://balboapark.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('food-truck-alley', 'Food Truck Alley', 'Food Trucks', 'central_mesa', 'dining', 'Zoo Pl, San Diego, CA 92101', 32.7342, -117.1465, '')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('house-of-hospitality', 'House of Hospitality', 'House of Hospitality', 'central_mesa', 'landmark', '1549 El Prado, San Diego, CA 92101', 32.73097, -117.14968, 'https://balboapark.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('international-cottages', 'House of Pacific Relations International Cottages', 'International Cottages', 'palisades', 'landmark', '2191 Pan American Rd, San Diego, CA 92101', 32.7289, -117.1522, 'https://www.sdhpr.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('inez-grant-parker-memorial-rose-garden', 'Inez Grant Parker Memorial Rose Garden', 'Rose Garden', 'central_mesa', 'garden', 'Park Blvd, San Diego, CA 92101', 32.73119, -117.14568, 'https://balboapark.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('japanese-friendship-garden', 'Japanese Friendship Garden', 'Japanese Friendship Garden', 'palisades', 'garden', '2215 Pan American Rd, San Diego, CA 92101', 32.72943, -117.14917, 'https://www.niwa.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('tea-pavilion', 'Japanese Friendship Garden Tea Pavilion', 'Tea Pavilion', 'palisades', 'dining', '2215 Pan American Rd, San Diego, CA 92101', 32.73011, -117.14998, 'https://www.niwa.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('puppet-theater', 'Marie Hitchcock Puppet Theater', 'Puppet Theater', 'palisades', 'theater', '2130 Pan American Plaza, San Diego, CA 92101', 32.72827, -117.1536, 'https://www.bfrr.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('mingei-international-museum', 'Mingei International Museum', 'Mingei Museum', 'palisades', 'museum', '1439 El Prado, San Diego, CA 92101', 32.73101, -117.15103, 'https://www.mingei.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('morley-field-baseball', 'Morley Field Baseball Diamonds', 'Baseball Diamonds', 'morley_field', 'recreation', 'Morley Field Dr, San Diego, CA 92104', 32.7392, -117.1425, '')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('morley-field-disc-golf', 'Morley Field Disc Golf Course', 'Disc Golf', 'morley_field', 'recreation', '2300 Morley Field Dr, San Diego, CA 92104', 32.73762, -117.13576, 'https://bfrr.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('morley-field-pool', 'Morley Field Pool', 'Bud Kearns Pool', 'morley_field', 'recreation', '2229 Morley Field Dr, San Diego, CA 92104', 32.7395, -117.142, 'https://www.sandiego.gov')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('morley-field-tennis', 'Morley Field Tennis Center', 'Tennis Center', 'morley_field', 'recreation', '2221 Morley Field Dr, San Diego, CA 92104', 32.739, -117.141, 'https://www.bfrr.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('museum-of-photographic-arts', 'Museum of Photographic Arts', 'Photo Arts Museum', 'central_mesa', 'museum', '1649 El Prado, San Diego, CA 92101', 32.73116, -117.14889, 'https://mopa.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('museum-of-us', 'Museum of Us', 'Museum of Us', 'central_mesa', 'museum', '1350 El Prado, San Diego, CA 92101', 32.73148, -117.15255, 'https://www.museumofus.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('palm-canyon', 'Palm Canyon', 'Palm Canyon', 'palisades', 'garden', 'Pan American Rd, San Diego, CA 92101', 32.7304, -117.152, 'https://balboapark.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('pan-american-community-park', 'Pan American Community Park', 'Pan American Park', 'pan_american', 'recreation', 'Pan American Rd, San Diego, CA 92101', 32.729, -117.149, '')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('panama-66', 'Panama 66', 'Panama 66', 'central_mesa', 'dining', '1450 El Prado, San Diego, CA 92101', 32.73176, -117.15103, 'https://www.panama66.com')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('redwood-circle', 'Redwood Circle', 'Redwood Circle', 'central_mesa', 'garden', 'Cabrillo Bridge area, San Diego, CA 92101', 32.73332, -117.15709, 'https://balboapark.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('san-diego-air-space-museum', 'San Diego Air & Space Museum', 'Air & Space Museum', 'pan_american', 'museum', '2001 Pan American Plaza, San Diego, CA 92101', 32.72624, -117.15441, 'https://www.sandiegoairandspace.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('san-diego-automotive-museum', 'San Diego Automotive Museum', 'Automotive Museum', 'pan_american', 'museum', '2080 Pan American Plaza, San Diego, CA 92101', 32.72749, -117.15391, 'https://www.sdautomuseum.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('san-diego-hall-of-champions', 'San Diego Hall of Champions', 'Hall of Champions', 'pan_american', 'museum', '2131 Pan American Plaza, San Diego, CA 92101', 32.7295, -117.1485, '')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('san-diego-history-center', 'San Diego History Center', 'History Center', 'central_mesa', 'museum', '1649 El Prado, San Diego, CA 92101', 32.73116, -117.14827, 'https://www.sandiegohistory.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('san-diego-junior-theatre', 'San Diego Junior Theatre', 'Junior Theatre', 'central_mesa', 'theater', '1650 El Prado, San Diego, CA 92101', 32.73249, -117.14884, 'https://www.juniortheatre.com')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('san-diego-model-railroad-museum', 'San Diego Model Railroad Museum', 'Model Railroad Museum', 'central_mesa', 'museum', '1649 El Prado, San Diego, CA 92101', 32.73116, -117.14874, 'https://www.sdmrm.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('san-diego-museum-of-art', 'San Diego Museum of Art', 'Museum of Art', 'central_mesa', 'museum', '1450 El Prado, San Diego, CA 92101', 32.73217, -117.15045, 'https://www.sdmart.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('san-diego-natural-history-museum', 'San Diego Natural History Museum', 'NAT Museum', 'central_mesa', 'museum', '1788 El Prado, San Diego, CA 92101', 32.73205, -117.14736, 'https://www.sdnhm.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('morley-field-velodrome', 'San Diego Velodrome', 'Velodrome', 'morley_field', 'recreation', '2221 Morley Field Dr, San Diego, CA 92104', 32.7387, -117.13824, 'https://www.sdvelodrome.com')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('san-diego-zoo', 'San Diego Zoo', 'San Diego Zoo', 'central_mesa', 'zoo', '2920 Zoo Dr, San Diego, CA 92101', 32.7353, -117.149, 'https://zoo.sandiegozoo.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('spanish-village-art-center', 'Spanish Village Art Center', 'Spanish Village', 'central_mesa', 'landmark', '1770 Village Pl, San Diego, CA 92101', 32.73375, -117.14759, 'https://www.spanishvillageart.com')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('spreckels-organ-pavilion', 'Spreckels Organ Pavilion', 'Organ Pavilion', 'palisades', 'landmark', '1549 El Prado, San Diego, CA 92101', 32.72948, -117.15042, 'https://www.spreckelsorgan.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('starlight-bowl', 'Starlight Bowl', 'Starlight Bowl', 'pan_american', 'theater', '2005 Pan American Plaza, San Diego, CA 92101', 32.72635, -117.15334, '')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('old-globe-theatre', 'The Old Globe', 'The Old Globe', 'palisades', 'theater', '1363 Old Globe Way, San Diego, CA 92101', 32.73226, -117.15227, 'https://www.theoldglobe.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('the-prado-restaurant', 'The Prado at Balboa Park', 'The Prado', 'central_mesa', 'dining', '1549 El Prado, San Diego, CA 92101', 32.73097, -117.14968, 'https://www.pradobalboa.com')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('timken-museum-of-art', 'Timken Museum of Art', 'Timken Museum', 'central_mesa', 'museum', '1500 El Prado, San Diego, CA 92101', 32.73185, -117.14963, 'https://www.timkenmuseum.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('veterans-museum', 'Veterans Museum & Memorial Center', 'Veterans Museum', 'pan_american', 'museum', '2115 Park Blvd, San Diego, CA 92101', 32.7258, -117.14879, 'https://www.veteranmuseum.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('war-memorial-building', 'War Memorial Building', 'War Memorial', 'central_mesa', 'landmark', '3325 Zoo Dr, San Diego, CA 92101', 32.7352, -117.1468, 'https://www.sandiego.gov')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('worldbeat-cultural-center', 'WorldBeat Cultural Center', 'WorldBeat Center', 'pan_american', 'museum', '2100 Park Blvd, San Diego, CA 92101', 32.72721, -117.14957, 'https://www.worldbeatcenter.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('zoro-garden', 'Zoro Garden', 'Zoro Garden', 'central_mesa', 'garden', 'Park Blvd, San Diego, CA 92101', 32.73112, -117.1478, 'https://balboapark.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('comic-con-museum', 'Comic-Con Museum', 'Comic-Con Museum', 'pan_american', 'museum', '2131 Pan American Plaza, San Diego, CA 92101', 32.72728, -117.15241, 'https://www.comic-con.org/museum')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('marston-house', 'Marston House Museum & Gardens', 'Marston House', 'central_mesa', 'museum', '3525 7th Ave, San Diego, CA 92103', 32.74171, -117.15783, 'https://www.sandiegohistory.org/marston-house')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('kate-sessions-cactus-garden', 'Kate O. Sessions Cactus Garden', 'Cactus Garden', 'palisades', 'garden', 'Pan American Rd, San Diego, CA 92101', 32.72894, -117.15426, 'https://balboapark.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('bea-evenson-fountain', 'Bea Evenson Fountain', 'Bea Evenson Fountain', 'central_mesa', 'landmark', '1549 El Prado, San Diego, CA 92101', 32.73119, -117.14584, 'https://balboapark.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('plaza-de-panama', 'Plaza de Panama', 'Plaza de Panama', 'central_mesa', 'landmark', 'El Prado, San Diego, CA 92101', 32.732, -117.15, 'https://balboapark.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('palisades-building', 'Palisades Building', 'Palisades Building', 'palisades', 'landmark', '2130 Pan American Plaza, San Diego, CA 92101', 32.72827, -117.1536, 'https://balboapark.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('casa-del-rey-moro-garden', 'Casa del Rey Moro Garden', 'Casa del Rey Moro', 'palisades', 'garden', 'Pan American Rd, San Diego, CA 92101', 32.7318, -117.15153, 'https://balboapark.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('ethnobotany-peace-garden', 'Ethnobotany Peace Garden', 'Peace Garden', 'pan_american', 'garden', '2004 Park Blvd, San Diego, CA 92101', 32.72691, -117.14982, 'https://balboapark.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('lawn-bowling-green', 'San Diego Lawn Bowling Club', 'Lawn Bowling', 'palisades', 'recreation', 'Pan American Rd, San Diego, CA 92101', 32.731, -117.157, 'https://balboapark.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('veterans-memorial-garden', 'Veterans Memorial Garden', 'Veterans Garden', 'palisades', 'garden', 'Pan American Rd, San Diego, CA 92101', 32.7315, -117.156, 'https://balboapark.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('trees-for-health-garden', 'Trees for Health Garden', 'Trees for Health', 'central_mesa', 'garden', '6th Ave, San Diego, CA 92101', 32.73719, -117.15838, 'https://balboapark.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('may-marcy-sculpture-garden', 'May S. Marcy Sculpture Court & Garden', 'Sculpture Garden', 'central_mesa', 'garden', '1450 El Prado, San Diego, CA 92101', 32.73182, -117.15153, 'https://www.sdmart.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('institute-of-contemporary-art', 'Institute of Contemporary Art, San Diego', 'ICA San Diego', 'central_mesa', 'museum', '1439 El Prado, San Diego, CA 92101', 32.73101, -117.15103, 'https://www.icasandiego.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('grape-street-dog-park', 'Grape Street Dog Park', 'Grape Street Dog Park', 'east_mesa', 'recreation', 'Grape St, San Diego, CA 92102', 32.72621, -117.1348, '')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('administration-building', 'Administration Building', 'Admin Building', 'pan_american', 'landmark', '2125 Park Blvd, San Diego, CA 92101', 32.72668, -117.14771, 'https://balboapark.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('morley-field-dog-park', 'Morley Field Dog Park', 'Morley Field Dog Park', 'morley_field', 'recreation', 'Morley Field Dr, San Diego, CA 92104', 32.73886, -117.14242, '')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('california-native-plant-garden', 'California Native Plant Garden', 'Native Plant Garden', 'morley_field', 'garden', 'Morley Field Dr, San Diego, CA 92104', 32.738, -117.144, 'https://balboapark.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('rube-powell-archery-range', 'Rube Powell Archery Range', 'Archery Range', 'central_mesa', 'recreation', 'Balboa Park, San Diego, CA 92101', 32.7335, -117.155, 'https://balboapark.org')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('golden-hill-recreation-center', 'Golden Hill Recreation Center', 'Golden Hill Rec Center', 'east_mesa', 'recreation', '2600 Golf Course Dr, San Diego, CA 92102', 32.7249, -117.1376, 'https://www.sandiego.gov')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO destinations (slug, name, display_name, area, type, address, lat, lng, website_url)
VALUES ('balboa-park-golf-course', 'Balboa Park Golf Course', 'Golf Course', 'east_mesa', 'recreation', '2600 Golf Course Dr, San Diego, CA 92102', 32.725, -117.138, 'https://www.sandiego.gov')
ON CONFLICT (slug) DO NOTHING;

-- Pricing Rules
-- =============================================================
INSERT INTO pricing_rules (tier, user_type, duration_type, rate_cents, max_daily_cents, effective_date, end_date)
VALUES (1, 'resident', 'block', 500, 800, '2026-01-05', NULL)
ON CONFLICT DO NOTHING;

INSERT INTO pricing_rules (tier, user_type, duration_type, rate_cents, max_daily_cents, effective_date, end_date)
VALUES (1, 'nonresident', 'block', 1000, 1600, '2026-01-05', NULL)
ON CONFLICT DO NOTHING;

INSERT INTO pricing_rules (tier, user_type, duration_type, rate_cents, max_daily_cents, effective_date, end_date)
VALUES (2, 'resident', 'daily', 500, 500, '2026-01-05', '2026-03-01')
ON CONFLICT DO NOTHING;

INSERT INTO pricing_rules (tier, user_type, duration_type, rate_cents, max_daily_cents, effective_date, end_date)
VALUES (2, 'nonresident', 'daily', 1000, 1000, '2026-01-05', NULL)
ON CONFLICT DO NOTHING;

INSERT INTO pricing_rules (tier, user_type, duration_type, rate_cents, max_daily_cents, effective_date, end_date)
VALUES (3, 'resident', 'daily', 500, 500, '2026-01-05', '2026-03-01')
ON CONFLICT DO NOTHING;

INSERT INTO pricing_rules (tier, user_type, duration_type, rate_cents, max_daily_cents, effective_date, end_date)
VALUES (3, 'nonresident', 'daily', 1000, 1000, '2026-01-05', NULL)
ON CONFLICT DO NOTHING;

INSERT INTO pricing_rules (tier, user_type, duration_type, rate_cents, max_daily_cents, effective_date, end_date)
VALUES (0, 'resident', 'daily', 0, 0, '2026-01-05', NULL)
ON CONFLICT DO NOTHING;

INSERT INTO pricing_rules (tier, user_type, duration_type, rate_cents, max_daily_cents, effective_date, end_date)
VALUES (0, 'nonresident', 'daily', 0, 0, '2026-01-05', NULL)
ON CONFLICT DO NOTHING;

INSERT INTO pricing_rules (tier, user_type, duration_type, rate_cents, max_daily_cents, effective_date, end_date)
VALUES (1, 'staff', 'daily', 500, 800, '2026-01-05', NULL)
ON CONFLICT DO NOTHING;

INSERT INTO pricing_rules (tier, user_type, duration_type, rate_cents, max_daily_cents, effective_date, end_date)
VALUES (2, 'staff', 'daily', 0, 0, '2026-01-05', NULL)
ON CONFLICT DO NOTHING;

INSERT INTO pricing_rules (tier, user_type, duration_type, rate_cents, max_daily_cents, effective_date, end_date)
VALUES (3, 'staff', 'daily', 0, 0, '2026-01-05', NULL)
ON CONFLICT DO NOTHING;

INSERT INTO pricing_rules (tier, user_type, duration_type, rate_cents, max_daily_cents, effective_date, end_date)
VALUES (0, 'staff', 'daily', 0, 0, '2026-01-05', NULL)
ON CONFLICT DO NOTHING;

INSERT INTO pricing_rules (tier, user_type, duration_type, rate_cents, max_daily_cents, effective_date, end_date)
VALUES (1, 'volunteer', 'daily', 500, 800, '2026-01-05', NULL)
ON CONFLICT DO NOTHING;

INSERT INTO pricing_rules (tier, user_type, duration_type, rate_cents, max_daily_cents, effective_date, end_date)
VALUES (2, 'volunteer', 'daily', 0, 0, '2026-01-05', NULL)
ON CONFLICT DO NOTHING;

INSERT INTO pricing_rules (tier, user_type, duration_type, rate_cents, max_daily_cents, effective_date, end_date)
VALUES (3, 'volunteer', 'daily', 0, 0, '2026-01-05', NULL)
ON CONFLICT DO NOTHING;

INSERT INTO pricing_rules (tier, user_type, duration_type, rate_cents, max_daily_cents, effective_date, end_date)
VALUES (0, 'volunteer', 'daily', 0, 0, '2026-01-05', NULL)
ON CONFLICT DO NOTHING;

INSERT INTO pricing_rules (tier, user_type, duration_type, rate_cents, max_daily_cents, effective_date, end_date)
VALUES (1, 'ada', 'daily', 0, 0, '2026-01-05', NULL)
ON CONFLICT DO NOTHING;

INSERT INTO pricing_rules (tier, user_type, duration_type, rate_cents, max_daily_cents, effective_date, end_date)
VALUES (2, 'ada', 'daily', 0, 0, '2026-01-05', NULL)
ON CONFLICT DO NOTHING;

INSERT INTO pricing_rules (tier, user_type, duration_type, rate_cents, max_daily_cents, effective_date, end_date)
VALUES (3, 'ada', 'daily', 0, 0, '2026-01-05', NULL)
ON CONFLICT DO NOTHING;

INSERT INTO pricing_rules (tier, user_type, duration_type, rate_cents, max_daily_cents, effective_date, end_date)
VALUES (0, 'ada', 'daily', 0, 0, '2026-01-05', NULL)
ON CONFLICT DO NOTHING;

-- Post-March 2 resident pricing changes (free for verified residents)
INSERT INTO pricing_rules (tier, user_type, duration_type, rate_cents, max_daily_cents, effective_date)
VALUES (2, 'resident', 'daily', 0, 0, '2026-03-02')
ON CONFLICT DO NOTHING;

INSERT INTO pricing_rules (tier, user_type, duration_type, rate_cents, max_daily_cents, effective_date)
VALUES (3, 'resident', 'daily', 0, 0, '2026-03-02')
ON CONFLICT DO NOTHING;

-- Holidays
-- =============================================================
INSERT INTO holidays (name, date, is_recurring)
VALUES ('New Year''s Day', '2026-01-01', true)
ON CONFLICT DO NOTHING;

INSERT INTO holidays (name, date, is_recurring)
VALUES ('Martin Luther King Jr. Day', '2026-01-19', false)
ON CONFLICT DO NOTHING;

INSERT INTO holidays (name, date, is_recurring)
VALUES ('Presidents'' Day', '2026-02-16', false)
ON CONFLICT DO NOTHING;

INSERT INTO holidays (name, date, is_recurring)
VALUES ('Memorial Day', '2026-05-25', false)
ON CONFLICT DO NOTHING;

INSERT INTO holidays (name, date, is_recurring)
VALUES ('Independence Day', '2026-07-04', true)
ON CONFLICT DO NOTHING;

INSERT INTO holidays (name, date, is_recurring)
VALUES ('Labor Day', '2026-09-07', false)
ON CONFLICT DO NOTHING;

INSERT INTO holidays (name, date, is_recurring)
VALUES ('Veterans Day', '2026-11-11', true)
ON CONFLICT DO NOTHING;

INSERT INTO holidays (name, date, is_recurring)
VALUES ('Thanksgiving', '2026-11-26', false)
ON CONFLICT DO NOTHING;

INSERT INTO holidays (name, date, is_recurring)
VALUES ('Christmas Day', '2026-12-25', true)
ON CONFLICT DO NOTHING;

-- Enforcement Periods
-- =============================================================
INSERT INTO enforcement_periods (start_time, end_time, days_of_week, effective_date, end_date)
VALUES ('08:00', '20:00', ARRAY[0,1,2,3,4,5,6], '2026-01-05', '2026-03-01')
ON CONFLICT DO NOTHING;

INSERT INTO enforcement_periods (start_time, end_time, days_of_week, effective_date, end_date)
VALUES ('08:00', '18:00', ARRAY[0,1,2,3,4,5,6], '2026-03-02', NULL)
ON CONFLICT DO NOTHING;

-- Tram Stops
-- =============================================================
INSERT INTO tram_stops (name, lot_id, lat, lng, stop_order)
VALUES ('Park Blvd & Presidents Way', NULL, 32.72541, -117.14942, 1)
ON CONFLICT DO NOTHING;

INSERT INTO tram_stops (name, lot_id, lat, lng, stop_order)
VALUES ('Federal Building', (SELECT id FROM parking_lots WHERE slug = 'federal-building'), 32.7267, -117.15172, 2)
ON CONFLICT DO NOTHING;

INSERT INTO tram_stops (name, lot_id, lat, lng, stop_order)
VALUES ('Inspiration Point', (SELECT id FROM parking_lots WHERE slug = 'inspiration-point-upper'), 32.72763, -117.153, 3)
ON CONFLICT DO NOTHING;

INSERT INTO tram_stops (name, lot_id, lat, lng, stop_order)
VALUES ('Organ Pavilion', (SELECT id FROM parking_lots WHERE slug = 'organ-pavilion'), 32.72977, -117.15139, 4)
ON CONFLICT DO NOTHING;

INSERT INTO tram_stops (name, lot_id, lat, lng, stop_order)
VALUES ('House of Charm', (SELECT id FROM parking_lots WHERE slug = 'alcazar-parking-structure'), 32.73113, -117.15045, 5)
ON CONFLICT DO NOTHING;

-- Tram Schedule
-- =============================================================
INSERT INTO tram_schedule (start_time, end_time, frequency_minutes, days_of_week, effective_date, end_date)
VALUES ('09:00', '18:00', 10, ARRAY[0,1,2,3,4,5,6], '2026-01-05', NULL)
ON CONFLICT DO NOTHING;

-- Payment Methods
-- =============================================================
INSERT INTO payment_methods (lot_id, method)
VALUES ((SELECT id FROM parking_lots WHERE slug = 'space-theater'), 'parkmobile')
ON CONFLICT (lot_id, method) DO NOTHING;

INSERT INTO payment_methods (lot_id, method)
VALUES ((SELECT id FROM parking_lots WHERE slug = 'space-theater'), 'credit_card')
ON CONFLICT (lot_id, method) DO NOTHING;

INSERT INTO payment_methods (lot_id, method)
VALUES ((SELECT id FROM parking_lots WHERE slug = 'casa-de-balboa'), 'parkmobile')
ON CONFLICT (lot_id, method) DO NOTHING;

INSERT INTO payment_methods (lot_id, method)
VALUES ((SELECT id FROM parking_lots WHERE slug = 'casa-de-balboa'), 'credit_card')
ON CONFLICT (lot_id, method) DO NOTHING;

INSERT INTO payment_methods (lot_id, method)
VALUES ((SELECT id FROM parking_lots WHERE slug = 'alcazar-parking-structure'), 'parkmobile')
ON CONFLICT (lot_id, method) DO NOTHING;

INSERT INTO payment_methods (lot_id, method)
VALUES ((SELECT id FROM parking_lots WHERE slug = 'alcazar-parking-structure'), 'credit_card')
ON CONFLICT (lot_id, method) DO NOTHING;

INSERT INTO payment_methods (lot_id, method)
VALUES ((SELECT id FROM parking_lots WHERE slug = 'alcazar-parking-structure'), 'apple_pay')
ON CONFLICT (lot_id, method) DO NOTHING;

INSERT INTO payment_methods (lot_id, method)
VALUES ((SELECT id FROM parking_lots WHERE slug = 'alcazar-parking-structure'), 'google_pay')
ON CONFLICT (lot_id, method) DO NOTHING;

INSERT INTO payment_methods (lot_id, method)
VALUES ((SELECT id FROM parking_lots WHERE slug = 'organ-pavilion'), 'parkmobile')
ON CONFLICT (lot_id, method) DO NOTHING;

INSERT INTO payment_methods (lot_id, method)
VALUES ((SELECT id FROM parking_lots WHERE slug = 'organ-pavilion'), 'credit_card')
ON CONFLICT (lot_id, method) DO NOTHING;

INSERT INTO payment_methods (lot_id, method)
VALUES ((SELECT id FROM parking_lots WHERE slug = 'palisades'), 'parkmobile')
ON CONFLICT (lot_id, method) DO NOTHING;

INSERT INTO payment_methods (lot_id, method)
VALUES ((SELECT id FROM parking_lots WHERE slug = 'palisades'), 'credit_card')
ON CONFLICT (lot_id, method) DO NOTHING;

INSERT INTO payment_methods (lot_id, method)
VALUES ((SELECT id FROM parking_lots WHERE slug = 'bea-evenson'), 'parkmobile')
ON CONFLICT (lot_id, method) DO NOTHING;

INSERT INTO payment_methods (lot_id, method)
VALUES ((SELECT id FROM parking_lots WHERE slug = 'bea-evenson'), 'credit_card')
ON CONFLICT (lot_id, method) DO NOTHING;

INSERT INTO payment_methods (lot_id, method)
VALUES ((SELECT id FROM parking_lots WHERE slug = 'south-carousel'), 'parkmobile')
ON CONFLICT (lot_id, method) DO NOTHING;

INSERT INTO payment_methods (lot_id, method)
VALUES ((SELECT id FROM parking_lots WHERE slug = 'south-carousel'), 'credit_card')
ON CONFLICT (lot_id, method) DO NOTHING;

INSERT INTO payment_methods (lot_id, method)
VALUES ((SELECT id FROM parking_lots WHERE slug = 'pepper-grove'), 'parkmobile')
ON CONFLICT (lot_id, method) DO NOTHING;

INSERT INTO payment_methods (lot_id, method)
VALUES ((SELECT id FROM parking_lots WHERE slug = 'federal-building'), 'parkmobile')
ON CONFLICT (lot_id, method) DO NOTHING;

INSERT INTO payment_methods (lot_id, method)
VALUES ((SELECT id FROM parking_lots WHERE slug = 'marston-point'), 'parkmobile')
ON CONFLICT (lot_id, method) DO NOTHING;

INSERT INTO payment_methods (lot_id, method)
VALUES ((SELECT id FROM parking_lots WHERE slug = 'inspiration-point-upper'), 'parkmobile')
ON CONFLICT (lot_id, method) DO NOTHING;

INSERT INTO payment_methods (lot_id, method)
VALUES ((SELECT id FROM parking_lots WHERE slug = 'inspiration-point-upper'), 'credit_card')
ON CONFLICT (lot_id, method) DO NOTHING;

INSERT INTO payment_methods (lot_id, method)
VALUES ((SELECT id FROM parking_lots WHERE slug = 'inspiration-point-lower'), 'parkmobile')
ON CONFLICT (lot_id, method) DO NOTHING;

INSERT INTO payment_methods (lot_id, method)
VALUES ((SELECT id FROM parking_lots WHERE slug = 'inspiration-point-lower'), 'credit_card')
ON CONFLICT (lot_id, method) DO NOTHING;

-- Park Organizations
-- =============================================================
INSERT INTO park_organizations (slug, name, category)
VALUES ('museo-de-las-americas', 'Centro Cultural de la Raza', 'museum')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO park_organizations (slug, name, category)
VALUES ('comic-con-museum', 'Comic-Con Museum', 'museum')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO park_organizations (slug, name, category)
VALUES ('fleet-science-center', 'Fleet Science Center', 'museum')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO park_organizations (slug, name, category)
VALUES ('house-of-pacific-relations', 'House of Pacific Relations International Cottages', 'cultural')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO park_organizations (slug, name, category)
VALUES ('ica-san-diego', 'Institute of Contemporary Art San Diego', 'museum')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO park_organizations (slug, name, category)
VALUES ('japanese-friendship-garden', 'Japanese Friendship Garden', 'garden')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO park_organizations (slug, name, category)
VALUES ('marston-house', 'Marston House Museum', 'museum')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO park_organizations (slug, name, category)
VALUES ('mingei-international', 'Mingei International Museum', 'museum')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO park_organizations (slug, name, category)
VALUES ('museum-of-photographic-arts', 'Museum of Photographic Arts', 'museum')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO park_organizations (slug, name, category)
VALUES ('museum-of-us', 'Museum of Us', 'museum')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO park_organizations (slug, name, category)
VALUES ('san-diego-air-space-museum', 'San Diego Air & Space Museum', 'museum')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO park_organizations (slug, name, category)
VALUES ('san-diego-art-institute', 'San Diego Art Institute', 'museum')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO park_organizations (slug, name, category)
VALUES ('san-diego-automotive-museum', 'San Diego Automotive Museum', 'museum')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO park_organizations (slug, name, category)
VALUES ('san-diego-history-center', 'San Diego History Center', 'museum')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO park_organizations (slug, name, category)
VALUES ('san-diego-mineral-gem', 'San Diego Mineral & Gem Society', 'museum')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO park_organizations (slug, name, category)
VALUES ('san-diego-model-railroad', 'San Diego Model Railroad Museum', 'museum')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO park_organizations (slug, name, category)
VALUES ('san-diego-museum-of-art', 'San Diego Museum of Art', 'museum')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO park_organizations (slug, name, category)
VALUES ('san-diego-natural-history', 'San Diego Natural History Museum', 'museum')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO park_organizations (slug, name, category)
VALUES ('timken-museum', 'Timken Museum of Art', 'museum')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO park_organizations (slug, name, category)
VALUES ('veterans-museum', 'Veterans Museum at Balboa Park', 'museum')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO park_organizations (slug, name, category)
VALUES ('worldbeat-center', 'WorldBeat Center', 'cultural')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO park_organizations (slug, name, category)
VALUES ('the-old-globe', 'The Old Globe Theatre', 'performing-arts')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO park_organizations (slug, name, category)
VALUES ('sd-youth-symphony', 'San Diego Youth Symphony and Conservatory', 'performing-arts')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO park_organizations (slug, name, category)
VALUES ('spreckels-organ-society', 'Spreckels Organ Society', 'performing-arts')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO park_organizations (slug, name, category)
VALUES ('spanish-village-art-center', 'Spanish Village Art Center', 'cultural')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO park_organizations (slug, name, category)
VALUES ('forever-balboa-park', 'Forever Balboa Park', 'nonprofit')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO park_organizations (slug, name, category)
VALUES ('balboa-art-conservation', 'Balboa Art Conservation Center', 'nonprofit')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO park_organizations (slug, name, category)
VALUES ('committee-of-100', 'Committee of 100', 'nonprofit')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO park_organizations (slug, name, category)
VALUES ('sd-zoo-wildlife-alliance', 'San Diego Zoo Wildlife Alliance', 'zoo')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO park_organizations (slug, name, category)
VALUES ('sd-lawn-bowling', 'San Diego Lawn Bowling Club', 'club')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO park_organizations (slug, name, category)
VALUES ('sd-archers', 'San Diego Archers', 'club')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO park_organizations (slug, name, category)
VALUES ('redwood-bridge-club', 'Redwood Bridge Club', 'club')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO park_organizations (slug, name, category)
VALUES ('balboa-park-chess-club', 'Balboa Park Chess Club', 'club')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO park_organizations (slug, name, category)
VALUES ('house-of-scotland', 'House of Scotland Pipe Band', 'club')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO park_organizations (slug, name, category)
VALUES ('balboa-park-horseshoe', 'Balboa Park Horseshoe Club', 'club')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO park_organizations (slug, name, category)
VALUES ('city-parks-recreation', 'City of San Diego Parks & Recreation', 'government')
ON CONFLICT (slug) DO NOTHING;
