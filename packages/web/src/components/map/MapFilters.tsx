'use client'

import { useAppStore } from '@/store/app-store'
import { Train, DoorOpen, Droplets, Zap, ParkingMeter, type LucideIcon } from 'lucide-react'

const FILTERS: readonly { key: string; label: string; Icon: LucideIcon }[] = [
  { key: 'tram', label: 'Tram', Icon: Train },
  { key: 'restrooms', label: 'Restrooms', Icon: DoorOpen },
  { key: 'water', label: 'Water', Icon: Droplets },
  { key: 'ev_charging', label: 'EV Charging', Icon: Zap },
  { key: 'street_parking', label: 'Street Meters', Icon: ParkingMeter },
]

export function MapFilters() {
  const mapFilters = useAppStore((s) => s.mapFilters)
  const toggleMapFilter = useAppStore((s) => s.toggleMapFilter)

  return (
    <div className="absolute top-3 left-3 z-10 flex gap-2 overflow-x-auto max-w-[calc(100%-80px)] scrollbar-hide pr-2">
      {FILTERS.map((f) => {
        const active = !!mapFilters[f.key]
        return (
          <button
            key={f.key}
            type="button"
            onClick={() => toggleMapFilter(f.key)}
            className={`
              inline-flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-xs font-medium
              whitespace-nowrap transition-all duration-200 cursor-pointer shrink-0
              backdrop-blur-sm
              ${
                active
                  ? 'bg-park-green text-white shadow-sm'
                  : 'bg-white/90 text-stone-600 border border-stone-200 hover:bg-white hover:shadow-sm'
              }
            `}
          >
            <f.Icon className="w-3.5 h-3.5" />
            {f.label}
          </button>
        )
      })}
    </div>
  )
}
