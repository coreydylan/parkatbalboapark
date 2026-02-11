'use client'

import { useEffect } from 'react'

// Hardcoded tram route connecting 4 stops in a loop
const TRAM_ROUTE_GEOJSON: GeoJSON.Feature = {
  type: 'Feature',
  properties: {},
  geometry: {
    type: 'LineString',
    coordinates: [
      [-117.1553, 32.7263], // Inspiration Point
      [-117.1503, 32.7316], // Palisades / The Old Globe
      [-117.1480, 32.7340], // Plaza de Panama
      [-117.1428, 32.7323], // Park Blvd & Presidents Way
      [-117.1553, 32.7263], // back to Inspiration Point
    ],
  },
}

const TRAM_STOPS: GeoJSON.FeatureCollection = {
  type: 'FeatureCollection',
  features: [
    {
      type: 'Feature',
      properties: { name: 'Inspiration Point' },
      geometry: { type: 'Point', coordinates: [-117.1553, 32.7263] },
    },
    {
      type: 'Feature',
      properties: { name: 'Palisades / The Old Globe' },
      geometry: { type: 'Point', coordinates: [-117.1503, 32.7316] },
    },
    {
      type: 'Feature',
      properties: { name: 'Plaza de Panama' },
      geometry: { type: 'Point', coordinates: [-117.1480, 32.7340] },
    },
    {
      type: 'Feature',
      properties: { name: 'Park Blvd & Presidents Way' },
      geometry: { type: 'Point', coordinates: [-117.1428, 32.7323] },
    },
  ],
}

interface TramRouteProps {
  map: mapboxgl.Map | null
}

/**
 * Manages the tram route overlay on the map.
 * Adds a dashed orange line and circle markers at each tram stop.
 */
export function TramRoute({ map }: TramRouteProps) {
  useEffect(() => {
    if (!map || !map.isStyleLoaded()) return

    // Add tram route if not already present
    if (!map.getSource('tram-route')) {
      map.addSource('tram-route', {
        type: 'geojson',
        data: TRAM_ROUTE_GEOJSON,
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
    }

    if (!map.getSource('tram-stops')) {
      map.addSource('tram-stops', {
        type: 'geojson',
        data: TRAM_STOPS,
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
    }
  }, [map])

  return null
}
