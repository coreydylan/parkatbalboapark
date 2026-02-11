'use client'

import { useState } from 'react'
import { TramFront, ChevronDown, Clock, RotateCw } from 'lucide-react'

const TRAM_STOPS = [
  'Inspiration Point',
  'Palisades / The Old Globe',
  'Plaza de Panama',
  'Park Blvd & Presidents Way',
]

export function TramInfo() {
  const [isOpen, setIsOpen] = useState(false)

  return (
    <div className="border border-stone-100 rounded-xl overflow-hidden bg-white transition-all duration-200">
      <button
        type="button"
        onClick={() => setIsOpen(!isOpen)}
        className="w-full flex items-center justify-between p-3 hover:bg-stone-50 transition-all duration-200"
      >
        <div className="flex items-center gap-2.5">
          <span className="w-7 h-7 bg-park-gold/10 rounded-full flex items-center justify-center">
            <TramFront className="w-4 h-4 text-park-gold" />
          </span>
          <span className="text-sm font-semibold text-stone-800">Free Tram</span>
        </div>
        <ChevronDown
          className={`w-4 h-4 text-stone-400 transition-transform duration-200 ${isOpen ? 'rotate-180' : ''}`}
        />
      </button>

      {isOpen && (
        <div className="px-3 pb-3 border-t border-stone-100">
          <div className="mt-3 space-y-2.5">
            <div className="flex justify-between text-sm items-center">
              <span className="flex items-center gap-1.5 text-stone-500">
                <Clock className="w-3.5 h-3.5" />
                Schedule
              </span>
              <span className="text-stone-700 font-medium">
                9:00 AM - 6:00 PM daily
              </span>
            </div>
            <div className="flex justify-between text-sm items-center">
              <span className="flex items-center gap-1.5 text-stone-500">
                <RotateCw className="w-3.5 h-3.5" />
                Frequency
              </span>
              <span className="text-stone-700 font-medium">Every 10 minutes</span>
            </div>

            <div className="mt-3">
              <p className="text-xs font-semibold text-stone-400 uppercase tracking-wide mb-2">Stops</p>
              <div className="space-y-0">
                {TRAM_STOPS.map((stop, i) => (
                  <div key={stop} className="flex items-start gap-2.5">
                    <div className="flex flex-col items-center pt-0.5">
                      <div className="w-2.5 h-2.5 rounded-full bg-park-green border-2 border-park-green/30" />
                      {i < TRAM_STOPS.length - 1 && (
                        <div className="w-0.5 h-4 bg-park-green/20 rounded-full" />
                      )}
                    </div>
                    <span className="text-xs text-stone-600 pb-1.5">{stop}</span>
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
