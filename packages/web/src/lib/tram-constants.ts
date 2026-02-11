/**
 * Tram route and stop data for Balboa Park free tram service.
 * Coordinates derived from data/raw/tram-data.json.
 */

export interface TramStop {
  name: string
  coords: [number, number]
  lotSlug: string | null
  stopOrder: number
}

export const TRAM_STOPS: TramStop[] = [
  { name: 'Inspiration Point', coords: [-117.152, 32.728], lotSlug: 'inspiration-point-upper', stopOrder: 1 },
  { name: 'Organ Pavilion', coords: [-117.15, 32.731], lotSlug: 'organ-pavilion', stopOrder: 2 },
  { name: 'Park Blvd / Village Place', coords: [-117.1465, 32.7345], lotSlug: null, stopOrder: 3 },
  { name: 'Zoo / Boy Scout Trail', coords: [-117.148, 32.7355], lotSlug: null, stopOrder: 4 },
]

/** Route coordinates forming the tram loop (first stop repeated at end to close the loop). */
export const TRAM_ROUTE_COORDS: [number, number][] = [
  ...TRAM_STOPS.map((s) => s.coords),
  TRAM_STOPS[0]!.coords, // close the loop
]

export const TRAM_SCHEDULE = {
  startTime: '09:00',
  endTime: '18:00',
  frequencyMinutes: 10,
  daysOfWeek: [0, 1, 2, 3, 4, 5, 6] as number[],
} as const
