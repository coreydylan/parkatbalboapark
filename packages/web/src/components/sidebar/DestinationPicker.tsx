'use client'

import { useState, useEffect, useMemo } from 'react'
import { useAppStore } from '@/store/app-store'
import type { Waypoint } from '@/store/app-store'
import { SearchInput } from '@/components/ui/SearchInput'
import { useDebounce } from '@/lib/hooks'
import { getAreaLabel, getTypeIconComponent } from '@/lib/utils'
import { MapPin, X } from 'lucide-react'
import type { Destination, DestinationArea, DestinationType } from '@parkatbalboa/shared'

function mapCategoryToType(category: string): DestinationType {
  const map: Record<string, DestinationType> = {
    museum: 'museum',
    arts_culture: 'landmark',
    garden: 'garden',
    garden_nature: 'garden',
    theatre: 'theater',
    theater_performance: 'theater',
    dining: 'dining',
    cafe: 'dining',
    restaurant: 'dining',
    recreation: 'recreation',
    sports: 'recreation',
    playground: 'recreation',
    zoo: 'zoo',
    zoo_animals: 'zoo',
  }
  return map[category] ?? 'other'
}

function waypointToDestination(wp: Waypoint): Destination {
  return {
    id: wp.id,
    slug: wp.id.replace('/', '-'),
    name: wp.name,
    displayName: wp.name,
    area: 'central_mesa' as DestinationArea,
    type: mapCategoryToType(wp.category),
    address: null,
    lat: wp.lat,
    lng: wp.lng,
    websiteUrl: null,
    createdAt: '',
  }
}

function DestinationTypeIcon({ type, className }: { type: DestinationType; className?: string }) {
  const Icon = getTypeIconComponent(type)
  return <Icon className={className} />
}

export function DestinationPicker() {
  const destinations = useAppStore((s) => s.destinations)
  const waypoints = useAppStore((s) => s.waypoints)
  const selectedDestination = useAppStore((s) => s.selectedDestination)
  const setDestination = useAppStore((s) => s.setDestination)
  const fetchDestinations = useAppStore((s) => s.fetchDestinations)
  const fetchWaypoints = useAppStore((s) => s.fetchWaypoints)

  const [search, setSearch] = useState('')
  const [isOpen, setIsOpen] = useState(false)
  const debouncedSearch = useDebounce(search, 200)

  useEffect(() => {
    fetchDestinations()
    fetchWaypoints()
  }, [fetchDestinations, fetchWaypoints])

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

  const filteredWaypoints = useMemo(() => {
    if (!debouncedSearch) return []

    const q = debouncedSearch.toLowerCase()

    // Get IDs of curated destinations to exclude duplicates
    const curatedNames = new Set(
      destinations.map((d) => d.name.toLowerCase())
    )

    return waypoints
      .filter(
        (w) =>
          w.name.toLowerCase().includes(q) &&
          !curatedNames.has(w.name.toLowerCase())
      )
      .slice(0, 20)
  }, [waypoints, destinations, debouncedSearch])

  function handleSelect(dest: Destination) {
    setDestination(dest)
    setIsOpen(false)
    setSearch('')
  }

  function handleSelectWaypoint(wp: Waypoint) {
    setDestination(waypointToDestination(wp))
    setIsOpen(false)
    setSearch('')
  }

  function handleClear() {
    setDestination(null)
    setSearch('')
  }

  const hasResults = grouped.length > 0 || filteredWaypoints.length > 0

  return (
    <div className="relative">
      <label className="text-base font-semibold text-stone-800 mb-3 block">
        I&apos;m going to...
      </label>

      {selectedDestination && !isOpen ? (
        <div className="flex items-center justify-between p-3 border border-park-green/30 rounded-xl bg-park-green/5 transition-all duration-200">
          <div className="flex items-center gap-2.5">
            <MapPin className="w-4 h-4 text-park-green" />
            <span className="text-sm font-medium text-stone-800">
              {selectedDestination.displayName}
            </span>
          </div>
          <button
            onClick={handleClear}
            className="text-stone-400 hover:text-stone-600 transition-all duration-200 p-0.5 rounded-md hover:bg-stone-100"
            aria-label="Clear destination"
          >
            <X className="w-4 h-4" />
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
            <div className="absolute top-full left-0 right-0 mt-1 bg-white border border-stone-100 rounded-xl shadow-lg max-h-64 overflow-y-auto z-30">
              {!hasResults ? (
                <div className="p-4 text-sm text-stone-400 text-center">
                  No destinations found
                </div>
              ) : (
                <>
                  {grouped.map(([area, dests]) => (
                    <div key={area}>
                      <div className="px-3 py-1.5 text-xs font-semibold text-stone-400 uppercase tracking-wide bg-stone-50 sticky top-0">
                        {getAreaLabel(area)}
                      </div>
                      {dests.map((d) => (
                        <button
                          key={d.id}
                          onClick={() => handleSelect(d)}
                          className="w-full text-left px-3 py-2.5 flex items-center gap-2.5 hover:bg-park-green/5 transition-all duration-200"
                        >
                          <DestinationTypeIcon type={d.type} className="w-4 h-4 text-stone-400" />
                          <span className="text-sm text-stone-700">
                            {d.displayName}
                          </span>
                        </button>
                      ))}
                    </div>
                  ))}

                  {filteredWaypoints.length > 0 && (
                    <div>
                      <div className="px-3 py-1.5 text-xs font-semibold text-stone-400 uppercase tracking-wide bg-stone-50 sticky top-0">
                        Other Places
                      </div>
                      {filteredWaypoints.map((wp) => (
                        <button
                          key={wp.id}
                          onClick={() => handleSelectWaypoint(wp)}
                          className="w-full text-left px-3 py-2.5 flex items-center gap-2.5 hover:bg-park-green/5 transition-all duration-200"
                        >
                          <DestinationTypeIcon type={mapCategoryToType(wp.category)} className="w-4 h-4 text-stone-400" />
                          <span className="text-sm text-stone-700">
                            {wp.name}
                          </span>
                          {wp.onOfficialMap && (
                            <span className="ml-auto text-[10px] font-semibold text-park-green bg-park-green/10 px-2 py-0.5 rounded-full border border-park-green/20">
                              On Map
                            </span>
                          )}
                        </button>
                      ))}
                    </div>
                  )}
                </>
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
