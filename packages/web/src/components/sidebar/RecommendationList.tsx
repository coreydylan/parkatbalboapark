'use client'

import { useAppStore } from '@/store/app-store'
import { RecommendationCard } from './RecommendationCard'

export function RecommendationList() {
  const recommendations = useAppStore((s) => s.recommendations)
  const isLoading = useAppStore((s) => s.isLoading)
  const userType = useAppStore((s) => s.userType)
  const enforcementActive = useAppStore((s) => s.enforcementActive)

  if (!userType) {
    return (
      <div className="text-center py-8">
        <div className="text-stone-300 mb-2">
          <svg
            className="w-12 h-12 mx-auto"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.5"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <rect x="1" y="3" width="15" height="13" rx="2" />
            <path d="m16 8 4 2.5v3L16 16" />
            <circle cx="5.5" cy="18" r="2" />
            <circle cx="12.5" cy="18" r="2" />
          </svg>
        </div>
        <p className="text-sm text-stone-400">
          Select who you are and where you&apos;re going
        </p>
      </div>
    )
  }

  if (isLoading) {
    return (
      <div>
        <div className="flex items-center justify-between mb-3">
          <h3 className="text-sm font-medium text-stone-700">
            Recommended Parking
          </h3>
        </div>
        <div className="space-y-3">
          {[1, 2, 3].map((i) => (
            <div
              key={i}
              className="rounded-xl border border-stone-200 p-4 animate-pulse"
            >
              <div className="flex items-start justify-between mb-3">
                <div className="h-5 bg-stone-200 rounded w-32" />
                <div className="h-5 bg-stone-200 rounded w-12" />
              </div>
              <div className="flex gap-4">
                <div className="h-4 bg-stone-100 rounded w-20" />
                <div className="h-4 bg-stone-100 rounded w-24" />
              </div>
            </div>
          ))}
        </div>
      </div>
    )
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-3">
        <h3 className="text-sm font-medium text-stone-700">
          Recommended Parking
        </h3>
        <div className="flex items-center gap-2">
          {enforcementActive ? (
            <span className="text-xs text-yellow-700 bg-yellow-50 px-2 py-0.5 rounded-full">
              Enforcement active
            </span>
          ) : (
            <span className="text-xs text-green-700 bg-green-50 px-2 py-0.5 rounded-full">
              Free parking hours
            </span>
          )}
          <span className="text-xs text-stone-400">
            {recommendations.length} lot{recommendations.length !== 1 ? 's' : ''}
          </span>
        </div>
      </div>

      {recommendations.length === 0 ? (
        <p className="text-sm text-stone-400 text-center py-4">
          No parking recommendations available
        </p>
      ) : (
        <div className="space-y-3">
          {recommendations.map((rec, index) => (
            <RecommendationCard key={rec.lotSlug} recommendation={rec} rank={index + 1} />
          ))}
        </div>
      )}
    </div>
  )
}
