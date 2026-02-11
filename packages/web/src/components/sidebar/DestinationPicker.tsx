'use client'

import { useState, useEffect, useMemo } from 'react'
import { useAppStore } from '@/store/app-store'
import { SearchInput } from '@/components/ui/SearchInput'
import { useDebounce } from '@/lib/hooks'
import { getAreaLabel, getTypeIcon } from '@/lib/utils'
import type { Destination, DestinationArea } from '@parkatbalboa/shared'

export function DestinationPicker() {
  const destinations = useAppStore((s) => s.destinations)
  const selectedDestination = useAppStore((s) => s.selectedDestination)
  const setDestination = useAppStore((s) => s.setDestination)
  const fetchDestinations = useAppStore((s) => s.fetchDestinations)

  const [search, setSearch] = useState('')
  const [isOpen, setIsOpen] = useState(false)
  const debouncedSearch = useDebounce(search, 200)

  useEffect(() => {
    fetchDestinations()
  }, [fetchDestinations])

  const grouped = useMemo(() => {
    const filtered = destinations.filter((d) =>
      d.displayName.toLowerCase().includes(debouncedSearch.toLowerCase())
    )

    const groups: Record<DestinationArea, Destination[]> = {
      central_mesa: [],
      palisades: [],
      east_mesa: [],
      florida_canyon: [],
      morley_field: [],
      pan_american: [],
    }

    for (const d of filtered) {
      if (groups[d.area]) {
        groups[d.area].push(d)
      }
    }

    return Object.entries(groups).filter(
      ([, dests]) => dests.length > 0
    ) as [DestinationArea, Destination[]][]
  }, [destinations, debouncedSearch])

  function handleSelect(dest: Destination) {
    setDestination(dest)
    setIsOpen(false)
    setSearch('')
  }

  function handleClear() {
    setDestination(null)
    setSearch('')
  }

  return (
    <div className="relative">
      <label className="text-sm font-medium text-stone-700 mb-2 block">
        I&apos;m going to...
      </label>

      {selectedDestination && !isOpen ? (
        <div className="flex items-center justify-between p-3 border border-park-green rounded-lg bg-park-cream">
          <div className="flex items-center gap-2">
            <span>{getTypeIcon(selectedDestination.type)}</span>
            <span className="text-sm font-medium text-stone-800">
              {selectedDestination.displayName}
            </span>
          </div>
          <button
            onClick={handleClear}
            className="text-stone-400 hover:text-stone-600 transition-colors"
            aria-label="Clear destination"
          >
            <svg
              className="w-4 h-4"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <path d="M18 6 6 18" />
              <path d="m6 6 12 12" />
            </svg>
          </button>
        </div>
      ) : (
        <>
          <SearchInput
            value={search}
            onChange={(val) => {
              setSearch(val)
              setIsOpen(true)
            }}
            placeholder="Search destinations..."
          />

          {isOpen && (
            <div className="absolute top-full left-0 right-0 mt-1 bg-white border border-stone-200 rounded-lg shadow-lg max-h-64 overflow-y-auto z-30">
              {grouped.length === 0 ? (
                <div className="p-3 text-sm text-stone-400 text-center">
                  No destinations found
                </div>
              ) : (
                grouped.map(([area, dests]) => (
                  <div key={area}>
                    <div className="px-3 py-1.5 text-xs font-semibold text-stone-400 uppercase tracking-wide bg-stone-50 sticky top-0">
                      {getAreaLabel(area)}
                    </div>
                    {dests.map((d) => (
                      <button
                        key={d.id}
                        onClick={() => handleSelect(d)}
                        className="w-full text-left px-3 py-2 flex items-center gap-2 hover:bg-stone-50 transition-colors"
                      >
                        <span className="text-base">{getTypeIcon(d.type)}</span>
                        <span className="text-sm text-stone-700">
                          {d.displayName}
                        </span>
                      </button>
                    ))}
                  </div>
                ))
              )}
            </div>
          )}
        </>
      )}

      {!selectedDestination && !isOpen && (
        <button
          onClick={() => setIsOpen(true)}
          className="w-full mt-0"
          aria-label="Open destination picker"
        >
          <SearchInput
            value=""
            onChange={() => setIsOpen(true)}
            placeholder="Search destinations..."
          />
        </button>
      )}
    </div>
  )
}
