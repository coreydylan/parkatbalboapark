import { useEffect, useCallback } from 'react'
import mapboxgl from 'mapbox-gl'
import { useAppStore } from '@/store/app-store'
import { getCostColor } from '@/lib/utils'
import type { ParkingRecommendation } from '@parkatbalboa/shared'

/**
 * Manages the parking lot GeoJSON source and layers on the map.
 * Sets up the initial empty source/layers on map load, then updates
 * the data whenever lots, recommendations, or selectedLot change.
 */
export function useLotLayers(map: mapboxgl.Map | null, mapReady: boolean) {
  const lots = useAppStore((s) => s.lots)
  const recommendations = useAppStore((s) => s.recommendations)
  const selectedLot = useAppStore((s) => s.selectedLot)
  const selectLot = useAppStore((s) => s.selectLot)

  // Add sources/layers once on map load
  useEffect(() => {
    if (!map || !mapReady) return

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

    // Click handler
    map.on('click', 'lots-circles', (e) => {
      if (!e.features || e.features.length === 0) return
      const props = e.features[0]!.properties
      if (!props) return

      const lotSlug = props['slug'] as string
      const lot = useAppStore.getState().lots.find((l) => l.slug === lotSlug)
      if (lot) selectLot(lot)
    })

    map.on('mouseenter', 'lots-circles', () => {
      map.getCanvas().style.cursor = 'pointer'
    })

    map.on('mouseleave', 'lots-circles', () => {
      map.getCanvas().style.cursor = ''
    })
  }, [map, mapReady, selectLot])

  // Update lot feature data when lots/recommendations/selection change
  const updateLotData = useCallback(() => {
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
  }, [map, lots, recommendations, selectedLot])

  useEffect(() => {
    updateLotData()
  }, [updateLotData])
}
