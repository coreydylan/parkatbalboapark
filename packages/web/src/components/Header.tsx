'use client'

import { useState } from 'react'
import { TreePine, Info, X } from 'lucide-react'

export function Header() {
  const [showInfo, setShowInfo] = useState(false)

  return (
    <>
      <header className="h-16 px-4 flex items-center justify-between bg-park-green shadow-sm shrink-0 z-20">
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-lg bg-white/15 flex items-center justify-center">
            <TreePine className="w-5 h-5 text-white" />
          </div>
          <div className="flex items-center gap-2">
            <h1 className="text-base font-semibold text-white tracking-tight">
              Park at Balboa Park
            </h1>
            <span className="hidden sm:inline text-sm text-white/60">
              Find the best parking spot
            </span>
          </div>
        </div>

        <button
          onClick={() => setShowInfo(true)}
          className="w-8 h-8 flex items-center justify-center rounded-lg text-white/70 hover:text-white hover:bg-white/10 transition-all duration-200 cursor-pointer"
          aria-label="Information"
        >
          <Info className="w-5 h-5" />
        </button>
      </header>

      {showInfo && (
        <div
          className="fixed inset-0 bg-black/40 backdrop-blur-xs z-50 flex items-center justify-center p-4"
          onClick={() => setShowInfo(false)}
        >
          <div
            className="bg-white rounded-2xl max-w-md w-full p-6 shadow-lg"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-lg bg-park-green/10 flex items-center justify-center">
                  <TreePine className="w-4 h-4 text-park-green" />
                </div>
                <h2 className="text-base font-semibold text-stone-800">
                  About Park at Balboa Park
                </h2>
              </div>
              <button
                onClick={() => setShowInfo(false)}
                className="w-7 h-7 flex items-center justify-center rounded-lg text-stone-400 hover:text-stone-600 hover:bg-stone-100 transition-all duration-200 cursor-pointer"
                aria-label="Close"
              >
                <X className="w-4 h-4" />
              </button>
            </div>
            <p className="text-sm text-stone-600 mb-3">
              Find free and paid parking at Balboa Park, San Diego.
              Get personalized recommendations based on where you are going,
              how long you will stay, and who you are.
            </p>
            <p className="text-sm text-stone-500 mb-5">
              Parking enforcement hours are typically 8 AM - 6 PM daily.
              Outside these hours, all paid lots are free.
              Holidays are also free.
            </p>
            <button
              onClick={() => setShowInfo(false)}
              className="w-full py-2.5 bg-park-green text-white rounded-lg font-medium hover:bg-park-green-dark transition-all duration-200 cursor-pointer shadow-sm hover:shadow-md"
            >
              Got it
            </button>
          </div>
        </div>
      )}
    </>
  )
}
