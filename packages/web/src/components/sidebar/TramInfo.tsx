'use client'

import { useState } from 'react'

const TRAM_STOPS = [
  'Inspiration Point',
  'Palisades / The Old Globe',
  'Plaza de Panama',
  'Park Blvd & Presidents Way',
]

export function TramInfo() {
  const [isOpen, setIsOpen] = useState(false)

  return (
    <div className="border border-stone-200 rounded-xl overflow-hidden">
      <button
        type="button"
        onClick={() => setIsOpen(!isOpen)}
        className="w-full flex items-center justify-between p-3 hover:bg-stone-50 transition-colors"
      >
        <div className="flex items-center gap-2">
          <span className="w-6 h-6 bg-orange-100 rounded-full flex items-center justify-center text-orange-600 text-xs font-bold">
            T
          </span>
          <span className="text-sm font-medium text-stone-700">Free Tram</span>
        </div>
        <svg
          className={`w-4 h-4 text-stone-400 transition-transform ${isOpen ? 'rotate-180' : ''}`}
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
        >
          <polyline points="6 9 12 15 18 9" />
        </svg>
      </button>

      {isOpen && (
        <div className="px-3 pb-3 border-t border-stone-100">
          <div className="mt-3 space-y-2">
            <div className="flex justify-between text-sm">
              <span className="text-stone-500">Schedule</span>
              <span className="text-stone-700 font-medium">
                9:00 AM - 6:00 PM daily
              </span>
            </div>
            <div className="flex justify-between text-sm">
              <span className="text-stone-500">Frequency</span>
              <span className="text-stone-700 font-medium">Every 10 minutes</span>
            </div>

            <div className="mt-3">
              <p className="text-xs font-medium text-stone-500 mb-2">Stops</p>
              <div className="space-y-1.5">
                {TRAM_STOPS.map((stop, i) => (
                  <div key={stop} className="flex items-center gap-2">
                    <div className="flex flex-col items-center">
                      <div className="w-2.5 h-2.5 rounded-full bg-orange-500" />
                      {i < TRAM_STOPS.length - 1 && (
                        <div className="w-px h-3 bg-orange-200" />
                      )}
                    </div>
                    <span className="text-xs text-stone-600">{stop}</span>
                  </div>
                ))}
              </div>
            </div>

            <p className="text-xs text-stone-400 mt-2 pt-2 border-t border-stone-100">
              Free to ride for all Balboa Park visitors
            </p>
          </div>
        </div>
      )}
    </div>
  )
}
