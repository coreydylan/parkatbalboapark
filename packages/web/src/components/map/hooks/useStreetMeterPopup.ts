import { useEffect, useRef } from 'react'
import mapboxgl from 'mapbox-gl'

const CIRCLE_LAYER_ID = 'street-segments-circles'

/**
 * Click handler for street meter segment circles.
 * Shows a popup with street name, rate, hours, meter count, and mobile pay badge.
 */
export function useStreetMeterPopup(
  map: mapboxgl.Map | null,
  visible: boolean,
) {
  const popupRef = useRef<mapboxgl.Popup | null>(null)

  useEffect(() => {
    if (!map) return

    // Dismiss popup when layer is hidden
    if (!visible && popupRef.current) {
      popupRef.current.remove()
      popupRef.current = null
    }

    if (!visible) return

    const onClick = (e: mapboxgl.MapMouseEvent & { features?: mapboxgl.GeoJSONFeature[] }) => {
      const feature = e.features?.[0]
      if (!feature || feature.geometry.type !== 'Point') return

      const props = feature.properties!
      const coords = (feature.geometry as GeoJSON.Point).coordinates.slice() as [number, number]

      const area = props.area || ''
      const subArea = props.subArea || ''
      const zone = props.zone || ''
      const streetName = subArea !== 'Unknown' ? subArea : area
      const subtitle = zone !== streetName ? zone : ''
      const rateDisplay = props.rateDisplay || 'N/A'
      const meterCount = props.meterCount || 0
      const timeStart = props.timeStart || ''
      const timeEnd = props.timeEnd || ''
      const timeLimit = props.timeLimit || ''
      const hasMobilePay = props.hasMobilePay === true || props.hasMobilePay === 'true'

      const hours = timeStart && timeEnd ? `${timeStart} – ${timeEnd}` : ''
      const mobileBadge = hasMobilePay
        ? '<span style="display:inline-block;background:#dbeafe;color:#1d4ed8;font-size:10px;padding:1px 6px;border-radius:4px;margin-top:4px;">Mobile Pay</span>'
        : ''

      // Remove previous popup
      if (popupRef.current) popupRef.current.remove()

      const popup = new mapboxgl.Popup({ closeOnClick: true, offset: 12 })
        .setLngLat(coords)
        .setHTML(
          `<div style="padding:10px;min-width:150px;font-family:system-ui,sans-serif;">
            <div style="font-weight:600;font-size:13px;margin-bottom:2px;">${streetName}</div>
            ${subtitle ? `<div style="font-size:11px;color:#78716c;margin-bottom:4px;">${subtitle}</div>` : ''}
            <div style="font-size:13px;font-weight:600;color:#16a34a;">${rateDisplay}</div>
            <div style="font-size:11px;color:#57534e;margin-top:2px;">${meterCount} meter${meterCount !== 1 ? 's' : ''}</div>
            ${hours ? `<div style="font-size:11px;color:#57534e;">${hours}</div>` : ''}
            ${timeLimit ? `<div style="font-size:11px;color:#57534e;">${timeLimit} limit</div>` : ''}
            ${mobileBadge}
          </div>`
        )
        .addTo(map)

      popupRef.current = popup
    }

    const onMouseEnter = () => {
      map.getCanvas().style.cursor = 'pointer'
    }
    const onMouseLeave = () => {
      map.getCanvas().style.cursor = ''
    }

    map.on('click', CIRCLE_LAYER_ID, onClick)
    map.on('mouseenter', CIRCLE_LAYER_ID, onMouseEnter)
    map.on('mouseleave', CIRCLE_LAYER_ID, onMouseLeave)

    return () => {
      map.off('click', CIRCLE_LAYER_ID, onClick)
      map.off('mouseenter', CIRCLE_LAYER_ID, onMouseEnter)
      map.off('mouseleave', CIRCLE_LAYER_ID, onMouseLeave)
      if (popupRef.current) {
        popupRef.current.remove()
        popupRef.current = null
      }
    }
  }, [map, visible])
}
