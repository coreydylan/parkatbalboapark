import { useEffect } from 'react'
import mapboxgl from 'mapbox-gl'
import { TRAM_ROUTE_COORDS, TRAM_STOPS } from '@/lib/tram-constants'

const TRAM_LAYER_IDS = ['tram-route-line', 'tram-stops-circles', 'tram-stops-labels'] as const

/**
 * Adds the tram route line and tram stop markers to the map.
 * Sources/layers are added once when the map is ready.
 * Visibility is toggled via the `visible` parameter.
 */
export function useTramLayers(map: mapboxgl.Map | null, mapReady: boolean, visible: boolean) {
  useEffect(() => {
    if (!map || !mapReady) return

    // Tram route line
    map.addSource('tram-route', {
      type: 'geojson',
      data: {
        type: 'Feature',
        properties: {},
        geometry: {
          type: 'LineString',
          coordinates: TRAM_ROUTE_COORDS,
        },
      },
    })

    map.addLayer({
      id: 'tram-route-line',
      type: 'line',
      source: 'tram-route',
      paint: {
        'line-color': '#f97316',
        'line-width': 3,
        'line-dasharray': [3, 2],
      },
    })

    // Tram stop circles + labels
    map.addSource('tram-stops', {
      type: 'geojson',
      data: {
        type: 'FeatureCollection',
        features: TRAM_STOPS.map((stop) => ({
          type: 'Feature' as const,
          properties: { name: stop.name },
          geometry: {
            type: 'Point' as const,
            coordinates: stop.coords,
          },
        })),
      },
    })

    map.addLayer({
      id: 'tram-stops-circles',
      type: 'circle',
      source: 'tram-stops',
      paint: {
        'circle-radius': 5,
        'circle-color': '#f97316',
        'circle-stroke-width': 2,
        'circle-stroke-color': '#ffffff',
      },
    })

    map.addLayer({
      id: 'tram-stops-labels',
      type: 'symbol',
      source: 'tram-stops',
      layout: {
        'text-field': ['get', 'name'],
        'text-size': 10,
        'text-offset': [0, 1.5],
        'text-anchor': 'top',
      },
      paint: {
        'text-color': '#9a3412',
        'text-halo-color': '#ffffff',
        'text-halo-width': 1.5,
      },
    })
  }, [map, mapReady])

  // Toggle visibility when the `visible` prop changes
  useEffect(() => {
    if (!map || !mapReady) return
    const vis = visible ? 'visible' : 'none'
    for (const layerId of TRAM_LAYER_IDS) {
      if (map.getLayer(layerId)) {
        map.setLayoutProperty(layerId, 'visibility', vis)
      }
    }
  }, [map, mapReady, visible])
}
