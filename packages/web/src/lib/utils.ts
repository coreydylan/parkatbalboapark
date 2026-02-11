import type { DestinationArea, DestinationType } from '@parkatbalboa/shared'

/**
 * Format cost in cents to a display string.
 */
export function formatCost(cents: number): string {
  if (cents <= 0) return 'FREE'
  const dollars = cents / 100
  if (cents % 100 === 0) return `$${dollars}`
  return `$${dollars.toFixed(2)}`
}

/**
 * Format walking time in seconds to a human-readable string.
 */
export function formatWalkTime(seconds: number): string {
  const minutes = Math.round(seconds / 60)
  if (minutes <= 0) return '1 min walk'
  return `${minutes} min walk`
}

/**
 * Format distance in meters to miles.
 */
export function formatDistance(meters: number): string {
  const miles = meters / 1609.344
  if (miles < 0.1) return `${Math.round(meters)} ft`
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
 * Get an icon for a destination type.
 */
export function getTypeIcon(type: DestinationType): string {
  const icons: Record<DestinationType, string> = {
    museum: '\u{1F3DB}\uFE0F',
    garden: '\u{1F33F}',
    theater: '\u{1F3AD}',
    landmark: '\u{1F3F0}',
    recreation: '\u26BD',
    dining: '\u{1F37D}\uFE0F',
    zoo: '\u{1F981}',
    other: '\u{1F4CD}',
  }
  return icons[type] ?? '\u{1F4CD}'
}
