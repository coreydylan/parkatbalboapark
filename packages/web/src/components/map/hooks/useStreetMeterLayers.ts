import { useEffect, useCallback } from 'react'
import mapboxgl from 'mapbox-gl'
import { useAppStore } from '@/store/app-store'

const SOURCE_ID = 'street-segments'
const CIRCLE_LAYER_ID = 'street-segments-circles'
const LABEL_LAYER_ID = 'street-segments-labels'

/**
 * Manages street meter segment layers on the map.
 * Lazy-loads segment data on first toggle. Circles sized by meter count,
 * colored by rate, with count labels inside.
 */
export function useStreetMeterLayers(
  map: mapboxgl.Map | null,
  mapReady: boolean,
  visible: boolean,
) {
  const streetSegments = useAppStore((s) => s.streetSegments)
  const fetchStreetSegments = useAppStore((s) => s.fetchStreetSegments)

  // Lazy fetch on first toggle
  useEffect(() => {
    if (visible && streetSegments.length === 0) {
      fetchStreetSegments()
    }
  }, [visible, streetSegments.length, fetchStreetSegments])

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
      layout: {
        visibility: 'none',
      },
      paint: {
        'circle-radius': [
          'interpolate', ['linear'], ['get', 'meterCount'],
          1, 5,
          5, 7,
          15, 9,
          30, 12,
        ],
        'circle-color': [
          'step', ['get', 'rateCentsPerHour'],
          '#22c55e', // 0 = free → green
          1, '#3b82f6', // 1-199 → blue (cheap)
          200, '#f59e0b', // 200-399 → amber (moderate)
          400, '#ef4444', // 400+ → red (expensive)
        ],
        'circle-opacity': 0.85,
        'circle-stroke-width': 1.5,
        'circle-stroke-color': '#ffffff',
      },
    })

    map.addLayer({
      id: LABEL_LAYER_ID,
      type: 'symbol',
      source: SOURCE_ID,
      layout: {
        visibility: 'none',
        'text-field': ['to-string', ['get', 'meterCount']],
        'text-size': 9,
        'text-allow-overlap': true,
      },
      paint: {
        'text-color': '#ffffff',
        'text-halo-color': 'rgba(0,0,0,0.3)',
        'text-halo-width': 0.5,
      },
    })
  }, [map, mapReady])

  // Update data when segments change
  const updateData = useCallback(() => {
    if (!map || !map.isStyleLoaded()) return
    const source = map.getSource(SOURCE_ID) as mapboxgl.GeoJSONSource | undefined
    if (!source) return

    const features: GeoJSON.Feature[] = streetSegments.map((seg) => ({
      type: 'Feature' as const,
      properties: {
        segmentId: seg.segmentId,
        area: seg.area,
        subArea: seg.subArea,
        zone: seg.zone,
        meterCount: seg.meterCount,
        rateCentsPerHour: seg.rateCentsPerHour,
        rateDisplay: seg.rateDisplay,
        timeStart: seg.timeStart,
        timeEnd: seg.timeEnd,
        timeLimit: seg.timeLimit,
        daysInOperation: seg.daysInOperation,
        hasMobilePay: seg.hasMobilePay,
      },
      geometry: {
        type: 'Point' as const,
        coordinates: [seg.lng, seg.lat],
      },
    }))

    source.setData({ type: 'FeatureCollection', features })
  }, [map, streetSegments])

  useEffect(() => {
    updateData()
  }, [updateData])

  // Toggle visibility
  useEffect(() => {
    if (!map || !mapReady) return
    const vis = visible ? 'visible' : 'none'
    for (const layerId of [CIRCLE_LAYER_ID, LABEL_LAYER_ID]) {
      if (map.getLayer(layerId)) {
        map.setLayoutProperty(layerId, 'visibility', vis)
      }
    }
  }, [map, mapReady, visible])
}
