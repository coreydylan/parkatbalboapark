-- Remove Hall of Champions destination
-- The San Diego Hall of Champions permanently closed in 2017.
-- The building at 2131 Pan American Plaza is now the Comic-Con Museum,
-- which is already listed as a separate destination.

DELETE FROM lot_destination_distances
WHERE destination_id = (
    SELECT id FROM destinations WHERE slug = 'san-diego-hall-of-champions'
);

DELETE FROM destinations WHERE slug = 'san-diego-hall-of-champions';
