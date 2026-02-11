'use client'

import { useEffect } from 'react'
import { useAppStore } from '@/store/app-store'

interface WalkingRouteProps {
  map: mapboxgl.Map | null
}

/**
 * Manages the walking route GeoJSON layer on the map.
 * Subscribes to selectedLot and selectedDestination from store.
 */
export function WalkingRoute({ map }: WalkingRouteProps) {
  const selectedLot = useAppStore((s) => s.selectedLot)
  const selectedDestination = useAppStore((s) => s.selectedDestination)

  useEffect(() => {
    if (!map || !map.isStyleLoaded()) return

    const source = map.getSource('walking-route') as mapboxgl.GeoJSONSource | undefined
    if (!source) return

    if (selectedLot && selectedDestination) {
      source.setData({
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
    } else {
      source.setData({ type: 'FeatureCollection', features: [] })
    }
  }, [map, selectedLot, selectedDestination])

  return null
}
