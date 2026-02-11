'use client'

import { useAppStore } from '@/store/app-store'

const FILTERS = [
  { key: 'tram', label: 'Tram', icon: '\u{1F68A}', activeColor: 'bg-orange-500 border-orange-500' },
  { key: 'restrooms', label: 'Restrooms', icon: '\u{1F6BB}', activeColor: 'bg-blue-500 border-blue-500' },
  { key: 'water', label: 'Water', icon: '\u{1F4A7}', activeColor: 'bg-cyan-500 border-cyan-500' },
  { key: 'ev_charging', label: 'EV Charging', icon: '\u26A1', activeColor: 'bg-green-600 border-green-600' },
] as const

export function MapFilters() {
  const mapFilters = useAppStore((s) => s.mapFilters)
  const toggleMapFilter = useAppStore((s) => s.toggleMapFilter)

  return (
    <div className="absolute top-2 left-2 z-10 flex gap-1.5 overflow-x-auto max-w-[calc(100%-80px)] scrollbar-hide">
      {FILTERS.map((f) => {
        const active = !!mapFilters[f.key]
        return (
          <button
            key={f.key}
            type="button"
            onClick={() => toggleMapFilter(f.key)}
            className={`
              inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-xs font-medium
              whitespace-nowrap transition-colors cursor-pointer shrink-0
              backdrop-blur-sm border
              ${
                active
                  ? `${f.activeColor} text-white shadow-sm`
                  : 'bg-white/80 text-stone-600 border-stone-200 hover:bg-white'
              }
            `}
          >
            <span className="text-sm leading-none">{f.icon}</span>
            {f.label}
          </button>
        )
      })}
    </div>
  )
}
