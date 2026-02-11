import { useEffect, useRef } from 'react'
import mapboxgl from 'mapbox-gl'
import { useAppStore } from '@/store/app-store'
import { getCostColor } from '@/lib/utils'

/**
 * Manages the popup that appears when a parking lot is selected.
 * Shows lot name, cost, and walking time.
 */
export function useLotPopup(map: mapboxgl.Map | null) {
  const selectedLot = useAppStore((s) => s.selectedLot)
  const recommendations = useAppStore((s) => s.recommendations)
  const popupRef = useRef<mapboxgl.Popup | null>(null)

  useEffect(() => {
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
  }, [map, selectedLot, recommendations])
}
