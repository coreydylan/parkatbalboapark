import { useEffect, useCallback } from 'react'
import mapboxgl from 'mapbox-gl'
import { useAppStore, type Waypoint } from '@/store/app-store'

/** Maps filter keys to waypoint category values */
const FILTER_CATEGORY_MAP: Record<string, string> = {
  restrooms: 'amenity_restroom',
  water: 'amenity_drinking_water',
  ev_charging: 'amenity_ev_charging',
}

/** Colors per category */
const CATEGORY_COLORS: Record<string, string> = {
  amenity_restroom: '#3b82f6',
  amenity_drinking_water: '#06b6d4',
  amenity_ev_charging: '#16a34a',
}

const SOURCE_ID = 'waypoints'
const CIRCLE_LAYER_ID = 'waypoints-circles'
const LABEL_LAYER_ID = 'waypoints-labels'

/**
 * Manages waypoint GeoJSON layers on the map.
 * Filters waypoints based on active map filter categories.
 */
export function useWaypointLayers(
  map: mapboxgl.Map | null,
  mapReady: boolean,
  filters: Record<string, boolean>,
) {
  const waypoints = useAppStore((s) => s.waypoints)
  const fetchWaypoints = useAppStore((s) => s.fetchWaypoints)

  // Fetch waypoints data if not loaded yet
  useEffect(() => {
    if (waypoints.length === 0) fetchWaypoints()
  }, [waypoints.length, fetchWaypoints])

  // Add source and layers once on map load
  useEffect(() => {
    if (!map || !mapReady) return

    map.addSource(SOURCE_ID, {
      type: 'geojson',
      data: { type: 'FeatureCollection', features: [] },
    })

    map.addLayer({
      id: CIRCLE_LAYER_ID,
      type: 'circle',
      source: SOURCE_ID,
      paint: {
        'circle-radius': 4,
        'circle-color': ['get', 'color'],
        'circle-stroke-width': 1.5,
        'circle-stroke-color': '#ffffff',
      },
    })

    map.addLayer({
      id: LABEL_LAYER_ID,
      type: 'symbol',
      source: SOURCE_ID,
      layout: {
        'text-field': ['get', 'name'],
        'text-size': 9,
        'text-offset': [0, 1.3],
        'text-anchor': 'top',
        'text-optional': true,
      },
      paint: {
        'text-color': ['get', 'textColor'],
        'text-halo-color': '#ffffff',
        'text-halo-width': 1,
      },
    })
  }, [map, mapReady])

  // Build the set of active waypoint categories from filters
  const activeCategories = Object.entries(FILTER_CATEGORY_MAP)
    .filter(([key]) => filters[key])
    .map(([, cat]) => cat)

  // Update data whenever waypoints or filters change
  const updateData = useCallback(() => {
    if (!map || !map.isStyleLoaded()) return

    const source = map.getSource(SOURCE_ID) as mapboxgl.GeoJSONSource | undefined
    if (!source) return

    const activeCatSet = new Set(activeCategories)

    const features: GeoJSON.Feature[] = waypoints
      .filter((w: Waypoint) => activeCatSet.has(w.category))
      .map((w: Waypoint) => ({
        type: 'Feature' as const,
        properties: {
          name: w.name,
          color: CATEGORY_COLORS[w.category] ?? '#6b7280',
          textColor: CATEGORY_COLORS[w.category] ?? '#374151',
        },
        geometry: {
          type: 'Point' as const,
          coordinates: [w.lng, w.lat],
        },
      }))

    source.setData({ type: 'FeatureCollection', features })
  }, [map, waypoints, activeCategories.join(',')])

  useEffect(() => {
    updateData()
  }, [updateData])
}
