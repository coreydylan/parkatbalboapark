'use client'

import { useRef, useEffect, useCallback } from 'react'
import mapboxgl from 'mapbox-gl'
import { useAppStore } from '@/store/app-store'
import { MAPBOX_TOKEN, DEFAULT_CENTER, DEFAULT_ZOOM, MAP_STYLE } from '@/lib/mapbox'
import { getCostColor } from '@/lib/utils'
import type { ParkingLot, ParkingRecommendation } from '@parkatbalboa/shared'

// Tram route coordinates (loop connecting 4 stops)
const TRAM_ROUTE_COORDS: [number, number][] = [
  [-117.1553, 32.7263], // Inspiration Point
  [-117.1503, 32.7316], // Palisades / The Old Globe
  [-117.1480, 32.7340], // Plaza de Panama
  [-117.1428, 32.7323], // Park Blvd & Presidents Way
  [-117.1553, 32.7263], // back to Inspiration Point
]

const TRAM_STOPS = [
  { name: 'Inspiration Point', coords: [-117.1553, 32.7263] as [number, number] },
  { name: 'Palisades / The Old Globe', coords: [-117.1503, 32.7316] as [number, number] },
  { name: 'Plaza de Panama', coords: [-117.1480, 32.7340] as [number, number] },
  { name: 'Park Blvd & Presidents Way', coords: [-117.1428, 32.7323] as [number, number] },
]

export function ParkMap() {
  const mapContainer = useRef<HTMLDivElement>(null)
  const mapRef = useRef<mapboxgl.Map | null>(null)
  const popupRef = useRef<mapboxgl.Popup | null>(null)

  const lots = useAppStore((s) => s.lots)
  const recommendations = useAppStore((s) => s.recommendations)
  const selectedLot = useAppStore((s) => s.selectedLot)
  const selectedDestination = useAppStore((s) => s.selectedDestination)
  const selectLot = useAppStore((s) => s.selectLot)
  const fetchLots = useAppStore((s) => s.fetchLots)
  const fetchEnforcement = useAppStore((s) => s.fetchEnforcement)
  const mapCenter = useAppStore((s) => s.mapCenter)
  const mapZoom = useAppStore((s) => s.mapZoom)

  // Initialize map
  useEffect(() => {
    if (!mapContainer.current || mapRef.current) return

    mapboxgl.accessToken = MAPBOX_TOKEN

    const map = new mapboxgl.Map({
      container: mapContainer.current,
      style: MAP_STYLE,
      center: DEFAULT_CENTER,
      zoom: DEFAULT_ZOOM,
    })

    map.addControl(new mapboxgl.NavigationControl(), 'top-right')
    map.addControl(
      new mapboxgl.GeolocateControl({
        positionOptions: { enableHighAccuracy: true },
        trackUserLocation: true,
      }),
      'top-right'
    )

    map.on('load', () => {
      // Tram route layer
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

      // Tram stops
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

      // Lot markers source (will be updated)
      map.addSource('lots', {
        type: 'geojson',
        data: { type: 'FeatureCollection', features: [] },
      })

      map.addLayer({
        id: 'lots-circles',
        type: 'circle',
        source: 'lots',
        paint: {
          'circle-radius': [
            'case',
            ['boolean', ['get', 'selected'], false],
            10,
            7,
          ],
          'circle-color': ['get', 'color'],
          'circle-stroke-width': [
            'case',
            ['boolean', ['get', 'selected'], false],
            3,
            2,
          ],
          'circle-stroke-color': '#ffffff',
        },
      })

      map.addLayer({
        id: 'lots-labels',
        type: 'symbol',
        source: 'lots',
        layout: {
          'text-field': ['get', 'label'],
          'text-size': 9,
          'text-font': ['DIN Pro Bold', 'Arial Unicode MS Bold'],
          'text-allow-overlap': true,
        },
        paint: {
          'text-color': '#ffffff',
        },
      })

      // Walking route source (will be updated)
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

      // Destination marker source
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

      // Click handler for lots
      map.on('click', 'lots-circles', (e) => {
        if (!e.features || e.features.length === 0) return
        const feature = e.features[0]!
        const props = feature.properties
        if (!props) return

        const lotSlug = props['slug'] as string
        const lot = useAppStore.getState().lots.find((l) => l.slug === lotSlug)
        if (lot) {
          selectLot(lot)
        }
      })

      map.on('mouseenter', 'lots-circles', () => {
        map.getCanvas().style.cursor = 'pointer'
      })

      map.on('mouseleave', 'lots-circles', () => {
        map.getCanvas().style.cursor = ''
      })
    })

    mapRef.current = map

    // Load initial data
    fetchLots()
    fetchEnforcement()

    return () => {
      map.remove()
      mapRef.current = null
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  // Update lot markers when lots or recommendations change
  const updateLotMarkers = useCallback(() => {
    const map = mapRef.current
    if (!map || !map.isStyleLoaded()) return

    const source = map.getSource('lots') as mapboxgl.GeoJSONSource | undefined
    if (!source) return

    const recMap = new Map<string, ParkingRecommendation>()
    for (const rec of recommendations) {
      recMap.set(rec.lotSlug, rec)
    }

    const features: GeoJSON.Feature[] = lots.map((lot) => {
      const rec = recMap.get(lot.slug)
      const costCents = rec?.costCents ?? 0
      const color = getCostColor(costCents)
      const isSelected = selectedLot?.slug === lot.slug

      return {
        type: 'Feature',
        properties: {
          slug: lot.slug,
          name: lot.displayName,
          label: 'P',
          color,
          cost: rec?.costDisplay ?? '',
          selected: isSelected,
        },
        geometry: {
          type: 'Point',
          coordinates: [lot.lng, lot.lat],
        },
      }
    })

    source.setData({ type: 'FeatureCollection', features })
  }, [lots, recommendations, selectedLot])

  useEffect(() => {
    updateLotMarkers()
  }, [updateLotMarkers])

  // Update walking route when lot and destination selected
  useEffect(() => {
    const map = mapRef.current
    if (!map || !map.isStyleLoaded()) return

    const walkSource = map.getSource('walking-route') as mapboxgl.GeoJSONSource | undefined
    const destSource = map.getSource('destination') as mapboxgl.GeoJSONSource | undefined

    if (selectedLot && selectedDestination) {
      // Draw walking route line
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

      // Show destination marker
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
      // Clear walking route
      if (walkSource) {
        walkSource.setData({ type: 'FeatureCollection', features: [] })
      }

      // Show destination marker if only destination is selected
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
  }, [selectedLot, selectedDestination])

  // Show popup on selected lot
  useEffect(() => {
    const map = mapRef.current
    if (!map) return

    // Remove existing popup
    if (popupRef.current) {
      popupRef.current.remove()
      popupRef.current = null
    }

    if (selectedLot) {
      const rec = recommendations.find((r) => r.lotSlug === selectedLot.slug)
      const costText = rec?.costDisplay ?? 'N/A'
      const walkText = rec?.walkingTimeDisplay ?? ''

      const popup = new mapboxgl.Popup({
        closeOnClick: false,
        offset: 15,
        className: 'lot-popup',
      })
        .setLngLat([selectedLot.lng, selectedLot.lat])
        .setHTML(
          `<div style="padding: 12px; min-width: 140px;">
            <div style="font-weight: 600; font-size: 14px; margin-bottom: 4px;">${selectedLot.displayName}</div>
            <div style="font-size: 13px; color: ${getCostColor(rec?.costCents ?? 0)}; font-weight: 600;">${costText}</div>
            ${walkText ? `<div style="font-size: 12px; color: #78716c; margin-top: 2px;">${walkText}</div>` : ''}
          </div>`
        )
        .addTo(map)

      popupRef.current = popup
    }
  }, [selectedLot, recommendations])

  // Pan map when center/zoom changes from store
  useEffect(() => {
    const map = mapRef.current
    if (!map) return
    map.flyTo({ center: mapCenter, zoom: mapZoom, duration: 800 })
  }, [mapCenter, mapZoom])

  return (
    <div ref={mapContainer} className="flex-1 h-full" />
  )
}
