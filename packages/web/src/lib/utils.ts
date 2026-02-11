import type { DestinationArea, DestinationType } from '@parkatbalboa/shared'
import type { LucideIcon } from 'lucide-react'
import {
  Landmark,
  Flower2,
  Music,
  MapPin,
  Bike,
  UtensilsCrossed,
  PawPrint,
  CircleDot,
} from 'lucide-react'

export { formatCost, formatWalkTime } from '@parkatbalboa/shared'

/**
 * Format distance in meters to feet or miles.
 */
export function formatDistance(meters: number): string {
  const miles = meters / 1609.344
  if (miles < 0.1) return `${Math.round(meters * 3.28084)} ft`
  return `${miles.toFixed(1)} mi`
}

/**
 * Get a color hex code based on cost in cents.
 */
export function getCostColor(cents: number): string {
  if (cents <= 0) return '#22c55e'
  if (cents <= 800) return '#f59e0b'
  return '#ef4444'
}

/**
 * Get a human-readable label for a destination area.
 */
export function getAreaLabel(area: DestinationArea): string {
  const labels: Record<DestinationArea, string> = {
    central_mesa: 'Central Mesa',
    palisades: 'Palisades',
    east_mesa: 'East Mesa',
    florida_canyon: 'Florida Canyon',
    morley_field: 'Morley Field',
    pan_american: 'Pan American Plaza',
  }
  return labels[area] ?? area
}

/**
 * Map of destination types to their lucide icon components.
 */
const TYPE_ICONS: Record<DestinationType, LucideIcon> = {
  museum: Landmark,
  garden: Flower2,
  theater: Music,
  landmark: MapPin,
  recreation: Bike,
  dining: UtensilsCrossed,
  zoo: PawPrint,
  other: CircleDot,
}

/**
 * Get the lucide icon component for a destination type.
 */
export function getTypeIconComponent(type: DestinationType): LucideIcon {
  return TYPE_ICONS[type] ?? CircleDot
}
