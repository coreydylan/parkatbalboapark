'use client'

import { getCostColor } from '@/lib/utils'

interface LotMarkerProps {
  name: string
  costCents: number
  selected?: boolean
}

/**
 * Creates a custom HTML element for a parking lot map marker.
 * Used with mapboxgl.Marker for custom rendering.
 */
export function createLotMarkerElement(
  props: LotMarkerProps
): HTMLDivElement {
  const { name, costCents, selected = false } = props
  const color = getCostColor(costCents)
  const initial = name.charAt(0).toUpperCase()

  const el = document.createElement('div')
  el.className = 'lot-marker'
  el.style.width = '32px'
  el.style.height = '32px'
  el.style.borderRadius = '50%'
  el.style.backgroundColor = color
  el.style.border = selected ? '3px solid #15803d' : '2px solid white'
  el.style.boxShadow = '0 2px 4px rgba(0,0,0,0.2)'
  el.style.display = 'flex'
  el.style.alignItems = 'center'
  el.style.justifyContent = 'center'
  el.style.color = 'white'
  el.style.fontSize = '12px'
  el.style.fontWeight = '700'
  el.style.cursor = 'pointer'
  el.style.transition = 'transform 0.15s ease'
  el.textContent = initial || 'P'

  el.addEventListener('mouseenter', () => {
    el.style.transform = 'scale(1.15)'
  })
  el.addEventListener('mouseleave', () => {
    el.style.transform = 'scale(1)'
  })

  return el
}

/**
 * React component for rendering a lot marker preview (non-map usage).
 */
export function LotMarker({ name, costCents, selected = false }: LotMarkerProps) {
  const color = getCostColor(costCents)
  const initial = name.charAt(0).toUpperCase()

  return (
    <div
      className="inline-flex items-center justify-center rounded-full text-white text-xs font-bold"
      style={{
        width: 32,
        height: 32,
        backgroundColor: color,
        border: selected ? '3px solid #15803d' : '2px solid white',
        boxShadow: '0 2px 4px rgba(0,0,0,0.2)',
      }}
    >
      {initial || 'P'}
    </div>
  )
}
