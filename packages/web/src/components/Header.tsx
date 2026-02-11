'use client'

import { useState } from 'react'

export function Header() {
  const [showInfo, setShowInfo] = useState(false)

  return (
    <>
      <header className="h-14 px-4 flex items-center justify-between border-b border-stone-200 bg-white shrink-0 z-20">
        <div className="flex items-center gap-2">
          <svg
            className="w-6 h-6 text-park-green"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <circle cx="12" cy="12" r="10" />
            <path d="M9 9h4a2 2 0 0 1 0 4H9V7" />
          </svg>
          <h1 className="text-lg font-semibold text-park-green">
            Park at Balboa Park
          </h1>
          <span className="hidden sm:inline text-sm text-stone-400 ml-2">
            Find the best parking spot
          </span>
        </div>

        <button
          onClick={() => setShowInfo(true)}
          className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-stone-100 transition-colors text-stone-400 hover:text-stone-600"
          aria-label="Information"
        >
          <svg
            className="w-5 h-5"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <circle cx="12" cy="12" r="10" />
            <path d="M12 16v-4" />
            <path d="M12 8h.01" />
          </svg>
        </button>
      </header>

      {showInfo && (
        <div
          className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4"
          onClick={() => setShowInfo(false)}
        >
          <div
            className="bg-white rounded-2xl max-w-md w-full p-6 shadow-xl"
            onClick={(e) => e.stopPropagation()}
          >
            <h2 className="text-lg font-semibold text-park-green mb-3">
              About Park at Balboa Park
            </h2>
            <p className="text-sm text-stone-600 mb-3">
              Find free and paid parking at Balboa Park, San Diego.
              Get personalized recommendations based on where you are going,
              how long you will stay, and who you are.
            </p>
            <p className="text-sm text-stone-500 mb-4">
              Parking enforcement hours are typically 8 AM - 6 PM daily.
              Outside these hours, all paid lots are free.
              Holidays are also free.
            </p>
            <button
              onClick={() => setShowInfo(false)}
              className="w-full py-2 bg-park-green text-white rounded-lg font-medium hover:bg-park-green-dark transition-colors"
            >
              Got it
            </button>
          </div>
        </div>
      )}
    </>
  )
}
