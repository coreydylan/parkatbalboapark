import { useEffect } from 'react'
import mapboxgl from 'mapbox-gl'
import { useAppStore } from '@/store/app-store'

/**
 * Manages the walking route line and destination marker on the map.
 * Draws a straight line from selected lot to selected destination,
 * and shows/hides the destination marker accordingly.
 */
export function useWalkingRoute(map: mapboxgl.Map | null, mapReady: boolean) {
  const selectedLot = useAppStore((s) => s.selectedLot)
  const selectedDestination = useAppStore((s) => s.selectedDestination)

  // Add sources/layers once on map load
  useEffect(() => {
    if (!map || !mapReady) return

    map.addSource('walking-route', {
      type: 'geojson',
      data: { type: 'FeatureCollection', features: [] },
    })

    map.addLayer({
      id: 'walking-route-line',
      type: 'line',
      source: 'walking-route',
      paint: {
        'line-color': '#3b82f6',
        'line-width': 3,
        'line-dasharray': [2, 2],
      },
    })

    map.addSource('destination', {
      type: 'geojson',
      data: { type: 'FeatureCollection', features: [] },
    })

    map.addLayer({
      id: 'destination-marker',
      type: 'circle',
      source: 'destination',
      paint: {
        'circle-radius': 8,
        'circle-color': '#dc2626',
        'circle-stroke-width': 3,
        'circle-stroke-color': '#ffffff',
      },
    })
  }, [map, mapReady])

  // Update route/destination data when selection changes
  useEffect(() => {
    if (!map || !map.isStyleLoaded()) return

    const walkSource = map.getSource('walking-route') as mapboxgl.GeoJSONSource | undefined
    const destSource = map.getSource('destination') as mapboxgl.GeoJSONSource | undefined

    if (selectedLot && selectedDestination) {
      if (walkSource) {
        walkSource.setData({
          type: 'Feature',
          properties: {},
          geometry: {
            type: 'LineString',
            coordinates: [
              [selectedLot.lng, selectedLot.lat],
              [selectedDestination.lng, selectedDestination.lat],
            ],
          },
        })
      }

      if (destSource) {
        destSource.setData({
          type: 'FeatureCollection',
          features: [
            {
              type: 'Feature',
              properties: { name: selectedDestination.displayName },
              geometry: {
                type: 'Point',
                coordinates: [selectedDestination.lng, selectedDestination.lat],
              },
            },
          ],
        })
      }
    } else {
      if (walkSource) {
        walkSource.setData({ type: 'FeatureCollection', features: [] })
      }

      if (destSource) {
        if (selectedDestination) {
          destSource.setData({
            type: 'FeatureCollection',
            features: [
              {
                type: 'Feature',
                properties: { name: selectedDestination.displayName },
                geometry: {
                  type: 'Point',
                  coordinates: [selectedDestination.lng, selectedDestination.lat],
                },
              },
            ],
          })
        } else {
          destSource.setData({ type: 'FeatureCollection', features: [] })
        }
      }
    }
  }, [map, selectedLot, selectedDestination])
}
